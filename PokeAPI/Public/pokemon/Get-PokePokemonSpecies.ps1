function Get-PokePokemonSpecies {
<#
    .SYNOPSIS
        Gets pokemon species from PokeAPI

    .DESCRIPTION
        The Get-PokePokemonSpecies cmdlet gets pokemon species from PokeAPI

        A Pokemon Species forms the basis for at least one Pokemon. Attributes of a
        Pokemon species are shared across all varieties of Pokemon within the species.

        A good example is Wormadam; Wormadam is the species which can be found in three
        different varieties, Wormadam-Trash, Wormadam-Sandy and Wormadam-Plant.

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
        Get-PokePokemonSpecies

        Gets the first 20 pokemon species sorted by id

    .EXAMPLE
        Get-PokePokemonSpecies -id 1

        Gets the pokemon species with the defined id

    .EXAMPLE
        Get-PokePokemonSpecies -name ditto

        Gets the pokemon species with the defined name

    .EXAMPLE
        Get-PokePokemonSpecies -offset 151 -limit 100

        Gets the first 100 resources starting at resources with
        an id over 151

    .NOTES
        n/a

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/pokemon/Get-PokePokemonSpecies.html
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
                $resource_uri   = "/pokemon-species"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName
            }
            'index_ById'   {
                $resource_uri   = "/pokemon-species/$id"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -id $id
            }
            'index_ByName' {
                $resource_uri = ("/pokemon-species/$name").ToLower()
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
