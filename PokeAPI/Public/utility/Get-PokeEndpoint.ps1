function Get-PokeEndpoint {
<#
    .SYNOPSIS
        Gets endpoints from PokeAPI

    .DESCRIPTION
        The Get-PokeEndpoint cmdlet gets endpoints from PokeAPI


    .EXAMPLE
        Get-PokeEndpoint

        Gets the endpoints from PokeAPI

    .NOTES
        n/a

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/utility/Get-PokeEndpoint.html
#>

    [CmdletBinding()]
    Param ()

    begin {
        $PokeAPI_Endpoints = [System.Collections.Generic.List[object]]::new()
    }

    process {

        $invoke_Request = Invoke-RestMethod -Uri "$Poke_Base_URI/"

        foreach ($property in  $invoke_Request.PSObject.Properties) {

            $data = [PSCustomObject]@{
                name    = $property.name
                url     = $property.value
            }

            $PokeAPI_Endpoints.add($data)

        }

        $PokeAPI_Endpoints

    }

    end {}

}
