# ArcSentinel Antivirus Software

ArcSentinel is a comprehensive antivirus solution built with Python, offering real-time protection, file scanning, quarantine management, and system health monitoring in a modern, user-friendly interface.

![ArcSentinel Logo](icon.svg)

## Features

- **Real-time Protection**: Monitors file system changes to detect threats as they appear
- **Multiple Scan Types**: Quick, Full, and Custom scanning options
- **Threat Detection**: Uses signature-based and heuristic analysis to identify malware
- **Quarantine Management**: Safely isolate and manage detected threats
- **System Health Monitoring**: Track CPU, memory, and disk usage
- **Modern UI**: Clean, intuitive interface with dark theme
- **System Tray Integration**: Runs in the background with quick access to common functions

## Installation

### Prerequisites

- Python 3.8 or higher
- Required Python packages (see requirements.txt)

### Setup

1. Clone or download this repository
2. Install the required dependencies:

```bash
pip install -r requirements.txt
```

3. Run the application:

```bash
python ArcSentinel.py
```

### Building Executable

To create a standalone executable:

```bash
pyinstaller --onefile --windowed --icon=icon.ico ArcSentinel.py
```

## Usage

### Main Dashboard

The dashboard provides an overview of your system's protection status, including:
- Protection status indicators
- Last scan information
- Threat statistics
- Quick access to common functions

### Scanning

- **Quick Scan**: Checks common locations for malware
- **Full Scan**: Comprehensive scan of the entire system
- **Custom Scan**: Select specific folders or files to scan

### Quarantine Management

The quarantine tab allows you to:
- View quarantined files
- Restore files that were incorrectly flagged
- Permanently delete threats

### Settings

Configure ArcSentinel according to your needs:
- Enable/disable real-time protection
- Configure scan options (archives, heuristic analysis)
- Set startup behavior
- Update virus signatures

## Development

### Architecture

ArcSentinel is built with a modular architecture:
- **Core Engine**: Handles scanning, detection, and file operations
- **Real-time Monitor**: Watches for file system changes
- **UI Layer**: PyQt5-based user interface
- **Settings Manager**: Handles configuration persistence

### Adding Custom Signatures

You can add custom virus signatures by modifying the `signatures.json` file in the application data directory.

## Disclaimer

ArcSentinel is provided as-is for educational and demonstration purposes. While it implements real antivirus techniques, it is not intended to replace commercial security solutions in production environments.

## License

This project is licensed under the MIT License - see the LICENSE file for details.