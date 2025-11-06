# Script to create an installer for JET IDE using NSIS (Nullsoft Scriptable Install System)

# Configuration
$appName = "JET IDE"
$appVersion = "1.0.0"
$publishDir = "publish"
$installerDir = "installer"
$nsisCompiler = "C:\Program Files (x86)\NSIS\makensis.exe"

# Check if the published app exists
if (!(Test-Path "$publishDir\JET.exe")) {
    Write-Host "Error: Published application not found at $publishDir\JET.exe" -ForegroundColor Red
    Write-Host "Please run package-app.ps1 first to create the self-contained executable."
    exit 1
}

# Check if NSIS is installed
$nsisInstalled = Test-Path $nsisCompiler
if (!$nsisInstalled) {
    Write-Host "NSIS not found at $nsisCompiler" -ForegroundColor Yellow
    Write-Host "Please install NSIS from https://nsis.sourceforge.io/Download"
    Write-Host "Or adjust the path to makensis.exe in this script."
    
    $downloadNSIS = Read-Host "Would you like to open the NSIS download page? (Y/N)"
    if ($downloadNSIS -eq "Y" -or $downloadNSIS -eq "y") {
        Start-Process "https://nsis.sourceforge.io/Download"
    }
    exit 1
}

# Create installer directory if it doesn't exist
if (!(Test-Path $installerDir)) {
    New-Item -ItemType Directory -Path $installerDir | Out-Null
}

# Create NSIS script
$nsisScriptPath = "$installerDir\JETSetup.nsi"
Write-Host "Creating NSIS script at $nsisScriptPath..."

$nsisScript = @"
; JET IDE Installer Script
!include "MUI2.nsh"

; General
Name "$appName"
OutFile "$installerDir\JET_IDE_Setup.exe"
InstallDir "\$PROGRAMFILES64\$appName"
InstallDirRegKey HKCU "Software\$appName" ""

; Interface Settings
!define MUI_ABORTWARNING
!define MUI_ICON "JET.App\Resources\Icons\jet-icon.ico"
!define MUI_UNICON "JET.App\Resources\Icons\jet-icon.ico"

; Pages
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "LICENSE"
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

; Languages
!insertmacro MUI_LANGUAGE "English"

; Installer Sections
Section "JET IDE" SecMain
  SectionIn RO
  SetOutPath "\$INSTDIR"
  
  ; Copy all files from publish directory
  File /r "$publishDir\*.*"
  
  ; Create uninstaller
  WriteUninstaller "\$INSTDIR\Uninstall.exe"
  
  ; Create shortcuts
  CreateDirectory "\$SMPROGRAMS\$appName"
  CreateShortcut "\$SMPROGRAMS\$appName\$appName.lnk" "\$INSTDIR\JET.exe"
  CreateShortcut "\$SMPROGRAMS\$appName\Uninstall.lnk" "\$INSTDIR\Uninstall.exe"
  
  ; Write registry keys for uninstaller
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\$appName" "DisplayName" "$appName"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\$appName" "UninstallString" '"\$INSTDIR\Uninstall.exe"'
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\$appName" "DisplayIcon" '"\$INSTDIR\JET.exe"'
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\$appName" "DisplayVersion" "$appVersion"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\$appName" "Publisher" "JET IDE Team"
SectionEnd

Section "Desktop Shortcut" SecDesktop
  CreateShortcut "\$DESKTOP\$appName.lnk" "\$INSTDIR\JET.exe"
SectionEnd

; Descriptions
!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  !insertmacro MUI_DESCRIPTION_TEXT \${SecMain} "Install JET IDE core files."
  !insertmacro MUI_DESCRIPTION_TEXT \${SecDesktop} "Create a shortcut on the desktop."
!insertmacro MUI_FUNCTION_DESCRIPTION_END

; Uninstaller Section
Section "Uninstall"
  ; Remove files and uninstaller
  RMDir /r "\$INSTDIR"
  
  ; Remove shortcuts
  Delete "\$DESKTOP\$appName.lnk"
  Delete "\$SMPROGRAMS\$appName\$appName.lnk"
  Delete "\$SMPROGRAMS\$appName\Uninstall.lnk"
  RMDir "\$SMPROGRAMS\$appName"
  
  ; Remove registry keys
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\$appName"
SectionEnd
"@

Set-Content -Path $nsisScriptPath -Value $nsisScript

# Compile the installer
Write-Host "Compiling installer using NSIS..."
try {
    & $nsisCompiler $nsisScriptPath
    
    if ($LASTEXITCODE -eq 0) {
        $installerPath = "$installerDir\JET_IDE_Setup.exe"
        if (Test-Path $installerPath) {
            $fileSize = (Get-Item $installerPath).Length / 1MB
            Write-Host "\nInstaller creation successful!" -ForegroundColor Green
            Write-Host "Installer created at: $installerPath"
            Write-Host "File size: $($fileSize.ToString('0.00')) MB"
        } else {
            Write-Host "Error: Installer not found after compilation." -ForegroundColor Red
        }
    } else {
        Write-Host "Error: NSIS compilation failed with exit code $LASTEXITCODE" -ForegroundColor Red
    }
} catch {
    Write-Host "Error during installer creation: $_" -ForegroundColor Red
    exit 1
}

# Suggest next steps
Write-Host "\nNext steps:"
Write-Host "1. Test the installer by running: $installerDir\JET_IDE_Setup.exe"
Write-Host "2. Distribute the installer to users"