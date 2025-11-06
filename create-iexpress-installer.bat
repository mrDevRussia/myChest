@echo off
setlocal enabledelayedexpansion

echo Creating JET IDE All-in-One Installer...

:: Create a temporary directory
set TEMP_DIR=temp_installer
if exist %TEMP_DIR% rmdir /s /q %TEMP_DIR%
mkdir %TEMP_DIR%

:: Create the installation batch file
echo @echo off > %TEMP_DIR%\install.bat
echo echo Installing JET IDE... >> %TEMP_DIR%\install.bat
echo set INSTALL_DIR=%%LOCALAPPDATA%%\JET IDE >> %TEMP_DIR%\install.bat
echo if not exist "%%INSTALL_DIR%%" mkdir "%%INSTALL_DIR%%" >> %TEMP_DIR%\install.bat
echo xcopy /s /e /i /y "JET.App" "%%INSTALL_DIR%%\JET.App" >> %TEMP_DIR%\install.bat
echo copy /y "LICENSE" "%%INSTALL_DIR%%\LICENSE" >> %TEMP_DIR%\install.bat
echo copy /y "README.md" "%%INSTALL_DIR%%\README.md" >> %TEMP_DIR%\install.bat
echo copy /y "INSTALL.md" "%%INSTALL_DIR%%\INSTALL.md" >> %TEMP_DIR%\install.bat
echo copy /y "PACKAGING.md" "%%INSTALL_DIR%%\PACKAGING.md" >> %TEMP_DIR%\install.bat
echo echo Creating desktop shortcut... >> %TEMP_DIR%\install.bat
echo set SHORTCUT_JS=CreateShortcut.js >> %TEMP_DIR%\install.bat
echo echo var shell = new ActiveXObject("WScript.Shell"); > %%SHORTCUT_JS%% >> %TEMP_DIR%\install.bat
echo echo var shortcut = shell.CreateShortcut(shell.SpecialFolders("Desktop") + "\\JET IDE.lnk"); >> %%SHORTCUT_JS%% >> %TEMP_DIR%\install.bat
echo echo shortcut.TargetPath = "%%INSTALL_DIR%%\\JET.App\\JET.exe"; >> %%SHORTCUT_JS%% >> %TEMP_DIR%\install.bat
echo echo shortcut.WorkingDirectory = "%%INSTALL_DIR%%\\JET.App"; >> %%SHORTCUT_JS%% >> %TEMP_DIR%\install.bat
echo echo shortcut.IconLocation = "%%INSTALL_DIR%%\\JET.App\\Resources\\Icons\\jet-icon.ico"; >> %%SHORTCUT_JS%% >> %TEMP_DIR%\install.bat
echo echo shortcut.Description = "JET Integrated Development Environment"; >> %%SHORTCUT_JS%% >> %TEMP_DIR%\install.bat
echo echo shortcut.Save(); >> %%SHORTCUT_JS%% >> %TEMP_DIR%\install.bat
echo cscript //nologo %%SHORTCUT_JS%% >> %TEMP_DIR%\install.bat
echo del %%SHORTCUT_JS%% >> %TEMP_DIR%\install.bat
echo echo. >> %TEMP_DIR%\install.bat
echo echo Installation complete! >> %TEMP_DIR%\install.bat
echo echo Starting JET IDE... >> %TEMP_DIR%\install.bat
echo start "" "%%INSTALL_DIR%%\JET.App\JET.exe" >> %TEMP_DIR%\install.bat
echo exit >> %TEMP_DIR%\install.bat

:: Copy the license file for the installer
copy /y LICENSE %TEMP_DIR%\license.txt

:: Create the IExpress SED file
echo [Version] > %TEMP_DIR%\installer.sed
echo Class=IEXPRESS >> %TEMP_DIR%\installer.sed
echo SEDVersion=3 >> %TEMP_DIR%\installer.sed
echo [Options] >> %TEMP_DIR%\installer.sed
echo PackagePurpose=InstallApp >> %TEMP_DIR%\installer.sed
echo ShowInstallProgramWindow=1 >> %TEMP_DIR%\installer.sed
echo HideExtractAnimation=0 >> %TEMP_DIR%\installer.sed
echo UseLongFileName=1 >> %TEMP_DIR%\installer.sed
echo InsideCompressed=0 >> %TEMP_DIR%\installer.sed
echo CAB_FixedSize=0 >> %TEMP_DIR%\installer.sed
echo CAB_ResvCodeSigning=0 >> %TEMP_DIR%\installer.sed
echo RebootMode=N >> %TEMP_DIR%\installer.sed
echo InstallPrompt=%%InstallPrompt%% >> %TEMP_DIR%\installer.sed
echo DisplayLicense=1 >> %TEMP_DIR%\installer.sed
echo FinishMessage=JET IDE has been installed successfully. The application will now start. >> %TEMP_DIR%\installer.sed
echo TargetName=%%TargetName%% >> %TEMP_DIR%\installer.sed
echo FriendlyName=JET IDE Installer >> %TEMP_DIR%\installer.sed
echo AppLaunched=cmd /c install.bat >> %TEMP_DIR%\installer.sed
echo PostInstallCmd=<None> >> %TEMP_DIR%\installer.sed
echo AdminQuietInstCmd= >> %TEMP_DIR%\installer.sed
echo UserQuietInstCmd= >> %TEMP_DIR%\installer.sed
echo SourceFiles=SourceFiles >> %TEMP_DIR%\installer.sed
echo [Strings] >> %TEMP_DIR%\installer.sed
echo InstallPrompt=This will install JET IDE on your computer. Do you wish to continue? >> %TEMP_DIR%\installer.sed
echo TargetName=%cd%\JET-IDE-Setup.exe >> %TEMP_DIR%\installer.sed
echo FILE0="install.bat" >> %TEMP_DIR%\installer.sed
echo FILE1="license.txt" >> %TEMP_DIR%\installer.sed

:: Add JET.App directory files to the SED file
echo [SourceFiles] >> %TEMP_DIR%\installer.sed
echo SourceFiles0=%cd%\%TEMP_DIR% >> %TEMP_DIR%\installer.sed
echo SourceFiles1=%cd% >> %TEMP_DIR%\installer.sed
echo [SourceFiles0] >> %TEMP_DIR%\installer.sed
echo %%FILE0%%=%%FILE0%% >> %TEMP_DIR%\installer.sed
echo %%FILE1%%=%%FILE1%% >> %TEMP_DIR%\installer.sed
echo [SourceFiles1] >> %TEMP_DIR%\installer.sed

:: Add all files from JET.App directory
set FILE_INDEX=2
for /r JET.App %%f in (*) do (
    set REL_PATH=%%f
    set REL_PATH=!REL_PATH:%cd%\=!
    echo FILE!FILE_INDEX!=!REL_PATH! >> %TEMP_DIR%\installer.sed
    echo %%FILE!FILE_INDEX!%%=%%FILE!FILE_INDEX!%% >> %TEMP_DIR%\installer.sed
    set /a FILE_INDEX+=1
)

:: Add documentation files
echo FILE!FILE_INDEX!=LICENSE >> %TEMP_DIR%\installer.sed
echo %%FILE!FILE_INDEX!%%=%%FILE!FILE_INDEX!%% >> %TEMP_DIR%\installer.sed
set /a FILE_INDEX+=1

echo FILE!FILE_INDEX!=README.md >> %TEMP_DIR%\installer.sed
echo %%FILE!FILE_INDEX!%%=%%FILE!FILE_INDEX!%% >> %TEMP_DIR%\installer.sed
set /a FILE_INDEX+=1

echo FILE!FILE_INDEX!=INSTALL.md >> %TEMP_DIR%\installer.sed
echo %%FILE!FILE_INDEX!%%=%%FILE!FILE_INDEX!%% >> %TEMP_DIR%\installer.sed
set /a FILE_INDEX+=1

echo FILE!FILE_INDEX!=PACKAGING.md >> %TEMP_DIR%\installer.sed
echo %%FILE!FILE_INDEX!%%=%%FILE!FILE_INDEX!%% >> %TEMP_DIR%\installer.sed
set /a FILE_INDEX+=1

:: Run IExpress to create the self-extracting executable
echo Running IExpress to create the installer...
iexpress /n /q %TEMP_DIR%\installer.sed

:: Clean up
rmdir /s /q %TEMP_DIR%

if exist JET-IDE-Setup.exe (
    echo.
    echo JET-IDE-Setup.exe created successfully!
    echo This is an all-in-one installer that will install JET IDE and launch it automatically.
) else (
    echo.
    echo Failed to create JET-IDE-Setup.exe
)