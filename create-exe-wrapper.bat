@echo off
echo Creating JET IDE Executable Installer
echo ===================================

:: Create a temporary directory
if not exist temp mkdir temp

:: Create a VBScript to convert the batch file to an executable
echo Creating VBScript converter...
echo Set oWS = WScript.CreateObject("WScript.Shell") > temp\convert.vbs
echo sLinkFile = "%CD%\JET-IDE-Installer.exe" >> temp\convert.vbs
echo Set oLink = oWS.CreateShortcut(sLinkFile) >> temp\convert.vbs
echo oLink.TargetPath = "%CD%\fixed-installer.bat" >> temp\convert.vbs
echo oLink.IconLocation = "%CD%\JET.App\Resources\Icons\jet-icon.ico" >> temp\convert.vbs
echo oLink.Description = "JET IDE Installer" >> temp\convert.vbs
echo oLink.WorkingDirectory = "%CD%" >> temp\convert.vbs
echo oLink.Save >> temp\convert.vbs

:: Run the VBScript to create the shortcut
echo Creating executable shortcut...
cscript //nologo temp\convert.vbs

:: Clean up
rmdir /S /Q temp

if exist JET-IDE-Installer.exe (
    echo.
    echo JET-IDE-Installer.exe created successfully.
    echo This executable will run the installer when double-clicked.
) else (
    echo.
    echo Failed to create JET-IDE-Installer.exe
    exit /b 1
)

echo.
echo Process completed successfully.
echo.