; test_config.pb — Unit tests for Config.pbi
; Phase E — placeholder (full tests written when Config is implemented)
;
; Phase E tests will cover:
;   LoadDefaults() -> port=8080, browse=off, spa=off, maxConnections=100
;   ParseCLI() with valid port override
;   ParseCLI() with invalid port -> returns #False
EnableExplicit
XIncludeFile "TestCommon.pbi"

ProcedureUnit Placeholder_Config()
  ; Smoke test: LoadDefaults fills expected values
  Protected cfg.ServerConfig
  LoadDefaults(cfg)
  Assert(cfg\Port          = 8080,  "Default port is 8080")
  Assert(cfg\BrowseEnabled = #False, "Browse disabled by default")
  Assert(cfg\SpaFallback   = #False, "SPA fallback disabled by default")
  Assert(cfg\MaxConnections = 100,   "Default max connections = 100")
EndProcedureUnit
