; Types.pbi — shared structure definitions for PureSimpleHTTPServer
; Include with: XIncludeFile "Types.pbi"
; Dependencies (managed by main.pb and tests/TestCommon.pbi): Global.pbi

; HTTP request parsed from raw TCP data
Structure HttpRequest
  Method.s           ; HTTP method: "GET", "POST", "HEAD", etc.
  Path.s             ; Decoded, normalized URL path (no query string)
  QueryString.s      ; Raw query string (content after ? in request target)
  Version.s          ; HTTP version: "HTTP/1.1" or "HTTP/1.0"
  RawHeaders.s       ; Raw header lines (after request line, no trailing blank line)
  ContentLength.i    ; Value of Content-Length header, or 0
  Body.s             ; Request body (POST data), if any
  IsValid.i          ; #True if parsed successfully
  ErrorCode.i        ; HTTP status code on failure (typically 400)
EndStructure

; HTTP response to be sent to a client
Structure HttpResponse
  StatusCode.i       ; HTTP status code
  StatusText.s       ; HTTP reason phrase
  ExtraHeaders.s     ; Additional headers (each line ending with #CRLF$)
  Body.s             ; Response body as string (for text responses)
  BodyBuffer.i       ; Pointer to binary buffer (for file responses; 0 if unused)
  BodyBufferSize.i   ; Size of BodyBuffer in bytes
EndStructure

; Server runtime configuration
Structure ServerConfig
  Port.i             ; Listening port (default: #DEFAULT_PORT)
  RootDirectory.s    ; Document root directory
  IndexFiles.s       ; Comma-separated index file names (e.g. "index.html,index.htm")
  BrowseEnabled.i    ; #True to enable directory listing
  SpaFallback.i      ; #True to serve index.html for all 404s (SPA mode)
  HiddenPatterns.s   ; Comma-separated patterns to hide (e.g. ".git,.env,*.bak")
  LogFile.s          ; Path to access log file ("" to disable)
  MaxConnections.i   ; Max concurrent connections (used in Phase E; default 100)
EndStructure
