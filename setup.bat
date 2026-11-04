@echo off
setlocal enabledelayedexpansion

echo ================================================
echo SCMCIES System Setup - Windows
echo ================================================
echo.

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
echo Seeding initial data...
node seed.js
cd ..

REM Frontend setup
echo.
echo [2/5] Setting up Frontend...
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
echo [3/5] Setting up Mini PC Client...
cd mini_pc_client
if not exist .env (
    echo Creating .env file from .env.example...
    copy .env.example .env
)
echo Please ensure dlib is installed with CMake and Visual Studio Build Tools
echo Instructions: Read README.md Mini PC Setup section
cd ..

echo.
echo [4/5] Database Setup Instructions...
echo.
echo To set up the database, run:
echo   mysql -u root < backend-node\schema.sql
echo.
echo If you have set a MySQL password, use:
echo   mysql -u root -p < backend-node\schema.sql
echo.

echo.
echo [5/5] Configuration Instructions...
echo.
echo Please edit the following .env files with your configuration:
echo.
echo   1. backend-node\.env
echo      - Set your MySQL password
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
echo   2. Run: mysql -u root ^< backend-node\schema.sql
echo   3. Run: start-all.bat (to start all services)
echo.
echo For detailed instructions, see README.md
echo ================================================

pause
