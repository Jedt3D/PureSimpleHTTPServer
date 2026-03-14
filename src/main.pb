; main.pb — PureSimpleHTTPServer entry point
; Phase D: embedded asset serving via IncludeBinary + CatchPack
;
; Compile as console app:
;   pbcompiler -cl -o PureSimpleHTTPServer src/main.pb
;
; Run:
;   ./PureSimpleHTTPServer [port]     (default: 8080)
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
XIncludeFile "Config.pbi"

; g_Config — server configuration (global so HandleRequest can access it)
Global g_Config.ServerConfig

; HandleRequest — called by TcpServer for each complete HTTP request
Procedure.i HandleRequest(connection.i, raw.s)
  Protected req.HttpRequest

  If Not ParseHttpRequest(raw, req)
    SendTextResponse(connection, #HTTP_400, "text/plain; charset=utf-8", "400 Bad Request")
    ProcedureReturn #False
  EndIf

  If req\Method = "GET"
    ; Try embedded assets first (returns #False if no pack or file not in pack)
    If ServeEmbeddedFile(connection, req\Path)
      ProcedureReturn #True
    EndIf
    ProcedureReturn ServeFile(connection, @g_Config, @req)
  EndIf

  SendTextResponse(connection, #HTTP_400, "text/plain; charset=utf-8", "400 Bad Request")
  ProcedureReturn #False
EndProcedure

; Application entry point
Procedure Main()
  LoadDefaults(@g_Config)

  If Not ParseCLI(@g_Config)
    PrintN("ERROR: Invalid command-line arguments")
    PrintN("Usage: PureSimpleHTTPServer [port]")
    End 1
  EndIf

  ; To embed assets: add UseZipPacker() + DataSection (webapp: IncludeBinary "webapp.zip" webappEnd:)
  ; then call OpenEmbeddedPack(?webapp, ?webappEnd - ?webapp) here.
  ; Without embedded assets, OpenEmbeddedPack() returns #False and disk serving is used.
  OpenEmbeddedPack()

  PrintN(#APP_NAME + " v" + #APP_VERSION)
  If g_EmbeddedPack > 0
    PrintN("Mode:       embedded assets (in-memory)")
  EndIf
  PrintN("Serving:    " + g_Config\RootDirectory)
  PrintN("Listening:  http://localhost:" + Str(g_Config\Port))
  PrintN("Press Ctrl+C to stop")
  PrintN("")

  g_Handler = @HandleRequest()

  If Not StartServer(g_Config\Port)
    PrintN("ERROR: Failed to start server on port " + Str(g_Config\Port))
    CloseEmbeddedPack()
    End 1
  EndIf

  CloseEmbeddedPack()
EndProcedure

Main()
