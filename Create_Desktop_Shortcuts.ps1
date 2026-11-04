
# ============================================
# SCMCIES APP - Desktop Shortcut Creator
# ============================================
# Run as Administrator: Right-click > Run with PowerShell

$appPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$desktopPath = [System.Environment]::GetFolderPath("Desktop")

Write-Host "Creating Desktop Shortcuts for SCMCIES App..." -ForegroundColor Green
Write-Host ""

# Create Admin Shortcut
$adminBatchFile = "$appPath\LAUNCH_APP_ADMIN.bat"
$adminShortcutPath = "$desktopPath\SCMCIES App - Admin.lnk"

if (Test-Path $adminBatchFile) {
    $WshShell = New-Object -ComObject WScript.Shell
    $shortcut = $WshShell.CreateShortcut($adminShortcutPath)
    $shortcut.TargetPath = $adminBatchFile
    $shortcut.WorkingDirectory = $appPath
    $shortcut.Description = "Launch SCMCIES App (Admin)"
    $shortcut.IconLocation = "C:\Windows\System32\shell32.dll,2"
    $shortcut.WindowStyle = 1
    $shortcut.Save()
    Write-Host "✅ Created: $adminShortcutPath" -ForegroundColor Green
} else {
    Write-Host "❌ Error: $adminBatchFile not found!" -ForegroundColor Red
}

Write-Host ""

# Create Parent Shortcut
$parentBatchFile = "$appPath\LAUNCH_APP_PARENT.bat"
$parentShortcutPath = "$desktopPath\SCMCIES App - Parent.lnk"

if (Test-Path $parentBatchFile) {
    $WshShell = New-Object -ComObject WScript.Shell
    $shortcut = $WshShell.CreateShortcut($parentShortcutPath)
    $shortcut.TargetPath = $parentBatchFile
    $shortcut.WorkingDirectory = $appPath
    $shortcut.Description = "Launch SCMCIES App (Parent)"
    $shortcut.IconLocation = "C:\Windows\System32\shell32.dll,3"
    $shortcut.WindowStyle = 1
    $shortcut.Save()
    Write-Host "✅ Created: $parentShortcutPath" -ForegroundColor Green
} else {
    Write-Host "❌ Error: $parentBatchFile not found!" -ForegroundColor Red
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "Shortcuts created successfully!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "You can now find these shortcuts on your Desktop:" -ForegroundColor Yellow
Write-Host "  • SCMCIES App - Admin.lnk" -ForegroundColor Cyan
Write-Host "  • SCMCIES App - Parent.lnk" -ForegroundColor Cyan
Write-Host ""
Write-Host "Double-click any shortcut to launch the application!" -ForegroundColor Yellow
Write-Host ""
Read-Host "Press Enter to close"
