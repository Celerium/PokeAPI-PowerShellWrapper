---
external help file: PokeAPI-help.xml
grand_parent: Internal
Module Name: PokeAPI
online version: https://celerium.github.io/PokeAPI-PowerShellWrapper/site/Internal/Import-PokeModuleSettings.html
parent: SET
schema: 2.0.0
title: Import-PokeModuleSettings
---

# Import-PokeModuleSettings

## SYNOPSIS
Imports the Poke BaseURI information to the current session.

## SYNTAX

```powershell
Import-PokeModuleSettings [-PokeConfPath <String>] [-PokeConfFile <String>] [<CommonParameters>]
```

## DESCRIPTION
The Import-PokeModuleSettings cmdlet imports the Poke BaseURI stored in the
Poke configuration file to the users current session.

By default the configuration file is stored in the following location:
    $env:USERPROFILE\PokeAPI

## EXAMPLES

### EXAMPLE 1
```powershell
Import-PokeModuleSettings
```

Validates that the configuration file created with the Export-PokeModuleSettings cmdlet exists
then imports the stored data into the current users session.

The default location of the Poke configuration file is:
    $env:USERPROFILE\PokeAPI\config.psd1

### EXAMPLE 2
```powershell
Import-PokeModuleSettings -PokeConfPath C:\PokeAPI -PokeConfFile MyConfig.psd1
```

Validates that the configuration file created with the Export-PokeModuleSettings cmdlet exists
then imports the stored data into the current users session.

The location of the Poke configuration file in this example is:
    C:\PokeAPI\MyConfig.psd1

## PARAMETERS

### -PokeConfPath
Define the location to store the Poke configuration file.

By default the configuration file is stored in the following location:
    $env:USERPROFILE\PokeAPI

```yaml
Type: String
Parameter Sets: (All)
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
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Config.psd1
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

[https://celerium.github.io/PokeAPI-PowerShellWrapper/site/Internal/Import-PokeModuleSettings.html](https://celerium.github.io/PokeAPI-PowerShellWrapper/site/Internal/Import-PokeModuleSettings.html)

