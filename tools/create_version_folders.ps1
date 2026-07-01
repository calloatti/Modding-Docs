$folders = Get-ChildItem -Directory
foreach ($folder in $folders) {
    $manifestPath = Join-Path $folder.FullName "manifest.json"
    if (Test-Path $manifestPath) {
        try {
            $manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
            $minVersion = $manifest.MinimumGameVersion
            if ($null -ne $minVersion) {
                # Sanitize version string for folder name if necessary (though usually dots are fine)
                $newFolderName = "Version-$minVersion"
                $newFolderPath = Join-Path $folder.FullName $newFolderName
                if (-not (Test-Path $newFolderPath)) {
                    Write-Host "Creating folder: $newFolderPath in $($folder.Name)"
                    New-Item -ItemType Directory -Path $newFolderPath | Out-Null
                } else {
                    Write-Host "Folder already exists: $newFolderPath"
                }
            } else {
                Write-Host "No MinimumGameVersion found in $($folder.Name)/manifest.json"
            }
        } catch {
            Write-Warning "Failed to parse $manifestPath"
        }
    }
}
