# Define the root game installation folder
$inputRoot    = "C:\Program Files (x86)\Steam\steamapps\common\timberborn_experimental"

# Dynamically infer the internal asset directories from the root
$inputFolder      = Join-Path $inputRoot "Timberborn_Data\Managed"
$moddingZipFolder = Join-Path $inputRoot "Timberborn_Data\StreamingAssets\Modding"

# Your output repository stays the same
$outputRoot       = "C:\Users\calloatti\source\repos\Mods\_decompiled.experimental"

# Empty output folder if it exists, or create it if it doesn't
if (Test-Path $outputRoot) {
    Remove-Item -Path "$outputRoot\*" -Recurse -Force -ErrorAction SilentlyContinue
} else {
    New-Item -Path $outputRoot -ItemType Directory | Out-Null
}

Write-Host "Starting per-DLL decompilation..." -ForegroundColor Cyan

# CHANGED: Added Where-Object to filter for Timberborn*.dll and Unity*.dll (case-insensitive)
Get-ChildItem "$inputFolder\*.dll" | Where-Object { $_.Name -like "Timberborn*.dll" -or $_.Name -like "Unity*.dll" } | ForEach-Object {
    $dll = $_.FullName
    $dllName = $_.BaseName

    Write-Host "   Decompiling $dllName.dll ..." -ForegroundColor Gray
    
    # Decompile into a single .cs file per DLL
    ilspycmd "$dll" -o "$outputRoot"

    # Remove the ".decompiled" text from the resulting file name
    $generatedFile = Join-Path $outputRoot "$dllName.decompiled.cs"
    if (Test-Path $generatedFile) {
        Rename-Item -Path $generatedFile -NewName "$dllName.cs" -Force
    }
}

# --- NEW: Unzip Modding files ---
if (Test-Path $moddingZipFolder) {
    Write-Host "Extracting modding zip files..." -ForegroundColor Cyan
    Get-ChildItem "$moddingZipFolder\*.zip" | ForEach-Object {
        $zipName = $_.BaseName
        $targetZipDestination = Join-Path $outputRoot $zipName
        
        Write-Host "   Extracting $($_.Name) to $zipName\ ..." -ForegroundColor Gray
        
        # Ensure the subfolder exists, then extract
        New-Item -Path $targetZipDestination -ItemType Directory -Force | Out-Null
        Expand-Archive -Path $_.FullName -DestinationPath $targetZipDestination -Force
    }
} else {
    Write-Warning "Modding zip folder not found at: $moddingZipFolder"
}
# ---------------------------------

Write-Host "All done!" -ForegroundColor Green
Write-Host "Each DLL and Zip now has its own file/folder inside:" -ForegroundColor Green
Write-Host "$outputRoot" -ForegroundColor White

# Generate index file
$IndexPath = Join-Path $outputRoot "_index.txt"
Get-ChildItem -Path $outputRoot -File | Select-Object -ExpandProperty Name | Set-Content -Path $IndexPath -Encoding UTF8

# FIX: Target path updated to use timberborn_experimental
Copy-Item -Path "C:\Program Files (x86)\Steam\steamapps\common\timberborn_experimental\Timberborn_Data\StreamingAssets\Version.txt" -Destination (Join-Path $outputRoot "_version.txt")

pause