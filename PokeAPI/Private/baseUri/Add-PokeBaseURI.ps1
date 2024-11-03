function Add-PokeBaseURI {
<#
    .SYNOPSIS
        Sets the base URI for the Poke API connection.

    .DESCRIPTION
        The Add-PokeBaseURI cmdlet sets the base URI which is later used
        to construct the full URI for all API calls.

    .PARAMETER base_uri
        Define the base URI for the Poke API connection using Poke's URI or a custom URI.

    .EXAMPLE
        Add-PokeBaseURI

        The base URI will use https://pokeapi.co/api/v2/ which is Poke's default URI.

    .EXAMPLE
        Add-PokeBaseURI -base_uri http://myapi.gateway.example.com

        A custom API gateway of http://myapi.gateway.example.com will be used for all API calls to Poke's API.

    .NOTES
        N\A

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/Internal/Add-PokeBaseURI.html
#>

    [cmdletbinding()]
    Param (
        [Parameter(Mandatory = $false , ValueFromPipeline = $true)]
        [string]$base_uri = 'https://pokeapi.co/api/v2'
    )

    begin {}

    process {

        # Trim superfluous forward slash from address (if applicable)
        if ($base_uri[$base_uri.Length-1] -eq "/") {
            $base_uri = $base_uri.Substring(0,$base_uri.Length-1)
        }

        Set-Variable -Name "Poke_Base_URI" -Value $base_uri -Option ReadOnly -Scope global -Force

    }

    end {}

}

New-Alias -Name Set-PokeBaseURI -Value Add-PokeBaseURI