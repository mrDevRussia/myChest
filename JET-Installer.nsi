# JET IDE NSIS Installer Script

# Define constants
!define PRODUCT_NAME "JET IDE"
!define PRODUCT_VERSION "1.0.0"
!define PRODUCT_PUBLISHER "JET Team - IDS"
!define PRODUCT_WEB_SITE "https://jetide.com"
!define PRODUCT_DIR_REGKEY "Software\\Microsoft\\Windows\\CurrentVersion\\App Paths\\JET.exe"
!define PRODUCT_UNINST_KEY "Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\${PRODUCT_NAME}"
!define PRODUCT_UNINST_ROOT_KEY "HKLM"
!define PRODUCT_DESCRIPTION "JET IDE - The Next-Level AI-Powered IDE"

# Include modern UI
!include "MUI2.nsh"

# Set compression
SetCompressor lzma

# Set metadata
Name "${PRODUCT_NAME} ${PRODUCT_VERSION}"
OutFile "JET-IDE-Setup.exe"
InstallDir "$PROGRAMFILES\\JET IDE"
InstallDirRegKey HKLM "${PRODUCT_DIR_REGKEY}" ""
ShowInstDetails show
ShowUnInstDetails show

# MUI Settings
!define MUI_ABORTWARNING
!define MUI_ICON "JET.App\\Resources\\Icons\\jet-icon.ico"
!define MUI_UNICON "JET.App\\Resources\\Icons\\jet-icon.ico"

# Pages
!insertmacro MUI_PAGE_WELCOME
!define MUI_WELCOMEPAGE_TITLE "Welcome to the JET IDE Setup Wizard"
!define MUI_WELCOMEPAGE_TEXT "This wizard will guide you through the installation of JET IDE, a powerful development environment with AI capabilities.\r\n\r\nJET IDE is a complete development environment with all dependencies included. No additional software is required to run it.\r\n\r\nClick Next to continue."

!insertmacro MUI_PAGE_LICENSE "LICENSE"

!define MUI_PAGE_HEADER_TEXT "Installation Options"
!define MUI_PAGE_HEADER_SUBTEXT "Choose the installation options for JET IDE."
!define MUI_COMPONENTSPAGE_TEXT_TOP "Select the components you want to install."
!insertmacro MUI_PAGE_COMPONENTS

!insertmacro MUI_PAGE_DIRECTORY

!define MUI_PAGE_HEADER_TEXT "Ready to Install"
!define MUI_PAGE_HEADER_SUBTEXT "Setup is now ready to begin installing JET IDE on your computer."
!insertmacro MUI_PAGE_INSTFILES

!define MUI_FINISHPAGE_TITLE "JET IDE Installation Complete"
!define MUI_FINISHPAGE_TEXT "JET IDE has been installed on your computer.\r\n\r\nClick Finish to close this wizard."
!define MUI_FINISHPAGE_RUN "$INSTDIR\JET.exe"
!define MUI_FINISHPAGE_RUN_TEXT "Launch JET IDE now"
!define MUI_FINISHPAGE_SHOWREADME "$INSTDIR\README.md"
!define MUI_FINISHPAGE_SHOWREADME_TEXT "View README file"
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_WELCOME
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

# Language
!insertmacro MUI_LANGUAGE "English"

# Components
!define SECTION_CORE 0
!define SECTION_DESKTOP_SHORTCUT 1
!define SECTION_STARTMENU_SHORTCUT 2
!define SECTION_DOCUMENTATION 3

# Installer sections
Section "JET IDE Core Files (required)" SEC_CORE
  SectionIn RO  # Read-only, cannot be deselected
  SetOutPath "$INSTDIR"
  SetOverwrite ifnewer
  
  # Copy self-contained JET.exe and all required files
  File /r "JET.App\bin\Release\net6.0-windows\win-x64\publish\*.*"
SectionEnd

Section "Desktop Shortcut" SEC_DESKTOP
  CreateShortCut "$DESKTOP\\JET IDE.lnk" "$INSTDIR\\JET.exe" "" "$INSTDIR\\JET.exe" 0
SectionEnd

Section "Start Menu Shortcuts" SEC_STARTMENU
  CreateDirectory "$SMPROGRAMS\\JET IDE"
  CreateShortCut "$SMPROGRAMS\\JET IDE\\JET IDE.lnk" "$INSTDIR\\JET.exe" "" "$INSTDIR\\JET.exe" 0
  CreateShortCut "$SMPROGRAMS\\JET IDE\\Uninstall JET IDE.lnk" "$INSTDIR\\uninstall.exe" "" "$INSTDIR\\uninstall.exe" 0
SectionEnd

Section "Documentation" SEC_DOCS
  SetOutPath "$INSTDIR"
  File "README.md"
  File "LICENSE"
  File "INSTALL.md"
  File "PACKAGING.md"
SectionEnd
  
# Register application section
Section -Register
  WriteRegStr HKLM "${PRODUCT_DIR_REGKEY}" "" "$INSTDIR\\JET.exe"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayName" "$(^Name)"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "UninstallString" "$INSTDIR\\uninstall.exe"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayIcon" "$INSTDIR\\JET.exe"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayVersion" "${PRODUCT_VERSION}"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "URLInfoAbout" "${PRODUCT_WEB_SITE}"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "Publisher" "${PRODUCT_PUBLISHER}"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayDesc" "${PRODUCT_DESCRIPTION}"
  WriteRegDWORD ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "NoModify" 1
  WriteRegDWORD ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "NoRepair" 1
  
  # Write uninstaller
  WriteUninstaller "$INSTDIR\\uninstall.exe"
SectionEnd

# Uninstaller section
Section Uninstall
  # Remove shortcuts
  Delete "$SMPROGRAMS\\JET IDE\\JET IDE.lnk"
  Delete "$SMPROGRAMS\\JET IDE\\Uninstall JET IDE.lnk"
  Delete "$DESKTOP\\JET IDE.lnk"
  RMDir "$SMPROGRAMS\\JET IDE"
  
  # Remove files and directories
  RMDir /r "$INSTDIR"
  
  # Remove registry keys
  DeleteRegKey ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}"
  DeleteRegKey HKLM "${PRODUCT_DIR_REGKEY}"
  
  # Display completion message
  MessageBox MB_ICONINFORMATION|MB_OK "JET IDE has been successfully removed from your computer."
  
  SetAutoClose true
SectionEnd

# Section descriptions
!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC_CORE} "Core files required for JET IDE to function. This component cannot be deselected."
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC_DESKTOP} "Creates a shortcut to JET IDE on your desktop for easy access."
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC_STARTMENU} "Creates shortcuts to JET IDE in your Start Menu."
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC_DOCS} "Documentation files including README, LICENSE, and installation guides."
!insertmacro MUI_FUNCTION_DESCRIPTION_END