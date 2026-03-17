; Config.pbi — server configuration loading and CLI parsing
; Include with: XIncludeFile "Config.pbi"
; Provides: LoadDefaults(), ParseCLI()
;
; Phase F-1: new flags --error-log, --log-level, --log-size, --log-keep,
;            --no-log-daily, --pid-file added alongside existing Phase E flags
; Phase G:   new flags --clean-urls, --rewrite FILE
; Phase C:   new flags --service, --service-name (Windows service mode)
;
; Flags: --port N   --root DIR   --browse   --spa   --log FILE
;        --error-log FILE   --log-level LEVEL   --log-size MB
;        --log-keep N       --no-log-daily       --pid-file FILE
;        --clean-urls       --rewrite FILE
;        --service          --service-name NAME
; Also accepts a bare port number for backward compatibility (e.g. "8080")
; Dependencies (managed by main.pb and tests/TestCommon.pbi): Global.pbi, Types.pbi

; ReadPEMFile(path.s) — read an entire PEM file into a string
; Returns the file content (with line breaks preserved), or "" on error.
Procedure.s ReadPEMFile(path.s)
  Protected file.i, size.i, content.s
  If FileSize(path) < 0
    ProcedureReturn ""
  EndIf
  file = ReadFile(#PB_Any, path)
  If file = 0
    ProcedureReturn ""
  EndIf
  size = Lof(file)
  If size > 0
    content = ReadString(file, #PB_Ascii | #PB_File_IgnoreEOL, size)
  EndIf
  CloseFile(file)
  ProcedureReturn content
EndProcedure

; LoadDefaults(*cfg.ServerConfig) — populate config with default values
Procedure LoadDefaults(*cfg.ServerConfig)
  *cfg\Port           = #DEFAULT_PORT
  *cfg\RootDirectory  = GetPathPart(ProgramFilename()) + "wwwroot"
  *cfg\IndexFiles     = "index.html,index.htm"
  *cfg\BrowseEnabled  = #False
  *cfg\SpaFallback    = #False
  *cfg\HiddenPatterns = ".git,.env,.DS_Store"
  *cfg\LogFile        = ""
  *cfg\MaxConnections = 100
  ; F-1 log management defaults
  *cfg\ErrorLogFile   = ""
  *cfg\LogLevel       = 2    ; warn
  *cfg\LogSizeMB      = 100  ; 100 MB rotation threshold
  *cfg\LogKeepCount   = 30   ; keep 30 archives
  *cfg\LogDaily       = 1    ; daily rotation on by default (when log file is set)
  *cfg\PidFile        = ""
  ; G: URL rewriting defaults
  *cfg\CleanUrls      = #False
  *cfg\RewriteFile    = ""
  ; Phase C: Windows Service defaults
  *cfg\ServiceMode    = #False
  *cfg\ServiceName    = "PureSimpleHTTPServer"
  ; Phase 4+5: TLS defaults
  *cfg\TlsCert        = ""
  *cfg\TlsKey         = ""
  *cfg\AutoTlsDomain  = ""
  ; Phase 6: gzip default
  *cfg\NoGzip         = #False
  ; v2.4.0: health check, CORS, security headers
  *cfg\HealthPath     = ""
  *cfg\CorsEnabled    = #False
  *cfg\CorsOrigin     = ""
  *cfg\SecurityHeaders = #False
EndProcedure

; ParseLogLevel(s.s) — convert level name to integer (0 if unrecognized)
; Returns: none=0  error=1  warn=2  info=3
Procedure.i ParseLogLevel(s.s)
  Select LCase(s)
    Case "none"  : ProcedureReturn 0
    Case "error" : ProcedureReturn 1
    Case "warn"  : ProcedureReturn 2
    Case "info"  : ProcedureReturn 3
    Default      : ProcedureReturn -1  ; unrecognized
  EndSelect
EndProcedure

; ParseCLI(*cfg.ServerConfig) — override config from command-line arguments
; Returns #True on success, #False if an argument is invalid or unrecognized.
Procedure.i ParseCLI(*cfg.ServerConfig)
  Protected i.i, count.i, param.s, portVal.i, intVal.i, lvl.i

  count = CountProgramParameters()
  i = 0
  While i < count
    param = ProgramParameter(i)

    If param = "--port"
      i + 1
      If i >= count : ProcedureReturn #False : EndIf
      portVal = Val(ProgramParameter(i))
      If portVal < 1 Or portVal > 65535 : ProcedureReturn #False : EndIf
      *cfg\Port = portVal

    ElseIf param = "--root"
      i + 1
      If i >= count : ProcedureReturn #False : EndIf
      *cfg\RootDirectory = ProgramParameter(i)

    ElseIf param = "--browse"
      *cfg\BrowseEnabled = #True

    ElseIf param = "--spa"
      *cfg\SpaFallback = #True

    ElseIf param = "--log"
      i + 1
      If i >= count : ProcedureReturn #False : EndIf
      *cfg\LogFile = ProgramParameter(i)

    ElseIf param = "--error-log"
      i + 1
      If i >= count : ProcedureReturn #False : EndIf
      *cfg\ErrorLogFile = ProgramParameter(i)

    ElseIf param = "--log-level"
      i + 1
      If i >= count : ProcedureReturn #False : EndIf
      lvl = ParseLogLevel(ProgramParameter(i))
      If lvl = -1 : ProcedureReturn #False : EndIf
      *cfg\LogLevel = lvl

    ElseIf param = "--log-size"
      i + 1
      If i >= count : ProcedureReturn #False : EndIf
      intVal = Val(ProgramParameter(i))
      If intVal < 0 : ProcedureReturn #False : EndIf
      *cfg\LogSizeMB = intVal

    ElseIf param = "--log-keep"
      i + 1
      If i >= count : ProcedureReturn #False : EndIf
      intVal = Val(ProgramParameter(i))
      If intVal < 0 : ProcedureReturn #False : EndIf
      *cfg\LogKeepCount = intVal

    ElseIf param = "--no-log-daily"
      *cfg\LogDaily = 0

    ElseIf param = "--pid-file"
      i + 1
      If i >= count : ProcedureReturn #False : EndIf
      *cfg\PidFile = ProgramParameter(i)

    ElseIf param = "--clean-urls"
      *cfg\CleanUrls = #True

    ElseIf param = "--rewrite"
      i + 1
      If i >= count : ProcedureReturn #False : EndIf
      *cfg\RewriteFile = ProgramParameter(i)

    ElseIf param = "--no-gzip"
      *cfg\NoGzip = #True

    ElseIf param = "--tls-cert"
      i + 1
      If i >= count : ProcedureReturn #False : EndIf
      *cfg\TlsCert = ProgramParameter(i)

    ElseIf param = "--tls-key"
      i + 1
      If i >= count : ProcedureReturn #False : EndIf
      *cfg\TlsKey = ProgramParameter(i)

    ElseIf param = "--auto-tls"
      i + 1
      If i >= count : ProcedureReturn #False : EndIf
      *cfg\AutoTlsDomain = ProgramParameter(i)

    ElseIf param = "--health"
      i + 1
      If i >= count : ProcedureReturn #False : EndIf
      *cfg\HealthPath = ProgramParameter(i)

    ElseIf param = "--cors"
      *cfg\CorsEnabled = #True

    ElseIf param = "--cors-origin"
      i + 1
      If i >= count : ProcedureReturn #False : EndIf
      *cfg\CorsEnabled = #True
      *cfg\CorsOrigin = ProgramParameter(i)

    ElseIf param = "--security-headers"
      *cfg\SecurityHeaders = #True

    ElseIf param = "--service"
      *cfg\ServiceMode = #True

    ElseIf param = "--service-name"
      i + 1
      If i >= count : ProcedureReturn #False : EndIf
      *cfg\ServiceName = ProgramParameter(i)

    ElseIf Val(param) > 0
      ; Legacy: bare port number (e.g. "8080")
      portVal = Val(param)
      If portVal < 1 Or portVal > 65535 : ProcedureReturn #False : EndIf
      *cfg\Port = portVal

    Else
      ProcedureReturn #False  ; Unrecognized argument

    EndIf

    i + 1
  Wend

  ProcedureReturn #True
EndProcedure
