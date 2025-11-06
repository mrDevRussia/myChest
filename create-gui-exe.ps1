# Create GUI-based executable installer

$tempDir = "temp_gui_installer"
if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
New-Item -ItemType Directory -Path $tempDir | Out-Null

# Create C# source for GUI launcher
$csharpCode = @'
using System;
using System.Diagnostics;
using System.IO;
using System.Windows.Forms;

namespace JETIDEGUIInstaller
{
    class Program
    {
        [STAThread]
        static void Main(string[] args)
        {
            try
            {
                // Extract and run the PowerShell GUI installer
                string tempPath = Path.GetTempPath();
                string installerScript = Path.Combine(tempPath, "jet_gui_installer.ps1");
                
                // Write the embedded PowerShell script
                string psScript = GetEmbeddedScript();
                File.WriteAllText(installerScript, psScript);
                
                // Run PowerShell with the GUI script
                ProcessStartInfo psi = new ProcessStartInfo()
                {
                    FileName = "powershell.exe",
                    Arguments = $"-ExecutionPolicy Bypass -WindowStyle Hidden -File \"{installerScript}\"",
                    UseShellExecute = false,
                    CreateNoWindow = true
                };
                
                Process process = Process.Start(psi);
                process.WaitForExit();
                
                // Clean up
                if (File.Exists(installerScript))
                {
                    File.Delete(installerScript);
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error: {ex.Message}", "JET IDE Installer", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }
        
        private static string GetEmbeddedScript()
        {
            return @"# GUI Installer for JET IDE
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = \"JET IDE Setup\"
$form.Size = New-Object System.Drawing.Size(450, 350)
$form.StartPosition = \"CenterScreen\"
$form.FormBorderStyle = \"FixedDialog\"
$form.MaximizeBox = $false

$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = \"JET IDE Setup Wizard\"
$titleLabel.Font = New-Object System.Drawing.Font(\"Arial\", 14, [System.Drawing.FontStyle]::Bold)
$titleLabel.Location = New-Object System.Drawing.Point(120, 20)
$titleLabel.Size = New-Object System.Drawing.Size(200, 25)
$form.Controls.Add($titleLabel)

$descLabel = New-Object System.Windows.Forms.Label
$descLabel.Text = \"Welcome to the JET IDE Setup Wizard.`n`nThis will install JET IDE on your computer.`nClick Install to continue.\"
$descLabel.Location = New-Object System.Drawing.Point(30, 60)
$descLabel.Size = New-Object System.Drawing.Size(380, 60)
$form.Controls.Add($descLabel)

$dirLabel = New-Object System.Windows.Forms.Label
$dirLabel.Text = \"Destination folder:\"
$dirLabel.Location = New-Object System.Drawing.Point(30, 140)
$dirLabel.Size = New-Object System.Drawing.Size(100, 20)
$form.Controls.Add($dirLabel)

$dirTextBox = New-Object System.Windows.Forms.TextBox
$dirTextBox.Text = \"$env:LOCALAPPDATA\JET IDE\"
$dirTextBox.Location = New-Object System.Drawing.Point(30, 165)
$dirTextBox.Size = New-Object System.Drawing.Size(360, 20)
$form.Controls.Add($dirTextBox)

$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(30, 210)
$progressBar.Size = New-Object System.Drawing.Size(360, 20)
$progressBar.Visible = $false
$form.Controls.Add($progressBar)

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = \"Ready to install\"
$statusLabel.Location = New-Object System.Drawing.Point(30, 240)
$statusLabel.Size = New-Object System.Drawing.Size(360, 20)
$form.Controls.Add($statusLabel)

$installButton = New-Object System.Windows.Forms.Button
$installButton.Text = \"Install\"
$installButton.Location = New-Object System.Drawing.Point(230, 270)
$installButton.Size = New-Object System.Drawing.Size(75, 25)
$installButton.BackColor = [System.Drawing.Color]::LightGreen
$form.Controls.Add($installButton)

$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Text = \"Cancel\"
$cancelButton.Location = New-Object System.Drawing.Point(315, 270)
$cancelButton.Size = New-Object System.Drawing.Size(75, 25)
$cancelButton.Add_Click({ $form.Close() })
$form.Controls.Add($cancelButton)

$installButton.Add_Click({
    [System.Windows.Forms.MessageBox]::Show(
        \"This is a demo GUI installer.`nThe actual installation would copy files and create shortcuts here.\",
        \"JET IDE Setup\",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )
    $form.Close()
})

$form.ShowDialog() | Out-Null";
        }
    }
}
'@

# Write the C# source file
$csharpCode | Out-File -FilePath "$tempDir\Program.cs" -Encoding UTF8

# Copy icon if it exists
if (Test-Path "JET.App\Resources\Icons\jet-icon.ico") {
    Copy-Item "JET.App\Resources\Icons\jet-icon.ico" "$tempDir\icon.ico"
}

# Compile the C# code
Write-Host "Compiling GUI installer..."

$cscPath = "$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if (!(Test-Path $cscPath)) {
    $cscPath = "$env:WINDIR\Microsoft.NET\Framework\v4.0.30319\csc.exe"
}

if (Test-Path $cscPath) {
    $compileArgs = @(
        "/target:winexe"
        "/reference:System.Windows.Forms.dll"
        "/reference:System.Drawing.dll"
        "/out:JET-IDE-GUI-Setup.exe"
    )
    
    if (Test-Path "$tempDir\icon.ico") {
        $compileArgs += "/win32icon:$tempDir\icon.ico"
    }
    
    $compileArgs += "$tempDir\Program.cs"
    
    & $cscPath $compileArgs
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "JET-IDE-GUI-Setup.exe created successfully!" -ForegroundColor Green
        Write-Host "This installer provides a proper Windows GUI interface." -ForegroundColor Green
    } else {
        Write-Host "Compilation failed." -ForegroundColor Red
    }
} else {
    Write-Host "C# compiler not found. Please install .NET Framework." -ForegroundColor Red
}

# Clean up
Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue