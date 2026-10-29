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

if (-not $ActiveDir) {
    $cand = Join-Path $PSScriptRoot "active"
    if (Test-Path -LiteralPath $cand) { $ActiveDir = $cand } else { $ActiveDir = $PSScriptRoot }
}
if (-not $DisabledDir) {
    $cand = Join-Path $PSScriptRoot "archived"
    if (Test-Path -LiteralPath $cand) { $DisabledDir = $cand } else { $DisabledDir = $PSScriptRoot }
}
if (-not $OutputPath) {
    $OutputPath = Join-Path $PSScriptRoot "SKILLS_SUMMARY.txt"
}

Write-Host "  Active Skills Folder  : $ActiveDir"
Write-Host "  Archived Folder       : $DisabledDir"
Write-Host "  Output Summary File   : $OutputPath"
Write-Host "------------------------------------------------------------------------------"

$skillsMap = [ordered]@{}

function Parse-SkillFile($skillFilePath, $status) {
    if (-not (Test-Path -LiteralPath $skillFilePath)) { return }
    $content = Get-Content -LiteralPath $skillFilePath -Raw -Encoding UTF8
    
    $name = ""
    $desc = ""
    
    if ($content -match '(?ms)^---\s*\r?\n(.*?)\r?\n---') {
        $frontmatter = $matches[1]
        if ($frontmatter -match '(?m)^name:\s*([^\r\n]+)') {
            $name = $matches[1].Trim()
        }
        if ($frontmatter -match '(?ms)^description:\s*([|>]-?\s*\r?\n\s+.*?(?=\r?\n[a-zA-Z0-9_-]+:|\r?\n---|\Z))') {
            $desc = $matches[1] -replace '^[|>]-?\s*', ''
            $desc = ($desc -split "\r?\n" | ForEach-Object { $_.Trim() }) -join " "
        } elseif ($frontmatter -match '(?m)^description:\s*([^\r\n]+)') {
            $desc = $matches[1].Trim()
        }
    }
    
    if (-not $name) {
        $name = Split-Path (Split-Path $skillFilePath -Parent) -Leaf
    }
    if (-not $desc) {
        $desc = "Antigravity skill: $name"
    }

    $skillsMap[$name] = [PSCustomObject]@{
        Name = $name
        Description = $desc
        Status = $status
    }
}

# Scan Active Skills
if (Test-Path -LiteralPath $ActiveDir) {
    Get-ChildItem -LiteralPath $ActiveDir -Directory | ForEach-Object {
        $sm = Join-Path $_.FullName "SKILL.md"
        if (Test-Path -LiteralPath $sm) {
            Parse-SkillFile -skillFilePath $sm -status "Active"
        }
    }
}

# Scan Archived Skills
if (Test-Path -LiteralPath $DisabledDir) {
    Get-ChildItem -LiteralPath $DisabledDir -Directory | ForEach-Object {
        $sm = Join-Path $_.FullName "SKILL.md"
        if (Test-Path -LiteralPath $sm) {
            if (-not $skillsMap.Contains($_.Name)) {
                Parse-SkillFile -skillFilePath $sm -status "Archived"
            }
        }
    }
}

Write-Host "  Found $($skillsMap.Count) skills across directories."

# Write Output Summary
$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine("================================================================================")
[void]$sb.AppendLine("                    ANTIGRAVITY SKILLS QUICK REFERENCE")
[void]$sb.AppendLine("================================================================================")
[void]$sb.AppendLine("")

$coreNames = @("web-designer", "context-engineering", "massgen", "superpowers", "playwright-cli")
$coreSkills = @()
$subSkills = @()

foreach ($key in $skillsMap.Keys) {
    if ($coreNames -contains $key) {
        $coreSkills += $skillsMap[$key]
    } else {
        $subSkills += $skillsMap[$key]
    }
}

if ($coreSkills.Count -gt 0) {
    [void]$sb.AppendLine("[CORE WORKFLOW SKILLS]")
    foreach ($s in $coreSkills) {
        [void]$sb.AppendLine("$bullet $($s.Name) [$($s.Status)]: $($s.Description)")
    }
    [void]$sb.AppendLine("")
}

if ($subSkills.Count -gt 0) {
    [void]$sb.AppendLine("[SPECIALIZED & SUB-SKILLS]")
    foreach ($s in $subSkills) {
        [void]$sb.AppendLine("$bullet $($s.Name) [$($s.Status)]: $($s.Description)")
    }
    [void]$sb.AppendLine("")
}

[System.IO.File]::WriteAllText($OutputPath, $sb.ToString(), [System.Text.Encoding]::UTF8)

Write-Host "==============================================================================" -ForegroundColor Green
Write-Host "[SUCCESS] Generated SKILLS_SUMMARY.txt with $($skillsMap.Count) skills!" -ForegroundColor Green
Write-Host "File saved to: $OutputPath" -ForegroundColor Green
Write-Host "==============================================================================" -ForegroundColor Green
