# ============================================
# SCMCIES APP - Desktop Shortcut Creator
# ============================================
# Run as Administrator: Right-click > Run with PowerShell

$appPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$desktopPath = [System.Environment]::GetFolderPath("Desktop")

Write-Host "Creating Desktop Shortcut for SCMCIES App..." -ForegroundColor Green
Write-Host ""

# Create Main Application Shortcut
$launcherBatchFile = "$appPath\LAUNCH_SCMCIES.bat"
$shortcutPath = "$desktopPath\SCMCIES App.lnk"

if (Test-Path $launcherBatchFile) {
    $WshShell = New-Object -ComObject WScript.Shell
    $shortcut = $WshShell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $launcherBatchFile
    $shortcut.WorkingDirectory = $appPath
    $shortcut.Description = "Launch SCMCIES Application"
    $shortcut.IconLocation = "C:\Windows\System32\shell32.dll,15"
    $shortcut.WindowStyle = 1
    $shortcut.Save()
    Write-Host "✅ Created: $shortcutPath" -ForegroundColor Green
} else {
    Write-Host "❌ Error: $launcherBatchFile not found!" -ForegroundColor Red
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "Shortcut created successfully!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Desktop Shortcut:" -ForegroundColor Yellow
Write-Host "  • SCMCIES App.lnk" -ForegroundColor Cyan
Write-Host ""
Write-Host "Instructions:" -ForegroundColor Yellow
Write-Host "  1. Double-click 'SCMCIES App' on your Desktop" -ForegroundColor White
Write-Host "  2. Wait for the application to open" -ForegroundColor White
Write-Host "  3. Login with your account" -ForegroundColor White
Write-Host "  4. You will automatically go to your dashboard:" -ForegroundColor White
Write-Host "     - Admin users → Admin Dashboard" -ForegroundColor Cyan
Write-Host "     - Parent users → Parent Dashboard" -ForegroundColor Cyan
Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Read-Host "Press Enter to close"
