---
external help file: PokeAPI-help.xml
grand_parent: evolution
Module Name: PokeAPI
online version: https://celerium.github.io/PokeAPI-PowerShellWrapper/site/evolution/Get-PokeEvolutionTrigger.html
parent: GET
schema: 2.0.0
title: Get-PokeEvolutionTrigger
---

# Get-PokeEvolutionTrigger

## SYNOPSIS
Gets evolution triggers from PokeAPI

## SYNTAX

### index_ByAll (Default)
```powershell
Get-PokeEvolutionTrigger [-offset <Int32>] [-limit <Int32>] [-allPages] [<CommonParameters>]
```

### index_ById
```powershell
Get-PokeEvolutionTrigger -id <Int32> [<CommonParameters>]
```

### index_ByName
```powershell
Get-PokeEvolutionTrigger -name <String> [<CommonParameters>]
```

## DESCRIPTION
The Get-PokeEvolutionTrigger cmdlet gets evolution triggers from PokeAPI

Evolution triggers are the events and conditions that cause a Pokemon to evolve

## EXAMPLES

### EXAMPLE 1
```powershell
Get-PokeEvolutionTrigger
```

Gets the first 20 evolution triggers sorted by id

### EXAMPLE 2
```powershell
Get-PokeEvolutionTrigger -id 1
```

Gets the evolution trigger with the defined id

### EXAMPLE 3
```powershell
Get-PokeEvolutionTrigger -name ditto
```

Gets the evolution trigger with the defined name

### EXAMPLE 4
```powershell
Get-PokeEvolutionTrigger -offset 151 -limit 100
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

[https://celerium.github.io/PokeAPI-PowerShellWrapper/site/evolution/Get-PokeEvolutionTrigger.html](https://celerium.github.io/PokeAPI-PowerShellWrapper/site/evolution/Get-PokeEvolutionTrigger.html)

