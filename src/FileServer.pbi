; FileServer.pbi — static file serving from disk
; Include with: XIncludeFile "FileServer.pbi"
; Provides: ServeFile(), ResolveIndexFile(), BuildETag(), IsHiddenPath()
; Dependencies (managed by main.pb and tests/TestCommon.pbi):
;   Global.pbi, Types.pbi, DateHelper.pbi, HttpParser.pbi, HttpResponse.pbi,
;   MimeTypes.pbi, DirectoryListing.pbi, RangeParser.pbi (via forward declares below)

; Forward declarations for modules included after this file
Declare.s BuildDirectoryListing(dirPath.s, urlPath.s)
Declare.i ParseRangeHeader(header.s, fileSize.i, *range.RangeSpec)
Declare.i SendPartialResponse(connection.i, fsPath.s, *range.RangeSpec, mimeType.s, fileSize.i)

; ResolveIndexFile(dirPath.s, indexList.s) — find an index file in a directory
; indexList: comma-separated filenames, checked left-to-right (e.g. "index.html,index.htm")
; Returns the full path to the first matching file, or "" if none exists.
Procedure.s ResolveIndexFile(dirPath.s, indexList.s)
  Protected i.i, candidate.s, fullPath.s
  Protected count.i = CountString(indexList, ",") + 1

  If Right(dirPath, 1) <> "/" And Right(dirPath, 1) <> "\"
    dirPath + "/"
  EndIf

  For i = 1 To count
    candidate = Trim(StringField(indexList, i, ","))
    If candidate <> ""
      fullPath = dirPath + candidate
      If FileSize(fullPath) >= 0
        ProcedureReturn fullPath
      EndIf
    EndIf
  Next i

  ProcedureReturn ""
EndProcedure

; BuildETag(filePath.s) — generate a strong ETag for a file
; Returns a quoted ETag string (e.g. "1a2b-3c4d5e6f"), or "" if file not found.
Procedure.s BuildETag(filePath.s)
  Protected size.i = FileSize(filePath)
  If size < 0
    ProcedureReturn ""
  EndIf
  Protected mtime.q = GetFileDate(filePath, #PB_Date_Modified)
  ProcedureReturn Chr(34) + Hex(size) + "-" + Hex(mtime) + Chr(34)
EndProcedure

; IsHiddenPath(urlPath.s, hiddenPatterns.s) — check if any URL segment matches a hidden pattern
; hiddenPatterns: comma-separated exact segment names (e.g. ".git,.env,.DS_Store")
; Returns #True if the path contains a hidden segment.
Procedure.i IsHiddenPath(urlPath.s, hiddenPatterns.s)
  Protected i.i, j.i, pathPart.s, pattern.s
  Protected segCount.i = CountString(urlPath, "/") + 1
  Protected patCount.i = CountString(hiddenPatterns, ",") + 1

  For i = 1 To segCount
    pathPart = StringField(urlPath, i, "/")
    If pathPart = "" : Continue : EndIf
    For j = 1 To patCount
      pattern = Trim(StringField(hiddenPatterns, j, ","))
      If pattern <> "" And pathPart = pattern
        ProcedureReturn #True
      EndIf
    Next j
  Next i

  ProcedureReturn #False
EndProcedure

; ServeFile(connection.i, *cfg.ServerConfig, *req.HttpRequest) — serve a file from disk
;
; Handles:
;   - Hidden path blocking (403)       [cfg\HiddenPatterns]
;   - Directory → index file lookup    [cfg\IndexFiles]
;   - Directory browsing               [cfg\BrowseEnabled]
;   - SPA fallback for 404s            [cfg\SpaFallback]
;   - Pre-compressed .gz sidecars      [Accept-Encoding: gzip]
;   - ETag / If-None-Match (304)       [req headers]
;   - Byte-range requests (206)        [Range header]
;   - Regular 200 file serving
;
; Returns #True on success (response sent), #False if an error response was sent.
Procedure.i ServeFile(connection.i, *cfg.ServerConfig, *req.HttpRequest)
  Protected urlPath.s       = *req\Path
  Protected docRoot.s       = *cfg\RootDirectory
  Protected indexList.s     = *cfg\IndexFiles
  Protected fsPath.s, resolvedPath.s, ext.s, mimeType.s
  Protected fileSize.i, mtime.q, etag.s, extraHeaders.s
  Protected *buffer, file.i
  Protected rangeHeader.s, acceptEncoding.s, ifNoneMatch.s

  ; Block hidden paths
  If *cfg\HiddenPatterns <> "" And IsHiddenPath(urlPath, *cfg\HiddenPatterns)
    SendTextResponse(connection, #HTTP_403, "text/plain; charset=utf-8", "403 Forbidden")
    ProcedureReturn #False
  EndIf

  ; Extract request headers
  rangeHeader    = GetHeader(*req\RawHeaders, "Range")
  acceptEncoding = GetHeader(*req\RawHeaders, "Accept-Encoding")
  ifNoneMatch    = GetHeader(*req\RawHeaders, "If-None-Match")

  ; Build filesystem path (urlPath always starts with "/")
  If Right(docRoot, 1) = "/" Or Right(docRoot, 1) = "\"
    docRoot = Left(docRoot, Len(docRoot) - 1)
  EndIf
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    fsPath = ReplaceString(docRoot + urlPath, "/", "\")
  CompilerElse
    fsPath = docRoot + urlPath
  CompilerEndIf

  fileSize = FileSize(fsPath)

  ; --- Directory handling ---
  If fileSize = -2
    resolvedPath = ResolveIndexFile(fsPath, indexList)
    If resolvedPath <> ""
      fsPath   = resolvedPath
      fileSize = FileSize(fsPath)
    ElseIf *cfg\BrowseEnabled
      Protected listing.s = BuildDirectoryListing(fsPath, urlPath)
      If listing <> ""
        SendTextResponse(connection, #HTTP_200, "text/html; charset=utf-8", listing)
        ProcedureReturn #True
      EndIf
      SendTextResponse(connection, #HTTP_500, "text/plain; charset=utf-8", "500 Internal Server Error")
      ProcedureReturn #False
    Else
      SendTextResponse(connection, #HTTP_403, "text/plain; charset=utf-8", "403 Forbidden")
      ProcedureReturn #False
    EndIf
  EndIf

  ; --- File not found ---
  If fileSize < 0
    If *cfg\SpaFallback
      ; Serve root index for all 404s (Single-Page App mode)
      resolvedPath = ResolveIndexFile(docRoot + "/", indexList)
      If resolvedPath <> ""
        fsPath   = resolvedPath
        fileSize = FileSize(fsPath)
      Else
        SendTextResponse(connection, #HTTP_404, "text/plain; charset=utf-8", "404 Not Found")
        ProcedureReturn #False
      EndIf
    Else
      SendTextResponse(connection, #HTTP_404, "text/plain; charset=utf-8", "404 Not Found")
      ProcedureReturn #False
    EndIf
  EndIf

  ; Common metadata
  ext      = LCase(GetExtensionPart(fsPath))
  mimeType = GetMimeType(ext)
  etag     = BuildETag(fsPath)
  mtime    = GetFileDate(fsPath, #PB_Date_Modified)

  ; --- Pre-compressed .gz sidecar ---
  If FindString(acceptEncoding, "gzip") > 0
    Protected gzPath.s = fsPath + ".gz"
    Protected gzSize.i = FileSize(gzPath)
    If gzSize >= 0
      *buffer = AllocateMemory(gzSize + 1)
      If *buffer
        file = ReadFile(#PB_Any, gzPath)
        If file
          If gzSize > 0 : ReadData(file, *buffer, gzSize) : EndIf
          CloseFile(file)
          extraHeaders  = "Content-Type: "     + mimeType     + #CRLF$
          extraHeaders + "Content-Encoding: "  + "gzip"       + #CRLF$
          extraHeaders + "ETag: "              + etag         + #CRLF$
          extraHeaders + "Last-Modified: "     + HTTPDate(mtime) + #CRLF$
          extraHeaders + "Cache-Control: "     + "max-age=0"  + #CRLF$
          extraHeaders + "Vary: "              + "Accept-Encoding" + #CRLF$
          SendNetworkString(connection, BuildResponseHeaders(#HTTP_200, extraHeaders, gzSize), #PB_Ascii)
          If gzSize > 0 : SendNetworkData(connection, *buffer, gzSize) : EndIf
          FreeMemory(*buffer)
          ProcedureReturn #True
        EndIf
        FreeMemory(*buffer)
      EndIf
    EndIf
  EndIf

  ; --- 304 Not Modified (ETag match) ---
  If ifNoneMatch <> "" And ifNoneMatch = etag
    Protected hdr304.s = "ETag: " + etag + #CRLF$ + "Cache-Control: max-age=0" + #CRLF$
    SendNetworkString(connection, BuildResponseHeaders(#HTTP_304, hdr304, 0), #PB_Ascii)
    ProcedureReturn #True
  EndIf

  ; --- Range request (206 Partial Content) ---
  If rangeHeader <> ""
    Protected range.RangeSpec
    If ParseRangeHeader(rangeHeader, fileSize, @range)
      ProcedureReturn SendPartialResponse(connection, fsPath, @range, mimeType, fileSize)
    Else
      ; 416 Range Not Satisfiable
      Protected hdr416.s = "Content-Range: bytes */" + Str(fileSize) + #CRLF$
      SendNetworkString(connection, BuildResponseHeaders(#HTTP_416, hdr416, 0), #PB_Ascii)
      ProcedureReturn #False
    EndIf
  EndIf

  ; --- Regular 200 response ---
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

  If fileSize > 0 : ReadData(file, *buffer, fileSize) : EndIf
  CloseFile(file)

  extraHeaders  = "Content-Type: "  + mimeType        + #CRLF$
  extraHeaders + "ETag: "           + etag             + #CRLF$
  extraHeaders + "Last-Modified: "  + HTTPDate(mtime)  + #CRLF$
  extraHeaders + "Cache-Control: "  + "max-age=0"      + #CRLF$

  SendNetworkString(connection, BuildResponseHeaders(#HTTP_200, extraHeaders, fileSize), #PB_Ascii)
  If fileSize > 0 : SendNetworkData(connection, *buffer, fileSize) : EndIf
  FreeMemory(*buffer)
  ProcedureReturn #True
EndProcedure
