@echo off
title JET IDE Setup

echo Starting JET IDE GUI Installer...

:: Check if PowerShell is available
powershell -Command "Write-Host 'PowerShell is available'" >nul 2>&1
if errorlevel 1 (
    echo Error: PowerShell is required but not available.
    echo Please install PowerShell and try again.
    pause
    exit /b 1
)

:: Run the GUI installer
powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0gui-installer.ps1"

if errorlevel 1 (
    echo Installation failed or was cancelled.
    pause
) else (
    echo Installation completed successfully!
)

exit /b 0