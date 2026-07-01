# Timberborn Automated Workshop Deployment Pipeline

This automated deployment stack consists of two companion PowerShell scripts designed to streamline, validate, and execute Steam Workshop mod uploads. Instead of manually handling Valve Data Format (VDF) files or launching user interfaces, this pipeline parses updates and pushes files securely using **SteamCMD**.

---

## Architecture Overview

    [ Local Workspace ] ──> ( workshop_scan.ps1 ) ──> ( workshop_publish.ps1 ) ──> [ SteamCMD ] ──> [ Steam Workshop ]
                                │                         │
                                ├── Scrapes Changelogs     ├── Computes SHA256 Hash
                                └── Creates .meta/        └── Generates workshop.vdf

### 1. workshop_scan.ps1 (The Orchestrator)
This script acts as the entry point. It scans your active mod directories, extracts local documentation, and triggers the update workflow for any project found.

* **Project Discovery:** Scans your development source paths and cross-references them against your compiled game mod directories. If a mod hasn't been built yet, it safely skips it.
* **Smart Changelog Harvesting:** Automatically checks version-controlled subdirectories (e.g., `Version-1.0/`, `Version-1.1/`). It parses each local `changelog.txt` and grabs **only the topmost entry block** (stopping precisely when it hits a dashed separator line like `--------------------`).
* **Consolidated Update Notes:** Combines these fresh entries into a single `workshop_changelog.txt` file located in a hidden `.meta/` folder, preparing it for the upload engine.

### 2. workshop_publish.ps1 (The Deployment Engine)
This script handles optimization, state validation, configuration generation, and transactional data transfer to Steam.

* **Deterministic Change Detection (SHA256 Hashing):** To prevent redundant uploads that trigger unnecessary updates for players, the script computes a unique SHA256 signature of the mod's target assets. 
* **State Locking:** If the newly calculated hash matches the previously recorded `workshop_hash.txt` file, the pipeline cleanly exits and skips the upload. If changes are found, it sets an update flag.
* **Dynamic VDF Generation:** Constructs a temporary, Steam-compliant Valve Data Format (`workshop.vdf`) file on the fly, dynamically embedding your unique Workshop `ItemId`, content paths, and escaped changelog strings.
* **Headless Transmission Gateway:** Executes `steamcmd.exe` directly via command-line arguments, authenticates with your configured profile, transfers the files to Valve's backend, and handles system exit codes cleanly.

---

## Project Structure Requirements

To utilize this automation pipeline out of the box, your mod directories should adhere to the standard Timberborn multi-version layout:

    Documents/Timberborn/Mods/
    └── YourModName/
        ├── workshop_data.json   <-- Must contain your generated Steam "ItemId"
        └── Version-1.1/
            └── changelog.txt    <-- Top section is scraped for Steam update notes

---

## Execution Profiles

### Dry Run (Safe Simulation)
To run a safe simulation that verifies file changes, parses changelogs, and generates local configurations **without** pushing anything live to Steam, run:

    .\workshop_scan.ps1 -Dry

### Live Deployment
To calculate your asset signatures, update documentation, and push all modified projects live to the Steam Workshop instantly:

    .\workshop_scan.ps1

The MSVS project file has this so rebuilds always have the same hash if nothing changed:

  <PropertyGroup>
    <Deterministic>true</Deterministic>
  </PropertyGroup>