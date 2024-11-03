function Get-PokeMachine {
<#
    .SYNOPSIS
        Gets machines from PokeAPI

    .DESCRIPTION
        The Get-PokeMachine cmdlet gets machines from PokeAPI

        Machines are the representation of items that teach moves to Pokemon

        They vary from version to version, so it is not certain that one specific
        TM or HM corresponds to a single Machine

    .PARAMETER id
        Defines id of the resource

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
        Get-PokeMachine

        Gets the first 20 machines sorted by id

    .EXAMPLE
        Get-PokeMachine -id 1

        Gets the machine with the defined id

    .EXAMPLE
        Get-PokeMachine -offset 151 -limit 100

        Gets the first 100 resources starting at resources with
        an id over 151

    .NOTES
        n/a

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/machine/Get-PokeMachine.html
#>

    [CmdletBinding(DefaultParameterSetName = 'index_ByAll')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ById')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$id,

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
            'index_ByAll'  { $resource_uri = "/machine" }
            'index_ById'   { $resource_uri = "/machine/$id" }
        }

        Write-Verbose "Running the [ $($PSCmdlet.ParameterSetName) ] parameterSet"

        Set-Variable -Name 'PokeAPI_MachineParameters' -Value $PSBoundParameters -Scope Global -Force

        Invoke-PokeRequest -method GET -resource_Uri $resource_Uri -uri_Filter $PSBoundParameters -allPages:$allPages

    }

    end {}

}
