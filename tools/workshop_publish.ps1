param(
    [Parameter(Mandatory = $true)]
    [string] $ModName,

    # Live by default. Pass this switch to perform a safe simulation.
    [switch] $Dry
)

$ErrorActionPreference = "Stop"

# ==============================================================================
# CONFIGURATION PROFILES
# ==============================================================================
$SourceCodeRoot = "C:\Users\calloatti\source\repos\Mods"
$ModFilesRoot   = "C:\Users\calloatti\Documents\Timberborn\Mods"

$SteamCmdPath   = "C:\Users\calloatti\Documents\Timberborn\Mods.Modding\steamcmd\steamcmd.exe"
$SteamUserName  = "osmuni"

# ==============================================================================
# ENVIRONMENT RESOLUTION & VALIDATION
# ==============================================================================
$modSourceFolder = Join-Path $SourceCodeRoot $ModName
$modFilesFolder  = Join-Path $ModFilesRoot $ModName
$metaFolder      = Join-Path $modSourceFolder ".meta"

$jsonPath        = Join-Path $modFilesFolder "workshop_data.json"
$changelogPath   = Join-Path $metaFolder "workshop_changelog.txt"

# Standardized convention paths
$logPath         = Join-Path $metaFolder "workshop.log"
$hashPath        = Join-Path $metaFolder "workshop_hash.txt"
$steamNativeLog  = Join-Path (Split-Path $SteamCmdPath) "logs/workshop_log.txt"

# Non-fatal exit if metadata file is completely missing
if (-not (Test-Path $jsonPath)) {
    Write-Host "  [!] Missing workshop_data.json in $ModFilesRoot\$ModName. Skipping deployment." -ForegroundColor Yellow
    return
}

# Parse the JSON details from the active game tracking tree
$jsonData = Get-Content -Path $jsonPath -Raw | ConvertFrom-Json
$itemId   = $jsonData.ItemId

# Non-fatal exit if the Item ID hasn't been generated yet
if (-not $itemId) {
    Write-Host "  [!] No valid ItemId defined in $ModName\workshop_data.json. Skipping deployment." -ForegroundColor Yellow
    return
}

# Use safe forward slashes for paths to bypass VDF escaping rules
$contentFolderVdf = $modFilesFolder.Replace('\', '/')

# Fetch update logs and preserve raw CRLF line breaks intact
$changeNote = (Test-Path $changelogPath) ? (Get-Content -Path $changelogPath -Raw) : "Update"
if ([string]::IsNullOrWhiteSpace($changeNote)) { $changeNote = "Update" }
$changeNote = $changeNote.Replace('"', '\"')

# ==============================================================================
# DETERMINISTIC FOLDER HASH CALCULATOR & STATE VALIDATION
# ==============================================================================
$needsUpdate = $false
$currentFolderHash = ""

Write-Host "[+] Calculating current payload footprint signature for: $ModName..." -ForegroundColor Cyan

# Gather all files recursively, explicitly ignoring files in the root mod folder
$targetFiles = Get-ChildItem -Path $modFilesFolder -Recurse -File | 
               Where-Object { 
                   $_.DirectoryName -ne $modFilesFolder
               } | 
               Sort-Object FullName

if (-not $targetFiles) {
    throw "Target mod execution directory is empty or cannot be evaluated."
}

$fileHashes = foreach ($file in $targetFiles) {
    (Get-FileHash -Path $file.FullName -Algorithm SHA256).Hash
}

$combinedHashesString = $fileHashes -join ""
$stringBytes          = [System.Text.Encoding]::UTF8.GetBytes($combinedHashesString)
$sha256Engine         = [System.Security.Cryptography.SHA256]::Create()
$finalHashBytes       = $sha256Engine.ComputeHash($stringBytes)
$currentFolderHash    = ([System.BitConverter]::ToString($finalHashBytes) -replace "-").ToLower()

Write-Host "    -> Current:  $currentFolderHash" -ForegroundColor Gray

if (-not (Test-Path $hashPath)) {
    Write-Host "[!] Change Detected: 'workshop_hash.txt' is missing. Fresh upload required." -ForegroundColor Yellow
    $needsUpdate = $true
} else {
    $savedHash = (Get-Content -Path $hashPath -Raw).Trim()
    Write-Host "    -> Saved:    $savedHash" -ForegroundColor Gray

    if ($currentFolderHash -ne $savedHash) {
        Write-Host "[!] Change Detected: Local directory modified since last successful deployment." -ForegroundColor Yellow
        $needsUpdate = $true
    }
}

# ==============================================================================
# MANIFEST COMPILATION & STORAGE (Dynamic Key Insertion)
# ==============================================================================
$vdfPath = Join-Path $metaFolder "workshop.vdf"

# Construct VDF array dynamically based on mode
$vdfLines = @(
    '"workshopitem"',
    '{',
    '    "appid" "1062090"',
    "    `"publishedfileid`" `"$itemId`"",
    "    `"contentfolder`" `"$contentFolderVdf`"",
    "    `"changenote`" `"$changeNote`""
)

$vdfLines += "}"

$vdfContent = $vdfLines -join "`r`n"
Set-Content -LiteralPath $vdfPath -Value $vdfContent -Encoding UTF8
Write-Host "[+] Local Config Sync: 'workshop.vdf' successfully generated/refreshed." -ForegroundColor DarkGreen

# ==============================================================================
# TRANSACTION GATEWAY GATING LOOP
# ==============================================================================
if (-not $needsUpdate) {
    Write-Host "[+] Up to Date: Local files match last recorded signature. Skipping SteamCMD upload pipeline.`n" -ForegroundColor Green
    return
}

# ==============================================================================
# EXECUTION & CLEAN LOGGING BLOCK
# ==============================================================================
if (-not $Dry) {
    if (-not (Test-Path $SteamCmdPath)) {
        throw "Operational asset missing: steamcmd.exe not found at location: $SteamCmdPath"
    }

    if (Test-Path $logPath) { Remove-Item -Path $logPath -Force }
    if (Test-Path $steamNativeLog) { Remove-Item -Path $steamNativeLog -Force }

    Write-Host "`n[+] Initializing live upload sequence via SteamCMD..." -ForegroundColor Yellow
    
    & $SteamCmdPath +login $SteamUserName +workshop_build_item $vdfPath +quit
    
    $steamCmdExitCode = $LASTEXITCODE

    if (Test-Path $steamNativeLog) {
        Copy-Item -Path $steamNativeLog -Destination $logPath -Force
    }
    
    if ($steamCmdExitCode -ne 0) {
        throw "SteamCMD transaction faulted during active payload transmission. Exit code: $steamCmdExitCode. Check log file for details."
    }
    
    # SUCCESS ACCREDITATION GATE: Lock in the hash
    Set-Content -LiteralPath $hashPath -Value $currentFolderHash -Encoding utf8
    Write-Host "[+] Live upload complete. Log generated and change signature locked into: workshop_hash.txt`n" -ForegroundColor Green
} else {
    Write-Host "`n[+] Dry Run Mode Active: Modification check passed. Upload bypassed due to explicit switch presence.`n" -ForegroundColor DarkYellow
}