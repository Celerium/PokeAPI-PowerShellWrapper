function Get-PokeEndpoint {
<#
    .SYNOPSIS
        Gets endpoints from PokeAPI

    .DESCRIPTION
        The Get-PokeEndpoint cmdlet gets endpoints from PokeAPI

    .PARAMETER updateCache
        Defines if the cache is refreshed regardless of age

        By default the cache is refreshed every 30min

    .EXAMPLE
        Get-PokeEndpoint

        Gets the endpoints from PokeAPI

    .NOTES
        n/a

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/utility/Get-PokeEndpoint.html
#>

    [CmdletBinding(DefaultParameterSetName = 'index_ByAll')]
    Param (
        [Parameter(Mandatory = $false)]
        [Switch]$updateCache
    )

    begin {

        $functionName   = $MyInvocation.InvocationName
        $cachedDataName = $functionName + '_Cached' -replace '-','_'
        $parameterName  = $functionName + '_Parameters' -replace '-','_'
        $runTime        = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

        $endpoints = [System.Collections.Generic.List[object]]::new()

    }

    process {

        Write-Verbose "Running [ $functionName ] with [ $($PSCmdlet.ParameterSetName) ] parameterSet"
        Set-Variable -Name $parameterName -Value $PSBoundParameters -Scope Global -Force

        switch ( $PSCmdlet.ParameterSetName ) {

            'index_ByAll'  {
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName
            }

        }

        if ( $null -eq $cachedData -or ($cachedData.staleCache | Select-Object -First 1) -or $updateCache ) {

            if ($cachedData.staleCache) {
                Write-Verbose "Refreshing cached data: Old Timestamp [ $( ($cachedData.cachedTime| Select-Object -First 1)) | New Timestamp [ $([DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")) ]"
            }

            $invokeRequest = Invoke-RestMethod -Method GET -Uri $Poke_Base_URI

            $endpointCount = $invokeRequest.PSObject.Properties.Name.Count

            foreach ($property in  $invokeRequest.PSObject.Properties) {

                $data = [PSCustomObject]@{
                    name    = $property.name
                    url     = $property.value
                }

                $endpoints.add($data)

            }

            $results = [PSCustomObject]@{
                count       = $endpointCount
                next        = $null
                previous    = $null
                results     = $endpoints
            }

            if ($results) {
                Set-PokeCachedData -name $cachedDataName -timeStamp $runTime -data $results
            }

        }
        else {

            Write-Verbose "Returning cached data: Cached is [ $( (New-TimeSpan -Start $cachedData.cachedTime -End $(Get-Date)).Minutes)min ] old"
            $results = $cachedData
            $results.PSObject.Properties.Remove('staleCache')
            $results.PSObject.Properties.Remove('cachedTime')

        }

        return $results

    }

    end {}

}
