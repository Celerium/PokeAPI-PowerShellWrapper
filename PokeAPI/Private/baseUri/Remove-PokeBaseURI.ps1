function Remove-PokeBaseURI {
<#
    .SYNOPSIS
        Removes the Poke base URI global variable.

    .DESCRIPTION
        The Remove-PokeBaseURI cmdlet removes the Poke base URI global variable.

    .EXAMPLE
        Remove-PokeBaseURI

        Removes the Poke base URI global variable.

    .NOTES
        N\A

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/Internal/Remove-PokeBaseURI.html
#>

    [cmdletbinding(SupportsShouldProcess)]
    Param ()

    begin {}

    process {

        switch ([bool]$Poke_Base_URI) {
            $true   { Remove-Variable -Name "Poke_Base_URI" -Scope global -Force }
            $false  { Write-Warning "The Poke base URI variable is not set. Nothing to remove" }
        }

    }

    end {}

}