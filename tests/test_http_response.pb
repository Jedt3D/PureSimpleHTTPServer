; test_http_response.pb — Unit tests for HttpResponse.pbi
; Tests: StatusText(), BuildResponseHeaders()
; NOTE: SendTextResponse() requires a live network connection — not unit tested here.
; HttpResponse.pbi transitively includes Global.pbi
EnableExplicit
XIncludeFile "TestCommon.pbi"

; -----------------------------------------------------------------------
; StatusText: all known status codes return the correct reason phrase
; -----------------------------------------------------------------------
ProcedureUnit Test_StatusText_KnownCodes()
  Assert(StatusText(200) = "OK",                       "200")
  Assert(StatusText(206) = "Partial Content",          "206")
  Assert(StatusText(304) = "Not Modified",             "304")
  Assert(StatusText(400) = "Bad Request",              "400")
  Assert(StatusText(403) = "Forbidden",                "403")
  Assert(StatusText(404) = "Not Found",                "404")
  Assert(StatusText(416) = "Range Not Satisfiable",    "416")
  Assert(StatusText(500) = "Internal Server Error",    "500")
EndProcedureUnit

; -----------------------------------------------------------------------
; BuildResponseHeaders: status line is correct HTTP/1.1 format
; -----------------------------------------------------------------------
ProcedureUnit Test_BuildResponseHeaders_StatusLine()
  Protected result.s = BuildResponseHeaders(200, "", 0)
  Assert(Left(result, 15) = "HTTP/1.1 200 OK",
         "Status line starts with 'HTTP/1.1 200 OK' — got: '" + Left(result, 15) + "'")

  result = BuildResponseHeaders(404, "", 0)
  Assert(FindString(result, "HTTP/1.1 404 Not Found") > 0, "404 status line present")
EndProcedureUnit

; -----------------------------------------------------------------------
; BuildResponseHeaders: Content-Length matches bodyLen argument
; -----------------------------------------------------------------------
ProcedureUnit Test_BuildResponseHeaders_ContentLength()
  Protected result.s = BuildResponseHeaders(200, "", 42)
  Assert(FindString(result, "Content-Length: 42" + #CRLF$) > 0,
         "Content-Length: 42 present — headers: '" + result + "'")

  result = BuildResponseHeaders(200, "", 0)
  Assert(FindString(result, "Content-Length: 0" + #CRLF$) > 0,
         "Content-Length: 0 present for empty body")
EndProcedureUnit

; -----------------------------------------------------------------------
; BuildResponseHeaders: header block ends with blank line (\r\n\r\n)
; -----------------------------------------------------------------------
ProcedureUnit Test_BuildResponseHeaders_BlankLineTerminator()
  Protected result.s = BuildResponseHeaders(200, "", 0)
  Assert(Right(result, 4) = #CRLF$ + #CRLF$,
         "Header block ends with CRLFCRLF")
EndProcedureUnit

; -----------------------------------------------------------------------
; BuildResponseHeaders: extra headers are included in output
; -----------------------------------------------------------------------
ProcedureUnit Test_BuildResponseHeaders_ExtraHeaders()
  Protected extra.s  = "Content-Type: text/html; charset=utf-8" + #CRLF$ +
                       "Cache-Control: no-cache" + #CRLF$
  Protected result.s = BuildResponseHeaders(200, extra, 100)
  Assert(FindString(result, "Content-Type: text/html; charset=utf-8") > 0,
         "Content-Type extra header present")
  Assert(FindString(result, "Cache-Control: no-cache") > 0,
         "Cache-Control extra header present")
  Assert(Right(result, 4) = #CRLF$ + #CRLF$,
         "Still ends with CRLFCRLF when extra headers included")
EndProcedureUnit
