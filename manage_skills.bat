@echo off
:: Auto-maximize console window on launch
if not "%~1"=="--maximized" (
    start "" /max cmd.exe /c ""%~f0" --maximized %*"
    exit /b
)
shift

setlocal EnableDelayedExpansion

title Antigravity Global Skills Manager (Enable / Disable)

:: -----------------------------------------------------------------------------
:: PATH CONFIGURATION (Auto-detected relative to script directory)
:: -----------------------------------------------------------------------------
set "SCRIPT_DIR=%~dp0"
set "ACTIVE_DIR=%SCRIPT_DIR%active"
set "DISABLED_DIR=%SCRIPT_DIR%archived"
set "LOG_FILE=%SCRIPT_DIR%skills_transactions.txt"
set "SUMMARY_FILE=%SCRIPT_DIR%SKILLS_SUMMARY.txt"
set "GLOBAL_CONFIG=%USERPROFILE%\.gemini\config\skills.json"

:: Normalize forward-slash path for JSON
set "JSON_ACTIVE_PATH=%ACTIVE_DIR:\=/%"

:: Ensure base directories exist
if not exist "%ACTIVE_DIR%" mkdir "%ACTIVE_DIR%"
if not exist "%DISABLED_DIR%" mkdir "%DISABLED_DIR%"
if not exist "%USERPROFILE%\.gemini\config" mkdir "%USERPROFILE%\.gemini\config"

:: Self-healing: Ensure global skills.json exists and registers active directory
if not exist "%GLOBAL_CONFIG%" (
    echo {"entries":[{"path":"%JSON_ACTIVE_PATH%"}]} > "%GLOBAL_CONFIG%"
)

:menu
cls
set act_cnt=0
for /d %%D in ("%ACTIVE_DIR%\*") do (
    if exist "%%~fD\SKILL.md" set /a act_cnt+=1
)
set dis_cnt=0
for /d %%D in ("%DISABLED_DIR%\*") do (
    if exist "%%~fD\SKILL.md" set /a dis_cnt+=1
)

echo ==============================================================================
echo               ANTIGRAVITY GLOBAL SKILLS MANAGER (Enable / Disable)
echo ==============================================================================
echo   Active (GLOBAL) : active\            [!act_cnt! active across ALL projects]
echo   Archived (OFF)  : archived\          [!dis_cnt! disabled / 0 context tokens]
echo   Global Sync     : ~/.gemini/config/skills.json [LINKED]
echo   Log File        : skills_transactions.txt
echo ==============================================================================
echo.
echo   -- [ EXPLORE ^& INSPECT ] ---------------------------------------------------
echo   [1] List All Skills              View active vs archived skills
echo   [2] Inspect Skill Details        Look up what any skill does (one-liner)
echo   [3] Open Summary Guide           Open full SKILLS_SUMMARY.txt in text editor
echo   [J] Open Global skills.json      Open and inspect ~/.gemini/config/skills.json
echo   [G] Auto-Generate Summary        Rebuild SKILLS_SUMMARY.txt from all SKILL.md files
echo.
echo   -- [ TOGGLE ^& OPTIMIZE ] ---------------------------------------------------
echo   [4] Disable a Skill              Move: Active   -^> Archived
echo   [5] Enable a Skill               Move: Archived -^> Active
echo   [6] Optimize Web Sub-Skills      Archive sub-skills (Save ~2,000 tokens)
echo   [7] Enable All Skills            Move all archived skills to active
echo.
echo   -- [ HISTORY ^& UNDO / REDO ] -----------------------------------------------
echo   [U] Undo Last Action             Revert previous move/toggle transaction
echo   [R] Redo Last Action             Re-apply previously undone transaction
echo.
echo   -- [ BACKUP ^& LOGS ] -------------------------------------------------------
echo   [8] Run Backup Utility           Mirror active skills to BACKUP\
echo   [9] Open Transaction Log         View last 100 move/copy events in text editor
echo.
echo   -- [ SYSTEM ] --------------------------------------------------------------
echo   [0] Exit Manager
echo ==============================================================================
echo.
set "CHOICE="
set /p "CHOICE=Select an option [0-9, U, R, G, J]: "
if not defined CHOICE goto :menu
set "CHOICE=!CHOICE: =!"

if /i "!CHOICE!"=="J" goto :view_skills_json
if /i "!CHOICE!"=="G" goto :generate_summary
if /i "!CHOICE!"=="U" goto :undo_action
if /i "!CHOICE!"=="R" goto :redo_action
if "!CHOICE!"=="1" goto :list_skills
if "!CHOICE!"=="2" goto :inspect_skill
if "!CHOICE!"=="3" goto :view_summary
if "!CHOICE!"=="4" goto :disable_single
if "!CHOICE!"=="5" goto :enable_single
if "!CHOICE!"=="6" goto :disable_web_subskills
if "!CHOICE!"=="7" goto :enable_all
if "!CHOICE!"=="8" goto :backup_skills
if "!CHOICE!"=="9" goto :view_log
if "!CHOICE!"=="0" exit /b
goto :menu

:view_skills_json
cls
echo ==============================================================================
echo                   OPENING GLOBAL SKILLS.JSON REGISTRY
echo File: %GLOBAL_CONFIG%
echo ==============================================================================
if not exist "%GLOBAL_CONFIG%" (
    echo [ERROR] %GLOBAL_CONFIG% not found. Creating default configuration...
    if not exist "%USERPROFILE%\.gemini\config" mkdir "%USERPROFILE%\.gemini\config"
    echo {"entries":[{"path":"%JSON_ACTIVE_PATH%"}]} > "%GLOBAL_CONFIG%"
)
echo Opening skills.json in default text editor...
start "" "%GLOBAL_CONFIG%"
goto :menu

:undo_action
cls
echo ==============================================================================
echo                         UNDO LAST TRANSACTION
echo ==============================================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%skills_history.ps1" -Action Undo -ActiveDir "%ACTIVE_DIR%" -DisabledDir "%DISABLED_DIR%" -LogFile "%LOG_FILE%" <nul
echo.
echo ==============================================================================
pause
goto :menu

:redo_action
cls
echo ==============================================================================
echo                         REDO LAST TRANSACTION
echo ==============================================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%skills_history.ps1" -Action Redo -ActiveDir "%ACTIVE_DIR%" -DisabledDir "%DISABLED_DIR%" -LogFile "%LOG_FILE%" <nul
echo.
echo ==============================================================================
pause
goto :menu

:list_skills
cls
echo ==============================================================================
echo                      CURRENT SKILLS STATUS & OVERVIEW
echo ==============================================================================
echo ACTIVE SKILLS [Loaded globally across all projects]:
echo ------------------------------------------------------------------------------
set count=0
for /d %%D in ("%ACTIVE_DIR%\*") do (
    if exist "%%~fD\SKILL.md" (
        set /a count+=1
        echo   [!count!] %%~nxD
    )
)
if !count!==0 echo   (No active skills found)
echo.
echo ARCHIVED SKILLS [Archived - Consuming 0 tokens]:
echo ------------------------------------------------------------------------------
set count=0
for /d %%D in ("%DISABLED_DIR%\*") do (
    if exist "%%~fD\SKILL.md" (
        set /a count+=1
        echo   [!count!] %%~nxD
    )
)
if !count!==0 echo   (No archived skills found)
echo ==============================================================================
echo.
pause
goto :menu

:inspect_skill
cls
echo ==============================================================================
echo                         SKILL INFORMATION LOOKUP
echo Source: SKILLS_SUMMARY.txt
echo ==============================================================================
echo Available Skills:
echo ------------------------------------------------------------------------------
set count=0
for /d %%D in ("%ACTIVE_DIR%\*") do (
    if exist "%%~fD\SKILL.md" (
        set /a count+=1
        set "ALL_!count!=%%~nxD"
        echo   [!count!] %%~nxD  [Active]
    )
)
for /d %%D in ("%DISABLED_DIR%\*") do (
    if exist "%%~fD\SKILL.md" (
        set /a count+=1
        set "ALL_!count!=%%~nxD"
        echo   [!count!] %%~nxD  [Archived]
    )
)
echo ------------------------------------------------------------------------------
echo.
set "SEL="
set /p "SEL=Enter skill number or type skill name [or 0 to cancel]: "
if not defined SEL goto :inspect_skill
set "SEL=!SEL: =!"
if "!SEL!"=="0" goto :menu

set "QUERY="
for /f "delims=" %%A in ("!SEL!") do (
    set "QUERY=!ALL_%%A!"
)
if "!QUERY!"=="" set "QUERY=!SEL!"

cls
echo ==============================================================================
echo SKILL DETAILS: !QUERY!
echo ==============================================================================
echo.
if not exist "%SUMMARY_FILE%" (
    echo [ERROR] %SUMMARY_FILE% does not exist. Run [G] to generate it first.
) else (
    set "FOUND="
    for /f "delims=" %%L in ('findstr /i /c:"!QUERY!:" "%SUMMARY_FILE%"') do (
        echo %%L
        set "FOUND=1"
    )
    if not defined FOUND (
        echo [NOT FOUND] That skill is not listed in SKILLS_SUMMARY.txt.
    )
)
echo.
echo ==============================================================================
pause
goto :menu

:disable_single
cls
echo ==============================================================================
echo                       SELECT AN ACTIVE SKILL TO ARCHIVE
echo ==============================================================================
set count=0
for /d %%D in ("%ACTIVE_DIR%\*") do (
    if exist "%%~fD\SKILL.md" (
        set /a count+=1
        set "ACT_!count!=%%~nxD"
        echo   [!count!] %%~nxD
    )
)
if !count!==0 (
    echo No active skills to archive.
    echo ==============================================================================
    pause
    goto :menu
)
echo ==============================================================================
echo.
set "SEL="
set /p "SEL=Enter skill number to archive [or 0 to cancel]: "
if not defined SEL goto :disable_single
set "SEL=!SEL: =!"
if "!SEL!"=="0" goto :menu

set "TARGET="
for /f "delims=" %%A in ("!SEL!") do (
    set "TARGET=!ACT_%%A!"
)
if "!TARGET!"=="" (
    echo Invalid selection.
    pause
    goto :disable_single
)

echo.
echo Moving "!TARGET!" to Archived folder...

if exist "%DISABLED_DIR%\!TARGET!" (
    echo [WARNING] "!TARGET!" already exists in Archived folder.
    set "REPLACE="
    set /p "REPLACE=Overwrite / replace it? [Y/N]: "
    if /i not "!REPLACE!"=="Y" (
        echo [CANCELLED] Move cancelled.
        call :log_transaction "DISABLE" "Move of '!TARGET!' cancelled by user" "CANCELLED"
        pause
        goto :menu
    )
    rd /s /q "%DISABLED_DIR%\!TARGET!"
)

move "%ACTIVE_DIR%\!TARGET!" "%DISABLED_DIR%\" >nul
if exist "%DISABLED_DIR%\!TARGET!" (
    echo [SUCCESS] "!TARGET!" is now archived [0 context tokens].
    call :log_transaction "DISABLE" "Moved '!TARGET!' from active to archive" "SUCCESS"
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%skills_history.ps1" -Action Record -Type DISABLE -Skills "!TARGET!" <nul
) else (
    echo [ERROR] Failed to move "!TARGET!".
    call :log_transaction "DISABLE" "Failed to move '!TARGET!' from active to archive" "FAILED"
)
pause
goto :menu

:enable_single
cls
echo ==============================================================================
echo                      SELECT AN ARCHIVED SKILL TO ACTIVATE
echo ==============================================================================
set count=0
for /d %%D in ("%DISABLED_DIR%\*") do (
    if exist "%%~fD\SKILL.md" (
        set /a count+=1
        set "DIS_!count!=%%~nxD"
        echo   [!count!] %%~nxD
    )
)
if !count!==0 (
    echo No archived skills to activate.
    echo ==============================================================================
    pause
    goto :menu
)
echo ==============================================================================
echo.
set "SEL="
set /p "SEL=Enter skill number to activate [or 0 to cancel]: "
if not defined SEL goto :enable_single
set "SEL=!SEL: =!"
if "!SEL!"=="0" goto :menu

set "TARGET="
for /f "delims=" %%A in ("!SEL!") do (
    set "TARGET=!DIS_%%A!"
)
if "!TARGET!"=="" (
    echo Invalid selection.
    pause
    goto :enable_single
)

echo.
echo Moving "!TARGET!" to Active folder...

if exist "%ACTIVE_DIR%\!TARGET!" (
    echo [WARNING] "!TARGET!" already exists in Active folder.
    set "REPLACE="
    set /p "REPLACE=Overwrite / replace it? [Y/N]: "
    if /i not "!REPLACE!"=="Y" (
        echo [CANCELLED] Move cancelled.
        call :log_transaction "ENABLE" "Move of '!TARGET!' cancelled by user" "CANCELLED"
        pause
        goto :menu
    )
    rd /s /q "%ACTIVE_DIR%\!TARGET!"
)

move "%DISABLED_DIR%\!TARGET!" "%ACTIVE_DIR%\" >nul
if exist "%ACTIVE_DIR%\!TARGET!" (
    echo [SUCCESS] "!TARGET!" is now active.
    call :log_transaction "ENABLE" "Moved '!TARGET!' from archive to active" "SUCCESS"
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%skills_history.ps1" -Action Record -Type ENABLE -Skills "!TARGET!" <nul
) else (
    echo [ERROR] Failed to move "!TARGET!".
    call :log_transaction "ENABLE" "Failed to move '!TARGET!' from archive to active" "FAILED"
)
pause
goto :menu

:disable_web_subskills
cls
echo ==============================================================================
echo           OPTIMIZE WEB SUB-SKILLS (Retaining Umbrella 'web-designer')
echo ==============================================================================
echo Archiving individual web sub-skills to save ~2,000 tokens...
echo.
set "SUBSKILLS=unique-webapp-design-patterns threejs impeccable-web-design taste-skill awesome-design-md theme-factory image-to-code web-artifacts-builder web-design-guidelines canvas-design algorithmic-art human-centric-web-design"

set moved_count=0
set "moved_list="
for %%S in (%SUBSKILLS%) do (
    if exist "%ACTIVE_DIR%\%%S" (
        if exist "%DISABLED_DIR%\%%S" rd /s /q "%DISABLED_DIR%\%%S"
        move "%ACTIVE_DIR%\%%S" "%DISABLED_DIR%\" >nul
        if exist "%DISABLED_DIR%\%%S" (
            echo   [-] Archived: %%S
            call :log_transaction "DISABLE_WEB" "Moved '%%S' from active to archive" "SUCCESS"
            set /a moved_count+=1
            if defined moved_list (set "moved_list=!moved_list!,%%S") else (set "moved_list=%%S")
        ) else (
            echo   [!] Error moving: %%S
            call :log_transaction "DISABLE_WEB" "Failed moving '%%S' to archive" "FAILED"
        )
    )
)
if !moved_count! gtr 0 (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%skills_history.ps1" -Action Record -Type DISABLE_BATCH -Skills "!moved_list!" <nul
)
echo.
echo ==============================================================================
echo [DONE] Core skills retained. [!moved_count! sub-skills archived to save tokens]
echo ==============================================================================
pause
goto :menu

:enable_all
cls
echo ==============================================================================
echo                          ACTIVATE ALL ARCHIVED SKILLS
echo ==============================================================================
set count=0
set "moved_list="
for /d %%D in ("%DISABLED_DIR%\*") do (
    if exist "%%~fD\SKILL.md" (
        set "SKILLNAME=%%~nxD"
        if exist "%ACTIVE_DIR%\!SKILLNAME!" (
            rd /s /q "%ACTIVE_DIR%\!SKILLNAME!"
        )
        move "%%~fD" "%ACTIVE_DIR%\" >nul
        if exist "%ACTIVE_DIR%\!SKILLNAME!" (
            echo   [+] Activated: !SKILLNAME!
            call :log_transaction "ENABLE_ALL" "Moved '!SKILLNAME!' from archive to active" "SUCCESS"
            set /a count+=1
            if defined moved_list (set "moved_list=!moved_list!,!SKILLNAME!") else (set "moved_list=!SKILLNAME!")
        ) else (
            echo   [!] Error moving: !SKILLNAME!
            call :log_transaction "ENABLE_ALL" "Failed moving '!SKILLNAME!' to active" "FAILED"
        )
    )
)
if !count! gtr 0 (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%skills_history.ps1" -Action Record -Type ENABLE_BATCH -Skills "!moved_list!" <nul
)
echo.
echo ==============================================================================
if !count!==0 echo No archived skills found.
echo [DONE] All skills moved to Active folder [active\] - !count! activated
echo ==============================================================================
pause
goto :menu

:backup_skills
cls
echo ==============================================================================
echo                     BACKUP ACTIVE SKILLS (Robocopy Mirror)
echo ==============================================================================
set "BACKUP_SCRIPT=%SCRIPT_DIR%backup_skills.bat"
if exist "%BACKUP_SCRIPT%" (
    call "%BACKUP_SCRIPT%" nopause
) else (
    echo [ERROR] Backup script not found: "%BACKUP_SCRIPT%"
    call :log_transaction "BACKUP" "Backup script not found at %BACKUP_SCRIPT%" "FAILED"
)
echo.
echo ==============================================================================
pause
goto :menu

:view_log
cls
echo ==============================================================================
echo                         OPENING TRANSACTION LOG
echo Log file: %LOG_FILE%
echo ==============================================================================
if not exist "%LOG_FILE%" (
    echo [INFO] Log file does not exist yet. Creating empty log file...
    type nul > "%LOG_FILE%"
)
echo Opening skills_transactions.txt in default text editor...
start "" "%LOG_FILE%"
goto :menu

:generate_summary
cls
echo ==============================================================================
echo              AUTO-GENERATE SKILLS SUMMARY [from SKILL.md files]
echo ==============================================================================
set "GEN_SCRIPT=%SCRIPT_DIR%generate_summary.bat"
if exist "%GEN_SCRIPT%" (
    call "%GEN_SCRIPT%" nopause
) else (
    echo [ERROR] Generator script not found: "%GEN_SCRIPT%"
)
echo.
echo ==============================================================================
pause
goto :menu

:view_summary
cls
echo ==============================================================================
echo                         OPENING SKILLS SUMMARY GUIDE
echo File: %SUMMARY_FILE%
echo ==============================================================================
if not exist "%SUMMARY_FILE%" (
    echo [ERROR] %SUMMARY_FILE% not found. Run [G] to generate it first.
    pause
    goto :menu
)
echo Opening SKILLS_SUMMARY.txt in default text editor...
start "" "%SUMMARY_FILE%"
goto :menu

:log_transaction
set "LOG_TIME=%DATE% %TIME%"
echo [!LOG_TIME!] [%~1] %~2 [%~3] >> "%LOG_FILE%"
powershell -NoProfile -Command "$p = '%LOG_FILE%'; if (Test-Path -LiteralPath $p) { $c = Get-Content -LiteralPath $p; if ($c.Count -gt 100) { $c[-100..-1] | Set-Content -LiteralPath $p } }" >nul 2>&1
exit /b
