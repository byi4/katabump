@echo off
REM Katabump manual Chrome launcher (for debugging).
REM Uses the SAME profile directory as renew.js so a manually started instance
REM is recognised as the task's own Chrome instead of an "external instance".
setlocal

set "USER_DATA_DIR=%~dp0ChromeData_Katabump"

REM Chrome path: CHROME_PATH env first, then the usual install locations
REM (same probing order as renew.js).
if defined CHROME_PATH set "CHROME=%CHROME_PATH%"
if not defined CHROME set "CHROME=%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe"
if not exist "%CHROME%" set "CHROME=%ProgramFiles%\Google\Chrome\Application\chrome.exe"
if not exist "%CHROME%" set "CHROME=%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe"
if not exist "%CHROME%" (
    echo [ERROR] chrome.exe not found. Set CHROME_PATH or edit this script.
    pause
    exit /b 1
)

echo Chrome    : %CHROME%
echo User data : %USER_DATA_DIR%
echo.
echo Debug port 9222 will stay open until you close this window.
"%CHROME%" --remote-debugging-port=9222 --user-data-dir="%USER_DATA_DIR%"
