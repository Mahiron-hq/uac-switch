@echo off
rem Turns UAC off and restarts Windows. UAC-On.bat reverts the change.
setlocal
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "%~dp0Set-UacMode.ps1" -Mode Disabled -Restart
set "rc=%errorlevel%"
if not "%rc%"=="0" pause
exit /b %rc%
