; Config.pbi — server configuration loading and CLI parsing
; Include with: XIncludeFile "Config.pbi"
; Provides: LoadDefaults(), ParseCLI()
;
; Phase E: full CLI argument parsing
; Phase A: LoadDefaults() only
; Dependencies (managed by main.pb and tests/TestCommon.pbi): Global.pbi, Types.pbi

; LoadDefaults(*cfg.ServerConfig) — populate config with default values
Procedure LoadDefaults(*cfg.ServerConfig)
  *cfg\Port           = #DEFAULT_PORT
  *cfg\RootDirectory  = GetCurrentDirectory()
  *cfg\IndexFiles     = "index.html,index.htm"
  *cfg\BrowseEnabled  = #False
  *cfg\SpaFallback    = #False
  *cfg\HiddenPatterns = ".git,.env,.DS_Store"
  *cfg\LogFile        = ""
  *cfg\MaxConnections = 100
EndProcedure

; ParseCLI(*cfg.ServerConfig) — override config from command-line arguments
; Phase E: implement --port, --root, --browse, --spa, --log, etc.
; Returns #True on success, #False if arguments are invalid
Procedure.i ParseCLI(*cfg.ServerConfig)
  ; Phase A: minimal — just read port if provided as first arg
  If CountProgramParameters() >= 1
    Protected p.i = Val(ProgramParameter(0))
    If p > 0 And p <= 65535
      *cfg\Port = p
    Else
      ProcedureReturn #False
    EndIf
  EndIf
  ProcedureReturn #True
EndProcedure
