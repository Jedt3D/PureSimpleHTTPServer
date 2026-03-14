; HttpParser.pbi — HTTP/1.1 request parser
; Include with: XIncludeFile "HttpParser.pbi"
; Provides: ParseHttpRequest(), GetHeader()
; Dependencies (managed by main.pb and tests/TestCommon.pbi): Types.pbi, UrlHelper.pbi

; GetHeader(rawHeaders.s, name.s) — extract a header value by name
;
; rawHeaders: raw header block from HttpRequest\RawHeaders
;             (lines separated by #CRLF$, no trailing blank line required)
; name:       header name to find (case-insensitive)
; Returns:    trimmed header value, or "" if header not found
Procedure.s GetHeader(rawHeaders.s, name.s)
  Protected i.i, line.s, colonPos.i, count.i
  name = LCase(name)
  count = CountString(rawHeaders, #CRLF$) + 1
  For i = 1 To count
    line = StringField(rawHeaders, i, #CRLF$)
    colonPos = FindString(line, ":")
    If colonPos > 0
      If LCase(Left(line, colonPos - 1)) = name
        ProcedureReturn Trim(Mid(line, colonPos + 1))
      EndIf
    EndIf
  Next i
  ProcedureReturn ""
EndProcedure

; ParseHttpRequest(raw.s, *req.HttpRequest) — parse a raw HTTP/1.1 request string
;
; raw:  complete raw request (must contain \r\n\r\n header terminator)
; *req: pointer to HttpRequest structure to fill
;
; Returns #True on success, #False on failure.
; On failure: req\IsValid = #False, req\ErrorCode = 400
Procedure.i ParseHttpRequest(raw.s, *req.HttpRequest)
  Protected headerEndPos.i, headerBlock.s, requestLine.s
  Protected method.s, target.s, version.s, qpos.i, clValue.s

  ; Initialize all fields
  *req\IsValid       = #False
  *req\ErrorCode     = 400
  *req\Method        = ""
  *req\Path          = ""
  *req\QueryString   = ""
  *req\Version       = ""
  *req\RawHeaders    = ""
  *req\ContentLength = 0
  *req\Body          = ""

  ; Locate the end of the header block (\r\n\r\n)
  headerEndPos = FindString(raw, #CRLF$ + #CRLF$)
  If headerEndPos = 0
    ProcedureReturn #False
  EndIf

  ; Extract header block (everything before \r\n\r\n)
  headerBlock = Left(raw, headerEndPos - 1)

  ; Extract body (everything after \r\n\r\n)
  If Len(raw) > headerEndPos + 3
    *req\Body = Mid(raw, headerEndPos + 4)
  EndIf

  ; Parse request line (first line of header block)
  requestLine = StringField(headerBlock, 1, #CRLF$)
  method      = StringField(requestLine, 1, " ")
  target      = StringField(requestLine, 2, " ")
  version     = StringField(requestLine, 3, " ")

  If method = "" Or target = "" Or version = ""
    ProcedureReturn #False
  EndIf

  ; Validate HTTP version token (must start with "HTTP/")
  If Left(version, 5) <> "HTTP/"
    ProcedureReturn #False
  EndIf

  *req\Method  = method
  *req\Version = version

  ; Split request target into path and query string
  qpos = FindString(target, "?")
  If qpos > 0
    *req\Path        = NormalizePath(URLDecodePath(Left(target, qpos - 1)))
    *req\QueryString = Mid(target, qpos + 1)
  Else
    *req\Path        = NormalizePath(URLDecodePath(target))
    *req\QueryString = ""
  EndIf

  ; Store raw headers (everything after request line + \r\n)
  *req\RawHeaders = Mid(headerBlock, Len(requestLine) + 3)

  ; Extract Content-Length if present
  clValue = GetHeader(*req\RawHeaders, "content-length")
  If clValue <> ""
    *req\ContentLength = Val(clValue)
  EndIf

  *req\IsValid   = #True
  *req\ErrorCode = 0
  ProcedureReturn #True
EndProcedure
