@echo off
setlocal enabledelayedexpansion

echo ================================================
echo SCMCIES System Setup - Windows
echo ================================================
echo.

echo [0/5] Starting local Supabase...
call npx --yes supabase start
if !errorlevel! neq 0 (
    echo Failed to start Supabase. Start Docker Desktop and run this script again.
    pause
    exit /b 1
)

REM Backend setup
echo [1/5] Setting up Backend...
cd backend-node
if not exist .env (
    echo Creating .env file from .env.example...
    copy .env.example .env
)
echo Installing backend dependencies...
call npm install
if !errorlevel! neq 0 (
    echo Failed to install backend dependencies
    pause
    exit /b 1
)
cd ..

REM FastAPI setup
echo.
echo [2/6] Setting up FastAPI...
cd backend-fastapi
if not exist .env (
    echo Creating .env file from .env.example...
    copy .env.example .env
)
echo Installing FastAPI dependencies...
python -m pip install -r requirements.txt
if !errorlevel! neq 0 (
    echo Failed to install FastAPI dependencies
    pause
    exit /b 1
)
cd ..

REM Frontend setup
echo.
echo [3/6] Setting up Frontend...
cd frontend
if not exist .env (
    echo Creating .env file from .env.example...
    copy .env.example .env
)
echo Installing frontend dependencies...
call npm install
if !errorlevel! neq 0 (
    echo Failed to install frontend dependencies
    pause
    exit /b 1
)
cd ..

REM Mini PC setup
echo.
echo [4/6] Setting up Mini PC Client...
cd mini_pc_client
if not exist .env (
    echo Creating .env file from .env.example...
    copy .env.example .env
)
echo Please ensure dlib is installed with CMake and Visual Studio Build Tools
echo Instructions: Read README.md Mini PC Setup section
cd ..

echo.
echo [5/6] Database Setup Instructions...
echo.
echo Supabase is running at http://localhost:54323

echo.
echo [6/6] Configuration Instructions...
echo.
echo Please edit the following .env files with your configuration:
echo.
echo   1. backend-node\.env
echo      - Set DATABASE_URL and secure JWT/device secrets
echo      - Set your Gmail credentials
echo      - Generate secure JWT secrets
echo.
echo   2. mini_pc_client\.env
echo      - Set API_URL (default: http://localhost:8000)
echo      - Set DEVICE_API_KEY (must match backend)
echo.
echo   3. frontend\.env (optional)
echo      - REACT_APP_API_URL defaults to http://localhost:8000/api
echo.

echo ================================================
echo Setup Complete!
echo ================================================
echo.
echo Next steps:
echo   1. Edit configuration files (.env files)
echo   2. If migrating MySQL data, do that before seeding accounts
echo   3. Run: setup-and-run.bat (to start Supabase and all services)
echo.
echo For detailed instructions, see README.md
echo ================================================

pause
