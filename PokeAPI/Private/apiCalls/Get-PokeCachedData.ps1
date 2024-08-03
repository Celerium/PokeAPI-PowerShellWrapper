function Get-PokeCachedData {
<#
    .SYNOPSIS
        Gets cached data

    .DESCRIPTION
        The Get-PokeCachedData cmdlet gets cached data

    .PARAMETER cachedDataName
        Defines the cached variable name to get

    .PARAMETER id
        Defines id to search for in the cache

    .PARAMETER name
        Defines name to search for in the cache

    .EXAMPLE
        Get-PokeCachedData

        Returns cached multi-object results and is commonly used when
        all data is returned instead of a single id or name

    .EXAMPLE
        Get-PokeCachedData -id 1

        Returns cached single-object result

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/Internal/Get-PokeCachedData.html
#>

    [CmdletBinding(DefaultParameterSetName = 'cached_ByAll')]
    Param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$cachedDataName,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'cached_ById')]
        [ValidateRange(1, [Int]::MaxValue)]
        [int]$id,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'cached_ByName')]
        [ValidateNotNullOrEmpty()]
        [string]$name
    )

    begin {

        $functionName   = $MyInvocation.InvocationName

        $cachedData     = Get-Variable -Name $cachedDataName -ErrorAction SilentlyContinue
        if ($cachedData){
            $staleCache = ( $cachedData.Description -le [DateTime]::UtcNow.AddMinutes(-30).ToString("yyyy-MM-ddTHH:mm:ssZ") )
        }

    }

    process {

        Write-Verbose "Running [ $functionName ] with [ $($PSCmdlet.ParameterSetName) ] parameterSet"

        Set-Variable -name "$($functionName + '_Stage1' -replace '-','_')" -Value $cachedData -Scope Global -Force
        Set-Variable -name "$($functionName + '_StaleCache' -replace '-','_')" -Value $staleCache -Scope Global -Force

        switch ($PSCmdlet.ParameterSetName) {
            'cached_ByAll' {

                if ([bool]$cachedData.Value.Results -and $staleCache -eq $false) {
                    $results = $cachedData.Value
                }

            }
            'cached_ById'    {

                if ($cachedData.Value.id -eq $id -and $staleCache -eq $false) {
                    $results = $cachedData.Value
                }

            }
            'cached_ByName'  {

                if ($cachedData.Value.name -eq $name -and $staleCache -eq $false) {
                    $results = $cachedData.Value
                }

            }

        }

        if ($results) {
            $results | Add-Member -NotePropertyName staleCache -NotePropertyValue $staleCache -Force
            $results | Add-Member -NotePropertyName cachedTime -NotePropertyValue $cachedData.Description -Force
        }

        Set-Variable -name "$($functionName + '_Stage2' -replace '-','_')" -Value $results -Scope Global -Force

        return $results

    }

    end {}
}