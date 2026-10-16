@echo off
rem Keeps UAC enabled but elevates administrators without a prompt. UAC-Silent-Off.bat reverts the change.
setlocal
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "%~dp0Set-UacMode.ps1" -Mode NoPrompt -Restart
set "rc=%errorlevel%"
if not "%rc%"=="0" pause
exit /b %rc%
