; PureSimpleHTTPServer.nsi - NSIS Installer Script
;
; PureBasic HTTP Server - Windows Installer
;
; This script creates a professional Windows installer with:
; - License agreement
; - Installation directory selection
; - Optional service installation
; - Start Menu shortcuts
; - Optional desktop shortcut
; - Automatic uninstaller
; - Silent installation support

!define APP_NAME "PureSimpleHTTPServer"
!define APP_VERSION "1.6.1"
!define APP_PUBLISHER "PureSimpleHTTPServer"
!define APP_URL "https://github.com/woraj/PureSimpleHTTPServer"
!define APP_EXE "PureSimpleHTTPServer.exe"

; Set compressor
SetCompressor lzma

; Modern UI settings
!include "MUI2.nsh"

; General settings
Name "${APP_NAME} ${APP_VERSION}"
OutFile "dist\${APP_NAME}-${APP_VERSION}-windows-setup.exe"
InstallDir "$PROGRAMFILES\${APP_NAME}"
InstallDirRegKey HKLM "Software\${APP_NAME}" "InstallLocation"
RequestExecutionLevel admin

; Variables
Var StartMenuFolder

; Interface Settings
!define MUI_ABORTWARNING
!define MUI_ICON "assets\icon.ico"
!define MUI_UNICON "assets\icon.ico"
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP "installer\header.bmp" ; Optional: 150x57 bitmap
!define MUI_WELCOMEFINISHPAGE_BITMAP "installer\wizard.bmp" ; Optional: 164x314 bitmap

; Pages
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "LICENSE"
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_STARTMENU Application $StartMenuFolder
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_WELCOME
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

; Languages
!insertmacro MUI_LANGUAGE "English"

; Installer Sections
Section "Main Files" SEC01
  SectionIn RO ; Required section

  SetOutPath $INSTDIR

  ; Main executable
  File "dist\${APP_EXE}"

  ; Web root directory with sample file
  File /r "wwwroot"

  ; Documentation
  File "README.txt"
  File "LICENSE.txt"
  File "CHANGELOG.txt"
  File "quickstart.txt"

  ; Store installation directory
  WriteRegStr HKLM "Software\${APP_NAME}" "InstallLocation" $INSTDIR
  WriteRegStr HKLM "Software\${APP_NAME}" "Version" "${APP_VERSION}"

  ; Create uninstaller
  WriteUninstaller "$INSTDIR\Uninstall.exe"

  ; Add to Add/Remove Programs
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "DisplayName" "${APP_NAME}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "DisplayVersion" "${APP_VERSION}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "Publisher" "${APP_PUBLISHER}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "URLInfoAbout" "${APP_URL}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "DisplayIcon" "$INSTDIR\${APP_EXE}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "UninstallString" "$INSTDIR\Uninstall.exe"
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "NoRepair" 1

SectionEnd

Section "Windows Service" SEC02
  ; Optional: Install as Windows service
  ExecWait '"$INSTDIR\${APP_EXE}" --install' $0
  IfErrors skip_service
    DetailPrint "Service installed successfully"
    goto service_done
  skip_service:
    DetailPrint "WARNING: Service installation failed"
  service_done:
SectionEnd

Section "Start Menu Shortcuts" SEC03
  ; Create Start Menu shortcuts
  !insertmacro MUI_STARTMENU_WRITE_BEGIN Application

    CreateDirectory "$SMPROGRAMS\$StartMenuFolder"
    CreateShortcut "$SMPROGRAMS\$StartMenuFolder\${APP_NAME}.lnk" "$INSTDIR\${APP_EXE}" "" "$INSTDIR\${APP_EXE}" 0
    CreateShortcut "$SMPROGRAMS\$StartMenuFolder\Uninstall ${APP_NAME}.lnk" "$INSTDIR\Uninstall.exe"

    ; Create documentation shortcuts
    IfFileExists "$INSTDIR\README.txt" 0 +2
      CreateShortcut "$SMPROGRAMS\$StartMenuFolder\README.lnk" "$INSTDIR\README.txt"
    IfFileExists "$INSTDIR\quickstart.txt" 0 +2
      CreateShortcut "$SMPROGRAMS\$StartMenuFolder\Quick Start Guide.lnk" "$INSTDIR\quickstart.txt"

  !insertmacro MUI_STARTMENU_WRITE_END
SectionEnd

Section "Desktop Shortcut" SEC04
  ; Optional: Create desktop shortcut
  CreateShortcut "$DESKTOP\${APP_NAME}.lnk" "$INSTDIR\${APP_EXE}" "" "$INSTDIR\${APP_EXE}" 0
SectionEnd

; Section Descriptions
LangString DESC_SEC01 ${LANG_ENGLISH} "Install main application files and documentation."
LangString DESC_SEC02 ${LANG_ENGLISH} "Install PureSimpleHTTPServer as a Windows service (requires administrator privileges)."
LangString DESC_SEC03 ${LANG_ENGLISH} "Create shortcuts in the Start Menu."
LangString DESC_SEC04 ${LANG_ENGLISH} "Create a shortcut on the desktop."

!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC01} $(DESC_SEC01)
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC02} $(DESC_SEC02)
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC03} $(DESC_SEC03)
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC04} $(DESC_SEC04)
!insertmacro MUI_FUNCTION_DESCRIPTION_END

; Uninstaller Section
Section "Uninstall"
  ; Stop and uninstall service if running
  ExecWait '"$INSTDIR\${APP_EXE}" --uninstall'

  ; Remove files
  Delete $INSTDIR\${APP_EXE}
  Delete $INSTDIR\Uninstall.exe
  Delete $INSTDIR\README.txt
  Delete $INSTDIR\LICENSE.txt
  Delete $INSTDIR\CHANGELOG.txt
  Delete $INSTDIR\quickstart.txt

  ; Remove wwwroot directory (preserve user files by asking)
  MessageBox MB_YESNO "Remove web root directory and all files?$\n(This will delete all files in $INSTDIR\wwwroot)" IDNO skip_wwwroot
    RMDir /r "$INSTDIR\wwwroot"
  skip_wwwroot:

  ; Remove shortcuts
  !insertmacro MUI_STARTMENU_GETFOLDER Application $StartMenuFolder
  Delete "$SMPROGRAMS\$StartMenuFolder\${APP_NAME}.lnk"
  Delete "$SMPROGRAMS\$StartMenuFolder\Uninstall ${APP_NAME}.lnk"
  Delete "$SMPROGRAMS\$StartMenuFolder\README.lnk"
  Delete "$SMPROGRAMS\$StartMenuFolder\Quick Start Guide.lnk"
  RMDir "$SMPROGRAMS\$StartMenuFolder"

  Delete "$DESKTOP\${APP_NAME}.lnk"

  ; Remove registry keys
  DeleteRegKey HKLM "Software\${APP_NAME}"
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}"

  ; Remove installation directory (if empty)
  RMDir $INSTDIR

SectionEnd

; Silent Installation Support
Function .onInit
  ; Check for silent mode
  IfSilent silent+2
    Return

  silent:
  ; Default selections for silent install
  ; Main files, Start Menu, Service, no desktop shortcut
  SetSilent silent
FunctionEnd

; Installation Callbacks
Function .onInstSuccess
  ; Display success message
  IfSilent skip_message
    MessageBox MB_OK "PureSimpleHTTPServer has been installed successfully!$\n$\nYou can start the server from the Start Menu or desktop shortcut."
  skip_message:
FunctionEnd

; Uninstallation Callbacks
Function un.onInit
  ; Confirm uninstallation
  MessageBox MB_YESNO "Are you sure you want to completely remove $(^Name) and all of its components?" IDYES +2
    Abort
FunctionEnd
