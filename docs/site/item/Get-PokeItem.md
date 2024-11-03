---
external help file: PokeAPI-help.xml
grand_parent: item
Module Name: PokeAPI
online version: https://celerium.github.io/PokeAPI-PowerShellWrapper/site/item/Get-PokeItem.html
parent: GET
schema: 2.0.0
title: Get-PokeItem
---

# Get-PokeItem

## SYNOPSIS
Gets items from PokeAPI

## SYNTAX

### index_ByAll (Default)
```powershell
Get-PokeItem [-offset <Int32>] [-limit <Int32>] [-allPages] [<CommonParameters>]
```

### index_ById
```powershell
Get-PokeItem -id <Int32> [<CommonParameters>]
```

### index_ByName
```powershell
Get-PokeItem -name <String> [<CommonParameters>]
```

## DESCRIPTION
The Get-PokeItem cmdlet gets items from PokeAPI

An item is an object in the games which the player can pick up,
keep in their bag, and use in some manner

They have various uses, including healing, powering up, helping catch
Pokemon, or to access a new area

## EXAMPLES

### EXAMPLE 1
```powershell
Get-PokeItem
```

Gets the first 20 items sorted by id

### EXAMPLE 2
```powershell
Get-PokeItem -id 1
```

Gets the item with the defined id

### EXAMPLE 3
```powershell
Get-PokeItem -name ditto
```

Gets the item with the defined name

### EXAMPLE 4
```powershell
Get-PokeItem -offset 151 -limit 100
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

[https://celerium.github.io/PokeAPI-PowerShellWrapper/site/item/Get-PokeItem.html](https://celerium.github.io/PokeAPI-PowerShellWrapper/site/item/Get-PokeItem.html)

