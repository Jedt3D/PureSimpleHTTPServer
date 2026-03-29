; test_http_parser.pb — Unit tests for HttpParser.pbi
; Tests: ParseHttpRequest(), GetHeader()
; Note: HttpParser.pbi transitively includes Types.pbi, UrlHelper.pbi, Global.pbi
EnableExplicit
XIncludeFile "TestCommon.pbi"

; -----------------------------------------------------------------------
; ParseHttpRequest: simple GET request
; -----------------------------------------------------------------------
ProcedureUnit Test_ParseHttpRequest_SimpleGET()
  Protected req.HttpRequest
  Protected raw.s = "GET /index.html HTTP/1.1" + #CRLF$ +
                    "Host: localhost" + #CRLF$ +
                    #CRLF$
  ParseHttpRequest(raw, req)
  Assert(req\IsValid  = #True,        "Request is valid")
  Assert(req\Method   = "GET",        "Method is GET")
  Assert(req\Path     = "/index.html","Path extracted")
  Assert(req\Version  = "HTTP/1.1",   "Version extracted")
EndProcedureUnit

; -----------------------------------------------------------------------
; ParseHttpRequest: query string separated from path
; -----------------------------------------------------------------------
ProcedureUnit Test_ParseHttpRequest_QueryString()
  Protected req.HttpRequest
  Protected raw.s = "GET /search?q=hello%20world&page=1 HTTP/1.1" + #CRLF$ +
                    "Host: localhost" + #CRLF$ +
                    #CRLF$
  ParseHttpRequest(raw, req)
  Assert(req\IsValid      = #True,                    "Valid request")
  Assert(req\Path         = "/search",                "Path has no query string")
  Assert(req\QueryString  = "q=hello%20world&page=1", "Query string preserved raw")
EndProcedureUnit

; -----------------------------------------------------------------------
; ParseHttpRequest: multiple headers extracted via GetHeader()
; -----------------------------------------------------------------------
ProcedureUnit Test_ParseHttpRequest_Headers()
  Protected req.HttpRequest
  Protected raw.s = "GET / HTTP/1.1" + #CRLF$ +
                    "Host: example.com" + #CRLF$ +
                    "User-Agent: TestAgent/1.0" + #CRLF$ +
                    "Accept: text/html" + #CRLF$ +
                    #CRLF$
  ParseHttpRequest(raw, req)
  Assert(req\IsValid = #True, "Valid request with headers")
  Assert(GetHeader(req\RawHeaders, "host")       = "example.com",    "Host header")
  Assert(GetHeader(req\RawHeaders, "user-agent") = "TestAgent/1.0",  "User-Agent header")
  Assert(GetHeader(req\RawHeaders, "accept")     = "text/html",      "Accept header")
  Assert(GetHeader(req\RawHeaders, "x-missing")  = "",               "Missing header = empty")
EndProcedureUnit

; -----------------------------------------------------------------------
; ParseHttpRequest: URL percent-encoding decoded in path
; -----------------------------------------------------------------------
ProcedureUnit Test_ParseHttpRequest_URLDecoding()
  Protected req.HttpRequest
  Protected raw.s = "GET /hello%20world HTTP/1.1" + #CRLF$ +
                    "Host: localhost" + #CRLF$ +
                    #CRLF$
  ParseHttpRequest(raw, req)
  Assert(req\IsValid = #True,          "Valid request")
  Assert(req\Path    = "/hello world", "URL decoded path — got: '" + req\Path + "'")
EndProcedureUnit

; -----------------------------------------------------------------------
; ParseHttpRequest: malformed / incomplete request returns failure
; -----------------------------------------------------------------------
ProcedureUnit Test_ParseHttpRequest_Malformed()
  Protected req.HttpRequest

  ; No \r\n\r\n terminator
  ParseHttpRequest("GET / HTTP/1.1" + #CRLF$, req)
  Assert(req\IsValid  = #False, "Incomplete request: IsValid = #False")
  Assert(req\ErrorCode = 400,   "Incomplete request: ErrorCode = 400")

  ; Garbage with no request line structure
  ParseHttpRequest("not an http request at all" + #CRLF$ + #CRLF$, req)
  Assert(req\IsValid = #False, "Garbage: IsValid = #False")
EndProcedureUnit
