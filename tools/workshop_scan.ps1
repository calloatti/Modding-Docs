param(
    # Live by default. Pass this switch to perform a safe simulation.
    [switch] $Dry
)

# ==============================================================================
# PowerShell Script: Unified Steam Workshop Master Orchestrator
# Scrapes local changelogs and triggers the publisher (which handles hashing).
# ==============================================================================

$ErrorActionPreference = "Stop"

# Root directory configuration profiles
$SourceCodeRoot = "C:\Users\calloatti\source\repos\Mods"
$ModFilesRoot   = "C:\Users\calloatti\Documents\Timberborn\Mods"

# Locate the companion publisher script
$publishScriptPath = Join-Path $PSScriptRoot "workshop_publish.ps1"

if (-not (Test-Path $publishScriptPath)) {
    Write-Host "[!] CRITICAL ERROR: Could not locate publisher script: $publishScriptPath" -ForegroundColor Red
    pause; exit
}

# Scan the source repository to find active development mod projects
$modFolders = Get-ChildItem -Path $SourceCodeRoot -Directory

foreach ($mod in $modFolders) {
    $modName = $mod.Name
    $gameModFolder = Join-Path $ModFilesRoot $modName
    $metaFolder = Join-Path $mod.FullName ".meta"
    
    # Skip if the mod hasn't been compiled into the game folder yet
    if (-not (Test-Path $gameModFolder)) { continue }

    Write-Host "[+] Evaluating Mod: $modName" -ForegroundColor Cyan

    # Ensure .meta folder exists
    if (-not (Test-Path $metaFolder)) {
        [void](New-Item -ItemType Directory -Path $metaFolder -Force)
    }

    # --------------------------------------------------------------------------
    # STEP 1: HARVEST LOCAL CHANGELOGS (Strict Top-Item Only)
    # --------------------------------------------------------------------------
    $versionFolders = Get-ChildItem -Path $gameModFolder -Directory | 
                      Where-Object { $_.Name -like "Version-*" } |
                      Sort-Object Name -Descending

    if ($versionFolders.Count -eq 0) {
        Write-Host "    -> No 'Version-*' folders found. Skipping changelog generation." -ForegroundColor Gray
    } else {
        $consolidatedChangelog = @()

        foreach ($verFolder in $versionFolders) {
            $changelogPath = Join-Path $verFolder.FullName "changelog.txt"
            
            if (Test-Path $changelogPath) {
                $topItem = @()
                
                # Read line-by-line, capturing the top entry and its trailing dashed line
                foreach ($line in Get-Content -Path $changelogPath) {
                    $topItem += $line
                    
                    # Stop reading immediately after capturing the first dashed line
                    if ($line -match '^-{20,}') { 
                        break 
                    }
                }

                $extractedText = ($topItem -join "`r`n").Trim()

                if ($extractedText) {
                    $consolidatedChangelog += $extractedText
                }
            }
        }

        # Write the cleanly extracted changelog required by workshop_publish.ps1
        $changelogFilePath = Join-Path $metaFolder "workshop_changelog.txt"
        if ($consolidatedChangelog.Count -gt 0) {
            Set-Content -Path $changelogFilePath -Value $consolidatedChangelog -Force
            Write-Host "    -> Extracted and saved consolidated changelog." -ForegroundColor Gray
        }
    }

    # --------------------------------------------------------------------------
    # STEP 2: TRIGGER PUBLISHER
    # --------------------------------------------------------------------------
    Write-Host "[+] Executing: workshop_publish.ps1 -ModName $modName -Dry:$Dry" -ForegroundColor DarkYellow
    
    # Trigger the child publisher script. 
    # (Hashing and change-detection are automatically handled inside this script)
    & $publishScriptPath -ModName $modName -Dry:$Dry
}

Write-Host "`nOrchestrator sweep complete!" -ForegroundColor Green