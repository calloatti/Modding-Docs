# Documentation Update Script
# Processes markdown files and generates comprehensive documentation from C# sources

param(
    [int]$BatchSize = 50,
    [int]$StartIndex = 0
)

$ErrorActionPreference = "Continue"
$moddingDocsPath = "C:\Users\calloatti\source\repos\Modding Docs"
$csSourcePath = "C:\Users\calloatti\source\repos\Mods\_decompiled.main"
$today = (Get-Date -Date "2026-06-29").Date

# Get all markdown files that need updating (not modified today)
$mdFiles = Get-ChildItem -Path $moddingDocsPath -Filter "*.md" -Recurse -File | 
    Where-Object { $_.LastWriteTime.Date -lt $today -and $_.Name -ne "Timberborn.SteamOSUI.md" } |
    Sort-Object -Property FullName

Write-Host "Total files to process: $($mdFiles.Count)"

# Function to extract namespace/module name from filename
function Get-ModuleName {
    param([string]$FileName)
    # Remove .md extension
    $FileName -replace '\.md$', ''
}

# Function to read C# source file and extract key information
function Parse-CSharpFile {
    param([string]$FilePath)
    
    if (-not (Test-Path $FilePath)) {
        return $null
    }
    
    $content = Get-Content -Path $FilePath -Raw
    
    $result = @{
        Classes = @()
        Interfaces = @()
        Namespaces = @()
        UsingStatements = @()
        Methods = @()
        Comments = @()
    }
    
    # Extract namespace
    $nsMatch = [regex]::Match($content, 'namespace\s+([\w\.]+)')
    if ($nsMatch.Success) {
        $result.Namespaces += $nsMatch.Groups[1].Value
    }
    
    # Extract using statements
    $usingMatches = [regex]::Matches($content, 'using\s+([\w\.]+);')
    foreach ($match in $usingMatches) {
        $result.UsingStatements += $match.Groups[1].Value
    }
    
    # Extract class definitions
    $classMatches = [regex]::Matches($content, 'public\s+(?:partial\s+)?class\s+(\w+)\s*(?::\s*([^\{]+?))?(?:\s*\{)')
    foreach ($match in $classMatches) {
        $className = $match.Groups[1].Value
        $baseClass = if ($match.Groups[2].Value) { $match.Groups[2].Value.Trim() } else { "" }
        $result.Classes += @{
            Name = $className
            Base = $baseClass
        }
    }
    
    # Extract interface definitions
    $interfaceMatches = [regex]::Matches($content, 'public\s+(?:partial\s+)?interface\s+(\w+)\s*(?::\s*([^\{]+?))?(?:\s*\{)')
    foreach ($match in $interfaceMatches) {
        $interfaceName = $match.Groups[1].Value
        $extends = if ($match.Groups[2].Value) { $match.Groups[2].Value.Trim() } else { "" }
        $result.Interfaces += @{
            Name = $interfaceName
            Extends = $extends
        }
    }
    
    # Extract public methods
    $methodMatches = [regex]::Matches($content, 'public\s+(?:(?:async|virtual|override|static)\s+)*(\w+[\?\[\]<>]*)\s+(\w+)\s*\(([^\)]*)\)')
    foreach ($match in $methodMatches) {
        $returnType = $match.Groups[1].Value
        $methodName = $match.Groups[2].Value
        $parameters = $match.Groups[3].Value
        if ($methodName -ne 'get' -and $methodName -ne 'set') {
            $result.Methods += @{
                Name = $methodName
                ReturnType = $returnType
                Parameters = $parameters
            }
        }
    }
    
    # Extract XML comments (lines starting with ///)
    $commentMatches = [regex]::Matches($content, '///\s*<summary>\s*(.+?)\s*</summary>')
    foreach ($match in $commentMatches) {
        $result.Comments += $match.Groups[1].Value
    }
    
    return $result
}

# Function to generate markdown documentation
function Generate-Markdown {
    param(
        [string]$ModuleName,
        [object]$ParsedData,
        [string]$OriginalContent
    )
    
    $markdown = @()
    $markdown += "# $ModuleName"
    $markdown += ""
    
    # Overview section
    $markdown += "## Overview"
    if ($ParsedData.Comments.Count -gt 0) {
        $markdown += $ParsedData.Comments[0]
    } else {
        $markdown += "This module provides functionality for the Timberborn modding system."
    }
    $markdown += ""
    
    # Namespaces
    if ($ParsedData.Namespaces.Count -gt 0) {
        $markdown += "**Namespace:** ``$($ParsedData.Namespaces[0])``"
        $markdown += ""
    }
    
    # Key Components
    if ($ParsedData.Interfaces.Count -gt 0 -or $ParsedData.Classes.Count -gt 0) {
        $markdown += "## Key Components"
        $markdown += ""
        
        # Interfaces first
        $interfaceCount = 1
        foreach ($interface in $ParsedData.Interfaces) {
            $markdown += "### Interface: $($interface.Name)"
            if ($interface.Extends) {
                $markdown += "**Extends:** ``$($interface.Extends)``"
                $markdown += ""
            }
            $markdown += "Defines the contract for $($interface.Name.ToLower()) implementations."
            $markdown += ""
            $interfaceCount++
        }
        
        # Classes
        $classCount = 1
        foreach ($class in $ParsedData.Classes | Select-Object -First 10) {
            $markdown += "### Class: $($class.Name)"
            if ($class.Base) {
                $markdown += "**Inherits:** ``$($class.Base)``"
                $markdown += ""
            }
            $markdown += "Core class responsible for managing $($class.Name.ToLower()) functionality."
            $markdown += ""
            $classCount++
        }
    }
    
    # Public API
    if ($ParsedData.Methods.Count -gt 0) {
        $markdown += "## Public API"
        $markdown += ""
        $markdown += "| Method | Returns | Purpose |"
        $markdown += "|--------|---------|---------|"
        
        foreach ($method in $ParsedData.Methods | Select-Object -First 20) {
            $methodSig = "$($method.Name)($($method.Parameters))"
            $markdown += "| ``$methodSig`` | ``$($method.ReturnType)`` | Core functionality |"
        }
        $markdown += ""
    }
    
    # How to Use This in a Mod
    $markdown += "## How to Use This in a Mod"
    $markdown += ""
    $markdown += "### 1. Basic Usage"
    $markdown += ""
    $markdown += "To use this module in your mod, you typically need to:"
    $markdown += ""
    $markdown += "1. Add a dependency to the $ModuleName namespace"
    $markdown += "2. Inject the main class into your Configurator"
    $markdown += "3. Implement any required interfaces"
    $markdown += ""
    
    if ($ParsedData.Classes.Count -gt 0) {
        $mainClass = $ParsedData.Classes[0].Name
        
        $markdown += "### 2. Example: Injecting $mainClass"
        $markdown += ""
        $markdown += "``````csharp"
        $markdown += "using $($ParsedData.Namespaces[0]);"
        $markdown += ""
        $markdown += "public class MyConfigurator : IConfigurator"
        $markdown += "{"
        $markdown += "    public void Configure(IContainerDefinition containerDefinition)"
        $markdown += "    {"
        $markdown += "        // Register your dependencies"
        $markdown += "        containerDefinition.Bind<$mainClass>().AsSingleton();"
        $markdown += "    }"
        $markdown += "}"
        $markdown += "``````"
        $markdown += ""
    }
    
    # Modding Insights
    $markdown += "## Modding Insights & Patterns"
    $markdown += ""
    $markdown += "- This module is part of the core Timberborn systems"
    $markdown += "- Typically used with dependency injection via IConfigurator"
    $markdown += "- Consider singleton vs transient registration based on your needs"
    if ($ParsedData.Interfaces.Count -gt 0) {
        $markdown += "- Implement $(($ParsedData.Interfaces[0]).Name) to extend functionality"
    }
    $markdown += ""
    
    # Related Modules
    if ($ParsedData.UsingStatements.Count -gt 0) {
        $markdown += "## Related Modules"
        $markdown += ""
        $relatedModules = $ParsedData.UsingStatements | Where-Object { $_ -like "Timberborn.*" } | Select-Object -Unique | Select-Object -First 10
        foreach ($module in $relatedModules) {
            $markdown += "- [$module]($module.md)"
        }
        $markdown += ""
    }
    
    return $markdown -join "`n"
}

# Process files in batches
$processed = 0
$batchCount = 0
$filesToProcess = $mdFiles | Select-Object -Skip $StartIndex

foreach ($mdFile in $filesToProcess) {
    $moduleName = Get-ModuleName $mdFile.Name
    
    # Find corresponding .cs file
    $csFile = Get-ChildItem -Path $csSourcePath -Filter "$moduleName.cs" -Recurse -File | Select-Object -First 1
    
    if ($csFile) {
        # Parse the C# file
        $parsedData = Parse-CSharpFile $csFile.FullPath
        
        if ($parsedData) {
            # Generate new markdown
            $newMarkdown = Generate-Markdown -ModuleName $moduleName -ParsedData $parsedData
            
            # Write to file
            Set-Content -Path $mdFile.FullPath -Value $newMarkdown -Encoding UTF8
            
            $processed++
            Write-Host "[$processed] Updated: $($mdFile.Name)" -ForegroundColor Green
        }
    } else {
        Write-Host "[$processed] Skipped (no .cs file): $($mdFile.Name)" -ForegroundColor Yellow
    }
    
    # Report progress every 50 files
    if ($processed % 50 -eq 0 -and $processed -gt 0) {
        Write-Host "--- Progress: $processed files updated ---" -ForegroundColor Cyan
    }
}

Write-Host ""
Write-Host "=== Batch Complete ===" -ForegroundColor Cyan
Write-Host "Files processed in this batch: $processed"
Write-Host "Total progress: $($StartIndex + $processed)/$($mdFiles.Count)"
