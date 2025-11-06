#!/usr/bin/env python3
"""
Test Script for ArcSentinel

This script performs basic tests to ensure that ArcSentinel's core functionality
is working correctly.
"""

import os
import sys
import hashlib
import tempfile
import shutil
import json
from datetime import datetime

# Add the current directory to the path so we can import from ArcSentinel.py
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Try to import from ArcSentinel
try:
    from ArcSentinel import (
        APP_DIR, QUARANTINE_FOLDER, LOG_FILE, SETTINGS_FILE, SIGNATURES_FILE,
        create_app_dirs, init_logging, load_settings, save_settings,
        load_signatures, save_signatures, log_activity,
        scan_file, quarantine_file, restore_quarantined_file, delete_quarantined_file
    )
    print("Successfully imported ArcSentinel modules")
except ImportError as e:
    print(f"Error importing from ArcSentinel: {e}")
    print("Make sure ArcSentinel.py is in the current directory")
    sys.exit(1)

def create_test_file(content, suffix=".txt"):
    """Create a temporary test file with the given content"""
    fd, path = tempfile.mkstemp(suffix=suffix)
    with os.fdopen(fd, 'w') as f:
        f.write(content)
    return path

def test_file_scanning():
    """Test the file scanning functionality"""
    print("\n=== Testing File Scanning ===\n")
    
    # Create a clean test file
    clean_content = "This is a clean test file for ArcSentinel."
    clean_file = create_test_file(clean_content)
    print(f"Created clean test file: {clean_file}")
    
    # Create a test file with a signature that should be detected
    # Using one of the test signatures from ArcSentinel
    test_signature = "e1a1d38bc042e13e8d2dcb7184641c5abe21e5836715a5c6cc4cd1be9ab781b8"
    malware_content = f"TEST MALWARE SIGNATURE: {test_signature}\n"
    malware_file = create_test_file(malware_content, ".malware")
    print(f"Created test malware file: {malware_file}")
    
    # Test scanning the clean file
    print("\nScanning clean file...")
    result, threat_name = scan_file(clean_file)
    if result:
        print(f"ERROR: Clean file incorrectly detected as {threat_name}")
    else:
        print("SUCCESS: Clean file correctly identified as safe")
    
    # Test scanning the malware file
    print("\nScanning test malware file...")
    result, threat_name = scan_file(malware_file)
    if result:
        print(f"SUCCESS: Test malware correctly detected as {threat_name}")
    else:
        print("ERROR: Test malware not detected")
    
    # Clean up
    os.remove(clean_file)
    os.remove(malware_file)
    print("\nTest files removed")

def test_quarantine():
    """Test the quarantine functionality"""
    print("\n=== Testing Quarantine Functionality ===\n")
    
    # Create a test file to quarantine
    test_content = "This is a test file for quarantine functionality."
    test_file = create_test_file(test_content)
    print(f"Created test file: {test_file}")
    
    # Test quarantining the file
    print("\nQuarantining test file...")
    success, quarantine_path = quarantine_file(test_file)
    
    if success:
        print(f"SUCCESS: File quarantined to {quarantine_path}")
        
        # Check if original file is gone
        if not os.path.exists(test_file):
            print("SUCCESS: Original file was removed")
        else:
            print("ERROR: Original file still exists")
        
        # Check if quarantine file exists
        if os.path.exists(quarantine_path):
            print("SUCCESS: Quarantine file exists")
        else:
            print("ERROR: Quarantine file does not exist")
        
        # Check if metadata file exists
        metadata_path = f"{quarantine_path}.meta"
        if os.path.exists(metadata_path):
            print("SUCCESS: Metadata file exists")
            
            # Check metadata content
            try:
                with open(metadata_path, 'r') as f:
                    metadata = json.load(f)
                if "original_path" in metadata and "quarantine_date" in metadata:
                    print("SUCCESS: Metadata contains required information")
                else:
                    print("ERROR: Metadata missing required fields")
            except Exception as e:
                print(f"ERROR: Failed to read metadata: {e}")
        else:
            print("ERROR: Metadata file does not exist")
        
        # Test restoring the file
        print("\nRestoring quarantined file...")
        restore_success, restore_path = restore_quarantined_file(quarantine_path)
        
        if restore_success:
            print(f"SUCCESS: File restored to {restore_path}")
            
            # Check if quarantine file is gone
            if not os.path.exists(quarantine_path):
                print("SUCCESS: Quarantine file was removed")
            else:
                print("ERROR: Quarantine file still exists")
            
            # Check if restored file exists
            if os.path.exists(restore_path):
                print("SUCCESS: Restored file exists")
                
                # Check content
                try:
                    with open(restore_path, 'r') as f:
                        restored_content = f.read()
                    if restored_content == test_content:
                        print("SUCCESS: Restored file content matches original")
                    else:
                        print("ERROR: Restored file content does not match original")
                except Exception as e:
                    print(f"ERROR: Failed to read restored file: {e}")
                
                # Clean up
                os.remove(restore_path)
            else:
                print("ERROR: Restored file does not exist")
        else:
            print(f"ERROR: Failed to restore file: {restore_path}")
            
            # Clean up quarantine file
            delete_quarantined_file(quarantine_path)
    else:
        print(f"ERROR: Failed to quarantine file: {quarantine_path}")
        # Clean up original file
        os.remove(test_file)

def test_settings():
    """Test the settings functionality"""
    print("\n=== Testing Settings Functionality ===\n")
    
    # Save original settings
    original_settings = load_settings()
    print("Loaded original settings")
    
    # Modify settings
    test_settings = {
        "scan_archives": not original_settings.get("scan_archives", True),
        "heuristic_analysis": not original_settings.get("heuristic_analysis", True),
        "startup_scan": not original_settings.get("startup_scan", True),
        "real_time_protection": not original_settings.get("real_time_protection", True),
        "last_update": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    }
    
    # Save test settings
    print("Saving test settings...")
    save_settings(test_settings)
    
    # Load settings again
    loaded_settings = load_settings()
    print("Loaded settings after save")
    
    # Compare
    success = True
    for key, value in test_settings.items():
        if loaded_settings.get(key) != value:
            print(f"ERROR: Setting {key} does not match")
            print(f"  Expected: {value}")
            print(f"  Got: {loaded_settings.get(key)}")
            success = False
    
    if success:
        print("SUCCESS: All settings saved and loaded correctly")
    
    # Restore original settings
    print("Restoring original settings...")
    save_settings(original_settings)

def main():
    print("===== ArcSentinel Test Suite =====\n")
    
    # Create necessary directories
    create_app_dirs()
    print(f"Application directory: {APP_DIR}")
    print(f"Quarantine folder: {QUARANTINE_FOLDER}")
    print(f"Log file: {LOG_FILE}")
    print(f"Settings file: {SETTINGS_FILE}")
    print(f"Signatures file: {SIGNATURES_FILE}")
    
    # Initialize logging
    init_logging()
    log_activity("Test suite started")
    
    # Run tests
    test_file_scanning()
    test_quarantine()
    test_settings()
    
    print("\n===== Test Suite Completed =====")
    log_activity("Test suite completed")

if __name__ == "__main__":
    main()