<#
    .SYNOPSIS
        Gets details for a random Pokemon

    .DESCRIPTION
        The Get-PokeApiRandomPokemon script gets details for a random Pokemon

    .PARAMETER base_uri
        Define the base URI for the Poke API connection using Poke's URI or a custom URI.

    .PARAMETER Report
        Defines if the script should output the results to a CSV, HTML or Both.

    .PARAMETER ShowReport
        Switch statement to open the report folder after the script runs.

    .EXAMPLE
        Get-PokeApiRandomPokemon

        Gets a random details for a pokemon from the PokeAPI

        Returned data is outputted to the console

    .EXAMPLE
        Get-PokeApiRandomPokemon -Report All -Verbose

        Gets a random details for a pokemon from the PokeAPI

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
    switch ([bool]$base_uri) {
        $true   { Add-PokeBaseURI -base_uri $base_uri }
        $false  { Add-PokeBaseURI }
    }

    #Get PokeApi data
    $ids     = (Get-PokePokemon -allPages -updateCache).results.url -replace "$Poke_Base_URI/pokemon/|/",''

    $PokeApi_Pokemon        = Get-PokePokemon -updateCache -id $(Get-Random -Minimum 1 -Maximum $ids)
    $Pokemon_Species        = Get-PokePokemonSpecies -name $PokeApi_Pokemon.species.name
    $Pokemon_Description    = (($Pokemon_Species).flavor_text_entries | Where-Object {$_.language.name -eq 'en'} | Select-Object -First 1).Flavor_text

    $PokeApi_Results        = [System.Collections.Generic.List[object]]::new()

    $data = [PSCustomObject]@{
        #Sprite      = $PokeApi_Pokemon.sprites.front_default
        Id          = $PokeApi_Pokemon.Id
        Name        = $PokeApi_Pokemon.Name
        Description = [string]::join(" ",($Pokemon_Description.Split("`n")))
        Generation  = $Pokemon_Species.Generation.Name
        Type        = $PokeApi_Pokemon.types.type.name -join '/'
        CaptureRate = $Pokemon_Species.capture_rate
        Moves       = $PokeApi_Pokemon.Moves.Count
        Height      = $PokeApi_Pokemon.height
        Weight      = $PokeApi_Pokemon.weight
    }

    $PokeApi_Results.Add($data) > $null

}
catch {
    Write-Error $_
}


#EndRegion  [ PokeAPI Data ]

Write-Verbose " - ($StepNumber/3) - $(Get-Date -Format MM-dd-HH:mm) - Generating PokeApi Report"
$StepNumber++

#Region     [ Report ]
Try{

    if ($PokeApi_Results) {

        Set-Variable -Name $($ReportFolderName -replace '-','_') -Value $PokeApi_Results -Scope Global -Force

        $PokeApi_Results = $PokeApi_Results | Sort-Object id

        if ([bool]$Report -eq $false){
            $PokeApi_Results
        }

        If($Report -eq 'All' -or $Report -eq 'CSV') {
            $PokeApi_Results | Export-Csv $CSVReport -NoTypeInformation
        }

        If($Report -eq 'All' -or $Report -eq 'HTML') {

            #HTML card header data to highlight useful information
            $Sprite      = "<a href=`"$($PokeApi_Pokemon.sprites.front_default)`"><img src=`"$($PokeApi_Pokemon.sprites.front_default)`" style=`"width:42px;height:42px;`"></a>"
            $Name        = $PokeApi_Results.Name
            $Generation  = $PokeApi_Results.Generation
            $Moves       = $PokeApi_Results.Moves
            $Height      = $PokeApi_Results.Height
            $Weight      = $PokeApi_Results.Weight

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
                $SummaryCards = $SummaryCards -replace ('xCARD1Valuex',$Sprite)
                $SummaryCards = $SummaryCards -replace ('xCARD2Valuex',$Name)
                $SummaryCards = $SummaryCards -replace ('xCARD3Valuex',$Generation)
                $SummaryCards = $SummaryCards -replace ('xCARD4Valuex',$Moves)
                $SummaryCards = $SummaryCards -replace ('xCARD5Valuex',$Height)
                $SummaryCards = $SummaryCards -replace ('xCARD6Valuex',$Weight)

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
            $TableResults = $PokeApi_Results | Select-Object * -ExcludeProperty Description | ConvertTo-Html -As Table -Fragment `
                                            -PostContent    "   <ul>
                                                                    <li>$($PokeApi_Results.Description)</li>
                                                                    <li>Note: SAMPLE 1 = Only applies to stuff and things</li>
                                                                    <li>Note: SAMPLE 2 = Only applies to stuff and things</li>
                                                                </ul>
                                                            "

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