@echo off
REM SCMCIES Complete Setup and Start Script
REM Run this as Administrator

setlocal enabledelayedexpansion

cls
echo.
echo ================================================
echo SCMCIES System Setup and Start
echo ================================================
echo.

REM Step 1: Setup Database
echo [1/5] Setting up database...
if exist "backend-node\schema.sql" (
    mysql -u root < "backend-node\schema.sql"
    if errorlevel 0 (
        echo Database setup completed
    ) else (
        echo Database may already exist or MySQL needs password
    )
) else (
    echo schema.sql not found
)

echo.

REM Step 2: Configure .env files
echo [2/5] Configuring environment files...

if not exist "backend-node\.env" (
    if exist "backend-node\.env.example" (
        copy "backend-node\.env.example" "backend-node\.env" >nul
        echo Created backend-node\.env
    )
)

if not exist "frontend\.env" (
    if exist "frontend\.env.example" (
        copy "frontend\.env.example" "frontend\.env" >nul
        echo Created frontend\.env
    )
)

if not exist "mini_pc_client\.env" (
    if exist "mini_pc_client\.env.example" (
        copy "mini_pc_client\.env.example" "mini_pc_client\.env" >nul
        echo Created mini_pc_client\.env
    )
)

echo.

REM Step 3: Install Dependencies
echo [3/5] Installing dependencies...

echo Installing backend dependencies...
cd backend-node
if exist "package.json" (
    call npm install --silent >nul 2>&1
)
cd ..

echo Installing frontend dependencies...
cd frontend
if exist "package.json" (
    call npm install --silent >nul 2>&1
)
cd ..

echo Installing Mini PC dependencies...
cd mini_pc_client
if exist "requirements.txt" (
    python -m pip install -q -r requirements.txt >nul 2>&1
)
cd ..

echo.

REM Step 4: Seed Database
echo [4/5] Seeding initial admin account...

cd backend-node
if exist "seed.js" (
    call node seed.js
    if errorlevel 1 (
        echo Configure unique account credentials in backend-node\.env, then run this step again.
    )
)
cd ..

echo.

REM Step 5: Start Services
echo [5/5] Starting all services...
echo.

echo Starting Backend Server...
start "Backend API - http://localhost:8000" cmd /k "cd backend-node && npm start"

timeout /t 2 /nobreak

echo Starting Frontend...
start "Frontend - http://localhost:3000" cmd /k "cd frontend && npm start"

timeout /t 2 /nobreak

echo Starting Mini PC Face Recognition...
start "Mini PC Client" cmd /k "cd mini_pc_client && python main.py"

echo.
echo ================================================
echo Setup Complete
echo ================================================
echo.
echo Services started:
echo   Backend API:    http://localhost:8000
echo   Frontend:       http://localhost:3000
echo   Mini PC Client: Running
echo.
echo Configure unique administrator and parent credentials in backend-node\.env.
echo.
echo Close any window to stop that service.
echo.

endlocal
