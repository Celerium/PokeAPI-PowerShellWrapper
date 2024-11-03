---
external help file: PokeAPI-help.xml
grand_parent: Internal
Module Name: PokeAPI
online version: https://celerium.github.io/PokeAPI-PowerShellWrapper/site/Internal/Get-PokeMetaData.html
parent: GET
schema: 2.0.0
title: Get-PokeMetaData
---

# Get-PokeMetaData

## SYNOPSIS
Gets various Api metadata values

## SYNTAX

```powershell
Get-PokeMetaData [[-base_uri] <String>] [<CommonParameters>]
```

## DESCRIPTION
The Get-PokeMetaData cmdlet gets various Api metadata values from an
Invoke-WebRequest to assist in various troubleshooting scenarios such
as rate-limiting.

## EXAMPLES

### EXAMPLE 1
```powershell
Get-PokeMetaData
```

Gets various Api metadata values from an Invoke-WebRequest to assist
in various troubleshooting scenarios such as rate-limiting.

The default full base uri test path is:
    https://pokeapi.co/api/v2

### EXAMPLE 2
```powershell
Get-PokeMetaData -base_uri http://myapi.gateway.example.com
```

Gets various Api metadata values from an Invoke-WebRequest to assist
in various troubleshooting scenarios such as rate-limiting.

The full base uri test path in this example is:
    http://myapi.gateway.example.com/device

## PARAMETERS

### -base_uri
Define the base URI for the Poke API connection using Poke's URI or a custom URI.

The default base URI is https://pokeapi.co/api/v2

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: $Poke_Base_URI
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
N\A

## RELATED LINKS

[https://celerium.github.io/PokeAPI-PowerShellWrapper/site/Internal/Get-PokeMetaData.html](https://celerium.github.io/PokeAPI-PowerShellWrapper/site/Internal/Get-PokeMetaData.html)

