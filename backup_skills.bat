@echo off
setlocal EnableDelayedExpansion

title Antigravity Skills Backup Utility

set "SCRIPT_DIR=%~dp0"
set "CONFIG_FILE=%SCRIPT_DIR%skills_config.cfg"
set "LOG_FILE=%SCRIPT_DIR%skills_transactions.txt"

if not exist "%CONFIG_FILE%" (
    echo ==============================================================================
    echo [ERROR] Configuration file not found: %CONFIG_FILE%
    echo Please run 'manage_skills.bat' first to configure your folder paths.
    echo ==============================================================================
    if not "%~1"=="nopause" pause
    exit /b 1
)

for /f "usebackq eol=: delims=" %%L in ("%CONFIG_FILE%") do %%L

set "SOURCE=!ACTIVE_DIR!"
set "DEST=!BACKUP_DIR!"

echo ==============================================================================
echo                     ANTIGRAVITY SKILLS BACKUP UTILITY
echo ==============================================================================
echo Source     : "%SOURCE%"
echo Destination: "%DEST%"
echo Log File   : "%LOG_FILE%"
echo.

if not exist "%SOURCE%" (
    echo [ERROR] Source folder does not exist: "%SOURCE%"
    call :log_transaction "BACKUP" "Source folder does not exist: %SOURCE%" "FAILED"
    goto :end
)

if not exist "%DEST%" (
    echo Creating backup directory...
    mkdir "%DEST%"
)

echo Starting mirror backup using robocopy...
echo.
robocopy "%SOURCE%" "%DEST%" /E /R:1 /W:1 /NP /NDL

if %ERRORLEVEL% LEQ 7 (
    echo.
    echo ==============================================================================
    echo [SUCCESS] Backup completed successfully to:
    echo "%DEST%"
    echo ==============================================================================
    call :log_transaction "BACKUP" "Mirrored active skills to backup folder via robocopy" "SUCCESS"
) else (
    echo.
    echo [ERROR] Robocopy encountered an error with exit code %ERRORLEVEL%.
    call :log_transaction "BACKUP" "Robocopy failed with exit code %ERRORLEVEL%" "FAILED"
)

:end
echo.
if not "%~1"=="nopause" pause
exit /b 0

:log_transaction
set "LOG_TIME=%DATE% %TIME%"
echo [!LOG_TIME!] [%~1] %~2 [%~3] >> "%LOG_FILE%"
powershell -NoProfile -Command "$p = '%LOG_FILE%'; if (Test-Path -LiteralPath $p) { $c = Get-Content -LiteralPath $p; if ($c.Count -gt 100) { $c[-100..-1] | Set-Content -LiteralPath $p } }" >nul 2>&1
exit /b
