; test_directory_listing.pb — Unit tests for DirectoryListing.pbi
EnableExplicit
XIncludeFile "TestCommon.pbi"

Global g_ListDir.s
Global g_ListFile1.s
Global g_ListFile2.s
Global g_ListSubDir.s

ProcedureUnitStartup setup()
  Protected f.i
  g_ListDir   = GetTemporaryDirectory() + "pshs_listing/"
  g_ListFile1 = g_ListDir + "readme.txt"
  g_ListFile2 = g_ListDir + "index.html"
  g_ListSubDir = g_ListDir + "assets/"

  CreateDirectory(g_ListDir)
  CreateDirectory(g_ListSubDir)

  f = CreateFile(#PB_Any, g_ListFile1)
  If f : WriteStringN(f, "readme content") : CloseFile(f) : EndIf

  f = CreateFile(#PB_Any, g_ListFile2)
  If f : WriteStringN(f, "<html>index</html>") : CloseFile(f) : EndIf
EndProcedureUnit

ProcedureUnitShutdown teardown()
  DeleteFile(g_ListFile1)
  DeleteFile(g_ListFile2)
  DeleteDirectory(g_ListSubDir, "", #PB_FileSystem_Recursive)
  DeleteDirectory(g_ListDir,    "", #PB_FileSystem_Recursive)
EndProcedureUnit

ProcedureUnit DirListing_ReturnsHTML()
  Protected html.s = BuildDirectoryListing(g_ListDir, "/")
  Assert(html <> "", "should return non-empty HTML")
  Assert(FindString(html, "<!DOCTYPE html>") > 0, "should start with DOCTYPE")
EndProcedureUnit

ProcedureUnit DirListing_ContainsFilenames()
  Protected html.s = BuildDirectoryListing(g_ListDir, "/")
  Assert(FindString(html, "readme.txt")  > 0, "should list readme.txt")
  Assert(FindString(html, "index.html")  > 0, "should list index.html")
EndProcedureUnit

ProcedureUnit DirListing_ContainsSubdir()
  Protected html.s = BuildDirectoryListing(g_ListDir, "/")
  Assert(FindString(html, "assets/") > 0, "should list assets/ subdirectory with trailing slash")
EndProcedureUnit

ProcedureUnit DirListing_ParentLinkForNonRoot()
  Protected html.s = BuildDirectoryListing(g_ListDir, "/somepath/")
  Assert(FindString(html, "../") > 0, "non-root path should have parent link")
EndProcedureUnit

ProcedureUnit DirListing_NoParentLinkAtRoot()
  Protected html.s = BuildDirectoryListing(g_ListDir, "/")
  ; "../" should not appear as a clickable link at root
  ; (It might appear in text but not as a link for root)
  Protected parentHref.s = "<a href='../'"
  Protected pos.i = FindString(html, parentHref)
  Assert(pos = 0, "root listing should have no parent link; found at: " + Str(pos))
EndProcedureUnit

ProcedureUnit DirListing_TitleContainsPath()
  Protected html.s = BuildDirectoryListing(g_ListDir, "/docs/")
  Assert(FindString(html, "Index of /docs/") > 0, "title should contain the URL path")
EndProcedureUnit

ProcedureUnit HiddenPath_SingleSegment()
  Assert(IsHiddenPath("/.git/config", ".git,.env"),   "/.git/config is hidden")
  Assert(IsHiddenPath("/.env",        ".git,.env"),   "/.env is hidden")
  Assert(IsHiddenPath("/normal.html", ".git,.env") = #False, "/normal.html not hidden")
EndProcedureUnit

ProcedureUnit HiddenPath_NestedSegment()
  Assert(IsHiddenPath("/app/.git/hooks", ".git"), "nested /.git/ is hidden")
  Assert(IsHiddenPath("/app/main.js",    ".git") = #False, "/app/main.js not hidden")
EndProcedureUnit

ProcedureUnit HiddenPath_EmptyPatterns()
  Assert(IsHiddenPath("/.git/foo", "") = #False, "empty patterns = nothing hidden")
EndProcedureUnit
