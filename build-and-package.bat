@echo off
REM Batch file wrapper for the PowerShell packaging scripts
REM This allows users to run the packaging process with a double-click

echo =============================================
echo    JET IDE Build and Packaging Tool
echo =============================================
echo.

REM Check if PowerShell is available
where powershell >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo Error: PowerShell is not available on this system.
    echo Please install PowerShell to use the packaging scripts.
    echo.
    pause
    exit /b 1
)

REM Check if the main PowerShell script exists
if not exist "%~dp0build-and-package.ps1" (
    echo Error: build-and-package.ps1 not found.
    echo Please make sure all packaging scripts are in the same directory as this batch file.
    echo.
    pause
    exit /b 1
)

echo Starting the packaging process...
echo This will launch PowerShell to run the build-and-package.ps1 script.
echo The process includes:
echo  - Icon conversion
echo  - Building and publishing
echo  - Optional executable compression
echo  - Installer creation
echo  - Optional automatic updates setup
echo  - Package verification
echo  - Cleanup options
echo.

REM Run the PowerShell script with execution policy bypass
powershell.exe -ExecutionPolicy Bypass -File "%~dp0build-and-package.ps1"

if %ERRORLEVEL% neq 0 (
    echo.
    echo The packaging process encountered an error.
    echo Please check the output above for details.
) else (
    echo.
    echo The packaging process completed successfully.
)

echo.
echo Press any key to exit...
pause >nul