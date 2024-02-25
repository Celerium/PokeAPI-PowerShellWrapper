---
external help file: PokeAPI-help.xml
grand_parent: machine
Module Name: PokeAPI
online version: https://celerium.github.io/PokeAPI-PowerShellWrapper/site/machine/Get-PokeMachine.html
parent: GET
schema: 2.0.0
title: Get-PokeMachine
---

# Get-PokeMachine

## SYNOPSIS
Gets machines from PokeAPI

## SYNTAX

### index_ByAll (Default)
```powershell
Get-PokeMachine [-offset <Int32>] [-limit <Int32>] [-allPages] [<CommonParameters>]
```

### index_ById
```powershell
Get-PokeMachine -id <Int32> [<CommonParameters>]
```

## DESCRIPTION
The Get-PokeMachine cmdlet gets machines from PokeAPI

Machines are the representation of items that teach moves to Pokemon

They vary from version to version, so it is not certain that one specific
TM or HM corresponds to a single Machine

## EXAMPLES

### EXAMPLE 1
```powershell
Get-PokeMachine
```

Gets the first 20 machines sorted by id

### EXAMPLE 2
```powershell
Get-PokeMachine -id 1
```

Gets the machine with the defined id

### EXAMPLE 3
```powershell
Get-PokeMachine -offset 151 -limit 100
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

[https://celerium.github.io/PokeAPI-PowerShellWrapper/site/machine/Get-PokeMachine.html](https://celerium.github.io/PokeAPI-PowerShellWrapper/site/machine/Get-PokeMachine.html)

