@echo off
setlocal enabledelayedexpansion
REM ============================================
REM SCMCIES APP - Application Launcher
REM ============================================
cls
echo.
echo.
echo    ====================================
echo    SCMCIES APPLICATION LAUNCHER
echo    ====================================
echo.

REM Get the app directory
set "APP_DIR=%~dp0"
set "BACKEND_DIR=%APP_DIR%backend"

echo    Current Directory: %APP_DIR%
echo.

REM Check if backend folder exists
if not exist "%BACKEND_DIR%" (
    echo    ❌ ERROR: Backend folder not found!
    echo    Expected: %BACKEND_DIR%
    echo.
    pause
    exit /b 1
)

echo    [1/3] Checking Python installation...
where python >nul 2>&1
if errorlevel 1 (
    echo    ❌ ERROR: Python is not installed or not in PATH
    echo    Please install Python 3.8+ and add it to PATH
    echo.
    pause
    exit /b 1
)
echo    ✅ Python found
echo.

echo    [2/3] Starting Backend Server...
cd /d "%BACKEND_DIR%"
start "" cmd /k python -m uvicorn main:app --host 0.0.0.0 --port 8000

REM Wait for server to start
timeout /t 5 /nobreak

echo.
echo    [3/3] Opening Application in Browser...
start http://172.21.244.38:8000

cd /d "%APP_DIR%"

echo.
echo    ====================================
echo    ✅ APPLICATION LAUNCHED!
echo    ====================================
echo.
echo    The app is now opening in your browser.
echo.
echo    LOGIN WITH YOUR ACCOUNT:
echo    - If you are ADMIN → Auto to ADMIN DASHBOARD
echo    - If you are PARENT → Auto to PARENT DASHBOARD
echo.
echo    Backend is running in the command window above.
echo    Keep it open while using the app!
echo.
echo    ====================================
echo.
