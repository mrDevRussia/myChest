@echo off
echo Creating JET IDE Setup with IExpress...

:: Build the .NET application first
echo Building JET.App...
dotnet build JET.App\JET.App.csproj -c Release
if %ERRORLEVEL% neq 0 (
    echo Failed to build JET.App
    pause
    exit /b 1
)

:: Create a temporary directory for the installer files
set TEMP_DIR=%TEMP%\JET-IDE-Setup
if exist "%TEMP_DIR%" rmdir /s /q "%TEMP_DIR%"
mkdir "%TEMP_DIR%"

:: Copy all necessary files to the temp directory
echo Copying files to temporary directory...
xcopy /E /I "JET.App\bin\Release\net6.0-windows" "%TEMP_DIR%\JET.App"
if exist "LICENSE" copy "LICENSE" "%TEMP_DIR%"
if exist "README.md" copy "README.md" "%TEMP_DIR%"
if exist "INSTALL.md" copy "INSTALL.md" "%TEMP_DIR%"

:: Create a setup information file for IExpress
echo Creating IExpress SED file...
(
    echo [Version]
    echo Class=IEXPRESS
    echo SEDVersion=3
    echo [Options]
    echo PackagePurpose=InstallApp
    echo ShowInstallProgramWindow=1
    echo HideExtractAnimation=0
    echo UseLongFileName=1
    echo InsideCompressed=0
    echo CAB_FixedSize=0
    echo CAB_ResvCodeSigning=0
    echo RebootMode=N
    echo InstallPrompt=%%InstallPrompt%%
    echo DisplayLicense=%%DisplayLicense%%
    echo FinishMessage=%%FinishMessage%%
    echo TargetName=%%TargetName%%
    echo FriendlyName=%%FriendlyName%%
    echo AppLaunched=%%AppLaunched%%
    echo PostInstallCmd=%%PostInstallCmd%%
    echo AdminQuietInstCmd=%%AdminQuietInstCmd%%
    echo UserQuietInstCmd=%%UserQuietInstCmd%%
    echo SourceFiles=SourceFiles
    echo [Strings]
    echo InstallPrompt=Are you sure you want to install JET IDE?
    echo DisplayLicense=
    echo FinishMessage=JET IDE has been installed successfully.
    echo TargetName=%CD%\JET-IDE-Setup.exe
    echo FriendlyName=JET IDE Setup
    echo AppLaunched=setup.bat
    echo PostInstallCmd=<None>
    echo AdminQuietInstCmd=
    echo UserQuietInstCmd=
    echo FILE0="%%TEMP_DIR%%"
    echo [SourceFiles]
    echo SourceFiles0=%%TEMP_DIR%%
    echo [SourceFiles0]
    echo %%FILE0%%=
) > "%TEMP_DIR%\setup.sed"

:: Create a setup batch file that will run after extraction
echo Creating setup batch file...
(
    echo @echo off
    echo echo Installing JET IDE...
    echo set INSTALL_DIR=%%LOCALAPPDATA%%\JET IDE
    echo if not exist "%%INSTALL_DIR%%" mkdir "%%INSTALL_DIR%%"
    echo xcopy /E /I "JET.App" "%%INSTALL_DIR%%\JET.App"
    echo if exist "LICENSE" copy "LICENSE" "%%INSTALL_DIR%%"
    echo if exist "README.md" copy "README.md" "%%INSTALL_DIR%%"
    echo if exist "INSTALL.md" copy "INSTALL.md" "%%INSTALL_DIR%%"
    echo echo Creating shortcuts...
    echo set SHORTCUT_JS=%%TEMP%%\shortcut.js
    echo echo var shell = new ActiveXObject^("WScript.Shell"^); ^> %%SHORTCUT_JS%%
    echo echo var shortcut = shell.CreateShortcut^(shell.SpecialFolders^("Desktop"^) + "\JET IDE.lnk"^); ^>^> %%SHORTCUT_JS%%
    echo echo shortcut.TargetPath = "%%INSTALL_DIR%%\JET.App\JET.exe"; ^>^> %%SHORTCUT_JS%%
    echo echo shortcut.WorkingDirectory = "%%INSTALL_DIR%%\JET.App"; ^>^> %%SHORTCUT_JS%%
    echo echo shortcut.Save^(^); ^>^> %%SHORTCUT_JS%%
    echo cscript //nologo %%SHORTCUT_JS%%
    echo del %%SHORTCUT_JS%%
    echo echo.
    echo echo JET IDE has been installed successfully!
    echo echo.
    echo set /p LAUNCH=Launch JET IDE now? [Y/N]: 
    echo if /i "%%LAUNCH%%"=="Y" start "" "%%INSTALL_DIR%%\JET.App\JET.exe"
    echo exit /b 0
) > "%TEMP_DIR%\setup.bat"

:: Run IExpress to create the self-extracting installer
echo Running IExpress to create installer...
iexpress /n /q "%TEMP_DIR%\setup.sed"

if exist "JET-IDE-Setup.exe" (
    echo.
    echo JET-IDE-Setup.exe has been created successfully!
    echo.
) else (
    echo.
    echo Failed to create JET-IDE-Setup.exe
    echo.
)

:: Clean up
rmdir /s /q "%TEMP_DIR%"

pause