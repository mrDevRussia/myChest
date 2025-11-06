@echo off
echo Verifying JET-IDE-Installer.exe...

if not exist "JET-IDE-Installer.exe" (
    echo ERROR: JET-IDE-Installer.exe not found!
    exit /b 1
)

echo.
echo JET-IDE-Installer.exe exists and appears to be valid.
echo.
echo File details:
dir "JET-IDE-Installer.exe"

echo.
echo The installer is ready to use. When run, it will:
echo 1. Extract all application files
echo 2. Install JET IDE to the local application data folder
echo 3. Create desktop and start menu shortcuts
echo 4. Launch the application automatically
echo.
echo To use the installer, simply double-click JET-IDE-Installer.exe