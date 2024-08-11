<#
    .SYNOPSIS
        Gets general information about PokeApi

    .DESCRIPTION
        The Get-PokeApiOverview script gets general information about PokeApi

    .PARAMETER base_uri
        Define the base URI for the Poke API connection using Poke's URI or a custom URI.

    .PARAMETER Generation
        Defines what generation to pull an overview from

    .PARAMETER Report
        Defines if the script should output the results to a CSV, HTML or Both.

    .PARAMETER ShowReport
        Switch statement to open the report folder after the script runs.


    .EXAMPLE
        Get-PokeApiOverview

        Gets general PokeAPI resource information and generation 1 pokemon details

        Returned data is outputted to the console

    .EXAMPLE
        Get-PokeApiOverview -Report All -Verbose

        Gets general PokeAPI resource information and generation 1 pokemon details

        Returned data is outputted to both a CSV & HTML file with progress
        information being written to the console

    .NOTES
        N\A

    .LINK
        https://celerium.org/

    .LINK
        https://github.com/Celerium/PokeAPI-PowerShellWrapper

#>

#Requires -Version 5.1

#Region    [ Parameters ]

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [ValidateNotNullOrEmpty]
        [string]$base_uri,

        [Parameter(Mandatory=$false)]
        [ValidateRange(1,9)]
        [int]$Generation = 1,

        [Parameter(Mandatory=$false)]
        [ValidateSet('All','CSV','HTML')]
        [string]$Report,

        [Parameter(Mandatory=$false)]
        [switch]$ShowReport
    )

#EndRegion [ Parameters ]

Write-Verbose ''
Write-Verbose "Start - $(Get-Date -Format 'yyyy-MM-dd HH:mm') -  [ $($PSCmdlet.ParameterSetName) ]"
Write-Verbose ''

Write-Verbose " - (1/3) - $(Get-Date -Format MM-dd-HH:mm) - Setting Prerequisites"

#Region    [ Prerequisites ]

try {

    $ScriptName         = $MyInvocation.MyCommand.Name -replace '.ps1',''
    $ReportFolderName   = "$ScriptName-Report"
    $Date               = Get-Date
    $FileDate           = $Date.ToString('yyyy-MM-dd-HHmm')
    $HTMLDate           = $Date.ToString('yyyy-MM-dd HH:mmtt').ToLower()
    $StepNumber         = 2

    #Set PowerShell session to use TLS 1.2
    Write-Verbose " -       - $(Get-Date -Format MM-dd-HH:mm) - Setting TLS to 1.2"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12


    #Install the PokeApi PowerShell Module
    $packageProvider = Get-PackageProvider -Verbose:$false | Where-Object {$_.Name -eq 'NuGet'}

    If ($null -eq $packageProvider) {
        throw 'The NuGet prerequisites are not installed, Please update Nuget [ 2.8.5.201 ] or higher first'
    }

    $PokeApiModule = Get-InstalledModule -Name PokeAPI -ErrorAction SilentlyContinue

    If($null -eq $PokeApiModule) {
        Write-Verbose " -       - $(Get-Date -Format MM-dd-HH:mm) - Installing PokeApi PowerShell Module"
        Install-Module PokeAPI
    }

    Import-Module PokeAPI -Verbose:$false -ErrorAction Stop


    #Create & set report location
    if ([bool]$Report) {

        $Log        = "C:\Celerium\$ReportFolderName"
        $CSVReport  = "$Log\$ScriptName-$FileDate.csv"
        $HTMLReport = "$Log\$ScriptName-$FileDate.html"

        if ( (Test-Path -Path $Log -PathType Container) -eq $false ) {
            New-Item -Path $Log -ItemType Directory > $null
        }

    }

}
Catch{
    Write-Error $_
    exit 1
}

#EndRegion [ Prerequisites ]

Write-Verbose " - ($StepNumber/3) - $(Get-Date -Format MM-dd-HH:mm) - Getting PokeApi data"
$StepNumber++

#Region     [ PokeAPI Data ]

try {

    #Set PokeApi base uri
    switch ([bool]$base_uri){
        $true   { Add-PokeBaseURI -base_uri $base_uri }
        $false  { Add-PokeBaseURI }
    }

    #Get PokeApi data
    $PokeApi_Endpoint       = Get-PokeEndpoint
    $PokeApi_Language       = Get-PokeLanguage

    $PokeApi_Games          = Get-PokeGameVersion
    $PokeApi_Generation     = Get-PokeGameGeneration
    $PokeApi_Pokemon        = Get-PokePokemon

    $PokeApi_GenObject      = [System.Collections.Generic.List[object]]::new()

    $PokeApi_Gen            = Get-PokeGameGeneration -id $Generation
    $PokeApi_GenCount       = $PokeApi_Gen.pokemon_species.count

    $PokeApi_GenNumbers     = $PokeApi_Gen.pokemon_species.url -replace "$Poke_Base_URI/pokemon-species/|/",''
    foreach ($number in $PokeApi_GenNumbers) {
        $PokeApi_GenObject.Add([int]$number) > $null
    }

    $PokeApi_GenObject      = $PokeApi_GenObject | Sort-Object
    $PokeApi_GenStartNumber = $PokeApi_GenObject | Select-Object -First 1
    $PokeApi_GenEndNumber   = $PokeApi_GenObject | Select-Object -Last 1

    $PokeApi_PokemonCount   = @($PokeApi_GenStartNumber..$PokeApi_GenEndNumber)

    Write-Verbose " -       - $(Get-Date -Format MM-dd-HH:mm) - Getting [ $($PokeApi_GenCount) ] Generation $Generation Pokemon details"

    $PokemonResults         = [System.Collections.Generic.List[object]]::new()
    foreach ($Pokemon in $PokeApi_PokemonCount) {

        $data = Get-PokePokemon -id $Pokemon

        if ($data) {
            $PokemonResults.Add($data)  > $null
        }

    }

}
catch {
    Write-Error $_
}


#EndRegion  [ PokeAPI Data ]

Write-Verbose " - ($StepNumber/3) - $(Get-Date -Format MM-dd-HH:mm) - Generating PokeApi Report"
$StepNumber++

#Region     [ Report ]
Try{

    if ($PokemonResults) {

        Set-Variable -Name $($ReportFolderName -replace '-','_') -Value $PokemonResults -Scope Global -Force

        $PokemonResults = $PokemonResults | Sort-Object id

        if ([bool]$Report -eq $false){
            $PokemonResults
        }

        If($Report -eq 'All' -or $Report -eq 'CSV') {
            $PokemonResults | Export-Csv $CSVReport -NoTypeInformation
        }

        If($Report -eq 'All' -or $Report -eq 'HTML') {

            #HTML card header data to highlight useful information
            $TotalEndpoints         = $PokeApi_Endpoint.Count
            $TotalLanguages         = $PokeApi_Language.Count
            $TotalGames             = $PokeApi_Games.Count
            $TotalGenerations       = $PokeApi_Generation.Count
            $TotalPokemon           = $PokeApi_Pokemon.Count
            $TotalPokemonDetails    = ($PokemonResults | Measure-Object).Count

            $PokemonHTMLResults      = [System.Collections.Generic.List[object]]::new()
            foreach ($result in $PokemonResults) {

                $data = [PSCustomObject]@{
                    Id          = $result.id
                    Name        = $result.name
                    Generation  = $Generation
                    Type        = $result.types.type.name -join '/'
                    Height      = $result.height
                    Weight      = $result.weight
                }

                $PokemonHTMLResults.Add($data) > $null

            }

            #Region    [ HTML Report Building Blocks ]

            # Build the HTML header
            # This grabs the raw text from files to shorten the amount of lines in the PSScript
            # General idea is that the HTML assets would infrequently be changed once set
                $Meta = Get-Content -Path "$PSScriptRoot\Assets\Meta.html" -Raw
                $Meta = $Meta -replace 'xTITLECHANGEx',"$ScriptName"
                $CSS = Get-Content -Path "$PSScriptRoot\Assets\Styles.css" -Raw
                $JavaScript = Get-Content -Path "$PSScriptRoot\Assets\JavaScriptHeader.html" -Raw
                $Head = $Meta + ("<style>`n") + $CSS + ("`n</style>") + $JavaScript

            # HTML Body Building Blocks (In order)
                $TopNav = Get-Content -Path "$PSScriptRoot\Assets\TopBar.html" -Raw
                $DivMainStart = '<div id="layoutSidenav">'
                $SideBar = Get-Content -Path "$PSScriptRoot\Assets\SideBar.html" -Raw
                $SideBar = $SideBar -replace ('xTIMESETx',"$HTMLDate")
                $DivSecondStart = '<div id="layoutSidenav_content">'
                $PreLoader = Get-Content -Path "$PSScriptRoot\Assets\PreLoader.html" -Raw
                $MainStart = '<main>'

            #Base Table Container
                $BaseTableContainer = Get-Content -Path "$PSScriptRoot\Assets\TableContainer.html" -Raw

            #Summary Header
                $SummaryTableContainer = $BaseTableContainer
                $SummaryTableContainer = $SummaryTableContainer -replace ('xHEADERx',"$ScriptName - Summary")
                $SummaryTableContainer = $SummaryTableContainer -replace ('xBreadCrumbx','')

            #Summary Cards
            #HTML in Summary.html would be edited depending on the report and summary info you want to show
                $SummaryCards = Get-Content -Path "$PSScriptRoot\Assets\Summary.html" -Raw
                $SummaryCards = $SummaryCards -replace ('xCARD1Valuex',$TotalEndpoints)
                $SummaryCards = $SummaryCards -replace ('xCARD2Valuex',$TotalLanguages)
                $SummaryCards = $SummaryCards -replace ('xCARD3Valuex',$TotalGames)
                $SummaryCards = $SummaryCards -replace ('xCARD4Valuex',$TotalGenerations)
                $SummaryCards = $SummaryCards -replace ('xCARD5Valuex',$TotalPokemon)
                $SummaryCards = $SummaryCards -replace ('xCARD6Valuex',$TotalPokemonDetails)

            #Body table headers, would be duplicated\adjusted depending on how many tables you want to show
                $BodyTableContainer = $BaseTableContainer
                $BodyTableContainer = $BodyTableContainer -replace ('xHEADERx',"$ScriptName - Details")
                $BodyTableContainer = $BodyTableContainer -replace ('xBreadCrumbx',"Data gathered from $(hostname)")

            #Ending HTML
                $DivEnd = '</div>'
                $MainEnd = '</main>'
                $JavaScriptEnd = Get-Content -Path "$PSScriptRoot\Assets\JavaScriptEnd.html" -Raw

            #EndRegion [ HTML Report Building Blocks ]
            #Region    [ Example HTML Report Data\Structure ]

            #Creates an HTML table from PowerShell function results without any extra HTML tags
            $TableResults = $PokemonHTMLResults | ConvertTo-Html -As Table -Fragment `
                                            -PostContent    '   <ul>
                                                                    <li>Note: SAMPLE 1 = Only applies to stuff and things</li>
                                                                    <li>Note: SAMPLE 2 = Only applies to stuff and things</li>
                                                                    <li>Note: SAMPLE 3 = Only applies to stuff and things</li>
                                                                </ul>
                                                            '

            #Table section segregation
            #PS doesn't create a <thead> tag so I have find the first row and make it so
            $TableHeader = $TableResults -split "`r`n" | Where-Object {$_ -match '<th>'}
            #Unsure why PS makes empty <colgroup> as it contains no data
            $TableColumnGroup = $TableResults -split "`r`n" | Where-Object {$_ -match '<colgroup>'}

            #Table ModIfications
            #Replacing empty html table tags with simple replaceable names
            #It was annoying me that empty rows showed in the raw HTML and I couldn't delete them as they were not $NUll but were empty
            $TableResults = $TableResults -replace ($TableHeader,'xblanklinex')
            $TableResults = $TableResults -replace ($TableColumnGroup,'xblanklinex')
            $TableResults = $TableResults | Where-Object {$_ -ne 'xblanklinex'} | ForEach-Object {$_.Replace('xblanklinex','')}

            #Inject modified data back into the table
            #Makes the table have a <thead> tag
            $TableResults = $TableResults -replace '<Table>',"<Table>`n<thead>$TableHeader</thead>"
            $TableResults = $TableResults -replace '<table>','<table class="dataTable-table" style="width: 100%;">'

            #Mark Focus Data to draw attention\talking points
            #Need to understand RegEx more as this doesn't scale at all
            $TableResults = $TableResults -replace '<td>True</td>','<td class="WarningStatus">True</td>'


            #Building the final HTML report using the various ordered HTML building blocks from above.
            #This is injecting html\css\javascript in a certain order into a file to make an HTML report
            $HTML = ConvertTo-HTML -Head $Head -Body "  $TopNav $DivMainStart $SideBar $DivSecondStart $PreLoader $MainStart
                                                        $SummaryTableContainer $SummaryCards $DivEnd $DivEnd $DivEnd
                                                        $BodyTableContainer $TableResults $DivEnd $DivEnd $DivEnd
                                                        $MainEnd $DivEnd $DivEnd $JavaScriptEnd
                                                    "
            $HTML = $HTML -replace '<body>','<body class="sb-nav-fixed">'
            $HTML | Out-File $HTMLReport -Encoding utf8

        }


    }
    else{
        Write-Warning " -       - $(Get-Date -Format MM-dd-HH:mm) - No data found"
    }

}
catch {
    Write-Error $_
}

#EndRegion [ Report ]

If ($ShowReport -and [bool]$Report -eq $true){ Invoke-Item $Log }

Write-Verbose ''
Write-Verbose "END - $(Get-Date -Format yyyy-MM-dd-HH:mm)"
Write-Verbose ''