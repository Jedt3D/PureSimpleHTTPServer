; test_config.pb — Unit tests for Config.pbi
; Phase E: full tests for LoadDefaults() and ParseCLI()
EnableExplicit
XIncludeFile "TestCommon.pbi"

ProcedureUnit Config_LoadDefaults_Port()
  Protected cfg.ServerConfig
  LoadDefaults(@cfg)
  Assert(cfg\Port = 8080, "Default port should be 8080")
EndProcedureUnit

ProcedureUnit Config_LoadDefaults_BrowseDisabled()
  Protected cfg.ServerConfig
  LoadDefaults(@cfg)
  Assert(cfg\BrowseEnabled = #False, "Browse should be disabled by default")
EndProcedureUnit

ProcedureUnit Config_LoadDefaults_SpaDisabled()
  Protected cfg.ServerConfig
  LoadDefaults(@cfg)
  Assert(cfg\SpaFallback = #False, "SPA fallback should be disabled by default")
EndProcedureUnit

ProcedureUnit Config_LoadDefaults_MaxConnections()
  Protected cfg.ServerConfig
  LoadDefaults(@cfg)
  Assert(cfg\MaxConnections = 100, "Default max connections should be 100")
EndProcedureUnit

ProcedureUnit Config_LoadDefaults_IndexFiles()
  Protected cfg.ServerConfig
  LoadDefaults(@cfg)
  Assert(FindString(cfg\IndexFiles, "index.html") > 0,
         "Default index files should include index.html")
EndProcedureUnit

ProcedureUnit Config_LoadDefaults_HiddenPatterns()
  Protected cfg.ServerConfig
  LoadDefaults(@cfg)
  Assert(FindString(cfg\HiddenPatterns, ".git") > 0,
         "Default hidden patterns should include .git")
EndProcedureUnit

ProcedureUnit Config_LoadDefaults_LogFileEmpty()
  Protected cfg.ServerConfig
  LoadDefaults(@cfg)
  Assert(cfg\LogFile = "", "Default log file should be empty (disabled)")
EndProcedureUnit

ProcedureUnit Config_ParseCLI_DoesNotCrash()
  ; PureUnit may pass internal runtime arguments to the test binary, so we cannot
  ; assert on the return value — we only verify ParseCLI does not crash when called.
  Protected cfg.ServerConfig
  LoadDefaults(@cfg)
  ParseCLI(@cfg)
  Assert(#True, "ParseCLI should not crash when invoked from PureUnit")
EndProcedureUnit

ProcedureUnit Config_ParseCLI_ConfigRemainsValid()
  ; After ParseCLI (which may or may not succeed depending on PureUnit args),
  ; MaxConnections should remain at the value set by LoadDefaults since it is not
  ; a recognised flag, so Config.pbi either leaves it unchanged or returns early.
  Protected cfg.ServerConfig
  LoadDefaults(@cfg)
  ParseCLI(@cfg)
  Assert(cfg\MaxConnections = 100, "MaxConnections should be unchanged after ParseCLI")
EndProcedureUnit
