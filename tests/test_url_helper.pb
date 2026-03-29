; test_url_helper.pb — Unit tests for UrlHelper.pbi
; Tests: URLDecodePath(), NormalizePath()
EnableExplicit
XIncludeFile "TestCommon.pbi"

; -----------------------------------------------------------------------
; URLDecodePath: percent-encoding is decoded correctly
; -----------------------------------------------------------------------
ProcedureUnit Test_URLDecodePath_PercentEncoding()
  Assert(URLDecodePath("%2Ffoo%2Fbar")  = "/foo/bar",   "Decode %2F (slash)")
  Assert(URLDecodePath("hello%20world") = "hello world", "Decode %20 (space)")
  Assert(URLDecodePath("%41%42%43")     = "ABC",         "Decode ASCII hex")
  Assert(URLDecodePath("/plain/path")   = "/plain/path", "Plain path unchanged")
  Assert(URLDecodePath("")              = "",             "Empty string")
EndProcedureUnit

; -----------------------------------------------------------------------
; NormalizePath: . and .. segments resolved
; -----------------------------------------------------------------------
ProcedureUnit Test_NormalizePath_DotSegments()
  Assert(NormalizePath("/foo/./bar")    = "/foo/bar", "Single dot removed")
  Assert(NormalizePath("/foo/../bar")   = "/bar",     "Double dot resolves up")
  Assert(NormalizePath("/foo/bar/..")   = "/foo",     "Trailing dot-dot")
  Assert(NormalizePath("/")             = "/",        "Root stays root")
  Assert(NormalizePath("")              = "/",        "Empty string becomes root")
  Assert(NormalizePath("/foo//bar")     = "/foo/bar", "Double slash collapsed")
EndProcedureUnit

; -----------------------------------------------------------------------
; NormalizePath: traversal above root is safely capped
; -----------------------------------------------------------------------
ProcedureUnit Test_NormalizePath_TraversalAboveRoot()
  ; Going above root should not expose parent filesystem paths
  Protected r1.s = NormalizePath("/../etc/passwd")
  Assert(r1 = "/etc/passwd", "One traversal above root — got: '" + r1 + "'")

  Protected r2.s = NormalizePath("/../../..")
  Assert(r2 = "/", "Multiple traversals collapse to root — got: '" + r2 + "'")
EndProcedureUnit

; -----------------------------------------------------------------------
; NormalizePath: relative path gets leading slash added
; -----------------------------------------------------------------------
ProcedureUnit Test_NormalizePath_RelativePath()
  Protected r.s = NormalizePath("foo/bar")
  Assert(Left(r, 1) = "/", "Relative path gets leading slash — got: '" + r + "'")
  Assert(r = "/foo/bar",   "Relative path normalized to absolute — got: '" + r + "'")
EndProcedureUnit
