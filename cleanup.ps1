# Script to clean up build artifacts after packaging JET IDE

# Display header
Write-Host "\n=============================================" -ForegroundColor Cyan
Write-Host "   JET IDE Packaging Cleanup Tool   " -ForegroundColor Cyan
Write-Host "=============================================\n" -ForegroundColor Cyan

# Function to safely remove a directory
function Remove-DirectorySafely {
    param (
        [string]$Path,
        [string]$Description
    )
    
    if (Test-Path $Path) {
        Write-Host "Removing $Description..." -NoNewline
        
        try {
            Remove-Item -Path $Path -Recurse -Force
            Write-Host "Done!" -ForegroundColor Green
            return $true
        } catch {
            Write-Host "Failed!" -ForegroundColor Red
            Write-Host "  Error: $_"
            return $false
        }
    } else {
        Write-Host "$Description not found, skipping." -ForegroundColor Yellow
        return $true
    }
}

# Function to safely remove a file
function Remove-FileSafely {
    param (
        [string]$Path,
        [string]$Description
    )
    
    if (Test-Path $Path) {
        Write-Host "Removing $Description..." -NoNewline
        
        try {
            Remove-Item -Path $Path -Force
            Write-Host "Done!" -ForegroundColor Green
            return $true
        } catch {
            Write-Host "Failed!" -ForegroundColor Red
            Write-Host "  Error: $_"
            return $false
        }
    } else {
        Write-Host "$Description not found, skipping." -ForegroundColor Yellow
        return $true
    }
}

# Ask user what to clean up
Write-Host "What would you like to clean up?\n"
Write-Host "1. Temporary build files only (preserves final outputs)"
Write-Host "2. All build artifacts (including published executable and installer)"
Write-Host "3. Everything (complete cleanup, including all scripts and outputs)"
Write-Host "4. Custom cleanup (select specific items to clean up)"

$cleanupOption = Read-Host "\nEnter your choice (1-4)"

# Define cleanup targets
$tempBuildDirs = @(
    @{ Path = "JET.App\bin"; Description = "bin directory" },
    @{ Path = "JET.App\obj"; Description = "obj directory" }
)

$buildArtifactDirs = @(
    @{ Path = "publish"; Description = "publish directory" },
    @{ Path = "installer"; Description = "installer directory" },
    @{ Path = "update-server"; Description = "update server directory" }
)

$scriptFiles = @(
    @{ Path = "convert-icon.ps1"; Description = "icon conversion script" },
    @{ Path = "package-app.ps1"; Description = "packaging script" },
    @{ Path = "compress-exe.ps1"; Description = "compression script" },
    @{ Path = "create-installer.ps1"; Description = "Inno Setup installer script" },
    @{ Path = "create-nsis-installer.ps1"; Description = "NSIS installer script" },
    @{ Path = "setup-auto-updates.ps1"; Description = "auto-updates setup script" },
    @{ Path = "build-and-package.ps1"; Description = "master build script" },
    @{ Path = "build-and-package.bat"; Description = "batch file wrapper" },
    @{ Path = "check-requirements.ps1"; Description = "requirements check script" },
    @{ Path = "troubleshoot-packaging.ps1"; Description = "troubleshooting script" },
    @{ Path = "cleanup.ps1"; Description = "this cleanup script" }
)

$backupFiles = @(
    @{ Path = "publish\JET.exe.backup"; Description = "executable backup" }
)

# Perform cleanup based on user choice
switch ($cleanupOption) {
    "1" {
        Write-Host "\nCleaning up temporary build files...\n" -ForegroundColor Yellow
        
        foreach ($dir in $tempBuildDirs) {
            Remove-DirectorySafely -Path $dir.Path -Description $dir.Description
        }
        
        foreach ($file in $backupFiles) {
            Remove-FileSafely -Path $file.Path -Description $file.Description
        }
    }
    "2" {
        Write-Host "\nCleaning up all build artifacts...\n" -ForegroundColor Yellow
        
        foreach ($dir in $tempBuildDirs) {
            Remove-DirectorySafely -Path $dir.Path -Description $dir.Description
        }
        
        foreach ($dir in $buildArtifactDirs) {
            Remove-DirectorySafely -Path $dir.Path -Description $dir.Description
        }
        
        foreach ($file in $backupFiles) {
            Remove-FileSafely -Path $file.Path -Description $file.Description
        }
    }
    "3" {
        Write-Host "\nPerforming complete cleanup...\n" -ForegroundColor Yellow
        
        $confirmation = Read-Host "This will remove ALL packaging scripts and outputs. Are you sure? (Y/N)"
        
        if ($confirmation -eq "Y" -or $confirmation -eq "y") {
            foreach ($dir in $tempBuildDirs) {
                Remove-DirectorySafely -Path $dir.Path -Description $dir.Description
            }
            
            foreach ($dir in $buildArtifactDirs) {
                Remove-DirectorySafely -Path $dir.Path -Description $dir.Description
            }
            
            foreach ($file in $scriptFiles) {
                Remove-FileSafely -Path $file.Path -Description $file.Description
            }
            
            foreach ($file in $backupFiles) {
                Remove-FileSafely -Path $file.Path -Description $file.Description
            }
            
            Remove-FileSafely -Path "PACKAGING.md" -Description "packaging documentation"
        } else {
            Write-Host "Complete cleanup cancelled." -ForegroundColor Yellow
        }
    }
    "4" {
        Write-Host "\nCustom cleanup - select items to clean up:\n" -ForegroundColor Yellow
        
        Write-Host "Temporary build directories:"
        for ($i = 0; $i -lt $tempBuildDirs.Count; $i++) {
            Write-Host "$($i+1). $($tempBuildDirs[$i].Description)"
        }
        
        Write-Host "\nBuild artifact directories:"
        for ($i = 0; $i -lt $buildArtifactDirs.Count; $i++) {
            Write-Host "$($i+1+$tempBuildDirs.Count). $($buildArtifactDirs[$i].Description)"
        }
        
        Write-Host "\nScript files:"
        for ($i = 0; $i -lt $scriptFiles.Count; $i++) {
            Write-Host "$($i+1+$tempBuildDirs.Count+$buildArtifactDirs.Count). $($scriptFiles[$i].Description)"
        }
        
        Write-Host "\nOther files:"
        Write-Host "$($tempBuildDirs.Count+$buildArtifactDirs.Count+$scriptFiles.Count+1). packaging documentation"
        
        $selections = Read-Host "Enter the numbers of items to clean up, separated by commas (e.g., 1,3,5)"
        $selectedItems = $selections -split ',' | ForEach-Object { $_.Trim() }
        
        foreach ($item in $selectedItems) {
            $index = [int]$item - 1
            
            if ($index -lt $tempBuildDirs.Count) {
                Remove-DirectorySafely -Path $tempBuildDirs[$index].Path -Description $tempBuildDirs[$index].Description
            } elseif ($index -lt ($tempBuildDirs.Count + $buildArtifactDirs.Count)) {
                $artifactIndex = $index - $tempBuildDirs.Count
                Remove-DirectorySafely -Path $buildArtifactDirs[$artifactIndex].Path -Description $buildArtifactDirs[$artifactIndex].Description
            } elseif ($index -lt ($tempBuildDirs.Count + $buildArtifactDirs.Count + $scriptFiles.Count)) {
                $scriptIndex = $index - $tempBuildDirs.Count - $buildArtifactDirs.Count
                Remove-FileSafely -Path $scriptFiles[$scriptIndex].Path -Description $scriptFiles[$scriptIndex].Description
            } elseif ($index -eq ($tempBuildDirs.Count + $buildArtifactDirs.Count + $scriptFiles.Count)) {
                Remove-FileSafely -Path "PACKAGING.md" -Description "packaging documentation"
            }
        }
    }
    default {
        Write-Host "Invalid option. No cleanup performed." -ForegroundColor Red
    }
}

# Summary
Write-Host "\nCleanup completed!" -ForegroundColor Green
Write-Host "If you want to package JET IDE again, make sure the necessary scripts are still available."