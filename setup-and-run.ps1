#!/usr/bin/env powershell

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "SCMCIES System Setup and Start" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1/5] Setting up database..." -ForegroundColor Green
Write-Host "Running: mysql with schema file" -ForegroundColor Gray

$mysqlPath = Get-Command mysql -ErrorAction SilentlyContinue
if ($mysqlPath) {
    $schemaFile = Join-Path (Get-Location) "backend-node\schema.sql"
    & cmd /c "mysql -u root < `"$schemaFile`""
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Database setup completed" -ForegroundColor Green
    } else {
        Write-Host "Database may already exist or MySQL needs password" -ForegroundColor Yellow
    }
} else {
    Write-Host "MySQL not found in PATH" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "[2/5] Configuring environment files..." -ForegroundColor Green

$envConfigs = @(
    "backend-node",
    "frontend",
    "mini_pc_client"
)

foreach ($folder in $envConfigs) {
    $envFile = Join-Path $folder ".env"
    $exampleFile = Join-Path $folder ".env.example"
    
    if (-not (Test-Path $envFile)) {
        if (Test-Path $exampleFile) {
            Copy-Item -Path $exampleFile -Destination $envFile
            Write-Host "Created $folder\.env" -ForegroundColor Green
        }
    } else {
        Write-Host "Using existing $folder\.env" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "[3/5] Installing dependencies..." -ForegroundColor Green

Push-Location backend-node
Write-Host "Installing backend dependencies..." -ForegroundColor Gray
npm install --silent
Pop-Location

Write-Host ""
Push-Location frontend
Write-Host "Installing frontend dependencies..." -ForegroundColor Gray
npm install --silent
Pop-Location

Write-Host ""
Push-Location mini_pc_client
Write-Host "Installing Mini PC dependencies..." -ForegroundColor Gray
$pythonPath = Get-Command python -ErrorAction SilentlyContinue
if ($pythonPath) {
    python -m pip install -q -r requirements.txt 2>&1 | Out-Null
}
Pop-Location

Write-Host ""
Write-Host "[4/5] Seeding initial admin account..." -ForegroundColor Green

Push-Location backend-node
Write-Host "Running: node seed.js" -ForegroundColor Gray
node seed.js
$seedExitCode = $LASTEXITCODE
Pop-Location
if ($seedExitCode -ne 0) {
    Write-Host "Configure unique credentials in backend-node\.env before using the application." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "[5/5] Starting all services..." -ForegroundColor Green
Write-Host ""

$currentDir = Get-Location
$backendCmd = "cd /d `"$currentDir\backend-node`" && npm start"
$frontendCmd = "cd /d `"$currentDir\frontend`" && npm start"
$minipcCmd = "cd /d `"$currentDir\mini_pc_client`" && python main.py"

Write-Host "Starting Backend Server..." -ForegroundColor Cyan
Start-Process cmd -ArgumentList "/k", $backendCmd

Start-Sleep -Seconds 2

Write-Host "Starting Frontend..." -ForegroundColor Cyan
Start-Process cmd -ArgumentList "/k", $frontendCmd

Start-Sleep -Seconds 2

Write-Host "Starting Mini PC Face Recognition..." -ForegroundColor Cyan
Start-Process cmd -ArgumentList "/k", $minipcCmd

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Setup Complete" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Services started:" -ForegroundColor Cyan
Write-Host "  Backend API:    http://localhost:8000" -ForegroundColor White
Write-Host "  Frontend:       http://localhost:3000" -ForegroundColor White
Write-Host "  Mini PC Client: Running" -ForegroundColor White
Write-Host ""
Write-Host "Configure unique administrator and parent credentials in backend-node\.env." -ForegroundColor Yellow
Write-Host ""
