# Script to set up automatic updates for JET IDE

# Configuration
$appName = "JET IDE"
$appVersion = "1.0.0"
$updateServerUrl = "https://example.com/updates" # Replace with your actual update server URL

# Create update configuration file
$updateConfigPath = "JET.App\update-config.json"
Write-Host "Creating update configuration at $updateConfigPath..."

$updateConfig = @"
{
  "ApplicationName": "$appName",
  "ApplicationVersion": "$appVersion",
  "UpdateServerUrl": "$updateServerUrl",
  "CheckForUpdatesOnStartup": true,
  "CheckForUpdatesIntervalHours": 24,
  "AutomaticDownload": false,
  "AutomaticInstallation": false
}
"@

Set-Content -Path $updateConfigPath -Value $updateConfig
Write-Host "Update configuration created successfully."

# Add NetSparkle NuGet package to the project
Write-Host "\nTo implement automatic updates, you need to add an update framework to your project."
Write-Host "Here are two recommended options:\n"

Write-Host "Option 1: NetSparkle (Recommended for WPF applications)"
Write-Host "Run the following command in your project directory:"
Write-Host "dotnet add JET.App package NetSparkleUpdater.UI.WPF" -ForegroundColor Cyan
Write-Host "\nImplementation guide: https://github.com/NetSparkleUpdater/NetSparkle\n"

Write-Host "Option 2: Squirrel.Windows"
Write-Host "Run the following command in your project directory:"
Write-Host "dotnet add JET.App package Squirrel.Windows" -ForegroundColor Cyan
Write-Host "\nImplementation guide: https://github.com/Squirrel/Squirrel.Windows\n"

# Create sample implementation file for NetSparkle
$updateServicePath = "JET.App\Services\UpdateService.cs"
Write-Host "Creating sample UpdateService implementation at $updateServicePath..."

$updateServiceContent = @"
using System;
using System.IO;
using System.Threading.Tasks;
using System.Windows;
using NetSparkleUpdater;
using NetSparkleUpdater.Enums;
using NetSparkleUpdater.UI.WPF;

namespace JET.App.Services
{
    public class UpdateService
    {
        private readonly SparkleUpdater _sparkle;
        private readonly string _appCastUrl;

        public UpdateService()
        {
            // Read configuration from update-config.json
            var configPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "update-config.json");
            var config = System.Text.Json.JsonSerializer.Deserialize<UpdateConfig>(
                File.ReadAllText(configPath),
                new System.Text.Json.JsonSerializerOptions { PropertyNameCaseInsensitive = true });

            _appCastUrl = config.UpdateServerUrl + "/appcast.xml";

            // Initialize NetSparkle
            _sparkle = new SparkleUpdater(_appCastUrl, new DSAVerifier());
            
            // Configure the updater
            _sparkle.UIFactory = new UIFactory();
            _sparkle.CheckForUpdateEvents = true;
            _sparkle.ShowsUIOnMainThread = true;
            
            // Set up event handlers
            _sparkle.UpdateDetected += OnUpdateDetected;
            _sparkle.UpdateCheckFinished += OnUpdateCheckFinished;
            
            // Configure automatic update checking
            if (config.CheckForUpdatesOnStartup)
            {
                _sparkle.StartLoop(checkForUpdatesOnFirstStart: true, 
                    timeBeforeFirstCheck: TimeSpan.Zero, 
                    checkFrequency: TimeSpan.FromHours(config.CheckForUpdatesIntervalHours));
            }
        }

        public async Task CheckForUpdatesAsync(bool silent = false)
        {
            await Task.Run(() => _sparkle.CheckForUpdatesAtUserRequest());
        }

        private void OnUpdateDetected(object sender, UpdateDetectedEventArgs e)
        {
            // This event is raised when an update is detected
            Console.WriteLine($"Update detected: {e.AppCastItem.Version}");
        }

        private void OnUpdateCheckFinished(object sender, UpdateCheckFinishedEventArgs e)
        {
            // This event is raised when the update check is complete
            if (e.Status == UpdateStatus.UpdateNotAvailable)
            {
                Console.WriteLine("No updates available");
            }
        }
    }

    public class UpdateConfig
    {
        public string ApplicationName { get; set; }
        public string ApplicationVersion { get; set; }
        public string UpdateServerUrl { get; set; }
        public bool CheckForUpdatesOnStartup { get; set; }
        public int CheckForUpdatesIntervalHours { get; set; }
        public bool AutomaticDownload { get; set; }
        public bool AutomaticInstallation { get; set; }
    }
}
"@

Set-Content -Path $updateServicePath -Value $updateServiceContent
Write-Host "Sample UpdateService implementation created successfully."

# Create sample appcast.xml file
$appcastDir = "update-server"
if (!(Test-Path $appcastDir)) {
    New-Item -ItemType Directory -Path $appcastDir | Out-Null
}

$appcastPath = "$appcastDir\appcast.xml"
Write-Host "\nCreating sample appcast.xml at $appcastPath..."

$appcastContent = @"
<?xml version="1.0" encoding="UTF-8"?>
<rss xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" xmlns:dc="http://purl.org/dc/elements/1.1/" version="2.0">
    <channel>
        <title>$appName Updates</title>
        <description>Most recent changes with links to updates.</description>
        <language>en</language>
        <item>
            <title>Version $appVersion</title>
            <sparkle:version>$appVersion</sparkle:version>
            <description>
                <![CDATA[
                    <h2>$appName $appVersion</h2>
                    <p>Initial release of $appName.</p>
                    <ul>
                        <li>Feature 1: AI-powered code assistance</li>
                        <li>Feature 2: Integrated Git support</li>
                        <li>Feature 3: Collaboration tools</li>
                    </ul>
                ]]>
            </description>
            <pubDate>$(Get-Date -Format r)</pubDate>
            <enclosure url="$updateServerUrl/JET_IDE_Setup.exe" 
                       sparkle:version="$appVersion" 
                       length="0" 
                       type="application/octet-stream" />
        </item>
    </channel>
</rss>
"@

Set-Content -Path $appcastPath -Value $appcastContent
Write-Host "Sample appcast.xml created successfully."

# Provide instructions for server setup
Write-Host "\nTo complete the automatic update setup:"
Write-Host "1. Host the 'update-server' directory on a web server accessible at $updateServerUrl"
Write-Host "2. Add the NetSparkleUpdater.UI.WPF NuGet package to your project"
Write-Host "3. Integrate the UpdateService class into your application"
Write-Host "4. Update the appcast.xml file whenever you release a new version"

Write-Host "\nFor more information on setting up a proper update server, refer to:"
Write-Host "- NetSparkle documentation: https://github.com/NetSparkleUpdater/NetSparkle"
Write-Host "- Squirrel.Windows documentation: https://github.com/Squirrel/Squirrel.Windows"