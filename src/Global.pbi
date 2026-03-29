; Global.pbi — application-wide constants, enumerations, version
; Include with: XIncludeFile "Global.pbi"
EnableExplicit

; --- Application identity ---
#APP_NAME    = "PureSimpleHTTPServer"
#APP_VERSION = "2.5.0"

; --- HTTP status codes ---
#HTTP_200 = 200   ; OK
#HTTP_204 = 204   ; No Content
#HTTP_206 = 206   ; Partial Content
#HTTP_301 = 301   ; Moved Permanently
#HTTP_302 = 302   ; Found (temporary redirect)
#HTTP_304 = 304   ; Not Modified
#HTTP_400 = 400   ; Bad Request
#HTTP_401 = 401   ; Unauthorized
#HTTP_403 = 403   ; Forbidden
#HTTP_404 = 404   ; Not Found
#HTTP_416 = 416   ; Range Not Satisfiable
#HTTP_500 = 500   ; Internal Server Error

; --- Buffer sizes ---
#RECV_BUFFER_SIZE = 65536  ; 64 KB receive buffer per connection
#SEND_CHUNK_SIZE  = 65536  ; 64 KB file send chunk size
#MAX_HEADER_SIZE  = 8192   ; 8 KB maximum request header block

; --- Path separator (compile-time, zero cost) ---
CompilerIf #PB_Compiler_OS = #PB_OS_Windows
  #SEP = "\"
CompilerElse
  #SEP = "/"
CompilerEndIf

; --- Server defaults ---
#DEFAULT_PORT  = 8080
#DEFAULT_INDEX = "index.html"
