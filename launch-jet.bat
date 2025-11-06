@echo off
echo Launching JET IDE...

set JET_EXE="%~dp0JET.App\bin\Release\net6.0-windows\JET.exe"

if exist %JET_EXE% (
    start "" %JET_EXE%
    echo JET IDE launched successfully.
) else (
    echo ERROR: JET.exe not found at %JET_EXE%
    echo Please build the application first using: dotnet build JET.App\JET.App.csproj -c Release
)

pause