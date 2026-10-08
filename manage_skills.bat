@echo off
setlocal EnableDelayedExpansion

title Antigravity Skills Manager (Enable / Disable)

set "SCRIPT_DIR=%~dp0"
set "CONFIG_FILE=%SCRIPT_DIR%skills_config.cfg"
set "LOG_FILE=%SCRIPT_DIR%skills_transactions.txt"
set "SUMMARY_FILE=%SCRIPT_DIR%SKILLS_SUMMARY.txt"

:: Check if configuration exists; if not, trigger first-run setup
if not exist "%CONFIG_FILE%" goto :first_run_setup

:: Load configuration
for /f "usebackq eol=: delims=" %%L in ("%CONFIG_FILE%") do %%L

:: Validate loaded configuration
if not defined ACTIVE_DIR goto :first_run_setup
if not defined DISABLED_DIR goto :first_run_setup
if not defined BACKUP_DIR goto :first_run_setup

if not exist "%ACTIVE_DIR%" mkdir "%ACTIVE_DIR%" 2>nul
if not exist "%DISABLED_DIR%" mkdir "%DISABLED_DIR%" 2>nul
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%" 2>nul

:menu
cls
set act_cnt=0
for /d %%D in ("!ACTIVE_DIR!\*") do (
    if exist "%%~fD\SKILL.md" set /a act_cnt+=1
)
set dis_cnt=0
for /d %%D in ("!DISABLED_DIR!\*") do (
    if exist "%%~fD\SKILL.md" set /a dis_cnt+=1
)

echo ==============================================================================
echo                         ANTIGRAVITY SKILLS MANAGER
echo ==============================================================================
echo   Active Folder   : !ACTIVE_DIR!
echo                     [!act_cnt! active skills in agent context]
echo   Archived Folder : !DISABLED_DIR!
echo                     [!dis_cnt! archived skills - 0 tokens]
echo   Backup Folder   : !BACKUP_DIR!
echo   Log File        : !LOG_FILE!
echo ==============================================================================
echo.
echo   -- [ EXPLORE ^& INSPECT ] ---------------------------------------------------
echo   [1] List All Skills              View active vs archived skills
echo   [2] Inspect Skill Details        Look up what any skill does (one-liner)
echo   [3] Open Summary Guide           Open full SKILLS_SUMMARY.txt in text editor
echo   [G] Auto-Generate Summary        Rebuild SKILLS_SUMMARY.txt from all SKILL.md files
echo.
echo   -- [ TOGGLE ^& OPTIMIZE ] ---------------------------------------------------
echo   [4] Disable a Skill              Move: Active   -^> Archived
echo   [5] Enable a Skill               Move: Archived -^> Active
echo   [6] Optimize Web Sub-Skills      Archive redundant web sub-skills (Save tokens)
echo   [7] Enable All Skills            Move all archived skills to active
echo.
echo   -- [ BACKUP ^& LOGS ] -------------------------------------------------------
echo   [8] Run Backup Utility           Mirror active skills to backup folder
echo   [9] Open Transaction Log         View last 100 move/copy events in text editor
echo.
echo   -- [ SETTINGS ^& SYSTEM ] ---------------------------------------------------
echo   [C] Reconfigure Folder Paths     Change active, archive, or backup locations
echo   [0] Exit Manager
echo ==============================================================================
echo.
set "CHOICE="
set /p "CHOICE=Select an option [0-9 or C]: "
if not defined CHOICE goto :menu
set "CHOICE=!CHOICE: =!"

if /i "!CHOICE!"=="C" goto :first_run_setup
if /i "!CHOICE!"=="G" goto :generate_summary
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
if "!CHOICE!"=="10" exit /b
goto :menu

:first_run_setup
cls
echo ==============================================================================
echo                 ANTIGRAVITY SKILLS MANAGER - FOLDER SETUP
echo ==============================================================================
echo   Configure your skills directories. Settings are saved to skills_config.cfg
echo   and can be updated anytime by selecting option [C] from the menu.
echo ==============================================================================
echo.
echo [1/3] ACTIVE SKILLS FOLDER
echo       Where your AI agent / IDE currently loads active skills into memory.
echo       Example: C:\Project\.agents\skills  or  %%USERPROFILE%%\.agents\skills
echo.
set "INP_ACT="
set /p "INP_ACT=Enter path for Active Skills: "
if not defined INP_ACT (
    echo [ERROR] Active skills folder cannot be empty.
    pause
    goto :first_run_setup
)
set "INP_ACT=!INP_ACT:"=!"

echo.
echo [2/3] ARCHIVED / DISABLED SKILLS FOLDER
echo       Where inactive skills will be parked on disk at 0 context tokens.
echo       [Press ENTER to default to: %SCRIPT_DIR%skills_archive]
echo.
set "INP_DIS="
set /p "INP_DIS=Enter path for Archived Skills (or press ENTER): "
if not defined INP_DIS set "INP_DIS=%SCRIPT_DIR%skills_archive"
set "INP_DIS=!INP_DIS:"=!"

echo.
echo [3/3] BACKUP FOLDER
echo       Where active skills will be mirrored safely using Robocopy.
echo       [Press ENTER to default to: %SCRIPT_DIR%skills_backup]
echo.
set "INP_BAK="
set /p "INP_BAK=Enter path for Backup (or press ENTER): "
if not defined INP_BAK set "INP_BAK=%SCRIPT_DIR%skills_backup"
set "INP_BAK=!INP_BAK:"=!"

:: Create folders if they do not exist
if not exist "!INP_ACT!" mkdir "!INP_ACT!" 2>nul
if not exist "!INP_DIS!" mkdir "!INP_DIS!" 2>nul
if not exist "!INP_BAK!" mkdir "!INP_BAK!" 2>nul

:: Set in-memory variables immediately
set "ACTIVE_DIR=!INP_ACT!"
set "DISABLED_DIR=!INP_DIS!"
set "BACKUP_DIR=!INP_BAK!"

:: Save configuration
(
    echo :: Antigravity Skills Manager Configuration File
    echo :: Auto-generated on %DATE% %TIME%
    echo set "ACTIVE_DIR=!INP_ACT!"
    echo set "DISABLED_DIR=!INP_DIS!"
    echo set "BACKUP_DIR=!INP_BAK!"
) > "%CONFIG_FILE%"

echo.
echo ==============================================================================
echo [SUCCESS] Configuration saved to skills_config.cfg!
echo ==============================================================================
echo   Active Folder   : !INP_ACT!
echo   Archived Folder : !INP_DIS!
echo   Backup Folder   : !INP_BAK!
echo ==============================================================================
echo.
pause

:: Reload variables
for /f "usebackq eol=: delims=" %%L in ("%CONFIG_FILE%") do %%L
goto :menu

:list_skills
cls
echo ==============================================================================
echo                      CURRENT SKILLS STATUS ^& OVERVIEW
echo ==============================================================================
echo ACTIVE SKILLS [Loaded in memory - Consuming context tokens]:
echo ------------------------------------------------------------------------------
set count=0
for /d %%D in ("!ACTIVE_DIR!\*") do (
    if exist "%%~fD\SKILL.md" (
        set /a count+=1
        echo   [!count!] %%~nxD
    )
)
if !count!==0 echo   (No active skills found)
echo.
echo ARCHIVED SKILLS [Stored on disk - Consuming 0 tokens]:
echo ------------------------------------------------------------------------------
set count=0
for /d %%D in ("!DISABLED_DIR!\*") do (
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
echo Source: %SUMMARY_FILE%
echo ==============================================================================
echo Available Skills:
echo ------------------------------------------------------------------------------
set count=0
for /d %%D in ("!ACTIVE_DIR!\*") do (
    if exist "%%~fD\SKILL.md" (
        set /a count+=1
        set "ALL_!count!=%%~nxD"
        echo   [!count!] %%~nxD  [Active]
    )
)
for /d %%D in ("!DISABLED_DIR!\*") do (
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
    echo [ERROR] %SUMMARY_FILE% does not exist.
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
for /d %%D in ("!ACTIVE_DIR!\*") do (
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

if exist "!DISABLED_DIR!\!TARGET!" (
    echo [WARNING] "!TARGET!" already exists in Archived folder.
    set "REPLACE="
    set /p "REPLACE=Overwrite / replace it? [Y/N]: "
    if /i not "!REPLACE!"=="Y" (
        echo [CANCELLED] Move cancelled.
        call :log_transaction "DISABLE" "Move of '!TARGET!' cancelled by user" "CANCELLED"
        pause
        goto :menu
    )
    rd /s /q "!DISABLED_DIR!\!TARGET!"
)

move "!ACTIVE_DIR!\!TARGET!" "!DISABLED_DIR!\" >nul
if exist "!DISABLED_DIR!\!TARGET!" (
    echo [SUCCESS] "!TARGET!" is now archived [0 tokens].
    call :log_transaction "DISABLE" "Moved '!TARGET!' from active to archive" "SUCCESS"
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
for /d %%D in ("!DISABLED_DIR!\*") do (
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

if exist "!ACTIVE_DIR!\!TARGET!" (
    echo [WARNING] "!TARGET!" already exists in Active folder.
    set "REPLACE="
    set /p "REPLACE=Overwrite / replace it? [Y/N]: "
    if /i not "!REPLACE!"=="Y" (
        echo [CANCELLED] Move cancelled.
        call :log_transaction "ENABLE" "Move of '!TARGET!' cancelled by user" "CANCELLED"
        pause
        goto :menu
    )
    rd /s /q "!ACTIVE_DIR!\!TARGET!"
)

move "!DISABLED_DIR!\!TARGET!" "!ACTIVE_DIR!\" >nul
if exist "!ACTIVE_DIR!\!TARGET!" (
    echo [SUCCESS] "!TARGET!" is now active.
    call :log_transaction "ENABLE" "Moved '!TARGET!' from archive to active" "SUCCESS"
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
set "SUBSKILLS=unique-webapp-design-patterns threejs human-centric-web-design taste-skill awesome-design-md theme-factory image-to-code web-artifacts-builder web-design-guidelines canvas-design algorithmic-art ux_ui_research"

set moved_count=0
for %%S in (%SUBSKILLS%) do (
    if exist "!ACTIVE_DIR!\%%S" (
        if exist "!DISABLED_DIR!\%%S" rd /s /q "!DISABLED_DIR!\%%S"
        move "!ACTIVE_DIR!\%%S" "!DISABLED_DIR!\" >nul
        if exist "!DISABLED_DIR!\%%S" (
            echo   [-] Archived: %%S
            call :log_transaction "DISABLE_WEB" "Moved '%%S' from active to archive" "SUCCESS"
            set /a moved_count+=1
        ) else (
            echo   [!] Error moving: %%S
            call :log_transaction "DISABLE_WEB" "Failed moving '%%S' to archive" "FAILED"
        )
    )
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
for /d %%D in ("!DISABLED_DIR!\*") do (
    if exist "%%~fD\SKILL.md" (
        set "SKILLNAME=%%~nxD"
        if exist "!ACTIVE_DIR!\!SKILLNAME!" (
            rd /s /q "!ACTIVE_DIR!\!SKILLNAME!"
        )
        move "%%~fD" "!ACTIVE_DIR!\" >nul
        if exist "!ACTIVE_DIR!\!SKILLNAME!" (
            echo   [+] Activated: !SKILLNAME!
            call :log_transaction "ENABLE_ALL" "Moved '!SKILLNAME!' from archive to active" "SUCCESS"
            set /a count+=1
        ) else (
            echo   [!] Error moving: !SKILLNAME!
            call :log_transaction "ENABLE_ALL" "Failed moving '!SKILLNAME!' to active" "FAILED"
        )
    )
)
echo.
echo ==============================================================================
if !count!==0 echo No archived skills found.
echo [DONE] All skills moved to Active folder. [!count! activated]
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
    echo [ERROR] %SUMMARY_FILE% not found.
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
