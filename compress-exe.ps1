# Script to compress the JET IDE executable using UPX

# Configuration
$publishDir = "publish"
$exePath = "$publishDir\JET.exe"
$upxPath = "upx.exe" # Assumes UPX is in PATH, adjust if needed

# Check if the published app exists
if (!(Test-Path $exePath)) {
    Write-Host "Error: Published application not found at $exePath" -ForegroundColor Red
    Write-Host "Please run package-app.ps1 first to create the self-contained executable."
    exit 1
}

# Check if UPX is installed
$upxInstalled = $false
try {
    $upxVersion = & $upxPath --version 2>&1
    if ($upxVersion -match "UPX") {
        $upxInstalled = $true
        Write-Host "UPX is installed: $upxVersion"
    }
} catch {
    # UPX not found
}

if (!$upxInstalled) {
    Write-Host "UPX not found in PATH" -ForegroundColor Yellow
    Write-Host "Please download UPX from https://github.com/upx/upx/releases"
    Write-Host "Extract the upx.exe file and either:"
    Write-Host "1. Add it to your PATH"
    Write-Host "2. Place it in the same directory as this script"
    Write-Host "3. Update this script with the correct path to upx.exe"
    
    $downloadUPX = Read-Host "Would you like to open the UPX download page? (Y/N)"
    if ($downloadUPX -eq "Y" -or $downloadUPX -eq "y") {
        Start-Process "https://github.com/upx/upx/releases"
    }
    exit 1
}

# Get original file size
$originalSize = (Get-Item $exePath).Length / 1MB
Write-Host "Original file size: $($originalSize.ToString('0.00')) MB"

# Compress the executable
Write-Host "Compressing $exePath using UPX..."
try {
    # Make a backup of the original file
    Copy-Item $exePath "$exePath.backup"
    Write-Host "Backup created at $exePath.backup"
    
    # Compress with UPX using best compression
    & $upxPath --best $exePath
    
    if ($LASTEXITCODE -eq 0) {
        $compressedSize = (Get-Item $exePath).Length / 1MB
        $savingsPercent = (1 - ($compressedSize / $originalSize)) * 100
        
        Write-Host "\nCompression successful!" -ForegroundColor Green
        Write-Host "Compressed file size: $($compressedSize.ToString('0.00')) MB"
        Write-Host "Size reduction: $($savingsPercent.ToString('0.00'))%"
    } else {
        Write-Host "Error: UPX compression failed with exit code $LASTEXITCODE" -ForegroundColor Red
        Write-Host "Restoring backup..."
        Copy-Item "$exePath.backup" $exePath
        Write-Host "Original file restored."
    }
} catch {
    Write-Host "Error during compression: $_" -ForegroundColor Red
    if (Test-Path "$exePath.backup") {
        Write-Host "Restoring backup..."
        Copy-Item "$exePath.backup" $exePath
        Write-Host "Original file restored."
    }
    exit 1
}

# Cleanup backup if successful
if ($LASTEXITCODE -eq 0) {
    Remove-Item "$exePath.backup"
    Write-Host "Backup file removed."
}

# Suggest next steps
Write-Host "\nNext steps:"
Write-Host "1. Test the compressed application by running: $exePath"
Write-Host "2. Create an installer using the create-installer.ps1 or create-nsis-installer.ps1 script"