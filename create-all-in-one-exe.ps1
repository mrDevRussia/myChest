# PowerShell script to create an all-in-one executable for JET IDE

# Create a temporary directory
$tempDir = "temp_allinone"
if (!(Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir | Out-Null
}

# Create a C# source file for the all-in-one application
$appSource = @"
using System;
using System.Diagnostics;
using System.IO;
using System.IO.Compression;
using System.Reflection;
using System.Windows.Forms;
using System.Threading.Tasks;

namespace JETIDEAllInOne
{
    class Program
    {
        private static string appDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "JET IDE");
        private static string appExe = Path.Combine(appDir, "JET.App", "JET.exe");
        private static string resourceName = "JETIDEAllInOne.Resources.jetapp.zip";

        [STAThread]
        static void Main(string[] args)
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);

            try
            {
                if (!IsAppInstalled())
                {
                    if (MessageBox.Show("JET IDE needs to be installed. Would you like to install it now?", 
                                       "JET IDE Setup", MessageBoxButtons.YesNo, MessageBoxIcon.Question) == DialogResult.Yes)
                    {
                        InstallApp();
                    }
                    else
                    {
                        return;
                    }
                }

                // Launch the application
                LaunchApp();
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error: {ex.Message}", "JET IDE", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private static bool IsAppInstalled()
        {
            return File.Exists(appExe);
        }

        private static void InstallApp()
        {
            using (var progressForm = new Form()
            {
                Text = "Installing JET IDE",
                Size = new System.Drawing.Size(400, 100),
                FormBorderStyle = FormBorderStyle.FixedDialog,
                StartPosition = FormStartPosition.CenterScreen,
                MaximizeBox = false,
                MinimizeBox = false
            })
            {
                var progressBar = new ProgressBar()
                {
                    Minimum = 0,
                    Maximum = 100,
                    Value = 0,
                    Dock = DockStyle.Fill,
                    Margin = new Padding(10)
                };

                progressForm.Controls.Add(progressBar);
                progressForm.Show();

                Task.Run(() =>
                {
                    try
                    {
                        // Create application directory
                        if (!Directory.Exists(appDir))
                        {
                            Directory.CreateDirectory(appDir);
                        }

                        // Extract embedded zip file
                        var assembly = Assembly.GetExecutingAssembly();
                        using (var stream = assembly.GetManifestResourceStream(resourceName))
                        {
                            if (stream == null)
                            {
                                throw new Exception("Could not find embedded application files.");
                            }

                            var tempZipPath = Path.Combine(Path.GetTempPath(), "jetapp.zip");
                            using (var fileStream = new FileStream(tempZipPath, FileMode.Create))
                            {
                                stream.CopyTo(fileStream);
                            }

                            // Extract the zip file
                            ZipFile.ExtractToDirectory(tempZipPath, appDir);

                            // Delete the temporary zip file
                            File.Delete(tempZipPath);
                        }

                        // Create desktop shortcut
                        CreateShortcut();

                        progressForm.Invoke(new Action(() => progressForm.Close()));
                    }
                    catch (Exception ex)
                    {
                        progressForm.Invoke(new Action(() =>
                        {
                            progressForm.Close();
                            MessageBox.Show($"Installation failed: {ex.Message}", "JET IDE Setup", MessageBoxButtons.OK, MessageBoxIcon.Error);
                        }));
                    }
                });

                progressForm.ShowDialog();
            }
        }

        private static void CreateShortcut()
        {
            var desktopPath = Environment.GetFolderPath(Environment.SpecialFolder.Desktop);
            var shortcutPath = Path.Combine(desktopPath, "JET IDE.lnk");

            var shell = new IWshRuntimeLibrary.WshShell();
            var shortcut = (IWshRuntimeLibrary.IWshShortcut)shell.CreateShortcut(shortcutPath);
            shortcut.TargetPath = appExe;
            shortcut.WorkingDirectory = Path.GetDirectoryName(appExe);
            shortcut.Description = "JET Integrated Development Environment";
            shortcut.IconLocation = Path.Combine(Path.GetDirectoryName(appExe), "Resources", "Icons", "jet-icon.ico");
            shortcut.Save();
        }

        private static void LaunchApp()
        {
            Process.Start(appExe);
        }
    }
}
"@

# Create the project file
$csprojContent = @"
<Project Sdk="Microsoft.NET.Sdk">

  <PropertyGroup>
    <OutputType>WinExe</OutputType>
    <TargetFramework>net472</TargetFramework>
    <UseWindowsForms>true</UseWindowsForms>
    <ApplicationIcon>jet-icon.ico</ApplicationIcon>
    <AssemblyName>JET-IDE-Setup</AssemblyName>
  </PropertyGroup>

  <ItemGroup>
    <COMReference Include="IWshRuntimeLibrary">
      <WrapperTool>tlbimp</WrapperTool>
      <VersionMinor>0</VersionMinor>
      <VersionMajor>1</VersionMajor>
      <Guid>f935dc20-1cf0-11d0-adb9-00c04fd58a0b</Guid>
      <Lcid>0</Lcid>
      <Isolated>false</Isolated>
      <EmbedInteropTypes>true</EmbedInteropTypes>
    </COMReference>
  </ItemGroup>

  <ItemGroup>
    <Content Include="jet-icon.ico" />
  </ItemGroup>

  <ItemGroup>
    <EmbeddedResource Include="Resources\jetapp.zip" />
  </ItemGroup>

</Project>
"@

# Create the necessary directories
New-Item -ItemType Directory -Path "$tempDir\Resources" -Force | Out-Null

# Copy the icon file
Copy-Item -Path "JET.App\Resources\Icons\jet-icon.ico" -Destination "$tempDir\jet-icon.ico" -Force

# Write the C# source to a file
$appSource | Out-File -FilePath "$tempDir\Program.cs" -Encoding UTF8

# Write the project file
$csprojContent | Out-File -FilePath "$tempDir\JETIDEAllInOne.csproj" -Encoding UTF8

# Create a zip file of the JET.App directory
Write-Host "Creating application package..."
$zipPath = "$tempDir\Resources\jetapp.zip"

if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory("JET.App", $zipPath)

# Check if dotnet is available
$dotnetAvailable = $null -ne (Get-Command "dotnet" -ErrorAction SilentlyContinue)

if ($dotnetAvailable) {
    # Build the project using .NET SDK
    Write-Host "Building all-in-one executable..."
    Push-Location $tempDir
    try {
        dotnet publish -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -o "..\publish"
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Failed to build the project using dotnet." -ForegroundColor Red
            exit 1
        }
    } finally {
        Pop-Location
    }
} else {
    # Use MSBuild if available
    $msbuildPath = Get-ChildItem -Path "${env:ProgramFiles(x86)}\Microsoft Visual Studio\*\*\MSBuild\*\Bin\MSBuild.exe" -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName
    
    if ($msbuildPath) {
        Write-Host "Building all-in-one executable using MSBuild..."
        Push-Location $tempDir
        try {
            & $msbuildPath /p:Configuration=Release /p:Platform="Any CPU" /t:Rebuild
            if ($LASTEXITCODE -ne 0) {
                Write-Host "Failed to build the project using MSBuild." -ForegroundColor Red
                exit 1
            }
        } finally {
            Pop-Location
        }
    } else {
        Write-Host "Neither .NET SDK nor MSBuild is available. Cannot build the project." -ForegroundColor Red
        exit 1
    }
}

# Check if the executable was created
if (Test-Path "publish\JET-IDE-Setup.exe") {
    Copy-Item "publish\JET-IDE-Setup.exe" -Destination "JET-IDE-Setup.exe" -Force
    Write-Host "`nJET-IDE-Setup.exe created successfully." -ForegroundColor Green
} elseif (Test-Path "$tempDir\bin\Release\JET-IDE-Setup.exe") {
    Copy-Item "$tempDir\bin\Release\JET-IDE-Setup.exe" -Destination "JET-IDE-Setup.exe" -Force
    Write-Host "`nJET-IDE-Setup.exe created successfully." -ForegroundColor Green
} else {
    Write-Host "`nFailed to create JET-IDE-Setup.exe" -ForegroundColor Red
    exit 1
}

# Clean up
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "publish" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "`nProcess completed successfully." -ForegroundColor Green
Write-Host "The all-in-one executable will install and launch JET IDE when run." -ForegroundColor Green