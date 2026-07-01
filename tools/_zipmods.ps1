# Define the path to your Timberborn Mods folder
$modsPath = "C:\Users\calloatti\Documents\Timberborn\Mods"
$zipsPath = "C:\Users\calloatti\source\repos\ModZips"

# Load required .NET assemblies
Add-Type -AssemblyName System.Text.Encoding
Add-Type -AssemblyName System.IO.Compression.FileSystem

# Define the custom encoder to force forward slashes for Linux compatibility
class FixedEncoder : System.Text.UTF8Encoding {
    FixedEncoder() : base($true) { }

    [byte[]] GetBytes([string] $s)
    {
        $s = $s.Replace("\", "/")
        return ([System.Text.UTF8Encoding]$this).GetBytes($s)
    }
}

# Check if the Mods directory exists
if (-not (Test-Path -Path $modsPath)) {
    Write-Host "Mods directory not found: $modsPath" -ForegroundColor Red
    exit
}

# Get all subdirectories (mod folders) in the Mods folder
$modFolders = Get-ChildItem -Path $modsPath -Directory

foreach ($folder in $modFolders) {
    # Find all manifest.json files within the mod folder recursively
    $allManifests = Get-ChildItem -Path $folder.FullName -Filter "manifest.json" -Recurse

    if ($allManifests) {
        try {
            $highestVersion = $null
            $highestParsedVersion = $null

            # Read and parse all found JSON files to extract the highest version
            foreach ($manifest in $allManifests) {
                $manifestData = Get-Content -Path $manifest.FullName -Raw | ConvertFrom-Json
                $versionString = $manifestData.Version

                if (-not [string]::IsNullOrWhiteSpace($versionString)) {
                    $parsedVersion = $null
                    # Parses as [System.Version] to ensure Version-1.10 is higher than Version-1.2
                    if ([System.Version]::TryParse($versionString, [ref]$parsedVersion)) {
                        if ($null -eq $highestParsedVersion -or $parsedVersion -gt $highestParsedVersion) {
                            $highestParsedVersion = $parsedVersion
                            $highestVersion = $versionString
                        }
                    } else {
                        # Fallback to string sort if it has letters (e.g., 1.0-beta)
                        if ($null -eq $highestVersion -or $versionString -gt $highestVersion) {
                            $highestVersion = $versionString
                        }
                    }
                }
            }

            $version = $highestVersion

            if (-not [string]::IsNullOrWhiteSpace($version)) {
                # Format the zip file name: foldername_version.zip
                $zipFileName = "{0}_{1}.zip" -f $folder.Name, $version
                $zipDestination = Join-Path -Path $zipsPath -ChildPath $zipFileName

                Write-Host "Zipping '$($folder.Name)' (Version: $version)..." -ForegroundColor Cyan

                # Delete the existing zip to ensure a completely fresh archive
                if (Test-Path -Path $zipDestination) {
                    Remove-Item -Path $zipDestination -Force
                }

                # Create the zip archive using the custom FixedEncoder
                # Note: Currently zipping the root mod folder ($folder.FullName). 
                # Change this to $highestVersionFolder.FullName if you only want the version folder zipped.
                [System.IO.Compression.ZipFile]::CreateFromDirectory($folder.FullName, $zipDestination, [System.IO.Compression.CompressionLevel]::Optimal, $true, [FixedEncoder]::new())

                Write-Host "Successfully created: $zipFileName" -ForegroundColor Green
            } else {
                Write-Host "Version property not found or empty in any manifest.json. Skipping." -ForegroundColor Yellow
            }
        } catch {
            Write-Host "Error parsing JSON or zipping folder for $($folder.Name): $_" -ForegroundColor Red
        }
    } else {
        Write-Host "No manifest.json found for $($folder.Name). Skipping." -ForegroundColor DarkGray
    }
}

Write-Host "Done!" -ForegroundColor Green
Pause