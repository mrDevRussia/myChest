# Script to package JET IDE as a self-contained executable

# Configuration
$projectPath = "JET.App"
$configuration = "Release"
$runtime = "win-x64"
$outputPath = "publish"

# Check if .NET SDK is installed
try {
    $dotnetVersion = dotnet --version
    Write-Host "Using .NET SDK version: $dotnetVersion"
} catch {
    Write-Host "Error: .NET SDK is not installed or not in PATH."
    Write-Host "Please install .NET SDK 6.0 or later from https://dotnet.microsoft.com/download"
    exit 1
}

# Ensure icon is available
$icoPath = "$projectPath\Resources\Icons\jet-icon.ico"
if (!(Test-Path $icoPath)) {
    Write-Host "Warning: Icon file not found at $icoPath"
    Write-Host "Please convert the SVG icon to ICO format using the convert-icon.ps1 script or an online converter."
}

# Create publish directory if it doesn't exist
if (!(Test-Path $outputPath)) {
    New-Item -ItemType Directory -Path $outputPath | Out-Null
}

# Build and publish the application
Write-Host "Building and publishing JET IDE as a self-contained executable..."
Write-Host "This may take a few minutes..."

try {
    dotnet publish $projectPath `
        -c $configuration `
        -r $runtime `
        -p:PublishSingleFile=true `
        -p:PublishTrimmed=true `
        -p:PublishReadyToRun=true `
        --self-contained true `
        -o $outputPath
    
    if ($LASTEXITCODE -eq 0) {
        $exePath = "$outputPath\JET.exe"
        if (Test-Path $exePath) {
            $fileSize = (Get-Item $exePath).Length / 1MB
            Write-Host "\nPackaging successful!" -ForegroundColor Green
            Write-Host "Executable created at: $exePath"
            Write-Host "File size: $($fileSize.ToString('0.00')) MB"
        } else {
            Write-Host "Error: Executable not found after publishing." -ForegroundColor Red
        }
    } else {
        Write-Host "Error: Publishing failed with exit code $LASTEXITCODE" -ForegroundColor Red
    }
} catch {
    Write-Host "Error during publishing: $_" -ForegroundColor Red
    exit 1
}

# Suggest next steps
Write-Host "\nNext steps:"
Write-Host "1. Test the application by running: $outputPath\JET.exe"
Write-Host "2. Create an installer using the create-installer.ps1 script"