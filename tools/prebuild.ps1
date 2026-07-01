param (
    [string]$ProjectDir,
    [string]$TargetDir
)

# Force strict output or error handling if required
$ErrorActionPreference = "Stop"

$ModsRoot = "C:\Users\calloatti\source\repos\Mods"

# Resolve absolute paths to ensure string matching works correctly
$ModsRootPath = (Get-Item $ModsRoot).FullName
$ProjectDir = (Get-Item $ProjectDir).FullName

if ($ProjectDir.StartsWith($ModsRootPath, [System.StringComparison]::OrdinalIgnoreCase)) {
    $RelativePath = $ProjectDir.Substring($ModsRootPath.Length).TrimStart([System.IO.Path]::DirectorySeparatorChar)
} else {
    Write-Error "ProjectDir ($ProjectDir) is not within ModsRoot ($ModsRootPath)"
    exit 1
}

$DestDir = Join-Path "$env:USERPROFILE\Documents\Timberborn\Mods" $RelativePath
$ParentDestDir = Split-Path $DestDir -Parent
$ParentProjectDir = Split-Path $ProjectDir -Parent

# --- NEW LOGIC: Copy workshop_data.json back to the source repository ---
$WorkshopDataSrc = Join-Path $ParentDestDir "workshop_data.json"
$WorkshopDataDest = Join-Path $ParentProjectDir "workshop_data.json"

if (Test-Path $WorkshopDataSrc) {
    Write-Host "PreBuild: Backing up workshop_data.json from $ParentDestDir to $ParentProjectDir"
    Copy-Item -Path $WorkshopDataSrc -Destination $WorkshopDataDest -Force
}
# ------------------------------------------------------------------------

Write-Host "PreBuild: Cleaning TargetDir ($TargetDir)"
if (Test-Path $TargetDir) {
    Get-ChildItem $TargetDir -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force
}

Write-Host "PreBuild: Cleaning DestDir ($DestDir)"
if (Test-Path $DestDir) {
    Get-ChildItem -Path $DestDir -Exclude 'workshop_data.json' -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force
}