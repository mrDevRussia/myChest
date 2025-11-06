# Master script to build and package JET IDE
# This script orchestrates the entire build, packaging, and installer creation process

# Configuration
$appName = "JET IDE"
$appVersion = "1.0.0"

# Display header
Write-Host "\n=============================================" -ForegroundColor Cyan
Write-Host "   $appName v$appVersion Build & Packaging Tool   " -ForegroundColor Cyan
Write-Host "=============================================\n" -ForegroundColor Cyan

# Function to check if a command was successful
function Test-CommandSuccess {
    param (
        [string]$StepName,
        [int]$ExitCode
    )
    
    if ($ExitCode -eq 0) {
        Write-Host "✓ $StepName completed successfully." -ForegroundColor Green
        return $true
    } else {
        Write-Host "✗ $StepName failed with exit code $ExitCode." -ForegroundColor Red
        return $false
    }
}

# Step 1: Convert SVG icon to ICO (if needed)
Write-Host "\nStep 1: Converting SVG icon to ICO format..." -ForegroundColor Yellow
$icoPath = "JET.App\Resources\Icons\jet-icon.ico"
if (!(Test-Path $icoPath)) {
    Write-Host "Icon file not found at $icoPath"
    Write-Host "You need to convert the SVG icon to ICO format."
    Write-Host "Options:"
    Write-Host "1. Run convert-icon.ps1 (requires ImageMagick)"
    Write-Host "2. Use an online converter service"
    Write-Host "3. Skip icon conversion (the application will use a default icon)"
    
    $iconChoice = Read-Host "Choose an option (1-3)"
    
    switch ($iconChoice) {
        "1" {
            if (Test-Path "convert-icon.ps1") {
                & .\convert-icon.ps1
                if (!(Test-CommandSuccess "Icon conversion" $LASTEXITCODE)) {
                    Write-Host "Continuing without custom icon..."
                }
            } else {
                Write-Host "convert-icon.ps1 not found. Continuing without custom icon..."
            }
        }
        "2" {
            Write-Host "Please use an online converter and save the ICO file to $icoPath"
            $continue = Read-Host "Press Enter when done, or type 'skip' to continue without custom icon"
            if ($continue -eq "skip") {
                Write-Host "Continuing without custom icon..."
            }
        }
        "3" {
            Write-Host "Continuing without custom icon..."
        }
        default {
            Write-Host "Invalid option. Continuing without custom icon..."
        }
    }
} else {
    Write-Host "Icon file found at $icoPath"
}

# Step 2: Build and publish the application
Write-Host "\nStep 2: Building and publishing the application..." -ForegroundColor Yellow
if (Test-Path "package-app.ps1") {
    & .\package-app.ps1
    if (!(Test-CommandSuccess "Application build and publish" $LASTEXITCODE)) {
        Write-Host "Build failed. Exiting..."
        exit 1
    }
} else {
    Write-Host "package-app.ps1 not found. Attempting to build directly..."
    
    try {
        dotnet publish JET.App `
            -c Release `
            -r win-x64 `
            -p:PublishSingleFile=true `
            -p:PublishTrimmed=true `
            -p:PublishReadyToRun=true `
            --self-contained true `
            -o publish
        
        if (Test-CommandSuccess "Application build and publish" $LASTEXITCODE) {
            $exePath = "publish\JET.exe"
            if (Test-Path $exePath) {
                $fileSize = (Get-Item $exePath).Length / 1MB
                Write-Host "Executable created at: $exePath"
                Write-Host "File size: $($fileSize.ToString('0.00')) MB"
            } else {
                Write-Host "Error: Executable not found after publishing."
                exit 1
            }
        } else {
            Write-Host "Build failed. Exiting..."
            exit 1
        }
    } catch {
        Write-Host "Error during publishing: $_"
        exit 1
    }
}

# Step 3: Compress the executable (optional)
Write-Host "\nStep 3: Compress the executable with UPX (optional)..." -ForegroundColor Yellow
Write-Host "Compressing the executable can significantly reduce its size."
$compressChoice = Read-Host "Do you want to compress the executable? (Y/N)"

if ($compressChoice -eq "Y" -or $compressChoice -eq "y") {
    if (Test-Path "compress-exe.ps1") {
        & .\compress-exe.ps1
        Test-CommandSuccess "Executable compression" $LASTEXITCODE
    } else {
        Write-Host "compress-exe.ps1 not found. Skipping compression..."
    }
} else {
    Write-Host "Skipping compression..."
}

# Step 4: Create installer
Write-Host "\nStep 4: Create installer..." -ForegroundColor Yellow
Write-Host "Choose an installer type:"
Write-Host "1. Inno Setup installer (recommended for most users)"
Write-Host "2. NSIS installer (more customizable)"
Write-Host "3. Skip installer creation"

$installerChoice = Read-Host "Choose an option (1-3)"

switch ($installerChoice) {
    "1" {
        if (Test-Path "create-installer.ps1") {
            & .\create-installer.ps1
            Test-CommandSuccess "Inno Setup installer creation" $LASTEXITCODE
        } else {
            Write-Host "create-installer.ps1 not found. Skipping installer creation..."
        }
    }
    "2" {
        if (Test-Path "create-nsis-installer.ps1") {
            & .\create-nsis-installer.ps1
            Test-CommandSuccess "NSIS installer creation" $LASTEXITCODE
        } else {
            Write-Host "create-nsis-installer.ps1 not found. Skipping installer creation..."
        }
    }
    "3" {
        Write-Host "Skipping installer creation..."
    }
    default {
        Write-Host "Invalid option. Skipping installer creation..."
    }
}

# Step 5: Set up automatic updates (optional)
Write-Host "\nStep 5: Set up automatic updates (optional)..." -ForegroundColor Yellow
Write-Host "Setting up automatic updates allows your application to check for and install updates."
$updateChoice = Read-Host "Do you want to set up automatic updates? (Y/N)"

if ($updateChoice -eq "Y" -or $updateChoice -eq "y") {
    if (Test-Path "setup-auto-updates.ps1") {
        & .\setup-auto-updates.ps1
        Test-CommandSuccess "Automatic updates setup" $LASTEXITCODE
    } else {
        Write-Host "setup-auto-updates.ps1 not found. Skipping automatic updates setup..."
    }
} else {
    Write-Host "Skipping automatic updates setup..."
}

# Step 6: Verify the package (optional)
Write-Host "\nStep 6: Verify the package (optional)..." -ForegroundColor Yellow
Write-Host "Verifying the package helps ensure everything is working correctly before distribution."
$verifyChoice = Read-Host "Do you want to verify the package? (Y/N)"

if ($verifyChoice -eq "Y" -or $verifyChoice -eq "y") {
    if (Test-Path "verify-package.ps1") {
        & .\verify-package.ps1
        Test-CommandSuccess "Package verification" $LASTEXITCODE
    } else {
        Write-Host "verify-package.ps1 not found. Skipping verification..."
    }
} else {
    Write-Host "Skipping package verification..."
}

# Step 7: Cleanup (optional)
Write-Host "\nStep 7: Cleanup (optional)..." -ForegroundColor Yellow
Write-Host "Cleaning up temporary files and build artifacts can help maintain a tidy workspace."
$cleanupChoice = Read-Host "Do you want to run the cleanup tool? (Y/N)"

if ($cleanupChoice -eq "Y" -or $cleanupChoice -eq "y") {
    if (Test-Path "cleanup.ps1") {
        & .\cleanup.ps1
        Test-CommandSuccess "Cleanup" $LASTEXITCODE
    } else {
        Write-Host "cleanup.ps1 not found. Skipping cleanup..."
    }
} else {
    Write-Host "Skipping cleanup..."
}

# Summary
Write-Host "\n=============================================" -ForegroundColor Cyan
Write-Host "   Build and Packaging Summary   " -ForegroundColor Cyan
Write-Host "=============================================\n" -ForegroundColor Cyan

$exePath = "publish\JET.exe"
if (Test-Path $exePath) {
    $exeSize = (Get-Item $exePath).Length / 1MB
    Write-Host "✓ Executable:" -ForegroundColor Green
    Write-Host "  - Path: $exePath"
    Write-Host "  - Size: $($exeSize.ToString('0.00')) MB"
} else {
    Write-Host "✗ Executable not found" -ForegroundColor Red
}

$installerPath = "installer\JET-IDE-Setup.exe"
if (Test-Path $installerPath) {
    $installerSize = (Get-Item $installerPath).Length / 1MB
    Write-Host "\n✓ Installer:" -ForegroundColor Green
    Write-Host "  - Path: $installerPath"
    Write-Host "  - Size: $($installerSize.ToString('0.00')) MB"
} else {
    $nsisInstallerPath = "installer\JET-IDE-Setup-NSIS.exe"
    if (Test-Path $nsisInstallerPath) {
        $nsisInstallerSize = (Get-Item $nsisInstallerPath).Length / 1MB
        Write-Host "\n✓ NSIS Installer:" -ForegroundColor Green
        Write-Host "  - Path: $nsisInstallerPath"
        Write-Host "  - Size: $($nsisInstallerSize.ToString('0.00')) MB"
    } else {
        Write-Host "\n✗ Installer not created" -ForegroundColor Yellow
    }
}


Write-Host "\nNext steps:"
Write-Host "1. Test the application by running: $exePath"
if (Test-Path $installerPath) {
    Write-Host "2. Test the installer by running: $installerPath"
    Write-Host "3. Distribute the installer to users"
} elseif (Test-Path $nsisInstallerPath) {
    Write-Host "2. Test the installer by running: $nsisInstallerPath"
    Write-Host "3. Distribute the installer to users"
} else {
    Write-Host "2. Create an installer using create-installer.ps1 or create-nsis-installer.ps1"
    Write-Host "3. Distribute the application to users"
}

Write-Host "\nThank you for using the $appName Build & Packaging Tool!\n"