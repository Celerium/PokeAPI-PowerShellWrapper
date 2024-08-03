function Remove-PokeModuleSettings {
<#
    .SYNOPSIS
        Removes the stored Poke configuration folder.

    .DESCRIPTION
        The Remove-PokeModuleSettings cmdlet removes the Poke folder and its files.
        This cmdlet also has the option to remove sensitive Poke variables as well.

        By default configuration files are stored in the following location and will be removed:
            $env:USERPROFILE\PokeAPI

    .PARAMETER PokeConfPath
        Define the location of the Poke configuration folder.

        By default the configuration folder is located at:
            $env:USERPROFILE\PokeAPI

    .PARAMETER andVariables
        Define if sensitive Poke variables should be removed as well.

        By default the variables are not removed.

    .EXAMPLE
        Remove-PokeModuleSettings

        Checks to see if the default configuration folder exists and removes it if it does.

        The default location of the Poke configuration folder is:
            $env:USERPROFILE\PokeAPI

    .EXAMPLE
        Remove-PokeModuleSettings -PokeConfPath C:\PokeAPI -andVariables

        Checks to see if the defined configuration folder exists and removes it if it does.
        If sensitive Poke variables exist then they are removed as well.

        The location of the Poke configuration folder in this example is:
            C:\PokeAPI

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/Internal/Remove-PokeModuleSettings.html
#>

    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'set')]
    Param (
        [Parameter(ParameterSetName = 'set')]
        [string]$PokeConfPath = $(Join-Path -Path $home -ChildPath $(if ($IsWindows -or $PSEdition -eq 'Desktop'){"PokeAPI"}else{".PokeAPI"}) ),

        [Parameter(ParameterSetName = 'set')]
        [switch]$andVariables
    )

    begin {}

    process {

        if (Test-Path $PokeConfPath) {

            Remove-Item -Path $PokeConfPath -Recurse -Force -WhatIf:$WhatIfPreference

            If ($andVariables) {
                Remove-PokeBaseURI
            }

            if (!(Test-Path $PokeConfPath)) {
                Write-Output "The PokeAPI configuration folder has been removed successfully from [ $PokeConfPath ]"
            }
            else {
                Write-Error "The PokeAPI configuration folder could not be removed from [ $PokeConfPath ]"
            }

        }
        else {
            Write-Warning "No configuration folder found at [ $PokeConfPath ]"
        }

    }

    end {}

}