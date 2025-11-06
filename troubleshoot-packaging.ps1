# Script to help troubleshoot common packaging issues for JET IDE

# Display header
Write-Host "\n=============================================" -ForegroundColor Cyan
Write-Host "   JET IDE Packaging Troubleshooter   " -ForegroundColor Cyan
Write-Host "=============================================\n" -ForegroundColor Cyan

# Function to check if a file exists and display its details
function Test-FileExists {
    param (
        [string]$FilePath,
        [string]$Description
    )
    
    Write-Host "Checking for $Description..." -NoNewline
    
    if (Test-Path $FilePath) {
        $file = Get-Item $FilePath
        $fileSize = $file.Length / 1MB
        Write-Host "Found!" -ForegroundColor Green
        Write-Host "  Path: $FilePath"
        Write-Host "  Size: $($fileSize.ToString('0.00')) MB"
        Write-Host "  Last Modified: $($file.LastWriteTime)"
        return $true
    } else {
        Write-Host "Not found!" -ForegroundColor Red
        return $false
    }
}

# Function to check if a directory exists and display its details
function Test-DirectoryExists {
    param (
        [string]$DirectoryPath,
        [string]$Description
    )
    
    Write-Host "Checking for $Description..." -NoNewline
    
    if (Test-Path $DirectoryPath -PathType Container) {
        $dir = Get-Item $DirectoryPath
        $fileCount = (Get-ChildItem $DirectoryPath -Recurse | Measure-Object).Count
        Write-Host "Found!" -ForegroundColor Green
        Write-Host "  Path: $DirectoryPath"
        Write-Host "  Contains: $fileCount items"
        Write-Host "  Last Modified: $($dir.LastWriteTime)"
        return $true
    } else {
        Write-Host "Not found!" -ForegroundColor Red
        return $false
    }
}

# Function to check if a command is available
function Test-CommandAvailable {
    param (
        [string]$Command,
        [string]$Description
    )
    
    Write-Host "Checking for $Description..." -NoNewline
    
    try {
        $output = Invoke-Expression "$Command 2>&1"
        Write-Host "Available!" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "Not available!" -ForegroundColor Red
        return $false
    }
}

# Check for project files
Write-Host "Checking Project Files:\n" -ForegroundColor Yellow

$projectExists = Test-FileExists -FilePath "JET.App\JET.App.csproj" -Description "Project File"
Test-FileExists -FilePath "JET.App\Resources\Icons\jet-icon.ico" -Description "Application Icon"
Test-FileExists -FilePath "JET.App\Resources\Icons\jet-icon.svg" -Description "SVG Icon"
Test-DirectoryExists -FilePath "JET.App" -Description "Application Directory"

Write-Host ""

# Check for packaging scripts
Write-Host "Checking Packaging Scripts:\n" -ForegroundColor Yellow

Test-FileExists -FilePath "package-app.ps1" -Description "Packaging Script"
Test-FileExists -FilePath "create-installer.ps1" -Description "Installer Creation Script"
Test-FileExists -FilePath "build-and-package.ps1" -Description "Master Build Script"
Test-FileExists -FilePath "verify-package.ps1" -Description "Package Verification Script"
Test-FileExists -FilePath "cleanup.ps1" -Description "Cleanup Script"
Test-FileExists -FilePath "compress-exe.ps1" -Description "Executable Compression Script"
Test-FileExists -FilePath "setup-auto-updates.ps1" -Description "Auto-Updates Setup Script"

Write-Host ""

# Check for output directories
Write-Host "Checking Output Directories:\n" -ForegroundColor Yellow

$publishDirExists = Test-DirectoryExists -FilePath "publish" -Description "Publish Directory"
Test-DirectoryExists -FilePath "installer" -Description "Installer Directory"

Write-Host ""

# Check for required tools
Write-Host "Checking Required Tools:\n" -ForegroundColor Yellow

$dotnetAvailable = Test-CommandAvailable -Command "dotnet --version" -Description ".NET SDK"
Test-CommandAvailable -Command "magick -version" -Description "ImageMagick"
Test-CommandAvailable -Command "upx --version" -Description "UPX"

Write-Host ""

# Check for output files
if ($publishDirExists) {
    Write-Host "Checking Output Files:\n" -ForegroundColor Yellow
    
    Test-FileExists -FilePath "publish\JET.exe" -Description "Published Executable"
    Test-FileExists -FilePath "installer\JET_IDE_Setup.exe" -Description "Installer"
    
    Write-Host ""
}

# Diagnose common issues
Write-Host "Diagnosing Common Issues:\n" -ForegroundColor Yellow

# Check for .NET SDK version
if ($dotnetAvailable) {
    $dotnetVersion = dotnet --version
    $dotnetMajorVersion = [int]($dotnetVersion.Split('.')[0])
    
    if ($dotnetMajorVersion -lt 6) {
        Write-Host "⚠️ Warning: .NET SDK version $dotnetVersion is older than the recommended version 6.0." -ForegroundColor Yellow
        Write-Host "  This may cause issues with the publishing process."
        Write-Host "  Please consider updating to .NET 6.0 or later from https://dotnet.microsoft.com/download"
    } else {
        Write-Host "✓ .NET SDK version $dotnetVersion is compatible." -ForegroundColor Green
    }
}

# Check for project build configuration
if ($projectExists) {
    $projectContent = Get-Content "JET.App\JET.App.csproj" -Raw
    
    if ($projectContent -notmatch '<TargetFramework>net6\.0-windows</TargetFramework>') {
        Write-Host "⚠️ Warning: Project may not be configured for Windows desktop applications." -ForegroundColor Yellow
        Write-Host "  Make sure the project file contains <TargetFramework>net6.0-windows</TargetFramework>"
    } else {
        Write-Host "✓ Project is correctly configured for Windows desktop applications." -ForegroundColor Green
    }
    
    if ($projectContent -notmatch '<UseWPF>true</UseWPF>') {
        Write-Host "⚠️ Warning: Project may not be configured for WPF." -ForegroundColor Yellow
        Write-Host "  Make sure the project file contains <UseWPF>true</UseWPF>"
    } else {
        Write-Host "✓ Project is correctly configured for WPF." -ForegroundColor Green
    }
    
    if ($projectContent -notmatch '<ApplicationIcon>') {
        Write-Host "⚠️ Warning: Project does not specify an application icon." -ForegroundColor Yellow
        Write-Host "  Consider adding <ApplicationIcon>Resources\Icons\jet-icon.ico</ApplicationIcon> to the PropertyGroup"
    } else {
        Write-Host "✓ Project has an application icon specified." -ForegroundColor Green
    }
}

Write-Host ""

# Provide troubleshooting tips
Write-Host "Troubleshooting Tips:\n" -ForegroundColor Yellow

Write-Host "1. If the packaging process fails, check the following:"
Write-Host "   - Ensure all required tools are installed (run check-requirements.ps1)"
Write-Host "   - Make sure the project builds successfully in Visual Studio"
Write-Host "   - Check for any error messages in the console output"

Write-Host "\n2. If the executable is too large:"
Write-Host "   - Use UPX to compress it (run compress-exe.ps1)"
Write-Host "   - Adjust trimming options in package-app.ps1"
Write-Host "   - Consider removing unnecessary dependencies"

Write-Host "\n3. If the installer creation fails:"
Write-Host "   - Make sure Inno Setup or NSIS is installed"
Write-Host "   - Check if the paths in the scripts are correct"
Write-Host "   - Verify that the published executable exists"

Write-Host "\n4. If the application icon is not showing:"
Write-Host "   - Ensure the ICO file exists at the correct location"
Write-Host "   - Make sure the project file references the icon correctly"
Write-Host "   - Rebuild the application after adding the icon"

Write-Host "\n5. If the verification process reports issues:"
Write-Host "   - Run verify-package.ps1 to get detailed diagnostics"
Write-Host "   - Check that all dependencies are included in the package"
Write-Host "   - Ensure the executable runs correctly on its own"

Write-Host "\n6. If you need to clean up after packaging:"
Write-Host "   - Run cleanup.ps1 to remove temporary files and artifacts"
Write-Host "   - Choose the appropriate cleanup level based on your needs"
Write-Host "   - Make sure to keep the files you need for distribution"

Write-Host "\nFor more detailed troubleshooting, refer to PACKAGING.md"