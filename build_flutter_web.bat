@echo off
REM ====================================================
REM SCMCIES Flutter App Build and Deploy for Web
REM ====================================================

echo.
echo 🚀 SCMCIES Flutter Web App Builder
echo ====================================================
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

REM Check if we're in the right directory
if not exist "pubspec.yaml" (
    echo ❌ pubspec.yaml not found in current directory
    echo Please run this script from the SCMCIES APP root directory
    pause
    exit /b 1
)

echo.
echo 📦 Building Flutter Web Application...
echo This may take 2-5 minutes on first build...
echo.

REM Build for web
flutter build web --release

if errorlevel 1 (
    echo ❌ Build failed!
    pause
    exit /b 1
)

echo.
echo ✅ Build completed successfully!
echo.
echo 📂 Built files location: build/web
echo.
echo Next steps:
echo 1. Make sure the backend server is running (backend/run.bat)
echo 2. Open browser: http://172.21.244.38:8000/
echo 3. Your Flutter app will load automatically!
echo.
pause
