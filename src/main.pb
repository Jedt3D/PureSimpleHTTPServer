; main.pb — PureSimpleHTTPServer entry point
; Compile as console app (thread-safe mode required):
;   pbcompiler -cl -t -o PureSimpleHTTPServer src/main.pb
;
; Run:
;   ./PureSimpleHTTPServer [--port N] [--root DIR] [--browse] [--spa]
;                          [--log FILE] [--error-log FILE] [--log-level LEVEL]
;                          [--log-size MB] [--log-keep N] [--no-log-daily]
;                          [--pid-file FILE]
;                          [--clean-urls] [--rewrite FILE]
;                          [--tls-cert FILE] [--tls-key FILE]
;                          [--auto-tls DOMAIN]
;                          [--health PATH] [--cors] [--cors-origin ORIGIN]
;                          [--security-headers]
;                          [--error-pages DIR] [--basic-auth USER:PASS]
;                          [--cache-max-age N]
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
CompilerIf #PB_Compiler_OS = #PB_OS_Windows
  ImportC "kernel32.lib"
    GetCurrentProcessId.l()
  EndImport
CompilerElse
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
XIncludeFile "AutoTLS.pbi"
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
  Protected listenScheme.s

  LoadDefaults(@g_Config)

  If Not ParseCLI(@g_Config)
    PrintN("ERROR: Invalid command-line arguments")
    PrintN("Usage: PureSimpleHTTPServer [--port N] [--root DIR] [--browse] [--spa]")
    PrintN("                            [--log FILE] [--error-log FILE] [--log-level LEVEL]")
    PrintN("                            [--log-size MB] [--log-keep N] [--no-log-daily]")
    PrintN("                            [--pid-file FILE]")
    PrintN("                            [--clean-urls] [--rewrite FILE]")
    PrintN("                            [--tls-cert FILE --tls-key FILE]")
    PrintN("                            [--auto-tls DOMAIN]")
    PrintN("                            [--health PATH] [--cors] [--cors-origin ORIGIN]")
    PrintN("                            [--security-headers]")
    PrintN("                            [--error-pages DIR] [--basic-auth USER:PASS]")
    PrintN("                            [--cache-max-age N]")
    PrintN("                            [--service] [--service-name NAME]")
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
    PrintN("                            [--tls-cert FILE --tls-key FILE]")
    PrintN("                            [--auto-tls DOMAIN]")
    PrintN("                            [--health PATH] [--cors] [--cors-origin ORIGIN]")
    PrintN("                            [--security-headers]")
    PrintN("                            [--error-pages DIR] [--basic-auth USER:PASS]")
    PrintN("                            [--cache-max-age N]")
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
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    g_ServerPID = GetCurrentProcessId()
  CompilerElse
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

  ; ── TLS setup ──────────────────────────────────────────────────────────

  ; Determine TLS mode: auto-tls > manual tls > plain http
  If g_Config\AutoTlsDomain <> ""
    ; --- Auto-TLS: issue/renew certificates via acme.sh ---

    ; Auto-TLS requires acme.sh (bash script) — not available natively on Windows
    CompilerIf #PB_Compiler_OS = #PB_OS_Windows
      PrintN("ERROR: --auto-tls requires acme.sh which is not available on Windows")
      PrintN("       Use --tls-cert and --tls-key to provide certificates manually")
      End 1
    CompilerEndIf

    g_AutoTlsDomain = g_Config\AutoTlsDomain

    ; Set up ACME challenge directory inside the webroot
    g_AcmeChallengeDir = g_Config\RootDirectory + #SEP + ".well-known" + #SEP + "acme-challenge"
    CreateDirectory(g_Config\RootDirectory + #SEP + ".well-known")
    CreateDirectory(g_AcmeChallengeDir)

    ; Start HTTP redirect server on port 80 (ACME challenges + HTTPS redirect)
    PrintN("Starting HTTP challenge listener on port 80...")
    StartHttpRedirect(80)

    ; Issue certificate if it doesn't exist yet
    If Not CertificateExists(g_AutoTlsDomain)
      PrintN("Requesting TLS certificate for " + g_AutoTlsDomain + "...")
      If Not IssueCertificate(g_AutoTlsDomain, g_Config\RootDirectory)
        PrintN("ERROR: Failed to obtain TLS certificate")
        PrintN("       Make sure acme.sh is installed (~/.acme.sh/acme.sh)")
        PrintN("       and port 80 is accessible from the internet")
        StopHttpRedirect()
        End 1
      EndIf
      PrintN("Certificate obtained successfully")
    EndIf

    ; Load certificate into TLS globals
    g_TlsKey  = ReadPEMFile(GetKeyPath(g_AutoTlsDomain))
    g_TlsCert = ReadPEMFile(GetCertPath(g_AutoTlsDomain))
    If g_TlsKey = "" Or g_TlsCert = ""
      PrintN("ERROR: Failed to read TLS certificate/key files")
      StopHttpRedirect()
      End 1
    EndIf
    g_TlsEnabled = #True

    ; Default to port 443 for auto-TLS unless explicitly set
    If g_Config\Port = #DEFAULT_PORT
      g_Config\Port = 443
    EndIf

    ; Start background renewal thread
    StartCertRenewal()

  ElseIf g_Config\TlsCert <> "" And g_Config\TlsKey <> ""
    ; --- Manual TLS: user-provided certificate files ---
    g_TlsKey = ReadPEMFile(g_Config\TlsKey)
    If g_TlsKey = ""
      PrintN("ERROR: Cannot read TLS key file: " + g_Config\TlsKey)
      End 1
    EndIf
    g_TlsCert = ReadPEMFile(g_Config\TlsCert)
    If g_TlsCert = ""
      PrintN("ERROR: Cannot read TLS certificate file: " + g_Config\TlsCert)
      End 1
    EndIf
    g_TlsEnabled = #True

  ElseIf g_Config\TlsCert <> "" Or g_Config\TlsKey <> ""
    PrintN("ERROR: Both --tls-cert and --tls-key must be specified together")
    End 1
  EndIf

  ; ── Startup banner ─────────────────────────────────────────────────────

  PrintN(#APP_NAME + " v" + #APP_VERSION)
  If g_EmbeddedPack > 0
    PrintN("Mode:       embedded assets (in-memory)")
  EndIf
  PrintN("Serving:    " + g_Config\RootDirectory)

  If g_TlsEnabled
    listenScheme = "https"
  Else
    listenScheme = "http"
  EndIf
  PrintN("Listening:  " + listenScheme + "://localhost:" + Str(g_Config\Port))

  If g_Config\AutoTlsDomain <> ""
    PrintN("Auto-TLS:   " + g_Config\AutoTlsDomain + " (renew every 12h)")
    PrintN("Challenge:  http://localhost:80 (ACME + redirect)")
  ElseIf g_TlsEnabled
    PrintN("TLS cert:   " + g_Config\TlsCert)
    PrintN("TLS key:    " + g_Config\TlsKey)
  EndIf

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
  If g_Config\HealthPath <> ""
    PrintN("Health:     " + g_Config\HealthPath)
  EndIf
  If g_Config\CorsEnabled
    If g_Config\CorsOrigin <> ""
      PrintN("CORS:       enabled (origin: " + g_Config\CorsOrigin + ")")
    Else
      PrintN("CORS:       enabled (origin: *)")
    EndIf
  EndIf
  If g_Config\SecurityHeaders
    PrintN("Security:   security headers enabled")
  EndIf
  If g_Config\ErrorPagesDir <> ""
    PrintN("Errors:     custom pages from " + g_Config\ErrorPagesDir)
  EndIf
  If g_Config\BasicAuthUser <> ""
    PrintN("Auth:       basic auth enabled (user: " + g_Config\BasicAuthUser + ")")
  EndIf
  If g_Config\CacheMaxAge > 0
    PrintN("Cache:      max-age=" + Str(g_Config\CacheMaxAge))
  EndIf
  PrintN("Press Ctrl+C to stop")
  PrintN("")

  BuildChain()
  g_Handler = @RunRequestWrapper()

  If Not StartServer(g_Config\Port)
    PrintN("ERROR: Failed to start server on port " + Str(g_Config\Port))
    If g_Config\AutoTlsDomain <> ""
      StopCertRenewal()
      StopHttpRedirect()
    EndIf
    RemoveSignalHandlers()
    StopDailyRotation()
    CloseLogFile()
    CloseErrorLog()
    If g_Config\PidFile <> "" : DeleteFile(g_Config\PidFile) : EndIf
    CleanupRewriteEngine()
    CloseEmbeddedPack()
    End 1
  EndIf

  ; Clean shutdown
  If g_Config\AutoTlsDomain <> ""
    StopCertRenewal()
    StopHttpRedirect()
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
