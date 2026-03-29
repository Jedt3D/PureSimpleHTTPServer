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

; Middleware response buffer — replaces direct SendNetwork* calls inside handlers.
; Filled by middleware, sent by the chain runner (single point of I/O).
; Memory rule: the chain runner always frees *Body after sending.
Structure ResponseBuffer
  StatusCode.i       ; HTTP status code (200, 304, 403, 404, etc.)
  Headers.s          ; Extra response headers (each line ending with #CRLF$)
  *Body              ; Pointer to allocated memory buffer (0 = no body)
  BodySize.i         ; Size of Body in bytes
  Handled.b          ; #True = a handler produced a response
EndStructure

; Per-request state passed through the middleware chain
Structure MiddlewareContext
  ChainIndex.i       ; Current position in the middleware chain
  Connection.i       ; TCP connection ID (for the chain runner's send step)
  *Config.ServerConfig ; Read-only server configuration
  BytesSent.i        ; Filled after send — for access logging
EndStructure

; ResponseWriter prototypes and structure (Phase 6: streaming transform foundation)
Prototype.i ProtoWrite(*self, *data, length.i)    ; write bytes → returns bytes written
Prototype   ProtoFlush(*self)                      ; flush/finalize (close encoder, etc.)

; ResponseWriter — vtable-based writer abstraction for body output.
; PlainWriter sends directly to TCP. Future writers (gzip, brotli) wrap an inner writer.
Structure ResponseWriter
  Write.ProtoWrite          ; function pointer: write bytes
  Flush.ProtoFlush          ; function pointer: flush/finalize
  *inner.ResponseWriter     ; wrapped writer (0 for terminal writers like PlainWriter)
  *ctx                      ; opaque pointer to implementation-specific state
  connection.i              ; TCP connection ID (used by PlainWriter)
EndStructure

; Byte range for HTTP Range requests (used by RangeParser.pbi)
Structure RangeSpec
  Start.i    ; First byte to serve (inclusive)
  End.i      ; Last byte to serve (inclusive)
  IsValid.i  ; #True if range is satisfiable
EndStructure

; Server runtime configuration
Structure ServerConfig
  Port.i             ; Listening port (default: #DEFAULT_PORT)
  RootDirectory.s    ; Document root directory
  IndexFiles.s       ; Comma-separated index file names (e.g. "index.html,index.htm")
  BrowseEnabled.i    ; #True to enable directory listing
  SpaFallback.i      ; #True to serve index.html for all 404s (SPA mode)
  HiddenPatterns.s   ; Comma-separated patterns to hide (e.g. ".git,.env,.DS_Store")
  LogFile.s          ; Path to access log file ("" to disable)
  MaxConnections.i   ; Max concurrent connections (default 100)
  ; --- F-1: log management ---
  ErrorLogFile.s     ; Path to error log file ("" to disable)
  LogLevel.i         ; Min error log level: 1=error 2=warn 3=info 0=none (default: 2)
  LogSizeMB.i        ; Rotate when log exceeds N MB; 0 = disabled (default: 100)
  LogKeepCount.i     ; Max rotated archive files to keep (default: 30)
  LogDaily.i         ; 1 = rotate daily at midnight UTC (default: 1 when log file set)
  PidFile.s          ; Path to PID file (F-3; "" to disable)
  ; --- G: URL rewriting ---
  CleanUrls.i        ; #True: try path.html when extensionless path not found
  RewriteFile.s      ; Path to global rewrite.conf ("" to disable)
  ; --- Phase C: Windows Service ---
  ServiceMode.i      ; #True: run as Windows service (Windows only)
  ServiceName.s      ; Service name (default: "PureSimpleHTTPServer")
  ; --- Phase 4: Manual HTTPS ---
  TlsCert.s          ; Path to PEM certificate file ("" = TLS disabled)
  TlsKey.s           ; Path to PEM private key file ("" = TLS disabled)
  ; --- Phase 5: Auto-TLS ---
  AutoTlsDomain.s    ; Domain for automatic certificate management ("" = disabled)
  ; --- Phase 6: Dynamic gzip ---
  NoGzip.i           ; #True to disable dynamic gzip compression
  ; --- v2.4.0: health check, CORS, security headers ---
  HealthPath.s       ; Health check endpoint path ("" = disabled)
  CorsEnabled.i      ; #True to enable CORS headers
  CorsOrigin.s       ; Specific CORS origin ("" = use "*" when enabled)
  SecurityHeaders.i  ; #True to add security headers to responses
  ; --- v2.5.0: custom error pages, basic auth, cache-control ---
  ErrorPagesDir.s    ; Directory for custom error pages ("" = disabled)
  BasicAuthUser.s    ; Basic auth username ("" = disabled)
  BasicAuthPass.s    ; Basic auth password
  CacheMaxAge.i      ; Cache-Control max-age in seconds (default: 0)
EndStructure
