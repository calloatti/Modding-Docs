# Edit these paths to point to your actual folders
$SourceFolder = "C:\Users\calloatti\Documents\Timberborn\Mods.Modding\DECOMPILED.CONSOLIDATED.DEFAULT"
$TargetFolder = "C:\Users\calloatti\source\repos\Modding Docs"

# Verify the source folder exists
if (-not (Test-Path -Path $SourceFolder)) {
    Write-Error "Source folder does not exist: $SourceFolder"
    exit
}

# Retrieve all Timberborn*.cs files from the source directory
$csFiles = Get-ChildItem -Path $SourceFolder -Filter "Timberborn*.cs" -File

foreach ($file in $csFiles) {
    # Extract the file name without the .cs extension
    $baseName = $file.BaseName

    # Strip the "Timberborn." prefix to isolate the module name
    $moduleName = $baseName -replace "^Timberborn\.", ""

    # Grab the first letter for categorization and capitalize it
    $firstLetter = $moduleName.Substring(0,1).ToUpper()

    # Construct the path for the alphabetical subfolder
    $letterFolder = Join-Path -Path $TargetFolder -ChildPath $firstLetter

    # Create the subfolder if it does not already exist
    if (-not (Test-Path -Path $letterFolder)) {
        New-Item -ItemType Directory -Path $letterFolder | Out-Null
    }

    # Construct the full path for the new markdown file
    $mdFilePath = Join-Path -Path $letterFolder -ChildPath "$baseName.md"

    # Create the empty markdown file if it doesn't exist
    if (-not (Test-Path -Path $mdFilePath)) {
        New-Item -ItemType File -Path $mdFilePath | Out-Null
        Write-Host "Created: $mdFilePath"
    } else {
        Write-Host "Skipped (already exists): $mdFilePath"
    }
}

Write-Host "Markdown generation complete."

pause