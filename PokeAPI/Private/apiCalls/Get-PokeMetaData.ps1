function Get-PokeMetaData {
<#
    .SYNOPSIS
        Gets various Api metadata values

    .DESCRIPTION
        The Get-PokeMetaData cmdlet gets various Api metadata values from an
        Invoke-WebRequest to assist in various troubleshooting scenarios such
        as rate-limiting.

    .PARAMETER base_uri
        Define the base URI for the Poke API connection using Poke's URI or a custom URI.

        The default base URI is https://pokeapi.co/api/v2

    .EXAMPLE
        Get-PokeMetaData

        Gets various Api metadata values from an Invoke-WebRequest to assist
        in various troubleshooting scenarios such as rate-limiting.

        The default full base uri test path is:
            https://pokeapi.co/api/v2

    .EXAMPLE
        Get-PokeMetaData -base_uri http://myapi.gateway.example.com

        Gets various Api metadata values from an Invoke-WebRequest to assist
        in various troubleshooting scenarios such as rate-limiting.

        The full base uri test path in this example is:
            http://myapi.gateway.example.com/device

    .NOTES
        N\A

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/Internal/Get-PokeMetaData.html
#>

    [CmdletBinding()]
    Param (
        [parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$base_uri = $Poke_Base_URI
    )

    begin { $resource_uri = "/" }

    process {

        try {

            $Poke_Headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
            $Poke_Headers.Add("Content-Type", 'application/json')

            $rest_output = Invoke-WebRequest -method Get -uri ($base_uri + $resource_uri) -headers $Poke_Headers -ErrorAction Stop
        }
        catch {

            [PSCustomObject]@{
                Method = $_.Exception.Response.Method
                StatusCode = $_.Exception.Response.StatusCode.value__
                StatusDescription = $_.Exception.Response.StatusDescription
                Message = $_.Exception.Message
                URI = $($Poke_Base_URI + $resource_uri)
            }

        }
        finally {
            Remove-Variable -Name Poke_Headers -Force
        }

        Set-Variable -Name Test_rest_output -Value $rest_output -Scope Global -Force

        if ($rest_output){
            $data = @{}
            $data = $rest_output

            [PSCustomObject]@{
                ResponseUri             = $data.BaseResponse.ResponseUri.AbsoluteUri
                ResponsePort            = $data.BaseResponse.ResponseUri.Port
                StatusCode              = $data.StatusCode
                StatusDescription       = $data.StatusDescription
                raw                     = $data
            }
        }

    }

    end {}
}