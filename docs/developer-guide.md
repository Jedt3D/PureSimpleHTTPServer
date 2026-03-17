# Developer Guide — Middleware Architecture

> PureSimpleHTTPServer v2.0.0+

## Architecture Overview

Every HTTP request flows through an ordered chain of middleware. Each middleware
receives a parsed request, an empty response buffer, and a context object:

```
Client → TCP → RunRequest() → [chain] → send → free → log

Chain:  Rewrite → IndexFile → CleanUrls → SpaFallback → HiddenPath
        → ETag304 → GzipSidecar → EmbeddedAssets → FileServer
        → DirectoryListing
```

A middleware can:

- **Pre-process:** Modify `*req\Path`, then call `CallNext()` to pass to the
  next middleware (e.g., Rewrite, IndexFile, CleanUrls, SpaFallback).
- **Short-circuit:** Fill `*resp` and return `#True` without calling
  `CallNext()` (e.g., HiddenPath → 403, ETag304 → 304).
- **Produce a response:** Read a file into `*resp\Body` and return `#True`
  (e.g., FileServer → 200, GzipSidecar → 200).

The chain runner (`RunRequest`) is the **single point** of network I/O and
memory cleanup. Middleware never call `SendNetwork*` directly.

### File Layout

```
src/
  Middleware.pbi    ← chain infra + all 10 middleware + RunRequest
  Types.pbi         ← ResponseBuffer, MiddlewareContext structures
  HttpResponse.pbi  ← FillTextResponse() for text responses
  FileServer.pbi    ← utility functions (ResolveIndexFile, BuildETag, IsHiddenPath)
  ...               ← everything else unchanged from v1.x
```

---

## How to Add a New Middleware

### 1. Write the procedure

All middleware share the same signature:

```purebasic
Procedure.i Middleware_YourFeature(*req.HttpRequest, *resp.ResponseBuffer, *mCtx.MiddlewareContext)
  Protected *cfg.ServerConfig = *mCtx\Config

  ; Your logic here. Use *req for the request, *cfg for configuration.

  ; Option A: short-circuit (handled)
  ;   Fill *resp, return #True.
  ;
  ; Option B: pass through
  ;   ProcedureReturn CallNext(*req, *resp, *mCtx)

  ProcedureReturn CallNext(*req, *resp, *mCtx)
EndProcedure
```

**Example — CORS headers (post-processing):**

```purebasic
Procedure.i Middleware_Cors(*req.HttpRequest, *resp.ResponseBuffer, *mCtx.MiddlewareContext)
  ; Let downstream produce the response first
  Protected result.i = CallNext(*req, *resp, *mCtx)

  ; Then append CORS headers to whatever was produced
  If *resp\Handled
    *resp\Headers + "Access-Control-Allow-Origin: *" + #CRLF$
  EndIf

  ProcedureReturn result
EndProcedure
```

### 2. Register in BuildChain()

Add one line at the correct position in `BuildChain()` (in Middleware.pbi):

```purebasic
Procedure BuildChain()
  g_ChainCount = 0
  RegisterMiddleware(@Middleware_Rewrite())
  RegisterMiddleware(@Middleware_IndexFile())
  RegisterMiddleware(@Middleware_CleanUrls())
  RegisterMiddleware(@Middleware_SpaFallback())
  RegisterMiddleware(@Middleware_HiddenPath())
  RegisterMiddleware(@Middleware_Cors())        ; ← new
  RegisterMiddleware(@Middleware_ETag304())
  RegisterMiddleware(@Middleware_GzipSidecar())
  RegisterMiddleware(@Middleware_EmbeddedAssets())
  RegisterMiddleware(@Middleware_FileServer())
  RegisterMiddleware(@Middleware_DirectoryListing())
EndProcedure
```

### 3. Add tests

Create a `ProcedureUnit` in `tests/test_middleware.pb`:

```purebasic
ProcedureUnit Cors_AddsHeader()
  ; ... set up cfg, req, resp, mCtx ...
  ; Register a dummy terminal handler in the chain so CallNext succeeds
  Protected result.i = Middleware_Cors(@req, @resp, @mCtx)
  Assert(FindString(resp\Headers, "Access-Control-Allow-Origin") > 0, "...")
  FreeResp(@resp)
EndProcedureUnit
```

---

## Directive Order and Why It Matters

Position in the chain determines when each middleware runs relative to others.
The order is fixed in `BuildChain()` and based on Caddy's directive ordering
philosophy:

```
Pos  Middleware              Type               Why this position
───  ──────────────────────  ─────────────────  ─────────────────────────────
 1   Middleware_Rewrite      Request modifier   Rewrite path BEFORE anything
                                                checks the filesystem
 2   Middleware_IndexFile    Request modifier   Resolve /dir/ → /dir/index.html
                                                BEFORE clean URLs tries .html
 3   Middleware_CleanUrls    Request modifier   Try /about → /about.html BEFORE
                                                SPA fallback rewrites everything
 4   Middleware_SpaFallback  Request modifier   Last-resort path rewrite — only
                                                if file still not found
 5   Middleware_HiddenPath   Access control     Block .git/.env AFTER path is
                                                finalized by all modifiers
 6   Middleware_ETag304      Conditional resp   Return 304 BEFORE reading file
                                                (saves disk I/O on cache hits)
 7   Middleware_GzipSidecar  Response sidecar   Serve .gz BEFORE full file read
                                                (pre-compressed is cheaper)
 8   Middleware_EmbedAssets  Terminal handler   Try in-memory pack BEFORE disk
 9   Middleware_FileServer   Terminal handler   Read file from disk — primary
                                                content source
10   Middleware_DirListing   Terminal handler   Directory listing — last resort
                                                before 404
```

**Rules of thumb:**

- Request modifiers go first (they change what downstream sees).
- Access control goes after modifiers (check the final path, not the original).
- Conditional responses go before terminal handlers (avoid I/O when possible).
- Terminal handlers go last and do NOT call `CallNext()` on success.

---

## Memory Management Rules for ResponseBuffer

Three rules prevent leaks and double-frees:

### Rule 1: The chain runner always frees `resp\Body`

```purebasic
; In RunRequest(), after sending:
If resp\Body : FreeMemory(resp\Body) : EndIf
```

Middleware never need to free `resp\Body` after setting it. The runner handles
cleanup unconditionally.

### Rule 2: Replacing `resp\Body` requires freeing the old one first

If a post-processing middleware replaces the body (e.g., future gzip
compression), it must free the old buffer:

```purebasic
; Example: future gzip middleware
Procedure.i Middleware_GzipCompress(...)
  CallNext(*req, *resp, *mCtx)           ; downstream fills resp\Body

  If *resp\Handled And *resp\BodySize > threshold
    *compressed = CompressBuffer(...)
    FreeMemory(*resp\Body)               ; free old buffer
    *resp\Body     = *compressed          ; set new buffer
    *resp\BodySize = compressedSize
  EndIf

  ProcedureReturn *resp\Handled
EndProcedure
```

### Rule 3: Short-circuit middleware set `resp\Body` or leave it at 0

```purebasic
; 304 Not Modified — no body, nothing to free
*resp\StatusCode = #HTTP_304
*resp\Headers    = "ETag: " + etag + #CRLF$
*resp\Body       = 0          ; runner skips FreeMemory for null
*resp\BodySize   = 0
*resp\Handled    = #True
ProcedureReturn #True
```

### Why this is safe

- Only one owner of `resp\Body` at any time: either the middleware that last
  set it, or the chain runner after all middleware return.
- The chain is strictly sequential within one thread — no stale pointers.
- `ResponseBuffer` is stack-local per worker thread — no cross-thread sharing.

---

## Utility Functions

### BuildFsPath(docRoot.s, urlPath.s) → String

Builds a filesystem path from the document root and URL path. Handles trailing
separator stripping and Windows path conversion. Used by most middleware:

```purebasic
Protected fsPath.s = BuildFsPath(*cfg\RootDirectory, *req\Path)
```

### FillTextResponse(*resp, statusCode, contentType, body)

Fills a `ResponseBuffer` with a UTF-8 text response. Allocates the body
buffer — the chain runner frees it:

```purebasic
FillTextResponse(*resp, #HTTP_403, "text/plain; charset=utf-8", "403 Forbidden")
ProcedureReturn #True
```

---

## Testing Middleware

Middleware can be tested in isolation by calling them directly with crafted
structures. See `tests/test_middleware.pb` for examples.

Key pattern:

```purebasic
ProcedureUnit MyMiddleware_Test()
  Protected cfg.ServerConfig
  cfg\RootDirectory = g_TestRoot
  cfg\IndexFiles    = "index.html"

  Protected req.HttpRequest
  req\Method = "GET" : req\Path = "/test"

  Protected resp.ResponseBuffer
  resp\StatusCode = 0 : resp\Body = 0 : resp\Handled = #False

  Protected mCtx.MiddlewareContext
  mCtx\ChainIndex = 0 : mCtx\Config = @cfg

  ; Ensure chain is empty so CallNext returns #False
  g_ChainCount = 0

  Protected result.i = Middleware_YourFeature(@req, @resp, @mCtx)
  Assert(...)

  If resp\Body : FreeMemory(resp\Body) : EndIf
EndProcedureUnit
```
