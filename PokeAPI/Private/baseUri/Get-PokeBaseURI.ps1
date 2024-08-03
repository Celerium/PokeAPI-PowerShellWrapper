function Get-PokeBaseURI {
<#
    .SYNOPSIS
        Shows the Poke base URI global variable.

    .DESCRIPTION
        The Get-PokeBaseURI cmdlet shows the Poke base URI global variable value.

    .EXAMPLE
        Get-PokeBaseURI

        Shows the Poke base URI global variable value.

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/Internal/Get-PokeBaseURI.html
#>

    [cmdletbinding()]
    Param ()

    begin {}

    process {

        switch ([bool]$Poke_Base_URI) {
            $true   { $Poke_Base_URI }
            $false  { Write-Warning "The Poke base URI is not set. Run Add-PokeBaseURI to set the base URI." }
        }

    }

    end {}

}