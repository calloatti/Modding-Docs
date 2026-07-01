# ==============================================================================
# PowerShell Script: Fetch & Group All Available Master Workshop Tags
# ==============================================================================

# Target game App ID (1062090 is Timberborn)
$AppID = "1062090" 
$Url = "https://steamcommunity.com/app/$AppID/workshop/"

Write-Host "Fetching and categorizing master sidebar tags from the Steam Workshop for App ID: $AppID..." -ForegroundColor Cyan

try {
    # Request the full workshop landing page HTML string live
    $html = Invoke-RestMethod -Uri $Url -Method Get -UserAgent "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"

    # Extract Steam's modern SSR raw JSON array block safely
    if ($html -match 'window\.SSR\.loaderData\s*=\s*(\[[\s\S]*?\]);') {
        $rawArrayStr = $Matches[1]
        
        # Decode the outer wrapper string array
        $stringifiedObjects = ConvertFrom-Json $rawArrayStr
        
        $fileContent = @()
        $foundTags = $false

        # Loop through the decoded blocks to locate Valve's active tag index mapping
        foreach ($jsonStr in $stringifiedObjects) {
            if ($jsonStr -match '"declaredTags"') {
                # Decode the inner payload object natively
                $payloadObj = ConvertFrom-Json $jsonStr
                $tagCategories = $payloadObj.declaredTags.mtx_tags
                
                foreach ($category in $tagCategories) {
                    $categoryName = $category.name ? $category.name.Trim() : "Base Types"
                    $tagsList = @()

                    foreach ($tag in $category.tags) {
                        if ($tag.display_name) {
                            $tagsList += $tag.display_name.Trim()
                        }
                    }

                    # If this structural category contains valid tags, sort and display them
                    if ($tagsList.Count -gt 0) {
                        $foundTags = $true
                        $tagsList = $tagsList | Sort-Object

                        # Record section headers and items to the output buffer
                        $fileContent += "# $categoryName"
                        Write-Host "`n# $categoryName" -ForegroundColor Yellow

                        foreach ($tag in $tagsList) {
                            $fileContent += "$tag"
                            Write-Host "  - $tag" -ForegroundColor White
                        }
                    }
                }
                break # target found, exit loop safely
            }
        }

        if ($foundTags) {
            # Determine output path relative to script location
            $outputPath = "workshop_tags_master.txt"
            if ($PSScriptRoot) { 
                $outputPath = Join-Path $PSScriptRoot "workshop_tags_master.txt" 
            }

            # Commit grouped map to disk
            Set-Content -Path $outputPath -Value $fileContent -Force
            
            Write-Host "`n--------------------------------------------------------" -ForegroundColor Gray
            Write-Host "[+] Grouped tag schema compiled successfully to: $outputPath" -ForegroundColor Green
        } else {
            Write-Host "[!] Unable to locate the 'declaredTags' data block inside Steam's page payload." -ForegroundColor Red
        }

    } else {
        Write-Host "[!] Could not find the 'window.SSR.loaderData' variable footprint on the page." -ForegroundColor Red
    }

} catch {
    Write-Host "An error occurred while connecting to Steam: $_" -ForegroundColor Red
}

pause