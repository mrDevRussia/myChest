@echo off
echo JET IDE Executable Installer Creator
echo ================================

:: Check for IExpress
where iexpress >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo IExpress is not found. It should be included with Windows.
    exit /b 1
)

:: Create a temporary directory
if not exist temp mkdir temp

:: Create the installer batch file
echo @echo off > temp\install.bat
echo echo JET IDE Installer >> temp\install.bat
echo echo ================ >> temp\install.bat
echo. >> temp\install.bat
echo set INSTALL_DIR=%%USERPROFILE%%\Desktop\JET-IDE >> temp\install.bat
echo. >> temp\install.bat
echo echo Creating installation directory... >> temp\install.bat
echo if not exist "%%INSTALL_DIR%%" mkdir "%%INSTALL_DIR%%" >> temp\install.bat
echo. >> temp\install.bat
echo echo Extracting JET IDE files... >> temp\install.bat
echo xcopy /E /I /Y %%~dp0JET.App "%%INSTALL_DIR%%\JET.App\" >> temp\install.bat
echo xcopy /Y %%~dp0LICENSE "%%INSTALL_DIR%%\" >> temp\install.bat
echo xcopy /Y %%~dp0README.md "%%INSTALL_DIR%%\" >> temp\install.bat
echo xcopy /Y %%~dp0PACKAGING.md "%%INSTALL_DIR%%\" >> temp\install.bat
echo. >> temp\install.bat
echo echo Creating desktop shortcut... >> temp\install.bat
echo powershell -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%%USERPROFILE%%\Desktop\JET IDE.lnk'); $Shortcut.TargetPath = '%%INSTALL_DIR%%\JET.App\JET.exe'; $Shortcut.IconLocation = '%%INSTALL_DIR%%\JET.App\Resources\Icons\jet-icon.ico'; $Shortcut.Save()" >> temp\install.bat
echo. >> temp\install.bat
echo echo. >> temp\install.bat
echo echo JET IDE has been installed to: %%INSTALL_DIR%% >> temp\install.bat
echo echo A shortcut has been created on your desktop. >> temp\install.bat
echo echo. >> temp\install.bat
echo echo Press any key to exit... >> temp\install.bat
echo pause ^> nul >> temp\install.bat

:: Create the SED file for IExpress
echo [Version] > temp\installer.sed
echo Class=IEXPRESS >> temp\installer.sed
echo SEDVersion=3 >> temp\installer.sed
echo [Options] >> temp\installer.sed
echo PackagePurpose=InstallApp >> temp\installer.sed
echo ShowInstallProgramWindow=1 >> temp\installer.sed
echo HideExtractAnimation=0 >> temp\installer.sed
echo UseLongFileName=1 >> temp\installer.sed
echo InsideCompressed=0 >> temp\installer.sed
echo CAB_FixedSize=0 >> temp\installer.sed
echo CAB_ResvCodeSigning=0 >> temp\installer.sed
echo RebootMode=N >> temp\installer.sed
echo InstallPrompt=Do you want to install JET IDE? >> temp\installer.sed
echo DisplayLicense=LICENSE >> temp\installer.sed
echo FinishMessage=JET IDE has been installed successfully. >> temp\installer.sed
echo TargetName=JET-IDE-Setup.exe >> temp\installer.sed
echo FriendlyName=JET IDE Installer >> temp\installer.sed
echo AppLaunched=install.bat >> temp\installer.sed
echo PostInstallCmd=^<None^> >> temp\installer.sed
echo AdminQuietInstCmd=^<None^> >> temp\installer.sed
echo UserQuietInstCmd=^<None^> >> temp\installer.sed
echo SourceFiles=SourceFiles >> temp\installer.sed
echo [Strings] >> temp\installer.sed
echo InstallPrompt=Do you want to install JET IDE? >> temp\installer.sed
echo DisplayLicense=Do you accept the terms of the license agreement? >> temp\installer.sed
echo FinishMessage=JET IDE has been installed successfully. >> temp\installer.sed
echo FriendlyName=JET IDE Installer >> temp\installer.sed
echo AppLaunched=install.bat >> temp\installer.sed
echo PostInstallCmd=^<None^> >> temp\installer.sed
echo AdminQuietInstCmd=^<None^> >> temp\installer.sed
echo UserQuietInstCmd=^<None^> >> temp\installer.sed
echo FILE0="install.bat" >> temp\installer.sed
echo [SourceFiles] >> temp\installer.sed
echo SourceFiles0=temp >> temp\installer.sed
echo SourceFiles1=. >> temp\installer.sed
echo [SourceFiles0] >> temp\installer.sed
echo %FILE0%=>> temp\installer.sed
echo [SourceFiles1] >> temp\installer.sed
echo LICENSE=>> temp\installer.sed
echo README.md=>> temp\installer.sed
echo PACKAGING.md=>> temp\installer.sed

:: Create the directory list for JET.App
echo [SourceFiles2] >> temp\installer.sed
for /r JET.App %%F in (*) do (
    echo "%%~nxF"=>> temp\installer.sed
)

:: Run IExpress to create the self-extracting executable
echo Creating self-extracting executable...
iexpress /n /q temp\installer.sed

if exist JET-IDE-Setup.exe (
    echo.
    echo JET-IDE-Setup.exe created successfully.
) else (
    echo.
    echo Failed to create JET-IDE-Setup.exe
    exit /b 1
)

:: Clean up
rmdir /S /Q temp

echo.
echo Process completed successfully.
echo.

pause