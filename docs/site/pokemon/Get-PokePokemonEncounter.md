---
external help file: PokeAPI-help.xml
grand_parent: pokemon
Module Name: PokeAPI
online version: https://celerium.github.io/PokeAPI-PowerShellWrapper/site/pokemon/Get-PokePokemonEncounter.html
parent: GET
schema: 2.0.0
title: Get-PokePokemonEncounter
---

# Get-PokePokemonEncounter

## SYNOPSIS
Gets pokemon location areas from PokeAPI

## SYNTAX

### index_ById (Default)
```powershell
Get-PokePokemonEncounter -id <Int32> [<CommonParameters>]
```

### index_ByName
```powershell
Get-PokePokemonEncounter -name <String> [<CommonParameters>]
```

## DESCRIPTION
The Get-PokePokemonEncounter cmdlet gets pokemon location areas from PokeAPI

Pokemon Location Areas are ares where Pokemon can be found

## EXAMPLES

### EXAMPLE 1
```powershell
Get-PokePokemonEncounter -id 1
```

Gets the pokemon location area with the defined id

### EXAMPLE 2
```powershell
Get-PokePokemonEncounter -name ditto
```

Gets the pokemon location area with the defined name

## PARAMETERS

### -id
Defines id of the resource

```yaml
Type: Int32
Parameter Sets: index_ById
Aliases:

Required: True
Position: Named
Default value: 0
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -name
Defines name of the resource

```yaml
Type: String
Parameter Sets: index_ByName
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
n/a

## RELATED LINKS

[https://celerium.github.io/PokeAPI-PowerShellWrapper/site/pokemon/Get-PokePokemonEncounter.html](https://celerium.github.io/PokeAPI-PowerShellWrapper/site/pokemon/Get-PokePokemonEncounter.html)

