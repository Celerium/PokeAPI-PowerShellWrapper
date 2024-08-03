function Get-PokeModuleSettings {
<#
    .SYNOPSIS
        Gets the saved Poke configuration settings

    .DESCRIPTION
        The Get-PokeModuleSettings cmdlet gets the saved Poke configuration settings
        from the local system.

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

    .PARAMETER openConfFile
        Opens the Poke configuration file

    .EXAMPLE
        Get-PokeModuleSettings

        Gets the contents of the configuration file that was created with the
        Export-PokeModuleSettings

        The default location of the Poke configuration file is:
            $env:USERPROFILE\PokeAPI\config.psd1

    .EXAMPLE
        Get-PokeModuleSettings -PokeConfPath C:\PokeAPI -PokeConfFile MyConfig.psd1 -openConfFile

        Opens the configuration file from the defined location in the default editor

        The location of the Poke configuration file in this example is:
            C:\PokeAPI\MyConfig.psd1

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/Internal/Get-PokeModuleSettings.html
#>

    [CmdletBinding(DefaultParameterSetName = 'index')]
    Param (
        [Parameter(Mandatory = $false, ParameterSetName = 'index')]
        [string]$PokeConfPath = $(Join-Path -Path $home -ChildPath $(if ($IsWindows -or $PSEdition -eq 'Desktop'){"PokeAPI"}else{".PokeAPI"}) ),

        [Parameter(Mandatory = $false, ParameterSetName = 'index')]
        [String]$PokeConfFile = 'config.psd1',

        [Parameter(Mandatory = $false, ParameterSetName = 'show')]
        [Switch]$openConfFile
    )

    begin {
        $PokeConfig = Join-Path -Path $PokeConfPath -ChildPath $PokeConfFile
    }

    process {

        if ( Test-Path -Path $PokeConfig ){

            if($openConfFile){
                Invoke-Item -Path $PokeConfig
            }
            else{
                Import-LocalizedData -BaseDirectory $PokeConfPath -FileName $PokeConfFile
            }

        }
        else{
            Write-Verbose "No configuration file found at [ $PokeConfig ]"
        }

    }

    end {}

}