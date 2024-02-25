---
external help file: PokeAPI-help.xml
grand_parent: Internal
Module Name: PokeAPI
online version: https://celerium.github.io/PokeAPI-PowerShellWrapper/site/Internal/Add-PokeBaseURI.html
parent: POST
schema: 2.0.0
title: Add-PokeBaseURI
---

# Add-PokeBaseURI

## SYNOPSIS
Sets the base URI for the Poke API connection.

## SYNTAX

```powershell
Add-PokeBaseURI [[-base_uri] <String>] [<CommonParameters>]
```

## DESCRIPTION
The Add-PokeBaseURI cmdlet sets the base URI which is later used
to construct the full URI for all API calls.

## EXAMPLES

### EXAMPLE 1
```powershell
Add-PokeBaseURI
```

The base URI will use https://pokeapi.co/api/v2/ which is Poke's default URI.

### EXAMPLE 2
```powershell
Add-PokeBaseURI -base_uri http://myapi.gateway.example.com
```

A custom API gateway of http://myapi.gateway.example.com will be used for all API calls to Poke's API.

## PARAMETERS

### -base_uri
Define the base URI for the Poke API connection using Poke's URI or a custom URI.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: Https://pokeapi.co/api/v2
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

[https://celerium.github.io/PokeAPI-PowerShellWrapper/site/Internal/Add-PokeBaseURI.html](https://celerium.github.io/PokeAPI-PowerShellWrapper/site/Internal/Add-PokeBaseURI.html)

