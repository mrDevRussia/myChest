# GUI Installer for JET IDE
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "JET IDE Setup"
$form.Size = New-Object System.Drawing.Size(450, 350)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "JET IDE Setup Wizard"
$titleLabel.Font = New-Object System.Drawing.Font("Arial", 14, [System.Drawing.FontStyle]::Bold)
$titleLabel.Location = New-Object System.Drawing.Point(120, 20)
$titleLabel.Size = New-Object System.Drawing.Size(200, 25)
$form.Controls.Add($titleLabel)

$descLabel = New-Object System.Windows.Forms.Label
$descLabel.Text = "Welcome to the JET IDE Setup Wizard.`n`nThis will install JET IDE on your computer.`nClick Next to continue."
$descLabel.Location = New-Object System.Drawing.Point(30, 60)
$descLabel.Size = New-Object System.Drawing.Size(380, 60)
$form.Controls.Add($descLabel)

$dirLabel = New-Object System.Windows.Forms.Label
$dirLabel.Text = "Destination folder:"
$dirLabel.Location = New-Object System.Drawing.Point(30, 140)
$dirLabel.Size = New-Object System.Drawing.Size(100, 20)
$form.Controls.Add($dirLabel)

$dirTextBox = New-Object System.Windows.Forms.TextBox
$dirTextBox.Text = "$env:LOCALAPPDATA\JET IDE"
$dirTextBox.Location = New-Object System.Drawing.Point(30, 165)
$dirTextBox.Size = New-Object System.Drawing.Size(280, 20)
$form.Controls.Add($dirTextBox)

$browseButton = New-Object System.Windows.Forms.Button
$browseButton.Text = "Browse"
$browseButton.Location = New-Object System.Drawing.Point(320, 163)
$browseButton.Size = New-Object System.Drawing.Size(70, 25)
$form.Controls.Add($browseButton)

$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(30, 210)
$progressBar.Size = New-Object System.Drawing.Size(360, 20)
$progressBar.Visible = $false
$form.Controls.Add($progressBar)

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "Ready to install"
$statusLabel.Location = New-Object System.Drawing.Point(30, 240)
$statusLabel.Size = New-Object System.Drawing.Size(360, 20)
$form.Controls.Add($statusLabel)

$installButton = New-Object System.Windows.Forms.Button
$installButton.Text = "Install"
$installButton.Location = New-Object System.Drawing.Point(230, 270)
$installButton.Size = New-Object System.Drawing.Size(75, 25)
$installButton.BackColor = [System.Drawing.Color]::LightGreen
$form.Controls.Add($installButton)

$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Text = "Cancel"
$cancelButton.Location = New-Object System.Drawing.Point(315, 270)
$cancelButton.Size = New-Object System.Drawing.Size(75, 25)
$cancelButton.Add_Click({ $form.Close() })
$form.Controls.Add($cancelButton)

$installButton.Add_Click({
    $installButton.Enabled = $false
    $progressBar.Visible = $true
    $statusLabel.Text = "Installing JET IDE..."
    
    $installDir = $dirTextBox.Text
    
    try {
        # Create directory
        if (!(Test-Path $installDir)) {
            New-Item -ItemType Directory -Path $installDir -Force | Out-Null
        }
        $progressBar.Value = 20
        
        # Build JET.App
        $statusLabel.Text = "Building application..."
        $buildProcess = Start-Process -FilePath "dotnet" -ArgumentList "build JET.App\JET.App.csproj -c Release" -NoNewWindow -PassThru -Wait
        if ($buildProcess.ExitCode -ne 0) {
            throw "Failed to build JET.App. Exit code: $($buildProcess.ExitCode)"
        }
        $progressBar.Value = 40
        
        # Copy JET.App
        $statusLabel.Text = "Copying application files..."
        Copy-Item -Path "JET.App" -Destination "$installDir\JET.App" -Recurse -Force
        $progressBar.Value = 60
        
        # Copy docs
        $statusLabel.Text = "Copying documentation..."
        @("LICENSE", "README.md", "INSTALL.md", "PACKAGING.md") | ForEach-Object {
            if (Test-Path $_) { Copy-Item $_ "$installDir\$_" -Force }
        }
        $progressBar.Value = 80
        
        # Create shortcut
        $statusLabel.Text = "Creating shortcuts..."
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut("$env:USERPROFILE\Desktop\JET IDE.lnk")
        $shortcut.TargetPath = "$installDir\JET.App\bin\Release\net6.0-windows\JET.exe"
        $shortcut.WorkingDirectory = "$installDir\JET.App\bin\Release\net6.0-windows"
        $shortcut.Save()
        $progressBar.Value = 100
        
        $statusLabel.Text = "Installation complete!"
        
        $result = [System.Windows.Forms.MessageBox]::Show(
            "JET IDE installed successfully!`n`nLaunch JET IDE now?",
            "Setup Complete",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
        
        if ($result -eq "Yes") {
            Start-Process "$installDir\JET.App\bin\Release\net6.0-windows\JET.exe"
        }
        
        $form.Close()
        
    } catch {
        [System.Windows.Forms.MessageBox]::Show(
            "Installation failed: $($_.Exception.Message)",
            "Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
        $installButton.Enabled = $true
        $progressBar.Visible = $false
        $statusLabel.Text = "Installation failed"
    }
})

$form.ShowDialog() | Out-Null