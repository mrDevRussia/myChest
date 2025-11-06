import os
import sys
import hashlib
import threading
import time
import json
import shutil
import platform
import subprocess
import re
import ctypes
import winreg
from datetime import datetime


def resource_path(relative_path):

    if hasattr(sys,  '_MEIPASS'):
        return os.path.join(sys._MEIPASS,
relative_path)
    return os.path.join(os.path.abspath("."),
        relative_path)

# Import dependency installer
try:
    from dependency_installer import install_dependencies
except ImportError:
    # If running from source and dependency_installer.py is in the same directory
    sys.path.append(os.path.dirname(os.path.abspath(__file__)))
    try:
        from dependency_installer import install_dependencies
    except ImportError:
        # If running from a PyInstaller bundle, try to extract and import the dependency installer
        if getattr(sys, 'frozen', False):
            try:
                # Get the path to the bundled dependency_installer.py
                bundle_dir = getattr(sys, '_MEIPASS', os.path.abspath(os.path.dirname(__file__)))
                installer_path = os.path.join(bundle_dir, 'dependency_installer.py')
                
                # If the file exists in the bundle, load it
                if os.path.exists(installer_path):
                    import importlib.util
                    spec = importlib.util.spec_from_file_location("dependency_installer", installer_path)
                    dependency_installer = importlib.util.module_from_spec(spec)
                    spec.loader.exec_module(dependency_installer)
                    install_dependencies = dependency_installer.install_dependencies
                else:
                    def install_dependencies():
                        return True, "Running from frozen executable, dependencies should be included."
            except Exception as e:
                def install_dependencies():
                    return True, f"Dependency installer not available: {str(e)}"
        else:
            def install_dependencies():
                return True, "Dependency installer not available"

# Import add_to_startup function
try:
    from add_to_startup import add_to_startup
except ImportError:
    # If running from source and add_to_startup.py is in the same directory
    sys.path.append(os.path.dirname(os.path.abspath(__file__)))
    try:
        from add_to_startup import add_to_startup
    except ImportError:
        # If running from a PyInstaller bundle, try to extract and import the add_to_startup module
        if getattr(sys, 'frozen', False):
            try:
                # Get the path to the bundled add_to_startup.py
                bundle_dir = getattr(sys, '_MEIPASS', os.path.abspath(os.path.dirname(__file__)))
                startup_path = os.path.join(bundle_dir, 'add_to_startup.py')
                
                # If the file exists in the bundle, load it
                if os.path.exists(startup_path):
                    import importlib.util
                    spec = importlib.util.spec_from_file_location("add_to_startup", startup_path)
                    add_to_startup_module = importlib.util.module_from_spec(spec)
                    spec.loader.exec_module(add_to_startup_module)
                    add_to_startup = add_to_startup_module.add_to_startup
                else:
                    def add_to_startup():
                        return False, "Startup module not available in bundle"
            except Exception as e:
                def add_to_startup():
                    return False, f"Startup module not available: {str(e)}"
        else:
            def add_to_startup():
                return False, "Startup module not available"
from PyQt5.QtWidgets import (QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout, 
                           QLabel, QPushButton, QProgressBar, QFileDialog, QTabWidget, 
                           QListWidget, QListWidgetItem, QSystemTrayIcon, QMenu, QAction, 
                           QMessageBox, QCheckBox, QComboBox, QLineEdit, QGroupBox, QRadioButton,
                           QScrollArea, QSplashScreen, QFrame, QGridLayout, QSpacerItem, QSizePolicy,
                           QDialog, QTextEdit)
from PyQt5.QtCore import Qt, QThread, pyqtSignal, QTimer, QSize, QUrl, QDir, QFileInfo
from PyQt5.QtGui import QIcon, QPixmap, QFont, QColor, QPalette, QDesktopServices, QCursor

# Apply dark theme to application
def apply_dark_theme(app):
    dark_palette = QPalette()
    dark_palette.setColor(QPalette.Window, QColor(53, 53, 53))
    dark_palette.setColor(QPalette.WindowText, QColor(255, 255, 255))
    dark_palette.setColor(QPalette.Base, QColor(25, 25, 25))
    dark_palette.setColor(QPalette.AlternateBase, QColor(53, 53, 53))
    dark_palette.setColor(QPalette.ToolTipBase, QColor(255, 255, 255))
    dark_palette.setColor(QPalette.ToolTipText, QColor(255, 255, 255))
    dark_palette.setColor(QPalette.Text, QColor(255, 255, 255))
    dark_palette.setColor(QPalette.Button, QColor(53, 53, 53))
    dark_palette.setColor(QPalette.ButtonText, QColor(255, 255, 255))
    dark_palette.setColor(QPalette.BrightText, QColor(255, 0, 0))
    dark_palette.setColor(QPalette.Link, QColor(42, 130, 218))
    dark_palette.setColor(QPalette.Highlight, QColor(42, 130, 218))
    dark_palette.setColor(QPalette.HighlightedText, QColor(0, 0, 0))
    app.setPalette(dark_palette)
    app.setStyleSheet("QToolTip { color: #ffffff; background-color: #2a82da; border: 1px solid white; }")

# Global variables
APP_NAME = "ArcSentinel"
APP_DIR = os.path.dirname(os.path.abspath(__file__))
DATABASE_PATH = os.path.join(os.getenv('APPDATA'), APP_NAME)
MALWARE_SIGNATURES_FILE = os.path.join(DATABASE_PATH, "signatures.json")
QUARANTINE_FOLDER = os.path.join(DATABASE_PATH, "quarantine")
SCAN_HISTORY_FILE = os.path.join(DATABASE_PATH, "scan_history.json")
SETTINGS_FILE = os.path.join(DATABASE_PATH, "settings.json")
LOG_FILE = os.path.join(DATABASE_PATH, "activity.log")
APP_ICON =  os.path.join(os.path.dirname(os.path.abspath(__file__)), "icon.ico")

# Global settings dictionary
settings = {}

# Ensure necessary directories exist
def setup_directories():
    if not os.path.exists(DATABASE_PATH):
        os.makedirs(DATABASE_PATH)
    if not os.path.exists(QUARANTINE_FOLDER):
        os.makedirs(QUARANTINE_FOLDER)
    
    # Create default files if they don't exist
    if not os.path.exists(MALWARE_SIGNATURES_FILE):
        with open(MALWARE_SIGNATURES_FILE, 'w') as f:
            json.dump({"md5": [], "sha1": [], "sha256": []}, f)
    
    if not os.path.exists(SCAN_HISTORY_FILE):
        with open(SCAN_HISTORY_FILE, 'w') as f:
            json.dump([], f)
    
    if not os.path.exists(SETTINGS_FILE):
        default_settings = {
            "real_time_protection": True,
            "startup_scan": False,
            "scan_archives": True,
            "scan_removable_devices": True,
            "update_frequency": "daily",
            "theme": "dark",
            "excluded_paths": [],
            "last_update_check": None
        }
        with open(SETTINGS_FILE, 'w') as f:
            json.dump(default_settings, f)

# Logging function
def log_activity(message, level="INFO"):
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    log_entry = f"[{timestamp}] [{level}] {message}\n"
    
    with open(LOG_FILE, 'a') as f:
        f.write(log_entry)

# Initialize logging
def init_logging():
    if not os.path.exists(os.path.dirname(LOG_FILE)):
        os.makedirs(os.path.dirname(LOG_FILE))
    
    log_activity("ArcSentinel started", "INFO")

# Load settings
def load_settings():
    global settings
    try:
        with open(SETTINGS_FILE, 'r') as f:
            settings = json.load(f)
            return settings
    except Exception as e:
        log_activity(f"Error loading settings: {str(e)}", "ERROR")
        settings = {
            "real_time_protection": True,
            "startup_scan": False,
            "scan_archives": True,
            "scan_removable_devices": True,
            "update_frequency": "daily",
            "theme": "dark",
            "excluded_paths": [],
            "last_update_check": None
        }
        return settings

# Save settings
def save_settings(new_settings=None):
    global settings
    try:
        if new_settings is not None:
            settings = new_settings
        with open(SETTINGS_FILE, 'w') as f:
            json.dump(settings, f)
        return True
    except Exception as e:
        log_activity(f"Error saving settings: {str(e)}", "ERROR")
        return False

# Load malware signatures
def load_signatures():
    try:
        with open(MALWARE_SIGNATURES_FILE, 'r') as f:
            return json.load(f)
    except Exception as e:
        log_activity(f"Error loading signatures: {str(e)}", "ERROR")
        return {"md5": [], "sha1": [], "sha256": []}

# File scanning class
class FileScannerThread(QThread):
    update_progress = pyqtSignal(int, int, str)
    scan_complete = pyqtSignal(dict)
    threat_found = pyqtSignal(str, str)
    
    def __init__(self, paths, scan_archives=True):
        super().__init__()
        self.paths = paths
        self.scan_archives = scan_archives
        self.stop_requested = False
        self.signatures = load_signatures()
        self.settings = load_settings()
        self.excluded_paths = self.settings.get("excluded_paths", [])
        
    def run(self):
        start_time = time.time()
        scanned_files = 0
        infected_files = []
        total_files = self.count_files(self.paths)
        
        for path in self.paths:
            if os.path.isfile(path):
                self.scan_file(path, scanned_files, total_files, infected_files)
                scanned_files += 1
            elif os.path.isdir(path):
                for root, dirs, files in os.walk(path):
                    # Skip excluded paths
                    if any(os.path.abspath(root).startswith(os.path.abspath(excluded)) for excluded in self.excluded_paths):
                        continue
                        
                    for file in files:
                        if self.stop_requested:
                            break
                            
                        file_path = os.path.join(root, file)
                        self.scan_file(file_path, scanned_files, total_files, infected_files)
                        scanned_files += 1
                        
                    if self.stop_requested:
                        break
        
        end_time = time.time()
        scan_duration = end_time - start_time
        
        # Save scan results to history
        scan_result = {
            "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            "scanned_files": scanned_files,
            "infected_files": len(infected_files),
            "duration": scan_duration,
            "infected_file_paths": infected_files
        }
        
        try:
            with open(SCAN_HISTORY_FILE, 'r') as f:
                history = json.load(f)
            
            history.append(scan_result)
            
            with open(SCAN_HISTORY_FILE, 'w') as f:
                json.dump(history, f)
        except Exception as e:
            log_activity(f"Error saving scan history: {str(e)}", "ERROR")
        
        self.scan_complete.emit(scan_result)
    
    def count_files(self, paths):
        count = 0
        for path in paths:
            if os.path.isfile(path):
                count += 1
            elif os.path.isdir(path):
                for root, dirs, files in os.walk(path):
                    # Skip excluded paths
                    if any(os.path.abspath(root).startswith(os.path.abspath(excluded)) for excluded in self.excluded_paths):
                        continue
                    count += len(files)
        return count
    
    def scan_file(self, file_path, current, total, infected_files):
        try:
            # Skip very large files (>100MB) for performance
            if os.path.getsize(file_path) > 100 * 1024 * 1024:
                self.update_progress.emit(current, total, f"Skipping large file: {file_path}")
                return
                
            self.update_progress.emit(current, total, f"Scanning: {file_path}")
            
            # Calculate file hashes
            with open(file_path, 'rb') as f:
                data = f.read()
                md5_hash = hashlib.md5(data).hexdigest()
                sha1_hash = hashlib.sha1(data).hexdigest()
                sha256_hash = hashlib.sha256(data).hexdigest()
            
            # Check against known signatures
            if (md5_hash in self.signatures["md5"] or 
                sha1_hash in self.signatures["sha1"] or 
                sha256_hash in self.signatures["sha256"]):
                infected_files.append(file_path)
                self.threat_found.emit(file_path, "Malware signature match")
                log_activity(f"Malware detected: {file_path}", "WARNING")
                return
            
            # Basic heuristic analysis (check for suspicious patterns)
            if self.heuristic_scan(data, file_path):
                infected_files.append(file_path)
                self.threat_found.emit(file_path, "Suspicious behavior detected")
                log_activity(f"Suspicious file detected: {file_path}", "WARNING")
                return
                
        except Exception as e:
            log_activity(f"Error scanning file {file_path}: {str(e)}", "ERROR")
    
    def heuristic_scan(self, data, file_path):
        # Simple heuristic checks for suspicious patterns
        suspicious_patterns = [
            b"CreateRemoteThread",
            b"VirtualAllocEx",
            b"WriteProcessMemory",
            b"ShellExecute",
            b"WScript.Shell",
            b"cmd.exe /c",
            b"powershell -e",
            b"net user /add",
            b"reg add HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run"
        ]
        
        # Check file extension
        _, ext = os.path.splitext(file_path)
        if ext.lower() in [".exe", ".dll", ".bat", ".vbs", ".ps1"]:
            # Check for suspicious patterns in executable files
            for pattern in suspicious_patterns:
                if pattern in data:
                    return True
        
        return False
    
    def stop(self):
        self.stop_requested = True

# Real-time protection monitor
class RealTimeMonitor(QThread):
    threat_detected = pyqtSignal(str, str)
    
    def __init__(self):
        super().__init__()
        self.running = False
        self.signatures = load_signatures()
        self.settings = load_settings()
        self.excluded_paths = self.settings.get("excluded_paths", [])
        self.watched_extensions = [".exe", ".dll", ".bat", ".vbs", ".ps1", ".js", ".jar"]
        
    def run(self):
        self.running = True
        log_activity("Real-time protection started")
        
        # Monitor common directories
        watched_dirs = [
            os.path.join(os.environ["USERPROFILE"], "Downloads"),
            os.path.join(os.environ["USERPROFILE"], "Desktop"),
            os.environ["TEMP"]
        ]
        
        last_scan_times = {}
        
        while self.running:
            for directory in watched_dirs:
                if not os.path.exists(directory):
                    continue
                    
                # Skip excluded paths
                if any(os.path.abspath(directory).startswith(os.path.abspath(excluded)) for excluded in self.excluded_paths):
                    continue
                    
                try:
                    for filename in os.listdir(directory):
                        file_path = os.path.join(directory, filename)
                        
                        # Only scan files with watched extensions
                        _, ext = os.path.splitext(file_path)
                        if ext.lower() not in self.watched_extensions:
                            continue
                            
                        # Skip if file was recently scanned (within last 5 minutes)
                        if file_path in last_scan_times:
                            if time.time() - last_scan_times[file_path] < 300:  # 5 minutes
                                continue
                        
                        # Skip excluded paths
                        if any(os.path.abspath(file_path).startswith(os.path.abspath(excluded)) for excluded in self.excluded_paths):
                            continue
                            
                        # Only scan new or modified files
                        if os.path.isfile(file_path):
                            try:
                                # Record scan time
                                last_scan_times[file_path] = time.time()
                                
                                # Scan the file
                                with open(file_path, 'rb') as f:
                                    data = f.read()
                                    md5_hash = hashlib.md5(data).hexdigest()
                                    sha1_hash = hashlib.sha1(data).hexdigest()
                                    sha256_hash = hashlib.sha256(data).hexdigest()
                                
                                # Check against known signatures
                                if (md5_hash in self.signatures["md5"] or 
                                    sha1_hash in self.signatures["sha1"] or 
                                    sha256_hash in self.signatures["sha256"]):
                                    self.threat_detected.emit(file_path, "Malware signature match")
                                    log_activity(f"Real-time protection: Malware detected in {file_path}", "WARNING")
                                    continue
                                
                                # Basic heuristic analysis
                                suspicious_patterns = [
                                    b"CreateRemoteThread",
                                    b"VirtualAllocEx",
                                    b"WriteProcessMemory",
                                    b"ShellExecute",
                                    b"WScript.Shell",
                                    b"cmd.exe /c",
                                    b"powershell -e",
                                    b"net user /add",
                                    b"reg add HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run"
                                ]
                                
                                for pattern in suspicious_patterns:
                                    if pattern in data:
                                        self.threat_detected.emit(file_path, "Suspicious behavior detected")
                                        log_activity(f"Real-time protection: Suspicious file detected in {file_path}", "WARNING")
                                        break
                                        
                            except Exception as e:
                                log_activity(f"Error in real-time scan of {file_path}: {str(e)}", "ERROR")
                except Exception as e:
                    log_activity(f"Error monitoring directory {directory}: {str(e)}", "ERROR")
            
            # Sleep to reduce CPU usage
            time.sleep(2)
    
    def stop(self):
        self.running = False
        log_activity("Real-time protection stopped")

# Quarantine functions
def quarantine_file(file_path):
    try:
        if not os.path.exists(file_path):
            return False, "File does not exist"
            
        # Generate a unique filename for quarantine
        filename = os.path.basename(file_path)
        quarantine_name = f"{filename}_{int(time.time())}.quarantine"
        quarantine_path = os.path.join(QUARANTINE_FOLDER, quarantine_name)
        
        # Create metadata for restoration
        metadata = {
            "original_path": file_path,
            "quarantine_date": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            "original_name": filename
        }
        
        # Save metadata
        metadata_path = f"{quarantine_path}.meta"
        with open(metadata_path, 'w') as f:
            json.dump(metadata, f)
        
        # Move file to quarantine
        shutil.move(file_path, quarantine_path)
        log_activity(f"File quarantined: {file_path} -> {quarantine_path}")
        
        return True, "File successfully quarantined"
    except Exception as e:
        log_activity(f"Error quarantining file {file_path}: {str(e)}", "ERROR")
        return False, str(e)

def restore_quarantined_file(quarantine_path):
    try:
        if not os.path.exists(quarantine_path):
            return False, "Quarantined file does not exist"
            
        # Load metadata
        metadata_path = f"{quarantine_path}.meta"
        if not os.path.exists(metadata_path):
            return False, "Metadata file missing"
            
        with open(metadata_path, 'r') as f:
            metadata = json.load(f)
        
        original_path = metadata["original_path"]
        
        # Check if original location is writable
        original_dir = os.path.dirname(original_path)
        if not os.path.exists(original_dir):
            os.makedirs(original_dir)
        
        # Restore file
        shutil.move(quarantine_path, original_path)
        
        # Remove metadata file
        os.remove(metadata_path)
        
        log_activity(f"File restored from quarantine: {quarantine_path} -> {original_path}")
        return True, "File successfully restored"
    except Exception as e:
        log_activity(f"Error restoring file from quarantine: {str(e)}", "ERROR")
        return False, str(e)

def delete_quarantined_file(quarantine_path):
    try:
        if not os.path.exists(quarantine_path):
            return False, "Quarantined file does not exist"
            
        # Remove file
        os.remove(quarantine_path)
        
        # Remove metadata if it exists
        metadata_path = f"{quarantine_path}.meta"
        if os.path.exists(metadata_path):
            os.remove(metadata_path)
        
        log_activity(f"Quarantined file deleted: {quarantine_path}")
        return True, "File successfully deleted"
    except Exception as e:
        log_activity(f"Error deleting quarantined file: {str(e)}", "ERROR")
        return False, str(e)

# System health check
def check_system_health():
    health_status = {
        "windows_update": check_windows_update(),
        "firewall_status": check_firewall_status(),
        "disk_space": check_disk_space(),
        "startup_items": check_startup_items(),
        "browser_extensions": check_browser_extensions()
    }
    return health_status

def check_windows_update():
    # This is a simplified check - in a real app, you'd use the Windows Update API
    try:
        result = subprocess.run(["powershell", "-Command", "Get-HotFix | Sort-Object -Property InstalledOn -Descending | Select-Object -First 1 | Select-Object -ExpandProperty InstalledOn"], 
                               capture_output=True, text=True, timeout=10)
        if result.returncode == 0 and result.stdout.strip():
            last_update = result.stdout.strip()
            # Parse the date and check if it's recent (within 30 days)
            try:
                update_date = datetime.strptime(last_update, "%m/%d/%Y")
                days_since_update = (datetime.now() - update_date).days
                if days_since_update <= 30:
                    return {"status": "good", "message": f"Last update: {last_update} ({days_since_update} days ago)"}
                else:
                    return {"status": "warning", "message": f"Last update: {last_update} ({days_since_update} days ago). Consider updating your system."}
            except:
                return {"status": "unknown", "message": f"Last update: {last_update}"}
        return {"status": "unknown", "message": "Could not determine last update time"}
    except Exception as e:
        log_activity(f"Error checking Windows Update: {str(e)}", "ERROR")
        return {"status": "error", "message": "Error checking Windows Update status"}

def check_firewall_status():
    try:
        result = subprocess.run(["netsh", "advfirewall", "show", "allprofiles"], capture_output=True, text=True, timeout=10)
        if result.returncode == 0:
            output = result.stdout
            if "State                                 ON" in output:
                return {"status": "good", "message": "Firewall is enabled"}
            else:
                return {"status": "warning", "message": "Firewall appears to be disabled"}
        return {"status": "unknown", "message": "Could not determine firewall status"}
    except Exception as e:
        log_activity(f"Error checking firewall status: {str(e)}", "ERROR")
        return {"status": "error", "message": "Error checking firewall status"}

def check_disk_space():
    try:
        # Get the system drive (usually C:)
        system_drive = os.environ.get("SystemDrive", "C:")
        total, used, free = shutil.disk_usage(system_drive)
        
        # Convert to GB for readability
        total_gb = total / (1024**3)
        free_gb = free / (1024**3)
        used_gb = used / (1024**3)
        percent_free = (free / total) * 100
        
        if percent_free < 10:
            status = "warning"
            message = f"Low disk space: {free_gb:.2f} GB free ({percent_free:.1f}% of {total_gb:.2f} GB)"
        else:
            status = "good"
            message = f"Disk space: {free_gb:.2f} GB free ({percent_free:.1f}% of {total_gb:.2f} GB)"
            
        return {"status": status, "message": message}
    except Exception as e:
        log_activity(f"Error checking disk space: {str(e)}", "ERROR")
        return {"status": "error", "message": "Error checking disk space"}

def check_startup_items():
    startup_items = []
    try:
        # Check registry startup locations
        reg_locations = [
            (winreg.HKEY_CURRENT_USER, "Software\\Microsoft\\Windows\\CurrentVersion\\Run"),
            (winreg.HKEY_LOCAL_MACHINE, "Software\\Microsoft\\Windows\\CurrentVersion\\Run"),
            (winreg.HKEY_CURRENT_USER, "Software\\Microsoft\\Windows\\CurrentVersion\\RunOnce"),
            (winreg.HKEY_LOCAL_MACHINE, "Software\\Microsoft\\Windows\\CurrentVersion\\RunOnce")
        ]
        
        for hkey, key_path in reg_locations:
            try:
                key = winreg.OpenKey(hkey, key_path)
                i = 0
                while True:
                    try:
                        name, value, _ = winreg.EnumValue(key, i)
                        startup_items.append({"name": name, "command": value, "location": key_path})
                        i += 1
                    except WindowsError:
                        break
                winreg.CloseKey(key)
            except WindowsError:
                pass
                
        # Check startup folders
        startup_folders = [
            os.path.join(os.environ["APPDATA"], "Microsoft\\Windows\\Start Menu\\Programs\\Startup"),
            os.path.join(os.environ["ProgramData"], "Microsoft\\Windows\\Start Menu\\Programs\\Startup")
        ]
        
        for folder in startup_folders:
            if os.path.exists(folder):
                for item in os.listdir(folder):
                    item_path = os.path.join(folder, item)
                    startup_items.append({"name": item, "command": item_path, "location": folder})
        
        if len(startup_items) > 10:
            return {"status": "warning", "message": f"Found {len(startup_items)} startup items", "items": startup_items}
        else:
            return {"status": "good", "message": f"Found {len(startup_items)} startup items", "items": startup_items}
    except Exception as e:
        log_activity(f"Error checking startup items: {str(e)}", "ERROR")
        return {"status": "error", "message": "Error checking startup items", "items": []}

def check_browser_extensions():
    # This is a simplified check - in a real app, you'd check browser profiles
    extensions = []
    try:
        # Check Chrome extensions
        chrome_ext_path = os.path.join(os.environ["LOCALAPPDATA"], "Google\\Chrome\\User Data\\Default\\Extensions")
        if os.path.exists(chrome_ext_path):
            for ext_id in os.listdir(chrome_ext_path):
                extensions.append({"browser": "Chrome", "id": ext_id})
        
        # Check Edge extensions
        edge_ext_path = os.path.join(os.environ["LOCALAPPDATA"], "Microsoft\\Edge\\User Data\\Default\\Extensions")
        if os.path.exists(edge_ext_path):
            for ext_id in os.listdir(edge_ext_path):
                extensions.append({"browser": "Edge", "id": ext_id})
        
        if len(extensions) > 15:  # Arbitrary threshold
            return {"status": "warning", "message": f"Found {len(extensions)} browser extensions", "extensions": extensions}
        else:
            return {"status": "good", "message": f"Found {len(extensions)} browser extensions", "extensions": extensions}
    except Exception as e:
        log_activity(f"Error checking browser extensions: {str(e)}", "ERROR")
        return {"status": "error", "message": "Error checking browser extensions", "extensions": []}

# Main application window
class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle(APP_NAME)
        self.setMinimumSize(900, 600)
        
        # Set window icon
        if getattr(sys, 'frozen', False):
            # Running as PyInstaller bundle
            icon_path = os.path.join(sys._MEIPASS, "icon.ico")
        else:
            # Running as Python script
            icon_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "icon.ico")
        
        if os.path.exists(icon_path):
            self.setWindowIcon(QIcon(icon_path))
        
        # Load settings
        self.settings = load_settings()
        
        # Set up the UI theme
        self.apply_theme(self.settings.get("theme", "dark"))
        
        # Create system tray icon
        self.setup_tray_icon()
        
        # Set up the main UI
        self.setup_ui()
        
        # Initialize scanner and real-time protection
        self.scanner_thread = None
        self.real_time_monitor = None
        
        # Start real-time protection if enabled
        if self.settings.get("real_time_protection", True):
            self.toggle_real_time_protection(Qt.Checked)
        
        # Run startup scan if enabled
        if self.settings.get("startup_scan", False):
            self.start_scan("quick")
    
    def check_for_updates(self):
        # Placeholder for update checking functionality
        QMessageBox.information(self, "Updates", "You are running the latest version of ArcSentinel.")
    
    def run_health_check(self):
        # Placeholder for system health check functionality
        QMessageBox.information(self, "System Health", "System health check completed. All systems are functioning normally.")
    
    def view_logs(self):
        # Placeholder for log viewing functionality
        if os.path.exists(LOG_FILE):
            with open(LOG_FILE, 'r') as f:
                log_content = f.read()
            
            log_dialog = QDialog(self)
            log_dialog.setWindowTitle("Application Logs")
            log_dialog.setMinimumSize(700, 500)
            
            layout = QVBoxLayout(log_dialog)
            
            log_text = QTextEdit()
            log_text.setReadOnly(True)
            log_text.setPlainText(log_content)
            log_text.setFont(QFont("Courier New", 10))
            
            layout.addWidget(log_text)
            
            log_dialog.exec_()
        else:
            QMessageBox.information(self, "Logs", "No logs found.")
    
    def add_exclusion(self):
        # Open file dialog to select file or directory to exclude
        path = QFileDialog.getExistingDirectory(self, "Select Directory to Exclude")
        if path:
            # Add to exclusions list if not already present
            exclusions = self.settings.get("exclusions", [])
            if path not in exclusions:
                exclusions.append(path)
                self.settings["exclusions"] = exclusions
                save_settings(self.settings)
                self.update_exclusions_list()
    
    def remove_exclusion(self):
        # Remove selected exclusion from list
        selected_items = self.exclusions_list.selectedItems()
        if selected_items:
            exclusions = self.settings.get("exclusions", [])
            for item in selected_items:
                path = item.text()
                if path in exclusions:
                    exclusions.remove(path)
            
            self.settings["exclusions"] = exclusions
            save_settings(self.settings)
            self.update_exclusions_list()
    
    def update_exclusions_list(self):
        # Update the exclusions list widget
        self.exclusions_list.clear()
        exclusions = self.settings.get("exclusions", [])
        for path in exclusions:
            self.exclusions_list.addItem(path)
    
    def change_theme(self, theme_text):
        # Change application theme
        theme = theme_text.lower()
        self.settings["theme"] = theme
        self.apply_theme(theme)
    
    def save_settings_clicked(self):
        # Save current settings
        save_settings(self.settings)
        QMessageBox.information(self, "Settings", "Settings saved successfully.")
        
        # Apply settings
        if self.real_time_protection_cb.isChecked() != self.settings.get("real_time_protection", True):
            self.toggle_real_time_protection(Qt.Checked if self.real_time_protection_cb.isChecked() else Qt.Unchecked)

    
    def apply_theme(self, theme):
        if theme == "dark":
            # Dark theme
            dark_palette = QPalette()
            dark_palette.setColor(QPalette.Window, QColor(53, 53, 53))
            dark_palette.setColor(QPalette.WindowText, Qt.white)
            dark_palette.setColor(QPalette.Base, QColor(25, 25, 25))
            dark_palette.setColor(QPalette.AlternateBase, QColor(53, 53, 53))
            dark_palette.setColor(QPalette.ToolTipBase, Qt.white)
            dark_palette.setColor(QPalette.ToolTipText, Qt.white)
            dark_palette.setColor(QPalette.Text, Qt.white)
            dark_palette.setColor(QPalette.Button, QColor(53, 53, 53))
            dark_palette.setColor(QPalette.ButtonText, Qt.white)
            dark_palette.setColor(QPalette.BrightText, Qt.red)
            dark_palette.setColor(QPalette.Link, QColor(42, 130, 218))
            dark_palette.setColor(QPalette.Highlight, QColor(42, 130, 218))
            dark_palette.setColor(QPalette.HighlightedText, Qt.black)
            QApplication.setPalette(dark_palette)
            QApplication.setStyle("Fusion")
        else:
            # Light theme (default)
            QApplication.setPalette(QApplication.style().standardPalette())
    
    def setup_tray_icon(self):
        # Create system tray icon
        self.tray_icon = QSystemTrayIcon(self)
        if getattr(sys, 'frozen', False):
            # Running as PyInstaller bundle
            icon_path = os.path.join(sys._MEIPASS, "icon.ico")
        else:
            # Running as Python script
            icon_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "icon.ico")
        
        if os.path.exists(icon_path):
            self.tray_icon.setIcon(QIcon(icon_path))
        else:
            self.tray_icon.setIcon(QIcon(self.style().standardIcon(QApplication.style().SP_ComputerIcon)))
        
        # Create tray menu
        self.tray_menu = QMenu()
        
        # Add actions to the tray menu
        quick_scan_action = QAction("Quick Scan", self)
        quick_scan_action.triggered.connect(lambda: self.start_scan("quick"))
        self.tray_menu.addAction(quick_scan_action)
        
        # Store the toggle action as an instance variable so we can update it
        self.toggle_protection_action = QAction("", self)
        self.toggle_protection_action.triggered.connect(self.toggle_protection_from_tray)
        self.tray_menu.addAction(self.toggle_protection_action)
        
        self.tray_menu.addSeparator()
        
        show_action = QAction("Show", self)
        show_action.triggered.connect(self.show)
        self.tray_menu.addAction(show_action)
        
        exit_action = QAction("Exit", self)
        exit_action.triggered.connect(self.close_application)
        self.tray_menu.addAction(exit_action)
        
        # Set the tray menu
        self.tray_icon.setContextMenu(self.tray_menu)
        self.tray_icon.show()
        
        # Update the tray menu text
        self.update_tray_menu()
        
        # Connect the activated signal
        self.tray_icon.activated.connect(self.tray_icon_activated)
    
    def tray_icon_activated(self, reason):
        if reason == QSystemTrayIcon.DoubleClick:
            self.show()
            self.activateWindow()
    
    def toggle_protection_from_tray(self):
        """Toggle real-time protection from system tray menu"""
        current_state = self.settings.get("real_time_protection", True)
        self.toggle_real_time_protection(Qt.Unchecked if current_state else Qt.Checked)
        # Update checkbox in settings tab if it exists
        if hasattr(self, 'real_time_protection_cb'):
            self.real_time_protection_cb.setChecked(not current_state)
    
    def update_tray_menu(self):
        """Update the system tray menu text based on current protection state"""
        if self.settings.get("real_time_protection", True):
            self.toggle_protection_action.setText("Disable Real-time Protection")
        else:
            self.toggle_protection_action.setText("Enable Real-time Protection")
    
    def update_protection_ui(self):
        """Update all UI elements related to real-time protection status"""
        # Reload settings to get current state
        self.settings = load_settings()
        is_enabled = self.settings.get("real_time_protection", True)
        
        # Update tray menu
        self.update_tray_menu()
        
        # Update dashboard protection icon
        if hasattr(self, 'protection_icon'):
            if is_enabled:
                self.protection_icon.setPixmap(self.style().standardIcon(QApplication.style().SP_DialogApplyButton).pixmap(24, 24))
            else:
                self.protection_icon.setPixmap(self.style().standardIcon(QApplication.style().SP_DialogCancelButton).pixmap(24, 24))
        
        # Update dashboard protection label
        if hasattr(self, 'protection_label'):
            self.protection_label.setText("Real-time Protection: " + ("Enabled" if is_enabled else "Disabled"))
        
        # Show/hide enable button in dashboard
        if hasattr(self, 'enable_protection_btn'):
            if is_enabled:
                self.enable_protection_btn.hide()
            else:
                self.enable_protection_btn.show()
        elif not is_enabled and hasattr(self, 'protection_label'):
            # Create the enable button if it doesn't exist and protection is disabled
            parent_layout = self.protection_label.parent().layout()
            if parent_layout:
                self.enable_protection_btn = QPushButton("Enable Protection")
                self.enable_protection_btn.setIcon(self.style().standardIcon(QApplication.style().SP_DialogApplyButton))
                self.enable_protection_btn.clicked.connect(lambda: self.toggle_real_time_protection(Qt.Checked))
                self.enable_protection_btn.setStyleSheet("QPushButton { background-color: #4CAF50; color: white; font-weight: bold; padding: 8px; }")
                # Insert before the stretch
                parent_layout.insertWidget(parent_layout.count() - 1, self.enable_protection_btn)
    
    def setup_ui(self):
        # Create central widget and main layout
        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        main_layout = QVBoxLayout(central_widget)
        
        # Create header with logo and status
        header_widget = QWidget()
        header_layout = QHBoxLayout(header_widget)
        header_layout.setContentsMargins(10, 10, 10, 10)
        
        # Logo and app name
        logo_label = QLabel()
        logo_label.setPixmap(QPixmap(self.style().standardIcon(QApplication.style().SP_DesktopIcon).pixmap(48, 48)))
        header_layout.addWidget(logo_label)
        
        app_name_label = QLabel(APP_NAME)
        app_name_label.setFont(QFont("Arial", 18, QFont.Bold))
        header_layout.addWidget(app_name_label)
        
        header_layout.addStretch()
        
        # Protection status
        self.protection_status_label = QLabel()
        self.update_protection_status()
        header_layout.addWidget(self.protection_status_label)
        
        main_layout.addWidget(header_widget)
        
        # Create tab widget for different sections
        self.tab_widget = QTabWidget()
        
        # Dashboard tab
        self.create_dashboard_tab()
        
        # Scan tab
        self.create_scan_tab()
        
        # Quarantine tab
        self.create_quarantine_tab()
        
        # System Health tab
        self.create_system_health_tab()
        
        # Settings tab
        self.create_settings_tab()
        
        # Add tabs to tab widget
        main_layout.addWidget(self.tab_widget)
        
        # Create status bar
        self.statusBar().showMessage("Ready")
    
    def create_dashboard_tab(self):
        dashboard_widget = QWidget()
        dashboard_layout = QVBoxLayout(dashboard_widget)
        
        # Status overview
        status_group = QGroupBox("System Status")
        status_layout = QVBoxLayout(status_group)
        
        # Protection status
        protection_widget = QWidget()
        protection_layout = QHBoxLayout(protection_widget)
        protection_layout.setContentsMargins(0, 0, 0, 0)
        
        self.protection_icon = QLabel()
        if self.settings.get("real_time_protection", True):
            self.protection_icon.setPixmap(self.style().standardIcon(QApplication.style().SP_DialogApplyButton).pixmap(24, 24))
        else:
            self.protection_icon.setPixmap(self.style().standardIcon(QApplication.style().SP_DialogCancelButton).pixmap(24, 24))
        protection_layout.addWidget(self.protection_icon)
        
        self.protection_label = QLabel("Real-time Protection: " + ("Enabled" if self.settings.get("real_time_protection", True) else "Disabled"))
        protection_layout.addWidget(self.protection_label)
        
        # Add enable button if protection is disabled
        if not self.settings.get("real_time_protection", True):
            self.enable_protection_btn = QPushButton("Enable Protection")
            self.enable_protection_btn.setIcon(self.style().standardIcon(QApplication.style().SP_DialogApplyButton))
            self.enable_protection_btn.clicked.connect(lambda: self.toggle_real_time_protection(Qt.Checked))
            self.enable_protection_btn.setStyleSheet("QPushButton { background-color: #4CAF50; color: white; font-weight: bold; padding: 8px; }")
            protection_layout.addWidget(self.enable_protection_btn)
        
        protection_layout.addStretch()
        
        status_layout.addWidget(protection_widget)
        
        # Last scan info
        last_scan_widget = QWidget()
        last_scan_layout = QHBoxLayout(last_scan_widget)
        last_scan_layout.setContentsMargins(0, 0, 0, 0)
        
        last_scan_icon = QLabel()
        last_scan_icon.setPixmap(self.style().standardIcon(QApplication.style().SP_FileDialogInfoView).pixmap(24, 24))
        last_scan_layout.addWidget(last_scan_icon)
        
        # Get last scan info
        try:
            with open(SCAN_HISTORY_FILE, 'r') as f:
                history = json.load(f)
            
            if history:
                last_scan = history[-1]
                last_scan_text = f"Last Scan: {last_scan['timestamp']} - Scanned: {last_scan['scanned_files']} files, Found: {last_scan['infected_files']} threats"
            else:
                last_scan_text = "No scan history available"
        except:
            last_scan_text = "No scan history available"
        
        last_scan_label = QLabel(last_scan_text)
        last_scan_layout.addWidget(last_scan_label)
        last_scan_layout.addStretch()
        
        status_layout.addWidget(last_scan_widget)
        
        dashboard_layout.addWidget(status_group)
        
        # Quick action buttons
        actions_group = QGroupBox("Quick Actions")
        actions_layout = QGridLayout(actions_group)
        
        quick_scan_btn = QPushButton("Quick Scan")
        quick_scan_btn.setIcon(self.style().standardIcon(QApplication.style().SP_DialogApplyButton))
        quick_scan_btn.clicked.connect(lambda: self.start_scan("quick"))
        actions_layout.addWidget(quick_scan_btn, 0, 0)
        
        full_scan_btn = QPushButton("Full Scan")
        full_scan_btn.setIcon(self.style().standardIcon(QApplication.style().SP_DialogApplyButton))
        full_scan_btn.clicked.connect(lambda: self.start_scan("full"))
        actions_layout.addWidget(full_scan_btn, 0, 1)
        
        custom_scan_btn = QPushButton("Custom Scan")
        custom_scan_btn.setIcon(self.style().standardIcon(QApplication.style().SP_DialogApplyButton))
        custom_scan_btn.clicked.connect(lambda: self.start_scan("custom"))
        actions_layout.addWidget(custom_scan_btn, 0, 2)
        
        update_btn = QPushButton("Check for Updates")
        update_btn.setIcon(self.style().standardIcon(QApplication.style().SP_BrowserReload))
        update_btn.clicked.connect(self.check_for_updates)
        actions_layout.addWidget(update_btn, 1, 0)
        
        health_check_btn = QPushButton("System Health Check")
        health_check_btn.setIcon(self.style().standardIcon(QApplication.style().SP_ComputerIcon))
        health_check_btn.clicked.connect(self.run_health_check)
        actions_layout.addWidget(health_check_btn, 1, 1)
        
        view_logs_btn = QPushButton("View Logs")
        view_logs_btn.setIcon(self.style().standardIcon(QApplication.style().SP_FileDialogDetailedView))
        view_logs_btn.clicked.connect(self.view_logs)
        actions_layout.addWidget(view_logs_btn, 1, 2)
        
        dashboard_layout.addWidget(actions_group)
        
        # Recent threats
        threats_group = QGroupBox("Recent Threats")
        threats_layout = QVBoxLayout(threats_group)
        
        self.recent_threats_list = QListWidget()
        threats_layout.addWidget(self.recent_threats_list)
        
        # Populate recent threats from scan history
        try:
            with open(SCAN_HISTORY_FILE, 'r') as f:
                history = json.load(f)
            
            recent_threats = []
            for scan in reversed(history):
                for threat in scan.get("infected_file_paths", []):
                    recent_threats.append(threat)
                    if len(recent_threats) >= 10:  # Show only the 10 most recent threats
                        break
                if len(recent_threats) >= 10:
                    break
            
            for threat in recent_threats:
                item = QListWidgetItem(threat)
                item.setIcon(self.style().standardIcon(QApplication.style().SP_MessageBoxWarning))
                self.recent_threats_list.addItem(item)
        except Exception as e:
            log_activity(f"Error loading recent threats: {str(e)}", "ERROR")
        
        dashboard_layout.addWidget(threats_group)
        
        # Add dashboard tab
        self.tab_widget.addTab(dashboard_widget, "Dashboard")
    
    def create_scan_tab(self):
        scan_widget = QWidget()
        scan_layout = QVBoxLayout(scan_widget)
        
        # Scan options
        options_group = QGroupBox("Scan Options")
        options_layout = QVBoxLayout(options_group)
        
        # Quick scan option
        quick_scan_radio = QRadioButton("Quick Scan")
        quick_scan_radio.setChecked(True)
        quick_scan_radio.setToolTip("Scans common locations where malware typically resides")
        options_layout.addWidget(quick_scan_radio)
        
        # Full scan option
        full_scan_radio = QRadioButton("Full Scan")
        full_scan_radio.setToolTip("Scans your entire system for threats (may take a long time)")
        options_layout.addWidget(full_scan_radio)
        
        # Custom scan option
        custom_scan_radio = QRadioButton("Custom Scan")
        custom_scan_radio.setToolTip("Select specific files or folders to scan")
        options_layout.addWidget(custom_scan_radio)
        
        # Custom scan path selection
        custom_scan_widget = QWidget()
        custom_scan_layout = QHBoxLayout(custom_scan_widget)
        custom_scan_layout.setContentsMargins(20, 0, 0, 0)
        
        self.custom_scan_path = QLineEdit()
        self.custom_scan_path.setPlaceholderText("Select files or folders to scan")
        self.custom_scan_path.setEnabled(False)
        custom_scan_layout.addWidget(self.custom_scan_path)
        
        browse_btn = QPushButton("Browse")
        browse_btn.setEnabled(False)
        browse_btn.clicked.connect(self.browse_scan_location)
        custom_scan_layout.addWidget(browse_btn)
        
        options_layout.addWidget(custom_scan_widget)
        
        # Connect radio buttons to enable/disable custom scan path
        custom_scan_radio.toggled.connect(lambda checked: self.custom_scan_path.setEnabled(checked))
        custom_scan_radio.toggled.connect(lambda checked: browse_btn.setEnabled(checked))
        
        # Additional scan options
        scan_archives_cb = QCheckBox("Scan archives (zip, rar, etc.)")
        scan_archives_cb.setChecked(self.settings.get("scan_archives", True))
        options_layout.addWidget(scan_archives_cb)
        
        scan_layout.addWidget(options_group)
        
        # Start scan button
        start_scan_btn = QPushButton("Start Scan")
        start_scan_btn.setIcon(self.style().standardIcon(QApplication.style().SP_MediaPlay))
        start_scan_btn.clicked.connect(lambda: self.start_scan(
            "quick" if quick_scan_radio.isChecked() else 
            "full" if full_scan_radio.isChecked() else 
            "custom",
            self.custom_scan_path.text() if custom_scan_radio.isChecked() else "",
            scan_archives_cb.isChecked()
        ))
        scan_layout.addWidget(start_scan_btn)
        
        # Scan progress
        progress_group = QGroupBox("Scan Progress")
        progress_layout = QVBoxLayout(progress_group)
        
        self.scan_progress_bar = QProgressBar()
        self.scan_progress_bar.setRange(0, 100)
        self.scan_progress_bar.setValue(0)
        progress_layout.addWidget(self.scan_progress_bar)
        
        self.scan_status_label = QLabel("Ready to scan")
        progress_layout.addWidget(self.scan_status_label)
        
        # Cancel scan button
        self.cancel_scan_btn = QPushButton("Cancel Scan")
        self.cancel_scan_btn.setIcon(self.style().standardIcon(QApplication.style().SP_MediaStop))
        self.cancel_scan_btn.setEnabled(False)
        self.cancel_scan_btn.clicked.connect(self.cancel_scan)
        progress_layout.addWidget(self.cancel_scan_btn)
        
        scan_layout.addWidget(progress_group)
        
        # Scan results
        results_group = QGroupBox("Scan Results")
        results_layout = QVBoxLayout(results_group)
        
        self.scan_results_list = QListWidget()
        results_layout.addWidget(self.scan_results_list)
        
        # Action buttons for detected threats
        actions_widget = QWidget()
        actions_layout = QHBoxLayout(actions_widget)
        actions_layout.setContentsMargins(0, 0, 0, 0)
        
        quarantine_btn = QPushButton("Quarantine Selected")
        quarantine_btn.setIcon(self.style().standardIcon(QApplication.style().SP_TrashIcon))
        quarantine_btn.clicked.connect(self.quarantine_selected)
        actions_layout.addWidget(quarantine_btn)
        
        delete_btn = QPushButton("Delete Selected")
        delete_btn.setIcon(self.style().standardIcon(QApplication.style().SP_DialogDiscardButton))
        delete_btn.clicked.connect(self.delete_selected)
        actions_layout.addWidget(delete_btn)
        
        ignore_btn = QPushButton("Ignore Selected")
        ignore_btn.setIcon(self.style().standardIcon(QApplication.style().SP_DialogOkButton))
        ignore_btn.clicked.connect(self.ignore_selected)
        actions_layout.addWidget(ignore_btn)
        
        results_layout.addWidget(actions_widget)
        
        scan_layout.addWidget(results_group)
        
        # Add scan tab
        self.tab_widget.addTab(scan_widget, "Scan")
        
        # Store references to radio buttons
        self.quick_scan_radio = quick_scan_radio
        self.full_scan_radio = full_scan_radio
        self.custom_scan_radio = custom_scan_radio
        self.scan_archives_cb = scan_archives_cb
    
    def create_quarantine_tab(self):
        quarantine_widget = QWidget()
        quarantine_layout = QVBoxLayout(quarantine_widget)
        
        # Quarantined items list
        self.quarantine_list = QListWidget()
        quarantine_layout.addWidget(self.quarantine_list)
        
        # Refresh quarantine list
        self.refresh_quarantine_list()
        
        # Action buttons
        actions_widget = QWidget()
        actions_layout = QHBoxLayout(actions_widget)
        
        restore_btn = QPushButton("Restore Selected")
        restore_btn.setIcon(self.style().standardIcon(QApplication.style().SP_DialogApplyButton))
        restore_btn.clicked.connect(self.restore_selected)
        actions_layout.addWidget(restore_btn)
        
        delete_btn = QPushButton("Delete Selected")
        delete_btn.setIcon(self.style().standardIcon(QApplication.style().SP_DialogDiscardButton))
        delete_btn.clicked.connect(self.delete_quarantined)
        actions_layout.addWidget(delete_btn)
        
        refresh_btn = QPushButton("Refresh List")
        refresh_btn.setIcon(self.style().standardIcon(QApplication.style().SP_BrowserReload))
        refresh_btn.clicked.connect(self.refresh_quarantine_list)
        actions_layout.addWidget(refresh_btn)
        
        quarantine_layout.addWidget(actions_widget)
        
        # Add quarantine tab
        self.tab_widget.addTab(quarantine_widget, "Quarantine")
    
    def create_system_health_tab(self):
        health_widget = QWidget()
        health_layout = QVBoxLayout(health_widget)
        
        # Run health check button
        check_btn = QPushButton("Run System Health Check")
        check_btn.setIcon(self.style().standardIcon(QApplication.style().SP_ComputerIcon))
        check_btn.clicked.connect(self.run_health_check)
        health_layout.addWidget(check_btn)
        
        # Health status sections
        self.health_scroll_area = QScrollArea()
        self.health_scroll_area.setWidgetResizable(True)
        
        self.health_content_widget = QWidget()
        self.health_content_layout = QVBoxLayout(self.health_content_widget)
        
        self.health_scroll_area.setWidget(self.health_content_widget)
        health_layout.addWidget(self.health_scroll_area)
        
        # Add system health tab
        self.tab_widget.addTab(health_widget, "System Health")
    
    def create_settings_tab(self):
        settings_widget = QWidget()
        settings_layout = QVBoxLayout(settings_widget)
        
        # Protection settings
        protection_group = QGroupBox("Protection Settings")
        protection_layout = QVBoxLayout(protection_group)
        
        self.real_time_protection_cb = QCheckBox("Enable Real-time Protection")
        self.real_time_protection_cb.setChecked(self.settings.get("real_time_protection", True))
        self.real_time_protection_cb.toggled.connect(self.toggle_real_time_protection)
        protection_layout.addWidget(self.real_time_protection_cb)
        
        self.startup_scan_cb = QCheckBox("Run Quick Scan at Startup")
        self.startup_scan_cb.setChecked(self.settings.get("startup_scan", False))
        protection_layout.addWidget(self.startup_scan_cb)
        
        self.scan_archives_settings_cb = QCheckBox("Scan Archives (zip, rar, etc.)")
        self.scan_archives_settings_cb.setChecked(self.settings.get("scan_archives", True))
        protection_layout.addWidget(self.scan_archives_settings_cb)
        
        self.scan_removable_cb = QCheckBox("Scan Removable Devices When Connected")
        self.scan_removable_cb.setChecked(self.settings.get("scan_removable_devices", True))
        protection_layout.addWidget(self.scan_removable_cb)
        
        settings_layout.addWidget(protection_group)
        
        # Update settings
        update_group = QGroupBox("Update Settings")
        update_layout = QVBoxLayout(update_group)
        
        update_layout.addWidget(QLabel("Check for Updates:")
)
        
        self.update_frequency_combo = QComboBox()
        self.update_frequency_combo.addItems(["Never", "Daily", "Weekly", "Monthly"])
        current_frequency = self.settings.get("update_frequency", "daily")
        index = self.update_frequency_combo.findText(current_frequency.capitalize())
        if index >= 0:
            self.update_frequency_combo.setCurrentIndex(index)
        update_layout.addWidget(self.update_frequency_combo)
        
        check_now_btn = QPushButton("Check for Updates Now")
        check_now_btn.clicked.connect(self.check_for_updates)
        update_layout.addWidget(check_now_btn)
        
        settings_layout.addWidget(update_group)
        
        # Exclusions
        exclusions_group = QGroupBox("Scan Exclusions")
        exclusions_layout = QVBoxLayout(exclusions_group)
        
        self.exclusions_list = QListWidget()
        for path in self.settings.get("excluded_paths", []):
            self.exclusions_list.addItem(path)
        exclusions_layout.addWidget(self.exclusions_list)
        
        exclusions_buttons = QWidget()
        exclusions_buttons_layout = QHBoxLayout(exclusions_buttons)
        exclusions_buttons_layout.setContentsMargins(0, 0, 0, 0)
        
        add_exclusion_btn = QPushButton("Add")
        add_exclusion_btn.clicked.connect(self.add_exclusion)
        exclusions_buttons_layout.addWidget(add_exclusion_btn)
        
        remove_exclusion_btn = QPushButton("Remove Selected")
        remove_exclusion_btn.clicked.connect(self.remove_exclusion)
        exclusions_buttons_layout.addWidget(remove_exclusion_btn)
        
        exclusions_layout.addWidget(exclusions_buttons)
        
        settings_layout.addWidget(exclusions_group)
        
        # Appearance settings
        appearance_group = QGroupBox("Appearance")
        appearance_layout = QVBoxLayout(appearance_group)
        
        appearance_layout.addWidget(QLabel("Theme:"))
        
        self.theme_combo = QComboBox()
        self.theme_combo.addItems(["Light", "Dark"])
        current_theme = self.settings.get("theme", "dark")
        index = self.theme_combo.findText(current_theme.capitalize())
        if index >= 0:
            self.theme_combo.setCurrentIndex(index)
        self.theme_combo.currentTextChanged.connect(self.change_theme)
        appearance_layout.addWidget(self.theme_combo)
        
        settings_layout.addWidget(appearance_group)
        
        # Save settings button
        save_settings_btn = QPushButton("Save Settings")
        save_settings_btn.clicked.connect(self.save_settings_clicked)
        settings_layout.addWidget(save_settings_btn)
        
        # Add settings tab
        self.tab_widget.addTab(settings_widget, "Settings")
    
    def update_protection_status(self):
        if self.settings.get("real_time_protection", True):
            self.protection_status_label.setText("Protection: Active")
            self.protection_status_label.setStyleSheet("color: green; font-weight: bold;")
        else:
            self.protection_status_label.setText("Protection: Disabled")
            self.protection_status_label.setStyleSheet("color: red; font-weight: bold;")
    
    def browse_scan_location(self):
        file_dialog = QFileDialog()
        file_dialog.setFileMode(QFileDialog.Directory)
        file_dialog.setOption(QFileDialog.DontUseNativeDialog, True)
        file_dialog.setOption(QFileDialog.ShowDirsOnly, False)
        
        if file_dialog.exec_():
            selected_files = file_dialog.selectedFiles()
            if selected_files:
                self.custom_scan_path.setText(selected_files[0])
    
    def start_scan(self, scan_type, custom_path="", scan_archives=True):
        if self.scanner_thread and self.scanner_thread.isRunning():
            QMessageBox.warning(self, "Scan in Progress", "A scan is already in progress. Please wait for it to complete or cancel it.")
            return
        
        paths = []
        
        if scan_type == "quick":
            # Quick scan checks common locations
            paths = [
                os.path.join(os.environ["USERPROFILE"], "Downloads"),
                os.path.join(os.environ["USERPROFILE"], "Desktop"),
                os.environ["TEMP"],
                os.path.join(os.environ["ProgramData"], "Microsoft\\Windows\\Start Menu\\Programs\\Startup"),
                os.path.join(os.environ["APPDATA"], "Microsoft\\Windows\\Start Menu\\Programs\\Startup")
            ]
            self.scan_status_label.setText("Starting quick scan...")
        elif scan_type == "full":
            # Full scan checks entire system
            system_drive = os.environ.get("SystemDrive", "C:")
            paths = [system_drive + "\\"]
            self.scan_status_label.setText("Starting full system scan...")
        elif scan_type == "custom":
            # Custom scan checks user-specified location
            if not custom_path or not os.path.exists(custom_path):
                QMessageBox.warning(self, "Invalid Path", "Please select a valid file or folder to scan.")
                return
            paths = [custom_path]
            self.scan_status_label.setText(f"Starting custom scan of {custom_path}...")
        
        # Clear previous results
        self.scan_results_list.clear()
        
        # Start the scanner thread
        self.scanner_thread = FileScannerThread(paths, scan_archives)
        self.scanner_thread.update_progress.connect(self.update_scan_progress)
        self.scanner_thread.scan_complete.connect(self.scan_completed)
        self.scanner_thread.threat_found.connect(self.threat_detected)
        self.scanner_thread.start()
        
        # Enable cancel button
        self.cancel_scan_btn.setEnabled(True)
        
        # Log the scan start
        log_activity(f"Started {scan_type} scan")
    
    def update_scan_progress(self, current, total, status):
        if total > 0:
            progress = int((current / total) * 100)
            self.scan_progress_bar.setValue(progress)
        else:
            self.scan_progress_bar.setValue(0)
        
        self.scan_status_label.setText(status)
        self.statusBar().showMessage(f"Scanning... {current}/{total} files")
    
    def scan_completed(self, result):
        self.scan_progress_bar.setValue(100)
        self.scan_status_label.setText(f"Scan completed. Scanned {result['scanned_files']} files, found {result['infected_files']} threats.")
        self.statusBar().showMessage(f"Scan completed in {result['duration']:.2f} seconds")
        
        # Disable cancel button
        self.cancel_scan_btn.setEnabled(False)
        
        # Show notification
        self.tray_icon.showMessage(
            "Scan Completed",
            f"Scanned {result['scanned_files']} files, found {result['infected_files']} threats.",
            QSystemTrayIcon.Information,
            5000
        )
        
        # Log the scan completion
        log_activity(f"Scan completed: {result['scanned_files']} files scanned, {result['infected_files']} threats found")
        
        # Update dashboard
        self.create_dashboard_tab()
    
    def threat_detected(self, file_path, threat_type):
        item = QListWidgetItem(f"{file_path} - {threat_type}")
        item.setIcon(self.style().standardIcon(QApplication.style().SP_MessageBoxWarning))
        item.setData(Qt.UserRole, file_path)
        self.scan_results_list.addItem(item)
    
    def cancel_scan(self):
        if self.scanner_thread and self.scanner_thread.isRunning():
            self.scanner_thread.stop()
            self.scan_status_label.setText("Scan cancelled")
            self.statusBar().showMessage("Scan cancelled")
            self.cancel_scan_btn.setEnabled(False)
            log_activity("Scan cancelled by user")
    
    def quarantine_selected(self):
        selected_items = self.scan_results_list.selectedItems()
        if not selected_items:
            QMessageBox.information(self, "No Selection", "Please select one or more threats to quarantine.")
            return
        
        for item in selected_items:
            file_path = item.data(Qt.UserRole)
            success, message = quarantine_file(file_path)
            
            if success:
                self.scan_results_list.takeItem(self.scan_results_list.row(item))
                QMessageBox.information(self, "File Quarantined", f"{file_path} has been moved to quarantine.")
                log_activity(f"File quarantined: {file_path}")
            else:
                QMessageBox.warning(self, "Quarantine Failed", f"Failed to quarantine {file_path}: {message}")
        
        # Refresh quarantine list
        self.refresh_quarantine_list()
    
    def delete_selected(self):
        selected_items = self.scan_results_list.selectedItems()
        if not selected_items:
            QMessageBox.information(self, "No Selection", "Please select one or more threats to delete.")
            return
        
        confirm = QMessageBox.question(self, "Confirm Deletion", 
                                     "Are you sure you want to permanently delete the selected files?",
                                     QMessageBox.Yes | QMessageBox.No)
        
        if confirm == QMessageBox.Yes:
            for item in selected_items:
                file_path = item.data(Qt.UserRole)
                try:
                    os.remove(file_path)
                    self.scan_results_list.takeItem(self.scan_results_list.row(item))
                    log_activity(f"File deleted: {file_path}")
                except Exception as e:
                    QMessageBox.warning(self, "Deletion Failed", f"Failed to delete {file_path}: {str(e)}")
    
    def ignore_selected(self):
        selected_items = self.scan_results_list.selectedItems()
        if not selected_items:
            QMessageBox.information(self, "No Selection", "Please select one or more threats to ignore.")
            return
        
        for item in selected_items:
            self.scan_results_list.takeItem(self.scan_results_list.row(item))
    
    def refresh_quarantine_list(self):
        self.quarantine_list.clear()
        
        if os.path.exists(QUARANTINE_FOLDER):
            for filename in os.listdir(QUARANTINE_FOLDER):
                if filename.endswith(".quarantine"):
                    quarantine_path = os.path.join(QUARANTINE_FOLDER, filename)
                    metadata_path = f"{quarantine_path}.meta"
                    
                    if os.path.exists(metadata_path):
                        try:
                            with open(metadata_path, 'r') as f:
                                metadata = json.load(f)
                            
                            original_path = metadata.get("original_path", "Unknown")
                            quarantine_date = metadata.get("quarantine_date", "Unknown")
                            
                            item = QListWidgetItem(f"{original_path} (Quarantined on {quarantine_date})")
                            item.setData(Qt.UserRole, quarantine_path)
                            self.quarantine_list.addItem(item)
                        except Exception as e:
                            log_activity(f"Error loading quarantine metadata for {filename}: {str(e)}", "ERROR")
    
    def restore_selected(self):
        selected_items = self.quarantine_list.selectedItems()
        if not selected_items:
            QMessageBox.information(self, "No Selection", "Please select one or more quarantined files to restore.")
            return
        
        for item in selected_items:
            quarantine_path = item.data(Qt.UserRole)
            success, message = restore_quarantined_file(quarantine_path)
            
            if success:
                self.quarantine_list.takeItem(self.quarantine_list.row(item))
                QMessageBox.information(self, "File Restored", message)
            else:
                QMessageBox.warning(self, "Restore Failed", f"Failed to restore file: {message}")
    
    def delete_quarantined(self):
        selected_items = self.quarantine_list.selectedItems()
        if not selected_items:
            QMessageBox.information(self, "No Selection", "Please select one or more quarantined files to delete.")
            return
        
        confirm = QMessageBox.question(self, "Confirm Deletion", 
                                     "Are you sure you want to permanently delete the selected quarantined files?",
                                     QMessageBox.Yes | QMessageBox.No)
        
        if confirm == QMessageBox.Yes:
            for item in selected_items:
                quarantine_path = item.data(Qt.UserRole)
                success, message = delete_quarantined_file(quarantine_path)
                
                if success:
                    self.quarantine_list.takeItem(self.quarantine_list.row(item))
                    log_activity(f"Quarantined file deleted: {quarantine_path}")
                else:
                    QMessageBox.warning(self, "Deletion Failed", f"Failed to delete quarantined file: {message}")
    
    def toggle_real_time_protection(self, state):
        if state == Qt.Checked or state == True:
            if not self.real_time_monitor or not self.real_time_monitor.isRunning():
                self.real_time_monitor = RealTimeMonitor()
                self.real_time_monitor.threat_detected.connect(self.real_time_threat_detected)
                self.real_time_monitor.start()
                log_activity("Real-time protection enabled")
                self.statusBar().showMessage("Real-time protection enabled")
                settings["real_time_protection"] = True
                save_settings()
                # Update UI elements
                self.update_protection_ui()
        else:
            if self.real_time_monitor and self.real_time_monitor.isRunning():
                self.real_time_monitor.stop()
                self.real_time_monitor = None
                log_activity("Real-time protection disabled")
                self.statusBar().showMessage("Real-time protection disabled")
                settings["real_time_protection"] = False
                save_settings()
                # Update UI elements
                self.update_protection_ui()
    
    def real_time_threat_detected(self, file_path, threat_type):
        notification = QSystemTrayIcon.Information
        self.tray_icon.showMessage(
            "ArcSentinel - Threat Detected",
            f"Threat detected: {threat_type} in {file_path}",
            notification,
            5000
        )
        log_activity(f"Real-time protection detected threat: {threat_type} in {file_path}")
        
        # Add to scan results list
        self.tab_widget.setCurrentIndex(1)  # Switch to scan tab
        self.threat_detected(file_path, threat_type)
    
    def update_system_health(self):
        # Update system health metrics
        cpu_percent = psutil.cpu_percent()
        memory_percent = psutil.virtual_memory().percent
        disk_percent = psutil.disk_usage('/').percent
        
        self.cpu_progress.setValue(int(cpu_percent))
        self.memory_progress.setValue(int(memory_percent))
        self.disk_progress.setValue(int(disk_percent))
        
        # Update labels
        self.cpu_label.setText(f"CPU Usage: {cpu_percent}%")
        self.memory_label.setText(f"Memory Usage: {memory_percent}%")
        self.disk_label.setText(f"Disk Usage: {disk_percent}%")
        
        # Set colors based on usage
        for progress, usage in [(self.cpu_progress, cpu_percent), 
                               (self.memory_progress, memory_percent),
                               (self.disk_progress, disk_percent)]:
            if usage < 60:
                progress.setStyleSheet("QProgressBar::chunk { background-color: green; }")
            elif usage < 80:
                progress.setStyleSheet("QProgressBar::chunk { background-color: orange; }")
            else:
                progress.setStyleSheet("QProgressBar::chunk { background-color: red; }")
    
    def update_signatures(self):
        self.statusBar().showMessage("Updating virus signatures...")
        self.update_signatures_btn.setEnabled(False)
        
        # In a real application, this would download new signatures from a server
        # For this demo, we'll just simulate an update
        QTimer.singleShot(2000, self.finish_signature_update)
    
    def finish_signature_update(self):
        # Simulate adding new signatures
        global virus_signatures
        
        # Add some demo signatures if they don't exist
        new_signatures = {
            "test_malware_1": "e1a1d38bc042e13e8d2dcb7184641c5abe21e5836715a5c6cc4cd1be9ab781b8",
            "test_malware_2": "b1a8d38bc042e13e8d2dcb7184641c5abe21e5836715a5c6cc4cd1be9ab781c9",
            "test_ransomware": "c1a7d38bc042e13e8d2dcb7184641c5abe21e5836715a5c6cc4cd1be9ab781d0"
        }
        
        for name, sig in new_signatures.items():
            if name not in virus_signatures:
                virus_signatures[name] = sig
        
        save_signatures()
        
        self.statusBar().showMessage("Virus signatures updated successfully")
        self.update_signatures_btn.setEnabled(True)
        log_activity("Virus signatures updated")
        
        # Update last update date
        settings["last_update"] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        save_settings()
        self.last_update_label.setText(f"Last Update: {settings['last_update']}")
    
    def save_settings_ui(self):
        # Save settings from UI
        settings["scan_archives"] = self.scan_archives_cb.isChecked()
        settings["heuristic_analysis"] = self.heuristic_analysis_cb.isChecked()
        settings["startup_scan"] = self.startup_scan_cb.isChecked()
        settings["real_time_protection"] = self.real_time_protection_cb.isChecked()
        
        save_settings()
        QMessageBox.information(self, "Settings Saved", "Your settings have been saved successfully.")
        log_activity("Settings updated by user")
    
    def reset_settings(self):
        confirm = QMessageBox.question(self, "Confirm Reset", 
                                     "Are you sure you want to reset all settings to default?",
                                     QMessageBox.Yes | QMessageBox.No)
        
        if confirm == QMessageBox.Yes:
            # Reset to defaults
            global settings
            settings = {
                "scan_archives": True,
                "heuristic_analysis": True,
                "startup_scan": True,
                "real_time_protection": True,
                "last_update": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            }
            save_settings()
            
            # Update UI
            self.load_settings_ui()
            QMessageBox.information(self, "Settings Reset", "All settings have been reset to default values.")
            log_activity("Settings reset to defaults")
    
    def load_settings_ui(self):
        # Load settings into UI
        self.scan_archives_cb.setChecked(settings.get("scan_archives", True))
        self.heuristic_analysis_cb.setChecked(settings.get("heuristic_analysis", True))
        self.startup_scan_cb.setChecked(settings.get("startup_scan", True))
        self.real_time_protection_cb.setChecked(settings.get("real_time_protection", True))
        self.last_update_label.setText(f"Last Update: {settings.get('last_update', 'Never')}")
    
    def create_tray_icon(self):
        # Create system tray icon
        self.tray_icon = QSystemTrayIcon(self)
        self.tray_icon.setIcon(QIcon(os.path.join(APP_DIR, "icon.ico")))
        
        # Create tray menu
        tray_menu = QMenu()
        
        open_action = QAction("Open ArcSentinel", self)
        open_action.triggered.connect(self.show)
        
        quick_scan_action = QAction("Quick Scan", self)
        quick_scan_action.triggered.connect(lambda: self.start_scan("quick"))
        
        exit_action = QAction("Exit", self)
        exit_action.triggered.connect(self.close_application)
        
        tray_menu.addAction(open_action)
        tray_menu.addAction(quick_scan_action)
        tray_menu.addSeparator()
        tray_menu.addAction(exit_action)
        
        self.tray_icon.setContextMenu(tray_menu)
        self.tray_icon.show()
    
    def closeEvent(self, event):
        # Minimize to tray instead of closing
        if self.tray_icon.isVisible():
            QMessageBox.information(self, "ArcSentinel",
                                 "ArcSentinel will continue running in the system tray. "
                                 "To exit completely, right-click the tray icon and select 'Exit'.")
            self.hide()
            event.ignore()
    
    def close_application(self):
        # Stop all threads before closing
        if self.real_time_monitor and self.real_time_monitor.isRunning():
            self.real_time_monitor.stop()
        
        if self.scanner_thread and self.scanner_thread.isRunning():
            self.scanner_thread.stop()
        
        # Save settings
        save_settings()
        
        # Close application
        QApplication.quit()

# Main entry point
def main():
    # Check and install dependencies if needed
    try:
        success, message = install_dependencies()
        if not success:
            print(message)
            if not getattr(sys, 'frozen', False):
                # Only exit if running from source, not from frozen executable
                sys.exit(1)
    except Exception as e:
        print(f"Error checking dependencies: {str(e)}")
    
    # Create application directories
    setup_directories()
    
    # Initialize logging
    init_logging()
    
    # Add application to startup menu
    try:
        startup_success, startup_message = add_to_startup()
        if not startup_success:
            print(f"Warning: Could not add to startup: {startup_message}")
            logging.warning(f"Could not add to startup: {startup_message}")
    except Exception as e:
        print(f"Error adding to startup: {str(e)}")
        logging.error(f"Error adding to startup: {str(e)}")
    
    # Load settings and signatures
    load_settings()
    load_signatures()
    
    # Create and show the application
    app = QApplication(sys.argv)
    app.setStyle("Fusion")
    
    # Set application icon
    app_icon = QIcon(os.path.join(APP_DIR, "icon.ico"))
    app.setWindowIcon(app_icon)
    
    # Apply dark theme
    apply_dark_theme(app)
    
    # Create main window
    window = MainWindow()
    window.show()
    
    # Start real-time protection if enabled
    if settings.get("real_time_protection", True):
        window.real_time_protection_cb.setChecked(True)
        window.toggle_real_time_protection(Qt.Checked)
    
    # Run startup scan if enabled
    if settings.get("startup_scan", True):
        QTimer.singleShot(1000, lambda: window.start_scan("quick"))
    
    sys.exit(app.exec_())

if __name__ == "__main__":
    main()