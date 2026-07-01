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

# Define the source root folder
$ParentProjectDir = Split-Path $ProjectDir -Parent

Write-Host "PostBuild: Copying version-specific files from $TargetDir to $DestDir"
if (-not (Test-Path $DestDir)) {
    New-Item -ItemType Directory -Force -Path $DestDir | Out-Null
}

# Copy all files except thumbnail.jpg, thumbnail.png, and workshop_data.json to the version folder
Copy-Item -Path (Join-Path $TargetDir "*") -Destination $DestDir -Recurse -Force -Exclude "thumbnail.jpg","thumbnail.png","workshop_data.json"

# Copy thumbnail.jpg, thumbnail.png, and workshop_data.json from the SOURCE root mod directory to the DESTINATION root mod directory
$SpecialFiles = @("thumbnail.jpg", "thumbnail.png", "workshop_data.json")
foreach ($file in $SpecialFiles) {
    # CHANGED: Now looking in $ParentProjectDir instead of $TargetDir
    $srcFile = Join-Path $ParentProjectDir $file
    
    if (Test-Path $srcFile) {
        Write-Host "PostBuild: Copying $file from source root to destination root folder ($ParentDestDir)"
        if (-not (Test-Path $ParentDestDir)) {
            New-Item -ItemType Directory -Force -Path $ParentDestDir | Out-Null
        }
        Copy-Item -Path $srcFile -Destination $ParentDestDir -Force
    }
}