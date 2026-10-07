param(
    [string]$ConfigPath = "",
    [string]$OutputPath = "",
    [string]$ActiveDir = "",
    [string]$DisabledDir = ""
)

$bullet = [char]0x2022

Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host "                ANTIGRAVITY SKILLS SUMMARY AUTO-GENERATOR" -ForegroundColor Cyan
Write-Host "==============================================================================" -ForegroundColor Cyan

if (-not $ConfigPath) {
    $ConfigPath = Join-Path $PSScriptRoot "skills_config.cfg"
}
if (-not $OutputPath) {
    $OutputPath = Join-Path $PSScriptRoot "SKILLS_SUMMARY.txt"
}

# 1. Resolve Directories
if (-not $ActiveDir -or -not $DisabledDir) {
    if (Test-Path -LiteralPath $ConfigPath) {
        Get-Content -LiteralPath $ConfigPath | ForEach-Object {
            $line = $_.Trim()
            if ($line -match 'ACTIVE_DIR=([^"]+)') { $ActiveDir = $matches[1].Trim('"') }
            if ($line -match 'DISABLED_DIR=([^"]+)') { $DisabledDir = $matches[1].Trim('"') }
        }
    }
}

# Fallbacks if config is missing or directories not specified
if (-not $ActiveDir -or -not (Test-Path -LiteralPath $ActiveDir)) {
    $candActive1 = Join-Path $PSScriptRoot "..\.agents\skills"
    $candActive2 = Join-Path $PSScriptRoot ".agents\skills"
    $candActive3 = Join-Path $env:USERPROFILE ".agents\skills"
    if (Test-Path -LiteralPath $candActive1) {
        $ActiveDir = (Resolve-Path $candActive1).Path
    } elseif (Test-Path -LiteralPath $candActive2) {
        $ActiveDir = (Resolve-Path $candActive2).Path
    } elseif (Test-Path -LiteralPath $candActive3) {
        $ActiveDir = (Resolve-Path $candActive3).Path
    }
}

if (-not $DisabledDir -or -not (Test-Path -LiteralPath $DisabledDir)) {
    $candDis1 = Join-Path $PSScriptRoot "skills_archive"
    $candDis2 = Join-Path $PSScriptRoot "skills"
    $candDis3 = Join-Path $PSScriptRoot "..\skills"
    if (Test-Path -LiteralPath $candDis1) {
        $DisabledDir = (Resolve-Path $candDis1).Path
    } elseif (Test-Path -LiteralPath $candDis2) {
        $DisabledDir = (Resolve-Path $candDis2).Path
    } elseif (Test-Path -LiteralPath $candDis3) {
        $DisabledDir = (Resolve-Path $candDis3).Path
    } else {
        $DisabledDir = $PSScriptRoot
    }
}

Write-Host "  Active Skills Folder  : $ActiveDir" -ForegroundColor Gray
Write-Host "  Archived Folder       : $DisabledDir" -ForegroundColor Gray
Write-Host "  Output Summary File   : $OutputPath" -ForegroundColor Gray
Write-Host "------------------------------------------------------------------------------" -ForegroundColor Gray

# Known taxonomies
$coreSkillsList = @('web-designer', 'superpowers', 'playwright-cli', 'context-engineering', 'massgen')
$webSubSkillsList = @('unique-webapp-design-patterns', 'threejs', 'human-centric-web-design', 'taste-skill', 'awesome-design-md', 'theme-factory', 'image-to-code', 'web-artifacts-builder', 'web-design-guidelines', 'canvas-design')

function Get-SkillOneLiner($skillMdPath) {
    if (-not (Test-Path -LiteralPath $skillMdPath)) { return "No SKILL.md file found." }
    $raw = [System.IO.File]::ReadAllText($skillMdPath, [System.Text.Encoding]::UTF8)
    
    # Try YAML frontmatter
    $desc = ""
    if ($raw -match '(?ms)^---\s*\r?\n(.*?)\r?\n---') {
        $fm = $matches[1]
        if ($fm -match '(?ms)^description:\s*(.*?)(?=\r?\n[a-zA-Z0-9_-]+:|\Z)') {
            $rawDesc = $matches[1].Trim()
            $rawDesc = $rawDesc.TrimStart('|', '>', '"', "'", ' ')
            $rawDesc = $rawDesc.TrimEnd('"', "'", ' ')
            
            $lines = $rawDesc -split '\r?\n' | ForEach-Object {
                $l = $_.Trim()
                if ($l.StartsWith("- ") -or $l.StartsWith("* ")) { $l = $l.Substring(2).Trim() }
                $l
            } | Where-Object { $_.Length -gt 0 }
            
            $desc = ($lines -join ' ') -replace '\s+', ' '
            $desc = $desc.Trim()
        }
    }
    
    # Fallback to first non-empty markdown line
    if (-not $desc) {
        $lines = $raw -split '\r?\n' | Where-Object {
            $t = $_.Trim()
            $t.Length -gt 0 -and -not $t.StartsWith('#') -and -not $t.StartsWith('---')
        }
        if ($lines.Count -gt 0) {
            $desc = $lines[0].Trim() -replace '\s+', ' '
        }
    }
    
    if (-not $desc) { return "Custom skill." }
    
    # Extract first sentence or truncate at 140 chars
    $sentence = $desc
    if ($desc -match '^(.*?\.)(\s+[A-Z]|\Z)') {
        $sentence = $matches[1].Trim()
    }
    
    if ($sentence.Length -gt 145) {
        $truncated = $sentence.Substring(0, 140)
        $lastSpace = $truncated.LastIndexOf(' ')
        if ($lastSpace -gt 80) {
            $sentence = $truncated.Substring(0, $lastSpace) + "..."
        } else {
            $sentence = $truncated + "..."
        }
    }
    return $sentence
}

# Discover skills
$allDiscovered = [System.Collections.Generic.Dictionary[string, PSObject]]::new([System.StringComparer]::OrdinalIgnoreCase)

function Scan-SkillsDir($folderPath, $statusTag) {
    if ($folderPath -and (Test-Path -LiteralPath $folderPath)) {
        Get-ChildItem -LiteralPath $folderPath -Directory | ForEach-Object {
            $skillDir = $_
            $mdFile = Join-Path $skillDir.FullName "SKILL.md"
            if (Test-Path -LiteralPath $mdFile) {
                if (-not $allDiscovered.ContainsKey($skillDir.Name)) {
                    $desc = Get-SkillOneLiner $mdFile
                    $allDiscovered[$skillDir.Name] = [PSCustomObject]@{
                        Name = $skillDir.Name
                        Description = $desc
                        Status = $statusTag
                    }
                }
            }
        }
    }
}

Scan-SkillsDir $ActiveDir "Active"
Scan-SkillsDir $DisabledDir "Archived"

Write-Host "  Found $($allDiscovered.Count) skills across directories." -ForegroundColor Green

if ($allDiscovered.Count -eq 0) {
    Write-Host "[WARNING] No skills found in Active or Archived directories." -ForegroundColor Yellow
    Write-Host "Please ensure your folders are configured in skills_config.cfg or run manage_skills.bat first." -ForegroundColor Yellow
    if (Test-Path -LiteralPath $OutputPath) {
        Write-Host "Preserving existing summary file: $OutputPath" -ForegroundColor Yellow
    }
    exit 0
}

# Partition
$coreItems = @()
$webSubItems = @()
$customItems = @()

foreach ($key in ($allDiscovered.Keys | Sort-Object)) {
    $item = $allDiscovered[$key]
    if ($coreSkillsList -contains $item.Name) {
        $coreItems += $item
    } elseif ($webSubSkillsList -contains $item.Name) {
        $webSubItems += $item
    } else {
        $customItems += $item
    }
}

# Build output
$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine('================================================================================')
[void]$sb.AppendLine('                    ANTIGRAVITY SKILLS QUICK REFERENCE (ONE-LINERS)')
[void]$sb.AppendLine('================================================================================')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('[CORE SKILLS - KEEP ACTIVE]')
foreach ($item in $coreItems) {
    [void]$sb.AppendLine("$bullet $($item.Name): $($item.Description)")
}

[void]$sb.AppendLine('')
[void]$sb.AppendLine('[INDIVIDUAL WEB SUB-SKILLS - CAN ARCHIVE (INCLUDED IN WEB-DESIGNER)]')
foreach ($item in $webSubItems) {
    [void]$sb.AppendLine("$bullet $($item.Name): $($item.Description)")
}

if ($customItems.Count -gt 0) {
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('[ADDITIONAL & CREATIVE SKILLS]')
    foreach ($item in $customItems) {
        [void]$sb.AppendLine("$bullet $($item.Name): $($item.Description)")
    }
}

[void]$sb.AppendLine('')
[void]$sb.AppendLine('[GLOBAL BUILT-IN PLUGINS REFERENCE]')
[void]$sb.AppendLine("$bullet chrome-devtools-plugin: Browser automation, accessibility audits (a11y-debugging), LCP optimization, and heap profiling.")
[void]$sb.AppendLine("$bullet modern-web-guidance-plugin: Best practices for modern web standards, CSS APIs, and Chrome Extensions (Manifest V3).")
[void]$sb.AppendLine("$bullet flutter-plugin: Comprehensive Flutter and Dart engineering (unit/widget tests, responsive layout, architecture).")
[void]$sb.AppendLine("$bullet firebase-plugin: Firebase backend services (Auth, Firestore, App Hosting, Security Rules, Data Connect).")
[void]$sb.AppendLine("$bullet android-cli-plugin: Android virtual device management, SDK commands, and APK testing workflows.")
[void]$sb.AppendLine("$bullet google-antigravity-sdk: Native multi-agent orchestration, sidecars, skills creation, and Antigravity IDE guide.")
[void]$sb.AppendLine('')
[void]$sb.AppendLine('================================================================================')
[void]$sb.AppendLine('')

# Write UTF-8 with CRLF
$finalText = $sb.ToString().Replace("`r`n", "`n").Replace("`n", "`r`n")
[System.IO.File]::WriteAllBytes($OutputPath, [System.Text.Encoding]::UTF8.GetBytes($finalText))

Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host "[SUCCESS] Generated SKILLS_SUMMARY.txt with $($allDiscovered.Count) skills!" -ForegroundColor Green
Write-Host "File saved to: $OutputPath" -ForegroundColor Green
Write-Host "==============================================================================" -ForegroundColor Cyan
