@echo off
setlocal EnableDelayedExpansion

title Antigravity Skills Summary Generator

set "SCRIPT_DIR=%~dp0"
set "CONFIG_FILE=%SCRIPT_DIR%skills_config.cfg"
set "PS_SCRIPT=%SCRIPT_DIR%generate_summary.ps1"
set "OUTPUT_FILE=%SCRIPT_DIR%SKILLS_SUMMARY.txt"

if not exist "%PS_SCRIPT%" (
    echo [ERROR] PowerShell script not found: "%PS_SCRIPT%"
    if not "%~1"=="nopause" pause
    exit /b 1
)

echo Starting Skills Summary Auto-Generator...
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" -ConfigPath "%CONFIG_FILE%" -OutputPath "%OUTPUT_FILE%" <nul

if !errorlevel!==0 (
    echo.
    echo [SUCCESS] Summary generation completed successfully!
) else (
    echo.
    echo [ERROR] Generator encountered an issue [Exit code !errorlevel!].
)

if not "%~1"=="nopause" pause
exit /b !errorlevel!
