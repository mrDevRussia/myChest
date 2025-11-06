# JET IDE Packaging Guide

This document provides detailed instructions for packaging the JET IDE application into a self-contained executable and creating professional installers for distribution.

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Quick Start](#quick-start)
4. [Step-by-Step Guide](#step-by-step-guide)
   - [Converting SVG Icon to ICO](#converting-svg-icon-to-ico)
   - [Building and Publishing](#building-and-publishing)
   - [Compressing the Executable](#compressing-the-executable)
   - [Creating an Installer](#creating-an-installer)
   - [Setting Up Automatic Updates](#setting-up-automatic-updates)
   - [Verifying the Package](#verifying-the-package)
   - [Cleaning Up](#cleaning-up)
5. [Troubleshooting](#troubleshooting)
6. [Advanced Configuration](#advanced-configuration)

## Overview

JET IDE can be packaged as a self-contained executable that includes all necessary dependencies, including the .NET runtime. This allows users to run the application without installing .NET separately. Additionally, you can create professional installers for easy distribution and setup.

## Prerequisites

Before packaging JET IDE, ensure you have the following installed:

- **Required**:
  - Windows 10 or later
  - .NET 6.0 SDK or later
  - PowerShell 5.1 or later

- **Optional (but recommended)**:
  - ImageMagick (for icon conversion)
  - UPX (for executable compression)
  - Inno Setup or NSIS (for installer creation)

## Quick Start

For a guided packaging experience, run the master script:

```powershell
.\build-and-package.ps1
```

This interactive script will guide you through the entire process, from icon conversion to installer creation.

## Step-by-Step Guide

### Converting SVG Icon to ICO

The application icon needs to be in ICO format for Windows applications. If you have an SVG icon, you can convert it using the provided script:

```powershell
.\convert-icon.ps1
```

This script requires ImageMagick to be installed. If you don't have ImageMagick, you can:

1. Install it from https://imagemagick.org/script/download.php
2. Use an online converter service
3. Create the ICO file manually using a graphics editor

The ICO file should be placed at `JET.App\Resources\Icons\jet-icon.ico`.

### Building and Publishing

To build and publish JET IDE as a self-contained executable:

```powershell
.\package-app.ps1
```

This script uses the `dotnet publish` command with the following parameters:

- `-c Release`: Build in Release configuration for optimization
- `-r win-x64`: Target Windows 64-bit
- `-p:PublishSingleFile=true`: Package as a single EXE
- `-p:PublishTrimmed=true`: Remove unused libraries
- `-p:PublishReadyToRun=true`: Pre-compile for faster startup
- `--self-contained true`: Include .NET runtime

The output will be in the `publish` directory.

### Compressing the Executable

To reduce the size of the executable, you can compress it using UPX:

```powershell
.\compress-exe.ps1
```

This script requires UPX to be installed. If you don't have UPX, you can download it from https://github.com/upx/upx/releases.

Compression can reduce the executable size by 30-50% without affecting functionality.

### Creating an Installer

JET IDE provides two options for creating installers:

#### Option 1: Inno Setup (Recommended for most users)

```powershell
.\create-installer.ps1
```

This script requires Inno Setup to be installed. If you don't have Inno Setup, you can download it from https://jrsoftware.org/isinfo.php.

#### Option 2: NSIS (More customizable)

```powershell
.\create-nsis-installer.ps1
```

This script requires NSIS to be installed. If you don't have NSIS, you can download it from https://nsis.sourceforge.io/Download.

Both installers will be created in the `installer` directory.

### Setting Up Automatic Updates

To enable automatic updates for JET IDE:

```powershell
.\setup-auto-updates.ps1
```

This script creates the necessary configuration files and provides sample code for implementing automatic updates using NetSparkle or Squirrel.Windows.

### Verifying the Package

Before distributing your packaged application, you should verify that everything is working correctly:

```powershell
.\verify-package.ps1
```

This script performs the following checks:
- Verifies the existence and integrity of the executable
- Checks the size and dependencies of the package
- Validates the installers
- Provides recommendations for testing

Running this verification step helps ensure that your distribution package is complete and ready for users.

### Cleaning Up

After you've successfully packaged and verified your application, you may want to clean up temporary files and build artifacts:

```powershell
.\cleanup.ps1
```

This interactive script allows you to choose what to clean up:
1. Temporary build files only (preserves final outputs)
2. All build artifacts (including published executable and installer)
3. Everything (complete cleanup, including all scripts and outputs)
4. Custom cleanup (select specific items to clean up)

Regular cleanup helps maintain a tidy workspace and reduces disk space usage.

## Troubleshooting

### Common Issues

1. **Missing .NET SDK**
   - Error: `dotnet command not found`
   - Solution: Install .NET 6.0 SDK or later from https://dotnet.microsoft.com/download

2. **Icon Conversion Fails**
   - Error: `magick command not found`
   - Solution: Install ImageMagick or use an alternative method to create the ICO file

3. **Large Executable Size**
   - Issue: The published executable is too large (>100MB)
   - Solution: Use the compression script or adjust trimming options in the publish command

4. **Installer Creation Fails**
   - Error: `ISCC.exe not found` or `makensis.exe not found`
   - Solution: Install Inno Setup or NSIS, or adjust the path in the script

## Advanced Configuration

### Customizing the Publish Process

To customize the publish process, edit the `package-app.ps1` script. You can adjust the following parameters:

- **Target Runtime**: Change `-r win-x64` to target different platforms
- **Trimming Options**: Add specific assemblies to include or exclude from trimming
- **Output Path**: Change the output directory

### Customizing the Installer

To customize the installer, edit the `create-installer.ps1` or `create-nsis-installer.ps1` script. You can adjust:

- **Application Information**: Name, version, publisher
- **Installation Directory**: Default installation location
- **Shortcuts**: Start menu and desktop shortcuts
- **Additional Files**: Include additional files or documentation
- **Custom Pages**: Add custom pages to the installer wizard

### Implementing Automatic Updates

The `setup-auto-updates.ps1` script provides a basic implementation of automatic updates. For a production environment, you should:

1. Set up a proper update server
2. Implement version checking in your application
3. Create a secure update process
4. Test the update process thoroughly

Refer to the NetSparkle or Squirrel.Windows documentation for detailed implementation guidelines.