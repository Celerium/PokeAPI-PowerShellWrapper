function Import-PokeModuleSettings {
<#
    .SYNOPSIS
        Imports the Poke BaseURI information to the current session.

    .DESCRIPTION
        The Import-PokeModuleSettings cmdlet imports the Poke BaseURI stored in the
        Poke configuration file to the users current session.

        By default the configuration file is stored in the following location:
            $env:USERPROFILE\PokeAPI

    .PARAMETER PokeConfPath
        Define the location to store the Poke configuration file.

        By default the configuration file is stored in the following location:
            $env:USERPROFILE\PokeAPI

    .PARAMETER PokeConfFile
        Define the name of the Poke configuration file.

        By default the configuration file is named:
            config.psd1

    .EXAMPLE
        Import-PokeModuleSettings

        Validates that the configuration file created with the Export-PokeModuleSettings cmdlet exists
        then imports the stored data into the current users session.

        The default location of the Poke configuration file is:
            $env:USERPROFILE\PokeAPI\config.psd1

    .EXAMPLE
        Import-PokeModuleSettings -PokeConfPath C:\PokeAPI -PokeConfFile MyConfig.psd1

        Validates that the configuration file created with the Export-PokeModuleSettings cmdlet exists
        then imports the stored data into the current users session.

        The location of the Poke configuration file in this example is:
            C:\PokeAPI\MyConfig.psd1

    .NOTES
        N\A

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/Internal/Import-PokeModuleSettings.html
#>

    [CmdletBinding(DefaultParameterSetName = 'set')]
    Param (
        [Parameter(ParameterSetName = 'set')]
        [string]$PokeConfPath = $(Join-Path -Path $home -ChildPath $(if ($IsWindows -or $PSEdition -eq 'Desktop'){"PokeAPI"}else{".PokeAPI"}) ),

        [Parameter(ParameterSetName = 'set')]
        [string]$PokeConfFile = 'config.psd1'
    )

    begin {
        $PokeConfig = Join-Path -Path $PokeConfPath -ChildPath $PokeConfFile
    }

    process {

        if ( Test-Path $PokeConfig ) {
            $tmp_config = Import-LocalizedData -BaseDirectory $PokeConfPath -FileName $PokeConfFile

            # Send to function to strip potentially superfluous slash (/)
            Add-PokeBaseURI $tmp_config.Poke_Base_URI

            Write-Verbose "PokeAPI Module configuration loaded successfully from [ $PokeConfig ]"

            # Clean things up
            Remove-Variable "tmp_config"
        }
        else {
            Write-Verbose "No configuration file found at [ $PokeConfig ] run Add-PokeAPIKey to get started."

            Add-PokeBaseURI

            Set-Variable -Name "Poke_Base_URI" -Value $(Get-PokeBaseURI) -Option ReadOnly -Scope global -Force
        }

    }

    end {}

}