---
external help file: PokeAPI-help.xml
Module Name: PokeAPI
online version: https://github.com/Celerium/PokeAPI-PowerShellWrapper
schema: 2.0.0
title: Home
has_children: true
layout: default
nav_order: 1
---

<h1 align="center">
  <br>
  <a href="http://Celerium.org"><img src="https://raw.githubusercontent.com/Celerium/PokeAPI-PowerShellWrapper/main/.github/images/Celerium_PoSHGallery_PokeAPI.png" alt="_CeleriumDemo" width="200"></a>
  <br>
  Celerium_PokeAPI
  <br>
</h1>

[![Az_Pipeline][Az_Pipeline-shield]][Az_Pipeline-url]
[![GitHub_Pages][GitHub_Pages-shield]][GitHub_Pages-url]

[![PoshGallery_Version][PoshGallery_Version-shield]][PoshGallery_Version-url]
[![PoshGallery_Platforms][PoshGallery_Platforms-shield]][PoshGallery_Platforms-url]
[![PoshGallery_Downloads][PoshGallery_Downloads-shield]][PoshGallery_Downloads-url]
[![codeSize][codeSize-shield]][codeSize-url]

[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]

[![Blog][Website-shield]][Website-url]
[![GitHub_License][GitHub_License-shield]][GitHub_License-url]
---

## Buy me a coffee

Whether you use this project, have learned something from it, or just like it, please consider supporting it by buying me a coffee, so I can dedicate more time on open-source projects like this :)

<a href="https://www.buymeacoffee.com/Celerium" target="_blank"><img src="https://www.buymeacoffee.com/assets/img/guidelines/download-assets-sm-2.svg" alt="Buy Me A Coffee" style="width:150px;height:50px;"></a>

---

<a name="readme-top"></a>

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://celerium.org">
    <img src="https://raw.githubusercontent.com/Celerium/PokeAPI-PowerShellWrapper/main/.github/images/Celerium_PoSHGitHub_PokeAPI.png" alt="Logo">
  </a>

  <p align="center">
    <a href="https://www.powershellgallery.com/packages/PokeAPI" target="_blank">PowerShell Gallery</a>
    ·
    <a href="https://github.com/Celerium/PokeAPI-PowerShellWrapper/issues/new/choose" target="_blank">Report Bug</a>
    ·
    <a href="https://github.com/Celerium/PokeAPI-PowerShellWrapper/issues/new/choose" target="_blank">Request Feature</a>
  </p>
</div>

---

<!-- TABLE OF CONTENTS
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
      <ul>
        <li><a href="#built-with">Built With</a></li>
      </ul>
    </li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#installation">Installation</a></li>
      </ul>
    </li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#roadmap">Roadmap</a></li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details>
-->

## About The Project

The [PokeAPI](https://pokeapi.co/) offers users the ability to extract data from Poke into third-party reporting tools and aims to abstract away the details of interacting with Poke's API endpoints in such a way that is consistent with PowerShell nomenclature. This gives system administrators and PowerShell developers a convenient and familiar way of using Poke's API to create documentation scripts, automation, and integrations.

- :book: Project documentation can be found on [Github Pages](https://celerium.github.io/PokeAPI-PowerShellWrapper/)
- :book: Poke's REST API documentation on their website [here](https://pokeapi.co/docs/v2).

Poke features a REST API that makes use of common HTTP request methods. In order to maintain PowerShell best practices, only approved verbs are used.

- GET -> Get-

Additionally, PowerShell's `verb-noun` nomenclature is respected. Each noun is prefixed with `Poke` in an attempt to prevent naming problems.

For example, one might access the `/pokemon/` endpoint by running the following PowerShell command with the appropriate parameters:

```posh
Get-PokePokemon -id 1
```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Install

This module can be installed directly from the [PowerShell Gallery](https://www.powershellgallery.com/packages/PokeAPI) with the following command:

```posh
Install-Module -Name PokeAPI
```

- :information_source: This module supports PowerShell 5.0+ and *should* work in PowerShell Core.
- :information_source: If you are running an older version of PowerShell, or if PowerShellGet is unavailable, you can manually download the *main* branch and place the *PokeAPI* folder into the (default) `C:\Program Files\WindowsPowerShell\Modules` folder.

Project documentation can be found on [Github Pages](https://celerium.github.io/PokeAPI-PowerShellWrapper/)

- A full list of functions can be retrieved by running `Get-Command -Module PokeAPI`.
- Help info and a list of parameters can be found by running `Get-Help <command name>`, such as:

```posh
Get-Help Get-PokePokemon
Get-Help Get-PokePokemon -Full
```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Initial Setup

After installing this module, you will need to configure both the *base URI* & *API access tokens* that are used to talk with the Poke API.

1. Run `Add-PokeBaseURI`
   - By default, Poke's `https://pokeapi.co/api/v2` URI is used.
   - If you have your own API gateway or proxy, you may put in your own custom URI by specifying the `-base_uri` parameter:
      - `Add-PokeBaseURI -base_uri http://myapi.gateway.celerium.org`
      <br>

2. [**optional**] Run `Export-PokeModuleSettings`
   - This will create a config file at `%UserProfile%\PokeAPI` that holds the *base uri* & *API access tokens* information.
   - Next time you run `Import-Module -Name PokeAPI`, this configuration file will automatically be loaded.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Usage

Calling an API resource is as simple as running `Get-Poke<resourceName>`

- The following is a table of supported functions and their corresponding API resources:
- Table entries with [ `-` ] indicate that the functionality is **NOT** supported by the Poke API at this time.

|Category |EndpointUri                             |Method|Function                       |
|---------|----------------------------------------|------|-------------------------------|
|berry    |/berry/                                 |GET   |Get-PokeBerry                  |
|berry    |/berry/{id or name}/                    |GET   |Get-PokeBerry                  |
|berry    |/berry-firmness                         |GET   |Get-PokeBerryFirmness          |
|berry    |/berry-firmness/{id or name}/           |GET   |Get-PokeBerryFirmness          |
|berry    |/berry-flavor/                          |GET   |Get-PokeBerryFlavor            |
|berry    |/berry-flavor/{id or name}/             |GET   |Get-PokeBerryFlavor            |
|contest  |/contest-type/                          |GET   |Get-PokeContestType            |
|contest  |/contest-type/{id or name}/             |GET   |Get-PokeContestType            |
|contest  |/contest-effect/                        |GET   |Get-PokeContestEffect          |
|contest  |/contest-effect/{id}/                   |GET   |Get-PokeContestEffect          |
|contest  |/super-contest-effect/                  |GET   |Get-PokeContestSuperEffect     |
|contest  |/super-contest-effect/{id}/             |GET   |Get-PokeContestSuperEffect     |
|encounter|/encounter-method/                      |GET   |Get-PokeEncounterMethod        |
|encounter|/encounter-method/{id or name}/         |GET   |Get-PokeEncounterMethod        |
|encounter|/encounter-condition/                   |GET   |Get-PokeEncounterCondition     |
|encounter|/encounter-condition/{id or name}/      |GET   |Get-PokeEncounterCondition     |
|encounter|/encounter-condition-value/{id or name}/|GET   |Get-PokeEncounterConditionValue|
|encounter|/encounter-condition-value/{id or name}/|GET   |Get-PokeEncounterConditionValue|
|evolution|/evolution-chain/                       |GET   |Get-PokeEvolutionChain         |
|evolution|/evolution-chain/{id}/                  |GET   |Get-PokeEvolutionChain         |
|evolution|/evolution-trigger/                     |GET   |Get-PokeEvolutionTrigger       |
|evolution|/evolution-trigger/{id or name}/        |GET   |Get-PokeEvolutionTrigger       |
|game     |/generation/                            |GET   |Get-PokeGameGeneration         |
|game     |/generation/{id or name}/               |GET   |Get-PokeGameGeneration         |
|game     |/pokedex/                               |GET   |Get-PokeGamePokedex            |
|game     |/pokedex/{id or name}/                  |GET   |Get-PokeGamePokedex            |
|game     |/version/                               |GET   |Get-PokeGameVersion            |
|game     |/version/{id or name}/                  |GET   |Get-PokeGameVersion            |
|game     |/version-group/                         |GET   |Get-PokeGameVersionGroup       |
|game     |/version-group/{id or name}/            |GET   |Get-PokeGameVersionGroup       |
|Internal |                                        |POST  |Add-PokeBaseURI                |
|Internal |                                        |PUT   |ConvertTo-PokeQueryString      |
|Internal |                                        |GET   |Export-PokeModuleSettings      |
|Internal |                                        |GET   |Get-PokeBaseURI                |
|Internal |                                        |GET   |Get-PokeMetaData               |
|Internal |                                        |GET   |Get-PokeModuleSettings         |
|Internal |                                        |SET   |Import-PokeModuleSettings      |
|Internal |                                        |GET   |Invoke-PokeRequest             |
|Internal |                                        |DELETE|Remove-PokeBaseURI             |
|Internal |                                        |DELETE|Remove-PokeModuleSettings      |
|item     |/item/                                  |GET   |Get-PokeItem                   |
|item     |/item/{id or name}/                     |GET   |Get-PokeItem                   |
|item     |/item-attribute/                        |GET   |Get-PokeItemAttribute          |
|item     |/item-attribute/{id or name}/           |GET   |Get-PokeItemAttribute          |
|item     |/item-category/                         |GET   |Get-PokeItemCategory           |
|item     |/item-category/{id or name}/            |GET   |Get-PokeItemCategory           |
|item     |/item-fling-effect/                     |GET   |Get-PokeItemFlingEffect        |
|item     |/item-fling-effect/{id or name}/        |GET   |Get-PokeItemFlingEffect        |
|item     |/item-pocket/                           |GET   |Get-PokeItemPocket             |
|item     |/item-pocket/{id or name}/              |GET   |Get-PokeItemPocket             |
|location |/location/                              |GET   |Get-PokeLocation               |
|location |/location/{id or name}/                 |GET   |Get-PokeLocation               |
|location |/location-area/                         |GET   |Get-PokeLocationArea           |
|location |/location-area/{id or name}/            |GET   |Get-PokeLocationArea           |
|location |/pal-park-area/                         |GET   |Get-PokeLocationPalParkArea    |
|location |/pal-park-area/{id or name}/            |GET   |Get-PokeLocationPalParkArea    |
|location |/region/                                |GET   |Get-PokeLocationRegion         |
|location |/region/{id or name}/                   |GET   |Get-PokeLocationRegion         |
|machine  |/machine/                               |GET   |Get-PokeMachine                |
|machine  |/machine/{id}/                          |GET   |Get-PokeMachine                |
|move     |/move/                                  |GET   |Get-PokeMove                   |
|move     |/move/{id or name}/                     |GET   |Get-PokeMove                   |
|move     |/move-ailment/                          |GET   |Get-PokeMoveAilment            |
|move     |/move-ailment/{id or name}/             |GET   |Get-PokeMoveAilment            |
|move     |/move-battle-style/                     |GET   |Get-PokeMoveBattleStyle        |
|move     |/move-battle-style/{id or name}/        |GET   |Get-PokeMoveBattleStyle        |
|move     |/move-category/                         |GET   |Get-PokeMoveCategory           |
|move     |/move-category/{id or name}/            |GET   |Get-PokeMoveCategory           |
|move     |/move-damage-class/                     |GET   |Get-PokeMoveDamageClass        |
|move     |/move-damage-class/{id or name}/        |GET   |Get-PokeMoveDamageClass        |
|move     |/move-learn-method/                     |GET   |Get-PokeMoveLearnMethod        |
|move     |/move-learn-method/{id or name}/        |GET   |Get-PokeMoveLearnMethod        |
|move     |/move-target/                           |GET   |Get-PokeMoveTarget             |
|move     |/move-target/{id or name}/              |GET   |Get-PokeMoveTarget             |
|pokemon  |/ability/                               |GET   |Get-PokePokemonAbility         |
|pokemon  |/ability/{id or name}/                  |GET   |Get-PokePokemonAbility         |
|pokemon  |/characteristic/                        |GET   |Get-PokePokemonCharacteristic  |
|pokemon  |/characteristic/{id}/                   |GET   |Get-PokePokemonCharacteristic  |
|pokemon  |/egg-group/                             |GET   |Get-PokePokemonEggGroup        |
|pokemon  |/egg-group/{id or name}/                |GET   |Get-PokePokemonEggGroup        |
|pokemon  |/gender/                                |GET   |Get-PokePokemonGender          |
|pokemon  |/gender/{id or name}/                   |GET   |Get-PokePokemonGender          |
|pokemon  |/growth-rate/                           |GET   |Get-PokePokemonGrowthRate      |
|pokemon  |/growth-rate/{id or name}/              |GET   |Get-PokePokemonGrowthRate      |
|pokemon  |/nature/                                |GET   |Get-PokePokemonNature          |
|pokemon  |/nature/{id or name}/                   |GET   |Get-PokePokemonNature          |
|pokemon  |/pokeathlon-stat/                       |GET   |Get-PokePokemonPokeathlonStat  |
|pokemon  |/pokeathlon-stat/{id or name}/          |GET   |Get-PokePokemonPokeathlonStat  |
|pokemon  |/pokemon/                               |GET   |Get-PokePokemon                |
|pokemon  |/pokemon/{id or name}/                  |GET   |Get-PokePokemon                |
|pokemon  |/pokemon/{id or name}/encounters        |GET   |Get-PokePokemonEncounter       |
|pokemon  |/pokemon-color/                         |GET   |Get-PokePokemonColor           |
|pokemon  |/pokemon-color/{id or name}/            |GET   |Get-PokePokemonColor           |
|pokemon  |/pokemon-form/                          |GET   |Get-PokePokemonForm            |
|pokemon  |/pokemon-form/{id or name}/             |GET   |Get-PokePokemonForm            |
|pokemon  |/pokemon-habitat/                       |GET   |Get-PokePokemonHabitat         |
|pokemon  |/pokemon-habitat/{id or name}/          |GET   |Get-PokePokemonHabitat         |
|pokemon  |/pokemon-shape/                         |GET   |Get-PokePokemonShape           |
|pokemon  |/pokemon-shape/{id or name}/            |GET   |Get-PokePokemonShape           |
|pokemon  |/pokemon-species/                       |GET   |Get-PokePokemonSpecies         |
|pokemon  |/pokemon-species/{id or name}/          |GET   |Get-PokePokemonSpecies         |
|pokemon  |/stat/                                  |GET   |Get-PokePokemonStat            |
|pokemon  |/stat/{id or name}/                     |GET   |Get-PokePokemonStat            |
|pokemon  |/type/                                  |GET   |Get-PokePokemonType            |
|pokemon  |/type/{id or name}/                     |GET   |Get-PokePokemonType            |
|utility  |/language/                              |GET   |Get-PokeLanguage               |
|utility  |/language/{id or name}/                 |GET   |Get-PokeLanguage               |
|utility  |/                                       |GET   |Get-PokeEndpoint               |

Each `Get-Poke*` function will respond with the raw data that Poke's API provides.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Roadmap

- [ ] Add Changelog
- [x] Build more robust Pester & ScriptAnalyzer tests
- [x] Figure out how to do CI & PowerShell gallery automation
- [ ] Add example scripts & automation

See the [open issues](https://github.com/Celerium/PokeAPI-PowerShellWrapper/issues) for a full list of proposed features (and known issues).

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

## Contributing

Contributions are what makes the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".
Don't forget to give the project a star! Thanks again!

See the [CONTRIBUTING](https://github.com/Celerium/PokeAPI-PowerShellWrapper/blob/main/.github/CONTRIBUTING.md) guide for more information about contributing.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## License

Distributed under the MIT License. See [`LICENSE`](https://github.com/Celerium/PokeAPI-PowerShellWrapper/blob/main/LICENSE) for more information.

[![GitHub_License][GitHub_License-shield]][GitHub_License-url]

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Contact

<div align="left">

  <p align="left">
    ·
    <a href="https://celerium.org/#/contact" target="_blank">Website</a>
    ·
    <a href="mailto: celerium@celerium.org">Email</a>
    ·
    <a href="https://www.reddit.com/user/CeleriumIO" target="_blank">Reddit</a>
    ·
  </p>
</div>

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Acknowledgments

Big thank you to the following people and services as they have provided me with lots of helpful information as I continue this project!

- [GitHub Pages](https://pages.github.com)
- [Img Shields](https://shields.io)
- [Font Awesome](https://fontawesome.com)
- [Choose an Open Source License](https://choosealicense.com)
- [GitHub Emoji Cheat Sheet](https://www.webpagefx.com/tools/emoji-cheat-sheet)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->

[Az_Pipeline-shield]:               https://img.shields.io/azure-devops/build/AzCelerium/PokeAPI/4?style=for-the-badge&label=DevOps_Build
[Az_Pipeline-url]:                  https://dev.azure.com/AzCelerium/PokeAPI/_build?definitionId=4

[GitHub_Pages-shield]:              https://img.shields.io/github/actions/workflow/status/celerium/PokeAPI-PowerShellWrapper/pages%2Fpages-build-deployment?style=for-the-badge&label=GitHub%20Pages
[GitHub_Pages-url]:                 https://github.com/Celerium/PokeAPI-PowerShellWrapper/actions/workflows/pages/pages-build-deployment

[GitHub_License-shield]:            https://img.shields.io/github/license/celerium/PokeAPI-PowerShellWrapper?style=for-the-badge
[GitHub_License-url]:               https://github.com/Celerium/PokeAPI-PowerShellWrapper/blob/main/LICENSE

[PoshGallery_Version-shield]:       https://img.shields.io/powershellgallery/v/PokeAPI?include_prereleases&style=for-the-badge
[PoshGallery_Version-url]:          https://www.powershellgallery.com/packages/PokeAPI

[PoshGallery_Platforms-shield]:     https://img.shields.io/powershellgallery/p/PokeAPI?style=for-the-badge
[PoshGallery_Platforms-url]:        https://www.powershellgallery.com/packages/PokeAPI

[PoshGallery_Downloads-shield]:     https://img.shields.io/powershellgallery/dt/PokeAPI?style=for-the-badge
[PoshGallery_Downloads-url]:        https://www.powershellgallery.com/packages/PokeAPI

[website-shield]:                   https://img.shields.io/website?up_color=blue&url=https%3A%2F%2Fcelerium.org&style=for-the-badge&label=Blog
[website-url]:                      https://celerium.org

[codeSize-shield]:                  https://img.shields.io/github/repo-size/celerium/PokeAPI-PowerShellWrapper?style=for-the-badge
[codeSize-url]:                     https://github.com/Celerium/PokeAPI-PowerShellWrapper

[contributors-shield]:              https://img.shields.io/github/contributors/celerium/PokeAPI-PowerShellWrapper?style=for-the-badge
[contributors-url]:                 https://github.com/Celerium/PokeAPI-PowerShellWrapper/graphs/contributors

[forks-shield]:                     https://img.shields.io/github/forks/celerium/PokeAPI-PowerShellWrapper?style=for-the-badge
[forks-url]:                        https://github.com/Celerium/PokeAPI-PowerShellWrapper/network/members

[stars-shield]:                     https://img.shields.io/github/stars/celerium/PokeAPI-PowerShellWrapper?style=for-the-badge
[stars-url]:                        https://github.com/Celerium/PokeAPI-PowerShellWrapper/stargazers

[issues-shield]:                    https://img.shields.io/github/issues/Celerium/PokeAPI-PowerShellWrapper?style=for-the-badge
[issues-url]:                       https://github.com/Celerium/PokeAPI-PowerShellWrapper/issues
