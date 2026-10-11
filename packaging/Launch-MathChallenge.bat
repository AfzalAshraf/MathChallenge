@echo off
rem -------------------------------------------------------------------------
rem  Fallback launcher for Cognitive Trainer (MathChallenge).
rem  Prefer MathChallenge.exe when it sits next to this file. This runs the
rem  .ps1 through Windows PowerShell instead, which is useful when the .exe is
rem  blocked or you want to read an error message.
rem  Deliberately uses no labels and no multi-line blocks: those are the two
rem  constructs that break if the file ever ends up with LF line endings.
rem -------------------------------------------------------------------------
setlocal
set "SCRIPT=%~dp0MathChallenge.ps1"

if not exist "%SCRIPT%" (echo [MathChallenge] MathChallenge.ps1 was not found next to this launcher: & echo   %SCRIPT% & echo Extract the whole zip into one folder, then try again. & pause & exit /b 1)

where powershell.exe >nul 2>nul || (echo [MathChallenge] Windows PowerShell was not found on this system. & pause & exit /b 1)

start "Cognitive Trainer" powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%SCRIPT%"
endlocal
exit /b 0
