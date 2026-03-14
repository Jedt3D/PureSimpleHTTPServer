; main.pb — PureSimpleHTTPServer entry point
; Phase E: thread-per-connection, Logger integration, full CLI parsing
;
; Compile as console app (thread-safe mode required for Phase E):
;   pbcompiler -cl -t -o PureSimpleHTTPServer src/main.pb
;
; Run:
;   ./PureSimpleHTTPServer [--port N] [--root DIR] [--browse] [--spa] [--log FILE]
;   ./PureSimpleHTTPServer [port]     (legacy: bare port number, default 8080)
EnableExplicit

XIncludeFile "Global.pbi"
XIncludeFile "Types.pbi"
XIncludeFile "DateHelper.pbi"
XIncludeFile "UrlHelper.pbi"
XIncludeFile "HttpParser.pbi"
XIncludeFile "HttpResponse.pbi"
XIncludeFile "TcpServer.pbi"
XIncludeFile "MimeTypes.pbi"
XIncludeFile "FileServer.pbi"
XIncludeFile "DirectoryListing.pbi"
XIncludeFile "RangeParser.pbi"
XIncludeFile "EmbeddedAssets.pbi"
XIncludeFile "Logger.pbi"
XIncludeFile "Config.pbi"

; g_Config — server configuration (global so HandleRequest can access it)
Global g_Config.ServerConfig

; HandleRequest — called by TcpServer for each complete HTTP request
Procedure.i HandleRequest(connection.i, raw.s)
  Protected req.HttpRequest
  Protected clientIP.s = NetworkClientIP(connection)
  Protected result.i, status.i

  If Not ParseHttpRequest(raw, req)
    SendTextResponse(connection, #HTTP_400, "text/plain; charset=utf-8", "400 Bad Request")
    LogAccess("?", "/", 400, 0, clientIP)
    ProcedureReturn #False
  EndIf

  If req\Method = "GET"
    ; Try embedded assets first (returns #False if no pack or file not in pack)
    If ServeEmbeddedFile(connection, req\Path)
      LogAccess(req\Method, req\Path, 200, 0, clientIP)
      ProcedureReturn #True
    EndIf
    result = ServeFile(connection, @g_Config, @req)
    If result : status = 200 : Else : status = 400 : EndIf
    LogAccess(req\Method, req\Path, status, 0, clientIP)
    ProcedureReturn result
  EndIf

  SendTextResponse(connection, #HTTP_400, "text/plain; charset=utf-8", "400 Bad Request")
  LogAccess(req\Method, req\Path, 400, 0, clientIP)
  ProcedureReturn #False
EndProcedure

; Application entry point
Procedure Main()
  LoadDefaults(@g_Config)

  If Not ParseCLI(@g_Config)
    PrintN("ERROR: Invalid command-line arguments")
    PrintN("Usage: PureSimpleHTTPServer [--port N] [--root DIR] [--browse] [--spa] [--log FILE]")
    End 1
  EndIf

  ; To embed assets: add UseZipPacker() + DataSection (webapp: IncludeBinary "webapp.zip" webappEnd:)
  ; then call OpenEmbeddedPack(?webapp, ?webappEnd - ?webapp) here.
  ; Without embedded assets, OpenEmbeddedPack() returns #False and disk serving is used.
  OpenEmbeddedPack()

  If g_Config\LogFile <> ""
    If Not OpenLogFile(g_Config\LogFile)
      PrintN("WARNING: Cannot open log file: " + g_Config\LogFile)
    EndIf
  EndIf

  PrintN(#APP_NAME + " v" + #APP_VERSION)
  If g_EmbeddedPack > 0
    PrintN("Mode:       embedded assets (in-memory)")
  EndIf
  PrintN("Serving:    " + g_Config\RootDirectory)
  PrintN("Listening:  http://localhost:" + Str(g_Config\Port))
  If g_Config\LogFile <> ""
    PrintN("Log:        " + g_Config\LogFile)
  EndIf
  PrintN("Press Ctrl+C to stop")
  PrintN("")

  g_Handler = @HandleRequest()

  If Not StartServer(g_Config\Port)
    PrintN("ERROR: Failed to start server on port " + Str(g_Config\Port))
    CloseLogFile()
    CloseEmbeddedPack()
    End 1
  EndIf

  CloseLogFile()
  CloseEmbeddedPack()
EndProcedure

Main()
