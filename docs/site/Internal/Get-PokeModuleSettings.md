---
external help file: PokeAPI-help.xml
grand_parent: Internal
Module Name: PokeAPI
online version: https://celerium.github.io/PokeAPI-PowerShellWrapper/site/Internal/Get-PokeModuleSettings.html
parent: GET
schema: 2.0.0
title: Get-PokeModuleSettings
---

# Get-PokeModuleSettings

## SYNOPSIS
Gets the saved Poke configuration settings

## SYNTAX

### index (Default)
```powershell
Get-PokeModuleSettings [-PokeConfPath <String>] [-PokeConfFile <String>] [<CommonParameters>]
```

### show
```powershell
Get-PokeModuleSettings [-openConfFile] [<CommonParameters>]
```

## DESCRIPTION
The Get-PokeModuleSettings cmdlet gets the saved Poke configuration settings
from the local system.

By default the configuration file is stored in the following location:
    $env:USERPROFILE\PokeAPI

## EXAMPLES

### EXAMPLE 1
```powershell
Get-PokeModuleSettings
```

Gets the contents of the configuration file that was created with the
Export-PokeModuleSettings

The default location of the Poke configuration file is:
    $env:USERPROFILE\PokeAPI\config.psd1

### EXAMPLE 2
```powershell
Get-PokeModuleSettings -PokeConfPath C:\PokeAPI -PokeConfFile MyConfig.psd1 -openConfFile
```

Opens the configuration file from the defined location in the default editor

The location of the Poke configuration file in this example is:
    C:\PokeAPI\MyConfig.psd1

## PARAMETERS

### -PokeConfPath
Define the location to store the Poke configuration file.

By default the configuration file is stored in the following location:
    $env:USERPROFILE\PokeAPI

```yaml
Type: String
Parameter Sets: index
Aliases:

Required: False
Position: Named
Default value: $(Join-Path -Path $home -ChildPath $(if ($IsWindows -or $PSEdition -eq 'Desktop'){"PokeAPI"}else{".PokeAPI"}) )
Accept pipeline input: False
Accept wildcard characters: False
```

### -PokeConfFile
Define the name of the Poke configuration file.

By default the configuration file is named:
    config.psd1

```yaml
Type: String
Parameter Sets: index
Aliases:

Required: False
Position: Named
Default value: Config.psd1
Accept pipeline input: False
Accept wildcard characters: False
```

### -openConfFile
Opens the Poke configuration file

```yaml
Type: SwitchParameter
Parameter Sets: show
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
N\A

## RELATED LINKS

[https://celerium.github.io/PokeAPI-PowerShellWrapper/site/Internal/Get-PokeModuleSettings.html](https://celerium.github.io/PokeAPI-PowerShellWrapper/site/Internal/Get-PokeModuleSettings.html)

