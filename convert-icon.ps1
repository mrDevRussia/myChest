# Script to convert SVG to ICO using ImageMagick
# First, check if ImageMagick is installed
$imageMagickInstalled = $false
try {
    $magickVersion = magick -version
    $imageMagickInstalled = $true
    Write-Host "ImageMagick is installed: $magickVersion"
} catch {
    Write-Host "ImageMagick is not installed. Please install it from https://imagemagick.org/script/download.php"
    Write-Host "Or use an online converter service to convert your SVG to ICO format."
    exit 1
}

# Paths
$svgPath = "JET.App\Resources\Icons\jet-icon.svg"
$icoPath = "JET.App\Resources\Icons\jet-icon.ico"

# Check if SVG exists
if (!(Test-Path $svgPath)) {
    Write-Host "Error: SVG file not found at $svgPath"
    exit 1
}

# Convert SVG to ICO with multiple sizes
if ($imageMagickInstalled) {
    Write-Host "Converting $svgPath to $icoPath..."
    try {
        # Create ICO with multiple sizes (16x16, 32x32, 48x48, 64x64, 128x128, 256x256)
        magick convert $svgPath -background none -resize 256x256 -define icon:auto-resize=16,32,48,64,128,256 $icoPath
        Write-Host "Conversion successful! Icon saved to $icoPath"
    } catch {
        Write-Host "Error during conversion: $_"
        exit 1
    }
}