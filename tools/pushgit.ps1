# push-all-mods.ps1
# Place this in the root folder containing your mod repositories

param (
    [switch]$dry
)

if ($dry) {
    Write-Host "==================================================" -ForegroundColor Magenta
    Write-Host "DRY RUN MODE ENABLED - No changes will be pushed" -ForegroundColor Magenta
    Write-Host "==================================================" -ForegroundColor Magenta
}

# Get all subdirectories that contain a .git folder
$modFolders = Get-ChildItem -Directory | Where-Object { Test-Path (Join-Path $_.FullName ".git") }

foreach ($folder in $modFolders) {
    Write-Host "--------------------------------------------------" -ForegroundColor Cyan
    Write-Host "Processing Mod Repository: $($folder.Name)" -ForegroundColor Cyan
    Write-Host "--------------------------------------------------" -ForegroundColor Cyan
    
    Push-Location $folder.FullName

    # 1. Check if there are actual changes to commit
    $status = git status --porcelain
    if ([string]::IsNullOrEmpty($status)) {
        Write-Host "No changes detected in $($folder.Name). Skipping." -ForegroundColor Yellow
        Pop-Location
        continue
    }

    # 2. Stage all changes
    git add .

    # 3. Auto-generate the simplified commit description
    $commitMessage = "Update: Automated sync on $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
    $commitDescription = "Automated commit: Changes detected and synchronized via development script."

    Write-Host "Generated Commit Message:" -ForegroundColor Gray
    Write-Host "  Title: $commitMessage" -ForegroundColor DarkGray
    Write-Host "  Description: $commitDescription" -ForegroundColor DarkGray

    # 4. Commit and Push (Skipped if dry is specified)
    if ($dry) {
        Write-Host "[DRY RUN] Skipping actual git commit and git push." -ForegroundColor Magenta
        
        # Unstage changes back to normal so your workspace stays exactly how it was before the dry run
        git reset > $null
    } else {
        Write-Host "Committing changes..." -ForegroundColor Green
        git commit -m "$commitMessage" -m "$commitDescription"

        Write-Host "Pushing to GitHub..." -ForegroundColor Green
        $currentBranch = git branch --show-current
        git push origin $currentBranch
    }

    Pop-Location
}

Write-Host "`nAll repositories processed successfully!" -ForegroundColor Green