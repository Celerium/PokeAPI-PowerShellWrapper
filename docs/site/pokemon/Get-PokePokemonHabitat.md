---
external help file: PokeAPI-help.xml
grand_parent: pokemon
Module Name: PokeAPI
online version: https://celerium.github.io/PokeAPI-PowerShellWrapper/site/pokemon/Get-PokePokemonHabitat.html
parent: GET
schema: 2.0.0
title: Get-PokePokemonHabitat
---

# Get-PokePokemonHabitat

## SYNOPSIS
Gets pokemon habitats from PokeAPI

## SYNTAX

### index_ByAll (Default)
```powershell
Get-PokePokemonHabitat [-offset <Int32>] [-limit <Int32>] [-allPages] [<CommonParameters>]
```

### index_ById
```powershell
Get-PokePokemonHabitat -id <Int32> [<CommonParameters>]
```

### index_ByName
```powershell
Get-PokePokemonHabitat -name <String> [<CommonParameters>]
```

## DESCRIPTION
The Get-PokePokemonHabitat cmdlet gets pokemon habitats from PokeAPI

Habitats are generally different terrain Pokemon can be found
in but can also be areas designated for rare or legendary Pokemon.

## EXAMPLES

### EXAMPLE 1
```powershell
Get-PokePokemonHabitat
```

Gets the first 20 pokemon habitats sorted by id

### EXAMPLE 2
```powershell
Get-PokePokemonHabitat -id 1
```

Gets the pokemon habitat with the defined id

### EXAMPLE 3
```powershell
Get-PokePokemonHabitat -name ditto
```

Gets the pokemon habitat with the defined name

### EXAMPLE 4
```powershell
Get-PokePokemonHabitat -offset 151 -limit 100
```

Gets the first 100 resources starting at resources with
an id over 151

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

### -offset
Defines the page number to return

By default only 20 resources are returned

```yaml
Type: Int32
Parameter Sets: index_ByAll
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -limit
Defines the amount of resources to return with each page

By default only 20 resources are returned

```yaml
Type: Int32
Parameter Sets: index_ByAll
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -allPages
Returns all resources from an endpoint

As of 2024-02, there is no cap on how many resources can be
returned using the limit parameter.
There is currently no real
use for this parameter and it was included simply to account if
pagination is introduced.

```yaml
Type: SwitchParameter
Parameter Sets: index_ByAll
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
n/a

## RELATED LINKS

[https://celerium.github.io/PokeAPI-PowerShellWrapper/site/pokemon/Get-PokePokemonHabitat.html](https://celerium.github.io/PokeAPI-PowerShellWrapper/site/pokemon/Get-PokePokemonHabitat.html)

