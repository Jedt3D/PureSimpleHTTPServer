; main.pb — PureSimpleHTTPServer entry point
; Phase A: TCP server that responds with a Hello World / request-info HTML page
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

; HandleRequest — called by TcpServer for each complete HTTP request
Procedure.i HandleRequest(connection.i, raw.s)
  Protected req.HttpRequest

  If Not ParseHttpRequest(raw, req)
    SendTextResponse(connection, #HTTP_400, "text/plain; charset=utf-8", "400 Bad Request")
    ProcedureReturn #False
  EndIf

  ; Phase A: serve an informational HTML page echoing the parsed request
  Protected body.s
  body = "<!DOCTYPE html>" + #LF$
  body + "<html>" + #LF$
  body + "<head><title>" + #APP_NAME + " v" + #APP_VERSION + "</title></head>" + #LF$
  body + "<body>" + #LF$
  body + "<h1>" + #APP_NAME + " v" + #APP_VERSION + "</h1>" + #LF$
  body + "<table border='1' cellpadding='4'>" + #LF$
  body + "<tr><td><b>Method</b></td><td>" + req\Method + "</td></tr>" + #LF$
  body + "<tr><td><b>Path</b></td><td>" + req\Path + "</td></tr>" + #LF$
  body + "<tr><td><b>Query</b></td><td>" + req\QueryString + "</td></tr>" + #LF$
  body + "<tr><td><b>Version</b></td><td>" + req\Version + "</td></tr>" + #LF$
  body + "<tr><td><b>Server time</b></td><td>" + HTTPDate(DateUTC()) + "</td></tr>" + #LF$
  body + "</table>" + #LF$
  body + "</body></html>"

  SendTextResponse(connection, #HTTP_200, "text/html; charset=utf-8", body)
  ProcedureReturn #True
EndProcedure

; Application entry point
Procedure Main()
  Define port.i = #DEFAULT_PORT

  ; Optional port override from command line
  If CountProgramParameters() >= 1
    port = Val(ProgramParameter(0))
    If port <= 0 Or port > 65535
      PrintN("ERROR: Invalid port '" + ProgramParameter(0) + "' (must be 1-65535)")
      End 1
    EndIf
  EndIf

  PrintN(#APP_NAME + " v" + #APP_VERSION)
  PrintN("Listening on http://localhost:" + Str(port))
  PrintN("Press Ctrl+C to stop")
  PrintN("")

  g_Handler = @HandleRequest()

  If Not StartServer(port)
    PrintN("ERROR: Failed to start server on port " + Str(port))
    End 1
  EndIf
EndProcedure

Main()
