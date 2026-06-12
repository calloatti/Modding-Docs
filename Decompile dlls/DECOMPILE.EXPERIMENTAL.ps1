$inputFolder = "C:\Program Files (x86)\Steam\steamapps\common\Timberborn\Timberborn_Data\Managed"
$outputRoot  = "C:\Users\calloatti\Documents\Timberborn\Mods.Modding\DECOMPILED.EXPERIMENTAL.TEMP"

# Empty output folder if it exists, or create it if it doesn't
if (Test-Path $outputRoot) {
    Remove-Item -Path "$outputRoot\*" -Recurse -Force -ErrorAction SilentlyContinue
} else {
    New-Item -Path $outputRoot -ItemType Directory | Out-Null
}

Write-Host "🔄 Starting per-DLL decompilation..." -ForegroundColor Cyan

Get-ChildItem "$inputFolder\*.dll" | ForEach-Object {
    $dll = $_.FullName
    $dllName = $_.BaseName
    $outFolder = Join-Path $outputRoot $dllName

    Write-Host "   Decompiling $dllName.dll ..." -ForegroundColor Gray
    
    # Create project for this single DLL
    ilspycmd "$dll" -p -o "$outFolder"
}

Write-Host "`n✅ All done!" -ForegroundColor Green
Write-Host "Each DLL now has its own project folder inside:" -ForegroundColor Green
Write-Host "$outputRoot" -ForegroundColor White

pause