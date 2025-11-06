@echo off
echo ===================================
echo       Building JET IDE
echo ===================================
echo.

echo Step 1: Building self-contained JET.exe...
echo.

dotnet publish JET.App\JET.App.csproj -c Release --self-contained true -r win-x64 -p:PublishSingleFile=true -p:IncludeNativeLibrariesForSelfExtract=true

if %ERRORLEVEL% NEQ 0 (
    echo Error: Failed to build JET.exe
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo Step 2: Creating installer...
echo.

if exist "JET-IDE-Setup.exe" del "JET-IDE-Setup.exe"

where /q makensis
if %ERRORLEVEL% NEQ 0 (
    echo Warning: NSIS not found in PATH. Installer cannot be created.
    echo Please install NSIS from https://nsis.sourceforge.io/Download
    echo.
    echo The self-contained JET.exe has been built successfully and can be found at:
    echo %CD%\JET.App\bin\Release\net6.0-windows\win-x64\publish\JET.exe
    pause
    exit /b 0
)

makensis JET-Installer.nsi

if %ERRORLEVEL% NEQ 0 (
    echo Error: Failed to create installer
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo ===================================
echo       Build Complete!
echo ===================================
echo.
echo JET IDE has been successfully built as a self-contained application.
echo.
echo The installer has been created: JET-IDE-Setup.exe
echo.
echo You can now distribute this installer to users, and they will not need
echo to install .NET 6.0 separately as all dependencies are included.
echo.

pause