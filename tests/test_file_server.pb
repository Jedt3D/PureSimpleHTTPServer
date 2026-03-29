; test_file_server.pb — Unit tests for FileServer.pbi
EnableExplicit
XIncludeFile "TestCommon.pbi"

; Fixture paths — set in ProcedureUnitStartup, cleaned in ProcedureUnitShutdown
Global g_TmpDir.s
Global g_TmpHtml.s
Global g_TmpEtag.s

ProcedureUnitStartup setup()
  Protected f.i
  g_TmpDir  = GetTemporaryDirectory()
  g_TmpHtml = g_TmpDir + "pshs_idx.html"
  g_TmpEtag = g_TmpDir + "pshs_etag.txt"

  f = CreateFile(#PB_Any, g_TmpHtml)
  If f : WriteStringN(f, "<html>index</html>") : CloseFile(f) : EndIf

  f = CreateFile(#PB_Any, g_TmpEtag)
  If f : WriteStringN(f, "etag test content") : CloseFile(f) : EndIf
EndProcedureUnit

ProcedureUnitShutdown teardown()
  DeleteFile(g_TmpHtml)
  DeleteFile(g_TmpEtag)
EndProcedureUnit

ProcedureUnit ResolveIndex_Found()
  Protected result.s = ResolveIndexFile(g_TmpDir, "pshs_idx.html,index.htm")
  Assert(result = g_TmpHtml, "should find pshs_idx.html; got: " + result)
EndProcedureUnit

ProcedureUnit ResolveIndex_NotFound()
  Protected result.s = ResolveIndexFile(g_TmpDir, "noexist.html,noexist.htm")
  Assert(result = "", "should return empty string; got: " + result)
EndProcedureUnit

ProcedureUnit ResolveIndex_FirstWins()
  ; first entry exists, second doesn't — first should be returned
  Protected result.s = ResolveIndexFile(g_TmpDir, "pshs_idx.html,noexist.htm")
  Assert(result = g_TmpHtml, "first found wins; got: " + result)
EndProcedureUnit

ProcedureUnit ResolveIndex_SecondFallback()
  ; first entry missing, second exists — second should be returned
  Protected result.s = ResolveIndexFile(g_TmpDir, "noexist.html,pshs_idx.html")
  Assert(result = g_TmpHtml, "should fall back to second entry; got: " + result)
EndProcedureUnit

ProcedureUnit ETag_NonEmpty()
  Protected etag.s = BuildETag(g_TmpEtag)
  Assert(etag <> "", "ETag should be non-empty for existing file")
EndProcedureUnit

ProcedureUnit ETag_Stable()
  Protected etag1.s = BuildETag(g_TmpEtag)
  Protected etag2.s = BuildETag(g_TmpEtag)
  Assert(etag1 = etag2, "ETag should be stable: [" + etag1 + "] vs [" + etag2 + "]")
EndProcedureUnit

ProcedureUnit ETag_QuotedFormat()
  Protected etag.s = BuildETag(g_TmpEtag)
  Assert(Left(etag, 1)  = Chr(34), "ETag must start with double-quote")
  Assert(Right(etag, 1) = Chr(34), "ETag must end with double-quote")
  Assert(Len(etag) > 2,            "ETag must have content between quotes")
EndProcedureUnit

ProcedureUnit ETag_MissingFile()
  Protected etag.s = BuildETag(g_TmpDir + "no_such_file_pshs_xyz.txt")
  Assert(etag = "", "ETag should be empty for missing file; got: " + etag)
EndProcedureUnit
