function Get-PokePokemonEncounter {
<#
    .SYNOPSIS
        Gets pokemon location areas from PokeAPI

    .DESCRIPTION
        The Get-PokePokemonEncounter cmdlet gets pokemon location areas from PokeAPI

        Pokemon Location Areas are ares where Pokemon can be found

    .PARAMETER id
        Defines id of the resource

    .PARAMETER name
        Defines name of the resource

    .EXAMPLE
        Get-PokePokemonEncounter -id 1

        Gets the pokemon location area with the defined id

    .EXAMPLE
        Get-PokePokemonEncounter -name ditto

        Gets the pokemon location area with the defined name

    .NOTES
        n/a

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/pokemon/Get-PokePokemonEncounter.html
#>

    [CmdletBinding(DefaultParameterSetName = 'index_ById')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ById')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$id,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ByName')]
        [ValidateNotNullOrEmpty()]
        [string]$name
    )

    begin {}

    process {

        switch ( $PSCmdlet.ParameterSetName ) {
            'index_ById'   { $resource_uri = "/pokemon/$id/encounters" }
            'index_ByName' { $resource_uri = ("/pokemon/$name/encounters").ToLower() }
        }

        Write-Verbose "Running the [ $($PSCmdlet.ParameterSetName) ] parameterSet"

        Set-Variable -Name 'PokeAPI_PokemonEncountersParameters' -Value $PSBoundParameters -Scope Global -Force

        Invoke-PokeRequest -method GET -resource_Uri $resource_Uri -uri_Filter $PSBoundParameters -allPages:$allPages

    }

    end {}

}
