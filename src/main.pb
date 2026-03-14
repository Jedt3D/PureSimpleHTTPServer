; main.pb — PureSimpleHTTPServer entry point
; Phase F-1: Apache Combined Log Format, error log, log level filtering
; Phase F-3: Daily rotation thread, PID file
;
; Compile as console app (thread-safe mode required):
;   pbcompiler -cl -t -o PureSimpleHTTPServer src/main.pb
;
; Run:
;   ./PureSimpleHTTPServer [--port N] [--root DIR] [--browse] [--spa]
;                          [--log FILE] [--error-log FILE] [--log-level LEVEL]
;                          [--log-size MB] [--log-keep N] [--no-log-daily]
;                          [--pid-file FILE]
;   ./PureSimpleHTTPServer [port]     (legacy: bare port number, default 8080)
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

; g_Config — server configuration (global so HandleRequest can access it)
Global g_Config.ServerConfig

; HandleRequest — called by TcpServer for each complete HTTP request
Procedure.i HandleRequest(connection.i, raw.s)
  Protected req.HttpRequest
  Protected clientIP.s   = IPString(GetClientIP(connection))
  Protected result.i
  Protected bytesOut.i   = 0
  Protected statusCode.i = 0
  Protected referer.s, userAgent.s

  If Not ParseHttpRequest(raw, req)
    SendTextResponse(connection, #HTTP_400, "text/plain; charset=utf-8", "400 Bad Request")
    LogAccess(clientIP, "?", "/", "HTTP/1.1", #HTTP_400, 0, "", "")
    ProcedureReturn #False
  EndIf

  referer   = GetHeader(req\RawHeaders, "Referer")
  userAgent = GetHeader(req\RawHeaders, "User-Agent")

  If req\Method = "GET"
    ; Try embedded assets first (returns #False if no pack or file not in pack)
    If ServeEmbeddedFile(connection, req\Path)
      LogAccess(clientIP, req\Method, req\Path, req\Version, #HTTP_200, 0, referer, userAgent)
      ProcedureReturn #True
    EndIf
    result = ServeFile(connection, @g_Config, @req, @bytesOut, @statusCode)
    LogAccess(clientIP, req\Method, req\Path, req\Version, statusCode, bytesOut, referer, userAgent)
    ProcedureReturn result
  EndIf

  SendTextResponse(connection, #HTTP_400, "text/plain; charset=utf-8", "400 Bad Request")
  LogAccess(clientIP, req\Method, req\Path, req\Version, #HTTP_400, 0, referer, userAgent)
  ProcedureReturn #False
EndProcedure

; Application entry point
Procedure Main()
  LoadDefaults(@g_Config)

  If Not ParseCLI(@g_Config)
    PrintN("ERROR: Invalid command-line arguments")
    PrintN("Usage: PureSimpleHTTPServer [--port N] [--root DIR] [--browse] [--spa]")
    PrintN("                            [--log FILE] [--error-log FILE] [--log-level LEVEL]")
    PrintN("                            [--log-size MB] [--log-keep N] [--no-log-daily]")
    PrintN("                            [--pid-file FILE]")
    End 1
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
  PrintN("Press Ctrl+C to stop")
  PrintN("")

  g_Handler = @HandleRequest()

  If Not StartServer(g_Config\Port)
    PrintN("ERROR: Failed to start server on port " + Str(g_Config\Port))
    StopDailyRotation()
    CloseLogFile()
    CloseErrorLog()
    If g_Config\PidFile <> "" : DeleteFile(g_Config\PidFile) : EndIf
    CloseEmbeddedPack()
    End 1
  EndIf

  StopDailyRotation()
  CloseLogFile()
  CloseErrorLog()
  If g_Config\PidFile <> "" : DeleteFile(g_Config\PidFile) : EndIf
  CloseEmbeddedPack()
EndProcedure

Main()
