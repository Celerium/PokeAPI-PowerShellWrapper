function Invoke-PokeRequest {
<#
    .SYNOPSIS
        Makes an API request

    .DESCRIPTION
        The Invoke-PokeRequest cmdlet invokes an API request to Poke API.

        This is an internal function that is used by all public functions

        As of 2023-08 the Poke v1 API only supports GET requests

    .PARAMETER method
        Defines the type of API method to use

        Allowed values:
        'GET', 'PUT'

    .PARAMETER resource_Uri
        Defines the resource uri (url) to use when creating the API call

    .PARAMETER uri_Filter
        Used with the internal function [ ConvertTo-PokeQueryString ] to combine
        a functions parameters with the resource_Uri parameter.

        This allows for the full uri query to occur

        The full resource path is made with the following data
        $Poke_Base_URI + $resource_Uri + ConvertTo-PokeQueryString

    .PARAMETER data
        Place holder parameter to use when other methods are supported
        by the Poke v1 API

    .PARAMETER allPages
        Returns all items from an endpoint

        When using this parameter there is no need to use either the page or perPage
        parameters

    .EXAMPLE
        Invoke-PokeRequest -method GET -resource_Uri '/account' -uri_Filter $uri_Filter

        Invoke a rest method against the defined resource using any of the provided parameters

        Example:
            Name                           Value
            ----                           -----
            Method                         GET
            Uri                            https://pokeapi.co/api/v2/account?accountId=12345&details=True


    .NOTES
        N/A

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/Internal/Invoke-PokeRequest.html

#>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet('GET')]
        [String]$method = 'GET',

        [Parameter(Mandatory = $true)]
        [String]$resource_Uri,

        [Parameter(Mandatory = $false)]
        [Hashtable]$uri_Filter = $null,

        [Parameter(Mandatory = $false)]
        [Switch]$allPages

    )

    begin {}

    process {

        # Load Web assembly when needed as PowerShell Core has the assembly preloaded
        if ( !("System.Web.HttpUtility" -as [Type]) ) {
            Add-Type -Assembly System.Web
        }

        $query_string = ConvertTo-PokeQueryString -uri_Filter $uri_Filter -resource_Uri $resource_Uri

        Set-Variable -Name 'PokeAPI_queryString' -Value $query_string -Scope Global -Force

        try {

            $parameters = [ordered] @{
                "Method"    = $method
                "Uri"       = $query_string.Uri
            }

            Set-Variable -Name 'PokeAPI_invokeParameters' -Value $parameters -Scope Global -Force

            if ($allPages) {

                Write-Verbose "Gathering all items from [  $( $Poke_Base_URI + $resource_Uri ) ] "

                $page_number = 1
                $all_responseData = [System.Collections.Generic.List[object]]::new()

                do {

                    $current_page = Invoke-RestMethod @parameters -ErrorAction Stop

                    $total_Count    = $current_page.count
                    $offset         = if([bool]$current_page.next){([regex]::match($current_page.next,'(offset=[0-9]+)').Groups[1].Value) -Replace '\D+'}else{$null}
                    $limit          = if([bool]$current_page.next){([regex]::match($current_page.next,'(limit=[0-9]+)').Groups[1].Value) -Replace '\D+'}else{$null}
                    $total_pages    = if([bool]$current_page.next ){[math]::ceiling($($total_Count - $offset)/$limit + $page_number)}else{$null}

                    Write-Verbose "[ $page_number ] of [ $total_pages ] pages"

                        foreach ($item in $current_page.results) {
                            $all_responseData.add($item)
                        }

                    $parameters.Remove('Uri') > $null
                    $parameters.Add('Uri',$current_page.next)

                    $page_number++

                } while ($null -ne $current_page.next)

            }
            else{
                $api_response = Invoke-RestMethod @parameters -ErrorAction Stop
            }

        }
        catch {

            $exceptionError = $_.Exception.Message
            Write-Warning 'The [ Poke_invokeParameters, Poke_queryString, & Poke_CmdletNameParameters ] variables can provide extra details'

            switch -Wildcard ($exceptionError) {
                '*404*' { Write-Error "Invoke-PokeRequest : [ $resource_Uri ] not found!" }
                '*429*' { Write-Error 'Invoke-PokeRequest : API rate limited' }
                '*504*' { Write-Error "Invoke-PokeRequest : Gateway Timeout" }
                default { Write-Error $_ }
            }

        }
        finally {}


        if($allPages) {

            Set-Variable -Name Test_all_responseData -Value $all_responseData -Scope Global -Force

            #Making output consistent
            if( [string]::IsNullOrEmpty($all_responseData) ) {
                $api_response = $null
            }
            else{
                $api_response = [PSCustomObject]@{
                    count       = $total_Count
                    next        = $null
                    previous    = $null
                    results     = $all_responseData
                }
            }

            return $api_response

        }
        else{ return $api_response }

    }

    end {}

}