# JET — The Next-Level AI-Powered Independent IDE

## Overview

JET is a revolutionary developer experience that creates a fully independent, AI-powered IDE surpassing existing solutions like VS Code in intelligence, performance, and usability. Designed primarily for Windows, JET combines cutting-edge local AI assistance with seamless real-time collaboration, robust project management, and superior code analysis, all integrated into a native desktop application with a clean, modern, and visually stunning user interface.

## Key Features

- **Multi-Language Support**: Native support for a wide range of popular programming languages
- **Superior AI Integration**: Advanced local AI models for faster, more private, and context-aware code suggestions
- **Optimized Native Performance**: Built with C# and WPF for snappier responsiveness and lower resource consumption
- **Full Offline Capability**: Works fully offline with all AI features embedded locally
- **Beautiful and Intuitive UI**: Clean, elegant, and customizable interface that enhances user focus
- **Enhanced Collaboration Tools**: Built-in live collaboration with real-time editing and communication
- **Modular and Scalable Architecture**: Enables continuous expansion without sacrificing stability or speed

## Technologies Used

- **C# with .NET (WPF)**: Primary programming language and framework for the native Windows desktop application
- **WPF (Windows Presentation Foundation)**: For designing a modern, customizable UI
- **AvalonEdit**: Provides syntax highlighting, code editing, and auto-completion features
- **Local AI Integration**: AI modules powered by lightweight local AI frameworks
- **LibGit2Sharp**: For Git version control features
- **SignalR**: For real-time collaboration features
- **SQLite**: For local data storage

## Project Structure

```
JET/
├── JET.App/                  # Main application project
│   ├── Models/               # Data models
│   ├── ViewModels/           # MVVM view models
│   ├── Views/                # XAML views
│   ├── Services/             # Application services
│   │   ├── AIService.cs      # AI integration service
│   │   ├── GitService.cs     # Git integration service
│   │   └── CollaborationService.cs # Real-time collaboration service
│   ├── Resources/            # Application resources
│   │   ├── Icons/            # Application icons
│   │   └── Themes/           # UI themes
│   └── Utilities/            # Helper classes and utilities
└── JET.sln                   # Solution file
```

## Getting Started

### Prerequisites

- Windows 10 or later
- .NET 6.0 SDK or later
- Visual Studio 2022 or later (recommended for development)

### Building the Project

1. Clone the repository
2. Open `JET.sln` in Visual Studio
3. Build the solution
4. Run the application

### Packaging the Application

JET IDE includes scripts for packaging the application as a self-contained executable and creating installers:

1. **Quick Packaging**: Run `build-and-package.ps1` for an interactive packaging experience
2. **Manual Steps**:
   - Convert SVG icon to ICO: `convert-icon.ps1` (requires ImageMagick)
   - Create self-contained executable: `package-app.ps1`
   - Compress executable (optional): `compress-exe.ps1` (requires UPX)
   - Create installer: `create-installer.ps1` (requires Inno Setup) or `create-nsis-installer.ps1` (requires NSIS)
   - Set up automatic updates: `setup-auto-updates.ps1`

#### Requirements for Packaging

- .NET 6.0 SDK or later
- PowerShell 5.1 or later
- For icon conversion: ImageMagick
- For compression: UPX
- For installers: Inno Setup or NSIS

## Development Roadmap

- **Phase 1**: Core IDE functionality and UI
- **Phase 2**: Language support and code editing features
- **Phase 3**: Local AI integration
- **Phase 4**: Git integration
- **Phase 5**: Real-time collaboration
- **Phase 6**: Performance optimization and polish

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.