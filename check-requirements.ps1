# Script to check if all required tools for packaging are installed

# Configuration
$requiredTools = @{
    ".NET SDK" = @{
        Command = "dotnet --version"
        MinVersion = "6.0.0"
        DownloadUrl = "https://dotnet.microsoft.com/download"
        Required = $true
    }
    "PowerShell" = @{
        Command = "$PSVersionTable.PSVersion.ToString()"
        MinVersion = "5.1.0"
        DownloadUrl = "https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell"
        Required = $true
    }
    "ImageMagick" = @{
        Command = "magick -version"
        MinVersion = ""
        DownloadUrl = "https://imagemagick.org/script/download.php"
        Required = $false
    }
    "UPX" = @{
        Command = "upx --version"
        MinVersion = ""
        DownloadUrl = "https://github.com/upx/upx/releases"
        Required = $false
    }
    "Inno Setup" = @{
        Command = "& { if (Test-Path 'C:\Program Files (x86)\Inno Setup 6\ISCC.exe') { 'Inno Setup is installed' } else { throw 'Inno Setup not found' } }"
        MinVersion = ""
        DownloadUrl = "https://jrsoftware.org/isdl.php"
        Required = $false
    }
    "NSIS" = @{
        Command = "& { if (Test-Path 'C:\Program Files (x86)\NSIS\makensis.exe') { 'NSIS is installed' } else { throw 'NSIS not found' } }"
        MinVersion = ""
        DownloadUrl = "https://nsis.sourceforge.io/Download"
        Required = $false
    }
}

# Display header
Write-Host "\n=============================================" -ForegroundColor Cyan
Write-Host "   JET IDE Packaging Requirements Check   " -ForegroundColor Cyan
Write-Host "=============================================\n" -ForegroundColor Cyan

# Function to check if a version string meets the minimum requirement
function Test-MinimumVersion {
    param (
        [string]$CurrentVersion,
        [string]$MinimumVersion
    )
    
    if ([string]::IsNullOrEmpty($MinimumVersion)) {
        return $true
    }
    
    try {
        $current = [System.Version]::Parse(($CurrentVersion -split ' ')[0])
        $minimum = [System.Version]::Parse($MinimumVersion)
        return $current -ge $minimum
    } catch {
        Write-Host "Warning: Could not parse version string '$CurrentVersion'" -ForegroundColor Yellow
        return $true
    }
}

# Check for required scripts
Write-Host "Checking for required scripts..." -ForegroundColor Yellow
$requiredScripts = @(
    "build-and-package.ps1",
    "package-app.ps1",
    "convert-icon.ps1"
)

$optionalScripts = @(
    "compress-exe.ps1",
    "create-installer.ps1",
    "create-nsis-installer.ps1",
    "setup-auto-updates.ps1",
    "verify-package.ps1",
    "cleanup.ps1",
    "troubleshoot-packaging.ps1"
)

$missingRequiredScripts = @()
foreach ($script in $requiredScripts) {
    Write-Host "Checking for $script..." -NoNewline
    if (Test-Path $script) {
        Write-Host "Found!" -ForegroundColor Green
    } else {
        Write-Host "Not found!" -ForegroundColor Red
        $missingRequiredScripts += $script
    }
}

$missingOptionalScripts = @()
foreach ($script in $optionalScripts) {
    Write-Host "Checking for $script..." -NoNewline
    if (Test-Path $script) {
        Write-Host "Found!" -ForegroundColor Green
    } else {
        Write-Host "Not found!" -ForegroundColor Yellow
        $missingOptionalScripts += $script
    }
}

Write-Host ""

# Check each tool
$allRequiredToolsInstalled = $true
$optionalToolsStatus = @{}

foreach ($tool in $requiredTools.Keys) {
    $toolInfo = $requiredTools[$tool]
    $isRequired = $toolInfo.Required
    
    Write-Host "Checking for $tool..." -NoNewline
    
    try {
        $output = Invoke-Expression $toolInfo.Command 2>&1
        $version = $output -join " "
        
        if (Test-MinimumVersion -CurrentVersion $version -MinimumVersion $toolInfo.MinVersion) {
            Write-Host "Found!" -ForegroundColor Green
            Write-Host "  Version: $version"
            
            if (-not $isRequired) {
                $optionalToolsStatus[$tool] = $true
            }
        } else {
            Write-Host "Outdated!" -ForegroundColor Yellow
            Write-Host "  Found version: $version"
            Write-Host "  Required version: $($toolInfo.MinVersion) or later"
            Write-Host "  Please update from: $($toolInfo.DownloadUrl)"
            
            if ($isRequired) {
                $allRequiredToolsInstalled = $false
            } else {
                $optionalToolsStatus[$tool] = $false
            }
        }
    } catch {
        Write-Host "Not found!" -ForegroundColor $(if ($isRequired) { "Red" } else { "Yellow" })
        Write-Host "  Please install from: $($toolInfo.DownloadUrl)"
        
        if ($isRequired) {
            $allRequiredToolsInstalled = $false
        } else {
            $optionalToolsStatus[$tool] = $false
        }
    }
    
    Write-Host ""
}

# Summary
Write-Host "\n=============================================" -ForegroundColor Cyan
Write-Host "   Requirements Check Summary   " -ForegroundColor Cyan
Write-Host "=============================================\n" -ForegroundColor Cyan

# Tools summary
if ($allRequiredToolsInstalled) {
    Write-Host "✓ All required tools are installed." -ForegroundColor Green
} else {
    Write-Host "✗ Some required tools are missing." -ForegroundColor Red
    Write-Host "  Please install the missing required tools before proceeding.\n"
}

Write-Host "Optional Tools Status:"
foreach ($tool in $optionalToolsStatus.Keys) {
    $status = $optionalToolsStatus[$tool]
    $statusText = if ($status) { "✓ Installed" } else { "✗ Not installed" }
    $statusColor = if ($status) { "Green" } else { "Yellow" }
    
    Write-Host "  $tool: " -NoNewline
    Write-Host $statusText -ForegroundColor $statusColor
}

Write-Host "\nNote: Optional tools are not required but recommended for full functionality."
Write-Host "      - ImageMagick: Required for icon conversion"
Write-Host "      - UPX: Required for executable compression"
Write-Host "      - Inno Setup or NSIS: Required for installer creation"

# Scripts summary
Write-Host "\nScripts Status:"
if ($missingRequiredScripts.Count -eq 0) {
    Write-Host "✓ All required scripts are present." -ForegroundColor Green
} else {
    Write-Host "✗ Some required scripts are missing:" -ForegroundColor Red
    foreach ($script in $missingRequiredScripts) {
        Write-Host "  - $script" -ForegroundColor Red
    }
}

if ($missingOptionalScripts.Count -eq 0) {
    Write-Host "✓ All optional scripts are present." -ForegroundColor Green
} else {
    Write-Host "! Some optional scripts are missing:" -ForegroundColor Yellow
    foreach ($script in $missingOptionalScripts) {
        Write-Host "  - $script" -ForegroundColor Yellow
    }
    Write-Host "  These scripts provide additional functionality but are not required."
}

Write-Host "\nScript Functions:"
Write-Host "  - verify-package.ps1: Verifies the packaged application before distribution"
Write-Host "  - cleanup.ps1: Cleans up temporary files and build artifacts"
Write-Host "  - troubleshoot-packaging.ps1: Helps diagnose packaging issues"
Write-Host ""

# Final verdict
if ($allRequiredToolsInstalled -and $missingRequiredScripts.Count -eq 0) {
    Write-Host "You can proceed with packaging JET IDE." -ForegroundColor Green
    Write-Host "Run build-and-package.ps1 to start the packaging process.\n"
} else {
    Write-Host "Please address the missing requirements before proceeding with packaging.\n" -ForegroundColor Red
}