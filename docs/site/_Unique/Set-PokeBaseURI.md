---
external help file: PokeAPI-help.xml
grand_parent: _Unique
Module Name: PokeAPI
online version: https://celerium.github.io/PokeAPI-PowerShellWrapper/site/_Unique/Set-PokeBaseURI.html
parent: Special
schema: 2.0.0
title: Set-PokeBaseURI
---

# Set-PokeBaseURI

## SYNOPSIS
Sets the base URI for the Poke API connection.

## SYNTAX

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
N\A

## RELATED LINKS

[https://celerium.github.io/PokeAPI-PowerShellWrapper/site/Internal/Add-PokeBaseURI.html](https://celerium.github.io/PokeAPI-PowerShellWrapper/site/Internal/Add-PokeBaseURI.html)

