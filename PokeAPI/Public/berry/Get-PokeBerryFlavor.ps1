function Get-PokeBerryFlavor {
<#
    .SYNOPSIS
        Gets berry flavor from PokeAPI

    .DESCRIPTION
        The Get-PokeBerryFlavor cmdlet gets berry flavor from PokeAPI

        Flavors determine whether a Pokemon will benefit or suffer
        from eating a berry based on their nature

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

    .EXAMPLE
        Get-PokeBerryFlavor

        Gets the first 20 berry flavors sorted by id

    .EXAMPLE
        Get-PokeBerryFlavor -id 1

        Gets the berry flavor with the defined id

    .EXAMPLE
        Get-PokeBerryFlavor -name ditto

        Gets the berry flavor with the defined name

    .EXAMPLE
        Get-PokeBerryFlavor -offset 151 -limit 100

        Gets the first 100 resources starting at resources with
        an id over 151

    .NOTES
        n/a

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/berry/Get-PokeBerryFlavor.html
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

        [Parameter( Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [Switch]$allPages
    )

    begin {}

    process {

        switch ( $PSCmdlet.ParameterSetName ) {
            'index_ByAll'  { $resource_uri = "/berry-flavor" }
            'index_ById'   { $resource_uri = "/berry-flavor/$id" }
            'index_ByName' { $resource_uri = ("/berry-flavor/$name").ToLower() }
        }

        Write-Verbose "Running the [ $($PSCmdlet.ParameterSetName) ] parameterSet"

        Set-Variable -Name 'PokeAPI_BerryFlavorParameters' -Value $PSBoundParameters -Scope Global -Force

        Invoke-PokeRequest -method GET -resource_Uri $resource_Uri -uri_Filter $PSBoundParameters -allPages:$allPages

    }

    end {}

}
