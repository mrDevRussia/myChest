# JET IDE Installer Information

## All-in-One Executable Installer

The `JET-IDE-Installer.exe` is a complete, self-contained installer that:

1. Contains all application files in a single executable
2. Installs JET IDE to your local application data folder
3. Creates desktop and start menu shortcuts
4. Launches the application automatically after installation
5. Works reliably on all modern Windows systems

To use the all-in-one installer:

1. Double-click on `JET-IDE-Installer.exe`
2. Follow the on-screen instructions
3. The application will start automatically after installation

## Known Issues with Previous Installers

The older `JET-IDE-Setup.exe` installer created with IExpress may encounter the following error on some systems:

```
Error creating process <Command.com /c C:\Users\...\install.bat>, Reason: The system cannot find the file specified.
```

This error occurs because IExpress attempts to use the legacy Command.com processor which may not be available on modern Windows systems. The new all-in-one installer resolves this issue.

## Alternative Installation Methods

If you prefer, you can also use:

- `simple-installer.bat` - A basic installer with similar functionality
- Manual installation - Copy the files yourself as described in the INSTALL.md file

## Troubleshooting

If you encounter any issues with the installation:

1. Ensure you have sufficient permissions to write to the installation directory
2. Try running the installer as administrator
3. Check that no antivirus software is blocking the installation
4. Verify that the JET.App directory contains all necessary files

## Support

For additional assistance, please contact the JET IDE development team.