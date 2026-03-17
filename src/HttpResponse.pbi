; HttpResponse.pbi — HTTP/1.1 response builder
; Include with: XIncludeFile "HttpResponse.pbi"
; Provides: StatusText(), BuildResponseHeaders(), SendTextResponse(), FillTextResponse()
; Dependencies (managed by main.pb and tests/TestCommon.pbi): Global.pbi, Types.pbi

; StatusText(code.i) — return the standard HTTP reason phrase for a status code
Procedure.s StatusText(code.i)
  Select code
    Case 200 : ProcedureReturn "OK"
    Case 204 : ProcedureReturn "No Content"
    Case 206 : ProcedureReturn "Partial Content"
    Case 301 : ProcedureReturn "Moved Permanently"
    Case 302 : ProcedureReturn "Found"
    Case 304 : ProcedureReturn "Not Modified"
    Case 400 : ProcedureReturn "Bad Request"
    Case 401 : ProcedureReturn "Unauthorized"
    Case 403 : ProcedureReturn "Forbidden"
    Case 404 : ProcedureReturn "Not Found"
    Case 416 : ProcedureReturn "Range Not Satisfiable"
    Case 500 : ProcedureReturn "Internal Server Error"
    Default  : ProcedureReturn "Unknown"
  EndSelect
EndProcedure

; BuildResponseHeaders(statusCode.i, extraHeaders.s, bodyLen.i) — assemble an HTTP response header block
;
; extraHeaders: additional response headers (each line must end with #CRLF$; may be "")
; bodyLen:      Content-Length value in bytes
;
; Returns: complete header block string ending with #CRLF$+#CRLF$ (ready to send as-is)
;
; NOTE: This is a pure string function — testable without a network connection.
Procedure.s BuildResponseHeaders(statusCode.i, extraHeaders.s, bodyLen.i)
  Protected result.s
  result = "HTTP/1.1 " + Str(statusCode) + " " + StatusText(statusCode) + #CRLF$
  result + "Server: " + #APP_NAME + "/" + #APP_VERSION + #CRLF$
  result + "Content-Length: " + Str(bodyLen) + #CRLF$
  result + "Connection: close" + #CRLF$
  If extraHeaders <> ""
    result + extraHeaders
  EndIf
  result + #CRLF$  ; blank line — marks end of headers
  ProcedureReturn result
EndProcedure

; SendTextResponse(connection.i, statusCode.i, contentType.s, body.s)
; Send a complete HTTP response with a UTF-8 string body.
; Uses StringByteLength() for correct Content-Length on non-ASCII content.
Procedure SendTextResponse(connection.i, statusCode.i, contentType.s, body.s)
  Protected byteLen.i      = StringByteLength(body, #PB_UTF8)
  Protected extraHeaders.s = "Content-Type: " + contentType + #CRLF$
  Protected headerBlock.s  = BuildResponseHeaders(statusCode, extraHeaders, byteLen)
  SendNetworkString(connection, headerBlock, #PB_Ascii)
  If byteLen > 0
    SendNetworkString(connection, body, #PB_UTF8)
  EndIf
EndProcedure

; FillTextResponse(*resp, statusCode, contentType, body)
; Write a text response into a ResponseBuffer instead of the network.
; Allocates a UTF-8 body buffer; the chain runner frees it after sending.
Procedure FillTextResponse(*resp.ResponseBuffer, statusCode.i, contentType.s, body.s)
  Protected byteLen.i = StringByteLength(body, #PB_UTF8)
  *resp\StatusCode = statusCode
  *resp\Headers    = "Content-Type: " + contentType + #CRLF$
  If byteLen > 0
    *resp\Body = AllocateMemory(byteLen)
    If *resp\Body
      PokeS(*resp\Body, body, -1, #PB_UTF8 | #PB_String_NoZero)
    EndIf
  Else
    *resp\Body = 0
  EndIf
  *resp\BodySize = byteLen
  *resp\Handled  = #True
EndProcedure
