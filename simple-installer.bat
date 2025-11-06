@echo off
echo JET IDE Simple Installer
echo =====================

:: Set installation directory
set INSTALL_DIR=%USERPROFILE%\Desktop\JET-IDE

:: Create installation directory
echo Creating installation directory...
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

:: Copy all files
echo Copying JET IDE files...
xcopy /E /I /Y JET.App "%INSTALL_DIR%\JET.App\"
xcopy /Y LICENSE "%INSTALL_DIR%\"
xcopy /Y README.md "%INSTALL_DIR%\"
xcopy /Y PACKAGING.md "%INSTALL_DIR%\"

:: Create shortcut on desktop
echo Creating desktop shortcut...

powershell -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%USERPROFILE%\Desktop\JET IDE.lnk'); $Shortcut.TargetPath = '%INSTALL_DIR%\JET.App\JET.exe'; $Shortcut.IconLocation = '%INSTALL_DIR%\JET.App\Resources\Icons\jet-icon.ico'; $Shortcut.Save()"

echo.
echo JET IDE has been installed to: %INSTALL_DIR%
echo A shortcut has been created on your desktop.
echo.
echo Press any key to exit...
pause > nul