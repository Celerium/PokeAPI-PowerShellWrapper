#Region '.\Private\apiCalls\ConvertTo-PokeQueryString.ps1' -1

function ConvertTo-PokeQueryString {
<#
    .SYNOPSIS
        Converts uri filter parameters

    .DESCRIPTION
        The Invoke-PokeRequest cmdlet converts & formats uri filter parameters
        from a function which are later used to make the full resource uri for
        an API call

        This is an internal helper function the ties in directly with the
        Invoke-PokeRequest & any public functions that define parameters

    .PARAMETER uri_Filter
        Hashtable of values to combine a functions parameters with
        the resource_Uri parameter.

        This allows for the full uri query to occur

    .PARAMETER resource_Uri
        Defines the short resource uri (url) to use when creating the API call

    .EXAMPLE
        ConvertTo-PokeQueryString -uri_Filter $uri_Filter -resource_Uri '/account'

        Example: (From public function)
            $uri_Filter = @{}

            ForEach ( $Key in $PSBoundParameters.GetEnumerator() ){
                if( $excludedParameters -contains $Key.Key ){$null}
                else{ $uri_Filter += @{ $Key.Key = $Key.Value } }
            }

            1x key = https://pokeapi.co/api/v2/account?accountId=12345
            2x key = https://pokeapi.co/api/v2/account?accountId=12345&details=True

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/Internal/ConvertTo-PokeQueryString.html

#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [hashtable]$uri_Filter,

    [Parameter(Mandatory = $true)]
    [String]$resource_Uri
)

    begin {}

    process {

        if (-not $uri_Filter) {
            return ""
        }

        $excludedParameters =   'Debug', 'ErrorAction', 'ErrorVariable', 'InformationAction', 'InformationVariable',
                                'OutBuffer', 'OutVariable', 'PipelineVariable', 'Verbose', 'WarningAction', 'WarningVariable',
                                'allPages','updateCache',
                                'id', 'name'

        $query_Parameters = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)

        ForEach ( $Key in $uri_Filter.GetEnumerator() ){

            if( $excludedParameters -contains $Key.Key ){$null}
            elseif ( $Key.Value.GetType().IsArray ){
                Write-Verbose "[ $($Key.Key) ] is an array parameter"
                foreach ($Value in $Key.Value) {
                    #$ParameterName = $Key.Key
                    $query_Parameters.Add($Key.Key, $Value)
                }
            }
            else{
                $query_Parameters.Add($Key.Key, $Key.Value)
            }

        }

        # Build the request and load it with the query string.
        $uri_Request        = [System.UriBuilder]($Poke_Base_URI + $resource_Uri)
        $uri_Request.Query  = $query_Parameters.ToString()

        return $uri_Request

    }

    end {}

}
#EndRegion '.\Private\apiCalls\ConvertTo-PokeQueryString.ps1' 96
#Region '.\Private\apiCalls\Get-PokeCachedData.ps1' -1

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
#EndRegion '.\Private\apiCalls\Get-PokeCachedData.ps1' 107
#Region '.\Private\apiCalls\Get-PokeMetaData.ps1' -1

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
        N/A

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/Internal/Get-PokeMetaData.html
#>

    [CmdletBinding()]
    Param (
        [parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$base_uri = $Poke_Base_URI
    )

    begin { $resource_uri   = "/" }

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
#EndRegion '.\Private\apiCalls\Get-PokeMetaData.ps1' 92
#Region '.\Private\apiCalls\Invoke-PokeRequest.ps1' -1

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
#EndRegion '.\Private\apiCalls\Invoke-PokeRequest.ps1' 178
#Region '.\Private\apiCalls\Set-PokeCachedData.ps1' -1

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
#EndRegion '.\Private\apiCalls\Set-PokeCachedData.ps1' 66
#Region '.\Private\baseUri\Add-PokeBaseURI.ps1' -1

function Add-PokeBaseURI {
<#
    .SYNOPSIS
        Sets the base URI for the Poke API connection.

    .DESCRIPTION
        The Add-PokeBaseURI cmdlet sets the base URI which is later used
        to construct the full URI for all API calls.

    .PARAMETER base_uri
        Define the base URI for the Poke API connection using Poke's URI or a custom URI.

    .EXAMPLE
        Add-PokeBaseURI

        The base URI will use https://pokeapi.co/api/v2/ which is Poke's default URI.

    .EXAMPLE
        Add-PokeBaseURI -base_uri http://myapi.gateway.example.com

        A custom API gateway of http://myapi.gateway.example.com will be used for all API calls to Poke's API.

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/Internal/Add-PokeBaseURI.html
#>

    [cmdletbinding()]
    Param (
        [Parameter(Mandatory = $false , ValueFromPipeline = $true)]
        [string]$base_uri = 'https://pokeapi.co/api/v2'
    )

    begin {}

    process {

        # Trim superfluous forward slash from address (if applicable)
        if ($base_uri[$base_uri.Length-1] -eq "/") {
            $base_uri = $base_uri.Substring(0,$base_uri.Length-1)
        }

        Set-Variable -Name "Poke_Base_URI" -Value $base_uri -Option ReadOnly -Scope global -Force

    }

    end {}

}

New-Alias -Name Set-PokeBaseURI -Value Add-PokeBaseURI
#EndRegion '.\Private\baseUri\Add-PokeBaseURI.ps1' 54
#Region '.\Private\baseUri\Get-PokeBaseURI.ps1' -1

function Get-PokeBaseURI {
<#
    .SYNOPSIS
        Shows the Poke base URI global variable.

    .DESCRIPTION
        The Get-PokeBaseURI cmdlet shows the Poke base URI global variable value.

    .EXAMPLE
        Get-PokeBaseURI

        Shows the Poke base URI global variable value.

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/Internal/Get-PokeBaseURI.html
#>

    [cmdletbinding()]
    Param ()

    begin {}

    process {

        switch ([bool]$Poke_Base_URI) {
            $true   { $Poke_Base_URI }
            $false  { Write-Warning "The Poke base URI is not set. Run Add-PokeBaseURI to set the base URI." }
        }

    }

    end {}

}
#EndRegion '.\Private\baseUri\Get-PokeBaseURI.ps1' 38
#Region '.\Private\baseUri\Remove-PokeBaseURI.ps1' -1

function Remove-PokeBaseURI {
<#
    .SYNOPSIS
        Removes the Poke base URI global variable.

    .DESCRIPTION
        The Remove-PokeBaseURI cmdlet removes the Poke base URI global variable.

    .EXAMPLE
        Remove-PokeBaseURI

        Removes the Poke base URI global variable.

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/Internal/Remove-PokeBaseURI.html
#>

    [cmdletbinding(SupportsShouldProcess)]
    Param ()

    begin {}

    process {

        switch ([bool]$Poke_Base_URI) {
            $true   { Remove-Variable -Name "Poke_Base_URI" -Scope global -Force }
            $false  { Write-Warning "The Poke base URI variable is not set. Nothing to remove" }
        }

    }

    end {}

}
#EndRegion '.\Private\baseUri\Remove-PokeBaseURI.ps1' 38
#Region '.\Private\moduleSettings\Export-PokeModuleSettings.ps1' -1

function Export-PokeModuleSettings {
<#
    .SYNOPSIS
        Exports the Poke BaseURI, API, & JSON configuration information to file.

    .DESCRIPTION
        The Export-PokeModuleSettings cmdlet exports the Poke BaseURI information to file.

    .PARAMETER PokeConfPath
        Define the location to store the Poke configuration file.

        By default the configuration file is stored in the following location:
            $env:USERPROFILE\PokeAPI

    .PARAMETER PokeConfFile
        Define the name of the Poke configuration file.

        By default the configuration file is named:
            config.psd1

    .EXAMPLE
        Export-PokeModuleSettings

        Validates that the BaseURI is set then exports their values
        to the current user's Poke configuration file located at:
            $env:USERPROFILE\PokeAPI\config.psd1

    .EXAMPLE
        Export-PokeModuleSettings -PokeConfPath C:\PokeAPI -PokeConfFile MyConfig.psd1

        Validates that the BaseURI is set then exports their values
        to the current user's Poke configuration file located at:
            C:\PokeAPI\MyConfig.psd1

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/Internal/Export-PokeModuleSettings.html
#>

    [CmdletBinding(DefaultParameterSetName = 'set')]
    Param (
        [Parameter(ParameterSetName = 'set')]
        [string]$PokeConfPath = $(Join-Path -Path $home -ChildPath $(if ($IsWindows -or $PSEdition -eq 'Desktop'){"PokeAPI"}else{".PokeAPI"}) ),

        [Parameter(ParameterSetName = 'set')]
        [string]$PokeConfFile = 'config.psd1'
    )

    begin {}

    process {

        $PokeConfig = Join-Path -Path $PokeConfPath -ChildPath $PokeConfFile

        # Confirm variables exist and are not null before exporting
        if ($Poke_Base_URI) {

            if ($IsWindows -or $PSEdition -eq 'Desktop') {
                New-Item -Path $PokeConfPath -ItemType Directory -Force | ForEach-Object { $_.Attributes = $_.Attributes -bor "Hidden" }
            }
            else{
                New-Item -Path $PokeConfPath -ItemType Directory -Force
            }
@"
    @{
        Poke_Base_URI = '$Poke_Base_URI'
    }
"@ | Out-File -FilePath $PokeConfig -Force
        }
        else {
            Write-Error "Failed to export Poke Module settings to [ $PokeConfig ]"
            Write-Error $_
            exit 1
        }

    }

    end {}

}
#EndRegion '.\Private\moduleSettings\Export-PokeModuleSettings.ps1' 83
#Region '.\Private\moduleSettings\Get-PokeModuleSettings.ps1' -1

function Get-PokeModuleSettings {
<#
    .SYNOPSIS
        Gets the saved Poke configuration settings

    .DESCRIPTION
        The Get-PokeModuleSettings cmdlet gets the saved Poke configuration settings
        from the local system.

        By default the configuration file is stored in the following location:
            $env:USERPROFILE\PokeAPI

    .PARAMETER PokeConfPath
        Define the location to store the Poke configuration file.

        By default the configuration file is stored in the following location:
            $env:USERPROFILE\PokeAPI

    .PARAMETER PokeConfFile
        Define the name of the Poke configuration file.

        By default the configuration file is named:
            config.psd1

    .PARAMETER openConfFile
        Opens the Poke configuration file

    .EXAMPLE
        Get-PokeModuleSettings

        Gets the contents of the configuration file that was created with the
        Export-PokeModuleSettings

        The default location of the Poke configuration file is:
            $env:USERPROFILE\PokeAPI\config.psd1

    .EXAMPLE
        Get-PokeModuleSettings -PokeConfPath C:\PokeAPI -PokeConfFile MyConfig.psd1 -openConfFile

        Opens the configuration file from the defined location in the default editor

        The location of the Poke configuration file in this example is:
            C:\PokeAPI\MyConfig.psd1

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/Internal/Get-PokeModuleSettings.html
#>

    [CmdletBinding(DefaultParameterSetName = 'index')]
    Param (
        [Parameter(Mandatory = $false, ParameterSetName = 'index')]
        [string]$PokeConfPath = $(Join-Path -Path $home -ChildPath $(if ($IsWindows -or $PSEdition -eq 'Desktop'){"PokeAPI"}else{".PokeAPI"}) ),

        [Parameter(Mandatory = $false, ParameterSetName = 'index')]
        [String]$PokeConfFile = 'config.psd1',

        [Parameter(Mandatory = $false, ParameterSetName = 'show')]
        [Switch]$openConfFile
    )

    begin {
        $PokeConfig = Join-Path -Path $PokeConfPath -ChildPath $PokeConfFile
    }

    process {

        if ( Test-Path -Path $PokeConfig ){

            if($openConfFile){
                Invoke-Item -Path $PokeConfig
            }
            else{
                Import-LocalizedData -BaseDirectory $PokeConfPath -FileName $PokeConfFile
            }

        }
        else{
            Write-Verbose "No configuration file found at [ $PokeConfig ]"
        }

    }

    end {}

}
#EndRegion '.\Private\moduleSettings\Get-PokeModuleSettings.ps1' 89
#Region '.\Private\moduleSettings\Import-PokeModuleSettings.ps1' -1

function Import-PokeModuleSettings {
<#
    .SYNOPSIS
        Imports the Poke BaseURI information to the current session.

    .DESCRIPTION
        The Import-PokeModuleSettings cmdlet imports the Poke BaseURI stored in the
        Poke configuration file to the users current session.

        By default the configuration file is stored in the following location:
            $env:USERPROFILE\PokeAPI

    .PARAMETER PokeConfPath
        Define the location to store the Poke configuration file.

        By default the configuration file is stored in the following location:
            $env:USERPROFILE\PokeAPI

    .PARAMETER PokeConfFile
        Define the name of the Poke configuration file.

        By default the configuration file is named:
            config.psd1

    .EXAMPLE
        Import-PokeModuleSettings

        Validates that the configuration file created with the Export-PokeModuleSettings cmdlet exists
        then imports the stored data into the current users session.

        The default location of the Poke configuration file is:
            $env:USERPROFILE\PokeAPI\config.psd1

    .EXAMPLE
        Import-PokeModuleSettings -PokeConfPath C:\PokeAPI -PokeConfFile MyConfig.psd1

        Validates that the configuration file created with the Export-PokeModuleSettings cmdlet exists
        then imports the stored data into the current users session.

        The location of the Poke configuration file in this example is:
            C:\PokeAPI\MyConfig.psd1

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/Internal/Import-PokeModuleSettings.html
#>

    [CmdletBinding(DefaultParameterSetName = 'set')]
    Param (
        [Parameter(ParameterSetName = 'set')]
        [string]$PokeConfPath = $(Join-Path -Path $home -ChildPath $(if ($IsWindows -or $PSEdition -eq 'Desktop'){"PokeAPI"}else{".PokeAPI"}) ),

        [Parameter(ParameterSetName = 'set')]
        [string]$PokeConfFile = 'config.psd1'
    )

    begin {
        $PokeConfig = Join-Path -Path $PokeConfPath -ChildPath $PokeConfFile
    }

    process {

        if ( Test-Path $PokeConfig ) {
            $tmp_config = Import-LocalizedData -BaseDirectory $PokeConfPath -FileName $PokeConfFile

            # Send to function to strip potentially superfluous slash (/)
            Add-PokeBaseURI $tmp_config.Poke_Base_URI

            Write-Verbose "PokeAPI Module configuration loaded successfully from [ $PokeConfig ]"

            # Clean things up
            Remove-Variable "tmp_config"
        }
        else {
            Write-Verbose "No configuration file found at [ $PokeConfig ] run Add-PokeAPIKey to get started."

            Add-PokeBaseURI

            Set-Variable -Name "Poke_Base_URI" -Value $(Get-PokeBaseURI) -Option ReadOnly -Scope global -Force
        }

    }

    end {}

}
#EndRegion '.\Private\moduleSettings\Import-PokeModuleSettings.ps1' 89
#Region '.\Private\moduleSettings\Initialize-PokeModuleSettings.ps1' -1

#Used to auto load either baseline settings or saved configurations when the module is imported
Import-PokeModuleSettings -Verbose:$false
#EndRegion '.\Private\moduleSettings\Initialize-PokeModuleSettings.ps1' 3
#Region '.\Private\moduleSettings\Remove-PokeModuleSettings.ps1' -1

function Remove-PokeModuleSettings {
<#
    .SYNOPSIS
        Removes the stored Poke configuration folder.

    .DESCRIPTION
        The Remove-PokeModuleSettings cmdlet removes the Poke folder and its files.
        This cmdlet also has the option to remove sensitive Poke variables as well.

        By default configuration files are stored in the following location and will be removed:
            $env:USERPROFILE\PokeAPI

    .PARAMETER PokeConfPath
        Define the location of the Poke configuration folder.

        By default the configuration folder is located at:
            $env:USERPROFILE\PokeAPI

    .PARAMETER andVariables
        Define if sensitive Poke variables should be removed as well.

        By default the variables are not removed.

    .EXAMPLE
        Remove-PokeModuleSettings

        Checks to see if the default configuration folder exists and removes it if it does.

        The default location of the Poke configuration folder is:
            $env:USERPROFILE\PokeAPI

    .EXAMPLE
        Remove-PokeModuleSettings -PokeConfPath C:\PokeAPI -andVariables

        Checks to see if the defined configuration folder exists and removes it if it does.
        If sensitive Poke variables exist then they are removed as well.

        The location of the Poke configuration folder in this example is:
            C:\PokeAPI

    .NOTES
        N/A

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/Internal/Remove-PokeModuleSettings.html
#>

    [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'set')]
    Param (
        [Parameter(ParameterSetName = 'set')]
        [string]$PokeConfPath = $(Join-Path -Path $home -ChildPath $(if ($IsWindows -or $PSEdition -eq 'Desktop'){"PokeAPI"}else{".PokeAPI"}) ),

        [Parameter(ParameterSetName = 'set')]
        [switch]$andVariables
    )

    begin {}

    process {

        if (Test-Path $PokeConfPath) {

            Remove-Item -Path $PokeConfPath -Recurse -Force -WhatIf:$WhatIfPreference

            If ($andVariables) {
                Remove-PokeBaseURI
            }

            if (!(Test-Path $PokeConfPath)) {
                Write-Output "The PokeAPI configuration folder has been removed successfully from [ $PokeConfPath ]"
            }
            else {
                Write-Error "The PokeAPI configuration folder could not be removed from [ $PokeConfPath ]"
            }

        }
        else {
            Write-Warning "No configuration folder found at [ $PokeConfPath ]"
        }

    }

    end {}

}
#EndRegion '.\Private\moduleSettings\Remove-PokeModuleSettings.ps1' 86
#Region '.\Public\berry\Get-PokeBerry.ps1' -1

function Get-PokeBerry {
<#
    .SYNOPSIS
        Gets berries from PokeAPI

    .DESCRIPTION
        The Get-PokeBerry cmdlet gets berries from PokeAPI

        Berries are small fruits that can provide HP and status condition restoration,
        stat enhancement, and even damage negation when eaten by Pokemon

    .PARAMETER id
        Defines id of the resource

    .PARAMETER name
        Defines name of the resource

    .PARAMETER offset
        Defines the page number to return

        By default only 20 resources are returned

    .PARAMETER limit
        Defines the amount of resources to return with each page

        By default only 20 resources are returned

    .PARAMETER allPages
        Returns all resources from an endpoint

        As of 2024-02, there is no cap on how many resources can be
        returned using the limit parameter. There is currently no real
        use for this parameter and it was included simply to account if
        pagination is introduced.

    .PARAMETER updateCache
        Defines if the cache is refreshed regardless of age

        By default the cache is refreshed every 30min

    .EXAMPLE
        Get-PokeBerry

        Gets the first 20 berries sorted by id

    .EXAMPLE
        Get-PokeBerry -id 1

        Gets the berry with the defined id

    .EXAMPLE
        Get-PokeBerry -name ditto

        Gets the berry with the defined name

    .EXAMPLE
        Get-PokeBerry -offset 151 -limit 100

        Gets the first 100 resources starting at resources with
        an id over 151

    .NOTES
        n/a

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/berry/Get-PokeBerry.html
#>

    [CmdletBinding(DefaultParameterSetName = 'index_ByAll')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ById')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$id,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ByName')]
        [ValidateNotNullOrEmpty()]
        [String]$name,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$offset,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$limit,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [Switch]$allPages,

        [Parameter(Mandatory = $false)]
        [Switch]$updateCache
    )

    begin {

        $functionName   = $MyInvocation.InvocationName
        $cachedDataName = $functionName + '_Cached' -replace '-','_'
        $parameterName  = $functionName + '_Parameters' -replace '-','_'
        $runTime        = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    }

    process {

        Write-Verbose "Running [ $functionName ] with [ $($PSCmdlet.ParameterSetName) ] parameterSet"
        Set-Variable -Name $parameterName -Value $PSBoundParameters -Scope Global -Force

        switch ( $PSCmdlet.ParameterSetName ) {

            'index_ByAll'  {
                $resource_uri   = "/berry"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName
            }
            'index_ById'   {
                $resource_uri   = "/berry/$id"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -id $id
            }
            'index_ByName' {
                $resource_uri = ("/berry/$name").ToLower()
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -name $name
            }

        }

        if ( $null -eq $cachedData -or $cachedData.staleCache -or $updateCache ) {

            if ($cachedData.staleCache) {
                Write-Verbose "Refreshing cached data: Old Timestamp [ $($cachedData.cachedTime) | New Timestamp $([DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")) ]"
            }

            $results = Invoke-PokeRequest -method GET -resource_Uri $resource_Uri -uri_Filter $PSBoundParameters -allPages:$allPages

            if ($results) {
                Set-PokeCachedData -name $cachedDataName -timeStamp $runTime -data $results
            }

        }
        else {

            Write-Verbose "Returning cached data: Cached is [ $( (New-TimeSpan -Start $cachedData.cachedTime -End $(Get-Date)).Minutes)min ] old"
            $results = $cachedData
            $results.PSObject.Properties.Remove('staleCache')
            $results.PSObject.Properties.Remove('cachedTime')

        }

        return $results

    }

    end {}

}
#EndRegion '.\Public\berry\Get-PokeBerry.ps1' 154
#Region '.\Public\berry\Get-PokeBerryFirmness.ps1' -1

function Get-PokeBerryFirmness {
<#
    .SYNOPSIS
        Gets the firmness of berries from PokeAPI

    .DESCRIPTION
        The Get-PokeBerryFirmness cmdlet gets the firmness of
        berries from PokeAPI

        Berries can be soft or hard

    .PARAMETER id
        Defines id of the resource

    .PARAMETER name
        Defines name of the resource

    .PARAMETER offset
        Defines the page number to return

        By default only 20 resources are returned

    .PARAMETER limit
        Defines the amount of resources to return with each page

        By default only 20 resources are returned

    .PARAMETER allPages
        Returns all resources from an endpoint

        As of 2024-02, there is no cap on how many resources can be
        returned using the limit parameter. There is currently no real
        use for this parameter and it was included simply to account if
        pagination is introduced.

    .PARAMETER updateCache
        Defines if the cache is refreshed regardless of age

        By default the cache is refreshed every 30min

    .EXAMPLE
        Get-PokeBerryFirmness

        Gets the first 20 berry firmness sorted by id

    .EXAMPLE
        Get-PokeBerryFirmness -id 1

        Gets the berry firmness with the defined id

    .EXAMPLE
        Get-PokeBerryFirmness -name ditto

        Gets the berry firmness with the defined name

    .EXAMPLE
        Get-PokeBerryFirmness -offset 151 -limit 100

        Gets the first 100 resources starting at resources with
        an id over 151

    .NOTES
        n/a

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/berry/Get-PokeBerryFirmness.html
#>

    [CmdletBinding(DefaultParameterSetName = 'index_ByAll')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ById')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$id,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ByName')]
        [ValidateNotNullOrEmpty()]
        [string]$name,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$offset,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$limit,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [Switch]$allPages,

        [Parameter(Mandatory = $false)]
        [Switch]$updateCache
    )

    begin {

        $functionName   = $MyInvocation.InvocationName
        $cachedDataName = $functionName + '_Cached' -replace '-','_'
        $parameterName  = $functionName + '_Parameters' -replace '-','_'
        $runTime        = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    }

    process {

        Write-Verbose "Running [ $functionName ] with [ $($PSCmdlet.ParameterSetName) ] parameterSet"
        Set-Variable -Name $parameterName -Value $PSBoundParameters -Scope Global -Force

        switch ( $PSCmdlet.ParameterSetName ) {

            'index_ByAll'  {
                $resource_uri   = "/berry-firmness"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName
            }
            'index_ById'   {
                $resource_uri   = "/berry-firmness/$id"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -id $id
            }
            'index_ByName' {
                $resource_uri = ("/berry-firmness/$name").ToLower()
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -name $name
            }

        }

        if ( $null -eq $cachedData -or $cachedData.staleCache -or $updateCache ) {

            if ($cachedData.staleCache) {
                Write-Verbose "Refreshing cached data: Old Timestamp [ $($cachedData.cachedTime) | New Timestamp [ $([DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")) ]"
            }

            $results = Invoke-PokeRequest -method GET -resource_Uri $resource_Uri -uri_Filter $PSBoundParameters -allPages:$allPages

            if ($results) {
                Set-PokeCachedData -name $cachedDataName -timeStamp $runTime -data $results
            }

        }
        else {

            Write-Verbose "Returning cached data: Cached is [ $( (New-TimeSpan -Start $cachedData.cachedTime -End $(Get-Date)).Minutes)min ] old"
            $results = $cachedData
            $results.PSObject.Properties.Remove('staleCache')
            $results.PSObject.Properties.Remove('cachedTime')

        }

        return $results

    }

    end {}

}
#EndRegion '.\Public\berry\Get-PokeBerryFirmness.ps1' 154
#Region '.\Public\berry\Get-PokeBerryFlavor.ps1' -1

function Get-PokeBerryFlavor {
<#
    .SYNOPSIS
        Gets berry flavor from PokeAPI

    .DESCRIPTION
        The Get-PokeBerryFlavor cmdlet gets berry flavor from PokeAPI

        Flavors determine whether a Pokemon will benefit or suffer
        from eating a berry based on their nature

    .PARAMETER id
        Defines id of the resource

    .PARAMETER name
        Defines name of the resource

    .PARAMETER offset
        Defines the page number to return

        By default only 20 resources are returned

    .PARAMETER limit
        Defines the amount of resources to return with each page

        By default only 20 resources are returned

    .PARAMETER allPages
        Returns all resources from an endpoint

        As of 2024-02, there is no cap on how many resources can be
        returned using the limit parameter. There is currently no real
        use for this parameter and it was included simply to account if
        pagination is introduced.

    .PARAMETER updateCache
        Defines if the cache is refreshed regardless of age

        By default the cache is refreshed every 30min

    .EXAMPLE
        Get-PokeBerryFlavor

        Gets the first 20 berry flavors sorted by id

    .EXAMPLE
        Get-PokeBerryFlavor -id 1

        Gets the berry flavor with the defined id

    .EXAMPLE
        Get-PokeBerryFlavor -name ditto

        Gets the berry flavor with the defined name

    .EXAMPLE
        Get-PokeBerryFlavor -offset 151 -limit 100

        Gets the first 100 resources starting at resources with
        an id over 151

    .NOTES
        n/a

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/berry/Get-PokeBerryFlavor.html
#>

    [CmdletBinding(DefaultParameterSetName = 'index_ByAll')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ById')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$id,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ByName')]
        [ValidateNotNullOrEmpty()]
        [string]$name,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$offset,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$limit,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [Switch]$allPages,

        [Parameter(Mandatory = $false)]
        [Switch]$updateCache
    )

    begin {

        $functionName   = $MyInvocation.InvocationName
        $cachedDataName = $functionName + '_Cached' -replace '-','_'
        $parameterName  = $functionName + '_Parameters' -replace '-','_'
        $runTime        = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    }

    process {

        Write-Verbose "Running [ $functionName ] with [ $($PSCmdlet.ParameterSetName) ] parameterSet"
        Set-Variable -Name $parameterName -Value $PSBoundParameters -Scope Global -Force

        switch ( $PSCmdlet.ParameterSetName ) {

            'index_ByAll'  {
                $resource_uri   = "/berry-flavor"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName
            }
            'index_ById'   {
                $resource_uri   = "/berry-flavor/$id"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -id $id
            }
            'index_ByName' {
                $resource_uri = ("/berry-flavor/$name").ToLower()
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -name $name
            }

        }

        if ( $null -eq $cachedData -or $cachedData.staleCache -or $updateCache ) {

            if ($cachedData.staleCache) {
                Write-Verbose "Refreshing cached data: Old Timestamp [ $($cachedData.cachedTime) | New Timestamp [ $([DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")) ]"
            }

            $results = Invoke-PokeRequest -method GET -resource_Uri $resource_Uri -uri_Filter $PSBoundParameters -allPages:$allPages

            if ($results) {
                Set-PokeCachedData -name $cachedDataName -timeStamp $runTime -data $results
            }

        }
        else {

            Write-Verbose "Returning cached data: Cached is [ $( (New-TimeSpan -Start $cachedData.cachedTime -End $(Get-Date)).Minutes)min ] old"
            $results = $cachedData
            $results.PSObject.Properties.Remove('staleCache')
            $results.PSObject.Properties.Remove('cachedTime')

        }

        return $results

    }

    end {}

}
#EndRegion '.\Public\berry\Get-PokeBerryFlavor.ps1' 154
#Region '.\Public\contest\Get-PokeContestEffect.ps1' -1

function Get-PokeContestEffect {
<#
    .SYNOPSIS
        Gets contest effects from PokeAPI

    .DESCRIPTION
        The Get-PokeContestEffect cmdlet gets contest effects from PokeAPI

        Contest effects refer to the effects of moves when used in contests

    .PARAMETER id
        Defines id of the resource

    .PARAMETER name
        Defines name of the resource

    .PARAMETER offset
        Defines the page number to return

        By default only 20 resources are returned

    .PARAMETER limit
        Defines the amount of resources to return with each page

        By default only 20 resources are returned

    .PARAMETER allPages
        Returns all resources from an endpoint

        As of 2024-02, there is no cap on how many resources can be
        returned using the limit parameter. There is currently no real
        use for this parameter and it was included simply to account if
        pagination is introduced.

    .PARAMETER updateCache
        Defines if the cache is refreshed regardless of age

        By default the cache is refreshed every 30min

    .EXAMPLE
        Get-PokeContestEffect

        Gets the first 20 contest effects sorted by id

    .EXAMPLE
        Get-PokeContestEffect -id 1

        Gets the contest effect with the defined id

    .EXAMPLE
        Get-PokeContestEffect -name ditto

        Gets the contest effect with the defined name

    .EXAMPLE
        Get-PokeContestEffect -offset 151 -limit 100

        Gets the first 100 resources starting at resources with
        an id over 151

    .NOTES
        n/a

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/contest/Get-PokeContestEffect.html
#>

    [CmdletBinding(DefaultParameterSetName = 'index_ByAll')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ById')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$id,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ByName')]
        [ValidateNotNullOrEmpty()]
        [string]$name,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$offset,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$limit,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [Switch]$allPages,

        [Parameter(Mandatory = $false)]
        [Switch]$updateCache
    )

    begin {

        $functionName   = $MyInvocation.InvocationName
        $cachedDataName = $functionName + '_Cached' -replace '-','_'
        $parameterName  = $functionName + '_Parameters' -replace '-','_'
        $runTime        = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    }

    process {

        Write-Verbose "Running [ $functionName ] with [ $($PSCmdlet.ParameterSetName) ] parameterSet"
        Set-Variable -Name $parameterName -Value $PSBoundParameters -Scope Global -Force

        switch ( $PSCmdlet.ParameterSetName ) {

            'index_ByAll'  {
                $resource_uri   = "/contest-effect"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName
            }
            'index_ById'   {
                $resource_uri   = "/contest-effect/$id"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -id $id
            }
            'index_ByName' {
                $resource_uri = ("/contest-effect/$name").ToLower()
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -name $name
            }

        }

        if ( $null -eq $cachedData -or $cachedData.staleCache -or $updateCache ) {

            if ($cachedData.staleCache) {
                Write-Verbose "Refreshing cached data: Old Timestamp [ $($cachedData.cachedTime) | New Timestamp [ $([DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")) ]"
            }

            $results = Invoke-PokeRequest -method GET -resource_Uri $resource_Uri -uri_Filter $PSBoundParameters -allPages:$allPages

            if ($results) {
                Set-PokeCachedData -name $cachedDataName -timeStamp $runTime -data $results
            }

        }
        else {

            Write-Verbose "Returning cached data: Cached is [ $( (New-TimeSpan -Start $cachedData.cachedTime -End $(Get-Date)).Minutes)min ] old"
            $results = $cachedData
            $results.PSObject.Properties.Remove('staleCache')
            $results.PSObject.Properties.Remove('cachedTime')

        }

        return $results

    }

    end {}

}
#EndRegion '.\Public\contest\Get-PokeContestEffect.ps1' 153
#Region '.\Public\contest\Get-PokeContestSuperEffect.ps1' -1

function Get-PokeContestSuperEffect {
<#
    .SYNOPSIS
        Gets super contest effects from PokeAPI

    .DESCRIPTION
        The Get-PokeContestSuperEffect cmdlet gets super contest effects
        from PokeAPI

        Super contest effects refer to the effects of moves when
        used in super contests

    .PARAMETER id
        Defines id of the resource

    .PARAMETER name
        Defines name of the resource

    .PARAMETER offset
        Defines the page number to return

        By default only 20 resources are returned

    .PARAMETER limit
        Defines the amount of resources to return with each page

        By default only 20 resources are returned

    .PARAMETER allPages
        Returns all resources from an endpoint

        As of 2024-02, there is no cap on how many resources can be
        returned using the limit parameter. There is currently no real
        use for this parameter and it was included simply to account if
        pagination is introduced.

    .PARAMETER updateCache
        Defines if the cache is refreshed regardless of age

        By default the cache is refreshed every 30min

    .EXAMPLE
        Get-PokeContestSuperEffect

        Gets the first 20 super contest effects sorted by id

    .EXAMPLE
        Get-PokeContestSuperEffect -id 1

        Gets the super contest effect with the defined id

    .EXAMPLE
        Get-PokeContestSuperEffect -name ditto

        Gets the super contest effect with the defined name

    .EXAMPLE
        Get-PokeContestSuperEffect -offset 151 -limit 100

        Gets the first 100 resources starting at resources with
        an id over 151

    .NOTES
        n/a

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/contest/Get-PokeContestSuperEffect.html
#>

    [CmdletBinding(DefaultParameterSetName = 'index_ByAll')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ById')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$id,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ByName')]
        [ValidateNotNullOrEmpty()]
        [string]$name,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$offset,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$limit,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [Switch]$allPages,

        [Parameter(Mandatory = $false)]
        [Switch]$updateCache
    )

    begin {

        $functionName   = $MyInvocation.InvocationName
        $cachedDataName = $functionName + '_Cached' -replace '-','_'
        $parameterName  = $functionName + '_Parameters' -replace '-','_'
        $runTime        = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    }

    process {

        Write-Verbose "Running [ $functionName ] with [ $($PSCmdlet.ParameterSetName) ] parameterSet"
        Set-Variable -Name $parameterName -Value $PSBoundParameters -Scope Global -Force

        switch ( $PSCmdlet.ParameterSetName ) {

            'index_ByAll'  {
                $resource_uri   = "/super-contest-effect"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName
            }
            'index_ById'   {
                $resource_uri   = "/super-contest-effect/$id"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -id $id
            }
            'index_ByName' {
                $resource_uri = ("/super-contest-effect/$name").ToLower()
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -name $name
            }

        }

        if ( $null -eq $cachedData -or $cachedData.staleCache -or $updateCache ) {

            if ($cachedData.staleCache) {
                Write-Verbose "Refreshing cached data: Old Timestamp [ $($cachedData.cachedTime) | New Timestamp [ $([DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")) ]"
            }

            $results = Invoke-PokeRequest -method GET -resource_Uri $resource_Uri -uri_Filter $PSBoundParameters -allPages:$allPages

            if ($results) {
                Set-PokeCachedData -name $cachedDataName -timeStamp $runTime -data $results
            }

        }
        else {

            Write-Verbose "Returning cached data: Cached is [ $( (New-TimeSpan -Start $cachedData.cachedTime -End $(Get-Date)).Minutes)min ] old"
            $results = $cachedData
            $results.PSObject.Properties.Remove('staleCache')
            $results.PSObject.Properties.Remove('cachedTime')

        }

        return $results

    }

    end {}

}
#EndRegion '.\Public\contest\Get-PokeContestSuperEffect.ps1' 155
#Region '.\Public\contest\Get-PokeContestType.ps1' -1

function Get-PokeContestType {
<#
    .SYNOPSIS
        Gets contest types from PokeAPI

    .DESCRIPTION
        The Get-PokeContestType cmdlet gets contest types from PokeAPI

        Contest types are categories judges used to weigh a
        Pokemon's condition in Pokemon contests.

    .PARAMETER id
        Defines id of the resource

    .PARAMETER name
        Defines name of the resource

    .PARAMETER offset
        Defines the page number to return

        By default only 20 resources are returned

    .PARAMETER limit
        Defines the amount of resources to return with each page

        By default only 20 resources are returned

    .PARAMETER allPages
        Returns all resources from an endpoint

        As of 2024-02, there is no cap on how many resources can be
        returned using the limit parameter. There is currently no real
        use for this parameter and it was included simply to account if
        pagination is introduced.

    .PARAMETER updateCache
        Defines if the cache is refreshed regardless of age

        By default the cache is refreshed every 30min

    .EXAMPLE
        Get-PokeContestType

        Gets the first 20 contest types sorted by id

    .EXAMPLE
        Get-PokeContestType -id 1

        Gets the contest type with the defined id

    .EXAMPLE
        Get-PokeContestType -name ditto

        Gets the contest type with the defined name

    .EXAMPLE
        Get-PokeContestType -offset 151 -limit 100

        Gets the first 100 resources starting at resources with
        an id over 151

    .NOTES
        n/a

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/contest/Get-PokeContestType.html
#>

    [CmdletBinding(DefaultParameterSetName = 'index_ByAll')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ById')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$id,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ByName')]
        [ValidateNotNullOrEmpty()]
        [string]$name,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$offset,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$limit,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [Switch]$allPages,

        [Parameter(Mandatory = $false)]
        [Switch]$updateCache
    )

    begin {

        $functionName   = $MyInvocation.InvocationName
        $cachedDataName = $functionName + '_Cached' -replace '-','_'
        $parameterName  = $functionName + '_Parameters' -replace '-','_'
        $runTime        = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    }

    process {

        Write-Verbose "Running [ $functionName ] with [ $($PSCmdlet.ParameterSetName) ] parameterSet"
        Set-Variable -Name $parameterName -Value $PSBoundParameters -Scope Global -Force

        switch ( $PSCmdlet.ParameterSetName ) {

            'index_ByAll'  {
                $resource_uri   = "/contest-type"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName
            }
            'index_ById'   {
                $resource_uri   = "/contest-type/$id"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -id $id
            }
            'index_ByName' {
                $resource_uri = ("/contest-type/$name").ToLower()
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -name $name
            }

        }

        if ( $null -eq $cachedData -or $cachedData.staleCache -or $updateCache ) {

            if ($cachedData.staleCache) {
                Write-Verbose "Refreshing cached data: Old Timestamp [ $($cachedData.cachedTime) | New Timestamp [ $([DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")) ]"
            }

            $results = Invoke-PokeRequest -method GET -resource_Uri $resource_Uri -uri_Filter $PSBoundParameters -allPages:$allPages

            if ($results) {
                Set-PokeCachedData -name $cachedDataName -timeStamp $runTime -data $results
            }

        }
        else {

            Write-Verbose "Returning cached data: Cached is [ $( (New-TimeSpan -Start $cachedData.cachedTime -End $(Get-Date)).Minutes)min ] old"
            $results = $cachedData
            $results.PSObject.Properties.Remove('staleCache')
            $results.PSObject.Properties.Remove('cachedTime')

        }

        return $results

    }

    end {}

}
#EndRegion '.\Public\contest\Get-PokeContestType.ps1' 154
#Region '.\Public\encounter\Get-PokeEncounterCondition.ps1' -1

function Get-PokeEncounterCondition {
<#
    .SYNOPSIS
        Gets encounter conditions from PokeAPI

    .DESCRIPTION
        The Get-PokeEncounterCondition cmdlet gets encounter conditions from PokeAPI

        Conditions which affect what pokemon might appear in the
        wild, e.g., day or night.

    .PARAMETER id
        Defines id of the resource

    .PARAMETER name
        Defines name of the resource

    .PARAMETER offset
        Defines the page number to return

        By default only 20 resources are returned

    .PARAMETER limit
        Defines the amount of resources to return with each page

        By default only 20 resources are returned

    .PARAMETER allPages
        Returns all resources from an endpoint

        As of 2024-02, there is no cap on how many resources can be
        returned using the limit parameter. There is currently no real
        use for this parameter and it was included simply to account if
        pagination is introduced.

    .PARAMETER updateCache
        Defines if the cache is refreshed regardless of age

        By default the cache is refreshed every 30min

    .EXAMPLE
        Get-PokeEncounterCondition

        Gets the first 20 encounter conditions sorted by id

    .EXAMPLE
        Get-PokeEncounterCondition -id 1

        Gets the encounter condition with the defined id

    .EXAMPLE
        Get-PokeEncounterCondition -name ditto

        Gets the encounter condition with the defined name

    .EXAMPLE
        Get-PokeEncounterCondition -offset 151 -limit 100

        Gets the first 100 resources starting at resources with
        an id over 151

    .NOTES
        n/a

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/encounter/Get-PokeEncounterCondition.html
#>

    [CmdletBinding(DefaultParameterSetName = 'index_ByAll')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ById')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$id,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ByName')]
        [ValidateNotNullOrEmpty()]
        [string]$name,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$offset,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$limit,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [Switch]$allPages,

        [Parameter(Mandatory = $false)]
        [Switch]$updateCache
    )

    begin {

        $functionName   = $MyInvocation.InvocationName
        $cachedDataName = $functionName + '_Cached' -replace '-','_'
        $parameterName  = $functionName + '_Parameters' -replace '-','_'
        $runTime        = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    }

    process {

        Write-Verbose "Running [ $functionName ] with [ $($PSCmdlet.ParameterSetName) ] parameterSet"
        Set-Variable -Name $parameterName -Value $PSBoundParameters -Scope Global -Force

        switch ( $PSCmdlet.ParameterSetName ) {

            'index_ByAll'  {
                $resource_uri   = "/encounter-condition"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName
            }
            'index_ById'   {
                $resource_uri   = "/encounter-condition/$id"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -id $id
            }
            'index_ByName' {
                $resource_uri = ("/encounter-condition/$name").ToLower()
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -name $name
            }

        }

        if ( $null -eq $cachedData -or $cachedData.staleCache -or $updateCache ) {

            if ($cachedData.staleCache) {
                Write-Verbose "Refreshing cached data: Old Timestamp [ $($cachedData.cachedTime) | New Timestamp [ $([DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")) ]"
            }

            $results = Invoke-PokeRequest -method GET -resource_Uri $resource_Uri -uri_Filter $PSBoundParameters -allPages:$allPages

            if ($results) {
                Set-PokeCachedData -name $cachedDataName -timeStamp $runTime -data $results
            }

        }
        else {

            Write-Verbose "Returning cached data: Cached is [ $( (New-TimeSpan -Start $cachedData.cachedTime -End $(Get-Date)).Minutes)min ] old"
            $results = $cachedData
            $results.PSObject.Properties.Remove('staleCache')
            $results.PSObject.Properties.Remove('cachedTime')

        }

        return $results

    }

    end {}

}
#EndRegion '.\Public\encounter\Get-PokeEncounterCondition.ps1' 154
#Region '.\Public\encounter\Get-PokeEncounterConditionValue.ps1' -1

function Get-PokeEncounterConditionValue {
<#
    .SYNOPSIS
        Gets encounter condition values from PokeAPI

    .DESCRIPTION
        The Get-PokeEncounterConditionValue cmdlet gets encounter condition values
        from PokeAPI

        Encounter condition values are the various states that an encounter
        condition can have, i.e., time of day can be either day or night.

    .PARAMETER id
        Defines id of the resource

    .PARAMETER name
        Defines name of the resource

    .PARAMETER offset
        Defines the page number to return

        By default only 20 resources are returned

    .PARAMETER limit
        Defines the amount of resources to return with each page

        By default only 20 resources are returned

    .PARAMETER allPages
        Returns all resources from an endpoint

        As of 2024-02, there is no cap on how many resources can be
        returned using the limit parameter. There is currently no real
        use for this parameter and it was included simply to account if
        pagination is introduced.

    .PARAMETER updateCache
        Defines if the cache is refreshed regardless of age

        By default the cache is refreshed every 30min

    .EXAMPLE
        Get-PokeEncounterConditionValue

        Gets the first 20 encounter condition values sorted by id

    .EXAMPLE
        Get-PokeEncounterConditionValue -id 1

        Gets the encounter condition value with the defined id

    .EXAMPLE
        Get-PokeEncounterConditionValue -name ditto

        Gets the encounter condition value with the defined name

    .EXAMPLE
        Get-PokeEncounterConditionValue -offset 151 -limit 100

        Gets the first 100 resources starting at resources with
        an id over 151

    .NOTES
        n/a

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/encounter/Get-PokeEncounterConditionValue.html
#>

    [CmdletBinding(DefaultParameterSetName = 'index_ByAll')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ById')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$id,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ByName')]
        [ValidateNotNullOrEmpty()]
        [string]$name,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$offset,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$limit,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [Switch]$allPages,

        [Parameter(Mandatory = $false)]
        [Switch]$updateCache
    )

    begin {

        $functionName   = $MyInvocation.InvocationName
        $cachedDataName = $functionName + '_Cached' -replace '-','_'
        $parameterName  = $functionName + '_Parameters' -replace '-','_'
        $runTime        = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    }

    process {

        Write-Verbose "Running [ $functionName ] with [ $($PSCmdlet.ParameterSetName) ] parameterSet"
        Set-Variable -Name $parameterName -Value $PSBoundParameters -Scope Global -Force

        switch ( $PSCmdlet.ParameterSetName ) {

            'index_ByAll'  {
                $resource_uri   = "/encounter-condition-value"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName
            }
            'index_ById'   {
                $resource_uri   = "/encounter-condition-value/$id"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -id $id
            }
            'index_ByName' {
                $resource_uri = ("/encounter-condition-value/$name").ToLower()
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -name $name
            }

        }

        if ( $null -eq $cachedData -or $cachedData.staleCache -or $updateCache ) {

            if ($cachedData.staleCache) {
                Write-Verbose "Refreshing cached data: Old Timestamp [ $($cachedData.cachedTime) | New Timestamp [ $([DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")) ]"
            }

            $results = Invoke-PokeRequest -method GET -resource_Uri $resource_Uri -uri_Filter $PSBoundParameters -allPages:$allPages

            if ($results) {
                Set-PokeCachedData -name $cachedDataName -timeStamp $runTime -data $results
            }

        }
        else {

            Write-Verbose "Returning cached data: Cached is [ $( (New-TimeSpan -Start $cachedData.cachedTime -End $(Get-Date)).Minutes)min ] old"
            $results = $cachedData
            $results.PSObject.Properties.Remove('staleCache')
            $results.PSObject.Properties.Remove('cachedTime')

        }

        return $results

    }

    end {}

}
#EndRegion '.\Public\encounter\Get-PokeEncounterConditionValue.ps1' 155
#Region '.\Public\encounter\Get-PokeEncounterMethod.ps1' -1

function Get-PokeEncounterMethod {
<#
    .SYNOPSIS
        Gets encounter methods from PokeAPI

    .DESCRIPTION
        The Get-PokeEncounterMethod cmdlet gets encounter methods from PokeAPI

        Methods by which the player might can encounter Pokemon in the wild,
        e.g., walking in tall grass

    .PARAMETER id
        Defines id of the resource

    .PARAMETER name
        Defines name of the resource

    .PARAMETER offset
        Defines the page number to return

        By default only 20 resources are returned

    .PARAMETER limit
        Defines the amount of resources to return with each page

        By default only 20 resources are returned

    .PARAMETER allPages
        Returns all resources from an endpoint

        As of 2024-02, there is no cap on how many resources can be
        returned using the limit parameter. There is currently no real
        use for this parameter and it was included simply to account if
        pagination is introduced.

    .PARAMETER updateCache
        Defines if the cache is refreshed regardless of age

        By default the cache is refreshed every 30min

    .EXAMPLE
        Get-PokeEncounterMethod

        Gets the first 20 encounter methods sorted by id

    .EXAMPLE
        Get-PokeEncounterMethod -id 1

        Gets the encounter method with the defined id

    .EXAMPLE
        Get-PokeEncounterMethod -name ditto

        Gets the encounter method with the defined name

    .EXAMPLE
        Get-PokeEncounterMethod -offset 151 -limit 100

        Gets the first 100 resources starting at resources with
        an id over 151

    .NOTES
        n/a

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/encounter/Get-PokeEncounterMethod.html
#>

    [CmdletBinding(DefaultParameterSetName = 'index_ByAll')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ById')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$id,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ByName')]
        [ValidateNotNullOrEmpty()]
        [string]$name,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$offset,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$limit,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [Switch]$allPages,

        [Parameter(Mandatory = $false)]
        [Switch]$updateCache
    )

    begin {

        $functionName   = $MyInvocation.InvocationName
        $cachedDataName = $functionName + '_Cached' -replace '-','_'
        $parameterName  = $functionName + '_Parameters' -replace '-','_'
        $runTime        = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    }

    process {

        Write-Verbose "Running [ $functionName ] with [ $($PSCmdlet.ParameterSetName) ] parameterSet"
        Set-Variable -Name $parameterName -Value $PSBoundParameters -Scope Global -Force

        switch ( $PSCmdlet.ParameterSetName ) {

            'index_ByAll'  {
                $resource_uri   = "/encounter-method"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName
            }
            'index_ById'   {
                $resource_uri   = "/encounter-method/$id"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -id $id
            }
            'index_ByName' {
                $resource_uri = ("/encounter-method/$name").ToLower()
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -name $name
            }

        }

        if ( $null -eq $cachedData -or $cachedData.staleCache -or $updateCache ) {

            if ($cachedData.staleCache) {
                Write-Verbose "Refreshing cached data: Old Timestamp [ $($cachedData.cachedTime) | New Timestamp [ $([DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")) ]"
            }

            $results = Invoke-PokeRequest -method GET -resource_Uri $resource_Uri -uri_Filter $PSBoundParameters -allPages:$allPages

            if ($results) {
                Set-PokeCachedData -name $cachedDataName -timeStamp $runTime -data $results
            }

        }
        else {

            Write-Verbose "Returning cached data: Cached is [ $( (New-TimeSpan -Start $cachedData.cachedTime -End $(Get-Date)).Minutes)min ] old"
            $results = $cachedData
            $results.PSObject.Properties.Remove('staleCache')
            $results.PSObject.Properties.Remove('cachedTime')

        }

        return $results

    }

    end {}

}
#EndRegion '.\Public\encounter\Get-PokeEncounterMethod.ps1' 154
#Region '.\Public\evolution\Get-PokeEvolutionChain.ps1' -1

function Get-PokeEvolutionChain {
<#
    .SYNOPSIS
        Gets evolution chains from PokeAPI

    .DESCRIPTION
        The Get-PokeEvolutionChain cmdlet gets evolution chains from PokeAPI

        Evolution chains are essentially family trees. They start with the lowest stage
        within a family and detail evolution conditions for each as well as Pokemon
        they can evolve into up through the hierarchy.

    .PARAMETER id
        Defines id of the resource

    .PARAMETER name
        Defines name of the resource

    .PARAMETER offset
        Defines the page number to return

        By default only 20 resources are returned

    .PARAMETER limit
        Defines the amount of resources to return with each page

        By default only 20 resources are returned

    .PARAMETER allPages
        Returns all resources from an endpoint

        As of 2024-02, there is no cap on how many resources can be
        returned using the limit parameter. There is currently no real
        use for this parameter and it was included simply to account if
        pagination is introduced.

    .PARAMETER updateCache
        Defines if the cache is refreshed regardless of age

        By default the cache is refreshed every 30min

    .EXAMPLE
        Get-PokeEvolutionChain

        Gets the first 20 evolution chains sorted by id

    .EXAMPLE
        Get-PokeEvolutionChain -id 1

        Gets the evolution chain with the defined id

    .EXAMPLE
        Get-PokeEvolutionChain -name ditto

        Gets the evolution chain with the defined name

    .EXAMPLE
        Get-PokeEvolutionChain -offset 151 -limit 100

        Gets the first 100 resources starting at resources with
        an id over 151

    .NOTES
        n/a

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/evolution/Get-PokeEvolutionChain.html
#>

    [CmdletBinding(DefaultParameterSetName = 'index_ByAll')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ById')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$id,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ByName')]
        [ValidateNotNullOrEmpty()]
        [string]$name,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$offset,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$limit,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [Switch]$allPages,

        [Parameter(Mandatory = $false)]
        [Switch]$updateCache
    )

    begin {

        $functionName   = $MyInvocation.InvocationName
        $cachedDataName = $functionName + '_Cached' -replace '-','_'
        $parameterName  = $functionName + '_Parameters' -replace '-','_'
        $runTime        = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    }

    process {

        Write-Verbose "Running [ $functionName ] with [ $($PSCmdlet.ParameterSetName) ] parameterSet"
        Set-Variable -Name $parameterName -Value $PSBoundParameters -Scope Global -Force

        switch ( $PSCmdlet.ParameterSetName ) {
            'index_ByAll'  {
                $resource_uri   = "/evolution-chain"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName
            }
            'index_ById'   {
                $resource_uri   = "/evolution-chain/$id"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -id $id
            }
            'index_ByName' {
                $resource_uri = ("/evolution-chain/$name").ToLower()
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -name $name
            }
        }

        if ( $null -eq $cachedData -or $cachedData.staleCache -or $updateCache ) {

            if ($cachedData.staleCache) {
                Write-Verbose "Refreshing cached data: Old Timestamp [ $($cachedData.cachedTime) | New Timestamp [ $([DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")) ]"
            }

            $results = Invoke-PokeRequest -method GET -resource_Uri $resource_Uri -uri_Filter $PSBoundParameters -allPages:$allPages

            if ($results) {
                Set-PokeCachedData -name $cachedDataName -timeStamp $runTime -data $results
            }

        }
        else {

            Write-Verbose "Returning cached data: Cached is [ $( (New-TimeSpan -Start $cachedData.cachedTime -End $(Get-Date)).Minutes)min ] old"
            $results = $cachedData
            $results.PSObject.Properties.Remove('staleCache')
            $results.PSObject.Properties.Remove('cachedTime')

        }

        return $results

    }

    end {}

}
#EndRegion '.\Public\evolution\Get-PokeEvolutionChain.ps1' 153
#Region '.\Public\evolution\Get-PokeEvolutionTrigger.ps1' -1

function Get-PokeEvolutionTrigger {
<#
    .SYNOPSIS
        Gets evolution triggers from PokeAPI

    .DESCRIPTION
        The Get-PokeEvolutionTrigger cmdlet gets evolution triggers from PokeAPI

        Evolution triggers are the events and conditions that cause a Pokemon to evolve

    .PARAMETER id
        Defines id of the resource

    .PARAMETER name
        Defines name of the resource

    .PARAMETER offset
        Defines the page number to return

        By default only 20 resources are returned

    .PARAMETER limit
        Defines the amount of resources to return with each page

        By default only 20 resources are returned

    .PARAMETER allPages
        Returns all resources from an endpoint

        As of 2024-02, there is no cap on how many resources can be
        returned using the limit parameter. There is currently no real
        use for this parameter and it was included simply to account if
        pagination is introduced.

    .PARAMETER updateCache
        Defines if the cache is refreshed regardless of age

        By default the cache is refreshed every 30min

    .EXAMPLE
        Get-PokeEvolutionTrigger

        Gets the first 20 evolution triggers sorted by id

    .EXAMPLE
        Get-PokeEvolutionTrigger -id 1

        Gets the evolution trigger with the defined id

    .EXAMPLE
        Get-PokeEvolutionTrigger -name ditto

        Gets the evolution trigger with the defined name

    .EXAMPLE
        Get-PokeEvolutionTrigger -offset 151 -limit 100

        Gets the first 100 resources starting at resources with
        an id over 151

    .NOTES
        n/a

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/evolution/Get-PokeEvolutionTrigger.html
#>

    [CmdletBinding(DefaultParameterSetName = 'index_ByAll')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ById')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$id,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ByName')]
        [ValidateNotNullOrEmpty()]
        [string]$name,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$offset,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$limit,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [Switch]$allPages,

        [Parameter(Mandatory = $false)]
        [Switch]$updateCache
    )

    begin {

        $functionName   = $MyInvocation.InvocationName
        $cachedDataName = $functionName + '_Cached' -replace '-','_'
        $parameterName  = $functionName + '_Parameters' -replace '-','_'
        $runTime        = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    }

    process {

        Write-Verbose "Running [ $functionName ] with [ $($PSCmdlet.ParameterSetName) ] parameterSet"
        Set-Variable -Name $parameterName -Value $PSBoundParameters -Scope Global -Force

        switch ( $PSCmdlet.ParameterSetName ) {

            'index_ByAll'  {
                $resource_uri   = "/evolution-trigger"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName
            }
            'index_ById'   {
                $resource_uri   = "/evolution-trigger/$id"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -id $id
            }
            'index_ByName' {
                $resource_uri = ("/evolution-trigger/$name").ToLower()
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -name $name
            }

        }

        if ( $null -eq $cachedData -or $cachedData.staleCache -or $updateCache ) {

            if ($cachedData.staleCache) {
                Write-Verbose "Refreshing cached data: Old Timestamp [ $($cachedData.cachedTime) | New Timestamp [ $([DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")) ]"
            }

            $results = Invoke-PokeRequest -method GET -resource_Uri $resource_Uri -uri_Filter $PSBoundParameters -allPages:$allPages

            if ($results) {
                Set-PokeCachedData -name $cachedDataName -timeStamp $runTime -data $results
            }

        }
        else {

            Write-Verbose "Returning cached data: Cached is [ $( (New-TimeSpan -Start $cachedData.cachedTime -End $(Get-Date)).Minutes)min ] old"
            $results = $cachedData
            $results.PSObject.Properties.Remove('staleCache')
            $results.PSObject.Properties.Remove('cachedTime')

        }

        return $results

    }

    end {}

}
#EndRegion '.\Public\evolution\Get-PokeEvolutionTrigger.ps1' 153
#Region '.\Public\game\Get-PokeGameGeneration.ps1' -1

function Get-PokeGameGeneration {
<#
    .SYNOPSIS
        Gets game generations from PokeAPI

    .DESCRIPTION
        The Get-PokeGameGeneration cmdlet gets game generations from PokeAPI

        A generation is a grouping of the Pokemon games that separates them based
        on the Pokemon they include.

        In each generation, a new set of Pokemon, Moves, Abilities and Types that
        did not exist in the previous generation are released.

    .PARAMETER id
        Defines id of the resource

    .PARAMETER name
        Defines name of the resource

    .PARAMETER offset
        Defines the page number to return

        By default only 20 resources are returned

    .PARAMETER limit
        Defines the amount of resources to return with each page

        By default only 20 resources are returned

    .PARAMETER allPages
        Returns all resources from an endpoint

        As of 2024-02, there is no cap on how many resources can be
        returned using the limit parameter. There is currently no real
        use for this parameter and it was included simply to account if
        pagination is introduced.

    .PARAMETER updateCache
        Defines if the cache is refreshed regardless of age

        By default the cache is refreshed every 30min

    .EXAMPLE
        Get-PokeGameGeneration

        Gets the first 20 game generations sorted by id

    .EXAMPLE
        Get-PokeGameGeneration -id 1

        Gets the game generation with the defined id

    .EXAMPLE
        Get-PokeGameGeneration -name ditto

        Gets the game generation with the defined name

    .EXAMPLE
        Get-PokeGameGeneration -offset 151 -limit 100

        Gets the first 100 resources starting at resources with
        an id over 151

    .NOTES
        n/a

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/game/Get-PokeGameGeneration.html
#>

    [CmdletBinding(DefaultParameterSetName = 'index_ByAll')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ById')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$id,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ByName')]
        [ValidateNotNullOrEmpty()]
        [string]$name,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$offset,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$limit,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [Switch]$allPages,

        [Parameter(Mandatory = $false)]
        [Switch]$updateCache
    )

    begin {

        $functionName   = $MyInvocation.InvocationName
        $cachedDataName = $functionName + '_Cached' -replace '-','_'
        $parameterName  = $functionName + '_Parameters' -replace '-','_'
        $runTime        = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    }

    process {

        Write-Verbose "Running [ $functionName ] with [ $($PSCmdlet.ParameterSetName) ] parameterSet"
        Set-Variable -Name $parameterName -Value $PSBoundParameters -Scope Global -Force

        switch ( $PSCmdlet.ParameterSetName ) {

            'index_ByAll'  {
                $resource_uri   = "/generation"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName
            }
            'index_ById'   {
                $resource_uri   = "/generation/$id"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -id $id
            }
            'index_ByName' {
                $resource_uri = ("/generation/$name").ToLower()
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -name $name
            }

        }

        if ( $null -eq $cachedData -or $cachedData.staleCache -or $updateCache ) {

            if ($cachedData.staleCache) {
                Write-Verbose "Refreshing cached data: Old Timestamp [ $($cachedData.cachedTime) | New Timestamp [ $([DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")) ]"
            }

            $results = Invoke-PokeRequest -method GET -resource_Uri $resource_Uri -uri_Filter $PSBoundParameters -allPages:$allPages

            if ($results) {
                Set-PokeCachedData -name $cachedDataName -timeStamp $runTime -data $results
            }

        }
        else {

            Write-Verbose "Returning cached data: Cached is [ $( (New-TimeSpan -Start $cachedData.cachedTime -End $(Get-Date)).Minutes)min ] old"
            $results = $cachedData
            $results.PSObject.Properties.Remove('staleCache')
            $results.PSObject.Properties.Remove('cachedTime')

        }

        return $results

    }

    end {}

}
#EndRegion '.\Public\game\Get-PokeGameGeneration.ps1' 157
#Region '.\Public\game\Get-PokeGamePokedex.ps1' -1

function Get-PokeGamePokedex {
<#
    .SYNOPSIS
        Gets game pokedexes from PokeAPI

    .DESCRIPTION
        The Get-PokeGamePokedex cmdlet gets game pokedexes from PokeAPI

        A Pokedex is a handheld electronic encyclopedia device; one which is capable of
        recording and retaining information of the various Pokemon in a given region with the
        exception of the national dex and some smaller dexes related to portions of a region

    .PARAMETER id
        Defines id of the resource

    .PARAMETER name
        Defines name of the resource

    .PARAMETER offset
        Defines the page number to return

        By default only 20 resources are returned

    .PARAMETER limit
        Defines the amount of resources to return with each page

        By default only 20 resources are returned

    .PARAMETER allPages
        Returns all resources from an endpoint

        As of 2024-02, there is no cap on how many resources can be
        returned using the limit parameter. There is currently no real
        use for this parameter and it was included simply to account if
        pagination is introduced.

    .PARAMETER updateCache
        Defines if the cache is refreshed regardless of age

        By default the cache is refreshed every 30min

    .EXAMPLE
        Get-PokeGamePokedex

        Gets the first 20 game pokedexes sorted by id

    .EXAMPLE
        Get-PokeGamePokedex -id 1

        Gets the game pokedex with the defined id

    .EXAMPLE
        Get-PokeGamePokedex -name ditto

        Gets the game pokedex with the defined name

    .EXAMPLE
        Get-PokeGamePokedex -offset 151 -limit 100

        Gets the first 100 resources starting at resources with
        an id over 151

    .NOTES
        n/a

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/game/Get-PokeGamePokedex.html
#>

    [CmdletBinding(DefaultParameterSetName = 'index_ByAll')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ById')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$id,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ByName')]
        [ValidateNotNullOrEmpty()]
        [string]$name,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$offset,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$limit,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [Switch]$allPages,

        [Parameter(Mandatory = $false)]
        [Switch]$updateCache
    )

    begin {

        $functionName   = $MyInvocation.InvocationName
        $cachedDataName = $functionName + '_Cached' -replace '-','_'
        $parameterName  = $functionName + '_Parameters' -replace '-','_'
        $runTime        = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    }

    process {

        Write-Verbose "Running [ $functionName ] with [ $($PSCmdlet.ParameterSetName) ] parameterSet"
        Set-Variable -Name $parameterName -Value $PSBoundParameters -Scope Global -Force

        switch ( $PSCmdlet.ParameterSetName ) {

            'index_ByAll'  {
                $resource_uri   = "/pokedex"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName
            }
            'index_ById'   {
                $resource_uri   = "/pokedex/$id"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -id $id
            }
            'index_ByName' {
                $resource_uri = ("/pokedex/$name").ToLower()
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -name $name
            }

        }

        if ( $null -eq $cachedData -or $cachedData.staleCache -or $updateCache ) {

            if ($cachedData.staleCache) {
                Write-Verbose "Refreshing cached data: Old Timestamp [ $($cachedData.cachedTime) | New Timestamp [ $([DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")) ]"
            }

            $results = Invoke-PokeRequest -method GET -resource_Uri $resource_Uri -uri_Filter $PSBoundParameters -allPages:$allPages

            if ($results) {
                Set-PokeCachedData -name $cachedDataName -timeStamp $runTime -data $results
            }

        }
        else {

            Write-Verbose "Returning cached data: Cached is [ $( (New-TimeSpan -Start $cachedData.cachedTime -End $(Get-Date)).Minutes)min ] old"
            $results = $cachedData
            $results.PSObject.Properties.Remove('staleCache')
            $results.PSObject.Properties.Remove('cachedTime')

        }

        return $results

    }

    end {}

}
#EndRegion '.\Public\game\Get-PokeGamePokedex.ps1' 155
#Region '.\Public\game\Get-PokeGameVersion.ps1' -1

function Get-PokeGameVersion {
<#
    .SYNOPSIS
        Gets game versions from PokeAPI

    .DESCRIPTION
        The Get-PokeGameVersion cmdlet gets game versions from PokeAPI

        Versions of the games, e.g., Red, Blue or Yellow

    .PARAMETER id
        Defines id of the resource

    .PARAMETER name
        Defines name of the resource

    .PARAMETER offset
        Defines the page number to return

        By default only 20 resources are returned

    .PARAMETER limit
        Defines the amount of resources to return with each page

        By default only 20 resources are returned

    .PARAMETER allPages
        Returns all resources from an endpoint

        As of 2024-02, there is no cap on how many resources can be
        returned using the limit parameter. There is currently no real
        use for this parameter and it was included simply to account if
        pagination is introduced.

    .PARAMETER updateCache
        Defines if the cache is refreshed regardless of age

        By default the cache is refreshed every 30min

    .EXAMPLE
        Get-PokeGameVersion

        Gets the first 20 game versions sorted by id

    .EXAMPLE
        Get-PokeGameVersion -id 1

        Gets the game version with the defined id

    .EXAMPLE
        Get-PokeGameVersion -name ditto

        Gets the game version with the defined name

    .EXAMPLE
        Get-PokeGameVersion -offset 151 -limit 100

        Gets the first 100 resources starting at resources with
        an id over 151

    .NOTES
        n/a

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/game/Get-PokeGameVersion.html
#>

    [CmdletBinding(DefaultParameterSetName = 'index_ByAll')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ById')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$id,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ByName')]
        [ValidateNotNullOrEmpty()]
        [string]$name,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$offset,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$limit,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [Switch]$allPages,

        [Parameter(Mandatory = $false)]
        [Switch]$updateCache
    )

    begin {

        $functionName   = $MyInvocation.InvocationName
        $cachedDataName = $functionName + '_Cached' -replace '-','_'
        $parameterName  = $functionName + '_Parameters' -replace '-','_'
        $runTime        = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    }

    process {

        Write-Verbose "Running [ $functionName ] with [ $($PSCmdlet.ParameterSetName) ] parameterSet"
        Set-Variable -Name $parameterName -Value $PSBoundParameters -Scope Global -Force

        switch ( $PSCmdlet.ParameterSetName ) {

            'index_ByAll'  {
                $resource_uri   = "/version"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName
            }
            'index_ById'   {
                $resource_uri   = "/version/$id"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -id $id
            }
            'index_ByName' {
                $resource_uri = ("/version/$name").ToLower()
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -name $name
            }

        }

        if ( $null -eq $cachedData -or $cachedData.staleCache -or $updateCache ) {

            if ($cachedData.staleCache) {
                Write-Verbose "Refreshing cached data: Old Timestamp [ $($cachedData.cachedTime) | New Timestamp [ $([DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")) ]"
            }

            $results = Invoke-PokeRequest -method GET -resource_Uri $resource_Uri -uri_Filter $PSBoundParameters -allPages:$allPages

            if ($results) {
                Set-PokeCachedData -name $cachedDataName -timeStamp $runTime -data $results
            }

        }
        else {

            Write-Verbose "Returning cached data: Cached is [ $( (New-TimeSpan -Start $cachedData.cachedTime -End $(Get-Date)).Minutes)min ] old"
            $results = $cachedData
            $results.PSObject.Properties.Remove('staleCache')
            $results.PSObject.Properties.Remove('cachedTime')

        }

        return $results

    }

    end {}

}
#EndRegion '.\Public\game\Get-PokeGameVersion.ps1' 153
#Region '.\Public\game\Get-PokeGameVersionGroup.ps1' -1

function Get-PokeGameVersionGroup {
<#
    .SYNOPSIS
        Gets game version groups from PokeAPI

    .DESCRIPTION
        The Get-PokeGameVersionGroup cmdlet gets game version groups
        from PokeAPI

        Version groups categorize highly similar versions of the games

    .PARAMETER id
        Defines id of the resource

    .PARAMETER name
        Defines name of the resource

    .PARAMETER offset
        Defines the page number to return

        By default only 20 resources are returned

    .PARAMETER limit
        Defines the amount of resources to return with each page

        By default only 20 resources are returned

    .PARAMETER allPages
        Returns all resources from an endpoint

        As of 2024-02, there is no cap on how many resources can be
        returned using the limit parameter. There is currently no real
        use for this parameter and it was included simply to account if
        pagination is introduced.

    .PARAMETER updateCache
        Defines if the cache is refreshed regardless of age

        By default the cache is refreshed every 30min

    .EXAMPLE
        Get-PokeGameVersionGroup

        Gets the first 20 game version groups sorted by id

    .EXAMPLE
        Get-PokeGameVersionGroup -id 1

        Gets the game version group with the defined id

    .EXAMPLE
        Get-PokeGameVersionGroup -name ditto

        Gets the game version group with the defined name

    .EXAMPLE
        Get-PokeGameVersionGroup -offset 151 -limit 100

        Gets the first 100 resources starting at resources with
        an id over 151

    .NOTES
        n/a

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/game/Get-PokeGameVersionGroup.html
#>

    [CmdletBinding(DefaultParameterSetName = 'index_ByAll')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ById')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$id,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ByName')]
        [ValidateNotNullOrEmpty()]
        [string]$name,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$offset,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$limit,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [Switch]$allPages,

        [Parameter(Mandatory = $false)]
        [Switch]$updateCache
    )

    begin {

        $functionName   = $MyInvocation.InvocationName
        $cachedDataName = $functionName + '_Cached' -replace '-','_'
        $parameterName  = $functionName + '_Parameters' -replace '-','_'
        $runTime        = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    }

    process {

        Write-Verbose "Running [ $functionName ] with [ $($PSCmdlet.ParameterSetName) ] parameterSet"
        Set-Variable -Name $parameterName -Value $PSBoundParameters -Scope Global -Force

        switch ( $PSCmdlet.ParameterSetName ) {

            'index_ByAll'  {
                $resource_uri   = "/version-group"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName
            }
            'index_ById'   {
                $resource_uri   = "/version-group/$id"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -id $id
            }
            'index_ByName' {
                $resource_uri = ("/version-group/$name").ToLower()
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -name $name
            }

        }

        if ( $null -eq $cachedData -or $cachedData.staleCache -or $updateCache ) {

            if ($cachedData.staleCache) {
                Write-Verbose "Refreshing cached data: Old Timestamp [ $($cachedData.cachedTime) | New Timestamp [ $([DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")) ]"
            }

            $results = Invoke-PokeRequest -method GET -resource_Uri $resource_Uri -uri_Filter $PSBoundParameters -allPages:$allPages

            if ($results) {
                Set-PokeCachedData -name $cachedDataName -timeStamp $runTime -data $results
            }

        }
        else {

            Write-Verbose "Returning cached data: Cached is [ $( (New-TimeSpan -Start $cachedData.cachedTime -End $(Get-Date)).Minutes)min ] old"
            $results = $cachedData
            $results.PSObject.Properties.Remove('staleCache')
            $results.PSObject.Properties.Remove('cachedTime')

        }

        return $results

    }

    end {}

}
#EndRegion '.\Public\game\Get-PokeGameVersionGroup.ps1' 154
#Region '.\Public\item\Get-PokeItem.ps1' -1

function Get-PokeItem {
<#
    .SYNOPSIS
        Gets items from PokeAPI

    .DESCRIPTION
        The Get-PokeItem cmdlet gets items from PokeAPI

        An item is an object in the games which the player can pick up,
        keep in their bag, and use in some manner

        They have various uses, including healing, powering up, helping catch
        Pokemon, or to access a new area

    .PARAMETER id
        Defines id of the resource

    .PARAMETER name
        Defines name of the resource

    .PARAMETER offset
        Defines the page number to return

        By default only 20 resources are returned

    .PARAMETER limit
        Defines the amount of resources to return with each page

        By default only 20 resources are returned

    .PARAMETER allPages
        Returns all resources from an endpoint

        As of 2024-02, there is no cap on how many resources can be
        returned using the limit parameter. There is currently no real
        use for this parameter and it was included simply to account if
        pagination is introduced.

    .PARAMETER updateCache
        Defines if the cache is refreshed regardless of age

        By default the cache is refreshed every 30min

    .EXAMPLE
        Get-PokeItem

        Gets the first 20 items sorted by id

    .EXAMPLE
        Get-PokeItem -id 1

        Gets the item with the defined id

    .EXAMPLE
        Get-PokeItem -name ditto

        Gets the item with the defined name

    .EXAMPLE
        Get-PokeItem -offset 151 -limit 100

        Gets the first 100 resources starting at resources with
        an id over 151

    .NOTES
        n/a

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/item/Get-PokeItem.html
#>

    [CmdletBinding(DefaultParameterSetName = 'index_ByAll')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ById')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$id,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ByName')]
        [ValidateNotNullOrEmpty()]
        [string]$name,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$offset,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$limit,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [Switch]$allPages,

        [Parameter(Mandatory = $false)]
        [Switch]$updateCache
    )

    begin {

        $functionName   = $MyInvocation.InvocationName
        $cachedDataName = $functionName + '_Cached' -replace '-','_'
        $parameterName  = $functionName + '_Parameters' -replace '-','_'
        $runTime        = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    }

    process {

        Write-Verbose "Running [ $functionName ] with [ $($PSCmdlet.ParameterSetName) ] parameterSet"
        Set-Variable -Name $parameterName -Value $PSBoundParameters -Scope Global -Force

        switch ( $PSCmdlet.ParameterSetName ) {

            'index_ByAll'  {
                $resource_uri   = "/item"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName
            }
            'index_ById'   {
                $resource_uri   = "/item/$id"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -id $id
            }
            'index_ByName' {
                $resource_uri = ("/item/$name").ToLower()
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -name $name
            }

        }

        if ( $null -eq $cachedData -or $cachedData.staleCache -or $updateCache ) {

            if ($cachedData.staleCache) {
                Write-Verbose "Refreshing cached data: Old Timestamp [ $($cachedData.cachedTime) | New Timestamp [ $([DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")) ]"
            }

            $results = Invoke-PokeRequest -method GET -resource_Uri $resource_Uri -uri_Filter $PSBoundParameters -allPages:$allPages

            if ($results) {
                Set-PokeCachedData -name $cachedDataName -timeStamp $runTime -data $results
            }

        }
        else {

            Write-Verbose "Returning cached data: Cached is [ $( (New-TimeSpan -Start $cachedData.cachedTime -End $(Get-Date)).Minutes)min ] old"
            $results = $cachedData
            $results.PSObject.Properties.Remove('staleCache')
            $results.PSObject.Properties.Remove('cachedTime')

        }

        return $results

    }

    end {}

}
#EndRegion '.\Public\item\Get-PokeItem.ps1' 157
#Region '.\Public\item\Get-PokeItemAttribute.ps1' -1

function Get-PokeItemAttribute {
<#
    .SYNOPSIS
        Gets item attributes from PokeAPI

    .DESCRIPTION
        The Get-PokeItemAttribute cmdlet gets item attributes from PokeAPI

        Item attributes define particular aspects of items,
        e.g. "usable in battle" or "consumable"

    .PARAMETER id
        Defines id of the resource

    .PARAMETER name
        Defines name of the resource

    .PARAMETER offset
        Defines the page number to return

        By default only 20 resources are returned

    .PARAMETER limit
        Defines the amount of resources to return with each page

        By default only 20 resources are returned

    .PARAMETER allPages
        Returns all resources from an endpoint

        As of 2024-02, there is no cap on how many resources can be
        returned using the limit parameter. There is currently no real
        use for this parameter and it was included simply to account if
        pagination is introduced.

    .PARAMETER updateCache
        Defines if the cache is refreshed regardless of age

        By default the cache is refreshed every 30min

    .EXAMPLE
        Get-PokeItemAttribute

        Gets the first 20 item attributes sorted by id

    .EXAMPLE
        Get-PokeItemAttribute -id 1

        Gets the item attribute with the defined id

    .EXAMPLE
        Get-PokeItemAttribute -name ditto

        Gets the item attribute with the defined name

    .EXAMPLE
        Get-PokeItemAttribute -offset 151 -limit 100

        Gets the first 100 resources starting at resources with
        an id over 151

    .NOTES
        n/a

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/item/Get-PokeItemAttribute.html
#>

    [CmdletBinding(DefaultParameterSetName = 'index_ByAll')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ById')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$id,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ByName')]
        [ValidateNotNullOrEmpty()]
        [string]$name,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$offset,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$limit,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [Switch]$allPages,

        [Parameter(Mandatory = $false)]
        [Switch]$updateCache
    )

    begin {

        $functionName   = $MyInvocation.InvocationName
        $cachedDataName = $functionName + '_Cached' -replace '-','_'
        $parameterName  = $functionName + '_Parameters' -replace '-','_'
        $runTime        = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    }

    process {

        Write-Verbose "Running [ $functionName ] with [ $($PSCmdlet.ParameterSetName) ] parameterSet"
        Set-Variable -Name $parameterName -Value $PSBoundParameters -Scope Global -Force

        switch ( $PSCmdlet.ParameterSetName ) {

            'index_ByAll'  {
                $resource_uri   = "/item-attribute"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName
            }
            'index_ById'   {
                $resource_uri   = "/item-attribute/$id"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -id $id
            }
            'index_ByName' {
                $resource_uri = ("/item-attribute/$name").ToLower()
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -name $name
            }

        }

        if ( $null -eq $cachedData -or $cachedData.staleCache -or $updateCache ) {

            if ($cachedData.staleCache) {
                Write-Verbose "Refreshing cached data: Old Timestamp [ $($cachedData.cachedTime) | New Timestamp [ $([DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")) ]"
            }

            $results = Invoke-PokeRequest -method GET -resource_Uri $resource_Uri -uri_Filter $PSBoundParameters -allPages:$allPages

            if ($results) {
                Set-PokeCachedData -name $cachedDataName -timeStamp $runTime -data $results
            }

        }
        else {

            Write-Verbose "Returning cached data: Cached is [ $( (New-TimeSpan -Start $cachedData.cachedTime -End $(Get-Date)).Minutes)min ] old"
            $results = $cachedData
            $results.PSObject.Properties.Remove('staleCache')
            $results.PSObject.Properties.Remove('cachedTime')

        }

        return $results

    }

    end {}

}
#EndRegion '.\Public\item\Get-PokeItemAttribute.ps1' 154
#Region '.\Public\item\Get-PokeItemCategory.ps1' -1

function Get-PokeItemCategory {
<#
    .SYNOPSIS
        Gets item categories from PokeAPI

    .DESCRIPTION
        The Get-PokeItemCategory cmdlet gets item categories from PokeAPI

        Item categories determine where items will be placed in the players bag

    .PARAMETER id
        Defines id of the resource

    .PARAMETER name
        Defines name of the resource

    .PARAMETER offset
        Defines the page number to return

        By default only 20 resources are returned

    .PARAMETER limit
        Defines the amount of resources to return with each page

        By default only 20 resources are returned

    .PARAMETER allPages
        Returns all resources from an endpoint

        As of 2024-02, there is no cap on how many resources can be
        returned using the limit parameter. There is currently no real
        use for this parameter and it was included simply to account if
        pagination is introduced.

    .PARAMETER updateCache
        Defines if the cache is refreshed regardless of age

        By default the cache is refreshed every 30min

    .EXAMPLE
        Get-PokeItemCategory

        Gets the first 20 item categories sorted by id

    .EXAMPLE
        Get-PokeItemCategory -id 1

        Gets the item category with the defined id

    .EXAMPLE
        Get-PokeItemCategory -name ditto

        Gets the item category with the defined name

    .EXAMPLE
        Get-PokeItemCategory -offset 151 -limit 100

        Gets the first 100 resources starting at resources with
        an id over 151

    .NOTES
        n/a

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/item/Get-PokeItemCategory.html
#>

    [CmdletBinding(DefaultParameterSetName = 'index_ByAll')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ById')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$id,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ByName')]
        [ValidateNotNullOrEmpty()]
        [string]$name,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$offset,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$limit,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [Switch]$allPages,

        [Parameter(Mandatory = $false)]
        [Switch]$updateCache
    )

    begin {

        $functionName   = $MyInvocation.InvocationName
        $cachedDataName = $functionName + '_Cached' -replace '-','_'
        $parameterName  = $functionName + '_Parameters' -replace '-','_'
        $runTime        = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    }

    process {

        Write-Verbose "Running [ $functionName ] with [ $($PSCmdlet.ParameterSetName) ] parameterSet"
        Set-Variable -Name $parameterName -Value $PSBoundParameters -Scope Global -Force

        switch ( $PSCmdlet.ParameterSetName ) {

            'index_ByAll'  {
                $resource_uri   = "/item-category"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName
            }
            'index_ById'   {
                $resource_uri   = "/item-category/$id"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -id $id
            }
            'index_ByName' {
                $resource_uri = ("/item-category/$name").ToLower()
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -name $name
            }

        }

        if ( $null -eq $cachedData -or $cachedData.staleCache -or $updateCache ) {

            if ($cachedData.staleCache) {
                Write-Verbose "Refreshing cached data: Old Timestamp [ $($cachedData.cachedTime) | New Timestamp [ $([DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")) ]"
            }

            $results = Invoke-PokeRequest -method GET -resource_Uri $resource_Uri -uri_Filter $PSBoundParameters -allPages:$allPages

            if ($results) {
                Set-PokeCachedData -name $cachedDataName -timeStamp $runTime -data $results
            }

        }
        else {

            Write-Verbose "Returning cached data: Cached is [ $( (New-TimeSpan -Start $cachedData.cachedTime -End $(Get-Date)).Minutes)min ] old"
            $results = $cachedData
            $results.PSObject.Properties.Remove('staleCache')
            $results.PSObject.Properties.Remove('cachedTime')

        }

        return $results

    }

    end {}

}
#EndRegion '.\Public\item\Get-PokeItemCategory.ps1' 153
#Region '.\Public\item\Get-PokeItemFlingEffect.ps1' -1

function Get-PokeItemFlingEffect {
<#
    .SYNOPSIS
        Gets item fling effects from PokeAPI

    .DESCRIPTION
        The Get-PokeItemFlingEffect cmdlet gets item fling effects from PokeAPI

        The various effects of the move "Fling" when used with different items

    .PARAMETER id
        Defines id of the resource

    .PARAMETER name
        Defines name of the resource

    .PARAMETER offset
        Defines the page number to return

        By default only 20 resources are returned

    .PARAMETER limit
        Defines the amount of resources to return with each page

        By default only 20 resources are returned

    .PARAMETER allPages
        Returns all resources from an endpoint

        As of 2024-02, there is no cap on how many resources can be
        returned using the limit parameter. There is currently no real
        use for this parameter and it was included simply to account if
        pagination is introduced.

    .PARAMETER updateCache
        Defines if the cache is refreshed regardless of age

        By default the cache is refreshed every 30min

    .EXAMPLE
        Get-PokeItemFlingEffect

        Gets the first 20 item fling effects sorted by id

    .EXAMPLE
        Get-PokeItemFlingEffect -id 1

        Gets the item fling effect with the defined id

    .EXAMPLE
        Get-PokeItemFlingEffect -name ditto

        Gets the item fling effect with the defined name

    .EXAMPLE
        Get-PokeItemFlingEffect -offset 151 -limit 100

        Gets the first 100 resources starting at resources with
        an id over 151

    .NOTES
        n/a

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/item/Get-PokeItemFlingEffect.html
#>

    [CmdletBinding(DefaultParameterSetName = 'index_ByAll')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ById')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$id,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ByName')]
        [ValidateNotNullOrEmpty()]
        [string]$name,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$offset,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$limit,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [Switch]$allPages,

        [Parameter(Mandatory = $false)]
        [Switch]$updateCache
    )

    begin {

        $functionName   = $MyInvocation.InvocationName
        $cachedDataName = $functionName + '_Cached' -replace '-','_'
        $parameterName  = $functionName + '_Parameters' -replace '-','_'
        $runTime        = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    }

    process {

        Write-Verbose "Running [ $functionName ] with [ $($PSCmdlet.ParameterSetName) ] parameterSet"
        Set-Variable -Name $parameterName -Value $PSBoundParameters -Scope Global -Force

        switch ( $PSCmdlet.ParameterSetName ) {

            'index_ByAll'  {
                $resource_uri   = "/item-fling-effect"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName
            }
            'index_ById'   {
                $resource_uri   = "/item-fling-effect/$id"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -id $id
            }
            'index_ByName' {
                $resource_uri = ("/item-fling-effect/$name").ToLower()
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -name $name
            }

        }

        if ( $null -eq $cachedData -or $cachedData.staleCache -or $updateCache ) {

            if ($cachedData.staleCache) {
                Write-Verbose "Refreshing cached data: Old Timestamp [ $($cachedData.cachedTime) | New Timestamp [ $([DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")) ]"
            }

            $results = Invoke-PokeRequest -method GET -resource_Uri $resource_Uri -uri_Filter $PSBoundParameters -allPages:$allPages

            if ($results) {
                Set-PokeCachedData -name $cachedDataName -timeStamp $runTime -data $results
            }

        }
        else {

            Write-Verbose "Returning cached data: Cached is [ $( (New-TimeSpan -Start $cachedData.cachedTime -End $(Get-Date)).Minutes)min ] old"
            $results = $cachedData
            $results.PSObject.Properties.Remove('staleCache')
            $results.PSObject.Properties.Remove('cachedTime')

        }

        return $results

    }

    end {}

}
#EndRegion '.\Public\item\Get-PokeItemFlingEffect.ps1' 153
#Region '.\Public\item\Get-PokeItemPocket.ps1' -1

function Get-PokeItemPocket {
<#
    .SYNOPSIS
        Gets item pockets from PokeAPI

    .DESCRIPTION
        The Get-PokeItemPocket cmdlet gets item pockets from PokeAPI

        Pockets within the players bag used for storing items by category

    .PARAMETER id
        Defines id of the resource

    .PARAMETER name
        Defines name of the resource

    .PARAMETER offset
        Defines the page number to return

        By default only 20 resources are returned

    .PARAMETER limit
        Defines the amount of resources to return with each page

        By default only 20 resources are returned

    .PARAMETER allPages
        Returns all resources from an endpoint

        As of 2024-02, there is no cap on how many resources can be
        returned using the limit parameter. There is currently no real
        use for this parameter and it was included simply to account if
        pagination is introduced.

    .PARAMETER updateCache
        Defines if the cache is refreshed regardless of age

        By default the cache is refreshed every 30min

    .EXAMPLE
        Get-PokeItemPocket

        Gets the first 20 item pockets sorted by id

    .EXAMPLE
        Get-PokeItemPocket -id 1

        Gets the item pocket with the defined id

    .EXAMPLE
        Get-PokeItemPocket -name ditto

        Gets the item pocket with the defined name

    .EXAMPLE
        Get-PokeItemPocket -offset 151 -limit 100

        Gets the first 100 resources starting at resources with
        an id over 151

    .NOTES
        n/a

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/item/Get-PokeItemPocket.html
#>

    [CmdletBinding(DefaultParameterSetName = 'index_ByAll')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ById')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$id,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ByName')]
        [ValidateNotNullOrEmpty()]
        [string]$name,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$offset,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$limit,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [Switch]$allPages,

        [Parameter(Mandatory = $false)]
        [Switch]$updateCache
    )

    begin {

        $functionName   = $MyInvocation.InvocationName
        $cachedDataName = $functionName + '_Cached' -replace '-','_'
        $parameterName  = $functionName + '_Parameters' -replace '-','_'
        $runTime        = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    }

    process {

        Write-Verbose "Running [ $functionName ] with [ $($PSCmdlet.ParameterSetName) ] parameterSet"
        Set-Variable -Name $parameterName -Value $PSBoundParameters -Scope Global -Force

        switch ( $PSCmdlet.ParameterSetName ) {

            'index_ByAll'  {
                $resource_uri   = "/item-pocket"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName
            }
            'index_ById'   {
                $resource_uri   = "/item-pocket/$id"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -id $id
            }
            'index_ByName' {
                $resource_uri = ("/item-pocket/$name").ToLower()
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -name $name
            }

        }

        if ( $null -eq $cachedData -or $cachedData.staleCache -or $updateCache ) {

            if ($cachedData.staleCache) {
                Write-Verbose "Refreshing cached data: Old Timestamp [ $($cachedData.cachedTime) | New Timestamp [ $([DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")) ]"
            }

            $results = Invoke-PokeRequest -method GET -resource_Uri $resource_Uri -uri_Filter $PSBoundParameters -allPages:$allPages

            if ($results) {
                Set-PokeCachedData -name $cachedDataName -timeStamp $runTime -data $results
            }

        }
        else {

            Write-Verbose "Returning cached data: Cached is [ $( (New-TimeSpan -Start $cachedData.cachedTime -End $(Get-Date)).Minutes)min ] old"
            $results = $cachedData
            $results.PSObject.Properties.Remove('staleCache')
            $results.PSObject.Properties.Remove('cachedTime')

        }

        return $results

    }

    end {}

}
#EndRegion '.\Public\item\Get-PokeItemPocket.ps1' 153
#Region '.\Public\location\Get-PokeLocation.ps1' -1

function Get-PokeLocation {
<#
    .SYNOPSIS
        Gets locations from PokeAPI

    .DESCRIPTION
        The Get-PokeLocation cmdlet gets locations from PokeAPI

        Locations that can be visited within the games

        Locations make up sizable portions of regions, like cities or routes

    .PARAMETER id
        Defines id of the resource

    .PARAMETER name
        Defines name of the resource

    .PARAMETER offset
        Defines the page number to return

        By default only 20 resources are returned

    .PARAMETER limit
        Defines the amount of resources to return with each page

        By default only 20 resources are returned

    .PARAMETER allPages
        Returns all resources from an endpoint

        As of 2024-02, there is no cap on how many resources can be
        returned using the limit parameter. There is currently no real
        use for this parameter and it was included simply to account if
        pagination is introduced.

    .PARAMETER updateCache
        Defines if the cache is refreshed regardless of age

        By default the cache is refreshed every 30min

    .EXAMPLE
        Get-PokeLocation

        Gets the first 20 locations sorted by id

    .EXAMPLE
        Get-PokeLocation -id 1

        Gets the location with the defined id

    .EXAMPLE
        Get-PokeLocation -name ditto

        Gets the location with the defined name

    .EXAMPLE
        Get-PokeLocation -offset 151 -limit 100

        Gets the first 100 resources starting at resources with
        an id over 151

    .NOTES
        n/a

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/location/Get-PokeLocation.html
#>

    [CmdletBinding(DefaultParameterSetName = 'index_ByAll')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ById')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$id,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ByName')]
        [ValidateNotNullOrEmpty()]
        [string]$name,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$offset,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$limit,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [Switch]$allPages,

        [Parameter(Mandatory = $false)]
        [Switch]$updateCache
    )

    begin {

        $functionName   = $MyInvocation.InvocationName
        $cachedDataName = $functionName + '_Cached' -replace '-','_'
        $parameterName  = $functionName + '_Parameters' -replace '-','_'
        $runTime        = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    }

    process {

        Write-Verbose "Running [ $functionName ] with [ $($PSCmdlet.ParameterSetName) ] parameterSet"
        Set-Variable -Name $parameterName -Value $PSBoundParameters -Scope Global -Force

        switch ( $PSCmdlet.ParameterSetName ) {

            'index_ByAll'  {
                $resource_uri   = "/location"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName
            }
            'index_ById'   {
                $resource_uri   = "/location/$id"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -id $id
            }
            'index_ByName' {
                $resource_uri = ("/location/$name").ToLower()
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -name $name
            }

        }

        if ( $null -eq $cachedData -or $cachedData.staleCache -or $updateCache ) {

            if ($cachedData.staleCache) {
                Write-Verbose "Refreshing cached data: Old Timestamp [ $($cachedData.cachedTime) | New Timestamp [ $([DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")) ]"
            }

            $results = Invoke-PokeRequest -method GET -resource_Uri $resource_Uri -uri_Filter $PSBoundParameters -allPages:$allPages

            if ($results) {
                Set-PokeCachedData -name $cachedDataName -timeStamp $runTime -data $results
            }

        }
        else {

            Write-Verbose "Returning cached data: Cached is [ $( (New-TimeSpan -Start $cachedData.cachedTime -End $(Get-Date)).Minutes)min ] old"
            $results = $cachedData
            $results.PSObject.Properties.Remove('staleCache')
            $results.PSObject.Properties.Remove('cachedTime')

        }

        return $results

    }

    end {}

}
#EndRegion '.\Public\location\Get-PokeLocation.ps1' 155
#Region '.\Public\location\Get-PokeLocationArea.ps1' -1

function Get-PokeLocationArea {
<#
    .SYNOPSIS
        Gets location areas from PokeAPI

    .DESCRIPTION
        The Get-PokeLocationArea cmdlet gets location areas from PokeAPI

        Location areas are sections of areas, such as floors in a building or cave

        Each area has its own set of possible Pokemon encounters

    .PARAMETER id
        Defines id of the resource

    .PARAMETER name
        Defines name of the resource

    .PARAMETER offset
        Defines the page number to return

        By default only 20 resources are returned

    .PARAMETER limit
        Defines the amount of resources to return with each page

        By default only 20 resources are returned

    .PARAMETER allPages
        Returns all resources from an endpoint

        As of 2024-02, there is no cap on how many resources can be
        returned using the limit parameter. There is currently no real
        use for this parameter and it was included simply to account if
        pagination is introduced.

    .PARAMETER updateCache
        Defines if the cache is refreshed regardless of age

        By default the cache is refreshed every 30min

    .EXAMPLE
        Get-PokeLocationArea

        Gets the first 20 location areas sorted by id

    .EXAMPLE
        Get-PokeLocationArea -id 1

        Gets the location area with the defined id

    .EXAMPLE
        Get-PokeLocationArea -name ditto

        Gets the location area with the defined name

    .EXAMPLE
        Get-PokeLocationArea -offset 151 -limit 100

        Gets the first 100 resources starting at resources with
        an id over 151

    .NOTES
        n/a

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/location/Get-PokeLocationArea.html
#>

    [CmdletBinding(DefaultParameterSetName = 'index_ByAll')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ById')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$id,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ByName')]
        [ValidateNotNullOrEmpty()]
        [string]$name,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$offset,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$limit,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [Switch]$allPages,

        [Parameter(Mandatory = $false)]
        [Switch]$updateCache
    )

    begin {

        $functionName   = $MyInvocation.InvocationName
        $cachedDataName = $functionName + '_Cached' -replace '-','_'
        $parameterName  = $functionName + '_Parameters' -replace '-','_'
        $runTime        = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    }

    process {

        Write-Verbose "Running [ $functionName ] with [ $($PSCmdlet.ParameterSetName) ] parameterSet"
        Set-Variable -Name $parameterName -Value $PSBoundParameters -Scope Global -Force

        switch ( $PSCmdlet.ParameterSetName ) {

            'index_ByAll'  {
                $resource_uri   = "/location-area"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName
            }
            'index_ById'   {
                $resource_uri   = "/location-area/$id"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -id $id
            }
            'index_ByName' {
                $resource_uri = ("/location-area/$name").ToLower()
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -name $name
            }

        }

        if ( $null -eq $cachedData -or $cachedData.staleCache -or $updateCache ) {

            if ($cachedData.staleCache) {
                Write-Verbose "Refreshing cached data: Old Timestamp [ $($cachedData.cachedTime) | New Timestamp [ $([DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")) ]"
            }

            $results = Invoke-PokeRequest -method GET -resource_Uri $resource_Uri -uri_Filter $PSBoundParameters -allPages:$allPages

            if ($results) {
                Set-PokeCachedData -name $cachedDataName -timeStamp $runTime -data $results
            }

        }
        else {

            Write-Verbose "Returning cached data: Cached is [ $( (New-TimeSpan -Start $cachedData.cachedTime -End $(Get-Date)).Minutes)min ] old"
            $results = $cachedData
            $results.PSObject.Properties.Remove('staleCache')
            $results.PSObject.Properties.Remove('cachedTime')

        }

        return $results

    }

    end {}

}
#EndRegion '.\Public\location\Get-PokeLocationArea.ps1' 155
#Region '.\Public\location\Get-PokeLocationPalParkArea.ps1' -1

function Get-PokeLocationPalParkArea {
<#
    .SYNOPSIS
        Gets pal park areas from PokeAPI

    .DESCRIPTION
        The Get-PokeLocationPalParkArea cmdlet gets pal park areas from PokeAPI

        Areas used for grouping Pokemon encounters in Pal Park

        They're like habitats that are specific to Pal Park

    .PARAMETER id
        Defines id of the resource

    .PARAMETER name
        Defines name of the resource

    .PARAMETER offset
        Defines the page number to return

        By default only 20 resources are returned

    .PARAMETER limit
        Defines the amount of resources to return with each page

        By default only 20 resources are returned

    .PARAMETER allPages
        Returns all resources from an endpoint

        As of 2024-02, there is no cap on how many resources can be
        returned using the limit parameter. There is currently no real
        use for this parameter and it was included simply to account if
        pagination is introduced.

    .PARAMETER updateCache
        Defines if the cache is refreshed regardless of age

        By default the cache is refreshed every 30min

    .EXAMPLE
        Get-PokeLocationPalParkArea

        Gets the first 20 pal park areas sorted by id

    .EXAMPLE
        Get-PokeLocationPalParkArea -id 1

        Gets the pal park area with the defined id

    .EXAMPLE
        Get-PokeLocationPalParkArea -name ditto

        Gets the pal park area with the defined name

    .EXAMPLE
        Get-PokeLocationPalParkArea -offset 151 -limit 100

        Gets the first 100 resources starting at resources with
        an id over 151

    .NOTES
        n/a

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/location/Get-PokeLocationPalParkArea.html
#>

    [CmdletBinding(DefaultParameterSetName = 'index_ByAll')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ById')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$id,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ByName')]
        [ValidateNotNullOrEmpty()]
        [string]$name,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$offset,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$limit,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [Switch]$allPages,

        [Parameter(Mandatory = $false)]
        [Switch]$updateCache
    )

    begin {

        $functionName   = $MyInvocation.InvocationName
        $cachedDataName = $functionName + '_Cached' -replace '-','_'
        $parameterName  = $functionName + '_Parameters' -replace '-','_'
        $runTime        = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    }

    process {

        Write-Verbose "Running [ $functionName ] with [ $($PSCmdlet.ParameterSetName) ] parameterSet"
        Set-Variable -Name $parameterName -Value $PSBoundParameters -Scope Global -Force

        switch ( $PSCmdlet.ParameterSetName ) {

            'index_ByAll'  {
                $resource_uri   = "/pal-park-area"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName
            }
            'index_ById'   {
                $resource_uri   = "/pal-park-area/$id"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -id $id
            }
            'index_ByName' {
                $resource_uri = ("/pal-park-area/$name").ToLower()
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -name $name
            }

        }

        if ( $null -eq $cachedData -or $cachedData.staleCache -or $updateCache ) {

            if ($cachedData.staleCache) {
                Write-Verbose "Refreshing cached data: Old Timestamp [ $($cachedData.cachedTime) | New Timestamp [ $([DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")) ]"
            }

            $results = Invoke-PokeRequest -method GET -resource_Uri $resource_Uri -uri_Filter $PSBoundParameters -allPages:$allPages

            if ($results) {
                Set-PokeCachedData -name $cachedDataName -timeStamp $runTime -data $results
            }

        }
        else {

            Write-Verbose "Returning cached data: Cached is [ $( (New-TimeSpan -Start $cachedData.cachedTime -End $(Get-Date)).Minutes)min ] old"
            $results = $cachedData
            $results.PSObject.Properties.Remove('staleCache')
            $results.PSObject.Properties.Remove('cachedTime')

        }

        return $results

    }

    end {}

}
#EndRegion '.\Public\location\Get-PokeLocationPalParkArea.ps1' 155
#Region '.\Public\location\Get-PokeLocationRegion.ps1' -1

function Get-PokeLocationRegion {
<#
    .SYNOPSIS
        Gets regions from PokeAPI

    .DESCRIPTION
        The Get-PokeLocationRegion cmdlet gets regions from PokeAPI

        A region is an organized area of the Pokemon world

        Most often, the main difference between regions is the species of
        Pokemon that can be encountered within them.

    .PARAMETER id
        Defines id of the resource

    .PARAMETER name
        Defines name of the resource

    .PARAMETER offset
        Defines the page number to return

        By default only 20 resources are returned

    .PARAMETER limit
        Defines the amount of resources to return with each page

        By default only 20 resources are returned

    .PARAMETER allPages
        Returns all resources from an endpoint

        As of 2024-02, there is no cap on how many resources can be
        returned using the limit parameter. There is currently no real
        use for this parameter and it was included simply to account if
        pagination is introduced.

    .PARAMETER updateCache
        Defines if the cache is refreshed regardless of age

        By default the cache is refreshed every 30min

    .EXAMPLE
        Get-PokeLocationRegion

        Gets the first 20 regions sorted by id

    .EXAMPLE
        Get-PokeLocationRegion -id 1

        Gets the region with the defined id

    .EXAMPLE
        Get-PokeLocationRegion -name ditto

        Gets the region with the defined name

    .EXAMPLE
        Get-PokeLocationRegion -offset 151 -limit 100

        Gets the first 100 resources starting at resources with
        an id over 151

    .NOTES
        n/a

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/location/Get-PokeLocationRegion.html
#>

    [CmdletBinding(DefaultParameterSetName = 'index_ByAll')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ById')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$id,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ByName')]
        [ValidateNotNullOrEmpty()]
        [string]$name,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$offset,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$limit,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [Switch]$allPages,

        [Parameter(Mandatory = $false)]
        [Switch]$updateCache
    )

    begin {

        $functionName   = $MyInvocation.InvocationName
        $cachedDataName = $functionName + '_Cached' -replace '-','_'
        $parameterName  = $functionName + '_Parameters' -replace '-','_'
        $runTime        = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    }

    process {

        Write-Verbose "Running [ $functionName ] with [ $($PSCmdlet.ParameterSetName) ] parameterSet"
        Set-Variable -Name $parameterName -Value $PSBoundParameters -Scope Global -Force

        switch ( $PSCmdlet.ParameterSetName ) {

            'index_ByAll'  {
                $resource_uri   = "/region"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName
            }
            'index_ById'   {
                $resource_uri   = "/region/$id"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -id $id
            }
            'index_ByName' {
                $resource_uri = ("/region/$name").ToLower()
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -name $name
            }

        }

        if ( $null -eq $cachedData -or $cachedData.staleCache -or $updateCache ) {

            if ($cachedData.staleCache) {
                Write-Verbose "Refreshing cached data: Old Timestamp [ $($cachedData.cachedTime) | New Timestamp [ $([DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")) ]"
            }

            $results = Invoke-PokeRequest -method GET -resource_Uri $resource_Uri -uri_Filter $PSBoundParameters -allPages:$allPages

            if ($results) {
                Set-PokeCachedData -name $cachedDataName -timeStamp $runTime -data $results
            }

        }
        else {

            Write-Verbose "Returning cached data: Cached is [ $( (New-TimeSpan -Start $cachedData.cachedTime -End $(Get-Date)).Minutes)min ] old"
            $results = $cachedData
            $results.PSObject.Properties.Remove('staleCache')
            $results.PSObject.Properties.Remove('cachedTime')

        }

        return $results

    }

    end {}

}
#EndRegion '.\Public\location\Get-PokeLocationRegion.ps1' 156
#Region '.\Public\machine\Get-PokeMachine.ps1' -1

function Get-PokeMachine {
<#
    .SYNOPSIS
        Gets machines from PokeAPI

    .DESCRIPTION
        The Get-PokeMachine cmdlet gets machines from PokeAPI

        Machines are the representation of items that teach moves to Pokemon

        They vary from version to version, so it is not certain that one specific
        TM or HM corresponds to a single Machine

    .PARAMETER id
        Defines id of the resource

    .PARAMETER offset
        Defines the page number to return

        By default only 20 resources are returned

    .PARAMETER limit
        Defines the amount of resources to return with each page

        By default only 20 resources are returned

    .PARAMETER allPages
        Returns all resources from an endpoint

        As of 2024-02, there is no cap on how many resources can be
        returned using the limit parameter. There is currently no real
        use for this parameter and it was included simply to account if
        pagination is introduced.

    .PARAMETER updateCache
        Defines if the cache is refreshed regardless of age

        By default the cache is refreshed every 30min

    .EXAMPLE
        Get-PokeMachine

        Gets the first 20 machines sorted by id

    .EXAMPLE
        Get-PokeMachine -id 1

        Gets the machine with the defined id

    .EXAMPLE
        Get-PokeMachine -offset 151 -limit 100

        Gets the first 100 resources starting at resources with
        an id over 151

    .NOTES
        n/a

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/machine/Get-PokeMachine.html
#>

    [CmdletBinding(DefaultParameterSetName = 'index_ByAll')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ById')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$id,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$offset,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$limit,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [Switch]$allPages,

        [Parameter(Mandatory = $false)]
        [Switch]$updateCache
    )

    begin {

        $functionName   = $MyInvocation.InvocationName
        $cachedDataName = $functionName + '_Cached' -replace '-','_'
        $parameterName  = $functionName + '_Parameters' -replace '-','_'
        $runTime        = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    }

    process {

        Write-Verbose "Running [ $functionName ] with [ $($PSCmdlet.ParameterSetName) ] parameterSet"
        Set-Variable -Name $parameterName -Value $PSBoundParameters -Scope Global -Force

        switch ( $PSCmdlet.ParameterSetName ) {

            'index_ByAll'  {
                $resource_uri   = "/machine"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName
            }
            'index_ById'   {
                $resource_uri   = "/machine/$id"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -id $id
            }

        }

        if ( $null -eq $cachedData -or $cachedData.staleCache -or $updateCache ) {

            if ($cachedData.staleCache) {
                Write-Verbose "Refreshing cached data: Old Timestamp [ $($cachedData.cachedTime) | New Timestamp [ $([DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")) ]"
            }

            $results = Invoke-PokeRequest -method GET -resource_Uri $resource_Uri -uri_Filter $PSBoundParameters -allPages:$allPages

            if ($results) {
                Set-PokeCachedData -name $cachedDataName -timeStamp $runTime -data $results
            }

        }
        else {

            Write-Verbose "Returning cached data: Cached is [ $( (New-TimeSpan -Start $cachedData.cachedTime -End $(Get-Date)).Minutes)min ] old"
            $results = $cachedData
            $results.PSObject.Properties.Remove('staleCache')
            $results.PSObject.Properties.Remove('cachedTime')

        }

        return $results

    }

    end {}

}
#EndRegion '.\Public\machine\Get-PokeMachine.ps1' 140
#Region '.\Public\move\Get-PokeMove.ps1' -1

function Get-PokeMove {
<#
    .SYNOPSIS
        Gets moves from PokeAPI

    .DESCRIPTION
        The Get-PokeMove cmdlet gets moves from PokeAPI

        Moves are the skills of Pokemon in battle. In battle, a Pokemon uses one move each turn.

        Some moves (including those learned by Hidden Machine) can be used outside of battle as well,
        usually for the purpose of removing obstacles or exploring new areas.

    .PARAMETER id
        Defines id of the resource

    .PARAMETER name
        Defines name of the resource

    .PARAMETER offset
        Defines the page number to return

        By default only 20 resources are returned

    .PARAMETER limit
        Defines the amount of resources to return with each page

        By default only 20 resources are returned

    .PARAMETER allPages
        Returns all resources from an endpoint

        As of 2024-02, there is no cap on how many resources can be
        returned using the limit parameter. There is currently no real
        use for this parameter and it was included simply to account if
        pagination is introduced.

    .PARAMETER updateCache
        Defines if the cache is refreshed regardless of age

        By default the cache is refreshed every 30min

    .EXAMPLE
        Get-PokeMove

        Gets the first 20 moves sorted by id

    .EXAMPLE
        Get-PokeMove -id 1

        Gets the move with the defined id

    .EXAMPLE
        Get-PokeMove -name ditto

        Gets the move with the defined name

    .EXAMPLE
        Get-PokeMove -offset 151 -limit 100

        Gets the first 100 resources starting at resources with
        an id over 151

    .NOTES
        n/a

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/move/Get-PokeMove.html
#>

    [CmdletBinding(DefaultParameterSetName = 'index_ByAll')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ById')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$id,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ByName')]
        [ValidateNotNullOrEmpty()]
        [string]$name,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$offset,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$limit,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [Switch]$allPages,

        [Parameter(Mandatory = $false)]
        [Switch]$updateCache
    )

    begin {

        $functionName   = $MyInvocation.InvocationName
        $cachedDataName = $functionName + '_Cached' -replace '-','_'
        $parameterName  = $functionName + '_Parameters' -replace '-','_'
        $runTime        = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    }

    process {

        Write-Verbose "Running [ $functionName ] with [ $($PSCmdlet.ParameterSetName) ] parameterSet"
        Set-Variable -Name $parameterName -Value $PSBoundParameters -Scope Global -Force

        switch ( $PSCmdlet.ParameterSetName ) {

            'index_ByAll'  {
                $resource_uri   = "/move"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName
            }
            'index_ById'   {
                $resource_uri   = "/move/$id"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -id $id
            }
            'index_ByName' {
                $resource_uri = ("/move/$name").ToLower()
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -name $name
            }

        }

        if ( $null -eq $cachedData -or $cachedData.staleCache -or $updateCache ) {

            if ($cachedData.staleCache) {
                Write-Verbose "Refreshing cached data: Old Timestamp [ $($cachedData.cachedTime) | New Timestamp [ $([DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")) ]"
            }

            $results = Invoke-PokeRequest -method GET -resource_Uri $resource_Uri -uri_Filter $PSBoundParameters -allPages:$allPages

            if ($results) {
                Set-PokeCachedData -name $cachedDataName -timeStamp $runTime -data $results
            }

        }
        else {

            Write-Verbose "Returning cached data: Cached is [ $( (New-TimeSpan -Start $cachedData.cachedTime -End $(Get-Date)).Minutes)min ] old"
            $results = $cachedData
            $results.PSObject.Properties.Remove('staleCache')
            $results.PSObject.Properties.Remove('cachedTime')

        }

        return $results

    }

    end {}

}
#EndRegion '.\Public\move\Get-PokeMove.ps1' 156
#Region '.\Public\move\Get-PokeMoveAilment.ps1' -1

function Get-PokeMoveAilment {
<#
    .SYNOPSIS
        Gets move ailments from PokeAPI

    .DESCRIPTION
        The Get-PokeMoveAilment cmdlet gets move ailments from PokeAPI

        Move Ailments are status conditions caused by moves used during battle

    .PARAMETER id
        Defines id of the resource

    .PARAMETER name
        Defines name of the resource

    .PARAMETER offset
        Defines the page number to return

        By default only 20 resources are returned

    .PARAMETER limit
        Defines the amount of resources to return with each page

        By default only 20 resources are returned

    .PARAMETER allPages
        Returns all resources from an endpoint

        As of 2024-02, there is no cap on how many resources can be
        returned using the limit parameter. There is currently no real
        use for this parameter and it was included simply to account if
        pagination is introduced.

    .PARAMETER updateCache
        Defines if the cache is refreshed regardless of age

        By default the cache is refreshed every 30min

    .EXAMPLE
        Get-PokeMoveAilment

        Gets the first 20 move ailments sorted by id

    .EXAMPLE
        Get-PokeMoveAilment -id 1

        Gets the move ailment with the defined id

    .EXAMPLE
        Get-PokeMoveAilment -name ditto

        Gets the move ailment with the defined name

    .EXAMPLE
        Get-PokeMoveAilment -offset 151 -limit 100

        Gets the first 100 resources starting at resources with
        an id over 151

    .NOTES
        n/a

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/move/Get-PokeMoveAilment.html
#>

    [CmdletBinding(DefaultParameterSetName = 'index_ByAll')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ById')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$id,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ByName')]
        [ValidateNotNullOrEmpty()]
        [string]$name,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$offset,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$limit,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [Switch]$allPages,

        [Parameter(Mandatory = $false)]
        [Switch]$updateCache
    )

    begin {

        $functionName   = $MyInvocation.InvocationName
        $cachedDataName = $functionName + '_Cached' -replace '-','_'
        $parameterName  = $functionName + '_Parameters' -replace '-','_'
        $runTime        = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    }

    process {

        Write-Verbose "Running [ $functionName ] with [ $($PSCmdlet.ParameterSetName) ] parameterSet"
        Set-Variable -Name $parameterName -Value $PSBoundParameters -Scope Global -Force

        switch ( $PSCmdlet.ParameterSetName ) {

            'index_ByAll'  {
                $resource_uri   = "/move-ailment"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName
            }
            'index_ById'   {
                $resource_uri   = "/move-ailment/$id"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -id $id
            }
            'index_ByName' {
                $resource_uri = ("/move-ailment/$name").ToLower()
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -name $name
            }

        }

        if ( $null -eq $cachedData -or $cachedData.staleCache -or $updateCache ) {

            if ($cachedData.staleCache) {
                Write-Verbose "Refreshing cached data: Old Timestamp [ $($cachedData.cachedTime) | New Timestamp [ $([DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")) ]"
            }

            $results = Invoke-PokeRequest -method GET -resource_Uri $resource_Uri -uri_Filter $PSBoundParameters -allPages:$allPages

            if ($results) {
                Set-PokeCachedData -name $cachedDataName -timeStamp $runTime -data $results
            }

        }
        else {

            Write-Verbose "Returning cached data: Cached is [ $( (New-TimeSpan -Start $cachedData.cachedTime -End $(Get-Date)).Minutes)min ] old"
            $results = $cachedData
            $results.PSObject.Properties.Remove('staleCache')
            $results.PSObject.Properties.Remove('cachedTime')

        }

        return $results

    }

    end {}

}
#EndRegion '.\Public\move\Get-PokeMoveAilment.ps1' 153
#Region '.\Public\move\Get-PokeMoveBattleStyle.ps1' -1

function Get-PokeMoveBattleStyle {
<#
    .SYNOPSIS
        Gets move battle styles from PokeAPI

    .DESCRIPTION
        The Get-PokeMoveBattleStyle cmdlet gets move battle styles from PokeAPI

        Styles of moves when used in the Battle Palace

    .PARAMETER id
        Defines id of the resource

    .PARAMETER name
        Defines name of the resource

    .PARAMETER offset
        Defines the page number to return

        By default only 20 resources are returned

    .PARAMETER limit
        Defines the amount of resources to return with each page

        By default only 20 resources are returned

    .PARAMETER allPages
        Returns all resources from an endpoint

        As of 2024-02, there is no cap on how many resources can be
        returned using the limit parameter. There is currently no real
        use for this parameter and it was included simply to account if
        pagination is introduced.

    .PARAMETER updateCache
        Defines if the cache is refreshed regardless of age

        By default the cache is refreshed every 30min

    .EXAMPLE
        Get-PokeMoveBattleStyle

        Gets the first 20 move battle styles sorted by id

    .EXAMPLE
        Get-PokeMoveBattleStyle -id 1

        Gets the move battle style with the defined id

    .EXAMPLE
        Get-PokeMoveBattleStyle -name ditto

        Gets the move battle style with the defined name

    .EXAMPLE
        Get-PokeMoveBattleStyle -offset 151 -limit 100

        Gets the first 100 resources starting at resources with
        an id over 151

    .NOTES
        n/a

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/move/Get-PokeMoveBattleStyle.html
#>

    [CmdletBinding(DefaultParameterSetName = 'index_ByAll')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ById')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$id,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ByName')]
        [ValidateNotNullOrEmpty()]
        [string]$name,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$offset,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$limit,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [Switch]$allPages,

        [Parameter(Mandatory = $false)]
        [Switch]$updateCache
    )

    begin {

        $functionName   = $MyInvocation.InvocationName
        $cachedDataName = $functionName + '_Cached' -replace '-','_'
        $parameterName  = $functionName + '_Parameters' -replace '-','_'
        $runTime        = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    }

    process {

        Write-Verbose "Running [ $functionName ] with [ $($PSCmdlet.ParameterSetName) ] parameterSet"
        Set-Variable -Name $parameterName -Value $PSBoundParameters -Scope Global -Force

        switch ( $PSCmdlet.ParameterSetName ) {

            'index_ByAll'  {
                $resource_uri   = "/move-battle-style"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName
            }
            'index_ById'   {
                $resource_uri   = "/move-battle-style/$id"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -id $id
            }
            'index_ByName' {
                $resource_uri = ("/move-battle-style/$name").ToLower()
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -name $name
            }

        }

        if ( $null -eq $cachedData -or $cachedData.staleCache -or $updateCache ) {

            if ($cachedData.staleCache) {
                Write-Verbose "Refreshing cached data: Old Timestamp [ $($cachedData.cachedTime) | New Timestamp [ $([DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")) ]"
            }

            $results = Invoke-PokeRequest -method GET -resource_Uri $resource_Uri -uri_Filter $PSBoundParameters -allPages:$allPages

            if ($results) {
                Set-PokeCachedData -name $cachedDataName -timeStamp $runTime -data $results
            }

        }
        else {

            Write-Verbose "Returning cached data: Cached is [ $( (New-TimeSpan -Start $cachedData.cachedTime -End $(Get-Date)).Minutes)min ] old"
            $results = $cachedData
            $results.PSObject.Properties.Remove('staleCache')
            $results.PSObject.Properties.Remove('cachedTime')

        }

        return $results

    }

    end {}

}
#EndRegion '.\Public\move\Get-PokeMoveBattleStyle.ps1' 153
#Region '.\Public\move\Get-PokeMoveCategory.ps1' -1

function Get-PokeMoveCategory {
<#
    .SYNOPSIS
        Gets move categories from PokeAPI

    .DESCRIPTION
        The Get-PokeMoveCategory cmdlet gets move categories from PokeAPI

        Very general categories that loosely group move effects

    .PARAMETER id
        Defines id of the resource

    .PARAMETER name
        Defines name of the resource

    .PARAMETER offset
        Defines the page number to return

        By default only 20 resources are returned

    .PARAMETER limit
        Defines the amount of resources to return with each page

        By default only 20 resources are returned

    .PARAMETER allPages
        Returns all resources from an endpoint

        As of 2024-02, there is no cap on how many resources can be
        returned using the limit parameter. There is currently no real
        use for this parameter and it was included simply to account if
        pagination is introduced.

    .PARAMETER updateCache
        Defines if the cache is refreshed regardless of age

        By default the cache is refreshed every 30min

    .EXAMPLE
        Get-PokeMoveCategory

        Gets the first 20 move categories sorted by id

    .EXAMPLE
        Get-PokeMoveCategory -id 1

        Gets the move category with the defined id

    .EXAMPLE
        Get-PokeMoveCategory -name ditto

        Gets the move category with the defined name

    .EXAMPLE
        Get-PokeMoveCategory -offset 151 -limit 100

        Gets the first 100 resources starting at resources with
        an id over 151

    .NOTES
        n/a

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/move/Get-PokeMoveCategory.html
#>

    [CmdletBinding(DefaultParameterSetName = 'index_ByAll')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ById')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$id,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ByName')]
        [ValidateNotNullOrEmpty()]
        [string]$name,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$offset,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$limit,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [Switch]$allPages,

        [Parameter(Mandatory = $false)]
        [Switch]$updateCache
    )

    begin {

        $functionName   = $MyInvocation.InvocationName
        $cachedDataName = $functionName + '_Cached' -replace '-','_'
        $parameterName  = $functionName + '_Parameters' -replace '-','_'
        $runTime        = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    }

    process {

        Write-Verbose "Running [ $functionName ] with [ $($PSCmdlet.ParameterSetName) ] parameterSet"
        Set-Variable -Name $parameterName -Value $PSBoundParameters -Scope Global -Force

        switch ( $PSCmdlet.ParameterSetName ) {

            'index_ByAll'  {
                $resource_uri   = "/move-category"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName
            }
            'index_ById'   {
                $resource_uri   = "/move-category/$id"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -id $id
            }
            'index_ByName' {
                $resource_uri = ("/move-category/$name").ToLower()
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -name $name
            }

        }

        if ( $null -eq $cachedData -or $cachedData.staleCache -or $updateCache ) {

            if ($cachedData.staleCache) {
                Write-Verbose "Refreshing cached data: Old Timestamp [ $($cachedData.cachedTime) | New Timestamp [ $([DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")) ]"
            }

            $results = Invoke-PokeRequest -method GET -resource_Uri $resource_Uri -uri_Filter $PSBoundParameters -allPages:$allPages

            if ($results) {
                Set-PokeCachedData -name $cachedDataName -timeStamp $runTime -data $results
            }

        }
        else {

            Write-Verbose "Returning cached data: Cached is [ $( (New-TimeSpan -Start $cachedData.cachedTime -End $(Get-Date)).Minutes)min ] old"
            $results = $cachedData
            $results.PSObject.Properties.Remove('staleCache')
            $results.PSObject.Properties.Remove('cachedTime')

        }

        return $results

    }

    end {}

}
#EndRegion '.\Public\move\Get-PokeMoveCategory.ps1' 153
#Region '.\Public\move\Get-PokeMoveDamageClass.ps1' -1

function Get-PokeMoveDamageClass {
<#
    .SYNOPSIS
        Gets move damage classes from PokeAPI

    .DESCRIPTION
        The Get-PokeMoveDamageClass cmdlet gets move damage classes from PokeAPI

        Damage classes moves can have, e.g. physical, special, or non-damaging

    .PARAMETER id
        Defines id of the resource

    .PARAMETER name
        Defines name of the resource

    .PARAMETER offset
        Defines the page number to return

        By default only 20 resources are returned

    .PARAMETER limit
        Defines the amount of resources to return with each page

        By default only 20 resources are returned

    .PARAMETER allPages
        Returns all resources from an endpoint

        As of 2024-02, there is no cap on how many resources can be
        returned using the limit parameter. There is currently no real
        use for this parameter and it was included simply to account if
        pagination is introduced.

    .PARAMETER updateCache
        Defines if the cache is refreshed regardless of age

        By default the cache is refreshed every 30min

    .EXAMPLE
        Get-PokeMoveDamageClass

        Gets the first 20 move damage classes sorted by id

    .EXAMPLE
        Get-PokeMoveDamageClass -id 1

        Gets the move damage class with the defined id

    .EXAMPLE
        Get-PokeMoveDamageClass -name ditto

        Gets the move damage class with the defined name

    .EXAMPLE
        Get-PokeMoveDamageClass -offset 151 -limit 100

        Gets the first 100 resources starting at resources with
        an id over 151

    .NOTES
        n/a

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/move/Get-PokeMoveDamageClass.html
#>

    [CmdletBinding(DefaultParameterSetName = 'index_ByAll')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ById')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$id,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ByName')]
        [ValidateNotNullOrEmpty()]
        [string]$name,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$offset,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$limit,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [Switch]$allPages,

        [Parameter(Mandatory = $false)]
        [Switch]$updateCache
    )

    begin {

        $functionName   = $MyInvocation.InvocationName
        $cachedDataName = $functionName + '_Cached' -replace '-','_'
        $parameterName  = $functionName + '_Parameters' -replace '-','_'
        $runTime        = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    }

    process {

        Write-Verbose "Running [ $functionName ] with [ $($PSCmdlet.ParameterSetName) ] parameterSet"
        Set-Variable -Name $parameterName -Value $PSBoundParameters -Scope Global -Force

        switch ( $PSCmdlet.ParameterSetName ) {

            'index_ByAll'  {
                $resource_uri   = "/move-damage-class"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName
            }
            'index_ById'   {
                $resource_uri   = "/move-damage-class/$id"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -id $id
            }
            'index_ByName' {
                $resource_uri = ("/move-damage-class/$name").ToLower()
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -name $name
            }

        }

        if ( $null -eq $cachedData -or $cachedData.staleCache -or $updateCache ) {

            if ($cachedData.staleCache) {
                Write-Verbose "Refreshing cached data: Old Timestamp [ $($cachedData.cachedTime) | New Timestamp [ $([DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")) ]"
            }

            $results = Invoke-PokeRequest -method GET -resource_Uri $resource_Uri -uri_Filter $PSBoundParameters -allPages:$allPages

            if ($results) {
                Set-PokeCachedData -name $cachedDataName -timeStamp $runTime -data $results
            }

        }
        else {

            Write-Verbose "Returning cached data: Cached is [ $( (New-TimeSpan -Start $cachedData.cachedTime -End $(Get-Date)).Minutes)min ] old"
            $results = $cachedData
            $results.PSObject.Properties.Remove('staleCache')
            $results.PSObject.Properties.Remove('cachedTime')

        }

        return $results

    }

    end {}

}
#EndRegion '.\Public\move\Get-PokeMoveDamageClass.ps1' 153
#Region '.\Public\move\Get-PokeMoveLearnMethod.ps1' -1

function Get-PokeMoveLearnMethod {
<#
    .SYNOPSIS
        Gets move learn methods from PokeAPI

    .DESCRIPTION
        The Get-PokeMoveLearnMethod cmdlet gets move learn methods from PokeAPI

        Methods by which Pokemon can learn moves

    .PARAMETER id
        Defines id of the resource

    .PARAMETER name
        Defines name of the resource

    .PARAMETER offset
        Defines the page number to return

        By default only 20 resources are returned

    .PARAMETER limit
        Defines the amount of resources to return with each page

        By default only 20 resources are returned

    .PARAMETER allPages
        Returns all resources from an endpoint

        As of 2024-02, there is no cap on how many resources can be
        returned using the limit parameter. There is currently no real
        use for this parameter and it was included simply to account if
        pagination is introduced.

    .PARAMETER updateCache
        Defines if the cache is refreshed regardless of age

        By default the cache is refreshed every 30min

    .EXAMPLE
        Get-PokeMoveLearnMethod

        Gets the first 20 move learn methods sorted by id

    .EXAMPLE
        Get-PokeMoveLearnMethod -id 1

        Gets the move learn method with the defined id

    .EXAMPLE
        Get-PokeMoveLearnMethod -name ditto

        Gets the move learn method with the defined name

    .EXAMPLE
        Get-PokeMoveLearnMethod -offset 151 -limit 100

        Gets the first 100 resources starting at resources with
        an id over 151

    .NOTES
        n/a

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/move/Get-PokeMoveLearnMethod.html
#>

    [CmdletBinding(DefaultParameterSetName = 'index_ByAll')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ById')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$id,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ByName')]
        [ValidateNotNullOrEmpty()]
        [string]$name,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$offset,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$limit,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [Switch]$allPages,

        [Parameter(Mandatory = $false)]
        [Switch]$updateCache
    )

    begin {

        $functionName   = $MyInvocation.InvocationName
        $cachedDataName = $functionName + '_Cached' -replace '-','_'
        $parameterName  = $functionName + '_Parameters' -replace '-','_'
        $runTime        = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    }

    process {

        Write-Verbose "Running [ $functionName ] with [ $($PSCmdlet.ParameterSetName) ] parameterSet"
        Set-Variable -Name $parameterName -Value $PSBoundParameters -Scope Global -Force

        switch ( $PSCmdlet.ParameterSetName ) {

            'index_ByAll'  {
                $resource_uri   = "/move-learn-method"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName
            }
            'index_ById'   {
                $resource_uri   = "/move-learn-method/$id"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -id $id
            }
            'index_ByName' {
                $resource_uri = ("/move-learn-method/$name").ToLower()
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -name $name
            }

        }

        if ( $null -eq $cachedData -or $cachedData.staleCache -or $updateCache ) {

            if ($cachedData.staleCache) {
                Write-Verbose "Refreshing cached data: Old Timestamp [ $($cachedData.cachedTime) | New Timestamp [ $([DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")) ]"
            }

            $results = Invoke-PokeRequest -method GET -resource_Uri $resource_Uri -uri_Filter $PSBoundParameters -allPages:$allPages

            if ($results) {
                Set-PokeCachedData -name $cachedDataName -timeStamp $runTime -data $results
            }

        }
        else {

            Write-Verbose "Returning cached data: Cached is [ $( (New-TimeSpan -Start $cachedData.cachedTime -End $(Get-Date)).Minutes)min ] old"
            $results = $cachedData
            $results.PSObject.Properties.Remove('staleCache')
            $results.PSObject.Properties.Remove('cachedTime')

        }

        return $results

    }

    end {}

}
#EndRegion '.\Public\move\Get-PokeMoveLearnMethod.ps1' 153
#Region '.\Public\move\Get-PokeMoveTarget.ps1' -1

function Get-PokeMoveTarget {
<#
    .SYNOPSIS
        Gets move targets from PokeAPI

    .DESCRIPTION
        The Get-PokeMoveTarget cmdlet gets move targets from PokeAPI

        Targets moves can be directed at during battle

        Targets can be Pokemon, environments or even other moves.

    .PARAMETER id
        Defines id of the resource

    .PARAMETER name
        Defines name of the resource

    .PARAMETER offset
        Defines the page number to return

        By default only 20 resources are returned

    .PARAMETER limit
        Defines the amount of resources to return with each page

        By default only 20 resources are returned

    .PARAMETER allPages
        Returns all resources from an endpoint

        As of 2024-02, there is no cap on how many resources can be
        returned using the limit parameter. There is currently no real
        use for this parameter and it was included simply to account if
        pagination is introduced.

    .PARAMETER updateCache
        Defines if the cache is refreshed regardless of age

        By default the cache is refreshed every 30min

    .EXAMPLE
        Get-PokeMoveTarget

        Gets the first 20 move targets sorted by id

    .EXAMPLE
        Get-PokeMoveTarget -id 1

        Gets the move target with the defined id

    .EXAMPLE
        Get-PokeMoveTarget -name ditto

        Gets the move target with the defined name

    .EXAMPLE
        Get-PokeMoveTarget -offset 151 -limit 100

        Gets the first 100 resources starting at resources with
        an id over 151

    .NOTES
        n/a

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/move/Get-PokeMoveTarget.html
#>

    [CmdletBinding(DefaultParameterSetName = 'index_ByAll')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ById')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$id,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ByName')]
        [ValidateNotNullOrEmpty()]
        [string]$name,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$offset,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$limit,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [Switch]$allPages,

        [Parameter(Mandatory = $false)]
        [Switch]$updateCache
    )

    begin {

        $functionName   = $MyInvocation.InvocationName
        $cachedDataName = $functionName + '_Cached' -replace '-','_'
        $parameterName  = $functionName + '_Parameters' -replace '-','_'
        $runTime        = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    }

    process {

        Write-Verbose "Running [ $functionName ] with [ $($PSCmdlet.ParameterSetName) ] parameterSet"
        Set-Variable -Name $parameterName -Value $PSBoundParameters -Scope Global -Force

        switch ( $PSCmdlet.ParameterSetName ) {

            'index_ByAll'  {
                $resource_uri   = "/move-target"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName
            }
            'index_ById'   {
                $resource_uri   = "/move-target/$id"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -id $id
            }
            'index_ByName' {
                $resource_uri = ("/move-target/$name").ToLower()
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -name $name
            }

        }

        if ( $null -eq $cachedData -or $cachedData.staleCache -or $updateCache ) {

            if ($cachedData.staleCache) {
                Write-Verbose "Refreshing cached data: Old Timestamp [ $($cachedData.cachedTime) | New Timestamp [ $([DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")) ]"
            }

            $results = Invoke-PokeRequest -method GET -resource_Uri $resource_Uri -uri_Filter $PSBoundParameters -allPages:$allPages

            if ($results) {
                Set-PokeCachedData -name $cachedDataName -timeStamp $runTime -data $results
            }

        }
        else {

            Write-Verbose "Returning cached data: Cached is [ $( (New-TimeSpan -Start $cachedData.cachedTime -End $(Get-Date)).Minutes)min ] old"
            $results = $cachedData
            $results.PSObject.Properties.Remove('staleCache')
            $results.PSObject.Properties.Remove('cachedTime')

        }

        return $results

    }

    end {}

}
#EndRegion '.\Public\move\Get-PokeMoveTarget.ps1' 155
#Region '.\Public\pokemon\Get-PokePokemon.ps1' -1

function Get-PokePokemon {
<#
    .SYNOPSIS
        Gets Pokemon from PokeAPI

    .DESCRIPTION
        The Get-PokePokemon cmdlet gets Pokemon from PokeAPI

        Pokemon are the creatures that inhabit the world of the Pokemon games.
        They can be caught using Pokeballs and trained by battling with other Pokemon.
        Each Pokemon belongs to a specific species but may take on a variant which makes
        it differ from other Pokemon of the same species, such as base stats,
        available abilities and typings.

    .PARAMETER id
        Defines id of the resource

    .PARAMETER name
        Defines name of the resource

    .PARAMETER offset
        Defines the page number to return

        By default only 20 resources are returned

    .PARAMETER limit
        Defines the amount of resources to return with each page

        By default only 20 resources are returned

    .PARAMETER allPages
        Returns all resources from an endpoint

        As of 2024-02, there is no cap on how many resources can be
        returned using the limit parameter. There is currently no real
        use for this parameter and it was included simply to account if
        pagination is introduced.

    .PARAMETER updateCache
        Defines if the cache is refreshed regardless of age

        By default the cache is refreshed every 30min

    .EXAMPLE
        Get-PokePokemon

        Gets the first 20 pokemon sorted by id

    .EXAMPLE
        Get-PokePokemon -id 1

        Gets the pokemon with the defined id

    .EXAMPLE
        Get-PokePokemon -name ditto

        Gets the pokemon with the defined name

    .EXAMPLE
        Get-PokePokemon -offset 151 -limit 100

        Gets the first 100 resources starting at resources with
        an id over 151

    .NOTES
        n/a

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/pokemon/Get-PokePokemon.html
#>

    [CmdletBinding(DefaultParameterSetName = 'index_ByAll')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ById')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$id,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ByName')]
        [ValidateNotNullOrEmpty()]
        [string]$name,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$offset,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$limit,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [Switch]$allPages,

        [Parameter(Mandatory = $false)]
        [Switch]$updateCache
    )

    begin {

        $functionName   = $MyInvocation.InvocationName
        $cachedDataName = $functionName + '_Cached' -replace '-','_'
        $parameterName  = $functionName + '_Parameters' -replace '-','_'
        $runTime        = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    }

    process {

        Write-Verbose "Running [ $functionName ] with [ $($PSCmdlet.ParameterSetName) ] parameterSet"
        Set-Variable -Name $parameterName -Value $PSBoundParameters -Scope Global -Force

        switch ( $PSCmdlet.ParameterSetName ) {

            'index_ByAll'  {
                $resource_uri   = "/pokemon"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName
            }
            'index_ById'   {
                $resource_uri   = "/pokemon/$id"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -id $id
            }
            'index_ByName' {
                $resource_uri = ("/pokemon/$name").ToLower()
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -name $name
            }

        }

        if ( $null -eq $cachedData -or $cachedData.staleCache -or $updateCache ) {

            if ($cachedData.staleCache) {
                Write-Verbose "Refreshing cached data: Old Timestamp [ $($cachedData.cachedTime) | New Timestamp [ $([DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")) ]"
            }

            $results = Invoke-PokeRequest -method GET -resource_Uri $resource_Uri -uri_Filter $PSBoundParameters -allPages:$allPages

            if ($results) {
                Set-PokeCachedData -name $cachedDataName -timeStamp $runTime -data $results
            }

        }
        else {

            Write-Verbose "Returning cached data: Cached is [ $( (New-TimeSpan -Start $cachedData.cachedTime -End $(Get-Date)).Minutes)min ] old"
            $results = $cachedData
            $results.PSObject.Properties.Remove('staleCache')
            $results.PSObject.Properties.Remove('cachedTime')

        }

        return $results

    }

    end {}

}
#EndRegion '.\Public\pokemon\Get-PokePokemon.ps1' 157
#Region '.\Public\pokemon\Get-PokePokemonAbility.ps1' -1

function Get-PokePokemonAbility {
<#
    .SYNOPSIS
        Gets Pokemon abilities from PokeAPI

    .DESCRIPTION
        The Get-PokePokemonAbility cmdlet gets Pokemon abilities from PokeAPI

        Abilities provide passive effects for Pokemon in battle or in the overworld.
        Pokemon have multiple possible abilities but can have only one ability at a time

    .PARAMETER id
        Defines id of the resource

    .PARAMETER name
        Defines name of the resource

    .PARAMETER offset
        Defines the page number to return

        By default only 20 resources are returned

    .PARAMETER limit
        Defines the amount of resources to return with each page

        By default only 20 resources are returned

    .PARAMETER allPages
        Returns all resources from an endpoint

        As of 2024-02, there is no cap on how many resources can be
        returned using the limit parameter. There is currently no real
        use for this parameter and it was included simply to account if
        pagination is introduced.

    .PARAMETER updateCache
        Defines if the cache is refreshed regardless of age

        By default the cache is refreshed every 30min

    .EXAMPLE
        Get-PokePokemonAbility

        Gets the first 20 Pokemon abilities sorted by id

    .EXAMPLE
        Get-PokePokemonAbility -id 1

        Gets the Pokemon ability with the defined id

    .EXAMPLE
        Get-PokePokemonAbility -name ditto

        Gets the Pokemon ability with the defined name

    .EXAMPLE
        Get-PokePokemonAbility -offset 151 -limit 100

        Gets the first 100 resources starting at resources with
        an id over 151

    .NOTES
        n/a

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/pokemon/Get-PokePokemonAbility.html
#>

    [CmdletBinding(DefaultParameterSetName = 'index_ByAll')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ById')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$id,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ByName')]
        [ValidateNotNullOrEmpty()]
        [string]$name,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$offset,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$limit,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [Switch]$allPages,

        [Parameter(Mandatory = $false)]
        [Switch]$updateCache
    )

    begin {

        $functionName   = $MyInvocation.InvocationName
        $cachedDataName = $functionName + '_Cached' -replace '-','_'
        $parameterName  = $functionName + '_Parameters' -replace '-','_'
        $runTime        = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    }

    process {

        Write-Verbose "Running [ $functionName ] with [ $($PSCmdlet.ParameterSetName) ] parameterSet"
        Set-Variable -Name $parameterName -Value $PSBoundParameters -Scope Global -Force

        switch ( $PSCmdlet.ParameterSetName ) {

            'index_ByAll'  {
                $resource_uri   = "/ability"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName
            }
            'index_ById'   {
                $resource_uri   = "/ability/$id"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -id $id
            }
            'index_ByName' {
                $resource_uri = ("/ability/$name").ToLower()
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -name $name
            }

        }

        if ( $null -eq $cachedData -or $cachedData.staleCache -or $updateCache ) {

            if ($cachedData.staleCache) {
                Write-Verbose "Refreshing cached data: Old Timestamp [ $($cachedData.cachedTime) | New Timestamp [ $([DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")) ]"
            }

            $results = Invoke-PokeRequest -method GET -resource_Uri $resource_Uri -uri_Filter $PSBoundParameters -allPages:$allPages

            if ($results) {
                Set-PokeCachedData -name $cachedDataName -timeStamp $runTime -data $results
            }

        }
        else {

            Write-Verbose "Returning cached data: Cached is [ $( (New-TimeSpan -Start $cachedData.cachedTime -End $(Get-Date)).Minutes)min ] old"
            $results = $cachedData
            $results.PSObject.Properties.Remove('staleCache')
            $results.PSObject.Properties.Remove('cachedTime')

        }

        return $results

    }

    end {}

}
#EndRegion '.\Public\pokemon\Get-PokePokemonAbility.ps1' 154
#Region '.\Public\pokemon\Get-PokePokemonCharacteristic.ps1' -1

function Get-PokePokemonCharacteristic {
<#
    .SYNOPSIS
        Gets Pokemon characteristics from PokeAPI

    .DESCRIPTION
        The Get-PokePokemonCharacteristic cmdlet gets
        Pokemon characteristics from PokeAPI

        Characteristics indicate which stat contains a Pokemon's highest IV.
        A Pokemon's Characteristic is determined by the remainder
        of its highest IV divided by 5 (gene_modulo).

    .PARAMETER id
        Defines id of the resource

    .PARAMETER name
        Defines name of the resource

    .PARAMETER offset
        Defines the page number to return

        By default only 20 resources are returned

    .PARAMETER limit
        Defines the amount of resources to return with each page

        By default only 20 resources are returned

    .PARAMETER allPages
        Returns all resources from an endpoint

        As of 2024-02, there is no cap on how many resources can be
        returned using the limit parameter. There is currently no real
        use for this parameter and it was included simply to account if
        pagination is introduced.

    .PARAMETER updateCache
        Defines if the cache is refreshed regardless of age

        By default the cache is refreshed every 30min

    .EXAMPLE
        Get-PokePokemonCharacteristic

        Gets the first 20 Pokemon characteristics sorted by id

    .EXAMPLE
        Get-PokePokemonCharacteristic -id 1

        Gets the Pokemon characteristic with the defined id

    .EXAMPLE
        Get-PokePokemonCharacteristic -name ditto

        Gets the Pokemon characteristic with the defined name

    .EXAMPLE
        Get-PokePokemonCharacteristic -offset 151 -limit 100

        Gets the first 100 resources starting at resources with
        an id over 151

    .NOTES
        n/a

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/pokemon/Get-PokePokemonCharacteristic.html
#>

    [CmdletBinding(DefaultParameterSetName = 'index_ByAll')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ById')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$id,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ByName')]
        [ValidateNotNullOrEmpty()]
        [string]$name,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$offset,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$limit,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [Switch]$allPages,

        [Parameter(Mandatory = $false)]
        [Switch]$updateCache
    )

    begin {

        $functionName   = $MyInvocation.InvocationName
        $cachedDataName = $functionName + '_Cached' -replace '-','_'
        $parameterName  = $functionName + '_Parameters' -replace '-','_'
        $runTime        = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    }

    process {

        Write-Verbose "Running [ $functionName ] with [ $($PSCmdlet.ParameterSetName) ] parameterSet"
        Set-Variable -Name $parameterName -Value $PSBoundParameters -Scope Global -Force

        switch ( $PSCmdlet.ParameterSetName ) {

            'index_ByAll'  {
                $resource_uri   = "/characteristic"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName
            }
            'index_ById'   {
                $resource_uri   = "/characteristic/$id"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -id $id
            }
            'index_ByName' {
                $resource_uri = ("/characteristic/$name").ToLower()
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -name $name
            }

        }

        if ( $null -eq $cachedData -or $cachedData.staleCache -or $updateCache ) {

            if ($cachedData.staleCache) {
                Write-Verbose "Refreshing cached data: Old Timestamp [ $($cachedData.cachedTime) | New Timestamp [ $([DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")) ]"
            }

            $results = Invoke-PokeRequest -method GET -resource_Uri $resource_Uri -uri_Filter $PSBoundParameters -allPages:$allPages

            if ($results) {
                Set-PokeCachedData -name $cachedDataName -timeStamp $runTime -data $results
            }

        }
        else {

            Write-Verbose "Returning cached data: Cached is [ $( (New-TimeSpan -Start $cachedData.cachedTime -End $(Get-Date)).Minutes)min ] old"
            $results = $cachedData
            $results.PSObject.Properties.Remove('staleCache')
            $results.PSObject.Properties.Remove('cachedTime')

        }

        return $results

    }

    end {}

}
#EndRegion '.\Public\pokemon\Get-PokePokemonCharacteristic.ps1' 156
#Region '.\Public\pokemon\Get-PokePokemonColor.ps1' -1

function Get-PokePokemonColor {
<#
    .SYNOPSIS
        Gets pokemon colors from PokeAPI

    .DESCRIPTION
        The Get-PokePokemonColor cmdlet gets pokemon colors from PokeAPI

        Colors used for sorting Pokemon in a Pokedex. The color listed in the Pokedex
        is usually the color most apparent or covering each Pokemon's body.
        No orange category exists; Pokemon that are primarily orange are listed as red or brown.

    .PARAMETER id
        Defines id of the resource

    .PARAMETER name
        Defines name of the resource

    .PARAMETER offset
        Defines the page number to return

        By default only 20 resources are returned

    .PARAMETER limit
        Defines the amount of resources to return with each page

        By default only 20 resources are returned

    .PARAMETER allPages
        Returns all resources from an endpoint

        As of 2024-02, there is no cap on how many resources can be
        returned using the limit parameter. There is currently no real
        use for this parameter and it was included simply to account if
        pagination is introduced.

    .PARAMETER updateCache
        Defines if the cache is refreshed regardless of age

        By default the cache is refreshed every 30min

    .EXAMPLE
        Get-PokePokemonColor

        Gets the first 20 pokemon colors sorted by id

    .EXAMPLE
        Get-PokePokemonColor -id 1

        Gets the pokemon color with the defined id

    .EXAMPLE
        Get-PokePokemonColor -name ditto

        Gets the pokemon color with the defined name

    .EXAMPLE
        Get-PokePokemonColor -offset 151 -limit 100

        Gets the first 100 resources starting at resources with
        an id over 151

    .NOTES
        n/a

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/pokemon/Get-PokePokemonColor.html
#>

    [CmdletBinding(DefaultParameterSetName = 'index_ByAll')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ById')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$id,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ByName')]
        [ValidateNotNullOrEmpty()]
        [string]$name,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$offset,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$limit,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [Switch]$allPages,

        [Parameter(Mandatory = $false)]
        [Switch]$updateCache
    )

    begin {

        $functionName   = $MyInvocation.InvocationName
        $cachedDataName = $functionName + '_Cached' -replace '-','_'
        $parameterName  = $functionName + '_Parameters' -replace '-','_'
        $runTime        = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    }

    process {

        Write-Verbose "Running [ $functionName ] with [ $($PSCmdlet.ParameterSetName) ] parameterSet"
        Set-Variable -Name $parameterName -Value $PSBoundParameters -Scope Global -Force

        switch ( $PSCmdlet.ParameterSetName ) {

            'index_ByAll'  {
                $resource_uri   = "/pokemon-color"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName
            }
            'index_ById'   {
                $resource_uri   = "/pokemon-color/$id"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -id $id
            }
            'index_ByName' {
                $resource_uri = ("/pokemon-color/$name").ToLower()
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -name $name
            }

        }

        if ( $null -eq $cachedData -or $cachedData.staleCache -or $updateCache ) {

            if ($cachedData.staleCache) {
                Write-Verbose "Refreshing cached data: Old Timestamp [ $($cachedData.cachedTime) | New Timestamp [ $([DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")) ]"
            }

            $results = Invoke-PokeRequest -method GET -resource_Uri $resource_Uri -uri_Filter $PSBoundParameters -allPages:$allPages

            if ($results) {
                Set-PokeCachedData -name $cachedDataName -timeStamp $runTime -data $results
            }

        }
        else {

            Write-Verbose "Returning cached data: Cached is [ $( (New-TimeSpan -Start $cachedData.cachedTime -End $(Get-Date)).Minutes)min ] old"
            $results = $cachedData
            $results.PSObject.Properties.Remove('staleCache')
            $results.PSObject.Properties.Remove('cachedTime')

        }

        return $results

    }

    end {}

}
#EndRegion '.\Public\pokemon\Get-PokePokemonColor.ps1' 155
#Region '.\Public\pokemon\Get-PokePokemonEggGroup.ps1' -1

function Get-PokePokemonEggGroup {
<#
    .SYNOPSIS
        Gets egg groups from PokeAPI

    .DESCRIPTION
        The Get-PokePokemonEggGroup cmdlet gets egg groups from PokeAPI

        Egg Groups are categories which determine which Pokemon are
        able to interbreed. Pokemon may belong to either one or two Egg Groups

    .PARAMETER id
        Defines id of the resource

    .PARAMETER name
        Defines name of the resource

    .PARAMETER offset
        Defines the page number to return

        By default only 20 resources are returned

    .PARAMETER limit
        Defines the amount of resources to return with each page

        By default only 20 resources are returned

    .PARAMETER allPages
        Returns all resources from an endpoint

        As of 2024-02, there is no cap on how many resources can be
        returned using the limit parameter. There is currently no real
        use for this parameter and it was included simply to account if
        pagination is introduced.

    .PARAMETER updateCache
        Defines if the cache is refreshed regardless of age

        By default the cache is refreshed every 30min

    .EXAMPLE
        Get-PokePokemonEggGroup

        Gets the first 20 egg groups sorted by id

    .EXAMPLE
        Get-PokePokemonEggGroup -id 1

        Gets the egg group with the defined id

    .EXAMPLE
        Get-PokePokemonEggGroup -name ditto

        Gets the egg group with the defined name

    .EXAMPLE
        Get-PokePokemonEggGroup -offset 151 -limit 100

        Gets the first 100 resources starting at resources with
        an id over 151

    .NOTES
        n/a

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/pokemon/Get-PokePokemonEggGroup.html
#>

    [CmdletBinding(DefaultParameterSetName = 'index_ByAll')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ById')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$id,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ByName')]
        [ValidateNotNullOrEmpty()]
        [string]$name,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$offset,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$limit,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [Switch]$allPages,

        [Parameter(Mandatory = $false)]
        [Switch]$updateCache
    )

    begin {

        $functionName   = $MyInvocation.InvocationName
        $cachedDataName = $functionName + '_Cached' -replace '-','_'
        $parameterName  = $functionName + '_Parameters' -replace '-','_'
        $runTime        = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    }

    process {

        Write-Verbose "Running [ $functionName ] with [ $($PSCmdlet.ParameterSetName) ] parameterSet"
        Set-Variable -Name $parameterName -Value $PSBoundParameters -Scope Global -Force

        switch ( $PSCmdlet.ParameterSetName ) {

            'index_ByAll'  {
                $resource_uri   = "/egg-group"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName
            }
            'index_ById'   {
                $resource_uri   = "/egg-group/$id"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -id $id
            }
            'index_ByName' {
                $resource_uri = ("/egg-group/$name").ToLower()
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -name $name
            }

        }

        if ( $null -eq $cachedData -or $cachedData.staleCache -or $updateCache ) {

            if ($cachedData.staleCache) {
                Write-Verbose "Refreshing cached data: Old Timestamp [ $($cachedData.cachedTime) | New Timestamp [ $([DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")) ]"
            }

            $results = Invoke-PokeRequest -method GET -resource_Uri $resource_Uri -uri_Filter $PSBoundParameters -allPages:$allPages

            if ($results) {
                Set-PokeCachedData -name $cachedDataName -timeStamp $runTime -data $results
            }

        }
        else {

            Write-Verbose "Returning cached data: Cached is [ $( (New-TimeSpan -Start $cachedData.cachedTime -End $(Get-Date)).Minutes)min ] old"
            $results = $cachedData
            $results.PSObject.Properties.Remove('staleCache')
            $results.PSObject.Properties.Remove('cachedTime')

        }

        return $results

    }

    end {}

}
#EndRegion '.\Public\pokemon\Get-PokePokemonEggGroup.ps1' 154
#Region '.\Public\pokemon\Get-PokePokemonEncounter.ps1' -1

function Get-PokePokemonEncounter {
<#
    .SYNOPSIS
        Gets pokemon location areas from PokeAPI

    .DESCRIPTION
        The Get-PokePokemonEncounter cmdlet gets pokemon location areas from PokeAPI

        Pokemon Location Areas are ares where Pokemon can be found

    .PARAMETER id
        Defines id of the resource

    .PARAMETER name
        Defines name of the resource

    .EXAMPLE
        Get-PokePokemonEncounter -id 1

        Gets the pokemon location area with the defined id

    .EXAMPLE
        Get-PokePokemonEncounter -name ditto

        Gets the pokemon location area with the defined name

    .NOTES
        n/a

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/pokemon/Get-PokePokemonEncounter.html
#>

    [CmdletBinding(DefaultParameterSetName = 'index_ById')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ById')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$id,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ByName')]
        [ValidateNotNullOrEmpty()]
        [string]$name
    )

    begin {

        $functionName   = $MyInvocation.InvocationName
        $cachedDataName = $functionName + '_Cached' -replace '-','_'
        $parameterName  = $functionName + '_Parameters' -replace '-','_'
        $runTime        = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    }

    process {

        Write-Verbose "Running [ $functionName ] with [ $($PSCmdlet.ParameterSetName) ] parameterSet"
        Set-Variable -Name $parameterName -Value $PSBoundParameters -Scope Global -Force

        switch ( $PSCmdlet.ParameterSetName ) {

            'index_ById'   {
                $resource_uri   = "/pokemon/$id/encounters"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -id $id
            }
            'index_ByName' {
                $resource_uri = ("/pokemon/$name/encounters").ToLower()
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -name $name
            }

        }

        if ( $null -eq $cachedData -or $cachedData.staleCache -or $updateCache ) {

            if ($cachedData.staleCache) {
                Write-Verbose "Refreshing cached data: Old Timestamp [ $($cachedData.cachedTime) | New Timestamp [ $([DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")) ]"
            }

            $results = Invoke-PokeRequest -method GET -resource_Uri $resource_Uri -uri_Filter $PSBoundParameters -allPages:$allPages

            if ($results) {
                Set-PokeCachedData -name $cachedDataName -timeStamp $runTime -data $results
            }

        }
        else {

            Write-Verbose "Returning cached data: Cached is [ $( (New-TimeSpan -Start $cachedData.cachedTime -End $(Get-Date)).Minutes)min ] old"
            $results = $cachedData
            $results.PSObject.Properties.Remove('staleCache')
            $results.PSObject.Properties.Remove('cachedTime')

        }

        return $results

    }

    end {}

}
#EndRegion '.\Public\pokemon\Get-PokePokemonEncounter.ps1' 101
#Region '.\Public\pokemon\Get-PokePokemonForm.ps1' -1

function Get-PokePokemonForm {
<#
    .SYNOPSIS
        Gets pokemon forms from PokeAPI

    .DESCRIPTION
        The Get-PokePokemonForm cmdlet gets pokemon forms from PokeAPI

        Some Pokemon may appear in one of multiple, visually different forms.
        These differences are purely cosmetic. For variations within a Pokemon species,
        which do differ in more than just visuals, the
        'Pokemon' entity is used to represent such a variety.

    .PARAMETER id
        Defines id of the resource

    .PARAMETER name
        Defines name of the resource

    .PARAMETER offset
        Defines the page number to return

        By default only 20 resources are returned

    .PARAMETER limit
        Defines the amount of resources to return with each page

        By default only 20 resources are returned

    .PARAMETER allPages
        Returns all resources from an endpoint

        As of 2024-02, there is no cap on how many resources can be
        returned using the limit parameter. There is currently no real
        use for this parameter and it was included simply to account if
        pagination is introduced.

    .PARAMETER updateCache
        Defines if the cache is refreshed regardless of age

        By default the cache is refreshed every 30min

    .EXAMPLE
        Get-PokePokemonForm

        Gets the first 20 pokemon forms sorted by id

    .EXAMPLE
        Get-PokePokemonForm -id 1

        Gets the pokemon form with the defined id

    .EXAMPLE
        Get-PokePokemonForm -name ditto

        Gets the pokemon form with the defined name

    .EXAMPLE
        Get-PokePokemonForm -offset 151 -limit 100

        Gets the first 100 resources starting at resources with
        an id over 151

    .NOTES
        n/a

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/pokemon/Get-PokePokemonForm.html
#>

    [CmdletBinding(DefaultParameterSetName = 'index_ByAll')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ById')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$id,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ByName')]
        [ValidateNotNullOrEmpty()]
        [string]$name,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$offset,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$limit,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [Switch]$allPages,

        [Parameter(Mandatory = $false)]
        [Switch]$updateCache
    )

    begin {

        $functionName   = $MyInvocation.InvocationName
        $cachedDataName = $functionName + '_Cached' -replace '-','_'
        $parameterName  = $functionName + '_Parameters' -replace '-','_'
        $runTime        = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    }

    process {

        Write-Verbose "Running [ $functionName ] with [ $($PSCmdlet.ParameterSetName) ] parameterSet"
        Set-Variable -Name $parameterName -Value $PSBoundParameters -Scope Global -Force

        switch ( $PSCmdlet.ParameterSetName ) {

            'index_ByAll'  {
                $resource_uri   = "/pokemon-form"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName
            }
            'index_ById'   {
                $resource_uri   = "/pokemon-form/$id"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -id $id
            }
            'index_ByName' {
                $resource_uri = ("/pokemon-form/$name").ToLower()
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -name $name
            }

        }

        if ( $null -eq $cachedData -or $cachedData.staleCache -or $updateCache ) {

            if ($cachedData.staleCache) {
                Write-Verbose "Refreshing cached data: Old Timestamp [ $($cachedData.cachedTime) | New Timestamp [ $([DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")) ]"
            }

            $results = Invoke-PokeRequest -method GET -resource_Uri $resource_Uri -uri_Filter $PSBoundParameters -allPages:$allPages

            if ($results) {
                Set-PokeCachedData -name $cachedDataName -timeStamp $runTime -data $results
            }

        }
        else {

            Write-Verbose "Returning cached data: Cached is [ $( (New-TimeSpan -Start $cachedData.cachedTime -End $(Get-Date)).Minutes)min ] old"
            $results = $cachedData
            $results.PSObject.Properties.Remove('staleCache')
            $results.PSObject.Properties.Remove('cachedTime')

        }

        return $results

    }

    end {}

}
#EndRegion '.\Public\pokemon\Get-PokePokemonForm.ps1' 156
#Region '.\Public\pokemon\Get-PokePokemonGender.ps1' -1

function Get-PokePokemonGender {
<#
    .SYNOPSIS
        Gets genders from PokeAPI

    .DESCRIPTION
        The Get-PokePokemonGender cmdlet gets genders from PokeAPI

        Genders were introduced in Generation II for the purposes of
        breeding Pokemon but can also result in visual differences or
        even different evolutionary lines

    .PARAMETER id
        Defines id of the resource

    .PARAMETER name
        Defines name of the resource

    .PARAMETER offset
        Defines the page number to return

        By default only 20 resources are returned

    .PARAMETER limit
        Defines the amount of resources to return with each page

        By default only 20 resources are returned

    .PARAMETER allPages
        Returns all resources from an endpoint

        As of 2024-02, there is no cap on how many resources can be
        returned using the limit parameter. There is currently no real
        use for this parameter and it was included simply to account if
        pagination is introduced.

    .PARAMETER updateCache
        Defines if the cache is refreshed regardless of age

        By default the cache is refreshed every 30min

    .EXAMPLE
        Get-PokePokemonGender

        Gets the first 20 genders sorted by id

    .EXAMPLE
        Get-PokePokemonGender -id 1

        Gets the gender with the defined id

    .EXAMPLE
        Get-PokePokemonGender -name ditto

        Gets the gender with the defined name

    .EXAMPLE
        Get-PokePokemonGender -offset 151 -limit 100

        Gets the first 100 resources starting at resources with
        an id over 151

    .NOTES
        n/a

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/pokemon/Get-PokePokemonGender.html
#>

    [CmdletBinding(DefaultParameterSetName = 'index_ByAll')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ById')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$id,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ByName')]
        [ValidateNotNullOrEmpty()]
        [string]$name,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$offset,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$limit,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [Switch]$allPages,

        [Parameter(Mandatory = $false)]
        [Switch]$updateCache
    )

    begin {

        $functionName   = $MyInvocation.InvocationName
        $cachedDataName = $functionName + '_Cached' -replace '-','_'
        $parameterName  = $functionName + '_Parameters' -replace '-','_'
        $runTime        = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    }

    process {

        Write-Verbose "Running [ $functionName ] with [ $($PSCmdlet.ParameterSetName) ] parameterSet"
        Set-Variable -Name $parameterName -Value $PSBoundParameters -Scope Global -Force

        switch ( $PSCmdlet.ParameterSetName ) {

            'index_ByAll'  {
                $resource_uri   = "/gender"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName
            }
            'index_ById'   {
                $resource_uri   = "/gender/$id"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -id $id
            }
            'index_ByName' {
                $resource_uri = ("/gender/$name").ToLower()
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -name $name
            }

        }

        if ( $null -eq $cachedData -or $cachedData.staleCache -or $updateCache ) {

            if ($cachedData.staleCache) {
                Write-Verbose "Refreshing cached data: Old Timestamp [ $($cachedData.cachedTime) | New Timestamp [ $([DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")) ]"
            }

            $results = Invoke-PokeRequest -method GET -resource_Uri $resource_Uri -uri_Filter $PSBoundParameters -allPages:$allPages

            if ($results) {
                Set-PokeCachedData -name $cachedDataName -timeStamp $runTime -data $results
            }

        }
        else {

            Write-Verbose "Returning cached data: Cached is [ $( (New-TimeSpan -Start $cachedData.cachedTime -End $(Get-Date)).Minutes)min ] old"
            $results = $cachedData
            $results.PSObject.Properties.Remove('staleCache')
            $results.PSObject.Properties.Remove('cachedTime')

        }

        return $results

    }

    end {}

}
#EndRegion '.\Public\pokemon\Get-PokePokemonGender.ps1' 155
#Region '.\Public\pokemon\Get-PokePokemonGrowthRate.ps1' -1

function Get-PokePokemonGrowthRate {
<#
    .SYNOPSIS
        Gets growth rates from PokeAPI

    .DESCRIPTION
        The Get-PokePokemonGrowthRate cmdlet gets growth rates from PokeAPI

        Growth rates are the speed with which Pokemon gain levels through experience

    .PARAMETER id
        Defines id of the resource

    .PARAMETER name
        Defines name of the resource

    .PARAMETER offset
        Defines the page number to return

        By default only 20 resources are returned

    .PARAMETER limit
        Defines the amount of resources to return with each page

        By default only 20 resources are returned

    .PARAMETER allPages
        Returns all resources from an endpoint

        As of 2024-02, there is no cap on how many resources can be
        returned using the limit parameter. There is currently no real
        use for this parameter and it was included simply to account if
        pagination is introduced.

    .PARAMETER updateCache
        Defines if the cache is refreshed regardless of age

        By default the cache is refreshed every 30min

    .EXAMPLE
        Get-PokePokemonGrowthRate

        Gets the first 20 growth rates sorted by id

    .EXAMPLE
        Get-PokePokemonGrowthRate -id 1

        Gets the growth rate with the defined id

    .EXAMPLE
        Get-PokePokemonGrowthRate -name ditto

        Gets the growth rate with the defined name

    .EXAMPLE
        Get-PokePokemonGrowthRate -offset 151 -limit 100

        Gets the first 100 resources starting at resources with
        an id over 151

    .NOTES
        n/a

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/pokemon/Get-PokePokemonGrowthRate.html
#>

    [CmdletBinding(DefaultParameterSetName = 'index_ByAll')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ById')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$id,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ByName')]
        [ValidateNotNullOrEmpty()]
        [string]$name,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$offset,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$limit,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [Switch]$allPages,

        [Parameter(Mandatory = $false)]
        [Switch]$updateCache
    )

    begin {

        $functionName   = $MyInvocation.InvocationName
        $cachedDataName = $functionName + '_Cached' -replace '-','_'
        $parameterName  = $functionName + '_Parameters' -replace '-','_'
        $runTime        = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    }

    process {

        Write-Verbose "Running [ $functionName ] with [ $($PSCmdlet.ParameterSetName) ] parameterSet"
        Set-Variable -Name $parameterName -Value $PSBoundParameters -Scope Global -Force

        switch ( $PSCmdlet.ParameterSetName ) {

            'index_ByAll'  {
                $resource_uri   = "/growth-rate"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName
            }
            'index_ById'   {
                $resource_uri   = "/growth-rate/$id"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -id $id
            }
            'index_ByName' {
                $resource_uri = ("/growth-rate/$name").ToLower()
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -name $name
            }

        }

        if ( $null -eq $cachedData -or $cachedData.staleCache -or $updateCache ) {

            if ($cachedData.staleCache) {
                Write-Verbose "Refreshing cached data: Old Timestamp [ $($cachedData.cachedTime) | New Timestamp [ $([DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")) ]"
            }

            $results = Invoke-PokeRequest -method GET -resource_Uri $resource_Uri -uri_Filter $PSBoundParameters -allPages:$allPages

            if ($results) {
                Set-PokeCachedData -name $cachedDataName -timeStamp $runTime -data $results
            }

        }
        else {

            Write-Verbose "Returning cached data: Cached is [ $( (New-TimeSpan -Start $cachedData.cachedTime -End $(Get-Date)).Minutes)min ] old"
            $results = $cachedData
            $results.PSObject.Properties.Remove('staleCache')
            $results.PSObject.Properties.Remove('cachedTime')

        }

        return $results

    }

    end {}

}
#EndRegion '.\Public\pokemon\Get-PokePokemonGrowthRate.ps1' 153
#Region '.\Public\pokemon\Get-PokePokemonHabitat.ps1' -1

function Get-PokePokemonHabitat {
<#
    .SYNOPSIS
        Gets pokemon habitats from PokeAPI

    .DESCRIPTION
        The Get-PokePokemonHabitat cmdlet gets pokemon habitats from PokeAPI

        Habitats are generally different terrain Pokemon can be found
        in but can also be areas designated for rare or legendary Pokemon.

    .PARAMETER id
        Defines id of the resource

    .PARAMETER name
        Defines name of the resource

    .PARAMETER offset
        Defines the page number to return

        By default only 20 resources are returned

    .PARAMETER limit
        Defines the amount of resources to return with each page

        By default only 20 resources are returned

    .PARAMETER allPages
        Returns all resources from an endpoint

        As of 2024-02, there is no cap on how many resources can be
        returned using the limit parameter. There is currently no real
        use for this parameter and it was included simply to account if
        pagination is introduced.

    .PARAMETER updateCache
        Defines if the cache is refreshed regardless of age

        By default the cache is refreshed every 30min

    .EXAMPLE
        Get-PokePokemonHabitat

        Gets the first 20 pokemon habitats sorted by id

    .EXAMPLE
        Get-PokePokemonHabitat -id 1

        Gets the pokemon habitat with the defined id

    .EXAMPLE
        Get-PokePokemonHabitat -name ditto

        Gets the pokemon habitat with the defined name

    .EXAMPLE
        Get-PokePokemonHabitat -offset 151 -limit 100

        Gets the first 100 resources starting at resources with
        an id over 151

    .NOTES
        n/a

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/pokemon/Get-PokePokemonHabitat.html
#>

    [CmdletBinding(DefaultParameterSetName = 'index_ByAll')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ById')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$id,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ByName')]
        [ValidateNotNullOrEmpty()]
        [string]$name,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$offset,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$limit,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [Switch]$allPages,

        [Parameter(Mandatory = $false)]
        [Switch]$updateCache
    )

    begin {

        $functionName   = $MyInvocation.InvocationName
        $cachedDataName = $functionName + '_Cached' -replace '-','_'
        $parameterName  = $functionName + '_Parameters' -replace '-','_'
        $runTime        = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    }

    process {

        Write-Verbose "Running [ $functionName ] with [ $($PSCmdlet.ParameterSetName) ] parameterSet"
        Set-Variable -Name $parameterName -Value $PSBoundParameters -Scope Global -Force

        switch ( $PSCmdlet.ParameterSetName ) {

            'index_ByAll'  {
                $resource_uri   = "/pokemon-habitat"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName
            }
            'index_ById'   {
                $resource_uri   = "/pokemon-habitat/$id"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -id $id
            }
            'index_ByName' {
                $resource_uri = ("/pokemon-habitat/$name").ToLower()
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -name $name
            }

        }

        if ( $null -eq $cachedData -or $cachedData.staleCache -or $updateCache ) {

            if ($cachedData.staleCache) {
                Write-Verbose "Refreshing cached data: Old Timestamp [ $($cachedData.cachedTime) | New Timestamp [ $([DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")) ]"
            }

            $results = Invoke-PokeRequest -method GET -resource_Uri $resource_Uri -uri_Filter $PSBoundParameters -allPages:$allPages

            if ($results) {
                Set-PokeCachedData -name $cachedDataName -timeStamp $runTime -data $results
            }

        }
        else {

            Write-Verbose "Returning cached data: Cached is [ $( (New-TimeSpan -Start $cachedData.cachedTime -End $(Get-Date)).Minutes)min ] old"
            $results = $cachedData
            $results.PSObject.Properties.Remove('staleCache')
            $results.PSObject.Properties.Remove('cachedTime')

        }

        return $results

    }

    end {}

}
#EndRegion '.\Public\pokemon\Get-PokePokemonHabitat.ps1' 154
#Region '.\Public\pokemon\Get-PokePokemonNature.ps1' -1

function Get-PokePokemonNature {
<#
    .SYNOPSIS
        Gets natures from PokeAPI

    .DESCRIPTION
        The Get-PokePokemonNature cmdlet gets natures from PokeAPI

        Natures influence how a Pokemon's stats grow

    .PARAMETER id
        Defines id of the resource

    .PARAMETER name
        Defines name of the resource

    .PARAMETER offset
        Defines the page number to return

        By default only 20 resources are returned

    .PARAMETER limit
        Defines the amount of resources to return with each page

        By default only 20 resources are returned

    .PARAMETER allPages
        Returns all resources from an endpoint

        As of 2024-02, there is no cap on how many resources can be
        returned using the limit parameter. There is currently no real
        use for this parameter and it was included simply to account if
        pagination is introduced.

    .PARAMETER updateCache
        Defines if the cache is refreshed regardless of age

        By default the cache is refreshed every 30min

    .EXAMPLE
        Get-PokePokemonNature

        Gets the first 20 natures sorted by id

    .EXAMPLE
        Get-PokePokemonNature -id 1

        Gets the nature with the defined id

    .EXAMPLE
        Get-PokePokemonNature -name ditto

        Gets the nature with the defined name

    .EXAMPLE
        Get-PokePokemonNature -offset 151 -limit 100

        Gets the first 100 resources starting at resources with
        an id over 151

    .NOTES
        n/a

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/pokemon/Get-PokePokemonNature.html
#>

    [CmdletBinding(DefaultParameterSetName = 'index_ByAll')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ById')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$id,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ByName')]
        [ValidateNotNullOrEmpty()]
        [string]$name,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$offset,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$limit,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [Switch]$allPages,

        [Parameter(Mandatory = $false)]
        [Switch]$updateCache
    )

    begin {

        $functionName   = $MyInvocation.InvocationName
        $cachedDataName = $functionName + '_Cached' -replace '-','_'
        $parameterName  = $functionName + '_Parameters' -replace '-','_'
        $runTime        = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    }

    process {

        Write-Verbose "Running [ $functionName ] with [ $($PSCmdlet.ParameterSetName) ] parameterSet"
        Set-Variable -Name $parameterName -Value $PSBoundParameters -Scope Global -Force

        switch ( $PSCmdlet.ParameterSetName ) {

            'index_ByAll'  {
                $resource_uri   = "/nature"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName
            }
            'index_ById'   {
                $resource_uri   = "/nature/$id"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -id $id
            }
            'index_ByName' {
                $resource_uri = ("/nature/$name").ToLower()
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -name $name
            }

        }

        if ( $null -eq $cachedData -or $cachedData.staleCache -or $updateCache ) {

            if ($cachedData.staleCache) {
                Write-Verbose "Refreshing cached data: Old Timestamp [ $($cachedData.cachedTime) | New Timestamp [ $([DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")) ]"
            }

            $results = Invoke-PokeRequest -method GET -resource_Uri $resource_Uri -uri_Filter $PSBoundParameters -allPages:$allPages

            if ($results) {
                Set-PokeCachedData -name $cachedDataName -timeStamp $runTime -data $results
            }

        }
        else {

            Write-Verbose "Returning cached data: Cached is [ $( (New-TimeSpan -Start $cachedData.cachedTime -End $(Get-Date)).Minutes)min ] old"
            $results = $cachedData
            $results.PSObject.Properties.Remove('staleCache')
            $results.PSObject.Properties.Remove('cachedTime')

        }

        return $results

    }

    end {}

}
#EndRegion '.\Public\pokemon\Get-PokePokemonNature.ps1' 153
#Region '.\Public\pokemon\Get-PokePokemonPokeathlonStat.ps1' -1

function Get-PokePokemonPokeathlonStat {
<#
    .SYNOPSIS
        Gets pokeathlon stats from PokeAPI

    .DESCRIPTION
        The Get-PokePokemonPokeathlonStat cmdlet gets pokeathlon stats from PokeAPI

        Pokeathlon Stats are different attributes of a Pokemon's performance in Pokeathlons.
        In Pokeathlons, competitions happen on different courses; one for each
        of the different Pokeathlon stats

    .PARAMETER id
        Defines id of the resource

    .PARAMETER name
        Defines name of the resource

    .PARAMETER offset
        Defines the page number to return

        By default only 20 resources are returned

    .PARAMETER limit
        Defines the amount of resources to return with each page

        By default only 20 resources are returned

    .PARAMETER allPages
        Returns all resources from an endpoint

        As of 2024-02, there is no cap on how many resources can be
        returned using the limit parameter. There is currently no real
        use for this parameter and it was included simply to account if
        pagination is introduced.

    .PARAMETER updateCache
        Defines if the cache is refreshed regardless of age

        By default the cache is refreshed every 30min

    .EXAMPLE
        Get-PokePokemonPokeathlonStat

        Gets the first 20 pokeathlon stats sorted by id

    .EXAMPLE
        Get-PokePokemonPokeathlonStat -id 1

        Gets the pokeathlon stat with the defined id

    .EXAMPLE
        Get-PokePokemonPokeathlonStat -name ditto

        Gets the pokeathlon stat with the defined name

    .EXAMPLE
        Get-PokePokemonPokeathlonStat -offset 151 -limit 100

        Gets the first 100 resources starting at resources with
        an id over 151

    .NOTES
        n/a

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/pokemon/Get-PokePokemonPokeathlonStat.html
#>

    [CmdletBinding(DefaultParameterSetName = 'index_ByAll')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ById')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$id,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ByName')]
        [ValidateNotNullOrEmpty()]
        [string]$name,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$offset,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$limit,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [Switch]$allPages,

        [Parameter(Mandatory = $false)]
        [Switch]$updateCache
    )

    begin {

        $functionName   = $MyInvocation.InvocationName
        $cachedDataName = $functionName + '_Cached' -replace '-','_'
        $parameterName  = $functionName + '_Parameters' -replace '-','_'
        $runTime        = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    }

    process {

        Write-Verbose "Running [ $functionName ] with [ $($PSCmdlet.ParameterSetName) ] parameterSet"
        Set-Variable -Name $parameterName -Value $PSBoundParameters -Scope Global -Force

        switch ( $PSCmdlet.ParameterSetName ) {

            'index_ByAll'  {
                $resource_uri   = "/pokeathlon-stat"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName
            }
            'index_ById'   {
                $resource_uri   = "/pokeathlon-stat/$id"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -id $id
            }
            'index_ByName' {
                $resource_uri = ("/pokeathlon-stat/$name").ToLower()
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -name $name
            }

        }

        if ( $null -eq $cachedData -or $cachedData.staleCache -or $updateCache ) {

            if ($cachedData.staleCache) {
                Write-Verbose "Refreshing cached data: Old Timestamp [ $($cachedData.cachedTime) | New Timestamp [ $([DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")) ]"
            }

            $results = Invoke-PokeRequest -method GET -resource_Uri $resource_Uri -uri_Filter $PSBoundParameters -allPages:$allPages

            if ($results) {
                Set-PokeCachedData -name $cachedDataName -timeStamp $runTime -data $results
            }

        }
        else {

            Write-Verbose "Returning cached data: Cached is [ $( (New-TimeSpan -Start $cachedData.cachedTime -End $(Get-Date)).Minutes)min ] old"
            $results = $cachedData
            $results.PSObject.Properties.Remove('staleCache')
            $results.PSObject.Properties.Remove('cachedTime')

        }

        return $results

    }

    end {}

}
#EndRegion '.\Public\pokemon\Get-PokePokemonPokeathlonStat.ps1' 155
#Region '.\Public\pokemon\Get-PokePokemonShape.ps1' -1

function Get-PokePokemonShape {
<#
    .SYNOPSIS
        Gets pokemon shapes from PokeAPI

    .DESCRIPTION
        The Get-PokePokemonShape cmdlet gets pokemon shapes from PokeAPI

        Shapes used for sorting Pokemon in a Pokedex

    .PARAMETER id
        Defines id of the resource

    .PARAMETER name
        Defines name of the resource

    .PARAMETER offset
        Defines the page number to return

        By default only 20 resources are returned

    .PARAMETER limit
        Defines the amount of resources to return with each page

        By default only 20 resources are returned

    .PARAMETER allPages
        Returns all resources from an endpoint

        As of 2024-02, there is no cap on how many resources can be
        returned using the limit parameter. There is currently no real
        use for this parameter and it was included simply to account if
        pagination is introduced.

    .PARAMETER updateCache
        Defines if the cache is refreshed regardless of age

        By default the cache is refreshed every 30min

    .EXAMPLE
        Get-PokePokemonShape

        Gets the first 20 pokemon shapes sorted by id

    .EXAMPLE
        Get-PokePokemonShape -id 1

        Gets the pokemon shape with the defined id

    .EXAMPLE
        Get-PokePokemonShape -name ditto

        Gets the pokemon shape with the defined name

    .EXAMPLE
        Get-PokePokemonShape -offset 151 -limit 100

        Gets the first 100 resources starting at resources with
        an id over 151

    .NOTES
        n/a

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/pokemon/Get-PokePokemonShape.html
#>

    [CmdletBinding(DefaultParameterSetName = 'index_ByAll')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ById')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$id,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ByName')]
        [ValidateNotNullOrEmpty()]
        [string]$name,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$offset,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$limit,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [Switch]$allPages,

        [Parameter(Mandatory = $false)]
        [Switch]$updateCache
    )

    begin {

        $functionName   = $MyInvocation.InvocationName
        $cachedDataName = $functionName + '_Cached' -replace '-','_'
        $parameterName  = $functionName + '_Parameters' -replace '-','_'
        $runTime        = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    }

    process {

        Write-Verbose "Running [ $functionName ] with [ $($PSCmdlet.ParameterSetName) ] parameterSet"
        Set-Variable -Name $parameterName -Value $PSBoundParameters -Scope Global -Force

        switch ( $PSCmdlet.ParameterSetName ) {

            'index_ByAll'  {
                $resource_uri   = "/pokemon-shape"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName
            }
            'index_ById'   {
                $resource_uri   = "/pokemon-shape/$id"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -id $id
            }
            'index_ByName' {
                $resource_uri = ("/pokemon-shape/$name").ToLower()
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -name $name
            }

        }

        if ( $null -eq $cachedData -or $cachedData.staleCache -or $updateCache ) {

            if ($cachedData.staleCache) {
                Write-Verbose "Refreshing cached data: Old Timestamp [ $($cachedData.cachedTime) | New Timestamp [ $([DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")) ]"
            }

            $results = Invoke-PokeRequest -method GET -resource_Uri $resource_Uri -uri_Filter $PSBoundParameters -allPages:$allPages

            if ($results) {
                Set-PokeCachedData -name $cachedDataName -timeStamp $runTime -data $results
            }

        }
        else {

            Write-Verbose "Returning cached data: Cached is [ $( (New-TimeSpan -Start $cachedData.cachedTime -End $(Get-Date)).Minutes)min ] old"
            $results = $cachedData
            $results.PSObject.Properties.Remove('staleCache')
            $results.PSObject.Properties.Remove('cachedTime')

        }

        return $results

    }

    end {}

}
#EndRegion '.\Public\pokemon\Get-PokePokemonShape.ps1' 153
#Region '.\Public\pokemon\Get-PokePokemonSpecies.ps1' -1

function Get-PokePokemonSpecies {
<#
    .SYNOPSIS
        Gets pokemon species from PokeAPI

    .DESCRIPTION
        The Get-PokePokemonSpecies cmdlet gets pokemon species from PokeAPI

        A Pokemon Species forms the basis for at least one Pokemon. Attributes of a
        Pokemon species are shared across all varieties of Pokemon within the species.

        A good example is Wormadam; Wormadam is the species which can be found in three
        different varieties, Wormadam-Trash, Wormadam-Sandy and Wormadam-Plant.

    .PARAMETER id
        Defines id of the resource

    .PARAMETER name
        Defines name of the resource

    .PARAMETER offset
        Defines the page number to return

        By default only 20 resources are returned

    .PARAMETER limit
        Defines the amount of resources to return with each page

        By default only 20 resources are returned

    .PARAMETER allPages
        Returns all resources from an endpoint

        As of 2024-02, there is no cap on how many resources can be
        returned using the limit parameter. There is currently no real
        use for this parameter and it was included simply to account if
        pagination is introduced.

    .PARAMETER updateCache
        Defines if the cache is refreshed regardless of age

        By default the cache is refreshed every 30min

    .EXAMPLE
        Get-PokePokemonSpecies

        Gets the first 20 pokemon species sorted by id

    .EXAMPLE
        Get-PokePokemonSpecies -id 1

        Gets the pokemon species with the defined id

    .EXAMPLE
        Get-PokePokemonSpecies -name ditto

        Gets the pokemon species with the defined name

    .EXAMPLE
        Get-PokePokemonSpecies -offset 151 -limit 100

        Gets the first 100 resources starting at resources with
        an id over 151

    .NOTES
        n/a

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/pokemon/Get-PokePokemonSpecies.html
#>

    [CmdletBinding(DefaultParameterSetName = 'index_ByAll')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ById')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$id,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ByName')]
        [ValidateNotNullOrEmpty()]
        [string]$name,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$offset,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$limit,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [Switch]$allPages,

        [Parameter(Mandatory = $false)]
        [Switch]$updateCache
    )

    begin {

        $functionName   = $MyInvocation.InvocationName
        $cachedDataName = $functionName + '_Cached' -replace '-','_'
        $parameterName  = $functionName + '_Parameters' -replace '-','_'
        $runTime        = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    }

    process {

        Write-Verbose "Running [ $functionName ] with [ $($PSCmdlet.ParameterSetName) ] parameterSet"
        Set-Variable -Name $parameterName -Value $PSBoundParameters -Scope Global -Force

        switch ( $PSCmdlet.ParameterSetName ) {

            'index_ByAll'  {
                $resource_uri   = "/pokemon-species"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName
            }
            'index_ById'   {
                $resource_uri   = "/pokemon-species/$id"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -id $id
            }
            'index_ByName' {
                $resource_uri = ("/pokemon-species/$name").ToLower()
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -name $name
            }

        }

        if ( $null -eq $cachedData -or $cachedData.staleCache -or $updateCache ) {

            if ($cachedData.staleCache) {
                Write-Verbose "Refreshing cached data: Old Timestamp [ $($cachedData.cachedTime) | New Timestamp [ $([DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")) ]"
            }

            $results = Invoke-PokeRequest -method GET -resource_Uri $resource_Uri -uri_Filter $PSBoundParameters -allPages:$allPages

            if ($results) {
                Set-PokeCachedData -name $cachedDataName -timeStamp $runTime -data $results
            }

        }
        else {

            Write-Verbose "Returning cached data: Cached is [ $( (New-TimeSpan -Start $cachedData.cachedTime -End $(Get-Date)).Minutes)min ] old"
            $results = $cachedData
            $results.PSObject.Properties.Remove('staleCache')
            $results.PSObject.Properties.Remove('cachedTime')

        }

        return $results

    }

    end {}

}
#EndRegion '.\Public\pokemon\Get-PokePokemonSpecies.ps1' 157
#Region '.\Public\pokemon\Get-PokePokemonStat.ps1' -1

function Get-PokePokemonStat {
<#
    .SYNOPSIS
        Gets pokemon stats from PokeAPI

    .DESCRIPTION
        The Get-PokePokemonStat cmdlet gets pokemon stats from PokeAPI

        Stats determine certain aspects of battles. Each Pokemon has a
        value for each stat which grows as they gain levels and can be
        altered momentarily by effects in battles.

    .PARAMETER id
        Defines id of the resource

    .PARAMETER name
        Defines name of the resource

    .PARAMETER offset
        Defines the page number to return

        By default only 20 resources are returned

    .PARAMETER limit
        Defines the amount of resources to return with each page

        By default only 20 resources are returned

    .PARAMETER allPages
        Returns all resources from an endpoint

        As of 2024-02, there is no cap on how many resources can be
        returned using the limit parameter. There is currently no real
        use for this parameter and it was included simply to account if
        pagination is introduced.

    .PARAMETER updateCache
        Defines if the cache is refreshed regardless of age

        By default the cache is refreshed every 30min

    .EXAMPLE
        Get-PokePokemonStat

        Gets the first 20 pokemon stats sorted by id

    .EXAMPLE
        Get-PokePokemonStat -id 1

        Gets the pokemon stat with the defined id

    .EXAMPLE
        Get-PokePokemonStat -name ditto

        Gets the pokemon stat with the defined name

    .EXAMPLE
        Get-PokePokemonStat -offset 151 -limit 100

        Gets the first 100 resources starting at resources with
        an id over 151

    .NOTES
        n/a

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/pokemon/Get-PokePokemonStat.html
#>

    [CmdletBinding(DefaultParameterSetName = 'index_ByAll')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ById')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$id,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ByName')]
        [ValidateNotNullOrEmpty()]
        [string]$name,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$offset,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$limit,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [Switch]$allPages,

        [Parameter(Mandatory = $false)]
        [Switch]$updateCache
    )

    begin {

        $functionName   = $MyInvocation.InvocationName
        $cachedDataName = $functionName + '_Cached' -replace '-','_'
        $parameterName  = $functionName + '_Parameters' -replace '-','_'
        $runTime        = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    }

    process {

        Write-Verbose "Running [ $functionName ] with [ $($PSCmdlet.ParameterSetName) ] parameterSet"
        Set-Variable -Name $parameterName -Value $PSBoundParameters -Scope Global -Force

        switch ( $PSCmdlet.ParameterSetName ) {

            'index_ByAll'  {
                $resource_uri   = "/stat"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName
            }
            'index_ById'   {
                $resource_uri   = "/stat/$id"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -id $id
            }
            'index_ByName' {
                $resource_uri = ("/stat/$name").ToLower()
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -name $name
            }

        }

        if ( $null -eq $cachedData -or $cachedData.staleCache -or $updateCache ) {

            if ($cachedData.staleCache) {
                Write-Verbose "Refreshing cached data: Old Timestamp [ $($cachedData.cachedTime) | New Timestamp [ $([DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")) ]"
            }

            $results = Invoke-PokeRequest -method GET -resource_Uri $resource_Uri -uri_Filter $PSBoundParameters -allPages:$allPages

            if ($results) {
                Set-PokeCachedData -name $cachedDataName -timeStamp $runTime -data $results
            }

        }
        else {

            Write-Verbose "Returning cached data: Cached is [ $( (New-TimeSpan -Start $cachedData.cachedTime -End $(Get-Date)).Minutes)min ] old"
            $results = $cachedData
            $results.PSObject.Properties.Remove('staleCache')
            $results.PSObject.Properties.Remove('cachedTime')

        }

        return $results

    }

    end {}

}
#EndRegion '.\Public\pokemon\Get-PokePokemonStat.ps1' 155
#Region '.\Public\pokemon\Get-PokePokemonType.ps1' -1

function Get-PokePokemonType {
<#
    .SYNOPSIS
        Gets pokemon move type properties from PokeAPI

    .DESCRIPTION
        The Get-PokePokemonType cmdlet gets pokemon move type properties from PokeAPI

        Types are properties for Pokemon and their moves. Each type has
        three properties: which types of Pokemon it is super effective against,
        which types of Pokemon it is not very effective against, and which
        types of Pokemon it is completely ineffective against.

    .PARAMETER id
        Defines id of the resource

    .PARAMETER name
        Defines name of the resource

    .PARAMETER offset
        Defines the page number to return

        By default only 20 resources are returned

    .PARAMETER limit
        Defines the amount of resources to return with each page

        By default only 20 resources are returned

    .PARAMETER allPages
        Returns all resources from an endpoint

        As of 2024-02, there is no cap on how many resources can be
        returned using the limit parameter. There is currently no real
        use for this parameter and it was included simply to account if
        pagination is introduced.

    .PARAMETER updateCache
        Defines if the cache is refreshed regardless of age

        By default the cache is refreshed every 30min

    .EXAMPLE
        Get-PokePokemonType

        Gets the first 20 pokemon move type properties sorted by id

    .EXAMPLE
        Get-PokePokemonType -id 1

        Gets the pokemon move type property with the defined id

    .EXAMPLE
        Get-PokePokemonType -name ditto

        Gets the pokemon move type property with the defined name

    .EXAMPLE
        Get-PokePokemonType -offset 151 -limit 100

        Gets the first 100 resources starting at resources with
        an id over 151

    .NOTES
        n/a

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/pokemon/Get-PokePokemonType.html
#>

    [CmdletBinding(DefaultParameterSetName = 'index_ByAll')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ById')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$id,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ByName')]
        [ValidateNotNullOrEmpty()]
        [string]$name,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$offset,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$limit,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [Switch]$allPages,

        [Parameter(Mandatory = $false)]
        [Switch]$updateCache
    )

    begin {

        $functionName   = $MyInvocation.InvocationName
        $cachedDataName = $functionName + '_Cached' -replace '-','_'
        $parameterName  = $functionName + '_Parameters' -replace '-','_'
        $runTime        = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    }

    process {

        Write-Verbose "Running [ $functionName ] with [ $($PSCmdlet.ParameterSetName) ] parameterSet"
        Set-Variable -Name $parameterName -Value $PSBoundParameters -Scope Global -Force

        switch ( $PSCmdlet.ParameterSetName ) {

            'index_ByAll'  {
                $resource_uri   = "/type"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName
            }
            'index_ById'   {
                $resource_uri   = "/type/$id"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -id $id
            }
            'index_ByName' {
                $resource_uri = ("/type/$name").ToLower()
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -name $name
            }

        }

        if ( $null -eq $cachedData -or $cachedData.staleCache -or $updateCache ) {

            if ($cachedData.staleCache) {
                Write-Verbose "Refreshing cached data: Old Timestamp [ $($cachedData.cachedTime) | New Timestamp [ $([DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")) ]"
            }

            $results = Invoke-PokeRequest -method GET -resource_Uri $resource_Uri -uri_Filter $PSBoundParameters -allPages:$allPages

            if ($results) {
                Set-PokeCachedData -name $cachedDataName -timeStamp $runTime -data $results
            }

        }
        else {

            Write-Verbose "Returning cached data: Cached is [ $( (New-TimeSpan -Start $cachedData.cachedTime -End $(Get-Date)).Minutes)min ] old"
            $results = $cachedData
            $results.PSObject.Properties.Remove('staleCache')
            $results.PSObject.Properties.Remove('cachedTime')

        }

        return $results

    }

    end {}

}
#EndRegion '.\Public\pokemon\Get-PokePokemonType.ps1' 156
#Region '.\Public\utility\Get-PokeEndpoint.ps1' -1

function Get-PokeEndpoint {
<#
    .SYNOPSIS
        Gets endpoints from PokeAPI

    .DESCRIPTION
        The Get-PokeEndpoint cmdlet gets endpoints from PokeAPI

    .PARAMETER updateCache
        Defines if the cache is refreshed regardless of age

        By default the cache is refreshed every 30min

    .EXAMPLE
        Get-PokeEndpoint

        Gets the endpoints from PokeAPI

    .NOTES
        n/a

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/utility/Get-PokeEndpoint.html
#>

    [CmdletBinding(DefaultParameterSetName = 'index_ByAll')]
    Param (
        [Parameter(Mandatory = $false)]
        [Switch]$updateCache
    )

    begin {

        $functionName   = $MyInvocation.InvocationName
        $cachedDataName = $functionName + '_Cached' -replace '-','_'
        $parameterName  = $functionName + '_Parameters' -replace '-','_'
        $runTime        = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

        $endpoints = [System.Collections.Generic.List[object]]::new()

    }

    process {

        Write-Verbose "Running [ $functionName ] with [ $($PSCmdlet.ParameterSetName) ] parameterSet"
        Set-Variable -Name $parameterName -Value $PSBoundParameters -Scope Global -Force

        switch ( $PSCmdlet.ParameterSetName ) {

            'index_ByAll'  {
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName
            }

        }

        if ( $null -eq $cachedData -or ($cachedData.staleCache | Select-Object -First 1) -or $updateCache ) {

            if ($cachedData.staleCache) {
                Write-Verbose "Refreshing cached data: Old Timestamp [ $( ($cachedData.cachedTime| Select-Object -First 1)) | New Timestamp [ $([DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")) ]"
            }

            $invokeRequest = Invoke-RestMethod -Method GET -Uri $Poke_Base_URI

            $endpointCount = $invokeRequest.PSObject.Properties.Name.Count

            foreach ($property in  $invokeRequest.PSObject.Properties) {

                $data = [PSCustomObject]@{
                    name    = $property.name
                    url     = $property.value
                }

                $endpoints.add($data)

            }

            $results = [PSCustomObject]@{
                count       = $endpointCount
                next        = $null
                previous    = $null
                results     = $endpoints
            }

            if ($results) {
                Set-PokeCachedData -name $cachedDataName -timeStamp $runTime -data $results
            }

        }
        else {

            Write-Verbose "Returning cached data: Cached is [ $( (New-TimeSpan -Start $cachedData.cachedTime -End $(Get-Date)).Minutes)min ] old"
            $results = $cachedData
            $results.PSObject.Properties.Remove('staleCache')
            $results.PSObject.Properties.Remove('cachedTime')

        }

        return $results

    }

    end {}

}
#EndRegion '.\Public\utility\Get-PokeEndpoint.ps1' 105
#Region '.\Public\utility\Get-PokeLanguage.ps1' -1

function Get-PokeLanguage {
<#
    .SYNOPSIS
        Gets languages from PokeAPI

    .DESCRIPTION
        The Get-PokeLanguage cmdlet gets languages from PokeAPI

        Languages for translations of API resource information

    .PARAMETER id
        Defines id of the resource

    .PARAMETER name
        Defines name of the resource

    .PARAMETER offset
        Defines the page number to return

        By default only 20 resources are returned

    .PARAMETER limit
        Defines the amount of resources to return with each page

        By default only 20 resources are returned

    .PARAMETER allPages
        Returns all resources from an endpoint

        As of 2024-02, there is no cap on how many resources can be
        returned using the limit parameter. There is currently no real
        use for this parameter and it was included simply to account if
        pagination is introduced.

    .PARAMETER updateCache
        Defines if the cache is refreshed regardless of age

        By default the cache is refreshed every 30min

    .EXAMPLE
        Get-PokeLanguage

        Gets the first 20 languages sorted by id

    .EXAMPLE
        Get-PokeLanguage -id 1

        Gets the language with the defined id

    .EXAMPLE
        Get-PokeLanguage -name ditto

        Gets the language with the defined name

    .EXAMPLE
        Get-PokeLanguage -offset 151 -limit 100

        Gets the first 100 resources starting at resources with
        an id over 151

    .NOTES
        n/a

    .LINK
        https://celerium.github.io/PokeAPI-PowerShellWrapper/site/utility/Get-PokeLanguage.html
#>

    [CmdletBinding(DefaultParameterSetName = 'index_ByAll')]
    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ById')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$id,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'index_ByName')]
        [ValidateNotNullOrEmpty()]
        [string]$name,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$offset,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [ValidateRange(1, [Int]::MaxValue)]
        [Int]$limit,

        [Parameter(Mandatory = $false, ParameterSetName = 'index_ByAll')]
        [Switch]$allPages,

        [Parameter(Mandatory = $false)]
        [Switch]$updateCache
    )

    begin {

        $functionName   = $MyInvocation.InvocationName
        $cachedDataName = $functionName + '_Cached' -replace '-','_'
        $parameterName  = $functionName + '_Parameters' -replace '-','_'
        $runTime        = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

    }

    process {

        Write-Verbose "Running [ $functionName ] with [ $($PSCmdlet.ParameterSetName) ] parameterSet"
        Set-Variable -Name $parameterName -Value $PSBoundParameters -Scope Global -Force

        switch ( $PSCmdlet.ParameterSetName ) {

            'index_ByAll'  {
                $resource_uri   = "/language"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName
            }
            'index_ById'   {
                $resource_uri   = "/language/$id"
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -id $id
            }
            'index_ByName' {
                $resource_uri = ("/language/$name").ToLower()
                $cachedData     = Get-PokeCachedData -cachedDataName $cachedDataName -name $name
            }

        }

        if ( $null -eq $cachedData -or $cachedData.staleCache -or $updateCache ) {

            if ($cachedData.staleCache) {
                Write-Verbose "Refreshing cached data: Old Timestamp [ $($cachedData.cachedTime) | New Timestamp [ $([DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")) ]"
            }

            $results = Invoke-PokeRequest -method GET -resource_Uri $resource_Uri -uri_Filter $PSBoundParameters -allPages:$allPages

            if ($results) {
                Set-PokeCachedData -name $cachedDataName -timeStamp $runTime -data $results
            }

        }
        else {

            Write-Verbose "Returning cached data: Cached is [ $( (New-TimeSpan -Start $cachedData.cachedTime -End $(Get-Date)).Minutes)min ] old"
            $results = $cachedData
            $results.PSObject.Properties.Remove('staleCache')
            $results.PSObject.Properties.Remove('cachedTime')

        }

        return $results

    }

    end {}

}
#EndRegion '.\Public\utility\Get-PokeLanguage.ps1' 153
