; test_middleware.pb — Unit tests for individual middleware procedures
; Tests middleware in isolation by calling them directly with crafted structures.
EnableExplicit
XIncludeFile "TestCommon.pbi"

; Test fixture paths
Global g_MwRoot.s       ; temp document root directory
Global g_MwIndex.s      ; temp index.html for SPA/IndexFile tests
Global g_MwAbout.s      ; temp about.html for CleanUrls tests
Global g_MwEtagFile.s   ; temp file for ETag tests
Global g_MwRuleFile.s   ; temp rewrite.conf

; Helper: initialize a ServerConfig for tests
Procedure InitTestCfg(*cfg.ServerConfig, root.s)
  *cfg\RootDirectory  = root
  *cfg\IndexFiles     = "index.html"
  *cfg\HiddenPatterns = ".git,.env,.DS_Store"
  *cfg\CleanUrls      = #False
  *cfg\SpaFallback    = #False
  *cfg\BrowseEnabled  = #False
EndProcedure

; Helper: initialize an empty ResponseBuffer
Procedure InitResp(*resp.ResponseBuffer)
  *resp\StatusCode = 0
  *resp\Headers    = ""
  *resp\Body       = 0
  *resp\BodySize   = 0
  *resp\Handled    = #False
EndProcedure

; Helper: initialize a MiddlewareContext (chain set to empty so CallNext → #False)
Procedure InitMCtx(*mCtx.MiddlewareContext, *cfg.ServerConfig)
  *mCtx\ChainIndex = 0    ; middleware under test is at position 0
  *mCtx\Connection = 0
  *mCtx\Config     = *cfg
  *mCtx\BytesSent  = 0
EndProcedure

; Helper: free resp\Body if allocated
Procedure FreeResp(*resp.ResponseBuffer)
  If *resp\Body
    FreeMemory(*resp\Body)
    *resp\Body = 0
  EndIf
EndProcedure

ProcedureUnitStartup mw_setup()
  Protected f.i

  g_MwRoot     = GetTemporaryDirectory() + "pshs_mw_test/"
  g_MwIndex    = g_MwRoot + "index.html"
  g_MwAbout    = g_MwRoot + "about.html"
  g_MwEtagFile = g_MwRoot + "etag_test.txt"
  g_MwRuleFile = GetTemporaryDirectory() + "pshs_mw_rules.conf"

  CreateDirectory(g_MwRoot)

  f = CreateFile(#PB_Any, g_MwIndex)
  If f : WriteStringN(f, "<html>index</html>") : CloseFile(f) : EndIf

  f = CreateFile(#PB_Any, g_MwAbout)
  If f : WriteStringN(f, "<html>about</html>") : CloseFile(f) : EndIf

  f = CreateFile(#PB_Any, g_MwEtagFile)
  If f : WriteStringN(f, "etag test content for middleware") : CloseFile(f) : EndIf

  ; Ensure chain is empty so CallNext returns #False (clean pass-through)
  g_ChainCount = 0

  InitRewriteEngine()
EndProcedureUnit

ProcedureUnitShutdown mw_teardown()
  CleanupRewriteEngine()
  DeleteFile(g_MwIndex)
  DeleteFile(g_MwAbout)
  DeleteFile(g_MwEtagFile)
  DeleteFile(g_MwRuleFile)
EndProcedureUnit

; ── Middleware_HiddenPath ───────────────────────────────────────────────────

ProcedureUnit HiddenPath_GitBlocked()
  Protected cfg.ServerConfig : InitTestCfg(@cfg, g_MwRoot)
  Protected req.HttpRequest  : req\Method = "GET" : req\Path = "/.git/config" : req\RawHeaders = ""
  Protected resp.ResponseBuffer : InitResp(@resp)
  Protected mCtx.MiddlewareContext : InitMCtx(@mCtx, @cfg)

  Protected result.i = Middleware_HiddenPath(@req, @resp, @mCtx)
  Assert(result = #True, "should handle hidden path")
  Assert(resp\StatusCode = #HTTP_403, "should be 403; got: " + Str(resp\StatusCode))
  Assert(resp\Handled = #True, "should be marked handled")
  FreeResp(@resp)
EndProcedureUnit

ProcedureUnit HiddenPath_EnvBlocked()
  Protected cfg.ServerConfig : InitTestCfg(@cfg, g_MwRoot)
  Protected req.HttpRequest  : req\Method = "GET" : req\Path = "/.env" : req\RawHeaders = ""
  Protected resp.ResponseBuffer : InitResp(@resp)
  Protected mCtx.MiddlewareContext : InitMCtx(@mCtx, @cfg)

  Protected result.i = Middleware_HiddenPath(@req, @resp, @mCtx)
  Assert(result = #True, "should block .env")
  Assert(resp\StatusCode = #HTTP_403, "should be 403")
  FreeResp(@resp)
EndProcedureUnit

ProcedureUnit HiddenPath_NormalPassThrough()
  Protected cfg.ServerConfig : InitTestCfg(@cfg, g_MwRoot)
  Protected req.HttpRequest  : req\Method = "GET" : req\Path = "/index.html" : req\RawHeaders = ""
  Protected resp.ResponseBuffer : InitResp(@resp)
  Protected mCtx.MiddlewareContext : InitMCtx(@mCtx, @cfg)

  Protected result.i = Middleware_HiddenPath(@req, @resp, @mCtx)
  Assert(result = #False, "should pass through normal path")
  Assert(resp\Handled = #False, "resp should not be handled")
  FreeResp(@resp)
EndProcedureUnit

ProcedureUnit HiddenPath_EmptyPatterns_PassThrough()
  Protected cfg.ServerConfig : InitTestCfg(@cfg, g_MwRoot)
  cfg\HiddenPatterns = ""
  Protected req.HttpRequest  : req\Method = "GET" : req\Path = "/.git/config" : req\RawHeaders = ""
  Protected resp.ResponseBuffer : InitResp(@resp)
  Protected mCtx.MiddlewareContext : InitMCtx(@mCtx, @cfg)

  Protected result.i = Middleware_HiddenPath(@req, @resp, @mCtx)
  Assert(result = #False, "should pass through when no hidden patterns configured")
  FreeResp(@resp)
EndProcedureUnit

; ── Middleware_ETag304 ─────────────────────────────────────────────────────

ProcedureUnit ETag304_MatchReturns304()
  Protected cfg.ServerConfig : InitTestCfg(@cfg, g_MwRoot)
  ; Compute real ETag for the test file
  Protected etag.s = BuildETag(g_MwEtagFile)
  Assert(etag <> "", "precondition: etag_test.txt must have an ETag")

  Protected req.HttpRequest
  req\Method = "GET" : req\Path = "/etag_test.txt"
  req\RawHeaders = "If-None-Match: " + etag
  Protected resp.ResponseBuffer : InitResp(@resp)
  Protected mCtx.MiddlewareContext : InitMCtx(@mCtx, @cfg)

  Protected result.i = Middleware_ETag304(@req, @resp, @mCtx)
  Assert(result = #True, "should handle ETag match")
  Assert(resp\StatusCode = #HTTP_304, "should be 304; got: " + Str(resp\StatusCode))
  Assert(resp\Handled = #True, "should be marked handled")
  Assert(resp\Body = 0, "304 should have no body")
  Assert(resp\BodySize = 0, "304 should have zero body size")
  FreeResp(@resp)
EndProcedureUnit

ProcedureUnit ETag304_MismatchPassThrough()
  Protected cfg.ServerConfig : InitTestCfg(@cfg, g_MwRoot)
  Protected req.HttpRequest
  req\Method = "GET" : req\Path = "/etag_test.txt"
  req\RawHeaders = "If-None-Match: " + Chr(34) + "wrong-etag" + Chr(34)
  Protected resp.ResponseBuffer : InitResp(@resp)
  Protected mCtx.MiddlewareContext : InitMCtx(@mCtx, @cfg)

  Protected result.i = Middleware_ETag304(@req, @resp, @mCtx)
  Assert(result = #False, "should pass through on ETag mismatch")
  Assert(resp\Handled = #False, "resp should not be handled")
  FreeResp(@resp)
EndProcedureUnit

ProcedureUnit ETag304_NoHeaderPassThrough()
  Protected cfg.ServerConfig : InitTestCfg(@cfg, g_MwRoot)
  Protected req.HttpRequest
  req\Method = "GET" : req\Path = "/etag_test.txt" : req\RawHeaders = ""
  Protected resp.ResponseBuffer : InitResp(@resp)
  Protected mCtx.MiddlewareContext : InitMCtx(@mCtx, @cfg)

  Protected result.i = Middleware_ETag304(@req, @resp, @mCtx)
  Assert(result = #False, "should pass through when no If-None-Match header")
  FreeResp(@resp)
EndProcedureUnit

; ── Middleware_Rewrite ──────────────────────────────────────────────────────

ProcedureUnit Rewrite_Redirect()
  Protected cfg.ServerConfig : InitTestCfg(@cfg, g_MwRoot)
  ; Load a redirect rule
  Protected f.i = CreateFile(#PB_Any, g_MwRuleFile)
  If f : WriteString(f, ~"redir /old /new 301\n", #PB_Ascii) : CloseFile(f) : EndIf
  LoadGlobalRules(g_MwRuleFile)

  Protected req.HttpRequest : req\Method = "GET" : req\Path = "/old" : req\RawHeaders = ""
  Protected resp.ResponseBuffer : InitResp(@resp)
  Protected mCtx.MiddlewareContext : InitMCtx(@mCtx, @cfg)

  Protected result.i = Middleware_Rewrite(@req, @resp, @mCtx)
  Assert(result = #True, "redirect should be handled")
  Assert(resp\StatusCode = 301, "should be 301; got: " + Str(resp\StatusCode))
  Assert(FindString(resp\Headers, "/new") > 0, "Location header should contain /new")
  Assert(resp\Handled = #True, "should be marked handled")

  LoadGlobalRules("")   ; clear
  FreeResp(@resp)
EndProcedureUnit

ProcedureUnit Rewrite_PathRewrite()
  Protected cfg.ServerConfig : InitTestCfg(@cfg, g_MwRoot)
  Protected f.i = CreateFile(#PB_Any, g_MwRuleFile)
  If f : WriteString(f, ~"rewrite /old /new.html\n", #PB_Ascii) : CloseFile(f) : EndIf
  LoadGlobalRules(g_MwRuleFile)

  Protected req.HttpRequest : req\Method = "GET" : req\Path = "/old" : req\RawHeaders = ""
  Protected resp.ResponseBuffer : InitResp(@resp)
  Protected mCtx.MiddlewareContext : InitMCtx(@mCtx, @cfg)

  Protected result.i = Middleware_Rewrite(@req, @resp, @mCtx)
  ; Rewrite passes through (CallNext) — result is #False (empty chain)
  Assert(result = #False, "rewrite should pass through to chain")
  Assert(req\Path = "/new.html", "path should be rewritten; got: " + req\Path)

  LoadGlobalRules("")   ; clear
  FreeResp(@resp)
EndProcedureUnit

ProcedureUnit Rewrite_NoMatch_PassThrough()
  Protected cfg.ServerConfig : InitTestCfg(@cfg, g_MwRoot)
  ; No rules loaded — nothing should match
  LoadGlobalRules("")

  Protected req.HttpRequest : req\Method = "GET" : req\Path = "/whatever" : req\RawHeaders = ""
  Protected resp.ResponseBuffer : InitResp(@resp)
  Protected mCtx.MiddlewareContext : InitMCtx(@mCtx, @cfg)

  Protected result.i = Middleware_Rewrite(@req, @resp, @mCtx)
  Assert(result = #False, "no-match should pass through")
  Assert(req\Path = "/whatever", "path should be unchanged")
  FreeResp(@resp)
EndProcedureUnit

; ── Middleware_CleanUrls ───────────────────────────────────────────────────

ProcedureUnit CleanUrls_ResolvesHtml()
  Protected cfg.ServerConfig : InitTestCfg(@cfg, g_MwRoot)
  cfg\CleanUrls = #True
  ; about.html exists in g_MwRoot — /about should resolve to /about.html
  Protected req.HttpRequest : req\Method = "GET" : req\Path = "/about" : req\RawHeaders = ""
  Protected resp.ResponseBuffer : InitResp(@resp)
  Protected mCtx.MiddlewareContext : InitMCtx(@mCtx, @cfg)

  Protected result.i = Middleware_CleanUrls(@req, @resp, @mCtx)
  Assert(req\Path = "/about.html", "should rewrite to .html; got: " + req\Path)
  FreeResp(@resp)
EndProcedureUnit

ProcedureUnit CleanUrls_DisabledPassThrough()
  Protected cfg.ServerConfig : InitTestCfg(@cfg, g_MwRoot)
  cfg\CleanUrls = #False
  Protected req.HttpRequest : req\Method = "GET" : req\Path = "/about" : req\RawHeaders = ""
  Protected resp.ResponseBuffer : InitResp(@resp)
  Protected mCtx.MiddlewareContext : InitMCtx(@mCtx, @cfg)

  Protected result.i = Middleware_CleanUrls(@req, @resp, @mCtx)
  Assert(req\Path = "/about", "path should be unchanged when disabled; got: " + req\Path)
  FreeResp(@resp)
EndProcedureUnit

ProcedureUnit CleanUrls_WithExtensionSkipped()
  Protected cfg.ServerConfig : InitTestCfg(@cfg, g_MwRoot)
  cfg\CleanUrls = #True
  Protected req.HttpRequest : req\Method = "GET" : req\Path = "/style.css" : req\RawHeaders = ""
  Protected resp.ResponseBuffer : InitResp(@resp)
  Protected mCtx.MiddlewareContext : InitMCtx(@mCtx, @cfg)

  Protected result.i = Middleware_CleanUrls(@req, @resp, @mCtx)
  Assert(req\Path = "/style.css", "paths with extension should not be touched; got: " + req\Path)
  FreeResp(@resp)
EndProcedureUnit

; ── Middleware_SpaFallback ─────────────────────────────────────────────────

ProcedureUnit SpaFallback_RewritesToIndex()
  Protected cfg.ServerConfig : InitTestCfg(@cfg, g_MwRoot)
  cfg\SpaFallback = #True
  ; /nonexistent does not exist on disk — should rewrite to /index.html
  Protected req.HttpRequest : req\Method = "GET" : req\Path = "/nonexistent" : req\RawHeaders = ""
  Protected resp.ResponseBuffer : InitResp(@resp)
  Protected mCtx.MiddlewareContext : InitMCtx(@mCtx, @cfg)

  Protected result.i = Middleware_SpaFallback(@req, @resp, @mCtx)
  Assert(req\Path = "/index.html", "should rewrite to /index.html; got: " + req\Path)
  FreeResp(@resp)
EndProcedureUnit

ProcedureUnit SpaFallback_DisabledPassThrough()
  Protected cfg.ServerConfig : InitTestCfg(@cfg, g_MwRoot)
  cfg\SpaFallback = #False
  Protected req.HttpRequest : req\Method = "GET" : req\Path = "/nonexistent" : req\RawHeaders = ""
  Protected resp.ResponseBuffer : InitResp(@resp)
  Protected mCtx.MiddlewareContext : InitMCtx(@mCtx, @cfg)

  Protected result.i = Middleware_SpaFallback(@req, @resp, @mCtx)
  Assert(req\Path = "/nonexistent", "path should be unchanged when disabled; got: " + req\Path)
  FreeResp(@resp)
EndProcedureUnit

ProcedureUnit SpaFallback_ExistingFileUntouched()
  Protected cfg.ServerConfig : InitTestCfg(@cfg, g_MwRoot)
  cfg\SpaFallback = #True
  ; /index.html exists — should NOT be rewritten
  Protected req.HttpRequest : req\Method = "GET" : req\Path = "/index.html" : req\RawHeaders = ""
  Protected resp.ResponseBuffer : InitResp(@resp)
  Protected mCtx.MiddlewareContext : InitMCtx(@mCtx, @cfg)

  Protected result.i = Middleware_SpaFallback(@req, @resp, @mCtx)
  Assert(req\Path = "/index.html", "existing file should not be rewritten; got: " + req\Path)
  FreeResp(@resp)
EndProcedureUnit
