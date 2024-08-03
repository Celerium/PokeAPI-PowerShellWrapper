---
external help file: PokeAPI-help.xml
grand_parent: Internal
Module Name: PokeAPI
online version: https://celerium.github.io/PokeAPI-PowerShellWrapper/site/Internal/Export-PokeModuleSettings.html
parent: GET
schema: 2.0.0
title: Export-PokeModuleSettings
---

# Export-PokeModuleSettings

## SYNOPSIS
Exports the Poke BaseURI, API, & JSON configuration information to file.

## SYNTAX

```powershell
Export-PokeModuleSettings [-PokeConfPath <String>] [-PokeConfFile <String>] [<CommonParameters>]
```

## DESCRIPTION
The Export-PokeModuleSettings cmdlet exports the Poke BaseURI information to file.

## EXAMPLES

### EXAMPLE 1
```powershell
Export-PokeModuleSettings
```

Validates that the BaseURI is set then exports their values
to the current user's Poke configuration file located at:
    $env:USERPROFILE\PokeAPI\config.psd1

### EXAMPLE 2
```powershell
Export-PokeModuleSettings -PokeConfPath C:\PokeAPI -PokeConfFile MyConfig.psd1
```

Validates that the BaseURI is set then exports their values
to the current user's Poke configuration file located at:
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
N/A

## RELATED LINKS

[https://celerium.github.io/PokeAPI-PowerShellWrapper/site/Internal/Export-PokeModuleSettings.html](https://celerium.github.io/PokeAPI-PowerShellWrapper/site/Internal/Export-PokeModuleSettings.html)

