#
# Module manifest for module 'PokeAPI'
#
# Generated by: David Schulte
#
# Generated on: 2024-02-24
#

@{

    # Script module or binary module file associated with this manifest
    RootModule = 'PokeAPI.psm1'

    # Version number of this module.
    # Follows https://semver.org Semantic Versioning 2.0.0
    # Given a version number MAJOR.MINOR.PATCH, increment the:
    # -- MAJOR version when you make incompatible API changes,
    # -- MINOR version when you add functionality in a backwards-compatible manner, and
    # -- PATCH version when you make backwards-compatible bug fixes.

    # Version number of this module.
    ModuleVersion = '1.1.0'

    # Supported PSEditions
    # CompatiblePSEditions = @()

    # ID used to uniquely identify this module
    GUID = 'd6c6b73e-d0ad-4d09-8a24-a5a05064d26c'

    # Author of this module
    Author = 'David Schulte'

    # Company or vendor of this module
    CompanyName = 'Celerium'

    # Copyright information of this module
    Copyright = 'https://github.com/Celerium/PokeAPI-PowerShellWrapper/blob/main/LICENSE'

    # Description of the functionality provided by this module
    Description = 'This module provides a PowerShell wrapper for PokeAPI'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Name of the Windows PowerShell host required by this module
    # PowerShellHostName = ''

    # Minimum version of the Windows PowerShell host required by this module
    # PowerShellHostVersion = ''

    # Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # DotNetFrameworkVersion = ''

    # Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # CLRVersion = ''

    # Processor architecture (None, X86, Amd64) required by this module
    # ProcessorArchitecture = ''

    # Modules that must be imported into the global environment prior to importing this module
    # RequiredModules = @( )

    # Assemblies that must be loaded prior to importing this module
    # RequiredAssemblies = @()

    # Script files (.ps1) that are run in the caller's environment prior to importing this module.
    #ScriptsToProcess = @()

    # Type files (.ps1xml) to be loaded when importing this module
    # TypesToProcess = @()

    # Format files (.ps1xml) to be loaded when importing this module
    # FormatsToProcess = @()

    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    NestedModules = 'Private/apiCalls/ConvertTo-PokeQueryString.ps1',
                    'Private/apiCalls/Invoke-PokeRequest.ps1',
                    'Private/apiCalls/Get-PokeMetaData.ps1',
                    'Private/apiCalls/Get-PokeCachedData.ps1',
                    'Private/apiCalls/Set-PokeCachedData.ps1',

                    'Private/baseUri/Add-PokeBaseURI.ps1',
                    'Private/baseUri/Get-PokeBaseURI.ps1',
                    'Private/baseUri/Remove-PokeBaseURI.ps1',

                    'Private/moduleSettings/Export-PokeModuleSettings.ps1',
                    'Private/moduleSettings/Get-PokeModuleSettings.ps1',
                    'Private/moduleSettings/Import-PokeModuleSettings.ps1',
                    'Private/moduleSettings/Initialize-PokeModuleSettings.ps1',
                    'Private/moduleSettings/Remove-PokeModuleSettings.ps1',

                    'Public/berry/Get-PokeBerry.ps1',
                    'Public/berry/Get-PokeBerryFirmness.ps1',
                    'Public/berry/Get-PokeBerryFlavor.ps1',

                    'Public/contest/Get-PokeContestType.ps1',
                    'Public/contest/Get-PokeContestEffect.ps1',
                    'Public/contest/Get-PokeContestSuperEffect.ps1',

                    'Public/encounter/Get-PokeEncounterMethod.ps1',
                    'Public/encounter/Get-PokeEncounterCondition.ps1',
                    'Public/encounter/Get-PokeEncounterConditionValue.ps1',

                    'Public/evolution/Get-PokeEvolutionChain.ps1',
                    'Public/evolution/Get-PokeEvolutionTrigger.ps1',

                    'Public/game/Get-PokeGameGeneration.ps1',
                    'Public/game/Get-PokeGamePokedex.ps1',
                    'Public/game/Get-PokeGameVersion.ps1',
                    'Public/game/Get-PokeGameVersionGroup.ps1',

                    'Public/item/Get-PokeItem.ps1',
                    'Public/item/Get-PokeItemAttribute.ps1',
                    'Public/item/Get-PokeItemCategory.ps1',
                    'Public/item/Get-PokeItemFlingEffect.ps1',
                    'Public/item/Get-PokeItemPocket.ps1',

                    'Public/location/Get-PokeLocation.ps1',
                    'Public/location/Get-PokeLocationArea.ps1',
                    'Public/location/Get-PokeLocationPalParkArea.ps1',
                    'Public/location/Get-PokeLocationRegion.ps1',

                    'Public/machine/Get-PokeMachine.ps1',

                    'Public/move/Get-PokeMove.ps1',
                    'Public/move/Get-PokeMoveAilment.ps1',
                    'Public/move/Get-PokeMoveBattleStyle.ps1',
                    'Public/move/Get-PokeMoveCategory.ps1',
                    'Public/move/Get-PokeMoveDamageClass.ps1',
                    'Public/move/Get-PokeMoveLearnMethod.ps1',
                    'Public/move/Get-PokeMoveTarget.ps1',

                    'Public/pokemon/Get-PokePokemon.ps1',
                    'Public/pokemon/Get-PokePokemonAbility.ps1',
                    'Public/pokemon/Get-PokePokemonCharacteristic.ps1',
                    'Public/pokemon/Get-PokePokemonColor.ps1',
                    'Public/pokemon/Get-PokePokemonEggGroup.ps1',
                    'Public/pokemon/Get-PokePokemonEncounter.ps1',
                    'Public/pokemon/Get-PokePokemonForm.ps1',
                    'Public/pokemon/Get-PokePokemonGender.ps1',
                    'Public/pokemon/Get-PokePokemonGrowthRate.ps1',
                    'Public/pokemon/Get-PokePokemonHabitat.ps1',
                    'Public/pokemon/Get-PokePokemonNature.ps1',
                    'Public/pokemon/Get-PokePokemonPokeathlonStat.ps1',
                    'Public/pokemon/Get-PokePokemonShape.ps1',
                    'Public/pokemon/Get-PokePokemonSpecies.ps1',
                    'Public/pokemon/Get-PokePokemonStat.ps1',
                    'Public/pokemon/Get-PokePokemonType.ps1',

                    'Public/utility/Get-PokeLanguage.ps1',
                    'Public/utility/Get-PokeEndpoint.ps1'

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = '*'

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport = @()

    # Variables to export from this module
    VariablesToExport = '*'

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport = '*'

    # DSC resources to export from this module
    # DscResourcesToExport = @()

    # List of all modules packaged with this module
    # ModuleList = @()

    # List of all files packaged with this module
    # FileList = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData = @{

        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @('PokeAPI', 'Pokemon', 'API', 'PowerShell', 'Windows', 'MacOS', 'Linux', 'PSEdition_Desktop', 'PSEdition_Core', 'Celerium')

            # A URL to the license for this module.
            LicenseUri = 'https://github.com/Celerium/PokeAPI-PowerShellWrapper/blob/main/LICENSE'

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/Celerium/PokeAPI-PowerShellWrapper'

            # A URL to an icon representing this module.
            IconUri = 'https://raw.githubusercontent.com/Celerium/PokeAPI-PowerShellWrapper/main/.github/images/Celerium_PoSHGallery_PokeAPI.png'

            # ReleaseNotes of this module
            ReleaseNotes = 'https://github.com/Celerium/PokeAPI-PowerShellWrapper/blob/main/README.md'

            # Identifies the module as a prerelease version in online galleries.
            #PreRelease = '-BETA'

            # Indicate whether the module requires explicit user acceptance for install, update, or save.
            RequireLicenseAcceptance = $false

        } # End of PSData hashtable

    } # End of PrivateData hashtable

    # HelpInfo URI of this module
    # HelpInfoURI = 'https://github.com/Celerium/PokeAPI-PowerShellWrapper'

    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = ''

}

