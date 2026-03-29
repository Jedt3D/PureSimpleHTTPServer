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
Global g_ErrPagesDir.s  ; temp error pages directory

; Helper: initialize a ServerConfig for tests
Procedure InitTestCfg(*cfg.ServerConfig, root.s)
  *cfg\RootDirectory  = root
  *cfg\IndexFiles     = "index.html"
  *cfg\HiddenPatterns = ".git,.env,.DS_Store"
  *cfg\CleanUrls      = #False
  *cfg\SpaFallback    = #False
  *cfg\BrowseEnabled  = #False
  *cfg\HealthPath     = ""
  *cfg\CorsEnabled    = #False
  *cfg\CorsOrigin     = ""
  *cfg\SecurityHeaders = #False
  *cfg\ErrorPagesDir  = ""
  *cfg\BasicAuthUser  = ""
  *cfg\BasicAuthPass  = ""
  *cfg\CacheMaxAge    = 0
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
  g_ErrPagesDir = GetTemporaryDirectory() + "pshs_err_pages/"

  CreateDirectory(g_MwRoot)
  CreateDirectory(g_ErrPagesDir)

  f = CreateFile(#PB_Any, g_MwIndex)
  If f : WriteStringN(f, "<html>index</html>") : CloseFile(f) : EndIf

  f = CreateFile(#PB_Any, g_MwAbout)
  If f : WriteStringN(f, "<html>about</html>") : CloseFile(f) : EndIf

  f = CreateFile(#PB_Any, g_MwEtagFile)
  If f : WriteStringN(f, "etag test content for middleware") : CloseFile(f) : EndIf

  ; Custom error pages for FillErrorResponse tests
  f = CreateFile(#PB_Any, g_ErrPagesDir + "404.html")
  If f : WriteString(f, "<h1>Custom Not Found</h1>", #PB_Ascii) : CloseFile(f) : EndIf

  f = CreateFile(#PB_Any, g_ErrPagesDir + "403.html")
  If f : WriteString(f, "<h1>Custom Forbidden</h1>", #PB_Ascii) : CloseFile(f) : EndIf

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
  DeleteFile(g_ErrPagesDir + "404.html")
  DeleteFile(g_ErrPagesDir + "403.html")
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

; ── Middleware_HealthCheck ────────────────────────────────────────────────

ProcedureUnit HealthCheck_MatchReturns200Json()
  Protected cfg.ServerConfig : InitTestCfg(@cfg, g_MwRoot)
  cfg\HealthPath = "/healthz"
  Protected req.HttpRequest : req\Method = "GET" : req\Path = "/healthz" : req\RawHeaders = ""
  Protected resp.ResponseBuffer : InitResp(@resp)
  Protected mCtx.MiddlewareContext : InitMCtx(@mCtx, @cfg)

  Protected result.i = Middleware_HealthCheck(@req, @resp, @mCtx)
  Assert(result = #True, "should handle health check path")
  Assert(resp\StatusCode = #HTTP_200, "should be 200; got: " + Str(resp\StatusCode))
  Assert(resp\Handled = #True, "should be marked handled")
  Assert(FindString(resp\Headers, "application/json") > 0, "Content-Type should be JSON")
  FreeResp(@resp)
EndProcedureUnit

ProcedureUnit HealthCheck_NonMatchPassThrough()
  Protected cfg.ServerConfig : InitTestCfg(@cfg, g_MwRoot)
  cfg\HealthPath = "/healthz"
  Protected req.HttpRequest : req\Method = "GET" : req\Path = "/other" : req\RawHeaders = ""
  Protected resp.ResponseBuffer : InitResp(@resp)
  Protected mCtx.MiddlewareContext : InitMCtx(@mCtx, @cfg)

  Protected result.i = Middleware_HealthCheck(@req, @resp, @mCtx)
  Assert(result = #False, "should pass through non-matching path")
  Assert(resp\Handled = #False, "resp should not be handled")
  FreeResp(@resp)
EndProcedureUnit

ProcedureUnit HealthCheck_DisabledPassThrough()
  Protected cfg.ServerConfig : InitTestCfg(@cfg, g_MwRoot)
  ; HealthPath = "" (disabled by default)
  Protected req.HttpRequest : req\Method = "GET" : req\Path = "/healthz" : req\RawHeaders = ""
  Protected resp.ResponseBuffer : InitResp(@resp)
  Protected mCtx.MiddlewareContext : InitMCtx(@mCtx, @cfg)

  Protected result.i = Middleware_HealthCheck(@req, @resp, @mCtx)
  Assert(result = #False, "should pass through when disabled")
  Assert(resp\Handled = #False, "resp should not be handled")
  FreeResp(@resp)
EndProcedureUnit

ProcedureUnit HealthCheck_CustomPath()
  Protected cfg.ServerConfig : InitTestCfg(@cfg, g_MwRoot)
  cfg\HealthPath = "/_health"
  Protected req.HttpRequest : req\Method = "GET" : req\Path = "/_health" : req\RawHeaders = ""
  Protected resp.ResponseBuffer : InitResp(@resp)
  Protected mCtx.MiddlewareContext : InitMCtx(@mCtx, @cfg)

  Protected result.i = Middleware_HealthCheck(@req, @resp, @mCtx)
  Assert(result = #True, "should handle custom health path")
  Assert(resp\StatusCode = #HTTP_200, "should be 200; got: " + Str(resp\StatusCode))
  FreeResp(@resp)
EndProcedureUnit

; ── Middleware_Cors ───────────────────────────────────────────────────────

ProcedureUnit Cors_OptionsReturns204WithWildcard()
  Protected cfg.ServerConfig : InitTestCfg(@cfg, g_MwRoot)
  cfg\CorsEnabled = #True
  Protected req.HttpRequest : req\Method = "OPTIONS" : req\Path = "/" : req\RawHeaders = ""
  Protected resp.ResponseBuffer : InitResp(@resp)
  Protected mCtx.MiddlewareContext : InitMCtx(@mCtx, @cfg)

  Protected result.i = Middleware_Cors(@req, @resp, @mCtx)
  Assert(result = #True, "OPTIONS should be handled")
  Assert(resp\StatusCode = #HTTP_204, "should be 204; got: " + Str(resp\StatusCode))
  Assert(resp\Handled = #True, "should be marked handled")
  Assert(FindString(resp\Headers, "Access-Control-Allow-Origin: *") > 0, "should have wildcard origin")
  Assert(FindString(resp\Headers, "Access-Control-Allow-Methods:") > 0, "should have Allow-Methods")
  FreeResp(@resp)
EndProcedureUnit

ProcedureUnit Cors_OptionsWithSpecificOrigin()
  Protected cfg.ServerConfig : InitTestCfg(@cfg, g_MwRoot)
  cfg\CorsEnabled = #True
  cfg\CorsOrigin = "https://example.com"
  Protected req.HttpRequest : req\Method = "OPTIONS" : req\Path = "/" : req\RawHeaders = ""
  Protected resp.ResponseBuffer : InitResp(@resp)
  Protected mCtx.MiddlewareContext : InitMCtx(@mCtx, @cfg)

  Protected result.i = Middleware_Cors(@req, @resp, @mCtx)
  Assert(result = #True, "OPTIONS should be handled")
  Assert(resp\StatusCode = #HTTP_204, "should be 204; got: " + Str(resp\StatusCode))
  Assert(FindString(resp\Headers, "Access-Control-Allow-Origin: https://example.com") > 0, "should use specific origin")
  FreeResp(@resp)
EndProcedureUnit

ProcedureUnit Cors_GetResponseGetsCorsHeaders()
  Protected cfg.ServerConfig : InitTestCfg(@cfg, g_MwRoot)
  cfg\CorsEnabled = #True
  Protected req.HttpRequest : req\Method = "GET" : req\Path = "/index.html" : req\RawHeaders = ""
  Protected resp.ResponseBuffer : InitResp(@resp)
  ; Simulate a downstream handler having produced a response
  resp\StatusCode = #HTTP_200
  resp\Headers    = "Content-Type: text/html" + #CRLF$
  resp\Handled    = #True
  Protected mCtx.MiddlewareContext : InitMCtx(@mCtx, @cfg)

  ; Since chain is empty, CallNext returns #False and resp stays as-is (already handled)
  Protected result.i = Middleware_Cors(@req, @resp, @mCtx)
  Assert(FindString(resp\Headers, "Access-Control-Allow-Origin: *") > 0, "GET response should have CORS origin header")
  Assert(FindString(resp\Headers, "Vary: Origin") > 0, "GET response should have Vary header")
  FreeResp(@resp)
EndProcedureUnit

ProcedureUnit Cors_DisabledOptionsPassThrough()
  Protected cfg.ServerConfig : InitTestCfg(@cfg, g_MwRoot)
  ; CorsEnabled = #False (default)
  Protected req.HttpRequest : req\Method = "OPTIONS" : req\Path = "/" : req\RawHeaders = ""
  Protected resp.ResponseBuffer : InitResp(@resp)
  Protected mCtx.MiddlewareContext : InitMCtx(@mCtx, @cfg)

  Protected result.i = Middleware_Cors(@req, @resp, @mCtx)
  Assert(result = #False, "disabled CORS should pass through")
  Assert(resp\Handled = #False, "resp should not be handled")
  Assert(FindString(resp\Headers, "Access-Control") = 0, "should have no CORS headers")
  FreeResp(@resp)
EndProcedureUnit

ProcedureUnit Cors_DisabledGetNoCorsHeaders()
  Protected cfg.ServerConfig : InitTestCfg(@cfg, g_MwRoot)
  ; CorsEnabled = #False (default)
  Protected req.HttpRequest : req\Method = "GET" : req\Path = "/" : req\RawHeaders = ""
  Protected resp.ResponseBuffer : InitResp(@resp)
  Protected mCtx.MiddlewareContext : InitMCtx(@mCtx, @cfg)

  Protected result.i = Middleware_Cors(@req, @resp, @mCtx)
  Assert(FindString(resp\Headers, "Access-Control") = 0, "disabled CORS should add no headers")
  FreeResp(@resp)
EndProcedureUnit

; ── Middleware_SecurityHeaders ────────────────────────────────────────────

ProcedureUnit SecurityHeaders_EnabledAddsAllHeaders()
  Protected cfg.ServerConfig : InitTestCfg(@cfg, g_MwRoot)
  cfg\SecurityHeaders = #True
  Protected req.HttpRequest : req\Method = "GET" : req\Path = "/index.html" : req\RawHeaders = ""
  Protected resp.ResponseBuffer : InitResp(@resp)
  ; Simulate a downstream handler having produced a response
  resp\StatusCode = #HTTP_200
  resp\Headers    = "Content-Type: text/html" + #CRLF$
  resp\Handled    = #True
  Protected mCtx.MiddlewareContext : InitMCtx(@mCtx, @cfg)

  Protected result.i = Middleware_SecurityHeaders(@req, @resp, @mCtx)
  Assert(FindString(resp\Headers, "X-Content-Type-Options: nosniff") > 0, "should have nosniff")
  Assert(FindString(resp\Headers, "X-Frame-Options: DENY") > 0, "should have frame deny")
  Assert(FindString(resp\Headers, "X-XSS-Protection: 1; mode=block") > 0, "should have XSS protection")
  Assert(FindString(resp\Headers, "Referrer-Policy: strict-origin-when-cross-origin") > 0, "should have referrer policy")
  Assert(FindString(resp\Headers, "Cross-Origin-Opener-Policy: same-origin") > 0, "should have COOP")
  FreeResp(@resp)
EndProcedureUnit

ProcedureUnit SecurityHeaders_DisabledNoHeaders()
  Protected cfg.ServerConfig : InitTestCfg(@cfg, g_MwRoot)
  ; SecurityHeaders = #False (default)
  Protected req.HttpRequest : req\Method = "GET" : req\Path = "/" : req\RawHeaders = ""
  Protected resp.ResponseBuffer : InitResp(@resp)
  ; Simulate a handled response
  resp\StatusCode = #HTTP_200
  resp\Handled    = #True
  Protected mCtx.MiddlewareContext : InitMCtx(@mCtx, @cfg)

  Protected result.i = Middleware_SecurityHeaders(@req, @resp, @mCtx)
  Assert(FindString(resp\Headers, "X-Content-Type-Options") = 0, "disabled should have no security headers")
  Assert(FindString(resp\Headers, "X-Frame-Options") = 0, "disabled should have no X-Frame-Options")
  FreeResp(@resp)
EndProcedureUnit

ProcedureUnit SecurityHeaders_EnabledNotHandled_NoHeaders()
  Protected cfg.ServerConfig : InitTestCfg(@cfg, g_MwRoot)
  cfg\SecurityHeaders = #True
  Protected req.HttpRequest : req\Method = "GET" : req\Path = "/missing" : req\RawHeaders = ""
  Protected resp.ResponseBuffer : InitResp(@resp)
  ; resp\Handled = #False (default — no downstream match)
  Protected mCtx.MiddlewareContext : InitMCtx(@mCtx, @cfg)

  Protected result.i = Middleware_SecurityHeaders(@req, @resp, @mCtx)
  Assert(FindString(resp\Headers, "X-Content-Type-Options") = 0, "not-handled should get no security headers")
  FreeResp(@resp)
EndProcedureUnit

; ── FillErrorResponse (Custom Error Pages) ──────────────────────────────

ProcedureUnit ErrorPage_Custom404Served()
  Protected cfg.ServerConfig : InitTestCfg(@cfg, g_MwRoot)
  cfg\ErrorPagesDir = g_ErrPagesDir
  Protected resp.ResponseBuffer : InitResp(@resp)

  FillErrorResponse(@resp, @cfg, #HTTP_404, "404 Not Found")
  Assert(resp\StatusCode = #HTTP_404, "should be 404; got: " + Str(resp\StatusCode))
  Assert(resp\Handled = #True, "should be handled")
  Assert(FindString(resp\Headers, "text/html") > 0, "should serve as HTML")
  Assert(resp\BodySize > 0, "body should not be empty")
  ; Verify custom content
  Protected body.s = PeekS(resp\Body, resp\BodySize, #PB_Ascii)
  Assert(FindString(body, "Custom Not Found") > 0, "should contain custom page content")
  FreeResp(@resp)
EndProcedureUnit

ProcedureUnit ErrorPage_Custom403ViaHiddenPath()
  Protected cfg.ServerConfig : InitTestCfg(@cfg, g_MwRoot)
  cfg\ErrorPagesDir = g_ErrPagesDir
  Protected req.HttpRequest  : req\Method = "GET" : req\Path = "/.git/config" : req\RawHeaders = ""
  Protected resp.ResponseBuffer : InitResp(@resp)
  Protected mCtx.MiddlewareContext : InitMCtx(@mCtx, @cfg)

  Protected result.i = Middleware_HiddenPath(@req, @resp, @mCtx)
  Assert(result = #True, "should block hidden path")
  Assert(resp\StatusCode = #HTTP_403, "should be 403")
  Assert(FindString(resp\Headers, "text/html") > 0, "should serve custom HTML error page")
  Protected body.s = PeekS(resp\Body, resp\BodySize, #PB_Ascii)
  Assert(FindString(body, "Custom Forbidden") > 0, "should contain custom 403 content")
  FreeResp(@resp)
EndProcedureUnit

ProcedureUnit ErrorPage_FallbackWhenFileMissing()
  Protected cfg.ServerConfig : InitTestCfg(@cfg, g_MwRoot)
  cfg\ErrorPagesDir = g_ErrPagesDir
  Protected resp.ResponseBuffer : InitResp(@resp)

  ; No 500.html exists → should fall back to plain text
  FillErrorResponse(@resp, @cfg, #HTTP_500, "500 Internal Server Error")
  Assert(resp\StatusCode = #HTTP_500, "should be 500")
  Assert(FindString(resp\Headers, "text/plain") > 0, "should fall back to plain text")
  FreeResp(@resp)
EndProcedureUnit

ProcedureUnit ErrorPage_DisabledUsesPlainText()
  Protected cfg.ServerConfig : InitTestCfg(@cfg, g_MwRoot)
  ; ErrorPagesDir = "" (default — disabled)
  Protected resp.ResponseBuffer : InitResp(@resp)

  FillErrorResponse(@resp, @cfg, #HTTP_404, "404 Not Found")
  Assert(resp\StatusCode = #HTTP_404, "should be 404")
  Assert(FindString(resp\Headers, "text/plain") > 0, "disabled should use plain text")
  FreeResp(@resp)
EndProcedureUnit

; ── Middleware_BasicAuth ─────────────────────────────────────────────────

ProcedureUnit BasicAuth_DisabledPassThrough()
  Protected cfg.ServerConfig : InitTestCfg(@cfg, g_MwRoot)
  ; BasicAuthUser = "" (default — disabled)
  Protected req.HttpRequest : req\Method = "GET" : req\Path = "/" : req\RawHeaders = ""
  Protected resp.ResponseBuffer : InitResp(@resp)
  Protected mCtx.MiddlewareContext : InitMCtx(@mCtx, @cfg)

  Protected result.i = Middleware_BasicAuth(@req, @resp, @mCtx)
  Assert(result = #False, "disabled auth should pass through")
  Assert(resp\Handled = #False, "resp should not be handled")
  FreeResp(@resp)
EndProcedureUnit

ProcedureUnit BasicAuth_NoHeader401()
  Protected cfg.ServerConfig : InitTestCfg(@cfg, g_MwRoot)
  cfg\BasicAuthUser = "admin"
  cfg\BasicAuthPass = "secret"
  Protected req.HttpRequest : req\Method = "GET" : req\Path = "/" : req\RawHeaders = ""
  Protected resp.ResponseBuffer : InitResp(@resp)
  Protected mCtx.MiddlewareContext : InitMCtx(@mCtx, @cfg)

  Protected result.i = Middleware_BasicAuth(@req, @resp, @mCtx)
  Assert(result = #True, "missing auth should be handled")
  Assert(resp\StatusCode = #HTTP_401, "should be 401; got: " + Str(resp\StatusCode))
  Assert(resp\Handled = #True, "should be marked handled")
  Assert(FindString(resp\Headers, "WWW-Authenticate: Basic") > 0, "should have WWW-Authenticate header")
  FreeResp(@resp)
EndProcedureUnit

ProcedureUnit BasicAuth_WrongCredentials401()
  Protected cfg.ServerConfig : InitTestCfg(@cfg, g_MwRoot)
  cfg\BasicAuthUser = "admin"
  cfg\BasicAuthPass = "secret"
  ; Base64("wrong:creds") = "d3Jvbmc6Y3JlZHM="
  Protected req.HttpRequest : req\Method = "GET" : req\Path = "/"
  req\RawHeaders = "Authorization: Basic d3Jvbmc6Y3JlZHM="
  Protected resp.ResponseBuffer : InitResp(@resp)
  Protected mCtx.MiddlewareContext : InitMCtx(@mCtx, @cfg)

  Protected result.i = Middleware_BasicAuth(@req, @resp, @mCtx)
  Assert(result = #True, "wrong creds should be handled")
  Assert(resp\StatusCode = #HTTP_401, "should be 401; got: " + Str(resp\StatusCode))
  FreeResp(@resp)
EndProcedureUnit

ProcedureUnit BasicAuth_CorrectCredentials()
  Protected cfg.ServerConfig : InitTestCfg(@cfg, g_MwRoot)
  cfg\BasicAuthUser = "admin"
  cfg\BasicAuthPass = "secret"
  ; Base64("admin:secret") = "YWRtaW46c2VjcmV0"
  Protected req.HttpRequest : req\Method = "GET" : req\Path = "/"
  req\RawHeaders = "Authorization: Basic YWRtaW46c2VjcmV0"
  Protected resp.ResponseBuffer : InitResp(@resp)
  Protected mCtx.MiddlewareContext : InitMCtx(@mCtx, @cfg)

  Protected result.i = Middleware_BasicAuth(@req, @resp, @mCtx)
  Assert(result = #False, "correct creds should pass through (empty chain)")
  Assert(resp\Handled = #False, "resp should not be handled (passed to empty chain)")
  FreeResp(@resp)
EndProcedureUnit

ProcedureUnit BasicAuth_PasswordWithColon()
  Protected cfg.ServerConfig : InitTestCfg(@cfg, g_MwRoot)
  cfg\BasicAuthUser = "user"
  cfg\BasicAuthPass = "pass:word"
  ; Base64("user:pass:word") = "dXNlcjpwYXNzOndvcmQ="
  Protected req.HttpRequest : req\Method = "GET" : req\Path = "/"
  req\RawHeaders = "Authorization: Basic dXNlcjpwYXNzOndvcmQ="
  Protected resp.ResponseBuffer : InitResp(@resp)
  Protected mCtx.MiddlewareContext : InitMCtx(@mCtx, @cfg)

  Protected result.i = Middleware_BasicAuth(@req, @resp, @mCtx)
  Assert(result = #False, "password with colon should pass through")
  Assert(resp\Handled = #False, "resp should not be handled")
  FreeResp(@resp)
EndProcedureUnit

; ── Cache-Control ────────────────────────────────────────────────────────

ProcedureUnit CacheControl_DefaultZero()
  Protected cfg.ServerConfig : InitTestCfg(@cfg, g_MwRoot)
  ; CacheMaxAge = 0 (default)
  ; Use ETag304 to test — compute real ETag
  Protected etag.s = BuildETag(g_MwEtagFile)
  Protected req.HttpRequest : req\Method = "GET" : req\Path = "/etag_test.txt"
  req\RawHeaders = "If-None-Match: " + etag
  Protected resp.ResponseBuffer : InitResp(@resp)
  Protected mCtx.MiddlewareContext : InitMCtx(@mCtx, @cfg)

  Middleware_ETag304(@req, @resp, @mCtx)
  Assert(resp\StatusCode = #HTTP_304, "should be 304")
  Assert(FindString(resp\Headers, "max-age=0") > 0, "default should be max-age=0")
  FreeResp(@resp)
EndProcedureUnit

ProcedureUnit CacheControl_Custom3600InETag304()
  Protected cfg.ServerConfig : InitTestCfg(@cfg, g_MwRoot)
  cfg\CacheMaxAge = 3600
  Protected etag.s = BuildETag(g_MwEtagFile)
  Protected req.HttpRequest : req\Method = "GET" : req\Path = "/etag_test.txt"
  req\RawHeaders = "If-None-Match: " + etag
  Protected resp.ResponseBuffer : InitResp(@resp)
  Protected mCtx.MiddlewareContext : InitMCtx(@mCtx, @cfg)

  Middleware_ETag304(@req, @resp, @mCtx)
  Assert(resp\StatusCode = #HTTP_304, "should be 304")
  Assert(FindString(resp\Headers, "max-age=3600") > 0, "should use custom max-age=3600")
  Assert(FindString(resp\Headers, "max-age=0") = 0, "should not contain max-age=0")
  FreeResp(@resp)
EndProcedureUnit

ProcedureUnit CacheControl_FileServerUsesConfigured()
  Protected cfg.ServerConfig : InitTestCfg(@cfg, g_MwRoot)
  cfg\CacheMaxAge = 86400
  Protected req.HttpRequest : req\Method = "GET" : req\Path = "/index.html" : req\RawHeaders = ""
  Protected resp.ResponseBuffer : InitResp(@resp)
  Protected mCtx.MiddlewareContext : InitMCtx(@mCtx, @cfg)

  Middleware_FileServer(@req, @resp, @mCtx)
  Assert(resp\StatusCode = #HTTP_200, "should be 200; got: " + Str(resp\StatusCode))
  Assert(FindString(resp\Headers, "max-age=86400") > 0, "FileServer should use configured max-age=86400")
  FreeResp(@resp)
EndProcedureUnit
