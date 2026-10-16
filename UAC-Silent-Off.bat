@echo off
rem Restores the UAC settings saved before UAC-Silent-On.bat was first run.
setlocal
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "%~dp0Set-UacMode.ps1" -Mode Restore -Restart
set "rc=%errorlevel%"
if not "%rc%"=="0" pause
exit /b %rc%
