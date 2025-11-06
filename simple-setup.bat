@echo off
title JET IDE Setup Wizard
color 0A

echo ===================================
echo       JET IDE Setup Wizard
echo ===================================
echo.
echo Welcome to the JET IDE Setup Wizard.
echo This will install JET IDE on your computer.
echo.
echo Press any key to continue...
pause > nul

:: Set installation directory
set INSTALL_DIR=%LOCALAPPDATA%\JET IDE

:: Create installation directory if it doesn't exist
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

cls
echo ===================================
echo       JET IDE Setup Wizard
echo ===================================
echo.
echo Step 1 of 4: Copying application files...
echo.
xcopy /E /I /Y "JET.App" "%INSTALL_DIR%\JET.App" > nul
echo Application files copied successfully.

echo.
echo Step 2 of 4: Copying documentation...
echo.
if exist "LICENSE" copy "LICENSE" "%INSTALL_DIR%" > nul
if exist "README.md" copy "README.md" "%INSTALL_DIR%" > nul
if exist "INSTALL.md" copy "INSTALL.md" "%INSTALL_DIR%" > nul
if exist "PACKAGING.md" copy "PACKAGING.md" "%INSTALL_DIR%" > nul
echo Documentation copied successfully.

echo.
echo Step 3 of 4: Creating shortcuts...
echo.

:: Create the executable directory and placeholder batch file
set EXE_PATH=%INSTALL_DIR%\JET.App\bin\Release\net6.0-windows
if not exist "%EXE_PATH%" (
    mkdir "%EXE_PATH%" 2>nul
)

:: Create the JET.bat file
echo @echo off > "%EXE_PATH%\JET.bat"
echo cd "%EXE_PATH%" >> "%EXE_PATH%\JET.bat"
echo if exist JET.exe ( >> "%EXE_PATH%\JET.bat"
echo   start "" JET.exe >> "%EXE_PATH%\JET.bat"
echo ) else ( >> "%EXE_PATH%\JET.bat"
echo   title JET IDE >> "%EXE_PATH%\JET.bat"
echo   color 0A >> "%EXE_PATH%\JET.bat"
echo   echo ===================================== >> "%EXE_PATH%\JET.bat"
echo   echo              JET IDE >> "%EXE_PATH%\JET.bat"
echo   echo ===================================== >> "%EXE_PATH%\JET.bat"
echo   echo. >> "%EXE_PATH%\JET.bat"
echo   echo JET IDE would start here if built. >> "%EXE_PATH%\JET.bat"
echo   echo This is a placeholder since the actual executable hasn't been built. >> "%EXE_PATH%\JET.bat"
echo   echo. >> "%EXE_PATH%\JET.bat"
echo   pause >> "%EXE_PATH%\JET.bat"
echo ) >> "%EXE_PATH%\JET.bat"
echo echo Press any key to exit... >> "%EXE_PATH%\JET.bat"
echo pause ^> nul >> "%EXE_PATH%\JET.bat"
echo Created JET.bat placeholder file.

:: Create desktop shortcut
set SHORTCUT_JS=%TEMP%\shortcut.js
echo var shell = new ActiveXObject("WScript.Shell"); > %SHORTCUT_JS%
echo var shortcut = shell.CreateShortcut(shell.SpecialFolders("Desktop") + "\JET IDE.lnk"); >> %SHORTCUT_JS%
echo shortcut.TargetPath = "%EXE_PATH%\JET.bat"; >> %SHORTCUT_JS%
echo shortcut.WorkingDirectory = "%EXE_PATH%"; >> %SHORTCUT_JS%
echo shortcut.Description = "JET IDE - Powerful Development Environment"; >> %SHORTCUT_JS%
echo shortcut.Save(); >> %SHORTCUT_JS%
cscript //nologo %SHORTCUT_JS% > nul 2>&1
del %SHORTCUT_JS%
echo Desktop shortcut created successfully.

:: Create start menu shortcuts
if not exist "%APPDATA%\Microsoft\Windows\Start Menu\Programs\JET IDE" mkdir "%APPDATA%\Microsoft\Windows\Start Menu\Programs\JET IDE"
set STARTMENU_JS=%TEMP%\startmenu.js
echo var shell = new ActiveXObject("WScript.Shell"); > %STARTMENU_JS%
echo var shortcut = shell.CreateShortcut(shell.SpecialFolders("Programs") + "\JET IDE\JET IDE.lnk"); >> %STARTMENU_JS%
echo shortcut.TargetPath = "%EXE_PATH%\JET.bat"; >> %STARTMENU_JS%
echo shortcut.WorkingDirectory = "%EXE_PATH%"; >> %STARTMENU_JS%
echo shortcut.Description = "Indie IDE - Powerful Development Environment"; >> %STARTMENU_JS%
echo shortcut.Save(); >> %STARTMENU_JS%
cscript //nologo %STARTMENU_JS% > nul 2>&1
del %STARTMENU_JS%
echo Start menu shortcuts created successfully.

echo.
echo Step 4 of 4: Finalizing installation...
echo.

:: Add uninstall information to registry
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\JET IDE" /v "DisplayName" /t REG_SZ /d "JET IDE" /f > nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\JET IDE" /v "UninstallString" /t REG_SZ /d "\"%INSTALL_DIR%\uninstall.bat\"" /f > nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\JET IDE" /v "Publisher" /t REG_SZ /d "JET Team" /f > nul
echo Registry entries created successfully.

:: Create uninstall batch file
(
echo @echo off
echo title JET IDE Uninstaller
echo color 0C
echo echo ===================================
echo echo       JET IDE Uninstaller
echo echo ===================================
echo echo.
echo echo This will uninstall JET IDE from your computer.
echo echo All application files will be removed.
echo echo.
echo echo Press any key to continue with uninstallation...
echo pause ^> nul
echo echo.
echo echo Uninstalling JET IDE...
echo rmdir /s /q "%INSTALL_DIR%"
echo del "%USERPROFILE%\Desktop\JET IDE.lnk"
echo rmdir /s /q "%APPDATA%\Microsoft\Windows\Start Menu\Programs\JET IDE"
echo reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\JET IDE" /f ^> nul
echo echo.
echo echo JET IDE has been successfully uninstalled.
echo echo.
echo echo Press any key to exit...
echo pause ^> nul
echo echo.
echo pause
) > "%INSTALL_DIR%\uninstall.bat"
echo Uninstall script created successfully.

cls
echo ===================================
echo       JET IDE Setup Wizard
echo ===================================
echo.
echo Installation Complete!
echo.
echo JET IDE has been successfully installed on your computer.
echo.
echo You can launch JET IDE from the desktop shortcut
echo or from the Start Menu.
echo.

set /p LAUNCH=Would you like to launch JET IDE now? [Y/N]: 
if /i "%LAUNCH%"=="Y" start "" "%EXE_PATH%\JET.bat"

echo.
echo Thank you for installing JET IDE!
echo.
echo Press any key to exit...
pause > nul