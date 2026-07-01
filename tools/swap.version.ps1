# ==============================================================================
# Timberborn Instant Swapper (Native Steam Manifest Method)
# ==============================================================================

$steamPath = (Get-ItemProperty -Path "HKCU:\Software\Valve\Steam" -ErrorAction Stop).SteamPath
$steamapps = Join-Path $steamPath "steamapps"
$common = Join-Path $steamapps "common"

# Target Folder Names
$normalDirName = "timberborn_main"
$expDirName    = "timberborn_experimental"

# Paths to the Main Manifest and the SteamCMD Manifests
$mainManifest = Join-Path $steamapps "appmanifest_1062090.acf"
$normalManifestSrc = Join-Path $common "$normalDirName\steamapps\appmanifest_1062090.acf"
$expManifestSrc    = Join-Path $common "$expDirName\steamapps\appmanifest_1062090.acf"

# 1. Validation
if (!(Test-Path $normalManifestSrc) -or !(Test-Path $expManifestSrc)) {
    Write-Host "Error: Missing SteamCMD manifests. Please run the SteamCMD updater script first." -ForegroundColor Red
    Start-Sleep -Seconds 5
    Exit
}

if (!(Test-Path $mainManifest)) {
    Write-Host "Error: Main Steam manifest not found. Is the game installed?" -ForegroundColor Red
    Start-Sleep -Seconds 5
    Exit
}

# 2. Close Steam Gracefully
$steamProcesses = Get-Process -Name "steam" -ErrorAction SilentlyContinue
if ($steamProcesses) {
    Write-Host "Closing Steam to safely swap files..." -ForegroundColor Yellow
    Start-Process -FilePath "$steamPath\steam.exe" -ArgumentList "-shutdown" -Wait
    Start-Sleep -Seconds 3
    Stop-Process -Name "steam" -Force -ErrorAction SilentlyContinue
}

# 3. Read active manifest to preserve keys and determine current state
$currentManifest = Get-Content $mainManifest -Raw

$lastPlayed = ""
if ($currentManifest -match '(?m)^\s*"LastPlayed"\s+"([^"]*)"') { $lastPlayed = $matches[1] }

$launcherPath = ""
if ($currentManifest -match '(?m)^\s*"LauncherPath"\s+"([^"]*)"') { $launcherPath = $matches[1] }

$currentInstallDir = ""
if ($currentManifest -match '(?m)^\s*"installdir"\s+"([^"]*)"') { $currentInstallDir = $matches[1] }

# Determine Target State
if ($currentInstallDir -eq $expDirName) {
    $targetVersion = "Normal"
    $targetManifestSrc = $normalManifestSrc
    $targetInstallDir = $normalDirName
} else {
    $targetVersion = "Experimental"
    $targetManifestSrc = $expManifestSrc
    $targetInstallDir = $expDirName
}

# 4. Perform the Swap
Write-Host "Swapping to $targetVersion branch..." -ForegroundColor Cyan

# Load the base SteamCMD manifest for the target version
$newManifest = Get-Content $targetManifestSrc -Raw

# Update 'installdir'
$newManifest = $newManifest -replace '(?m)(^\s*"installdir"\s+)"[^"]*"', "`$1`"$targetInstallDir`""

# Inject preserved 'LastPlayed'
if ($lastPlayed) {
    if ($newManifest -match '(?m)^\s*"LastPlayed"') {
        $newManifest = $newManifest -replace '(?m)(^\s*"LastPlayed"\s+)"[^"]*"', "`$1`"$lastPlayed`""
    } else {
        $newManifest = $newManifest -replace '(?m)(^\s*"installdir"\s+"[^"]*")', "`$1`n`t`"LastPlayed`"`t`t`"$lastPlayed`""
    }
}

# Inject preserved 'LauncherPath'
if ($launcherPath) {
    if ($newManifest -match '(?m)^\s*"LauncherPath"') {
        $newManifest = $newManifest -replace '(?m)(^\s*"LauncherPath"\s+)"[^"]*"', "`$1`"$launcherPath`""
    } else {
        $newManifest = $newManifest -replace '(?m)(^\s*"installdir"\s+"[^"]*")', "`$1`n`t`"LauncherPath`"`t`t`"$launcherPath`""
    }
}

# Beta Key Management (for Steam UI consistency)
if ($targetVersion -eq "Experimental") {
    if ($newManifest -notmatch '"BetaKey"\s+"experimental"') {
        $newManifest = $newManifest -replace '("UserConfig"\s*\{)', "`$1`n`t`t`"BetaKey`"`t`t`"experimental`""
    }
} else {
    $newManifest = $newManifest -replace '(?m)^\s*"BetaKey"\s+"[^"]*"\r?\n?', ''
}

# 5. Write the final assembled manifest back to Steam
[System.IO.File]::WriteAllText($mainManifest, $newManifest)
Write-Host "Successfully updated manifest to point to $targetInstallDir!" -ForegroundColor Green

# Remove the legacy junction if it exists so things stay clean
$activeJunctionPath = Join-Path $common "Timberborn"
if ((Get-Item $activeJunctionPath -ErrorAction SilentlyContinue).Attributes -match "ReparsePoint") {
    cmd /c rd "$activeJunctionPath"
}

# 6. Restart Steam
Write-Host "Restarting Steam..." -ForegroundColor Cyan
Start-Process -FilePath "$steamPath\steam.exe"

Start-Sleep -Seconds 3