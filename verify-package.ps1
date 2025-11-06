# Script to verify the packaged JET IDE application before distribution

# Display header
Write-Host "\n=============================================" -ForegroundColor Cyan
Write-Host "   JET IDE Package Verification Tool   " -ForegroundColor Cyan
Write-Host "=============================================\n" -ForegroundColor Cyan

# Define paths
$publishDir = "publish"
$installerDir = "installer"
$exePath = Join-Path $publishDir "JET.exe"
$innoInstallerPath = Join-Path $installerDir "JET-IDE-Setup.exe"
$nsisInstallerPath = Join-Path $installerDir "JET-IDE-Setup-NSIS.exe"

# Function to check file existence and size
function Test-FileDetails {
    param (
        [string]$Path,
        [string]$Description
    )
    
    Write-Host "Checking $Description..." -NoNewline
    
    if (Test-Path $Path) {
        $fileInfo = Get-Item $Path
        $sizeInMB = [math]::Round($fileInfo.Length / 1MB, 2)
        
        Write-Host "Found!" -ForegroundColor Green
        Write-Host "  - Size: $sizeInMB MB"
        Write-Host "  - Last Modified: $($fileInfo.LastWriteTime)"
        return $true
    } else {
        Write-Host "Not found!" -ForegroundColor Red
        return $false
    }
}

# Function to check directory existence and content
function Test-DirectoryDetails {
    param (
        [string]$Path,
        [string]$Description
    )
    
    Write-Host "Checking $Description..." -NoNewline
    
    if (Test-Path $Path) {
        $dirInfo = Get-Item $Path
        $fileCount = (Get-ChildItem $Path -File -Recurse).Count
        $dirCount = (Get-ChildItem $Path -Directory -Recurse).Count
        
        Write-Host "Found!" -ForegroundColor Green
        Write-Host "  - Contains: $fileCount files in $dirCount directories"
        Write-Host "  - Last Modified: $($dirInfo.LastWriteTime)"
        return $true
    } else {
        Write-Host "Not found!" -ForegroundColor Red
        return $false
    }
}

# Function to verify executable
function Test-Executable {
    param (
        [string]$Path
    )
    
    if (Test-Path $Path) {
        Write-Host "Verifying executable integrity..." -NoNewline
        
        try {
            $signature = Get-AuthenticodeSignature $Path
            if ($signature.Status -eq "Valid") {
                Write-Host "Signed and valid!" -ForegroundColor Green
                Write-Host "  - Signed by: $($signature.SignerCertificate.Subject)"
            } else {
                Write-Host "Not signed or invalid signature." -ForegroundColor Yellow
                Write-Host "  - Status: $($signature.Status)"
            }
            
            # Check if it's a .NET assembly
            try {
                $assembly = [System.Reflection.Assembly]::LoadFile($Path)
                Write-Host "  - Assembly Version: $($assembly.GetName().Version)"
                Write-Host "  - Runtime Version: $($assembly.ImageRuntimeVersion)"
            } catch {
                Write-Host "  - Could not load as .NET assembly: $_" -ForegroundColor Yellow
            }
            
            return $true
        } catch {
            Write-Host "Error verifying!" -ForegroundColor Red
            Write-Host "  - Error: $_"
            return $false
        }
    }
    return $false
}

# Function to check dependencies
function Test-Dependencies {
    param (
        [string]$Path
    )
    
    if (Test-Path $Path) {
        $dllFiles = Get-ChildItem -Path (Split-Path $Path -Parent) -Filter "*.dll" -File
        
        Write-Host "Checking dependencies..." 
        Write-Host "  - Found $($dllFiles.Count) DLL files"
        
        # List top 5 largest DLLs
        if ($dllFiles.Count -gt 0) {
            Write-Host "  - Top 5 largest dependencies:"
            $dllFiles | Sort-Object Length -Descending | Select-Object -First 5 | ForEach-Object {
                $sizeInMB = [math]::Round($_.Length / 1MB, 2)
                Write-Host "    * $($_.Name) - $sizeInMB MB"
            }
        }
        
        return $true
    }
    return $false
}

# Main verification process
Write-Host "Starting verification process...\n" -ForegroundColor Yellow

# Check publish directory
$publishDirExists = Test-DirectoryDetails -Path $publishDir -Description "publish directory"

# Check executable
if ($publishDirExists) {
    $exeExists = Test-FileDetails -Path $exePath -Description "JET executable"
    
    if ($exeExists) {
        Test-Executable -Path $exePath
        Test-Dependencies -Path $exePath
    }
}

# Check installer directory
$installerDirExists = Test-DirectoryDetails -Path $installerDir -Description "installer directory"

# Check installers
if ($installerDirExists) {
    $innoInstallerExists = Test-FileDetails -Path $innoInstallerPath -Description "Inno Setup installer"
    $nsisInstallerExists = Test-FileDetails -Path $nsisInstallerPath -Description "NSIS installer"
    
    if ($innoInstallerExists) {
        Test-Executable -Path $innoInstallerPath
    }
    
    if ($nsisInstallerExists) {
        Test-Executable -Path $nsisInstallerPath
    }
}

# Verification summary
Write-Host "\nVerification Summary:" -ForegroundColor Yellow
Write-Host "-------------------"

if ($publishDirExists -and $exeExists) {
    Write-Host "✓ Executable package is available" -ForegroundColor Green
} else {
    Write-Host "✗ Executable package is missing" -ForegroundColor Red
}

if ($installerDirExists -and ($innoInstallerExists -or $nsisInstallerExists)) {
    Write-Host "✓ Installer package is available" -ForegroundColor Green
    
    if ($innoInstallerExists) {
        Write-Host "  - Inno Setup installer is ready" -ForegroundColor Green
    } else {
        Write-Host "  - Inno Setup installer is missing" -ForegroundColor Yellow
    }
    
    if ($nsisInstallerExists) {
        Write-Host "  - NSIS installer is ready" -ForegroundColor Green
    } else {
        Write-Host "  - NSIS installer is missing" -ForegroundColor Yellow
    }
} else {
    Write-Host "✗ Installer package is missing" -ForegroundColor Red
}

# Recommendations
Write-Host "\nRecommendations:" -ForegroundColor Yellow
Write-Host "-----------------"

if (-not $publishDirExists -or -not $exeExists) {
    Write-Host "! Run package-app.ps1 to create the executable package" -ForegroundColor Magenta
}

if (-not $installerDirExists -or (-not $innoInstallerExists -and -not $nsisInstallerExists)) {
    Write-Host "! Run create-installer.ps1 or create-nsis-installer.ps1 to create an installer" -ForegroundColor Magenta
}

if ($publishDirExists -and $exeExists) {
    Write-Host "! Test the application by running $exePath" -ForegroundColor Magenta
}

if ($installerDirExists -and ($innoInstallerExists -or $nsisInstallerExists)) {
    if ($innoInstallerExists) {
        Write-Host "! Test the Inno Setup installer by running $innoInstallerPath" -ForegroundColor Magenta
    }
    if ($nsisInstallerExists) {
        Write-Host "! Test the NSIS installer by running $nsisInstallerPath" -ForegroundColor Magenta
    }
}

Write-Host "\nVerification process completed!" -ForegroundColor Green