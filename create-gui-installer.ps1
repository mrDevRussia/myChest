# PowerShell script to create a GUI-based installer for JET IDE

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "JET IDE Installer"
$form.Size = New-Object System.Drawing.Size(500, 400)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.MinimizeBox = $false

# Create a logo/title label
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "JET IDE Installer"
$titleLabel.Font = New-Object System.Drawing.Font("Arial", 16, [System.Drawing.FontStyle]::Bold)
$titleLabel.Location = New-Object System.Drawing.Point(150, 20)
$titleLabel.Size = New-Object System.Drawing.Size(200, 30)
$titleLabel.TextAlign = "MiddleCenter"
$form.Controls.Add($titleLabel)

# Create description label
$descLabel = New-Object System.Windows.Forms.Label
$descLabel.Text = "This will install JET IDE on your computer.`nJET IDE is a modern integrated development environment.`n`nClick Install to begin the installation process."
$descLabel.Location = New-Object System.Drawing.Point(50, 70)
$descLabel.Size = New-Object System.Drawing.Size(400, 80)
$descLabel.TextAlign = "TopLeft"
$form.Controls.Add($descLabel)

# Create installation directory label
$dirLabel = New-Object System.Windows.Forms.Label
$dirLabel.Text = "Installation Directory:"
$dirLabel.Location = New-Object System.Drawing.Point(50, 170)
$dirLabel.Size = New-Object System.Drawing.Size(120, 20)
$form.Controls.Add($dirLabel)

# Create installation directory textbox
$dirTextBox = New-Object System.Windows.Forms.TextBox
$dirTextBox.Text = "$env:LOCALAPPDATA\JET IDE"
$dirTextBox.Location = New-Object System.Drawing.Point(50, 195)
$dirTextBox.Size = New-Object System.Drawing.Size(300, 20)
$dirTextBox.ReadOnly = $true
$form.Controls.Add($dirTextBox)

# Create browse button
$browseButton = New-Object System.Windows.Forms.Button
$browseButton.Text = "Browse..."
$browseButton.Location = New-Object System.Drawing.Point(360, 193)
$browseButton.Size = New-Object System.Drawing.Size(80, 25)
$browseButton.Add_Click({
    $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderDialog.Description = "Select installation directory"
    $folderDialog.SelectedPath = $dirTextBox.Text
    if ($folderDialog.ShowDialog() -eq "OK") {
        $dirTextBox.Text = $folderDialog.SelectedPath + "\JET IDE"
    }
})
$form.Controls.Add($browseButton)

# Create progress bar (initially hidden)
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(50, 240)
$progressBar.Size = New-Object System.Drawing.Size(390, 20)
$progressBar.Visible = $false
$form.Controls.Add($progressBar)

# Create status label (initially hidden)
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "Installing..."
$statusLabel.Location = New-Object System.Drawing.Point(50, 270)
$statusLabel.Size = New-Object System.Drawing.Size(390, 20)
$statusLabel.Visible = $false
$form.Controls.Add($statusLabel)

# Create Install button
$installButton = New-Object System.Windows.Forms.Button
$installButton.Text = "Install"
$installButton.Location = New-Object System.Drawing.Point(250, 310)
$installButton.Size = New-Object System.Drawing.Size(80, 30)
$installButton.BackColor = [System.Drawing.Color]::LightBlue
$installButton.Add_Click({
    # Disable the install button
    $installButton.Enabled = $false
    $browseButton.Enabled = $false
    
    # Show progress bar and status
    $progressBar.Visible = $true
    $statusLabel.Visible = $true
    
    # Start installation in background
    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 100
    $step = 0
    
    $timer.Add_Tick({
        $step++
        $progressBar.Value = [Math]::Min(100, $step * 2)
        
        switch ($step) {
            10 { $statusLabel.Text = "Creating installation directory..." }
            20 { $statusLabel.Text = "Copying application files..." }
            30 { $statusLabel.Text = "Copying documentation..." }
            40 { $statusLabel.Text = "Creating shortcuts..." }
            50 { 
                $statusLabel.Text = "Installation complete!"
                $timer.Stop()
                
                # Perform actual installation
                try {
                    $installDir = $dirTextBox.Text
                    
                    # Create installation directory
                    if (!(Test-Path $installDir)) {
                        New-Item -ItemType Directory -Path $installDir -Force | Out-Null
                    }
                    
                    # Copy JET.App directory
                    $sourceApp = "$PSScriptRoot\JET.App"
                    $destApp = "$installDir\JET.App"
                    if (Test-Path $sourceApp) {
                        Copy-Item -Path $sourceApp -Destination $destApp -Recurse -Force
                    }
                    
                    # Copy documentation files
                    $docFiles = @("LICENSE", "README.md", "INSTALL.md", "PACKAGING.md")
                    foreach ($file in $docFiles) {
                        if (Test-Path "$PSScriptRoot\$file") {
                            Copy-Item -Path "$PSScriptRoot\$file" -Destination "$installDir\$file" -Force
                        }
                    }
                    
                    # Create desktop shortcut
                    $shell = New-Object -ComObject WScript.Shell
                    $shortcut = $shell.CreateShortcut("$env:USERPROFILE\Desktop\JET IDE.lnk")
                    $shortcut.TargetPath = "$installDir\JET.App\JET.exe"
                    $shortcut.WorkingDirectory = "$installDir\JET.App"
                    $shortcut.IconLocation = "$installDir\JET.App\Resources\Icons\jet-icon.ico"
                    $shortcut.Description = "JET Integrated Development Environment"
                    $shortcut.Save()
                    
                    # Show completion message
                    [System.Windows.Forms.MessageBox]::Show(
                        "JET IDE has been installed successfully!`n`nInstallation Directory: $installDir`nA desktop shortcut has been created.`n`nWould you like to launch JET IDE now?",
                        "Installation Complete",
                        [System.Windows.Forms.MessageBoxButtons]::YesNo,
                        [System.Windows.Forms.MessageBoxIcon]::Information
                    ) | ForEach-Object {
                        if ($_ -eq "Yes") {
                            Start-Process "$installDir\JET.App\JET.exe"
                        }
                    }
                    
                    $form.Close()
                    
                } catch {
                    [System.Windows.Forms.MessageBox]::Show(
                        "Installation failed: $($_.Exception.Message)",
                        "Installation Error",
                        [System.Windows.Forms.MessageBoxButtons]::OK,
                        [System.Windows.Forms.MessageBoxIcon]::Error
                    )
                    
                    # Re-enable buttons
                    $installButton.Enabled = $true
                    $browseButton.Enabled = $true
                    $progressBar.Visible = $false
                    $statusLabel.Visible = $false
                }
            }
        }
    })
    
    $timer.Start()
})
$form.Controls.Add($installButton)

# Create Cancel button
$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Text = "Cancel"
$cancelButton.Location = New-Object System.Drawing.Point(350, 310)
$cancelButton.Size = New-Object System.Drawing.Size(80, 30)
$cancelButton.Add_Click({ $form.Close() })
$form.Controls.Add($cancelButton)

# Show the form
$form.ShowDialog() | Out-Null