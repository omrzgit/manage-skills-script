param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("Record", "Undo", "Redo", "Status")]
    [string]$Action,

    [string]$Type = "",
    [string]$Skills = "",
    [string]$ActiveDir = "",
    [string]$DisabledDir = "",
    [string]$LogFile = "",
    [string]$HistoryFile = ""
)

# Auto-detect configuration if parameters not passed explicitly
if (-not $ActiveDir -or -not $DisabledDir -or -not $LogFile) {
    $cfgPath = Join-Path $PSScriptRoot "skills_config.cfg"
    if (Test-Path -LiteralPath $cfgPath) {
        Get-Content -LiteralPath $cfgPath | ForEach-Object {
            if ($_ -match '^\s*set\s+"?([^=]+)"?\s*=\s*"?([^"]*)"?\s*$') {
                $k = $matches[1].Trim()
                $v = $matches[2].Trim()
                if ($k -eq "ACTIVE_DIR" -and -not $ActiveDir) { $ActiveDir = $v }
                if ($k -eq "DISABLED_DIR" -and -not $DisabledDir) { $DisabledDir = $v }
                if ($k -eq "LOG_FILE" -and -not $LogFile) { $LogFile = $v }
            }
        }
    }
}

if (-not $ActiveDir) {
    $cand = Join-Path $PSScriptRoot "..\.agents\skills"
    if (Test-Path -LiteralPath $cand) { $ActiveDir = (Resolve-Path $cand).Path }
}
if (-not $DisabledDir) {
    $DisabledDir = Join-Path $PSScriptRoot "skills_archive"
}
if (-not $LogFile) {
    $LogFile = Join-Path $PSScriptRoot "skills_transactions.txt"
}
if (-not $HistoryFile) {
    $HistoryFile = Join-Path $PSScriptRoot "skills_history.json"
}

function Log-Tx($tag, $msg, $status) {
    if (-not $LogFile) { return }
    $timeStr = (Get-Date).ToString("ddd MM/dd/yyyy HH:mm:ss.ff")
    $logLine = "[$timeStr] [$tag] $msg [$status]"
    Add-Content -LiteralPath $LogFile -Value $logLine -Encoding UTF8
    
    # Trim to 100 entries
    if (Test-Path -LiteralPath $LogFile) {
        $lines = Get-Content -LiteralPath $LogFile
        if ($lines.Count -gt 100) {
            $lines[-100..-1] | Set-Content -LiteralPath $LogFile -Encoding UTF8
        }
    }
}

function Load-History {
    if (Test-Path -LiteralPath $HistoryFile) {
        try {
            $raw = Get-Content -LiteralPath $HistoryFile -Raw -Encoding UTF8
            $obj = $raw | ConvertFrom-Json
            if ($obj -and ($null -ne $obj.undoStack) -and ($null -ne $obj.redoStack)) {
                # Ensure all skills are arrays
                foreach ($item in $obj.undoStack) { $item.skills = @($item.skills) }
                foreach ($item in $obj.redoStack) { $item.skills = @($item.skills) }
                return $obj
            }
        } catch { }
    }
    
    # Fallback seed from skills_transactions.txt if history file doesn't exist yet
    $undo = @()
    if (Test-Path -LiteralPath $LogFile) {
        $txLines = Get-Content -LiteralPath $LogFile -Encoding UTF8
        foreach ($l in $txLines) {
            if ($l -match '\[(DISABLE|ENABLE)\] Moved ''([^'']+)''') {
                $t = $matches[1]
                $sk = $matches[2]
                $undo += [PSCustomObject]@{
                    type = $t
                    skills = @($sk)
                    timestamp = ""
                }
            }
        }
        if ($undo.Count -gt 30) { $undo = $undo[-30..-1] }
    }

    return [PSCustomObject]@{
        undoStack = [System.Collections.ArrayList]@($undo)
        redoStack = [System.Collections.ArrayList]@()
    }
}

function Save-History($obj) {
    $json = $obj | ConvertTo-Json -Depth 5
    [System.IO.File]::WriteAllText($HistoryFile, $json, [System.Text.Encoding]::UTF8)
}

$history = Load-History

# Ensure ArrayList types for easy push/pop
$undoList = [System.Collections.ArrayList]::new()
if ($history.undoStack) { foreach ($item in $history.undoStack) { [void]$undoList.Add($item) } }
$redoList = [System.Collections.ArrayList]::new()
if ($history.redoStack) { foreach ($item in $history.redoStack) { [void]$redoList.Add($item) } }

$archiveLabel = if ($DisabledDir) { Split-Path $DisabledDir -Leaf } else { "Archive" }

switch ($Action) {
    "Record" {
        if (-not $Type -or -not $Skills) { exit 0 }
        $skillArr = @($Skills -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_.Length -gt 0 })
        if ($skillArr.Count -eq 0) { exit 0 }
        
        $entry = [PSCustomObject]@{
            type = $Type
            skills = $skillArr
            timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        }
        [void]$undoList.Add($entry)
        while ($undoList.Count -gt 50) { $undoList.RemoveAt(0) }
        $redoList.Clear()
        
        Save-History ([PSCustomObject]@{ undoStack = $undoList; redoStack = $redoList })
        exit 0
    }

    "Undo" {
        if ($undoList.Count -eq 0) {
            Write-Host "[INFO] Nothing to undo (History is empty)." -ForegroundColor Yellow
            exit 0
        }

        $lastIdx = $undoList.Count - 1
        $tx = $undoList[$lastIdx]
        $undoList.RemoveAt($lastIdx)

        $targetSkills = @($tx.skills)
        $successCount = 0
        $failCount = 0

        # Perform inverse operation
        if ($tx.type -eq "DISABLE" -or $tx.type -eq "DISABLE_WEB" -or $tx.type -eq "DISABLE_BATCH") {
            # Was moved from Active -> Disabled. Inverse: move Disabled -> Active
            Write-Host "Undoing action: Restoring $($targetSkills.Count) skill(s) to Active..." -ForegroundColor Cyan
            foreach ($sk in $targetSkills) {
                $src = Join-Path $DisabledDir $sk
                $dst = Join-Path $ActiveDir $sk
                if (Test-Path -LiteralPath $src) {
                    if (Test-Path -LiteralPath $dst) { Remove-Item -LiteralPath $dst -Recurse -Force -ErrorAction SilentlyContinue }
                    try {
                        Move-Item -LiteralPath $src -Destination $dst -Force -ErrorAction Stop
                        Write-Host "  [+] Restored: $sk -> Active" -ForegroundColor Green
                        Log-Tx "UNDO" "Restored '$sk' from archive to active" "SUCCESS"
                        $successCount++
                    } catch {
                        Write-Host "  [!] Failed restoring: $sk ($($_.Exception.Message))" -ForegroundColor Red
                        Log-Tx "UNDO" "Failed restoring '$sk' to active" "FAILED"
                        $failCount++
                    }
                } else {
                    Write-Host "  [!] Archived folder missing: $src" -ForegroundColor Red
                    $failCount++
                }
            }
        }
        elseif ($tx.type -eq "ENABLE" -or $tx.type -eq "ENABLE_ALL" -or $tx.type -eq "ENABLE_BATCH") {
            # Was moved from Disabled -> Active. Inverse: move Active -> Disabled
            Write-Host "Undoing action: Archiving $($targetSkills.Count) skill(s)..." -ForegroundColor Cyan
            foreach ($sk in $targetSkills) {
                $src = Join-Path $ActiveDir $sk
                $dst = Join-Path $DisabledDir $sk
                if (Test-Path -LiteralPath $src) {
                    if (Test-Path -LiteralPath $dst) { Remove-Item -LiteralPath $dst -Recurse -Force -ErrorAction SilentlyContinue }
                    try {
                        Move-Item -LiteralPath $src -Destination $dst -Force -ErrorAction Stop
                        Write-Host "  [-] Archived: $sk -> $archiveLabel" -ForegroundColor Green
                        Log-Tx "UNDO" "Moved '$sk' from active to archive" "SUCCESS"
                        $successCount++
                    } catch {
                        Write-Host "  [!] Failed archiving: $sk ($($_.Exception.Message))" -ForegroundColor Red
                        Log-Tx "UNDO" "Failed moving '$sk' to archive" "FAILED"
                        $failCount++
                    }
                } else {
                    Write-Host "  [!] Active folder missing: $src" -ForegroundColor Red
                    $failCount++
                }
            }
        }

        # Push to redo stack
        $tx.skills = $targetSkills
        [void]$redoList.Add($tx)
        while ($redoList.Count -gt 50) { $redoList.RemoveAt(0) }

        Save-History ([PSCustomObject]@{ undoStack = $undoList; redoStack = $redoList })

        Write-Host ""
        if ($successCount -gt 0) {
            Write-Host "[SUCCESS] Undo complete: $successCount skill(s) updated." -ForegroundColor Green
        } else {
            Write-Host "[WARNING] Undo finished with 0 modifications." -ForegroundColor Yellow
        }
        exit 0
    }

    "Redo" {
        if ($redoList.Count -eq 0) {
            Write-Host "[INFO] Nothing to redo (Redo history is empty)." -ForegroundColor Yellow
            exit 0
        }

        $lastIdx = $redoList.Count - 1
        $tx = $redoList[$lastIdx]
        $redoList.RemoveAt($lastIdx)

        $targetSkills = @($tx.skills)
        $successCount = 0
        $failCount = 0

        # Re-apply operation
        if ($tx.type -eq "DISABLE" -or $tx.type -eq "DISABLE_WEB" -or $tx.type -eq "DISABLE_BATCH") {
            # Re-apply: Move Active -> Disabled
            Write-Host "Redoing action: Archiving $($targetSkills.Count) skill(s)..." -ForegroundColor Cyan
            foreach ($sk in $targetSkills) {
                $src = Join-Path $ActiveDir $sk
                $dst = Join-Path $DisabledDir $sk
                if (Test-Path -LiteralPath $src) {
                    if (Test-Path -LiteralPath $dst) { Remove-Item -LiteralPath $dst -Recurse -Force -ErrorAction SilentlyContinue }
                    try {
                        Move-Item -LiteralPath $src -Destination $dst -Force -ErrorAction Stop
                        Write-Host "  [-] Re-archived: $sk -> $archiveLabel" -ForegroundColor Green
                        Log-Tx "REDO" "Moved '$sk' from active to archive" "SUCCESS"
                        $successCount++
                    } catch {
                        Write-Host "  [!] Failed re-archiving: $sk ($($_.Exception.Message))" -ForegroundColor Red
                        Log-Tx "REDO" "Failed moving '$sk' to archive" "FAILED"
                        $failCount++
                    }
                } else {
                    Write-Host "  [!] Active folder missing: $src" -ForegroundColor Red
                    $failCount++
                }
            }
        }
        elseif ($tx.type -eq "ENABLE" -or $tx.type -eq "ENABLE_ALL" -or $tx.type -eq "ENABLE_BATCH") {
            # Re-apply: Move Disabled -> Active
            Write-Host "Redoing action: Activating $($targetSkills.Count) skill(s)..." -ForegroundColor Cyan
            foreach ($sk in $targetSkills) {
                $src = Join-Path $DisabledDir $sk
                $dst = Join-Path $ActiveDir $sk
                if (Test-Path -LiteralPath $src) {
                    if (Test-Path -LiteralPath $dst) { Remove-Item -LiteralPath $dst -Recurse -Force -ErrorAction SilentlyContinue }
                    try {
                        Move-Item -LiteralPath $src -Destination $dst -Force -ErrorAction Stop
                        Write-Host "  [+] Re-activated: $sk -> Active" -ForegroundColor Green
                        Log-Tx "REDO" "Restored '$sk' from archive to active" "SUCCESS"
                        $successCount++
                    } catch {
                        Write-Host "  [!] Failed re-activating: $sk ($($_.Exception.Message))" -ForegroundColor Red
                        Log-Tx "REDO" "Failed restoring '$sk' to active" "FAILED"
                        $failCount++
                    }
                } else {
                    Write-Host "  [!] Archived folder missing: $src" -ForegroundColor Red
                    $failCount++
                }
            }
        }

        # Push back to undo stack
        $tx.skills = $targetSkills
        [void]$undoList.Add($tx)
        while ($undoList.Count -gt 50) { $undoList.RemoveAt(0) }

        Save-History ([PSCustomObject]@{ undoStack = $undoList; redoStack = $redoList })

        Write-Host ""
        if ($successCount -gt 0) {
            Write-Host "[SUCCESS] Redo complete: $successCount skill(s) updated." -ForegroundColor Green
        } else {
            Write-Host "[WARNING] Redo finished with 0 modifications." -ForegroundColor Yellow
        }
        exit 0
    }

    "Status" {
        $uCount = $undoList.Count
        $rCount = $redoList.Count
        $lastUndo = if ($uCount -gt 0) {
            $lastItem = $undoList[-1]
            "$($lastItem.type): $(@($lastItem.skills) -join ', ')"
        } else { "None" }
        $lastRedo = if ($rCount -gt 0) {
            $lastItem = $redoList[-1]
            "$($lastItem.type): $(@($lastItem.skills) -join ', ')"
        } else { "None" }
        Write-Host "Undo available: $uCount (Last: $lastUndo)"
        Write-Host "Redo available: $rCount (Last: $lastRedo)"
        exit 0
    }
}
