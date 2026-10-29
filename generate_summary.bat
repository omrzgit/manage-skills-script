@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0generate_summary.ps1"
if not "%~1"=="nopause" pause
exit /b %ERRORLEVEL%
