; Middleware.pbi — middleware chain infrastructure + individual middleware
; Include with: XIncludeFile "Middleware.pbi"
; Provides: RegisterMiddleware(), CallNext(), RunRequest(), BuildChain()
;           FillErrorResponse, Middleware_Rewrite, Middleware_HealthCheck,
;           Middleware_IndexFile, Middleware_CleanUrls, Middleware_SpaFallback,
;           Middleware_HiddenPath, Middleware_Cors, Middleware_BasicAuth,
;           Middleware_SecurityHeaders, Middleware_ETag304,
;           Middleware_GzipCompress, Middleware_GzipSidecar,
;           Middleware_EmbeddedAssets, Middleware_FileServer,
;           Middleware_DirectoryListing, PlainWriter, GzipCompressBuffer
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

; FillErrorResponse — serve a custom error page (if configured), else fall back to plain text
Procedure FillErrorResponse(*resp.ResponseBuffer, *cfg.ServerConfig, statusCode.i, fallbackMsg.s)
  Protected fsPath.s, fileSize.i, *buffer, file.i

  If *cfg\ErrorPagesDir <> ""
    fsPath = *cfg\ErrorPagesDir + #SEP + Str(statusCode) + ".html"
    fileSize = FileSize(fsPath)
    If fileSize > 0 And fileSize < 1048576  ; cap at 1 MB
      *buffer = AllocateMemory(fileSize + 1)
      If *buffer
        file = ReadFile(#PB_Any, fsPath)
        If file
          ReadData(file, *buffer, fileSize)
          CloseFile(file)
          *resp\StatusCode = statusCode
          *resp\Headers    = "Content-Type: text/html; charset=utf-8" + #CRLF$
          *resp\Body       = *buffer
          *resp\BodySize   = fileSize
          *resp\Handled    = #True
          ProcedureReturn
        EndIf
        FreeMemory(*buffer)
      EndIf
    EndIf
  EndIf

  ; Fallback to plain text
  FillTextResponse(*resp, statusCode, "text/plain; charset=utf-8", fallbackMsg)
EndProcedure

; ── PlainWriter — sends bytes directly to TCP socket ───────────────────────

Procedure.i PlainWrite(*self.ResponseWriter, *data, length.i)
  If length > 0
    ProcedureReturn SendNetworkData(*self\connection, *data, length)
  EndIf
  ProcedureReturn 0
EndProcedure

Procedure PlainFlush(*self.ResponseWriter)
  ; Nothing to flush — data already sent to network
EndProcedure

Procedure InitPlainWriter(*w.ResponseWriter, connection.i)
  *w\Write      = @PlainWrite()
  *w\Flush      = @PlainFlush()
  *w\inner      = 0
  *w\ctx        = 0
  *w\connection = connection
EndProcedure

; ── Gzip compression helper ───────────────────────────────────────────────
; Uses CompressMemory (zlib format) + manual gzip wrapper.
; CompressMemory with #PB_PackerPlugin_Zip produces zlib format:
;   2-byte zlib header + deflate data + 4-byte Adler-32
; We strip the zlib framing and wrap with gzip header/trailer.

; GzipCompressBuffer(*input, inputSize, *outSize) — compress to gzip format
; Allocates and returns a new buffer containing gzip data.
; Caller must FreeMemory() the returned buffer. Returns 0 on failure.
; *outSize receives the compressed size.
Procedure.i GzipCompressBuffer(*input, inputSize.i, *outSize.Integer)
  If inputSize <= 0 Or *input = 0
    *outSize\i = 0
    ProcedureReturn 0
  EndIf

  ; Compress with zlib format
  UseZipPacker()
  Protected zlibCap.i = inputSize + inputSize / 10 + 256
  Protected *zlibOut = AllocateMemory(zlibCap)
  If *zlibOut = 0
    *outSize\i = 0
    ProcedureReturn 0
  EndIf

  Protected zlibSize.i = CompressMemory(*input, inputSize, *zlibOut, zlibCap, #PB_PackerPlugin_Zip, 6)
  If zlibSize < 7   ; need at least 2-byte header + 1 byte data + 4-byte trailer
    FreeMemory(*zlibOut)
    *outSize\i = 0
    ProcedureReturn 0
  EndIf

  ; Extract raw deflate: strip 2-byte zlib header and 4-byte Adler-32 trailer
  Protected deflateSize.i = zlibSize - 6
  Protected *deflateData  = *zlibOut + 2

  ; Compute CRC32 of original uncompressed data
  UseCRC32Fingerprint()
  Protected crcHex.s = Fingerprint(*input, inputSize, #PB_Cipher_CRC32)
  Protected crc32.l  = Val("$" + crcHex)

  ; Build gzip output: 10-byte header + deflate + 8-byte trailer
  Protected gzipSize.i = 10 + deflateSize + 8
  Protected *gzip = AllocateMemory(gzipSize)
  If *gzip = 0
    FreeMemory(*zlibOut)
    *outSize\i = 0
    ProcedureReturn 0
  EndIf

  ; Gzip header (10 bytes)
  PokeA(*gzip + 0, $1F)   ; magic
  PokeA(*gzip + 1, $8B)   ; magic
  PokeA(*gzip + 2, $08)   ; method: deflate
  PokeA(*gzip + 3, $00)   ; flags: none
  PokeL(*gzip + 4, 0)     ; mtime: none
  PokeA(*gzip + 8, $00)   ; xfl
  PokeA(*gzip + 9, $03)   ; OS: Unix

  ; Raw deflate data
  CopyMemory(*deflateData, *gzip + 10, deflateSize)

  ; Gzip trailer (8 bytes): CRC32 + original size (both little-endian)
  PokeL(*gzip + 10 + deflateSize, crc32)
  PokeL(*gzip + 10 + deflateSize + 4, inputSize)

  FreeMemory(*zlibOut)
  *outSize\i = gzipSize
  ProcedureReturn *gzip
EndProcedure

; IsCompressibleType(contentType) — check if this MIME type benefits from compression
Procedure.i IsCompressibleType(headers.s)
  Protected ct.s = LCase(headers)
  If FindString(ct, "text/") > 0 : ProcedureReturn #True : EndIf
  If FindString(ct, "application/json") > 0 : ProcedureReturn #True : EndIf
  If FindString(ct, "application/javascript") > 0 : ProcedureReturn #True : EndIf
  If FindString(ct, "application/xml") > 0 : ProcedureReturn #True : EndIf
  If FindString(ct, "image/svg+xml") > 0 : ProcedureReturn #True : EndIf
  ProcedureReturn #False
EndProcedure

; ── Health Check (short-circuit) ──────────────────────────────────────────

; Middleware_HealthCheck — short-circuit health check endpoint with 200 JSON
Procedure.i Middleware_HealthCheck(*req.HttpRequest, *resp.ResponseBuffer, *mCtx.MiddlewareContext)
  Protected *cfg.ServerConfig = *mCtx\Config
  If *cfg\HealthPath = "" Or *req\Path <> *cfg\HealthPath
    ProcedureReturn CallNext(*req, *resp, *mCtx)
  EndIf
  FillTextResponse(*resp, #HTTP_200, "application/json; charset=utf-8", ~"{\"status\":\"ok\"}")
  ProcedureReturn #True
EndProcedure

; ── Request Modifiers (pre-processing) ─────────────────────────────────────

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

; Middleware_SpaFallback — rewrite to root index when file not found (SPA mode)
Procedure.i Middleware_SpaFallback(*req.HttpRequest, *resp.ResponseBuffer, *mCtx.MiddlewareContext)
  Protected *cfg.ServerConfig = *mCtx\Config
  Protected fsPath.s, resolvedPath.s

  If *cfg\SpaFallback
    fsPath = BuildFsPath(*cfg\RootDirectory, *req\Path)
    If FileSize(fsPath) < 0
      resolvedPath = ResolveIndexFile(BuildFsPath(*cfg\RootDirectory, "/"), *cfg\IndexFiles)
      If resolvedPath <> ""
        *req\Path = "/" + GetFilePart(resolvedPath)
      Else
        LogError("error", "Not found (SPA: no root index): " + *req\Path)
        FillErrorResponse(*resp, *cfg, #HTTP_404, "404 Not Found")
        ProcedureReturn #True
      EndIf
    EndIf
  EndIf

  ProcedureReturn CallNext(*req, *resp, *mCtx)
EndProcedure

; ── Access Control (short-circuit) ─────────────────────────────────────────

; Middleware_HiddenPath — block requests to hidden paths (.git, .env, etc.)
Procedure.i Middleware_HiddenPath(*req.HttpRequest, *resp.ResponseBuffer, *mCtx.MiddlewareContext)
  Protected *cfg.ServerConfig = *mCtx\Config

  If *cfg\HiddenPatterns <> "" And IsHiddenPath(*req\Path, *cfg\HiddenPatterns)
    LogError("error", "Forbidden: " + *req\Path)
    FillErrorResponse(*resp, *cfg, #HTTP_403, "403 Forbidden")
    ProcedureReturn #True
  EndIf

  ProcedureReturn CallNext(*req, *resp, *mCtx)
EndProcedure

; ── CORS (hybrid: preflight short-circuit + post-processing) ─────────────

; Middleware_Cors — handle CORS preflight and append CORS headers
Procedure.i Middleware_Cors(*req.HttpRequest, *resp.ResponseBuffer, *mCtx.MiddlewareContext)
  Protected *cfg.ServerConfig = *mCtx\Config
  Protected origin.s

  If Not *cfg\CorsEnabled
    ProcedureReturn CallNext(*req, *resp, *mCtx)
  EndIf

  origin = *cfg\CorsOrigin
  If origin = "" : origin = "*" : EndIf

  ; OPTIONS preflight → short-circuit 204
  If *req\Method = "OPTIONS"
    *resp\StatusCode = #HTTP_204
    *resp\Headers    = "Access-Control-Allow-Origin: " + origin + #CRLF$
    *resp\Headers  + "Access-Control-Allow-Methods: GET, OPTIONS" + #CRLF$
    *resp\Headers  + "Access-Control-Allow-Headers: Content-Type, If-None-Match, Range" + #CRLF$
    *resp\Headers  + "Access-Control-Max-Age: 86400" + #CRLF$
    *resp\Body       = 0
    *resp\BodySize   = 0
    *resp\Handled    = #True
    ProcedureReturn #True
  EndIf

  ; Normal request → post-process
  Protected result.i = CallNext(*req, *resp, *mCtx)
  If *resp\Handled
    *resp\Headers + "Access-Control-Allow-Origin: " + origin + #CRLF$
    *resp\Headers + "Access-Control-Expose-Headers: Content-Length, Content-Range, ETag" + #CRLF$
    *resp\Headers + "Vary: Origin" + #CRLF$
  EndIf
  ProcedureReturn result
EndProcedure

; ── Basic Auth (short-circuit) ────────────────────────────────────────────

; Middleware_BasicAuth — require HTTP Basic Authentication for all requests
Procedure.i Middleware_BasicAuth(*req.HttpRequest, *resp.ResponseBuffer, *mCtx.MiddlewareContext)
  Protected *cfg.ServerConfig = *mCtx\Config

  If *cfg\BasicAuthUser = ""
    ProcedureReturn CallNext(*req, *resp, *mCtx)
  EndIf

  Protected authHeader.s = GetHeader(*req\RawHeaders, "Authorization")

  If Left(authHeader, 6) = "Basic "
    Protected encoded.s = Mid(authHeader, 7)
    Protected decBufSize.i = Len(encoded) + 1
    Protected *decBuf = AllocateMemory(decBufSize)
    If *decBuf
      Protected decodedLen.i = Base64Decoder(encoded, *decBuf, decBufSize)
      If decodedLen > 0
        Protected decoded.s = PeekS(*decBuf, decodedLen, #PB_UTF8)
        FreeMemory(*decBuf)

        If decoded = *cfg\BasicAuthUser + ":" + *cfg\BasicAuthPass
          ProcedureReturn CallNext(*req, *resp, *mCtx)
        EndIf
      Else
        FreeMemory(*decBuf)
      EndIf
    EndIf
  EndIf

  ; Auth failed → 401
  FillErrorResponse(*resp, *cfg, #HTTP_401, "401 Unauthorized")
  *resp\Headers + "WWW-Authenticate: Basic realm=" + Chr(34) + "Protected" + Chr(34) + #CRLF$
  ProcedureReturn #True
EndProcedure

; ── Security Headers (post-processing) ───────────────────────────────────

; Middleware_SecurityHeaders — append security headers to handled responses
Procedure.i Middleware_SecurityHeaders(*req.HttpRequest, *resp.ResponseBuffer, *mCtx.MiddlewareContext)
  Protected *cfg.ServerConfig = *mCtx\Config
  Protected result.i = CallNext(*req, *resp, *mCtx)

  If Not *cfg\SecurityHeaders Or Not *resp\Handled
    ProcedureReturn result
  EndIf

  *resp\Headers + "X-Content-Type-Options: nosniff" + #CRLF$
  *resp\Headers + "X-Frame-Options: DENY" + #CRLF$
  *resp\Headers + "X-XSS-Protection: 1; mode=block" + #CRLF$
  *resp\Headers + "Referrer-Policy: strict-origin-when-cross-origin" + #CRLF$
  *resp\Headers + "Cross-Origin-Opener-Policy: same-origin" + #CRLF$

  ProcedureReturn result
EndProcedure

; ── Conditional Response (short-circuit) ───────────────────────────────────

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
      *resp\Headers    = "ETag: " + etag + #CRLF$ + "Cache-Control: max-age=" + Str(*cfg\CacheMaxAge) + #CRLF$
      *resp\Body       = 0
      *resp\BodySize   = 0
      *resp\Handled    = #True
      ProcedureReturn #True
    EndIf
  EndIf

  ProcedureReturn CallNext(*req, *resp, *mCtx)
EndProcedure

; ── Response Sidecar ───────────────────────────────────────────────────────

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
  extraHeaders + "Cache-Control: "     + "max-age=" + Str(*cfg\CacheMaxAge) + #CRLF$
  extraHeaders + "Vary: "              + "Accept-Encoding" + #CRLF$

  *resp\StatusCode = #HTTP_200
  *resp\Headers    = extraHeaders
  *resp\Body       = *buffer
  *resp\BodySize   = gzSize
  *resp\Handled    = #True
  ProcedureReturn #True
EndProcedure

; ── Dynamic Compression (post-processing) ──────────────────────────────────

; Middleware_GzipCompress — compress response body with gzip after downstream fills it
; Runs after ETag304/GzipSidecar, before terminal handlers in the chain.
; Skips compression when: disabled, body too small, non-compressible type,
;   client doesn't accept gzip, or Content-Encoding already set.
#GZIP_MIN_SIZE = 256

Procedure.i Middleware_GzipCompress(*req.HttpRequest, *resp.ResponseBuffer, *mCtx.MiddlewareContext)
  Protected *cfg.ServerConfig = *mCtx\Config

  ; Let downstream produce the response first
  Protected result.i = CallNext(*req, *resp, *mCtx)

  ; Skip if disabled, not handled, or no body
  If *cfg\NoGzip Or Not *resp\Handled Or *resp\Body = 0 Or *resp\BodySize < #GZIP_MIN_SIZE
    ProcedureReturn result
  EndIf

  ; Skip if client doesn't accept gzip
  Protected acceptEncoding.s = GetHeader(*req\RawHeaders, "Accept-Encoding")
  If FindString(acceptEncoding, "gzip") = 0
    ProcedureReturn result
  EndIf

  ; Skip if already compressed (e.g., GzipSidecar already served a .gz file)
  If FindString(*resp\Headers, "Content-Encoding:") > 0
    ProcedureReturn result
  EndIf

  ; Skip non-compressible types (images, video, zip, etc.)
  If Not IsCompressibleType(*resp\Headers)
    ProcedureReturn result
  EndIf

  ; Compress resp\Body → gzip
  Protected compressedSize.i
  Protected *compressed = GzipCompressBuffer(*resp\Body, *resp\BodySize, @compressedSize)
  If *compressed = 0 Or compressedSize >= *resp\BodySize
    ; Compression failed or didn't shrink — keep original
    If *compressed : FreeMemory(*compressed) : EndIf
    ProcedureReturn result
  EndIf

  ; Replace body with compressed version (Rule 2: free old first)
  FreeMemory(*resp\Body)
  *resp\Body     = *compressed
  *resp\BodySize = compressedSize
  *resp\Headers + "Content-Encoding: gzip" + #CRLF$
  *resp\Headers + "Vary: Accept-Encoding" + #CRLF$

  ProcedureReturn result
EndProcedure

; ── Terminal Handlers (produce the response body) ──────────────────────────

; Middleware_EmbeddedAssets — serve files from the in-memory asset pack
Procedure.i Middleware_EmbeddedAssets(*req.HttpRequest, *resp.ResponseBuffer, *mCtx.MiddlewareContext)
  If g_EmbeddedPack = 0
    ProcedureReturn CallNext(*req, *resp, *mCtx)
  EndIf

  Protected packPath.s = Mid(*req\Path, 2)
  If packPath = "" : packPath = "index.html" : EndIf

  Protected maxPackSize.i = 4 * 1024 * 1024
  Protected *packBuf = AllocateMemory(maxPackSize)
  If *packBuf = 0
    ProcedureReturn CallNext(*req, *resp, *mCtx)
  EndIf

  Protected uncompSize.i = UncompressPackMemory(g_EmbeddedPack, *packBuf, maxPackSize, packPath)
  If uncompSize < 0
    FreeMemory(*packBuf)
    ProcedureReturn CallNext(*req, *resp, *mCtx)
  EndIf

  Protected ext.s  = LCase(GetExtensionPart(packPath))
  Protected mime.s = GetMimeType(ext)
  *resp\StatusCode = #HTTP_200
  *resp\Headers    = "Content-Type: " + mime + #CRLF$
  *resp\Body       = *packBuf
  *resp\BodySize   = uncompSize
  *resp\Handled    = #True
  ProcedureReturn #True
EndProcedure

; Middleware_FileServer — serve files from disk (200 + 206 range responses)
Procedure.i Middleware_FileServer(*req.HttpRequest, *resp.ResponseBuffer, *mCtx.MiddlewareContext)
  Protected *cfg.ServerConfig = *mCtx\Config
  Protected fsPath.s = BuildFsPath(*cfg\RootDirectory, *req\Path)
  Protected fileSize.i = FileSize(fsPath)
  Protected ext.s, mimeType.s, etag.s, mtime.q, extraHeaders.s
  Protected *buffer, file.i
  Protected rangeHeader.s

  ; Not a regular file — let next handler try (DirListing, or runner 404)
  If fileSize < 0 Or fileSize = -2
    ProcedureReturn CallNext(*req, *resp, *mCtx)
  EndIf

  ; Compute metadata
  ext      = LCase(GetExtensionPart(fsPath))
  mimeType = GetMimeType(ext)
  etag     = BuildETag(fsPath)
  mtime    = GetFileDate(fsPath, #PB_Date_Modified)

  ; --- Range request (206 Partial Content) ---
  rangeHeader = GetHeader(*req\RawHeaders, "Range")
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
            extraHeaders + "Cache-Control: "  + "max-age=" + Str(*cfg\CacheMaxAge) + #CRLF$
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
      FillErrorResponse(*resp, *cfg, #HTTP_500, "500 Internal Server Error")
      ProcedureReturn #True
    Else
      ; 416 Range Not Satisfiable
      *resp\StatusCode = #HTTP_416
      *resp\Headers    = "Content-Range: bytes */" + Str(fileSize) + #CRLF$
      *resp\Body       = 0
      *resp\BodySize   = 0
      *resp\Handled    = #True
      ProcedureReturn #True
    EndIf
  EndIf

  ; --- Regular 200 response ---
  *buffer = AllocateMemory(fileSize + 1)
  If *buffer = 0
    LogError("error", "Out of memory serving: " + fsPath)
    FillErrorResponse(*resp, *cfg, #HTTP_500, "500 Internal Server Error")
    ProcedureReturn #True
  EndIf

  file = ReadFile(#PB_Any, fsPath)
  If file = 0
    FreeMemory(*buffer)
    LogError("error", "Cannot open file: " + fsPath)
    FillErrorResponse(*resp, *cfg, #HTTP_500, "500 Internal Server Error")
    ProcedureReturn #True
  EndIf

  If fileSize > 0 : ReadData(file, *buffer, fileSize) : EndIf
  CloseFile(file)

  extraHeaders  = "Content-Type: "  + mimeType        + #CRLF$
  extraHeaders + "ETag: "           + etag             + #CRLF$
  extraHeaders + "Last-Modified: "  + HTTPDate(mtime)  + #CRLF$
  extraHeaders + "Cache-Control: "  + "max-age=" + Str(*cfg\CacheMaxAge) + #CRLF$

  *resp\StatusCode = #HTTP_200
  *resp\Headers    = extraHeaders
  *resp\Body       = *buffer
  *resp\BodySize   = fileSize
  *resp\Handled    = #True
  ProcedureReturn #True
EndProcedure

; Middleware_DirectoryListing — generate HTML directory listing
Procedure.i Middleware_DirectoryListing(*req.HttpRequest, *resp.ResponseBuffer, *mCtx.MiddlewareContext)
  Protected *cfg.ServerConfig = *mCtx\Config
  Protected fsPath.s = BuildFsPath(*cfg\RootDirectory, *req\Path)

  If FileSize(fsPath) <> -2   ; not a directory
    ProcedureReturn CallNext(*req, *resp, *mCtx)
  EndIf

  If *cfg\BrowseEnabled
    Protected listing.s = BuildDirectoryListing(fsPath, *req\Path)
    If listing <> ""
      FillTextResponse(*resp, #HTTP_200, "text/html; charset=utf-8", listing)
      ProcedureReturn #True
    EndIf
    LogError("error", "BuildDirectoryListing failed: " + fsPath)
    FillErrorResponse(*resp, *cfg, #HTTP_500, "500 Internal Server Error")
    ProcedureReturn #True
  Else
    LogError("warn", "Directory listing disabled: " + *req\Path)
    FillErrorResponse(*resp, *cfg, #HTTP_403, "403 Forbidden")
    ProcedureReturn #True
  EndIf
EndProcedure

; ────────────────────────────────────────────────────────────────────────────
; RunRequest — chain runner; the single point of network I/O and memory cleanup
;
; Called from each worker thread via RunRequestWrapper (in main.pb).
; Flow: parse → method check → init buffer → run chain → send → free → log
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

  ; Only GET and OPTIONS are supported — reject everything else before running the chain
  If req\Method <> "GET" And req\Method <> "OPTIONS"
    SendTextResponse(connection, #HTTP_400, "text/plain; charset=utf-8", "400 Bad Request")
    LogAccess(clientIP, req\Method, req\Path, req\Version, #HTTP_400, 0, referer, userAgent)
    ProcedureReturn #False
  EndIf

  ; Initialize response buffer (empty)
  resp\StatusCode = 0
  resp\Headers    = ""
  resp\Body       = 0
  resp\BodySize   = 0
  resp\Handled    = #False

  ; Initialize middleware context
  mCtx\ChainIndex = -1           ; CallNext increments to 0 on first call
  mCtx\Connection = connection
  mCtx\Config     = *cfg
  mCtx\BytesSent  = 0

  ; Run the chain
  CallNext(@req, @resp, @mCtx)

  ; If no handler matched, fill a 404 error response
  If Not resp\Handled
    FillErrorResponse(@resp, *cfg, #HTTP_404, "404 Not Found")
  EndIf

  ; --- Single point of network I/O (via PlainWriter) ---
  Protected writer.ResponseWriter
  InitPlainWriter(@writer, connection)
  SendNetworkString(connection, BuildResponseHeaders(resp\StatusCode, resp\Headers, resp\BodySize), #PB_Ascii)
  If resp\Body And resp\BodySize > 0
    writer\Write(@writer, resp\Body, resp\BodySize)
  EndIf
  writer\Flush(@writer)
  mCtx\BytesSent = resp\BodySize

  ; --- Single point of memory cleanup ---
  If resp\Body
    FreeMemory(resp\Body)
  EndIf

  ; Access logging (always runs)
  LogAccess(clientIP, req\Method, req\Path, req\Version, resp\StatusCode, mCtx\BytesSent, referer, userAgent)

  ProcedureReturn resp\Handled
EndProcedure

; BuildChain() — register middleware in directive order (called once at startup)
; Order follows Section 9 of modular-refactor-plan.md.
Procedure BuildChain()
  g_ChainCount = 0
  ; Request modifiers (pre-processing)
  RegisterMiddleware(@Middleware_Rewrite())
  ; Health check (short-circuit — early, before file-serving logic)
  RegisterMiddleware(@Middleware_HealthCheck())
  RegisterMiddleware(@Middleware_IndexFile())
  RegisterMiddleware(@Middleware_CleanUrls())
  RegisterMiddleware(@Middleware_SpaFallback())
  ; Access control (short-circuit)
  RegisterMiddleware(@Middleware_HiddenPath())
  ; CORS (hybrid: preflight short-circuit + post-processing)
  RegisterMiddleware(@Middleware_Cors())
  ; Basic auth (short-circuit)
  RegisterMiddleware(@Middleware_BasicAuth())
  ; Security headers (post-processing)
  RegisterMiddleware(@Middleware_SecurityHeaders())
  ; Conditional response (short-circuit)
  RegisterMiddleware(@Middleware_ETag304())
  ; Response sidecar
  RegisterMiddleware(@Middleware_GzipSidecar())
  ; Dynamic compression (post-processing — compresses resp\Body after terminal handlers)
  RegisterMiddleware(@Middleware_GzipCompress())
  ; Terminal handlers
  RegisterMiddleware(@Middleware_EmbeddedAssets())
  RegisterMiddleware(@Middleware_FileServer())
  RegisterMiddleware(@Middleware_DirectoryListing())
EndProcedure
