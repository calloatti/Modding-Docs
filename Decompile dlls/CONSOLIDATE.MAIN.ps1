# CONFIGURATION
$SourcePath = Join-Path (Get-Location) "DECOMPILED.MAIN.TEMP"
$OutputDirectory = Join-Path (Get-Location) "DECOMPILED.MAIN"
$FileExtension = "*.cs"

# 1. Create Output Directory
if (-not (Test-Path $OutputDirectory)) {
    New-Item -ItemType Directory -Path $OutputDirectory | Out-Null
}

# Verify SourcePath exists before proceeding
if (-not (Test-Path $SourcePath)) {
    Write-Host "The source folder 'DECOMPILED' does not exist in the current directory." -ForegroundColor Red
    exit
}

# 2. Get Top-Level Folders Only
# We no longer need -Exclude since the output folder is outside the DECOMPILED folder
$topLevelFolders = Get-ChildItem -Path $SourcePath -Directory

Write-Host "Found $( $topLevelFolders.Count ) top-level folders in DECOMPILED." -ForegroundColor Cyan

foreach ($folder in $topLevelFolders) {
    $folderName = $folder.Name
    $outputFile = Join-Path $OutputDirectory "$folderName.cs"
    
    # Get all .cs files inside this specific folder (Recursive)
    $filesInFolder = Get-ChildItem -Path $folder.FullName -Recurse -Filter $FileExtension -File
    
    if ($filesInFolder.Count -eq 0) {
        Write-Host "Skipping '$folderName' (No .cs files found)." -ForegroundColor DarkGray
        continue
    }

    Write-Host "Processing '$folderName' ($($filesInFolder.Count) files)..." -ForegroundColor Green

    # 3. Use StreamWriter for Speed
    $writer = [System.IO.StreamWriter]::new($outputFile, $false, [System.Text.Encoding]::UTF8)

    # Add a main header for the consolidated file
    $writer.WriteLine("// ==============================================================================")
    $writer.WriteLine("// MODULE: $folderName")
    $writer.WriteLine("// FILE COUNT: $($filesInFolder.Count)")
    $writer.WriteLine("// ==============================================================================")
    $writer.WriteLine("")

    foreach ($file in $filesInFolder) {
        # Get path relative to the specific folder
        $relativePath = $file.FullName.Substring($folder.FullName.Length + 1)

        # Write Header
        $writer.WriteLine("// ------------------------------------------------------------------------------")
        $writer.WriteLine("// SOURCE: $folderName\$relativePath")
        $writer.WriteLine("// ------------------------------------------------------------------------------")
        
        # Write Content
        try {
            $content = [System.IO.File]::ReadAllText($file.FullName)
            $writer.WriteLine($content)
            $writer.WriteLine("") # Spacing
        }
        catch {
            $writer.WriteLine("// ERROR: Could not read file.")
        }
    }

    $writer.Flush()
    $writer.Close()
    $writer.Dispose()
}

Write-Host "Done! Consolidated files are in the 'DECOMPILED.CONSOLIDATED' folder." -ForegroundColor Yellow

# ------------------------------------------------------------------------------
# NEW CODE ADDED AT THE BOTTOM
# ------------------------------------------------------------------------------
$IndexPath = Join-Path $OutputDirectory "_index.txt"
Get-ChildItem -Path $OutputDirectory -File | Select-Object -ExpandProperty Name | Set-Content -Path $IndexPath -Encoding UTF8

Copy-Item -Path "C:\Program Files (x86)\Steam\steamapps\common\Timberborn\Timberborn_Data\StreamingAssets\Version.txt" -Destination "C:\Users\calloatti\Documents\Timberborn\Mods.Modding\DECOMPILED.MAIN\_Version.txt"

# ------------------------------------------------------------------------------
# CONSOLIDATE ALL Timberborn.*.cs INTO Timberborn.cs
# ------------------------------------------------------------------------------
$TimberbornConsolidatedFile = Join-Path $OutputDirectory "Timberborn.cs"
$TimberbornFiles = Get-ChildItem -Path $OutputDirectory -Filter "Timberborn.*.cs" -File

if ($TimberbornFiles.Count -gt 0) {
    Write-Host "Consolidating $($TimberbornFiles.Count) Timberborn files into Timberborn.cs..." -ForegroundColor Green
    
    $tbWriter = [System.IO.StreamWriter]::new($TimberbornConsolidatedFile, $false, [System.Text.Encoding]::UTF8)

    foreach ($tbFile in $TimberbornFiles) {
        try {
            $tbContent = [System.IO.File]::ReadAllText($tbFile.FullName)
            $tbWriter.Write($tbContent)
        }
        catch { }
    }

    $tbWriter.Flush()
    $tbWriter.Close()
    $tbWriter.Dispose()
    
    Write-Host "Consolidated Timberborn.cs successfully created." -ForegroundColor Yellow
}

pause