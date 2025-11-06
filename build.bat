@echo off
echo ===== ArcSentinel Executable Builder =====
echo.

:: Check if Python is installed
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: Python is not installed or not in PATH.
    echo Please install Python 3.8 or higher from https://www.python.org/downloads/
    echo.
    pause
    exit /b 1
)

:: Check if virtual environment exists, create if not
if not exist "%~dp0venv" (
    echo Setting up virtual environment...
    python -m venv "%~dp0venv"
    call "%~dp0venv\Scripts\activate.bat"
    echo Installing requirements...
    pip install -r "%~dp0requirements.txt"
    pip install pyinstaller cairosvg pillow
) else (
    call "%~dp0venv\Scripts\activate.bat"
    echo Ensuring build dependencies are installed...
    pip install pyinstaller cairosvg pillow
)

:: Run the build script
echo.
echo Building executable...
echo.
python "%~dp0build.py"

:: Check if build was successful
if exist "%~dp0dist\ArcSentinel.exe" (
    echo.
    echo Build successful! Executable created at:
    echo %~dp0dist\ArcSentinel.exe
    echo.
    echo You can now distribute this single file to run ArcSentinel.
) else (
    echo.
    echo Build failed. Please check the error messages above.
)

:: Deactivate virtual environment
call "%~dp0venv\Scripts\deactivate.bat"

echo.
pause