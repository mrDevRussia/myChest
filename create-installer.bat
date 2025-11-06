@echo off
echo Creating JET IDE Installer...

:: Check if NSIS is installed
where makensis >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo NSIS is not installed or not in PATH.
    echo Please install NSIS from https://nsis.sourceforge.io/Download
    exit /b 1
)

:: Run NSIS script
makensis JET-Installer.nsi

if %ERRORLEVEL% neq 0 (
    echo Failed to create installer.
    exit /b 1
) else (
    echo Installer created successfully: JET-IDE-Setup.exe
)