import sys
import subprocess
import importlib.util
import os
import time
import tempfile
import pkgutil

def is_module_installed(module_name):
    """Check if a module is installed"""
    try:
        # For packages with different import names than their PyPI names
        if module_name == 'PyQt5':
            import_name = 'PyQt5.QtWidgets'
        elif module_name == 'yara-python':
            import_name = 'yara'
        else:
            import_name = module_name.split('==')[0]  # Remove version if present
        
        spec = importlib.util.find_spec(import_name)
        return spec is not None
    except ImportError:
        return False

def install_dependencies():
    """Install missing dependencies"""
    # Define required packages
    required_packages = [
        'PyQt5',
        'psutil',
        'yara-python',
        'pefile',
        'requests',
        'chardet',
        'numpy'
    ]
    
    # Check if running from a PyInstaller bundle
    if getattr(sys, 'frozen', False):
        # When running from a PyInstaller bundle, we don't need to install dependencies
        # as they should already be included in the bundle
        return True, "Running from frozen executable, dependencies should be included."
    
    missing_packages = [pkg for pkg in required_packages if not is_module_installed(pkg)]
    
    if not missing_packages:
        return True, "All dependencies are already installed."
    
    # Create a temporary console window to show installation progress
    print("Installing missing dependencies...")
    print(f"Missing packages: {', '.join(missing_packages)}")
    
    try:
        for package in missing_packages:
            print(f"Installing {package}...")
            subprocess.check_call([sys.executable, "-m", "pip", "install", package])
            print(f"{package} installed successfully.")
            time.sleep(0.5)  # Small delay to show progress
        
        return True, "All dependencies installed successfully."
    except Exception as e:
        error_msg = f"Error installing dependencies: {str(e)}"
        print(error_msg)
        return False, error_msg

def main():
    """Main function to check and install dependencies"""
    success, message = install_dependencies()
    print(message)
    if not success:
        print("Press Enter to exit...")
        input()
        sys.exit(1)
    
    # If running as a standalone script, exit after installing
    if __name__ == "__main__":
        print("Dependencies check completed. Starting application...")
        time.sleep(1.5)  # Give user time to see the message
        
    return success, message

if __name__ == "__main__":
    main()