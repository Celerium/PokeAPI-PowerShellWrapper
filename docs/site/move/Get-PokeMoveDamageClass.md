---
external help file: PokeAPI-help.xml
grand_parent: move
Module Name: PokeAPI
online version: https://celerium.github.io/PokeAPI-PowerShellWrapper/site/move/Get-PokeMoveDamageClass.html
parent: GET
schema: 2.0.0
title: Get-PokeMoveDamageClass
---

# Get-PokeMoveDamageClass

## SYNOPSIS
Gets move damage classes from PokeAPI

## SYNTAX

### index_ByAll (Default)
```powershell
Get-PokeMoveDamageClass [-offset <Int32>] [-limit <Int32>] [-allPages] [-updateCache] [<CommonParameters>]
```

### index_ById
```powershell
Get-PokeMoveDamageClass -id <Int32> [-updateCache] [<CommonParameters>]
```

### index_ByName
```powershell
Get-PokeMoveDamageClass -name <String> [-updateCache] [<CommonParameters>]
```

## DESCRIPTION
The Get-PokeMoveDamageClass cmdlet gets move damage classes from PokeAPI

Damage classes moves can have, e.g.
physical, special, or non-damaging

## EXAMPLES

### EXAMPLE 1
```powershell
Get-PokeMoveDamageClass
```

Gets the first 20 move damage classes sorted by id

### EXAMPLE 2
```powershell
Get-PokeMoveDamageClass -id 1
```

Gets the move damage class with the defined id

### EXAMPLE 3
```powershell
Get-PokeMoveDamageClass -name ditto
```

Gets the move damage class with the defined name

### EXAMPLE 4
```powershell
Get-PokeMoveDamageClass -offset 151 -limit 100
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

### -updateCache
Defines if the cache is refreshed regardless of age

By default the cache is refreshed every 30min

```yaml
Type: SwitchParameter
Parameter Sets: (All)
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

[https://celerium.github.io/PokeAPI-PowerShellWrapper/site/move/Get-PokeMoveDamageClass.html](https://celerium.github.io/PokeAPI-PowerShellWrapper/site/move/Get-PokeMoveDamageClass.html)

