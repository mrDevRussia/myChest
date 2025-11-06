# PowerShell script to create a proper executable installer

# Create a temporary directory
$tempDir = "temp"
if (!(Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir | Out-Null
}

# Create the installer batch file
$installBatContent = @"
@echo off
echo JET IDE Installer
echo ==============
echo.

:: Set installation directory
set INSTALL_DIR=%USERPROFILE%\Desktop\JET-IDE

:: Create installation directory
echo Creating installation directory...
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

:: Copy all files
echo Copying JET IDE files...
xcopy /E /I /Y "%~dp0JET.App" "%INSTALL_DIR%\JET.App\"
xcopy /Y "%~dp0LICENSE" "%INSTALL_DIR%\"
xcopy /Y "%~dp0README.md" "%INSTALL_DIR%\"
xcopy /Y "%~dp0PACKAGING.md" "%INSTALL_DIR%\"
xcopy /Y "%~dp0INSTALL.md" "%INSTALL_DIR%\"

:: Create shortcut on desktop
echo Creating desktop shortcut...

powershell -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%USERPROFILE%\Desktop\JET IDE.lnk'); $Shortcut.TargetPath = '%INSTALL_DIR%\JET.App\JET.exe'; $Shortcut.IconLocation = '%INSTALL_DIR%\JET.App\Resources\Icons\jet-icon.ico'; $Shortcut.Description = 'JET Integrated Development Environment'; $Shortcut.Save()"

echo.
echo JET IDE has been installed to: %INSTALL_DIR%
echo A shortcut has been created on your desktop.
echo.
echo Press any key to exit...
pause > nul
"@

# Write the batch file to the temp directory
$installBatContent | Out-File -FilePath "$tempDir\install.bat" -Encoding ASCII

# Create the SED file for IExpress
$sedContent = @"
[Version]
Class=IEXPRESS
SEDVersion=3
[Options]
PackagePurpose=InstallApp
ShowInstallProgramWindow=1
HideExtractAnimation=0
UseLongFileName=1
InsideCompressed=0
CAB_FixedSize=0
CAB_ResvCodeSigning=0
RebootMode=N
InstallPrompt=Do you want to install JET IDE?
DisplayLicense=LICENSE
FinishMessage=JET IDE has been installed successfully.
TargetName=JET-IDE-Installer.exe
FriendlyName=JET IDE Installer
AppLaunched=cmd /c install.bat
PostInstallCmd=<None>
AdminQuietInstCmd=<None>
UserQuietInstCmd=<None>
SourceFiles=SourceFiles
[Strings]
InstallPrompt=Do you want to install JET IDE?
DisplayLicense=Do you accept the terms of the license agreement?
FinishMessage=JET IDE has been installed successfully.
FriendlyName=JET IDE Installer
AppLaunched=cmd /c install.bat
PostInstallCmd=<None>
AdminQuietInstCmd=<None>
UserQuietInstCmd=<None>
FILE0="install.bat"
FILE1="LICENSE"
FILE2="README.md"
FILE3="PACKAGING.md"
FILE4="INSTALL.md"
[SourceFiles]
SourceFiles0=$tempDir
SourceFiles1=.
SourceFiles2=JET.App
[SourceFiles0]
%FILE0%=
[SourceFiles1]
%FILE1%=
%FILE2%=
%FILE3%=
%FILE4%=
[SourceFiles2]
"@

# Write the SED file to the temp directory
$sedContent | Out-File -FilePath "$tempDir\installer.sed" -Encoding ASCII

# Add JET.App files to the SED file
$jetAppFiles = Get-ChildItem -Path "JET.App" -Recurse -File
$fileIndex = 5
$sourceFilesContent = "[SourceFiles2]\n"

foreach ($file in $jetAppFiles) {
    $relativePath = $file.FullName.Replace((Get-Item "JET.App").FullName + "\", "")
    $fileVar = "FILE$fileIndex"
    
    # Add to Strings section
    Add-Content -Path "$tempDir\installer.sed" -Value "$fileVar=\"$relativePath\""
    
    # Add to SourceFiles2 section
    $sourceFilesContent += "%$fileVar%=$relativePath\n"
    
    $fileIndex++
}

# Write the SourceFiles2 section to the SED file
Add-Content -Path "$tempDir\installer.sed" -Value $sourceFilesContent

# Run IExpress to create the self-extracting executable
Write-Host "Creating self-extracting executable..."
Start-Process -FilePath "iexpress" -ArgumentList "/N", "$tempDir\installer.sed" -Wait

if (Test-Path "JET-IDE-Installer.exe") {
    Write-Host "`nJET-IDE-Installer.exe created successfully." -ForegroundColor Green
} else {
    Write-Host "`nFailed to create JET-IDE-Installer.exe" -ForegroundColor Red
    exit 1
}

# Clean up
Remove-Item -Path $tempDir -Recurse -Force

Write-Host "`nProcess completed successfully." -ForegroundColor Green
