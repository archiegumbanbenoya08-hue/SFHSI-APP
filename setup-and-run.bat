@echo off
REM SCMCIES Complete Setup and Start Script
REM Docker Desktop must be running before starting local Supabase.

setlocal enabledelayedexpansion

cls
echo.
echo ================================================
echo SCMCIES System Setup and Start
echo ================================================
echo.

REM Step 1: Start local Supabase
echo [1/5] Starting local Supabase...
call npx --yes supabase start
if errorlevel 1 (
    echo Failed to start Supabase. Start Docker Desktop and run this script again.
    pause
    exit /b 1
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

if not exist "backend-fastapi\.env" (
    if exist "backend-fastapi\.env.example" (
        copy "backend-fastapi\.env.example" "backend-fastapi\.env" >nul
        echo Created backend-fastapi\.env
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

echo Installing FastAPI dependencies...
cd backend-fastapi
if exist "requirements.txt" (
    python -m pip install -q -r requirements.txt
    if errorlevel 1 (
        echo Failed to install FastAPI dependencies
        pause
        exit /b 1
    )
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

REM Step 4: Keep target empty for an optional migration.
echo [4/5] Database is ready.
echo If migrating MySQL data, do that before running node seed.js.

echo.

REM Step 5: Start Services
echo [5/5] Starting all services...
echo.

echo Starting Backend Server...
start "Backend API - http://localhost:8000" cmd /k "cd backend-node && npm start"

timeout /t 2 /nobreak

echo Starting FastAPI Server...
start "FastAPI - http://localhost:8001" cmd /k "cd backend-fastapi && python -m uvicorn main:app --host 0.0.0.0 --port 8001"

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
echo   Supabase Studio: http://localhost:54323
echo   Backend API:    http://localhost:8000
echo   FastAPI:        http://localhost:8001
echo   Frontend:       http://localhost:3000
echo   Mini PC Client: Running
echo.
echo Configure unique administrator and parent credentials in backend-node\.env.
echo If no data was migrated, run: cd backend-node ^&^& node seed.js
echo.
echo Close any window to stop that service.
echo.

endlocal
