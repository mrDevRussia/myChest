@echo off
echo ===== ArcSentinel Antivirus =====
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

:: Check if requirements are installed
if not exist "%~dp0venv" (
    echo Setting up virtual environment...
    python -m venv "%~dp0venv"
    call "%~dp0venv\Scripts\activate.bat"
    echo Installing requirements...
    pip install -r "%~dp0requirements.txt"
) else (
    call "%~dp0venv\Scripts\activate.bat"
)

:: Run the application
echo Starting ArcSentinel...
echo.
python "%~dp0ArcSentinel.py"

:: Deactivate virtual environment
call "%~dp0venv\Scripts\deactivate.bat"