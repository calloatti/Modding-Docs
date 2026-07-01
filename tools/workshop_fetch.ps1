# ==============================================================================
# PowerShell Script: Extract Workshop Metadata (Description & Simple Tags List)
# Run this from the root directory that contains your individual mod folders.
# ==============================================================================

# Get all individual mod folders in the current directory
$modFolders = Get-ChildItem -Directory

foreach ($mod in $modFolders) {
    $jsonPath = Join-Path $mod.FullName "workshop_data.json"
    
    # Check if workshop_data.json exists for this specific mod
    if (Test-Path $jsonPath) {
        Write-Host "Processing mod: $($mod.Name)" -ForegroundColor Cyan
        
        # Define and create the target .meta directory if it doesn't exist
        $metaFolder = Join-Path $mod.FullName ".meta"
        if (-not (Test-Path $metaFolder)) {
            [void](New-Item -ItemType Directory -Path $metaFolder)
        }

        try {
            # Parse the local JSON file to extract the Steam ItemId
            $jsonData = Get-Content -Path $jsonPath -Raw | ConvertFrom-Json
            $itemId = $jsonData.ItemId

            if (-not $itemId) {
                Write-Host "  [!] No ItemId found in workshop_data.json for $($mod.Name)" -ForegroundColor Yellow
                continue
            }

            Write-Host "  -> Contacting Steam Web API for ID: $itemId" -ForegroundColor Gray

            # Query Steam's public Remote Storage endpoint to fetch published details
            $apiUrl = "https://api.steampowered.com/ISteamRemoteStorage/GetPublishedFileDetails/v1/"
            $body = @{
                "itemcount" = 1
                "publishedfileids[0]" = $itemId
            }

            $apiResponse = Invoke-RestMethod -Method Post -Uri $apiUrl -Body $body
            $fileDetails = $apiResponse.response.publishedfiledetails[0]

            # Result = 1 means the item was found successfully on the Steam servers
            if ($fileDetails.result -eq 1) {
                
                # 1. Save the official published item description text
                $description = $fileDetails.description
                $descriptionPath = Join-Path $metaFolder "workshop_description.txt"
                Set-Content -Path $descriptionPath -Value $description -Force
                Write-Host "  -> Saved description to .meta\workshop_description.txt" -ForegroundColor Green

                # 2. Extract and save a simple list of matching tags
                $tagsPath = Join-Path $metaFolder "workshop_tags.txt"
                
                if ($fileDetails.tags) {
                    # Extract active tags directly from the live Steam workshop page data
                    $tagsList = $fileDetails.tags | ForEach-Object { $_.tag }
                    Set-Content -Path $tagsPath -Value $tagsList -Force
                    Write-Host "  -> Saved simple list of online tags to .meta\workshop_tags.txt" -ForegroundColor Green
                } else {
                    # Fallback directly to the local JSON definitions if it isn't live on Steam yet
                    if ($jsonData.Tags) {
                        $tagsList = $jsonData.Tags
                        Set-Content -Path $tagsPath -Value $tagsList -Force
                        Write-Host "  -> No online tags found. Saved simple local fallback tags to .meta\workshop_tags.txt" -ForegroundColor Yellow
                    } else {
                        # Create an empty file if no tags exist anywhere to prevent script crashes
                        Clear-Content -Path $tagsPath -ErrorAction SilentlyContinue
                        Write-Host "  -> No tags found online or locally. Created empty file." -ForegroundColor DarkGray
                    }
                }
            } else {
                Write-Host "  [!] Steam API error code $($fileDetails.result) for ID $itemId. (Item may be private, unlisted, or deleted)" -ForegroundColor Red
            }

        } catch {
            Write-Host "  [!] Error processing metadata for $($mod.Name): $_" -ForegroundColor Red
        }
    }
}

Write-Host "`nMetadata processing complete!" -ForegroundColor Green
pause