; Middleware.pbi — middleware chain infrastructure + individual middleware
; Include with: XIncludeFile "Middleware.pbi"
; Provides: RegisterMiddleware(), CallNext(), RunRequest(), BuildChain()
;           Middleware_Rewrite, Middleware_IndexFile, Middleware_CleanUrls,
;           Middleware_HiddenPath, Middleware_ETag304, Middleware_GzipSidecar,
;           Middleware_HandleAll
;
; Memory rules (from Section 7 of modular-refactor-plan.md):
;   Rule 1: The chain runner owns the final resp\Body and always frees it.
;   Rule 2: A middleware that replaces resp\Body must free the old one first.
;   Rule 3: A middleware that short-circuits must set resp\Body or leave it 0.
;
; Dependencies (managed by main.pb and tests/TestCommon.pbi):
;   Global.pbi, Types.pbi, HttpParser.pbi, HttpResponse.pbi, MimeTypes.pbi,
;   DateHelper.pbi, Logger.pbi, FileServer.pbi, DirectoryListing.pbi,
;   RangeParser.pbi, EmbeddedAssets.pbi, RewriteEngine.pbi

; --- Middleware function signature ---
; Returns #True if it handled the request, #False to pass to next
Prototype.i MiddlewareHandler(*req.HttpRequest, *resp.ResponseBuffer, *mCtx.MiddlewareContext)

; --- Chain storage (read-only after BuildChain) ---
; NOTE: PureBasic does not allow Prototype types in arrays. Store as integers
; and cast to a Prototype variable when calling.
#MAX_CHAIN = 16
Global Dim g_Chain.i(#MAX_CHAIN)
Global g_ChainCount.i = 0

; RegisterMiddleware(*handler) — add a middleware to the chain during startup
Procedure RegisterMiddleware(*handler)
  If g_ChainCount < #MAX_CHAIN
    g_Chain(g_ChainCount) = *handler
    g_ChainCount + 1
  EndIf
EndProcedure

; CallNext(*req, *resp, *mCtx) — advance to the next middleware in the chain
Procedure.i CallNext(*req.HttpRequest, *resp.ResponseBuffer, *mCtx.MiddlewareContext)
  Protected handler.MiddlewareHandler
  *mCtx\ChainIndex + 1
  If *mCtx\ChainIndex >= g_ChainCount
    ProcedureReturn #False      ; end of chain — no handler matched
  EndIf
  handler = g_Chain(*mCtx\ChainIndex)
  ProcedureReturn handler(*req, *resp, *mCtx)
EndProcedure

; ── Utility ────────────────────────────────────────────────────────────────

; BuildFsPath(docRoot, urlPath) — build a filesystem path from doc root + URL path
; Strips trailing separator from docRoot; converts "/" to "\" on Windows.
Procedure.s BuildFsPath(docRoot.s, urlPath.s)
  If Right(docRoot, 1) = "/" Or Right(docRoot, 1) = "\"
    docRoot = Left(docRoot, Len(docRoot) - 1)
  EndIf
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    ProcedureReturn ReplaceString(docRoot + urlPath, "/", "\")
  CompilerElse
    ProcedureReturn docRoot + urlPath
  CompilerEndIf
EndProcedure

; ── Extracted Middleware ────────────────────────────────────────────────────

; Middleware_Rewrite — apply URL rewrite/redirect rules
; Redirect → short-circuit with 3xx. Rewrite → modify req\Path, CallNext.
Procedure.i Middleware_Rewrite(*req.HttpRequest, *resp.ResponseBuffer, *mCtx.MiddlewareContext)
  Protected *cfg.ServerConfig = *mCtx\Config
  Protected rwResult.RewriteResult
  Protected qPos.i

  If *req\Method = "GET"
    If ApplyRewrites(*req\Path, *cfg\RootDirectory, @rwResult)
      If rwResult\Action = 2   ; redirect
        *resp\StatusCode = rwResult\RedirCode
        *resp\Headers    = "Location: " + rwResult\RedirURL + #CRLF$
        *resp\Body       = 0
        *resp\BodySize   = 0
        *resp\Handled    = #True
        ProcedureReturn #True
      ElseIf rwResult\Action = 1   ; rewrite — update path
        qPos = FindString(rwResult\NewPath, "?")
        If qPos > 0
          *req\QueryString = Mid(rwResult\NewPath, qPos + 1)
          *req\Path        = Left(rwResult\NewPath, qPos - 1)
        Else
          *req\Path = rwResult\NewPath
        EndIf
      EndIf
    EndIf
  EndIf

  ProcedureReturn CallNext(*req, *resp, *mCtx)
EndProcedure

; Middleware_IndexFile — resolve directory → index file
; If path is a directory and an index file exists, rewrite req\Path. Otherwise pass through.
Procedure.i Middleware_IndexFile(*req.HttpRequest, *resp.ResponseBuffer, *mCtx.MiddlewareContext)
  Protected *cfg.ServerConfig = *mCtx\Config
  Protected fsPath.s = BuildFsPath(*cfg\RootDirectory, *req\Path)
  Protected resolvedPath.s, urlDir.s

  If FileSize(fsPath) = -2   ; directory
    resolvedPath = ResolveIndexFile(fsPath, *cfg\IndexFiles)
    If resolvedPath <> ""
      urlDir = *req\Path
      If Right(urlDir, 1) <> "/"
        urlDir + "/"
      EndIf
      *req\Path = urlDir + GetFilePart(resolvedPath)
    EndIf
  EndIf

  ProcedureReturn CallNext(*req, *resp, *mCtx)
EndProcedure

; Middleware_CleanUrls — try path + ".html" for extensionless paths
Procedure.i Middleware_CleanUrls(*req.HttpRequest, *resp.ResponseBuffer, *mCtx.MiddlewareContext)
  Protected *cfg.ServerConfig = *mCtx\Config
  Protected fsPath.s

  If *cfg\CleanUrls And GetExtensionPart(*req\Path) = ""
    fsPath = BuildFsPath(*cfg\RootDirectory, *req\Path)
    If FileSize(fsPath) < 0
      If FileSize(fsPath + ".html") >= 0
        *req\Path = *req\Path + ".html"
      EndIf
    EndIf
  EndIf

  ProcedureReturn CallNext(*req, *resp, *mCtx)
EndProcedure

; Middleware_HiddenPath — block requests to hidden paths (.git, .env, etc.)
Procedure.i Middleware_HiddenPath(*req.HttpRequest, *resp.ResponseBuffer, *mCtx.MiddlewareContext)
  Protected *cfg.ServerConfig = *mCtx\Config

  If *cfg\HiddenPatterns <> "" And IsHiddenPath(*req\Path, *cfg\HiddenPatterns)
    LogError("error", "Forbidden: " + *req\Path)
    FillTextResponse(*resp, #HTTP_403, "text/plain; charset=utf-8", "403 Forbidden")
    ProcedureReturn #True
  EndIf

  ProcedureReturn CallNext(*req, *resp, *mCtx)
EndProcedure

; Middleware_ETag304 — return 304 Not Modified when ETag matches
Procedure.i Middleware_ETag304(*req.HttpRequest, *resp.ResponseBuffer, *mCtx.MiddlewareContext)
  Protected *cfg.ServerConfig = *mCtx\Config
  Protected ifNoneMatch.s = GetHeader(*req\RawHeaders, "If-None-Match")
  Protected fsPath.s, etag.s

  If ifNoneMatch <> ""
    fsPath = BuildFsPath(*cfg\RootDirectory, *req\Path)
    etag   = BuildETag(fsPath)
    If etag <> "" And ifNoneMatch = etag
      *resp\StatusCode = #HTTP_304
      *resp\Headers    = "ETag: " + etag + #CRLF$ + "Cache-Control: max-age=0" + #CRLF$
      *resp\Body       = 0
      *resp\BodySize   = 0
      *resp\Handled    = #True
      ProcedureReturn #True
    EndIf
  EndIf

  ProcedureReturn CallNext(*req, *resp, *mCtx)
EndProcedure

; Middleware_GzipSidecar — serve pre-compressed .gz sidecar files
Procedure.i Middleware_GzipSidecar(*req.HttpRequest, *resp.ResponseBuffer, *mCtx.MiddlewareContext)
  Protected *cfg.ServerConfig = *mCtx\Config
  Protected acceptEncoding.s = GetHeader(*req\RawHeaders, "Accept-Encoding")
  Protected fsPath.s, gzPath.s, gzSize.i
  Protected ext.s, mimeType.s, etag.s, mtime.q, extraHeaders.s
  Protected *buffer, file.i

  If FindString(acceptEncoding, "gzip") = 0
    ProcedureReturn CallNext(*req, *resp, *mCtx)
  EndIf

  fsPath = BuildFsPath(*cfg\RootDirectory, *req\Path)
  gzPath = fsPath + ".gz"
  gzSize = FileSize(gzPath)

  If gzSize < 0
    ProcedureReturn CallNext(*req, *resp, *mCtx)
  EndIf

  *buffer = AllocateMemory(gzSize + 1)
  If *buffer = 0
    ProcedureReturn CallNext(*req, *resp, *mCtx)
  EndIf

  file = ReadFile(#PB_Any, gzPath)
  If file = 0
    FreeMemory(*buffer)
    ProcedureReturn CallNext(*req, *resp, *mCtx)
  EndIf

  If gzSize > 0 : ReadData(file, *buffer, gzSize) : EndIf
  CloseFile(file)

  ; Metadata from the original (uncompressed) file
  ext      = LCase(GetExtensionPart(fsPath))
  mimeType = GetMimeType(ext)
  etag     = BuildETag(fsPath)
  mtime    = GetFileDate(fsPath, #PB_Date_Modified)

  extraHeaders  = "Content-Type: "     + mimeType          + #CRLF$
  extraHeaders + "Content-Encoding: "  + "gzip"            + #CRLF$
  extraHeaders + "ETag: "              + etag              + #CRLF$
  extraHeaders + "Last-Modified: "     + HTTPDate(mtime)   + #CRLF$
  extraHeaders + "Cache-Control: "     + "max-age=0"       + #CRLF$
  extraHeaders + "Vary: "              + "Accept-Encoding" + #CRLF$

  *resp\StatusCode = #HTTP_200
  *resp\Headers    = extraHeaders
  *resp\Body       = *buffer
  *resp\BodySize   = gzSize
  *resp\Handled    = #True
  ProcedureReturn #True
EndProcedure

; ── HandleAll (monolithic — remaining logic) ───────────────────────────────

Procedure.i Middleware_HandleAll(*req.HttpRequest, *resp.ResponseBuffer, *mCtx.MiddlewareContext)
  Protected *cfg.ServerConfig = *mCtx\Config
  Protected urlPath.s, docRoot.s, indexList.s
  Protected fsPath.s, resolvedPath.s, ext.s, mimeType.s
  Protected fileSize.i, mtime.q, etag.s, extraHeaders.s
  Protected *buffer, file.i
  Protected rangeHeader.s

  ; --- Only handle GET requests ---
  If *req\Method <> "GET"
    FillTextResponse(*resp, #HTTP_400, "text/plain; charset=utf-8", "400 Bad Request")
    ProcedureReturn #True
  EndIf

  ; --- Try embedded assets ---
  If g_EmbeddedPack > 0
    Protected packPath.s = Mid(*req\Path, 2)
    If packPath = "" : packPath = "index.html" : EndIf
    Protected maxPackSize.i = 4 * 1024 * 1024
    Protected *packBuf = AllocateMemory(maxPackSize)
    If *packBuf
      Protected uncompSize.i = UncompressPackMemory(g_EmbeddedPack, *packBuf, maxPackSize, packPath)
      If uncompSize >= 0
        Protected packExt.s  = LCase(GetExtensionPart(packPath))
        Protected packMime.s = GetMimeType(packExt)
        *resp\StatusCode = #HTTP_200
        *resp\Headers    = "Content-Type: " + packMime + #CRLF$
        *resp\Body       = *packBuf
        *resp\BodySize   = uncompSize
        *resp\Handled    = #True
        ProcedureReturn #True
      EndIf
      FreeMemory(*packBuf)
    EndIf
  EndIf

  ; ── File serving ──

  urlPath   = *req\Path
  docRoot   = *cfg\RootDirectory
  indexList = *cfg\IndexFiles

  ; Extract request headers
  rangeHeader = GetHeader(*req\RawHeaders, "Range")

  ; Build filesystem path
  fsPath = BuildFsPath(docRoot, urlPath)

  fileSize = FileSize(fsPath)

  ; --- Directory handling (browse / 403 only — index resolution moved to Middleware_IndexFile) ---
  If fileSize = -2
    If *cfg\BrowseEnabled
      Protected listing.s = BuildDirectoryListing(fsPath, urlPath)
      If listing <> ""
        FillTextResponse(*resp, #HTTP_200, "text/html; charset=utf-8", listing)
        ProcedureReturn #True
      EndIf
      LogError("error", "BuildDirectoryListing failed: " + fsPath)
      FillTextResponse(*resp, #HTTP_500, "text/plain; charset=utf-8", "500 Internal Server Error")
      ProcedureReturn #True
    Else
      LogError("warn", "Directory listing disabled: " + urlPath)
      FillTextResponse(*resp, #HTTP_403, "text/plain; charset=utf-8", "403 Forbidden")
      ProcedureReturn #True
    EndIf
  EndIf

  ; --- File not found ---
  If fileSize < 0
    If *cfg\SpaFallback
      resolvedPath = ResolveIndexFile(docRoot + "/", indexList)
      If resolvedPath <> ""
        fsPath   = resolvedPath
        fileSize = FileSize(fsPath)
      Else
        LogError("error", "Not found (SPA: no root index): " + urlPath)
        FillTextResponse(*resp, #HTTP_404, "text/plain; charset=utf-8", "404 Not Found")
        ProcedureReturn #True
      EndIf
    Else
      LogError("error", "File not found: " + fsPath)
      FillTextResponse(*resp, #HTTP_404, "text/plain; charset=utf-8", "404 Not Found")
      ProcedureReturn #True
    EndIf
  EndIf

  ; Common metadata
  ext      = LCase(GetExtensionPart(fsPath))
  mimeType = GetMimeType(ext)
  etag     = BuildETag(fsPath)
  mtime    = GetFileDate(fsPath, #PB_Date_Modified)

  ; --- Range request ---
  If rangeHeader <> ""
    Protected range.RangeSpec
    If ParseRangeHeader(rangeHeader, fileSize, @range)
      Protected rangeLen.i = range\End - range\Start + 1
      If rangeLen > 0
        *buffer = AllocateMemory(rangeLen + 1)
        If *buffer
          file = ReadFile(#PB_Any, fsPath)
          If file
            FileSeek(file, range\Start)
            ReadData(file, *buffer, rangeLen)
            CloseFile(file)
            Protected contentRange.s = "bytes " + Str(range\Start) + "-" + Str(range\End) + "/" + Str(fileSize)
            extraHeaders  = "Content-Type: "  + mimeType       + #CRLF$
            extraHeaders + "Content-Range: "  + contentRange   + #CRLF$
            extraHeaders + "Cache-Control: "  + "max-age=0"    + #CRLF$
            *resp\StatusCode = #HTTP_206
            *resp\Headers    = extraHeaders
            *resp\Body       = *buffer
            *resp\BodySize   = rangeLen
            *resp\Handled    = #True
            ProcedureReturn #True
          EndIf
          FreeMemory(*buffer)
        EndIf
      EndIf
      FillTextResponse(*resp, #HTTP_500, "text/plain; charset=utf-8", "500 Internal Server Error")
      ProcedureReturn #True
    Else
      *resp\StatusCode = #HTTP_416
      *resp\Headers    = "Content-Range: bytes */" + Str(fileSize) + #CRLF$
      *resp\Body       = 0
      *resp\BodySize   = 0
      *resp\Handled    = #True
      ProcedureReturn #True
    EndIf
  EndIf

  ; --- Regular 200 ---
  *buffer = AllocateMemory(fileSize + 1)
  If *buffer = 0
    LogError("error", "Out of memory serving: " + fsPath)
    FillTextResponse(*resp, #HTTP_500, "text/plain; charset=utf-8", "500 Internal Server Error")
    ProcedureReturn #True
  EndIf

  file = ReadFile(#PB_Any, fsPath)
  If file = 0
    FreeMemory(*buffer)
    LogError("error", "Cannot open file: " + fsPath)
    FillTextResponse(*resp, #HTTP_500, "text/plain; charset=utf-8", "500 Internal Server Error")
    ProcedureReturn #True
  EndIf

  If fileSize > 0 : ReadData(file, *buffer, fileSize) : EndIf
  CloseFile(file)

  extraHeaders  = "Content-Type: "  + mimeType        + #CRLF$
  extraHeaders + "ETag: "           + etag             + #CRLF$
  extraHeaders + "Last-Modified: "  + HTTPDate(mtime)  + #CRLF$
  extraHeaders + "Cache-Control: "  + "max-age=0"      + #CRLF$

  *resp\StatusCode = #HTTP_200
  *resp\Headers    = extraHeaders
  *resp\Body       = *buffer
  *resp\BodySize   = fileSize
  *resp\Handled    = #True
  ProcedureReturn #True
EndProcedure

; ────────────────────────────────────────────────────────────────────────────
; RunRequest — chain runner; the single point of network I/O and memory cleanup
; ────────────────────────────────────────────────────────────────────────────
Procedure.i RunRequest(connection.i, raw.s, *cfg.ServerConfig)
  Protected req.HttpRequest
  Protected resp.ResponseBuffer
  Protected mCtx.MiddlewareContext
  Protected clientIP.s   = IPString(GetClientIP(connection))
  Protected referer.s, userAgent.s

  ; Parse request
  If Not ParseHttpRequest(raw, req)
    SendTextResponse(connection, #HTTP_400, "text/plain; charset=utf-8", "400 Bad Request")
    LogAccess(clientIP, "?", "/", "HTTP/1.1", #HTTP_400, 0, "", "")
    ProcedureReturn #False
  EndIf

  referer   = GetHeader(req\RawHeaders, "Referer")
  userAgent = GetHeader(req\RawHeaders, "User-Agent")

  ; Initialize response buffer (empty)
  resp\StatusCode = 0
  resp\Headers    = ""
  resp\Body       = 0
  resp\BodySize   = 0
  resp\Handled    = #False

  ; Initialize middleware context
  mCtx\ChainIndex = -1
  mCtx\Connection = connection
  mCtx\Config     = *cfg
  mCtx\BytesSent  = 0

  ; Run the chain
  CallNext(@req, @resp, @mCtx)

  ; --- Single point of network I/O ---
  If resp\Handled
    SendNetworkString(connection, BuildResponseHeaders(resp\StatusCode, resp\Headers, resp\BodySize), #PB_Ascii)
    If resp\Body And resp\BodySize > 0
      SendNetworkData(connection, resp\Body, resp\BodySize)
    EndIf
    mCtx\BytesSent = resp\BodySize
  Else
    resp\StatusCode = #HTTP_404
    SendTextResponse(connection, #HTTP_404, "text/plain; charset=utf-8", "404 Not Found")
  EndIf

  ; --- Single point of memory cleanup ---
  If resp\Body
    FreeMemory(resp\Body)
  EndIf

  ; Access logging (always runs)
  LogAccess(clientIP, req\Method, req\Path, req\Version, resp\StatusCode, mCtx\BytesSent, referer, userAgent)

  ProcedureReturn resp\Handled
EndProcedure

; BuildChain() — register middleware in directive order (called once at startup)
Procedure BuildChain()
  g_ChainCount = 0
  RegisterMiddleware(@Middleware_Rewrite())
  RegisterMiddleware(@Middleware_IndexFile())
  RegisterMiddleware(@Middleware_CleanUrls())
  RegisterMiddleware(@Middleware_HiddenPath())
  RegisterMiddleware(@Middleware_ETag304())
  RegisterMiddleware(@Middleware_GzipSidecar())
  RegisterMiddleware(@Middleware_HandleAll())
EndProcedure
