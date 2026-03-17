; main.pb — PureSimpleHTTPServer entry point
; Phase F-1: Apache Combined Log Format, error log, log level filtering
; Phase F-3: Daily rotation thread, PID file
; Phase G:   URL rewriting (Caddy-compatible rewrite.conf, --clean-urls)
; Phase C:   Windows Service integration (service mode, install/uninstall)
;
; Compile as console app (thread-safe mode required):
;   pbcompiler -cl -t -o PureSimpleHTTPServer src/main.pb
;
; Run:
;   ./PureSimpleHTTPServer [--port N] [--root DIR] [--browse] [--spa]
;                          [--log FILE] [--error-log FILE] [--log-level LEVEL]
;                          [--log-size MB] [--log-keep N] [--no-log-daily]
;                          [--pid-file FILE]
;                          [--clean-urls] [--rewrite FILE]
;                          [--service] [--service-name NAME]
;   ./PureSimpleHTTPServer [port]     (legacy: bare port number, default 8080)
;
; Service Management (Windows only, requires admin):
;   ./PureSimpleHTTPServer --install          Install as Windows service
;   ./PureSimpleHTTPServer --uninstall        Uninstall Windows service
;   ./PureSimpleHTTPServer --start            Start the service
;   ./PureSimpleHTTPServer --stop             Stop the service
EnableExplicit

; Platform-specific: get current process ID for PID file and error log [pid N] field
CompilerIf #PB_Compiler_OS <> #PB_OS_Windows
  ImportC ""
    getpid.i()
  EndImport
CompilerEndIf

XIncludeFile "Global.pbi"
XIncludeFile "Types.pbi"
XIncludeFile "DateHelper.pbi"
XIncludeFile "UrlHelper.pbi"
XIncludeFile "HttpParser.pbi"
XIncludeFile "HttpResponse.pbi"
XIncludeFile "TcpServer.pbi"
XIncludeFile "MimeTypes.pbi"
XIncludeFile "Logger.pbi"
XIncludeFile "FileServer.pbi"
XIncludeFile "DirectoryListing.pbi"
XIncludeFile "RangeParser.pbi"
XIncludeFile "EmbeddedAssets.pbi"
XIncludeFile "Config.pbi"
XIncludeFile "RewriteEngine.pbi"
XIncludeFile "Middleware.pbi"
XIncludeFile "SignalHandler.pbi"
XIncludeFile "WindowsService.pbi"

; g_Config — server configuration (global so RunRequest can access it)
Global g_Config.ServerConfig

; RunRequestWrapper — thin wrapper matching ConnectionHandlerProto signature
; Bridges g_Handler (2 args) to RunRequest (3 args) by passing g_Config.
Procedure.i RunRequestWrapper(connection.i, raw.s)
  ProcedureReturn RunRequest(connection, raw, @g_Config)
EndProcedure

; Helper: Check if a command-line argument exists
Procedure.i ArgContains(arg.s)
  Protected i.i, count.i = CountProgramParameters()
  For i = 0 To count - 1
    If ProgramParameter(i) = arg
      ProcedureReturn #True
    EndIf
  Next
  ProcedureReturn #False
EndProcedure

; Helper: Get full path to current executable
Procedure.s GetFullExePath()
  ProcedureReturn GetPathPart(ProgramFilename())
EndProcedure

; Application entry point
Procedure Main()
  Protected serviceName.s
  Protected binaryPath.s

  LoadDefaults(@g_Config)

  If Not ParseCLI(@g_Config)
    PrintN("ERROR: Invalid command-line arguments")
    PrintN("Usage: PureSimpleHTTPServer [--port N] [--root DIR] [--browse] [--spa]")
    PrintN("                            [--log FILE] [--error-log FILE] [--log-level LEVEL]")
    PrintN("                            [--log-size MB] [--log-keep N] [--no-log-daily]")
    PrintN("                            [--pid-file FILE]")
    PrintN("                            [--clean-urls] [--rewrite FILE]")
    PrintN("                            [--service] [--service-name NAME]")
    PrintN("Service Management (Windows only):")
    PrintN("                            --install [--service-name NAME]")
    PrintN("                            --uninstall [--service-name NAME]")
    PrintN("                            --start [--service-name NAME]")
    PrintN("                            --stop [--service-name NAME]")
    End 1
  EndIf

  ; Handle Windows Service installation commands (Windows only)
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    If ArgContains("--install")
      binaryPath = GetFullExePath()
      serviceName = g_Config\ServiceName

      If Not InstallService(serviceName, "PureSimple HTTP Server", binaryPath, "Lightweight HTTP/1.1 static file server")
        PrintN("ERROR: Failed to install service")
        PrintN("       Make sure you are running as Administrator")
        End 1
      EndIf

      PrintN("Service installed successfully: " + serviceName)
      PrintN("")
      PrintN("Start the service with:")
      PrintN("  net start " + serviceName)
      PrintN("  Or: PureSimpleHTTPServer.exe --start")
      PrintN("")
      PrintN("Stop the service with:")
      PrintN("  net stop " + serviceName)
      PrintN("  Or: PureSimpleHTTPServer.exe --stop")
      PrintN("")
      PrintN("Uninstall the service with:")
      PrintN("  PureSimpleHTTPServer.exe --uninstall")
      End 0
    EndIf

    If ArgContains("--uninstall")
      serviceName = g_Config\ServiceName

      If Not UninstallService(serviceName)
        PrintN("ERROR: Failed to uninstall service: " + serviceName)
        PrintN("       Make sure you are running as Administrator")
        End 1
      EndIf

      PrintN("Service uninstalled successfully: " + serviceName)
      End 0
    EndIf

    If ArgContains("--start")
      serviceName = g_Config\ServiceName

      PrintN("Starting service: " + serviceName)
      PrintN("")

      RunProgram("sc.exe", "start " + serviceName, "", #PB_Program_Wait)
      End 0
    EndIf

    If ArgContains("--stop")
      serviceName = g_Config\ServiceName

      PrintN("Stopping service: " + serviceName)
      PrintN("")

      RunProgram("sc.exe", "stop " + serviceName, "", #PB_Program_Wait)
      End 0
    EndIf
  CompilerEndIf

  ; Service mode detection
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    If g_Config\ServiceMode
      PrintN("Starting as Windows Service...")
      PrintN("Service name: " + g_Config\ServiceName)
      PrintN("")

      ; Run as Windows service (never returns until service stops)
      RunAsService()
      End 0  ; Should never reach here
    EndIf
  CompilerEndIf

  ; Continue with standalone mode...

  If Not ParseCLI(@g_Config)
    PrintN("ERROR: Invalid command-line arguments")
    PrintN("Usage: PureSimpleHTTPServer [--port N] [--root DIR] [--browse] [--spa]")
    PrintN("                            [--log FILE] [--error-log FILE] [--log-level LEVEL]")
    PrintN("                            [--log-size MB] [--log-keep N] [--no-log-daily]")
    PrintN("                            [--pid-file FILE]")
    PrintN("                            [--clean-urls] [--rewrite FILE]")
    End 1
  EndIf

  InitRewriteEngine()

  ; Load global rewrite rules (if configured)
  If g_Config\RewriteFile <> ""
    LoadGlobalRules(g_Config\RewriteFile)
  EndIf

  ; Apply log settings from config
  g_LogLevel     = g_Config\LogLevel
  g_LogMaxBytes  = g_Config\LogSizeMB * 1024 * 1024
  g_LogKeepCount = g_Config\LogKeepCount

  ; Set process ID for error log lines and PID file
  CompilerIf #PB_Compiler_OS <> #PB_OS_Windows
    g_ServerPID = getpid()
  CompilerEndIf

  ; To embed assets: add UseZipPacker() + DataSection (webapp: IncludeBinary "webapp.zip" webappEnd:)
  ; then call OpenEmbeddedPack(?webapp, ?webappEnd - ?webapp) here.
  ; Without embedded assets, OpenEmbeddedPack() returns #False and disk serving is used.
  OpenEmbeddedPack()

  If g_Config\LogFile <> ""
    If Not OpenLogFile(g_Config\LogFile)
      PrintN("WARNING: Cannot open access log: " + g_Config\LogFile)
    EndIf
  EndIf

  If g_Config\ErrorLogFile <> ""
    If Not OpenErrorLog(g_Config\ErrorLogFile)
      PrintN("WARNING: Cannot open error log: " + g_Config\ErrorLogFile)
    EndIf
  EndIf

  ; Write PID file
  If g_Config\PidFile <> ""
    Protected pidFH.i = CreateFile(#PB_Any, g_Config\PidFile)
    If pidFH > 0
      WriteStringN(pidFH, Str(g_ServerPID), #PB_Ascii)
      CloseFile(pidFH)
    Else
      PrintN("WARNING: Cannot write PID file: " + g_Config\PidFile)
    EndIf
  EndIf

  ; Start daily midnight rotation if enabled and at least one log file is configured
  If g_Config\LogDaily = 1 And (g_Config\LogFile <> "" Or g_Config\ErrorLogFile <> "")
    StartDailyRotation()
  EndIf

  ; Install SIGHUP handler for logrotate integration (macOS/Linux; no-op on Windows)
  InstallSignalHandlers()

  PrintN(#APP_NAME + " v" + #APP_VERSION)
  If g_EmbeddedPack > 0
    PrintN("Mode:       embedded assets (in-memory)")
  EndIf
  PrintN("Serving:    " + g_Config\RootDirectory)
  PrintN("Listening:  http://localhost:" + Str(g_Config\Port))
  If g_Config\LogFile <> ""
    PrintN("Access log: " + g_Config\LogFile)
  EndIf
  If g_Config\ErrorLogFile <> ""
    PrintN("Error log:  " + g_Config\ErrorLogFile)
  EndIf
  If g_Config\PidFile <> "" And FileSize(g_Config\PidFile) >= 0
    PrintN("PID file:   " + g_Config\PidFile + " (PID " + Str(g_ServerPID) + ")")
  EndIf
  If g_Config\CleanUrls
    PrintN("Clean URLs: enabled (extensionless paths try .html)")
  EndIf
  If g_Config\RewriteFile <> ""
    PrintN("Rewrite:    " + g_Config\RewriteFile + " (" + Str(GlobalRuleCount()) + " rules)")
  EndIf
  PrintN("Press Ctrl+C to stop")
  PrintN("")

  BuildChain()
  g_Handler = @RunRequestWrapper()

  If Not StartServer(g_Config\Port)
    PrintN("ERROR: Failed to start server on port " + Str(g_Config\Port))
    RemoveSignalHandlers()
    StopDailyRotation()
    CloseLogFile()
    CloseErrorLog()
    If g_Config\PidFile <> "" : DeleteFile(g_Config\PidFile) : EndIf
    CleanupRewriteEngine()
    CloseEmbeddedPack()
    End 1
  EndIf

  RemoveSignalHandlers()
  StopDailyRotation()
  CloseLogFile()
  CloseErrorLog()
  If g_Config\PidFile <> "" : DeleteFile(g_Config\PidFile) : EndIf
  CleanupRewriteEngine()
  CloseEmbeddedPack()
EndProcedure

Main()
