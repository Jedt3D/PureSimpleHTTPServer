; WindowsService.pbi — Windows Service integration for PureSimpleHTTPServer
; Include with: XIncludeFile "WindowsService.pbi"
;
; Provides Windows Service functionality:
;   - InstallService()     : Install as Windows service
;   - UninstallService()   : Remove Windows service
;   - RunAsService()       : Execute as Windows service
;   - LogToEventLog()      : Write to Windows Event Log
;
; Dependencies:
;   - Global.pbi (for global configuration access)
;   - Windows Service API (advapi32.lib)
;
; Usage:
;   1. Include in main.pb: XIncludeFile "WindowsService.pbi"
;   2. Add CLI flags: --install, --uninstall, --service
;   3. Call RunAsService() when --service flag is detected
;
; Platform: Windows only (stubbed out on other platforms)

EnableExplicit

; ============================================================================
; Windows Service Constants
; ============================================================================
CompilerIf #PB_Compiler_OS = #PB_OS_Windows

  ; Service types
  #SERVICE_WIN32_OWN_PROCESS = $10
  #SERVICE_WIN32_SHARE_PROCESS = $20

  ; Service start types
  #SERVICE_BOOT_START   = $0
  #SERVICE_SYSTEM_START = $1
  #SERVICE_AUTO_START   = $2
  #SERVICE_DEMAND_START = $3
  #SERVICE_DISABLED     = $4

  ; Service error control
  #SERVICE_ERROR_IGNORE   = $0
  #SERVICE_ERROR_NORMAL   = $1
  #SERVICE_ERROR_SEVERE   = $2
  #SERVICE_ERROR_CRITICAL = $3

  ; Service status codes
  #SERVICE_STOPPED        = $1
  #SERVICE_START_PENDING  = $2
  #SERVICE_STOP_PENDING   = $3
  #SERVICE_RUNNING        = $4
  #SERVICE_CONTINUE_PENDING = $5
  #SERVICE_PAUSE_PENDING  = $6
  #SERVICE_PAUSED         = $7

  ; Service control codes
  #SERVICE_CONTROL_STOP     = $1
  #SERVICE_CONTROL_PAUSE    = $2
  #SERVICE_CONTROL_CONTINUE = $3
  #SERVICE_CONTROL_INTERROGATE = $4
  #SERVICE_CONTROL_SHUTDOWN = $5
  #SERVICE_CONTROL_PARAMCHANGE = $6
  #SERVICE_CONTROL_NETBINDADD = $7
  #SERVICE_CONTROL_NETBINDREMOVE = $8
  #SERVICE_CONTROL_NETBINDENABLE = $9
  #SERVICE_CONTROL_NETBINDDISABLE = $A
  #SERVICE_CONTROL_DEVICEEVENT = $B
  #SERVICE_CONTROL_HARDWAREPROFILECHANGE = $C
  #SERVICE_CONTROL_POWEREVENT = $D
  #SERVICE_CONTROL_SESSIONCHANGE = $E

  ; Service controls accepted
  #SERVICE_ACCEPT_STOP                  = $1
  #SERVICE_ACCEPT_PAUSE_CONTINUE        = $2
  #SERVICE_ACCEPT_SHUTDOWN             = $4
  #SERVICE_ACCEPT_PARAMCHANGE          = $8
  #SERVICE_ACCEPT_NETBINDCHANGE        = $10
  #SERVICE_ACCEPT_HARDWAREPROFILECHANGE = $20
  #SERVICE_ACCEPT_POWEREVENT           = $40
  #SERVICE_ACCEPT_SESSIONCHANGE        = $80
  #SERVICE_ACCEPT_PRESHUTDOWN          = $100

  ; Service access rights
  #SERVICE_ALL_ACCESS           = $F01FF
  #SERVICE_CHANGE_CONFIG        = $2
  #SERVICE_ENUMERATE_DEPENDENTS = $8
  #SERVICE_INTERROGATE          = $80
  #SERVICE_PAUSE_CONTINUE       = $40
  #SERVICE_QUERY_CONFIG         = $1
  #SERVICE_QUERY_STATUS         = $4
  #SERVICE_START                = $10
  #SERVICE_STOP                 = $20
  #USER_OBJECT_NAME             = $3
  #USER_OBJECT_TYPE             = $5

  ; Service Manager access rights (PureBasic provides these)
  ; #SC_MANAGER_CONNECT            = $1
  ; #SC_MANAGER_CREATE_SERVICE     = $2
  ; #SC_MANAGER_ENUMERATE_SERVICE  = $4
  ; #SC_MANAGER_LOCK               = $8
  ; #SC_MANAGER_QUERY_LOCK_STATUS  = $10
  ; #SC_MANAGER_MODIFY_BOOT_CONFIG = $20
  ; #SC_MANAGER_ALL_ACCESS         = $F003F

CompilerEndIf

; ============================================================================
; Service Status Structure (PureBasic provides this)
; ============================================================================
CompilerIf #PB_Compiler_OS = #PB_OS_Windows

  ; Structure SERVICE_STATUS
  ;   dwServiceType.l
  ;   dwCurrentState.l
  ;   dwControlsAccepted.l
  ;   dwWin32ExitCode.l
  ;   dwServiceSpecificExitCode.l
  ;   dwCheckPoint.l
  ;   dwWaitHint.l
  ; EndStructure

CompilerEndIf

; ============================================================================
; Global Service Variables
; ============================================================================
CompilerIf #PB_Compiler_OS = #PB_OS_Windows

  Global g_hServiceStatus.l
  Global g_ServiceStatus.SERVICE_STATUS
  Global g_ServiceStopRequested.i = #False

CompilerEndIf

; ============================================================================
; External Service Procedures (defined in TcpServer.pbi)
; ============================================================================

; These procedures are defined in TcpServer.pbi:
;   - StopServer() : Stops the TCP server
;   - StartServer(port.i) : Starts the TCP server on specified port

; Forward declaration for LogToEventLog (defined later in this file)
Declare LogToEventLog(eventID.i, eventType.i, message.s)

; ============================================================================
; Windows Service API Imports
; ============================================================================
CompilerIf #PB_Compiler_OS = #PB_OS_Windows

  ImportC "advapi32.lib"
    ; Service Control Manager functions
    OpenSCManagerA.l(lpMachineName.p-ascii, lpDatabaseName.p-ascii, dwDesiredAccess.l)
    CloseServiceHandle.l(hSCObject.l)

    ; Service installation functions
    CreateServiceA.l(hSCManager.l, lpServiceName.p-ascii, lpDisplayName.p-ascii, dwDesiredAccess.l, dwServiceType.l, dwStartType.l, dwErrorControl.l, lpBinaryPathName.p-ascii, lpLoadOrderGroup.p-ascii, lpdwTagId.l, lpDependencies.p-ascii, lpServiceStartName.p-ascii, lpPassword.p-ascii)
    OpenServiceA.l(hSCManager.l, lpServiceName.p-ascii, dwDesiredAccess.l)
    DeleteService.l(hService.l)

    ; Service control functions
    StartServiceA.l(hService.l, dwNumServiceArgs.l, lpServiceArgVectors.l)
    ControlService.l(hService.l, dwControlCode.l, *lpServiceStatus.SERVICE_STATUS)
    QueryServiceStatus.l(hService.l, *lpServiceStatus.SERVICE_STATUS)

    ; Service registration
    RegisterServiceCtrlHandlerA.l(lpServiceName.p-ascii, lpHandlerProc.l)
    SetServiceStatus.l(hServiceStatus.l, *lpServiceStatus.SERVICE_STATUS)

    ; Event Log functions
    RegisterEventSourceA.l(lpUNCServerName.p-ascii, lpSourceName.p-ascii)
    ReportEventA.l(hEventLog.l, wType.l, wCategory.l, dwEventID.l, lpUserSid.l, wNumStrings.l, dwDataSize.l, *lpStrings, *lpRawData)
    DeregisterEventSource.l(hEventLog.l)
    ; Service dispatcher (for RunAsService)
    StartServiceCtrlDispatcherA.l(*lpServiceTable)
  EndImport

CompilerEndIf

; ============================================================================
; Service Installation
; ============================================================================

CompilerIf #PB_Compiler_OS = #PB_OS_Windows

  Procedure.i InstallService(serviceName.s, displayName.s, binaryPath.s, description.s)
    ; Install PureSimpleHTTPServer as a Windows service
    ;
    ; Parameters:
    ;   serviceName  - Internal service name (e.g., "PureSimpleHTTPServer")
    ;   displayName  - Display name in Services MMC
    ;   binaryPath   - Full path to executable
    ;   description  - Service description
    ;
    ; Returns:
    ;   #True on success, #False on failure

    Protected hSCM.l
    Protected hService.l
    Protected result.i = #False

    ; Open Service Control Manager
    hSCM = OpenSCManagerA(#Null$, #Null$, #SC_MANAGER_CREATE_SERVICE)
    If hSCM = 0
      ProcedureReturn #False
    EndIf

    ; Create service
    hService = CreateServiceA(hSCM,
                              serviceName,
                              displayName,
                              #SERVICE_ALL_ACCESS,
                              #SERVICE_WIN32_OWN_PROCESS,
                              #SERVICE_DEMAND_START,
                              #SERVICE_ERROR_NORMAL,
                              binaryPath,
                              #Null$,    ; Load order group
                              #Null,     ; Tag ID (pointer to DWORD)
                              #Null$,    ; Dependencies
                              #Null$,    ; Service start name (LocalSystem)
                              #Null$)    ; Password

    If hService
      ; Set service description (requires additional API call, simplified here)
      result = #True
      CloseServiceHandle(hService)
    EndIf

    CloseServiceHandle(hSCM)
    ProcedureReturn result
  EndProcedure

CompilerEndIf

; ============================================================================
; Service Uninstallation
; ============================================================================

CompilerIf #PB_Compiler_OS = #PB_OS_Windows

  Procedure.i UninstallService(serviceName.s)
    ; Remove PureSimpleHTTPServer Windows service
    ;
    ; Parameters:
    ;   serviceName  - Service name to uninstall
    ;
    ; Returns:
    ;   #True on success, #False on failure

    Protected hSCM.l
    Protected hService.l
    Protected result.i = #False

    ; Open Service Control Manager
    hSCM = OpenSCManagerA(#Null$, #Null$, #SC_MANAGER_CONNECT)
    If hSCM = 0
      ProcedureReturn #False
    EndIf

    ; Open service
    hService = OpenServiceA(hSCM, serviceName, #SERVICE_ALL_ACCESS)
    If hService
      ; Stop service if running
      Protected status.SERVICE_STATUS
      If QueryServiceStatus(hService, @status)
        If status\dwCurrentState = #SERVICE_RUNNING
          ControlService(hService, #SERVICE_CONTROL_STOP, @status)
        EndIf
      EndIf

      ; Delete service
      If DeleteService(hService)
        result = #True
      EndIf

      CloseServiceHandle(hService)
    EndIf

    CloseServiceHandle(hSCM)
    ProcedureReturn result
  EndProcedure

CompilerEndIf

; ============================================================================
; Service Control Handler
; ============================================================================

CompilerIf #PB_Compiler_OS = #PB_OS_Windows

  Procedure ServiceCtrlHandler(dwCtrlCode.l)
    ; Handle service control requests from Service Control Manager
    ;
    ; Parameters:
    ;   dwCtrlCode  - Control code (STOP, PAUSE, CONTINUE, SHUTDOWN, etc.)

    Select dwCtrlCode
      Case #SERVICE_CONTROL_STOP, #SERVICE_CONTROL_SHUTDOWN
        ; Update service status to stopping
        g_ServiceStatus\dwCurrentState = #SERVICE_STOP_PENDING
        g_ServiceStatus\dwCheckPoint = 0
        g_ServiceStatus\dwWaitHint = 5000
        SetServiceStatus(g_hServiceStatus, g_ServiceStatus)

        ; Signal server to stop
        g_ServiceStopRequested = #True

        ; Stop the TCP server
        StopServer()

        ; Update service status to stopped
        g_ServiceStatus\dwCurrentState = #SERVICE_STOPPED
        g_ServiceStatus\dwWin32ExitCode = 0
        g_ServiceStatus\dwCheckPoint = 0
        g_ServiceStatus\dwWaitHint = 0
        SetServiceStatus(g_hServiceStatus, g_ServiceStatus)

      Case #SERVICE_CONTROL_INTERROGATE
        ; Service Control Manager requesting current status
        SetServiceStatus(g_hServiceStatus, g_ServiceStatus)

    EndSelect
  EndProcedure

CompilerEndIf

; ============================================================================
; Service Main Procedure
; ============================================================================

CompilerIf #PB_Compiler_OS = #PB_OS_Windows

  Procedure ServiceMain(dwArgc.l, *lpszArgv)
    ; Service main entry point called by Service Control Manager
    ;
    ; Parameters:
    ;   dwArgc      - Argument count
    ;   *lpszArgv   - Argument vectors

    ; Register service control handler
    g_hServiceStatus = RegisterServiceCtrlHandlerA("PureSimpleHTTPServer", @ServiceCtrlHandler())

    If g_hServiceStatus = 0
      ; Failed to register handler
      ProcedureReturn
    EndIf

    ; Initialize service status
    g_ServiceStatus\dwServiceType = #SERVICE_WIN32_OWN_PROCESS
    g_ServiceStatus\dwCurrentState = #SERVICE_START_PENDING
    g_ServiceStatus\dwControlsAccepted = #SERVICE_ACCEPT_STOP | #SERVICE_ACCEPT_SHUTDOWN
    g_ServiceStatus\dwWin32ExitCode = 0
    g_ServiceStatus\dwServiceSpecificExitCode = 0
    g_ServiceStatus\dwCheckPoint = 0
    g_ServiceStatus\dwWaitHint = 3000

    SetServiceStatus(g_hServiceStatus, g_ServiceStatus)

    ; TODO: Initialize server configuration from registry or config file
    ; For now, use default port 8080
    Protected serverPort.i = 8080

    ; Start the server (this blocks until StopServer is called)
    If StartServer(serverPort)
      ; Server started successfully
      g_ServiceStatus\dwCurrentState = #SERVICE_RUNNING
      g_ServiceStatus\dwCheckPoint = 0
      g_ServiceStatus\dwWaitHint = 0
      SetServiceStatus(g_hServiceStatus, g_ServiceStatus)

      ; Log to event log
      LogToEventLog(1, 4, "PureSimpleHTTPServer service started successfully")
    Else
      ; Failed to start server
      g_ServiceStatus\dwCurrentState = #SERVICE_STOPPED
      g_ServiceStatus\dwWin32ExitCode = 1
      SetServiceStatus(g_hServiceStatus, g_ServiceStatus)

      LogToEventLog(2, 1, "PureSimpleHTTPServer service failed to start")
    EndIf
  EndProcedure

CompilerEndIf

; ============================================================================
; Run as Service
; ============================================================================

CompilerIf #PB_Compiler_OS = #PB_OS_Windows

  Procedure RunAsService()
    ; Connect PureSimpleHTTPServer to the Service Control Manager
    ; This procedure never returns (until service is stopped)

    ; Service table entry structure (PureBasic provides this)
    ; Structure SERVICE_TABLE_ENTRY
    ;   *lpServiceName
    ;   *lpServiceProc
    ; EndStructure

    ; Define service table
    Dim serviceTable.SERVICE_TABLE_ENTRY(1)

    serviceTable(0)\lpServiceName = @"PureSimpleHTTPServer"
    serviceTable(0)\lpServiceProc = @ServiceMain()
    serviceTable(1)\lpServiceName = #Null
    serviceTable(1)\lpServiceProc = #Null

    ; Start service control dispatcher
    If Not StartServiceCtrlDispatcherA(@serviceTable())
      ; Failed to connect to Service Control Manager
      LogToEventLog(3, 1, "Failed to connect to Service Control Manager")
    EndIf
  EndProcedure

CompilerEndIf

; ============================================================================
; Event Log Integration
; ============================================================================

CompilerIf #PB_Compiler_OS = #PB_OS_Windows

  Procedure LogToEventLog(eventID.i, eventType.i, message.s)
    ; Write an event to the Windows Event Log
    ;
    ; Parameters:
    ;   eventID   - Event identifier (application-specific)
    ;   eventType - Event type: 1=ERROR, 2=WARNING, 4=INFORMATION
    ;   message   - Event message text
    ;
    ; Event ID Guidelines:
    ;   1 = Service started
    ;   2 = Service failed to start
    ;   3 = Service control manager error
    ;   4 = Service stopped

    Protected hEventLog.l
    Protected *msgPtr

    hEventLog = RegisterEventSourceA(#Null$, "PureSimpleHTTPServer")
    If hEventLog
      *msgPtr = @message
      ReportEventA(hEventLog, eventType, 0, eventID, #Null, 1, 0, @*msgPtr, #Null)
      DeregisterEventSource(hEventLog)
    EndIf
  EndProcedure

CompilerEndIf

; ============================================================================
; Platform-Specific Stubs (non-Windows platforms)
; ============================================================================
CompilerIf #PB_Compiler_OS <> #PB_OS_Windows

  Procedure.i InstallService(serviceName.s, displayName.s, binaryPath.s, description.s)
    ; Stub implementation for non-Windows platforms
    ProcedureReturn #False
  EndProcedure

  Procedure.i UninstallService(serviceName.s)
    ; Stub implementation for non-Windows platforms
    ProcedureReturn #False
  EndProcedure

  Procedure RunAsService()
    ; Stub implementation for non-Windows platforms
    ; Does nothing on non-Windows platforms
  EndProcedure

  Procedure LogToEventLog(eventID.i, eventType.i, message.s)
    ; Stub implementation for non-Windows platforms
    ; Does nothing on non-Windows platforms
  EndProcedure

CompilerEndIf
