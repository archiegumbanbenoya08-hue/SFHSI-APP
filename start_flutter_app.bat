@echo off
REM ==========================================
REM SCMCIES Flutter App - Windows Launcher
REM ==========================================

echo.
echo 🚀 SCMCIES Flutter Application
echo ==========================================
echo.

REM Check if Flutter is installed
flutter --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Flutter is not installed or not in PATH
    echo Please install Flutter from https://flutter.dev/docs/get-started/install
    pause
    exit /b 1
)

echo ✅ Flutter found:
flutter --version
echo.

echo 📱 Select a target device...
echo.
flutter devices
echo.

echo 🎉 Starting Flutter Application...
echo.
echo ⚠️  Make sure the backend server is running!
echo    See backend/run.bat for backend server startup
echo.
echo Choose target:
echo  1. Windows
echo  2. Chrome (Web)
echo  3. Custom (type device name)
echo.

set /p choice="Enter your choice (1/2/3): "

if "%choice%"=="1" (
    echo Launching on Windows...
    flutter run -d windows
) else if "%choice%"=="2" (
    echo Launching on Chrome...
    flutter run -d chrome
) else (
    echo Launching on custom device: %choice%
    flutter run -d %choice%
)

pause
