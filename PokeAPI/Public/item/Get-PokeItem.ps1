function Get-PokeItem {
<#
    .SYNOPSIS
        Gets items from PokeAPI

    .DESCRIPTION
        The Get-PokeItem cmdlet gets items from PokeAPI

        An item is an object in the games which the player can pick up,
        keep in their bag, and use in some manner

        They have various uses, including healing, powering up, helping catch
        Pokemon, or to access a new area

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
        Get-PokeItem

        Gets the first 20 items sorted by id

    .EXAMPLE
        Get-PokeItem -id 1

        Gets the item with the defined id

    .EXAMPLE
        Get-PokeItem -name ditto

        Gets the item with the defined name

    .EXAMPLE
        Get-PokeItem -offset 151 -limit 100

        Gets the first 100 resources starting at resources with
        an id over 151

    .NOTES
        n/a

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/item/Get-PokeItem.html
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
            'index_ByAll'  { $resource_uri = "/item" }
            'index_ById'   { $resource_uri = "/item/$id" }
            'index_ByName' { $resource_uri = ("/item/$name").ToLower() }
        }

        Write-Verbose "Running the [ $($PSCmdlet.ParameterSetName) ] parameterSet"

        Set-Variable -Name 'PokeAPI_ItemParameters' -Value $PSBoundParameters -Scope Global -Force

        Invoke-PokeRequest -method GET -resource_Uri $resource_Uri -uri_Filter $PSBoundParameters -allPages:$allPages

    }

    end {}

}
