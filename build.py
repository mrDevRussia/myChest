import os
import sys
import subprocess
import shutil
from pathlib import Path

def convert_svg_to_ico():
    """Convert SVG icon to ICO format for Windows applications"""
    try:
        # Try to import cairosvg for SVG conversion
        from cairosvg import svg2png
        from PIL import Image
        
        print("Converting SVG to ICO...")
        
        # Convert SVG to PNG first
        svg_path = os.path.join(os.getcwd(), "icon.svg")
        png_path = os.path.join(os.getcwd(), "icon.png")
        ico_path = os.path.join(os.getcwd(), "icon.ico")
        
        # Create PNG in different sizes
        sizes = [16, 32, 48, 64, 128, 256]
        png_files = []
        
        for size in sizes:
            size_png_path = os.path.join(os.getcwd(), f"icon_{size}.png")
            svg2png(url=svg_path, write_to=size_png_path, output_width=size, output_height=size)
            png_files.append(size_png_path)
        
        # Create ICO file with multiple sizes
        img = Image.open(png_files[0])
        img.save(ico_path, format='ICO', sizes=[(s, s) for s in sizes])
        
        # Clean up temporary PNG files
        for png_file in png_files:
            os.remove(png_file)
            
        print(f"Icon converted successfully: {ico_path}")
        return ico_path
    
    except ImportError:
        print("Warning: cairosvg or PIL not installed. Using default icon.")
        print("To convert SVG to ICO, install: pip install cairosvg pillow")
        return None

def build_executable():
    """Build the executable using PyInstaller"""
    print("\nBuilding ArcSentinel executable...")
    
    # Use existing icon.png file
    icon_path = os.path.join(os.getcwd(), "icon.png")
    
    # PyInstaller command
    cmd = [
        "pyinstaller",
        "--onefile",
        "--windowed",
        "--clean",
        "--name=ArcSentinel",
    ]
    
    # Add icon if available
    if os.path.exists(icon_path):
        cmd.extend(["--icon", icon_path])
    
    # Add main script
    cmd.append("ArcSentinel.py")
    
    # Run PyInstaller
    print(f"Running command: {' '.join(cmd)}")
    result = subprocess.run(cmd, capture_output=True, text=True)
    
    if result.returncode != 0:
        print("Error building executable:")
        print(result.stderr)
        return False
    
    print("\nExecutable built successfully!")
    
    # Copy additional files to dist folder
    dist_dir = os.path.join(os.getcwd(), "dist")
    
    # Copy README and other files
    for file in ["README.md", "icon.svg"]:
        if os.path.exists(file):
            shutil.copy(file, os.path.join(dist_dir, file))
    
    print(f"\nArcSentinel executable is ready in: {dist_dir}\ArcSentinel.exe")
    return True

def install_requirements():
    """Install required packages"""
    print("Installing required packages...")
    req_path = os.path.join(os.getcwd(), "requirements.txt")
    
    if os.path.exists(req_path):
        cmd = [sys.executable, "-m", "pip", "install", "-r", req_path]
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode != 0:
            print("Error installing requirements:")
            print(result.stderr)
            return False
        
        print("Requirements installed successfully!")
        return True
    else:
        print("requirements.txt not found!")
        return False

def main():
    print("===== ArcSentinel Build Script =====")
    
    # Install requirements first
    if not install_requirements():
        print("Failed to install requirements. Build aborted.")
        return
    
    # Build the executable
    if build_executable():
        print("\nBuild completed successfully!")
    else:
        print("\nBuild failed!")

if __name__ == "__main__":
    main()