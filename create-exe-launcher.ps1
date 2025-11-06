# PowerShell script to create an executable launcher for the installer

# Create a temporary directory
$tempDir = "temp"
if (!(Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir | Out-Null
}

# Create a C# source file for the launcher
$launcherSource = @"
using System;
using System.Diagnostics;
using System.IO;
using System.Windows.Forms;

namespace JETIDEInstaller
{
    class Program
    {
        [STAThread]
        static void Main(string[] args)
        {
            try
            {
                string currentDir = AppDomain.CurrentDomain.BaseDirectory;
                string installerPath = Path.Combine(currentDir, "fixed-installer.bat");
                
                if (!File.Exists(installerPath))
                {
                    MessageBox.Show("Installer file not found: " + installerPath, "JET IDE Installer", 
                        MessageBoxButtons.OK, MessageBoxIcon.Error);
                    return;
                }
                
                ProcessStartInfo psi = new ProcessStartInfo();
                psi.FileName = "cmd.exe";
                psi.Arguments = "/c \"" + installerPath + "\"";
                psi.WorkingDirectory = currentDir;
                psi.UseShellExecute = true;
                
                Process.Start(psi);
            }
            catch (Exception ex)
            {
                MessageBox.Show("Error launching installer: " + ex.Message, "JET IDE Installer", 
                    MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }
    }
}
"@

# Write the C# source to a file
$launcherSource | Out-File -FilePath "$tempDir\Launcher.cs" -Encoding UTF8

# Compile the launcher
Write-Host "Compiling launcher executable..."
$cscPath = "C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe"

if (!(Test-Path $cscPath)) {
    Write-Host "C# compiler not found at: $cscPath" -ForegroundColor Red
    Write-Host "Searching for alternative compiler..."
    
    $cscPath = Get-ChildItem -Path "C:\Windows\Microsoft.NET\Framework" -Filter "csc.exe" -Recurse | 
               Sort-Object -Property FullName -Descending | 
               Select-Object -First 1 -ExpandProperty FullName
    
    if (!$cscPath) {
        Write-Host "C# compiler not found. Cannot create executable." -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Found compiler at: $cscPath" -ForegroundColor Green
}

$iconPath = "JET.App\Resources\Icons\jet-icon.ico"
$compileCommand = "& '$cscPath' /target:winexe /out:JET-IDE-Installer.exe /reference:'System.Windows.Forms.dll' '$tempDir\Launcher.cs'"

if (Test-Path $iconPath) {
    $compileCommand = "& '$cscPath' /target:winexe /out:JET-IDE-Installer.exe /reference:'System.Windows.Forms.dll' /win32icon:'$iconPath' '$tempDir\Launcher.cs'"
}

try {
    Invoke-Expression $compileCommand
} catch {
    Write-Host "Error compiling launcher: $_" -ForegroundColor Red
    exit 1
}

# Check if the executable was created
if (Test-Path "JET-IDE-Installer.exe") {
    Write-Host "`nJET-IDE-Installer.exe created successfully." -ForegroundColor Green
} else {
    Write-Host "`nFailed to create JET-IDE-Installer.exe" -ForegroundColor Red
    exit 1
}

# Clean up
Remove-Item -Path $tempDir -Recurse -Force

Write-Host "`nProcess completed successfully." -ForegroundColor Green