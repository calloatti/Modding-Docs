function Decompile-GameBranch {
    param (
        [string]$InputRoot,
        [string]$OutputRoot,
        [string]$BranchLabel
    )

    $inputFolder      = Join-Path $InputRoot "Timberborn_Data\Managed"
    $moddingZipFolder = Join-Path $InputRoot "Timberborn_Data\StreamingAssets\Modding"

    if (Test-Path $OutputRoot) {
        Remove-Item -Path "$OutputRoot\*" -Recurse -Force -ErrorAction SilentlyContinue
    } else {
        New-Item -Path $OutputRoot -ItemType Directory | Out-Null
    }

    Write-Host "Starting per-DLL decompilation for $BranchLabel..." -ForegroundColor Cyan

    Get-ChildItem "$inputFolder\*.dll" | Where-Object { $_.Name -like "Timberborn*.dll" -or $_.Name -like "Unity*.dll" } | ForEach-Object {
        $dll = $_.FullName
        $dllName = $_.BaseName

        Write-Host "   Decompiling $dllName.dll ..." -ForegroundColor Gray
        
        ilspycmd "$dll" -o "$OutputRoot"

        $generatedFile = Join-Path $OutputRoot "$dllName.decompiled.cs"
        if (Test-Path $generatedFile) {
            Rename-Item -Path $generatedFile -NewName "$dllName.cs" -Force
        }
    }

    if (Test-Path $moddingZipFolder) {
        Write-Host "Extracting modding zip files for $BranchLabel..." -ForegroundColor Cyan
        Get-ChildItem "$moddingZipFolder\*.zip" | ForEach-Object {
            $zipName = $_.BaseName
            $targetZipDestination = Join-Path $OutputRoot $zipName
            
            Write-Host "   Extracting $($_.Name) to $zipName\ ..." -ForegroundColor Gray
            
            New-Item -Path $targetZipDestination -ItemType Directory -Force | Out-Null
            Expand-Archive -Path $_.FullName -DestinationPath $targetZipDestination -Force
        }
    } else {
        Write-Warning "Modding zip folder not found at: $moddingZipFolder"
    }

    Write-Host "$BranchLabel complete!" -ForegroundColor Green
    Write-Host "Each DLL and Zip now has its own file/folder inside:" -ForegroundColor Green
    Write-Host "$OutputRoot" -ForegroundColor White

    $IndexPath = Join-Path $OutputRoot "_index.txt"
    Get-ChildItem -Path $OutputRoot -File | Select-Object -ExpandProperty Name | Set-Content -Path $IndexPath -Encoding UTF8

    $versionSrc = Join-Path $InputRoot "Timberborn_Data\StreamingAssets\Version.txt"
    if (Test-Path $versionSrc) {
        Copy-Item -Path $versionSrc -Destination (Join-Path $OutputRoot "_version.txt")
    }
}

Decompile-GameBranch `
    -InputRoot "C:\Program Files (x86)\Steam\steamapps\common\timberborn_main" `
    -OutputRoot "C:\Users\calloatti\source\repos\Mods\_decompiled.main" `
    -BranchLabel "Main Branch"

Write-Host "--------------------------------------------------" -ForegroundColor Gray

Decompile-GameBranch `
    -InputRoot "C:\Program Files (x86)\Steam\steamapps\common\timberborn_experimental" `
    -OutputRoot "C:\Users\calloatti\source\repos\Mods\_decompiled.experimental" `
    -BranchLabel "Experimental Branch"

pause