@echo off
REM ====================================================
REM SCMCIES - Complete Setup & Launch Script
REM ====================================================

echo.
echo 🚀 SCMCIES Application - Complete Setup
echo ====================================================
echo.

REM Check Flask installation
python --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Python is not installed!
    pause
    exit /b 1
)

echo ✅ Python installed
echo.

REM Step 1: Build Flutter
echo 📦 STEP 1: Building Flutter App for Web...
echo.
if exist "build\web\index.html" (
    echo ✅ Flutter web build already exists
) else (
    echo 🔨 Building Flutter...
    call flutter build web --release
    if errorlevel 1 (
        echo ❌ Flutter build failed!
        pause
        exit /b 1
    )
    echo ✅ Flutter build completed!
)
echo.

REM Step 2: Start Backend
echo 🔧 STEP 2: Starting Backend Server...
echo.
cd backend

REM Check if python venv exists
if not exist "venv" (
    echo 📦 Creating Python virtual environment...
    python -m venv venv
    echo ✅ Virtual environment created
)

REM Activate venv and install deps
echo 🔌 Activating virtual environment...
call venv\Scripts\activate.bat

echo 📥 Installing dependencies...
pip install -q -r requirements.txt

echo.
echo 🎉 Starting FastAPI Backend Server...
echo ==========================================
echo.
echo 🌐 Your Application is Now Available At:
echo.
echo    ➜  http://172.21.244.38:8000/
echo.
echo 📖 API Documentation at:
echo    ➜  http://172.21.244.38:8000/docs
echo.
echo ⏸️  Press Ctrl+C to stop the server
echo ==========================================
echo.

REM Start the app
python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload

pause
