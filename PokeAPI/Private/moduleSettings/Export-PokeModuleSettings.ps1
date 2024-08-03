function Export-PokeModuleSettings {
<#
    .SYNOPSIS
        Exports the Poke BaseURI, API, & JSON configuration information to file.

    .DESCRIPTION
        The Export-PokeModuleSettings cmdlet exports the Poke BaseURI information to file.

    .PARAMETER PokeConfPath
        Define the location to store the Poke configuration file.

        By default the configuration file is stored in the following location:
            $env:USERPROFILE\PokeAPI

    .PARAMETER PokeConfFile
        Define the name of the Poke configuration file.

        By default the configuration file is named:
            config.psd1

    .EXAMPLE
        Export-PokeModuleSettings

        Validates that the BaseURI is set then exports their values
        to the current user's Poke configuration file located at:
            $env:USERPROFILE\PokeAPI\config.psd1

    .EXAMPLE
        Export-PokeModuleSettings -PokeConfPath C:\PokeAPI -PokeConfFile MyConfig.psd1

        Validates that the BaseURI is set then exports their values
        to the current user's Poke configuration file located at:
            C:\PokeAPI\MyConfig.psd1

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/Internal/Export-PokeModuleSettings.html
#>

    [CmdletBinding(DefaultParameterSetName = 'set')]
    Param (
        [Parameter(ParameterSetName = 'set')]
        [string]$PokeConfPath = $(Join-Path -Path $home -ChildPath $(if ($IsWindows -or $PSEdition -eq 'Desktop'){"PokeAPI"}else{".PokeAPI"}) ),

        [Parameter(ParameterSetName = 'set')]
        [string]$PokeConfFile = 'config.psd1'
    )

    begin {}

    process {

        $PokeConfig = Join-Path -Path $PokeConfPath -ChildPath $PokeConfFile

        # Confirm variables exist and are not null before exporting
        if ($Poke_Base_URI) {

            if ($IsWindows -or $PSEdition -eq 'Desktop') {
                New-Item -Path $PokeConfPath -ItemType Directory -Force | ForEach-Object { $_.Attributes = $_.Attributes -bor "Hidden" }
            }
            else{
                New-Item -Path $PokeConfPath -ItemType Directory -Force
            }
@"
    @{
        Poke_Base_URI = '$Poke_Base_URI'
    }
"@ | Out-File -FilePath $PokeConfig -Force
        }
        else {
            Write-Error "Failed to export Poke Module settings to [ $PokeConfig ]"
            Write-Error $_
            exit 1
        }

    }

    end {}

}