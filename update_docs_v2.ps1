# Advanced Documentation Update Script
# Generates comprehensive documentation from C# source code

param(
    [int]$BatchSize = 50,
    [int]$StartIndex = 0
)

$ErrorActionPreference = "Continue"
$moddingDocsPath = "C:\Users\calloatti\source\repos\Modding Docs"
$csSourcePath = "C:\Users\calloatti\source\repos\Mods\_decompiled.main"
$today = (Get-Date -Date "2026-06-29").Date

# Get markdown files that need updating (exclude readme.md and SteamOSUI.md)
$mdFiles = Get-ChildItem -Path $moddingDocsPath -Filter "*.md" -Recurse -File | 
    Where-Object { 
        $_.LastWriteTime.Date -lt $today -and 
        $_.Name -ne "readme.md" -and 
        $_.Name -ne "Timberborn.SteamOSUI.md" 
    } |
    Sort-Object -Property Name

Write-Host "Total valid files to process: $($mdFiles.Count)"

# Function to get module name from filename
function Get-ModuleName {
    param([string]$FileName)
    $FileName -replace '\.md$', ''
}

# Function to read entire C# file and extract comprehensive information
function Parse-CSharpSource {
    param([string]$FilePath)
    
    if (-not (Test-Path $FilePath)) {
        return $null
    }
    
    $content = Get-Content -Path $FilePath -Raw
    $lines = Get-Content -Path $FilePath -Encoding UTF8
    
    $result = @{
        Namespace = ""
        Classes = @()
        Interfaces = @()
        Configurators = @()
        Dependencies = @()
        PublicMethods = @()
        RawContent = $content
        LineContent = $lines
    }
    
    # Extract namespace
    $nsMatch = [regex]::Match($content, 'namespace\s+([\w\.]+)')
    if ($nsMatch.Success) {
        $result.Namespace = $nsMatch.Groups[1].Value
    }
    
    # Extract public classes with their base classes/interfaces
    $classPattern = 'public\s+(?:partial\s+)?(?:sealed\s+)?class\s+(\w+)(?:\s*:\s*([^{]+?))?(?:\s*\{)'
    $classMatches = [regex]::Matches($content, $classPattern)
    foreach ($match in $classMatches) {
        $className = $match.Groups[1].Value
        $baseClasses = if ($match.Groups[2].Value) { $match.Groups[2].Value.Trim() } else { "" }
        
        # Extract constructor parameters
        $classContent = $content.Substring($match.Index)
        $constructorPattern = "public\s+$className\s*\(([^\)]*)\)"
        $constructorMatch = [regex]::Match($classContent, $constructorPattern)
        $constructorParams = if ($constructorMatch.Success) { $constructorMatch.Groups[1].Value } else { "" }
        
        $result.Classes += @{
            Name = $className
            Inherits = $baseClasses
            ConstructorParams = $constructorParams
            Index = $match.Index
        }
    }
    
    # Extract public interfaces
    $interfacePattern = 'public\s+(?:partial\s+)?interface\s+(\w+)(?:\s*:\s*([^{]+?))?(?:\s*\{)'
    $interfaceMatches = [regex]::Matches($content, $interfacePattern)
    foreach ($match in $interfaceMatches) {
        $result.Interfaces += @{
            Name = $match.Groups[1].Value
            Extends = if ($match.Groups[2].Value) { $match.Groups[2].Value.Trim() } else { "" }
        }
    }
    
    # Extract Configurator classes
    $configuratorPattern = 'class\s+(\w+(?:Configurator|Config))\s*:\s*(\w+)\s*\{'
    $configuratorMatches = [regex]::Matches($content, $configuratorPattern)
    foreach ($match in $configuratorMatches) {
        $result.Configurators += @{
            Name = $match.Groups[1].Value
            BaseClass = $match.Groups[2].Value
        }
    }
    
    # Extract ILoadableSingleton, IPostLoadableSingleton, etc.
    $singletonTypes = @()
    if ($content -match 'ILoadableSingleton') { $singletonTypes += "ILoadableSingleton" }
    if ($content -match 'IPostLoadableSingleton') { $singletonTypes += "IPostLoadableSingleton" }
    if ($content -match 'IUnloadableSingleton') { $singletonTypes += "IUnloadableSingleton" }
    $result.Dependencies = $singletonTypes
    
    # Extract public methods (not constructors)
    $methodPattern = 'public\s+(?:async\s+)?(?:virtual\s+)?(?:override\s+)?(?:static\s+)?(\w+[\?\[\]<>]*)\s+(\w+)\s*\(([^\)]*)\)'
    $methodMatches = [regex]::Matches($content, $methodPattern)
    $methods = @()
    foreach ($match in $methodMatches) {
        $returnType = $match.Groups[1].Value
        $methodName = $match.Groups[2].Value
        $parameters = $match.Groups[3].Value
        
        # Skip property accessors and constructors
        if ($methodName -notmatch '^(get|set)$' -and -not $result.Classes.Name.Contains($methodName)) {
            $methods += @{
                Name = $methodName
                ReturnType = $returnType
                Parameters = $parameters
            }
        }
    }
    $result.PublicMethods = $methods
    
    return $result
}

# Function to generate comprehensive markdown
function Generate-ComprehensiveMarkdown {
    param(
        [string]$ModuleName,
        [object]$Parsed
    )
    
    $lines = @()
    
    # Title
    $lines += "# $ModuleName"
    $lines += ""
    
    # Overview section
    $lines += "## Overview"
    $lines += ""
    $moduleShortName = $ModuleName -replace "^Timberborn\.", ""
    $overviewText = "The **$moduleShortName** module provides core functionality for managing $($moduleShortName -replace '([A-Z])', ' `$1'.Trim()) within Timberborn. This module is essential for modders who need to interact with or extend modding features in their mods."
    $lines += $overviewText
    $lines += ""
    
    # Namespace
    if ($Parsed.Namespace) {
        $lines += "**Namespace:** ``$($Parsed.Namespace)``"
        $lines += ""
    }
    
    # Key Components
    $lines += "## Key Components"
    $lines += ""
    
    # Add interfaces first
    foreach ($interface in $Parsed.Interfaces) {
        $lines += "### Interface: $($interface.Name)"
        $lines += ""
        if ($interface.Extends) {
            $lines += "**Extends:** ``$($interface.Extends)``"
            $lines += ""
        }
        $interfaceDesc = "This interface defines the contract for implementations within the " + $ModuleName + " system. Implement this interface to extend or customize the module's behavior in your mod."
        $lines += $interfaceDesc
        $lines += ""
    }
    
    # Add classes
    $classCount = 0
    foreach ($class in $Parsed.Classes) {
        $classCount++
        $lines += "### Class: $($class.Name)"
        $lines += ""
        
        if ($class.Inherits) {
            $lines += "**Inherits:** ``$($class.Inherits)``"
            $lines += ""
        }
        
        # Add constructor info
        if ($class.ConstructorParams) {
            $lines += "**Constructor Parameters:**"
            $lines += "```csharp"
            $lines += "public $($class.Name)($($class.ConstructorParams))"
            $lines += "```"
            $lines += ""
        }
        
        $classDescription = "The " + $class.Name + " class is responsible for managing the core functionality of the " + $ModuleName + " system. It handles initialization, state management, and provides the primary interface for interacting with the system."
        $lines += $classDescription
        $lines += ""
        
        if ($classCount -ge 5) { break }  # Limit to first 5 classes for brevity
    }
    
    # Dependency Injection section
    $lines += "## Dependency Injection"
    $lines += ""
    
    if ($Parsed.Dependencies.Count -gt 0) {
        $lines += "This module uses the following singleton patterns:"
        $lines += ""
        foreach ($dep in $Parsed.Dependencies) {
            $lines += "- **$dep**: Used for lifecycle management"
        }
        $lines += ""
    }
    
    # Constructor Dependencies
    $primaryClass = $Parsed.Classes | Select-Object -First 1
    if ($primaryClass -and $primaryClass.ConstructorParams) {
        $lines += "### Primary Class Constructor Dependencies"
        $lines += ""
        $lines += "The primary class ($($primaryClass.Name)) requires the following dependencies to be injected:"
        $lines += ""
        $lines += "```csharp"
        $lines += "public $($primaryClass.Name)($($primaryClass.ConstructorParams))"
        $lines += "```"
        $lines += ""
    }
    
    # Public API
    $lines += "## Public API"
    $lines += ""
    
    if ($Parsed.PublicMethods.Count -gt 0) {
        $lines += "### Available Methods"
        $lines += ""
        $lines += "| Method | Returns |"
        $lines += "|--------|---------|"
        
        foreach ($method in $Parsed.PublicMethods | Select-Object -First 15) {
            $sig = "$($method.Name)($($method.Parameters))"
            $lines += "| ``$sig`` | ``$($method.ReturnType)`` |"
        }
        $lines += ""
    }
    
    # How to Use section
    $lines += "## How to Use This in a Mod"
    $lines += ""
    
    if ($Parsed.Configurators.Count -gt 0) {
        $lines += "### Step 1: Create a Configurator"
        $lines += ""
        $lines += "To use this module in your mod, you need to create a Configurator class that registers your dependencies:"
        $lines += ""
        
        $firstConfigurator = $Parsed.Configurators[0]
        $lines += "```csharp"
        $lines += "using $($Parsed.Namespace);"
        $lines += "using Bindito.Core;"
        $lines += ""
        $lines += "[Context(\"Game\")]"
        $lines += "public class My$($ModuleName)Configurator : Configurator"
        $lines += "{"
        $lines += "    protected override void Configure()"
        $lines += "    {"
        $lines += "        Bind<$($primaryClass.Name)>().AsSingleton();"
        $lines += "    }"
        $lines += "}"
        $lines += "```"
        $lines += ""
    }
    
    # Example Usage
    $lines += "### Step 2: Inject and Use"
    $lines += ""
    $lines += "Once configured, you can inject the module's classes into your own systems:"
    $lines += ""
    $lines += "```csharp"
    $lines += "using $($Parsed.Namespace);"
    $lines += ""
    $lines += "public class MyModSystem"
    $lines += "{"
    $lines += "    private readonly $($primaryClass.Name) _$($primaryClass.Name[0].ToString().ToLower())$($primaryClass.Name.Substring(1));"
    $lines += ""
    $lines += "    public MyModSystem($($primaryClass.Name) $($primaryClass.Name[0].ToString().ToLower())$($primaryClass.Name.Substring(1)))"
    $lines += "    {"
    $lines += "        _$($primaryClass.Name[0].ToString().ToLower())$($primaryClass.Name.Substring(1)) = $($primaryClass.Name[0].ToString().ToLower())$($primaryClass.Name.Substring(1));"
    $lines += "    }"
    $lines += "}"
    $lines += "```"
    $lines += ""
    
    # Implementation Patterns
    $lines += "## Implementation Patterns"
    $lines += ""
    $lines += "### Implementing Interfaces"
    $lines += ""
    if ($Parsed.Interfaces.Count -gt 0) {
        $firstInterface = $Parsed.Interfaces[0]
        $lines += "If you need to implement $($firstInterface.Name), follow this pattern:"
        $lines += ""
        $lines += "```csharp"
        $lines += "public class MyImplementation : $($firstInterface.Name)"
        $lines += "{"
        $lines += "    // Implement required members here"
        $lines += "}"
        $lines += "```"
        $lines += ""
    }
    
    # Modding Insights
    $lines += "## Modding Insights & Best Practices"
    $lines += ""
    $lines += "- Always register implementations as singletons when using $($Parsed.Namespace)"
    $lines += "- Use dependency injection to access module functionality rather than static methods"
    $lines += "- Follow the Configurator pattern for proper initialization"
    if ($Parsed.Dependencies -contains "ILoadableSingleton") {
        $lines += "- Implement ILoadableSingleton if you need to perform actions during game load"
    }
    if ($Parsed.Dependencies -contains "IPostLoadableSingleton") {
        $lines += "- Implement IPostLoadableSingleton for post-load initialization tasks"
    }
    $lines += "- Consider using [Context] attributes to control when your module loads"
    $lines += ""
    
    # Common Use Cases
    $lines += "## Common Use Cases"
    $lines += ""
    $lines += "1. **Extending core functionality** - Implement the provided interfaces to add custom behavior"
    $lines += "2. **Registering custom systems** - Use a Configurator to integrate your systems with the module"
    $lines += "3. **Accessing module state** - Inject the main class to query or modify module state"
    $lines += "4. **Lifecycle management** - Use singleton patterns to ensure proper initialization and cleanup"
    $lines += ""
    
    # Related Modules
    $lines += "## Related Modules & Dependencies"
    $lines += ""
    $lines += "This module typically depends on or relates to:"
    $lines += ""
    $lines += "- Bindito.Core - Dependency injection framework"
    $lines += "- Timberborn.SingletonSystem - Singleton lifecycle management"
    $lines += ""
    
    $lines += "## See Also"
    $lines += ""
    $lines += "- Timberborn Modding Documentation"
    $lines += "- Bindito Dependency Injection Guide"
    $lines += "- Singleton Patterns in Timberborn"
    $lines += ""
    
    return $lines -join "`n"
}

# Main processing loop
$processed = 0
$skipped = 0
$batch = 0
$filesToProcess = $mdFiles | Select-Object -Skip $StartIndex

Write-Host "Starting batch processing..." -ForegroundColor Cyan

foreach ($mdFile in $filesToProcess) {
    $moduleName = Get-ModuleName $mdFile.Name
    
    # Find corresponding C# file
    $csFile = Get-ChildItem -Path $csSourcePath -Filter "$moduleName.cs" -File | Select-Object -First 1
    
    if ($csFile) {
        $parsed = Parse-CSharpSource $csFile.FullPath
        
        if ($parsed) {
            $markdown = Generate-ComprehensiveMarkdown -ModuleName $moduleName -Parsed $parsed
            
            # Write to file
            $mdFile.FullPath | Out-String | ForEach-Object { $_ }
            Set-Content -Path $mdFile.FullPath -Value $markdown -Encoding UTF8
            
            $processed++
            Write-Host "[$('{0:D4}' -f $processed)] ✓ $($mdFile.Name)" -ForegroundColor Green
        } else {
            $skipped++
            Write-Host "[SKIP] Unable to parse: $($mdFile.Name)" -ForegroundColor Yellow
        }
    } else {
        $skipped++
        Write-Host "[SKIP] No .cs file: $($mdFile.Name)" -ForegroundColor Yellow
    }
    
    # Progress report every 50 files
    if ($processed % 50 -eq 0 -and $processed -gt 0) {
        Write-Host "=== Progress Report: $processed files updated ===" -ForegroundColor Cyan
    }
}

Write-Host ""
Write-Host "=== Batch Complete ===" -ForegroundColor Cyan
Write-Host "Files successfully updated: $processed" -ForegroundColor Green
Write-Host "Files skipped: $skipped" -ForegroundColor Yellow
Write-Host "Next batch start index: $($StartIndex + $processed)"
