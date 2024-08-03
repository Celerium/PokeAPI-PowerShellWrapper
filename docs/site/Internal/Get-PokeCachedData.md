---
external help file: PokeAPI-help.xml
grand_parent: Internal
Module Name: PokeAPI
online version: https://celerium.github.io/PokeAPI-PowerShellWrapper/site/Internal/Get-PokeCachedData.html
parent: GET
schema: 2.0.0
title: Get-PokeCachedData
---

# Get-PokeCachedData

## SYNOPSIS
Gets cached data

## SYNTAX

### cached_ByAll (Default)
```powershell
Get-PokeCachedData -cachedDataName <String> [<CommonParameters>]
```

### cached_ById
```powershell
Get-PokeCachedData -cachedDataName <String> [-id <Int32>] [<CommonParameters>]
```

### cached_ByName
```powershell
Get-PokeCachedData -cachedDataName <String> [-name <String>] [<CommonParameters>]
```

## DESCRIPTION
The Get-PokeCachedData cmdlet gets cached data

## EXAMPLES

### EXAMPLE 1
```powershell
Get-PokeCachedData
```

Returns cached multi-object results and is commonly used when
all data is returned instead of a single id or name

### EXAMPLE 2
```powershell
Get-PokeCachedData -id 1
```

Returns cached single-object result

## PARAMETERS

### -cachedDataName
Defines the cached variable name to get

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -id
Defines id to search for in the cache

```yaml
Type: Int32
Parameter Sets: cached_ById
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -name
Defines name to search for in the cache

```yaml
Type: String
Parameter Sets: cached_ByName
Aliases:

Required: False
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
N/A

## RELATED LINKS

[https://celerium.github.io/PokeAPI-PowerShellWrapper/site/Internal/Get-PokeCachedData.html](https://celerium.github.io/PokeAPI-PowerShellWrapper/site/Internal/Get-PokeCachedData.html)

