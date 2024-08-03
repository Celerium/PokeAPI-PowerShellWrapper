function Set-PokeCachedData {
<#
    .SYNOPSIS
        Sets cached data

    .DESCRIPTION
        The Set-PokeCachedData cmdlet sets cached data

    .PARAMETER name
        Defines the name of the variable

    .PARAMETER timeStamp
        Defines a string DateTime value

        String DateTime value Example
        2024-08-03T19:04:46Z

    .PARAMETER data
        The value to store in the cache

    .EXAMPLE
        Set-PokeCachedData -name Celerium-PokeAPI -timestamp 2024-08-03T19:04:46Z -value $results

        Creates a global variable to be used as a cache for returned data

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/Internal/Set-PokeCachedData.html
#>

    [CmdletBinding(SupportsShouldProcess)]
    Param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$name,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$timeStamp,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Object]$data
    )

    begin {

        $functionName   = $MyInvocation.InvocationName
        $parameterName  = $functionName + '_Parameters' -replace '-','_'

    }

    process {

        Write-Verbose "Running [ $functionName ] with [ $($PSCmdlet.ParameterSetName) ] parameterSet"
        Set-Variable -Name $parameterName -Value $PSBoundParameters -Scope Global -Force

        Set-Variable -Name $name -Description $timeStamp -Value $data -Scope Global -Force

    }

    end {}
}