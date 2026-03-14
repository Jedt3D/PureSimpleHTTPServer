; Config.pbi — server configuration loading and CLI parsing
; Include with: XIncludeFile "Config.pbi"
; Provides: LoadDefaults(), ParseCLI()
;
; Phase E: full CLI argument parsing
; Flags: --port N   --root DIR   --browse   --spa   --log FILE
; Also accepts a bare port number for backward compatibility (e.g. "8080")
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
; Supports: --port N   --root DIR   --browse   --spa   --log FILE
;           bare port number (e.g. "8080") for legacy compatibility
; Returns #True on success, #False if an argument is invalid or unrecognized.
Procedure.i ParseCLI(*cfg.ServerConfig)
  Protected i.i, count.i, param.s, portVal.i
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
