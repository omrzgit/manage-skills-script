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

if (-not $ActiveDir) {
    $cand = Join-Path $PSScriptRoot "active"
    if (Test-Path -LiteralPath $cand) { $ActiveDir = (Resolve-Path $cand).Path } else { $ActiveDir = $PSScriptRoot }
}
if (-not $DisabledDir) {
    $cand = Join-Path $PSScriptRoot "archived"
    if (Test-Path -LiteralPath $cand) { $DisabledDir = (Resolve-Path $cand).Path } else { $DisabledDir = $PSScriptRoot }
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
                foreach ($item in $obj.undoStack) { $item.skills = @($item.skills) }
                foreach ($item in $obj.redoStack) { $item.skills = @($item.skills) }
                return $obj
            }
        } catch { }
    }
    
    return [PSCustomObject]@{
        undoStack = [System.Collections.ArrayList]@()
        redoStack = [System.Collections.ArrayList]@()
    }
}

function Save-History($obj) {
    $json = $obj | ConvertTo-Json -Depth 5
    [System.IO.File]::WriteAllText($HistoryFile, $json, [System.Text.Encoding]::UTF8)
}

$history = Load-History
$undoList = [System.Collections.ArrayList]::new()
if ($history.undoStack) { foreach ($item in $history.undoStack) { [void]$undoList.Add($item) } }
$redoList = [System.Collections.ArrayList]::new()
if ($history.redoStack) { foreach ($item in $history.redoStack) { [void]$redoList.Add($item) } }

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
        if ($undoList.Count -gt 50) { [void]$undoList.RemoveAt(0) }
        $redoList.Clear()
        
        Save-History ([PSCustomObject]@{ undoStack = $undoList; redoStack = $redoList })
        exit 0
    }

    "Undo" {
        if ($undoList.Count -eq 0) {
            Write-Host "Nothing to undo." -ForegroundColor Yellow
            exit 0
        }

        $lastItem = $undoList[$undoList.Count - 1]
        [void]$undoList.RemoveAt($undoList.Count - 1)
        
        $opType = $lastItem.type
        $skills = @($lastItem.skills)
        
        Write-Host "Undoing transaction: $opType on ($($skills -join ', '))" -ForegroundColor Cyan
        
        $successList = @()
        switch -Regex ($opType) {
            "DISABLE" {
                foreach ($s in $skills) {
                    $src = Join-Path $DisabledDir $s
                    $dst = Join-Path $ActiveDir $s
                    if (Test-Path -LiteralPath $src) {
                        if (Test-Path -LiteralPath $dst) { Remove-Item -LiteralPath $dst -Recurse -Force }
                        Move-Item -LiteralPath $src -Destination $dst -Force
                        $successList += $s
                        Write-Host "  [+] Restored to Active: $s" -ForegroundColor Green
                    }
                }
            }
            "ENABLE" {
                foreach ($s in $skills) {
                    $src = Join-Path $ActiveDir $s
                    $dst = Join-Path $DisabledDir $s
                    if (Test-Path -LiteralPath $src) {
                        if (Test-Path -LiteralPath $dst) { Remove-Item -LiteralPath $dst -Recurse -Force }
                        Move-Item -LiteralPath $src -Destination $dst -Force
                        $successList += $s
                        Write-Host "  [-] Moved back to Archived: $s" -ForegroundColor Yellow
                    }
                }
            }
        }
        
        if ($successList.Count -gt 0) {
            [void]$redoList.Add($lastItem)
            Log-Tx "UNDO" "Undid $opType for ($($successList -join ', '))" "SUCCESS"
        }
        
        Save-History ([PSCustomObject]@{ undoStack = $undoList; redoStack = $redoList })
        exit 0
    }

    "Redo" {
        if ($redoList.Count -eq 0) {
            Write-Host "Nothing to redo." -ForegroundColor Yellow
            exit 0
        }

        $nextItem = $redoList[$redoList.Count - 1]
        [void]$redoList.RemoveAt($redoList.Count - 1)
        
        $opType = $nextItem.type
        $skills = @($nextItem.skills)
        
        Write-Host "Redoing transaction: $opType on ($($skills -join ', '))" -ForegroundColor Cyan
        
        $successList = @()
        switch -Regex ($opType) {
            "DISABLE" {
                foreach ($s in $skills) {
                    $src = Join-Path $ActiveDir $s
                    $dst = Join-Path $DisabledDir $s
                    if (Test-Path -LiteralPath $src) {
                        if (Test-Path -LiteralPath $dst) { Remove-Item -LiteralPath $dst -Recurse -Force }
                        Move-Item -LiteralPath $src -Destination $dst -Force
                        $successList += $s
                        Write-Host "  [-] Archived again: $s" -ForegroundColor Yellow
                    }
                }
            }
            "ENABLE" {
                foreach ($s in $skills) {
                    $src = Join-Path $DisabledDir $s
                    $dst = Join-Path $ActiveDir $s
                    if (Test-Path -LiteralPath $src) {
                        if (Test-Path -LiteralPath $dst) { Remove-Item -LiteralPath $dst -Recurse -Force }
                        Move-Item -LiteralPath $src -Destination $dst -Force
                        $successList += $s
                        Write-Host "  [+] Activated again: $s" -ForegroundColor Green
                    }
                }
            }
        }
        
        if ($successList.Count -gt 0) {
            [void]$undoList.Add($nextItem)
            Log-Tx "REDO" "Redid $opType for ($($successList -join ', '))" "SUCCESS"
        }
        
        Save-History ([PSCustomObject]@{ undoStack = $undoList; redoStack = $redoList })
        exit 0
    }
}
