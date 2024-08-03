function Get-PokeItemFlingEffect {
<#
    .SYNOPSIS
        Gets item fling effects from PokeAPI

    .DESCRIPTION
        The Get-PokeItemFlingEffect cmdlet gets item fling effects from PokeAPI

        The various effects of the move "Fling" when used with different items

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
        Get-PokeItemFlingEffect

        Gets the first 20 item fling effects sorted by id

    .EXAMPLE
        Get-PokeItemFlingEffect -id 1

        Gets the item fling effect with the defined id

    .EXAMPLE
        Get-PokeItemFlingEffect -name ditto

        Gets the item fling effect with the defined name

    .EXAMPLE
        Get-PokeItemFlingEffect -offset 151 -limit 100

        Gets the first 100 resources starting at resources with
        an id over 151

    .NOTES
        n/a

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/item/Get-PokeItemFlingEffect.html
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
                $resource_uri   = "/item-fling-effect"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName
            }
            'index_ById'   {
                $resource_uri   = "/item-fling-effect/$id"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -id $id
            }
            'index_ByName' {
                $resource_uri = ("/item-fling-effect/$name").ToLower()
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
