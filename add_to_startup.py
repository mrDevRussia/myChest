import os
import sys
import winreg
import shutil

def add_to_startup():
    """
    Add ArcSentinel to Windows startup menu and registry
    """
    try:
        # Get the path to the executable
        if getattr(sys, 'frozen', False):
            # Running as compiled executable
            app_path = os.path.abspath(sys.executable)
        else:
            # Running as script
            app_path = os.path.abspath(__file__)
            # In script mode, we would typically use a batch file
            app_path = os.path.join(os.path.dirname(app_path), "ArcSentinel.exe")
        
        app_name = "ArcSentinel"
        
        # 1. Add to registry for startup
        key = winreg.OpenKey(winreg.HKEY_CURRENT_USER, 
                           "Software\\Microsoft\\Windows\\CurrentVersion\\Run", 
                           0, winreg.KEY_SET_VALUE)
        winreg.SetValueEx(key, app_name, 0, winreg.REG_SZ, f'"{app_path}"')
        winreg.CloseKey(key)
        
        # 2. Add to Start Menu
        start_menu_path = os.path.join(os.environ["APPDATA"], 
                                    "Microsoft\\Windows\\Start Menu\\Programs")
        
        # Create ArcSentinel folder in Start Menu if it doesn't exist
        app_folder = os.path.join(start_menu_path, app_name)
        if not os.path.exists(app_folder):
            os.makedirs(app_folder)
        
        # Create shortcut in Start Menu
        shortcut_path = os.path.join(app_folder, f"{app_name}.lnk")
        
        # Use Windows Script Host to create shortcut
        with open(os.path.join(os.environ["TEMP"], "create_shortcut.vbs"), "w") as f:
            f.write(f'Set oWS = WScript.CreateObject("WScript.Shell")\n')
            f.write(f'sLinkFile = "{shortcut_path}"\n')
            f.write(f'Set oLink = oWS.CreateShortcut(sLinkFile)\n')
            f.write(f'oLink.TargetPath = "{app_path}"\n')
            f.write(f'oLink.Description = "ArcSentinel Antivirus"\n')
            f.write(f'oLink.IconLocation = "{app_path},0"\n')
            f.write(f'oLink.Save\n')
        
        os.system(f'cscript //nologo "{os.path.join(os.environ["TEMP"], "create_shortcut.vbs")}"')
        
        # 3. Add to Startup folder (alternative method)
        startup_folder = os.path.join(os.environ["APPDATA"], 
                                   "Microsoft\\Windows\\Start Menu\\Programs\\Startup")
        startup_shortcut = os.path.join(startup_folder, f"{app_name}.lnk")
        
        # Use Windows Script Host to create shortcut in Startup folder
        with open(os.path.join(os.environ["TEMP"], "create_startup_shortcut.vbs"), "w") as f:
            f.write(f'Set oWS = WScript.CreateObject("WScript.Shell")\n')
            f.write(f'sLinkFile = "{startup_shortcut}"\n')
            f.write(f'Set oLink = oWS.CreateShortcut(sLinkFile)\n')
            f.write(f'oLink.TargetPath = "{app_path}"\n')
            f.write(f'oLink.Description = "ArcSentinel Antivirus"\n')
            f.write(f'oLink.IconLocation = "{app_path},0"\n')
            f.write(f'oLink.Save\n')
        
        os.system(f'cscript //nologo "{os.path.join(os.environ["TEMP"], "create_startup_shortcut.vbs")}"')
        
        return True, "Successfully added ArcSentinel to startup"
    
    except Exception as e:
        return False, f"Error adding to startup: {str(e)}"

if __name__ == "__main__":
    success, message = add_to_startup()
    print(message)