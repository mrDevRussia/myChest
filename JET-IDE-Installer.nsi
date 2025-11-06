; JET IDE Installer Script
; Created with NSIS

!include "MUI2.nsh"

; General settings
Name "JET IDE"
OutFile "JET-IDE-Setup.exe"
InstallDir "$LOCALAPPDATA\JET IDE"
InstallDirRegKey HKCU "Software\JET IDE" "Install_Dir"
RequestExecutionLevel user

; Interface settings
!define MUI_ABORTWARNING
!define MUI_ICON "JET.App\Resources\Icons\jet-icon.ico"
!define MUI_UNICON "JET.App\Resources\Icons\jet-icon.ico"

; Pages
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "LICENSE"
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!define MUI_FINISHPAGE_RUN "$INSTDIR\JET.App\bin\Release\net6.0-windows\JET.exe"
!define MUI_FINISHPAGE_RUN_TEXT "Launch JET IDE"
!insertmacro MUI_PAGE_FINISH

; Uninstaller pages
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

; Language
!insertmacro MUI_LANGUAGE "English"

; Installer sections
Section "JET IDE" SecJETIDE
  SetOutPath "$INSTDIR"
  
  ; Copy all files from JET.App directory
  File /r "JET.App\*.*"
  
  ; Copy documentation files
  File "LICENSE"
  File "README.md"
  File "INSTALL.md"
  File "PACKAGING.md"
  File "INSTALLER_README.md"
  
  ; Create desktop shortcut
  CreateShortcut "$DESKTOP\JET IDE.lnk" "$INSTDIR\JET.App\bin\Release\net6.0-windows\JET.exe" "" "$INSTDIR\JET.App\Resources\Icons\jet-icon.ico"
  
  ; Create start menu shortcut
  CreateDirectory "$SMPROGRAMS\JET IDE"
  CreateShortcut "$SMPROGRAMS\JET IDE\JET IDE.lnk" "$INSTDIR\JET.App\bin\Release\net6.0-windows\JET.exe" "" "$INSTDIR\JET.App\Resources\Icons\jet-icon.ico"
  CreateShortcut "$SMPROGRAMS\JET IDE\Uninstall.lnk" "$INSTDIR\uninstall.exe"
  
  ; Write registry keys for uninstaller
  WriteRegStr HKCU "Software\JET IDE" "Install_Dir" $INSTDIR
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\JET IDE" "DisplayName" "JET IDE"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\JET IDE" "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\JET IDE" "DisplayIcon" '"$INSTDIR\JET.App\Resources\Icons\jet-icon.ico"'
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\JET IDE" "Publisher" "JET Team"
  
  ; Create uninstaller
  WriteUninstaller "$INSTDIR\uninstall.exe"
  
SectionEnd

; Uninstaller section
Section "Uninstall"
  ; Remove files and directories
  RMDir /r "$INSTDIR\JET.App"
  Delete "$INSTDIR\LICENSE"
  Delete "$INSTDIR\README.md"
  Delete "$INSTDIR\INSTALL.md"
  Delete "$INSTDIR\PACKAGING.md"
  Delete "$INSTDIR\INSTALLER_README.md"
  Delete "$INSTDIR\uninstall.exe"
  RMDir "$INSTDIR"
  
  ; Remove shortcuts
  Delete "$DESKTOP\JET IDE.lnk"
  Delete "$SMPROGRAMS\JET IDE\JET IDE.lnk"
  Delete "$SMPROGRAMS\JET IDE\Uninstall.lnk"
  RMDir "$SMPROGRAMS\JET IDE"
  
  ; Remove registry keys
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\JET IDE"
  DeleteRegKey HKCU "Software\JET IDE"
  
SectionEnd