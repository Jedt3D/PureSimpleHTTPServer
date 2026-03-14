; DirectoryListing.pbi — HTML directory browse page generator
; Include with: XIncludeFile "DirectoryListing.pbi"
; Provides: BuildDirectoryListing(dirPath.s, urlPath.s) -> String
; Dependencies (managed by main.pb and tests/TestCommon.pbi):
;   Global.pbi, DateHelper.pbi

; BuildDirectoryListing(dirPath.s, urlPath.s) — generate HTML directory listing
; dirPath: absolute filesystem path to the directory (trailing separator optional)
; urlPath: URL path for generating links (e.g. "/" or "/docs/")
; Returns: HTML string for the listing page, or "" on error
Procedure.s BuildDirectoryListing(dirPath.s, urlPath.s)
  Protected result.s, name.s, href.s, sizeStr.s
  Protected entPath.s, entSize.i, entDate.q

  ; Normalize separators
  If Right(dirPath, 1) <> "/" And Right(dirPath, 1) <> "\"
    dirPath + "/"
  EndIf
  If Right(urlPath, 1) <> "/"
    urlPath + "/"
  EndIf

  ; Collect directory entries into two sorted lists
  Protected NewList dirs.s()
  Protected NewList files.s()

  If Not ExamineDirectory(0, dirPath, "*")
    ProcedureReturn ""
  EndIf

  While NextDirectoryEntry(0)
    name = DirectoryEntryName(0)
    If name = "." Or name = ".."
      Continue
    EndIf
    If DirectoryEntryType(0) = #PB_DirectoryEntry_Directory
      AddElement(dirs())  : dirs()  = name
    Else
      AddElement(files()) : files() = name
    EndIf
  Wend
  FinishDirectory(0)

  SortList(dirs(),  #PB_Sort_Ascending | #PB_Sort_NoCase)
  SortList(files(), #PB_Sort_Ascending | #PB_Sort_NoCase)

  ; HTML header
  result  = "<!DOCTYPE html>" + #LF$
  result + "<html><head><meta charset='utf-8'>" + #LF$
  result + "<title>Index of " + urlPath + "</title>" + #LF$
  result + "<style>"
  result + "body{font-family:monospace;padding:1em}"
  result + "table{border-collapse:collapse;width:100%}"
  result + "th,td{text-align:left;padding:4px 12px;border-bottom:1px solid #ddd}"
  result + "th{background:#f4f4f4}"
  result + "a{text-decoration:none}a:hover{text-decoration:underline}"
  result + "</style></head><body>" + #LF$
  result + "<h2>Index of " + urlPath + "</h2>" + #LF$
  result + "<table><tr><th>Name</th><th>Size</th><th>Modified</th></tr>" + #LF$

  ; Parent directory link (not shown for root)
  If urlPath <> "/"
    result + "<tr><td><a href='../'>../</a></td><td>-</td><td>-</td></tr>" + #LF$
  EndIf

  ; Directories first
  ForEach dirs()
    href    = urlPath + URLEncoder(dirs()) + "/"
    result + "<tr><td><a href='" + href + "'>" + dirs() + "/</a></td>"
    result + "<td>-</td><td>-</td></tr>" + #LF$
  Next

  ; Files
  ForEach files()
    href    = urlPath + URLEncoder(files())
    entPath = dirPath + files()
    entSize = FileSize(entPath)
    entDate = GetFileDate(entPath, #PB_Date_Modified)

    If entSize < 1024
      sizeStr = Str(entSize) + " B"
    ElseIf entSize < 1048576
      sizeStr = StrF(entSize / 1024.0, 1) + " KB"
    Else
      sizeStr = StrF(entSize / 1048576.0, 1) + " MB"
    EndIf

    result + "<tr><td><a href='" + href + "'>" + files() + "</a></td>"
    result + "<td>" + sizeStr + "</td>"
    result + "<td>" + HTTPDate(entDate) + "</td></tr>" + #LF$
  Next

  result + "</table>" + #LF$
  result + "<hr><small>" + #APP_NAME + " v" + #APP_VERSION + "</small>" + #LF$
  result + "</body></html>"

  FreeList(dirs())
  FreeList(files())

  ProcedureReturn result
EndProcedure
