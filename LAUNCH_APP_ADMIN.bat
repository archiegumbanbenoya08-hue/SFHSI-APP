@echo off
REM ============================================
REM SCMCIES APP - Admin Launch Shortcut
REM ============================================
cls
echo.
echo Starting SCMCIES Application...
echo.

REM Start Backend Server
cd /d "%~dp0backend"
echo Starting Backend Server...
start /B pythonw -m uvicorn main:app --host 0.0.0.0 --port 8000

REM Wait for server to start
timeout /t 3 /nobreak

REM Open Application in Browser
echo Opening Application...
start http://172.21.244.38:8000

REM Return to parent directory
cd /d "%~dp0"

echo.
echo ✅ Application launched!
echo.
echo Use the administrator account configured for this deployment.
echo Do not use shared or default credentials.
echo.
pause
