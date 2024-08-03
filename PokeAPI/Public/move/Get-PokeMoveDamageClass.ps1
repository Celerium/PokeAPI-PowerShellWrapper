function Get-PokeMoveDamageClass {
<#
    .SYNOPSIS
        Gets move damage classes from PokeAPI

    .DESCRIPTION
        The Get-PokeMoveDamageClass cmdlet gets move damage classes from PokeAPI

        Damage classes moves can have, e.g. physical, special, or non-damaging

    .PARAMETER id
        Defines id of the resource

    .PARAMETER name
        Defines name of the resource

    .PARAMETER offset
        Defines the page number to return

        By default only 20 resources are returned

    .PARAMETER limit
        Defines the amount of resources to return with each page

        By default only 20 resources are returned

    .PARAMETER allPages
        Returns all resources from an endpoint

        As of 2024-02, there is no cap on how many resources can be
        returned using the limit parameter. There is currently no real
        use for this parameter and it was included simply to account if
        pagination is introduced.

    .PARAMETER updateCache
        Defines if the cache is refreshed regardless of age

        By default the cache is refreshed every 30min

    .EXAMPLE
        Get-PokeMoveDamageClass

        Gets the first 20 move damage classes sorted by id

    .EXAMPLE
        Get-PokeMoveDamageClass -id 1

        Gets the move damage class with the defined id

    .EXAMPLE
        Get-PokeMoveDamageClass -name ditto

        Gets the move damage class with the defined name

    .EXAMPLE
        Get-PokeMoveDamageClass -offset 151 -limit 100

        Gets the first 100 resources starting at resources with
        an id over 151

    .NOTES
        n/a

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/move/Get-PokeMoveDamageClass.html
#>

    [CmdletBinding(DefaultParameterSetName = 'index_ByAll')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ById')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$id,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ByName')]
        [ValidateNotNullOrEmpty()]
        [string]$name,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$offset,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$limit,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [Switch]$allPages,

        [Parameter(Mandatory = $false)]
        [Switch]$updateCache
    )

    begin {

        $functionName   = $MyInvocation.InvocationName
        $cachedDataName = $functionName + '_Cached' -replace '-','_'
        $parameterName  = $functionName + '_Parameters' -replace '-','_'
        $runTime        = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    }

    process {

        Write-Verbose "Running [ $functionName ] with [ $($PSCmdlet.ParameterSetName) ] parameterSet"
        Set-Variable -Name $parameterName -Value $PSBoundParameters -Scope Global -Force

        switch ( $PSCmdlet.ParameterSetName ) {

            'index_ByAll'  {
                $resource_uri   = "/move-damage-class"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName
            }
            'index_ById'   {
                $resource_uri   = "/move-damage-class/$id"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -id $id
            }
            'index_ByName' {
                $resource_uri = ("/move-damage-class/$name").ToLower()
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -name $name
            }

        }

        if ( $null -eq $cachedData -or $cachedData.staleCache -or $updateCache ) {

            if ($cachedData.staleCache) {
                Write-Verbose "Refreshing cached data: Old Timestamp [ $($cachedData.cachedTime) | New Timestamp [ $([DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")) ]"
            }

            $results = Invoke-PokeRequest -method GET -resource_Uri $resource_Uri -uri_Filter $PSBoundParameters -allPages:$allPages

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
