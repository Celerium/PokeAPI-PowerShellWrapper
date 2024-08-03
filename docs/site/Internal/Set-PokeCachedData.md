---
external help file: PokeAPI-help.xml
grand_parent: Internal
Module Name: PokeAPI
online version: https://celerium.github.io/PokeAPI-PowerShellWrapper/site/Internal/Set-PokeCachedData.html
parent: SET
schema: 2.0.0
title: Set-PokeCachedData
---

# Set-PokeCachedData

## SYNOPSIS
Sets cached data

## SYNTAX

```powershell
Set-PokeCachedData [-name] <String> [-timeStamp] <String> [-data] <Object> [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
The Set-PokeCachedData cmdlet sets cached data

## EXAMPLES

### EXAMPLE 1
```powershell
Set-PokeCachedData -name Celerium-PokeAPI -timestamp 2024-08-03T19:04:46Z -value $results
```

Creates a global variable to be used as a cache for returned data

## PARAMETERS

### -name
Defines the name of the variable

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -timeStamp
Defines a string DateTime value

String DateTime value Example
2024-08-03T19:04:46Z

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -data
The value to store in the cache

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
N/A

## RELATED LINKS

[https://celerium.github.io/PokeAPI-PowerShellWrapper/site/Internal/Set-PokeCachedData.html](https://celerium.github.io/PokeAPI-PowerShellWrapper/site/Internal/Set-PokeCachedData.html)

