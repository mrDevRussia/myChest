# Script to create an installer for JET IDE using Inno Setup

# Configuration
$appName = "JET IDE"
$appVersion = "1.0.0"
$publishDir = "publish"
$installerDir = "installer"
$innoSetupCompiler = "C:\Program Files (x86)\Inno Setup 6\ISCC.exe"

# Check if the published app exists
if (!(Test-Path "$publishDir\JET.exe")) {
    Write-Host "Error: Published application not found at $publishDir\JET.exe" -ForegroundColor Red
    Write-Host "Please run package-app.ps1 first to create the self-contained executable."
    exit 1
}

# Check if Inno Setup is installed
$innoSetupInstalled = Test-Path $innoSetupCompiler
if (!$innoSetupInstalled) {
    Write-Host "Inno Setup not found at $innoSetupCompiler" -ForegroundColor Yellow
    Write-Host "Please install Inno Setup from https://jrsoftware.org/isdl.php"
    Write-Host "Or adjust the path to ISCC.exe in this script."
    
    $downloadInno = Read-Host "Would you like to open the Inno Setup download page? (Y/N)"
    if ($downloadInno -eq "Y" -or $downloadInno -eq "y") {
        Start-Process "https://jrsoftware.org/isdl.php"
    }
    exit 1
}

# Create installer directory if it doesn't exist
if (!(Test-Path $installerDir)) {
    New-Item -ItemType Directory -Path $installerDir | Out-Null
}

# Create Inno Setup script
$innoScriptPath = "$installerDir\JETSetup.iss"
Write-Host "Creating Inno Setup script at $innoScriptPath..."

$innoScript = @"
[Setup]
AppName=$appName
AppVersion=$appVersion
DefaultDirName={autopf}\$appName
DefaultGroupName=$appName
OutputDir=$installerDir
OutputBaseFilename=JET_IDE_Setup
SetupIconFile=JET.App\Resources\Icons\jet-icon.ico
UninstallDisplayIcon={app}\JET.exe
Compression=lzma2
SolidCompression=yes
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog

[Files]
Source="$publishDir\*"; DestDir="{app}"; Flags: ignoreversion recursesubdirs

[Icons]
Name="{group}\$appName"; Filename="{app}\JET.exe"
Name="{group}\Uninstall $appName"; Filename="{uninstallexe}"
Name="{commondesktop}\$appName"; Filename="{app}\JET.exe"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Run]
Filename: "{app}\JET.exe"; Description: "{cm:LaunchProgram,{#StringChange(AppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
"@

Set-Content -Path $innoScriptPath -Value $innoScript

# Compile the installer
Write-Host "Compiling installer using Inno Setup..."
try {
    & $innoSetupCompiler $innoScriptPath
    
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
        Write-Host "Error: Inno Setup compilation failed with exit code $LASTEXITCODE" -ForegroundColor Red
    }
} catch {
    Write-Host "Error during installer creation: $_" -ForegroundColor Red
    exit 1
}

# Suggest next steps
Write-Host "\nNext steps:"
Write-Host "1. Test the installer by running: $installerDir\JET_IDE_Setup.exe"
Write-Host "2. Distribute the installer to users"