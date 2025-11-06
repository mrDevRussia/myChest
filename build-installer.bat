@echo off
echo Building JET IDE Installer...

:: Check if NSIS is installed
where makensis >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo NSIS is not installed or not in PATH. Please install NSIS from https://nsis.sourceforge.io/Download
    pause
    exit /b 1
)

:: Build the .NET application first
echo Building JET.App...
dotnet build JET.App\JET.App.csproj -c Release
if %ERRORLEVEL% neq 0 (
    echo Failed to build JET.App
    pause
    exit /b 1
)

:: Create the installer
echo Creating installer...
makensis JET-Installer.nsi
if %ERRORLEVEL% neq 0 (
    echo Failed to create installer
    pause
    exit /b 1
)

echo.
echo JET-IDE-Setup.exe has been created successfully!
echo.

pause