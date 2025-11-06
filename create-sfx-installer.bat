@echo off
echo Creating JET IDE Self-Extracting Installer...

:: Create a temporary directory for the installer files
if not exist temp mkdir temp

:: Copy all necessary files to the temp directory
xcopy /E /I /Y JET.App temp\JET.App\
xcopy /Y LICENSE temp\
xcopy /Y README.md temp\

:: Create a config file for the SFX archive
echo ;!@Install@!UTF-8! > config.txt
echo Title="JET IDE Installer" >> config.txt
echo BeginPrompt="Do you want to install JET IDE?" >> config.txt
echo ExecuteFile="JET.App\JET.exe" >> config.txt
echo ;!@InstallEnd@! >> config.txt

:: Check if 7-Zip is installed
where 7z >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo 7-Zip is not installed or not in PATH.
    echo Please install 7-Zip from https://www.7-zip.org/download.html
    exit /b 1
)

:: Create the archive
7z a -r temp\JET-IDE.7z temp\*

:: Create the self-extracting executable
copy /b 7zS.sfx + config.txt + temp\JET-IDE.7z JET-IDE-Setup.exe

if exist JET-IDE-Setup.exe (
    echo Installer created successfully: JET-IDE-Setup.exe
) else (
    echo Failed to create installer.
    exit /b 1
)

:: Clean up
rmdir /S /Q temp
del config.txt
del temp\JET-IDE.7z