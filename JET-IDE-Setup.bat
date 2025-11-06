@echo off
title JET IDE Setup
color 0A

echo ===================================
echo       JET IDE Setup Launcher
echo ===================================
echo.
echo Welcome to the JET IDE Setup.
echo.
echo This launcher will start the JET IDE installation process.
echo.
echo Press any key to continue...
pause > nul

:: Run the actual setup script
call "%~dp0simple-setup.bat"

exit /b 0