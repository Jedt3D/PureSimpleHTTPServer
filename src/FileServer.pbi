; FileServer.pbi — static file serving from disk
; Include with: XIncludeFile "FileServer.pbi"
; Provides: ServeFile(), ResolveIndexFile(), BuildETag()
; Dependencies (managed by main.pb and tests/TestCommon.pbi):
;   Global.pbi, Types.pbi, MimeTypes.pbi, DateHelper.pbi, HttpResponse.pbi

; ResolveIndexFile(dirPath.s, indexList.s) — find an index file in a directory
; dirPath:   filesystem path to a directory (trailing separator optional)
; indexList: comma-separated filenames, checked left-to-right (e.g. "index.html,index.htm")
; Returns the full path to the first matching file, or "" if none exists.
Procedure.s ResolveIndexFile(dirPath.s, indexList.s)
  Protected i.i, candidate.s, fullPath.s
  Protected count.i = CountString(indexList, ",") + 1

  ; Ensure dirPath ends with a path separator
  If Right(dirPath, 1) <> "/" And Right(dirPath, 1) <> "\"
    dirPath + "/"
  EndIf

  For i = 1 To count
    candidate = Trim(StringField(indexList, i, ","))
    If candidate <> ""
      fullPath = dirPath + candidate
      If FileSize(fullPath) >= 0   ; file exists (>= 0 means file, not directory)
        ProcedureReturn fullPath
      EndIf
    EndIf
  Next i

  ProcedureReturn ""
EndProcedure

; BuildETag(filePath.s) — generate a strong ETag for a file
; Combines hex-encoded file size and modification timestamp.
; Returns a quoted ETag string (e.g. "1a2b-3c4d5e6f"), or "" if file not found.
Procedure.s BuildETag(filePath.s)
  Protected size.i = FileSize(filePath)
  If size < 0
    ProcedureReturn ""
  EndIf
  Protected mtime.q = GetFileDate(filePath, #PB_Date_Modified)
  ProcedureReturn Chr(34) + Hex(size) + "-" + Hex(mtime) + Chr(34)
EndProcedure

; ServeFile(connection.i, docRoot.s, urlPath.s [, indexList.s]) — serve a file from disk
; docRoot:   server root directory (trailing separator optional)
; urlPath:   normalized URL path starting with "/" (from ParseHttpRequest)
; indexList: comma-separated index filenames (default: "index.html,index.htm")
;
; For directories: tries to resolve an index file; sends 403 if none found.
; For missing files: sends 404.
; On I/O error: sends 500.
; Returns #True on success (200 sent), #False if an error response was sent.
Procedure.i ServeFile(connection.i, docRoot.s, urlPath.s, indexList.s = "index.html,index.htm")
  Protected fsPath.s, resolvedPath.s, ext.s, mimeType.s
  Protected fileSize.i, mtime.q, etag.s, extraHeaders.s
  Protected *buffer, file.i

  ; Strip trailing separator from docRoot for consistent joining
  If Right(docRoot, 1) = "/" Or Right(docRoot, 1) = "\"
    docRoot = Left(docRoot, Len(docRoot) - 1)
  EndIf

  ; Build filesystem path (urlPath always starts with "/")
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    fsPath = ReplaceString(docRoot + urlPath, "/", "\")
  CompilerElse
    fsPath = docRoot + urlPath
  CompilerEndIf

  fileSize = FileSize(fsPath)

  ; Directory: try to resolve an index file
  If fileSize = -2
    resolvedPath = ResolveIndexFile(fsPath, indexList)
    If resolvedPath = ""
      SendTextResponse(connection, #HTTP_403, "text/plain; charset=utf-8", "403 Forbidden")
      ProcedureReturn #False
    EndIf
    fsPath   = resolvedPath
    fileSize = FileSize(fsPath)
  EndIf

  ; File not found
  If fileSize < 0
    SendTextResponse(connection, #HTTP_404, "text/plain; charset=utf-8", "404 Not Found")
    ProcedureReturn #False
  EndIf

  ; Read file into memory (+1 guards against zero-size edge case in AllocateMemory)
  *buffer = AllocateMemory(fileSize + 1)
  If *buffer = 0
    SendTextResponse(connection, #HTTP_500, "text/plain; charset=utf-8", "500 Internal Server Error")
    ProcedureReturn #False
  EndIf

  file = ReadFile(#PB_Any, fsPath)
  If file = 0
    FreeMemory(*buffer)
    SendTextResponse(connection, #HTTP_500, "text/plain; charset=utf-8", "500 Internal Server Error")
    ProcedureReturn #False
  EndIf

  If fileSize > 0
    ReadData(file, *buffer, fileSize)
  EndIf
  CloseFile(file)

  ; Build response headers
  ext          = LCase(GetExtensionPart(fsPath))
  mimeType     = GetMimeType(ext)
  etag         = BuildETag(fsPath)
  mtime        = GetFileDate(fsPath, #PB_Date_Modified)
  extraHeaders  = "Content-Type: "  + mimeType        + #CRLF$
  extraHeaders + "ETag: "           + etag             + #CRLF$
  extraHeaders + "Last-Modified: "  + HTTPDate(mtime)  + #CRLF$
  extraHeaders + "Cache-Control: "  + "max-age=0"      + #CRLF$

  SendNetworkString(connection, BuildResponseHeaders(#HTTP_200, extraHeaders, fileSize), #PB_Ascii)
  If fileSize > 0
    SendNetworkData(connection, *buffer, fileSize)
  EndIf

  FreeMemory(*buffer)
  ProcedureReturn #True
EndProcedure
