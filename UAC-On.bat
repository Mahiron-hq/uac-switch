@echo off
rem Restores the UAC settings saved by UAC-Off.bat and restarts Windows if needed.
setlocal
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "%~dp0Set-UacMode.ps1" -Mode Restore -Restart
set "rc=%errorlevel%"
if not "%rc%"=="0" pause
exit /b %rc%
