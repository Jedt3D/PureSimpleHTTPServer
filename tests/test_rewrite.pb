; test_rewrite.pb — Unit tests for RewriteEngine.pbi
; Phase G: URL rewriting (exact, glob, regex; rewrite and redir; per-dir cache)
EnableExplicit
XIncludeFile "TestCommon.pbi"

Global g_TmpRwDir.s   ; temp docroot for per-dir tests
Global g_TmpConf.s    ; temp global rewrite.conf

; WriteRuleFile_ — write multi-line content to a file (lines separated by LF)
Procedure WriteRuleFile_(path.s, content.s)
  Protected f.i = CreateFile(#PB_Any, path)
  If f
    WriteString(f, content, #PB_Ascii)
    CloseFile(f)
  EndIf
EndProcedure

ProcedureUnitStartup rw_setup()
  g_TmpRwDir = GetTemporaryDirectory() + "pshs_rw_test"
  g_TmpConf  = GetTemporaryDirectory() + "pshs_rw_global.conf"
  CreateDirectory(g_TmpRwDir)
  CreateDirectory(g_TmpRwDir + "/blog")
  InitRewriteEngine()
EndProcedureUnit

ProcedureUnitShutdown rw_teardown()
  CleanupRewriteEngine()
  DeleteFile(g_TmpConf)
  DeleteFile(g_TmpRwDir + "/blog/rewrite.conf")
  ; Note: temp directories (g_TmpRwDir, g_TmpRwDir/blog) are left for the OS to clean up
EndProcedureUnit

; ── Init ──────────────────────────────────────────────────────────────────────

ProcedureUnit RewriteEngine_Init_MutexCreated()
  Assert(g_RewriteMutex <> 0, "g_RewriteMutex should be non-zero after InitRewriteEngine()")
EndProcedureUnit

ProcedureUnit RewriteEngine_GlobalRuleCount_ZeroAfterInit()
  Assert(GlobalRuleCount() = 0, "No global rules loaded yet — count should be 0")
EndProcedureUnit

; ── Exact rewrite ─────────────────────────────────────────────────────────────

ProcedureUnit RewriteEngine_ExactRewrite_Match()
  WriteRuleFile_(g_TmpConf, ~"rewrite /about /about.html\n")
  LoadGlobalRules(g_TmpConf)
  Protected result.RewriteResult
  Protected matched.i = ApplyRewrites("/about", g_TmpRwDir, @result)
  LoadGlobalRules("")   ; clear
  Assert(matched = #True,        "Exact rewrite should match /about")
  Assert(result\Action  = 1,     "Action should be 1 (rewrite)")
  Assert(result\NewPath = "/about.html", "NewPath should be /about.html")
EndProcedureUnit

ProcedureUnit RewriteEngine_ExactRewrite_NoMatch()
  WriteRuleFile_(g_TmpConf, ~"rewrite /about /about.html\n")
  LoadGlobalRules(g_TmpConf)
  Protected result.RewriteResult
  Protected matched.i = ApplyRewrites("/contact", g_TmpRwDir, @result)
  LoadGlobalRules("")
  Assert(matched = #False, "Exact rewrite should NOT match /contact")
EndProcedureUnit

; ── Glob rewrite ──────────────────────────────────────────────────────────────

ProcedureUnit RewriteEngine_GlobRewrite_PathPlaceholder()
  WriteRuleFile_(g_TmpConf, ~"rewrite /blog/* /posts/{path}\n")
  LoadGlobalRules(g_TmpConf)
  Protected result.RewriteResult
  ApplyRewrites("/blog/hello-world", g_TmpRwDir, @result)
  LoadGlobalRules("")
  Assert(result\Action  = 1,                  "Action should be 1 (rewrite)")
  Assert(result\NewPath = "/posts/hello-world", "{path} should be the glob capture")
EndProcedureUnit

ProcedureUnit RewriteEngine_GlobRewrite_FilePlaceholder()
  WriteRuleFile_(g_TmpConf, ~"rewrite /static/* /assets/{file}\n")
  LoadGlobalRules(g_TmpConf)
  Protected result.RewriteResult
  ApplyRewrites("/static/img/logo.png", g_TmpRwDir, @result)
  LoadGlobalRules("")
  Assert(result\NewPath = "/assets/logo.png", "{file} should be basename of capture")
EndProcedureUnit

ProcedureUnit RewriteEngine_GlobRewrite_DirPlaceholder()
  WriteRuleFile_(g_TmpConf, ~"rewrite /static/* /assets/{dir}/{file}\n")
  LoadGlobalRules(g_TmpConf)
  Protected result.RewriteResult
  ApplyRewrites("/static/img/logo.png", g_TmpRwDir, @result)
  LoadGlobalRules("")
  Assert(result\NewPath = "/assets/img/logo.png", "{dir}/{file} should reconstruct capture path")
EndProcedureUnit

; ── Regex rewrite ─────────────────────────────────────────────────────────────

ProcedureUnit RewriteEngine_RegexRewrite_CaptureGroup()
  WriteRuleFile_(g_TmpConf, ~"rewrite ~/user/([0-9]+) /profile/{re.1}\n")
  LoadGlobalRules(g_TmpConf)
  Protected result.RewriteResult
  ApplyRewrites("/user/42", g_TmpRwDir, @result)
  LoadGlobalRules("")
  Assert(result\Action  = 1,             "Action should be 1 (rewrite)")
  Assert(result\NewPath = "/profile/42", "{re.1} should be the first capture group")
EndProcedureUnit

ProcedureUnit RewriteEngine_RegexRewrite_MultipleGroups()
  WriteRuleFile_(g_TmpConf, ~"rewrite ~/([a-z]+)/([0-9]+) /{re.2}/{re.1}\n")
  LoadGlobalRules(g_TmpConf)
  Protected result.RewriteResult
  ApplyRewrites("/post/99", g_TmpRwDir, @result)
  LoadGlobalRules("")
  Assert(result\NewPath = "/99/post", "{re.1} and {re.2} should swap correctly")
EndProcedureUnit

; ── Exact redirect ────────────────────────────────────────────────────────────

ProcedureUnit RewriteEngine_ExactRedir_301()
  WriteRuleFile_(g_TmpConf, ~"redir /old-page /new-page 301\n")
  LoadGlobalRules(g_TmpConf)
  Protected result.RewriteResult
  ApplyRewrites("/old-page", g_TmpRwDir, @result)
  LoadGlobalRules("")
  Assert(result\Action    = 2,          "Action should be 2 (redirect)")
  Assert(result\RedirURL  = "/new-page", "RedirURL should be /new-page")
  Assert(result\RedirCode = 301,         "RedirCode should be 301")
EndProcedureUnit

ProcedureUnit RewriteEngine_ExactRedir_DefaultCode302()
  WriteRuleFile_(g_TmpConf, ~"redir /old /new\n")
  LoadGlobalRules(g_TmpConf)
  Protected result.RewriteResult
  ApplyRewrites("/old", g_TmpRwDir, @result)
  LoadGlobalRules("")
  Assert(result\RedirCode = 302, "Omitted redirect code should default to 302")
EndProcedureUnit

; ── Glob redirect ─────────────────────────────────────────────────────────────

ProcedureUnit RewriteEngine_GlobRedir_PathSubstitution()
  WriteRuleFile_(g_TmpConf, ~"redir /downloads/* /files/{path} 301\n")
  LoadGlobalRules(g_TmpConf)
  Protected result.RewriteResult
  ApplyRewrites("/downloads/report.pdf", g_TmpRwDir, @result)
  LoadGlobalRules("")
  Assert(result\Action    = 2,                    "Action should be 2 (redirect)")
  Assert(result\RedirURL  = "/files/report.pdf",  "{path} should substitute in redirect URL")
  Assert(result\RedirCode = 301,                   "RedirCode should be 301")
EndProcedureUnit

; ── Regex redirect ────────────────────────────────────────────────────────────

ProcedureUnit RewriteEngine_RegexRedir_CaptureGroup()
  WriteRuleFile_(g_TmpConf, ~"redir ~/feed(.*) /rss{re.1} 301\n")
  LoadGlobalRules(g_TmpConf)
  Protected result.RewriteResult
  ApplyRewrites("/feed/atom", g_TmpRwDir, @result)
  LoadGlobalRules("")
  Assert(result\Action    = 2,          "Action should be 2 (redirect)")
  Assert(result\RedirURL  = "/rss/atom", "{re.1} should capture /atom after /feed")
  Assert(result\RedirCode = 301,         "RedirCode should be 301")
EndProcedureUnit

; ── Rule evaluation order ─────────────────────────────────────────────────────

ProcedureUnit RewriteEngine_FirstRuleWins()
  WriteRuleFile_(g_TmpConf, ~"rewrite /x /first\nrewrite /x /second\n")
  LoadGlobalRules(g_TmpConf)
  Protected result.RewriteResult
  ApplyRewrites("/x", g_TmpRwDir, @result)
  LoadGlobalRules("")
  Assert(result\NewPath = "/first", "First matching rule should win")
EndProcedureUnit

; ── Parsing edge cases ────────────────────────────────────────────────────────

ProcedureUnit RewriteEngine_Comments_Ignored()
  WriteRuleFile_(g_TmpConf, ~"# This is a comment\nrewrite /a /b\n")
  LoadGlobalRules(g_TmpConf)
  Protected count.i = GlobalRuleCount()
  LoadGlobalRules("")
  Assert(count = 1, "Comment lines should not create rules")
EndProcedureUnit

ProcedureUnit RewriteEngine_BlankLines_Ignored()
  WriteRuleFile_(g_TmpConf, ~"\n  \nrewrite /a /b\n\n")
  LoadGlobalRules(g_TmpConf)
  Protected count.i = GlobalRuleCount()
  LoadGlobalRules("")
  Assert(count = 1, "Blank lines should not create rules")
EndProcedureUnit

ProcedureUnit RewriteEngine_InvalidVerb_Ignored()
  WriteRuleFile_(g_TmpConf, ~"forward /a /b\nrewrite /x /y\n")
  LoadGlobalRules(g_TmpConf)
  Protected count.i = GlobalRuleCount()
  LoadGlobalRules("")
  Assert(count = 1, "Unknown verbs should be skipped; only valid rules counted")
EndProcedureUnit

ProcedureUnit RewriteEngine_NoMatch_ReturnsFalse()
  WriteRuleFile_(g_TmpConf, ~"rewrite /specific /target\n")
  LoadGlobalRules(g_TmpConf)
  Protected result.RewriteResult
  Protected matched.i = ApplyRewrites("/nomatch", g_TmpRwDir, @result)
  LoadGlobalRules("")
  Assert(matched = #False,   "ApplyRewrites should return #False when no rule matches")
  Assert(result\Action = 0,  "result.Action should be 0 when no rule matches")
EndProcedureUnit

; ── LoadGlobalRules from file ─────────────────────────────────────────────────

ProcedureUnit RewriteEngine_LoadFromFile_CountsCorrectly()
  WriteRuleFile_(g_TmpConf, ~"rewrite /a /b\nredir /c /d 301\n# skip\nrewrite /e /f\n")
  LoadGlobalRules(g_TmpConf)
  Protected count.i = GlobalRuleCount()
  LoadGlobalRules("")
  Assert(count = 3, "File with 3 valid rules (1 comment) should load 3 rules")
EndProcedureUnit

; ── Per-directory rules ───────────────────────────────────────────────────────

ProcedureUnit RewriteEngine_PerDir_LoadsFromDocRoot()
  Protected confPath.s = g_TmpRwDir + "/blog/rewrite.conf"
  WriteRuleFile_(confPath, ~"rewrite /blog/hello /blog/hello.html\n")
  Protected result.RewriteResult
  Protected matched.i = ApplyRewrites("/blog/hello", g_TmpRwDir, @result)
  DeleteFile(confPath)
  Assert(matched = #True,                   "Per-dir rewrite.conf should be found and applied")
  Assert(result\NewPath = "/blog/hello.html", "Per-dir rule should rewrite path correctly")
EndProcedureUnit

ProcedureUnit RewriteEngine_GlobalFirst_PerDirSecond()
  ; Global rule covers /blog/hello; per-dir rule also covers it — global must win
  WriteRuleFile_(g_TmpConf, ~"rewrite /blog/hello /global-target\n")
  LoadGlobalRules(g_TmpConf)
  Protected confPath.s = g_TmpRwDir + "/blog/rewrite.conf"
  WriteRuleFile_(confPath, ~"rewrite /blog/hello /perdir-target\n")
  Protected result.RewriteResult
  ApplyRewrites("/blog/hello", g_TmpRwDir, @result)
  LoadGlobalRules("")
  DeleteFile(confPath)
  Assert(result\NewPath = "/global-target", "Global rules should take priority over per-dir rules")
EndProcedureUnit

; ── Cleanup ───────────────────────────────────────────────────────────────────

ProcedureUnit RewriteEngine_Cleanup_Safe()
  ; CleanupRewriteEngine is called in ProcedureUnitShutdown —
  ; calling it an extra time here should not crash.
  CleanupRewriteEngine()
  InitRewriteEngine()   ; re-init so teardown can clean up normally
  Assert(#True, "CleanupRewriteEngine on already-clean state should not crash")
EndProcedureUnit
