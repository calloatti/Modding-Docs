# Get the directory where this script is located
$currentFolder = $PSScriptRoot

# Define the paths relative to the script location
$sourceDir = Join-Path $currentFolder ""
$templateFile = Join-Path $currentFolder "_generate.png.meta.json"

echo $sourceDir
echo $templateFile

# Check if the template file exists before proceeding
if (-not (Test-Path -Path $templateFile)) {
    Write-Error "Template file not found at $templateFile"
    exit
}

# Find all .png files recursively
$pngFiles = Get-ChildItem -Path $sourceDir -Filter "*.png" -Recurse

foreach ($file in $pngFiles) {
    # Construct the destination path (e.g., image.png.meta.json)
    $destinationPath = "$($file.FullName).meta.json"
    
    # Copy the template to the new destination
    # -Force ensures it overwrites if the meta file already exists
    Copy-Item -Path $templateFile -Destination $destinationPath -Force
    
    Write-Host "Generated meta file for: $($file.Name)" -ForegroundColor Cyan
}

Write-Host "Scan and generation complete." -ForegroundColor Green
pause