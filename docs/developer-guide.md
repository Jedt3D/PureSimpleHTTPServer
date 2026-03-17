# Developer Guide — Middleware Architecture

> PureSimpleHTTPServer v2.0.0+

## Architecture Overview

Every HTTP request flows through an ordered chain of middleware. Each middleware
receives a parsed request, an empty response buffer, and a context object:

```
Client → TCP → RunRequest() → [chain] → send → free → log

Chain:  Rewrite → HealthCheck → IndexFile → CleanUrls → SpaFallback
        → HiddenPath → Cors → SecurityHeaders → ETag304 → GzipSidecar
        → GzipCompress → EmbeddedAssets → FileServer → DirectoryListing
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
  Middleware.pbi    ← chain infra + all 14 middleware + RunRequest
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

**Example — Rate Limiter (post-processing):**

```purebasic
Procedure.i Middleware_RateLimit(*req.HttpRequest, *resp.ResponseBuffer, *mCtx.MiddlewareContext)
  ; Let downstream produce the response first
  Protected result.i = CallNext(*req, *resp, *mCtx)

  ; Then append rate limit headers to whatever was produced
  If *resp\Handled
    *resp\Headers + "X-RateLimit-Remaining: 99" + #CRLF$
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
  RegisterMiddleware(@Middleware_HealthCheck())
  RegisterMiddleware(@Middleware_IndexFile())
  RegisterMiddleware(@Middleware_CleanUrls())
  RegisterMiddleware(@Middleware_SpaFallback())
  RegisterMiddleware(@Middleware_HiddenPath())
  RegisterMiddleware(@Middleware_Cors())
  RegisterMiddleware(@Middleware_SecurityHeaders())
  RegisterMiddleware(@Middleware_ETag304())
  RegisterMiddleware(@Middleware_GzipSidecar())
  RegisterMiddleware(@Middleware_GzipCompress())
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
 2   Middleware_HealthCheck  Short-circuit      Early — skips all file-serving
                                                logic for load balancer probes
 3   Middleware_IndexFile    Request modifier   Resolve /dir/ → /dir/index.html
                                                BEFORE clean URLs tries .html
 4   Middleware_CleanUrls    Request modifier   Try /about → /about.html BEFORE
                                                SPA fallback rewrites everything
 5   Middleware_SpaFallback  Request modifier   Last-resort path rewrite — only
                                                if file still not found
 6   Middleware_HiddenPath   Access control     Block .git/.env AFTER path is
                                                finalized by all modifiers
 7   Middleware_Cors         Hybrid             OPTIONS preflight short-circuit;
                                                GET post-processing (CORS headers)
 8   Middleware_SecHeaders   Post-processing    Append security headers after CORS
                                                so both header sets can coexist
 9   Middleware_ETag304      Conditional resp   Return 304 BEFORE reading file
                                                (saves disk I/O on cache hits)
10   Middleware_GzipSidecar  Response sidecar   Serve .gz BEFORE full file read
                                                (pre-compressed is cheaper)
11   Middleware_GzipCompress Post-processing    Compress resp\Body after downstream
                                                fills it (skips if already encoded)
12   Middleware_EmbedAssets  Terminal handler   Try in-memory pack BEFORE disk
13   Middleware_FileServer   Terminal handler   Read file from disk — primary
                                                content source
14   Middleware_DirListing   Terminal handler   Directory listing — last resort
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

## ResponseWriter Abstraction (v2.3.0+)

The `ResponseWriter` is a vtable-based writer interface for body output. It
decouples *what produces the bytes* from *where the bytes go*.

```purebasic
Structure ResponseWriter
  Write.ProtoWrite          ; function pointer: write bytes
  Flush.ProtoFlush          ; function pointer: flush/finalize
  *inner.ResponseWriter     ; wrapped writer (0 for terminal)
  *ctx                      ; opaque state pointer
  connection.i              ; TCP connection ID (PlainWriter)
EndStructure
```

**PlainWriter** — sends bytes directly to the TCP socket via `SendNetworkData`.
The chain runner (`RunRequest`) uses PlainWriter for all body output.

Future writers (brotli, chunked transfer encoding) wrap an inner writer — the
handler writes to the wrapper, which transforms and forwards to the real writer.

## Dynamic Gzip Compression (v2.3.0+)

`Middleware_GzipCompress` is a **post-processing** middleware:

1. Calls `CallNext()` to let downstream fill `resp\Body`
2. If all conditions met: compresses the body in-place
3. Returns the downstream result

**Conditions for compression:**
- `--no-gzip` is NOT set
- Client sends `Accept-Encoding: gzip`
- Response has a body larger than 256 bytes
- Content-Type is compressible (text/\*, JSON, JS, XML, SVG)
- No `Content-Encoding` header already set (avoids double-compression)

**How it works internally:**

`GzipCompressBuffer()` converts PureBasic's `CompressMemory()` output
(zlib format) to valid gzip by:

1. Stripping the 2-byte zlib header and 4-byte Adler-32 trailer
2. Wrapping with a 10-byte gzip header + 8-byte CRC32/size trailer
3. CRC32 computed via `Fingerprint(*buf, size, #PB_Cipher_CRC32)`

Pre-compressed `.gz` sidecars still take priority — `Middleware_GzipSidecar`
runs before `Middleware_GzipCompress` in the chain and short-circuits.

**Chain position:**

```
... → Cors → SecurityHeaders → ETag304 → GzipSidecar → GzipCompress → EmbeddedAssets → FileServer → ...
```

## Health Check, CORS, and Security Headers (v2.4.0+)

Three middleware added in v2.4.0 for production deployments:

### Middleware_HealthCheck (slot 2)

Short-circuits requests matching `--health PATH` with `200 {"status":"ok"}`.
Placed early (after Rewrite) so health probes skip all file-serving logic.
Infrastructure probes from Caddy, nginx, AWS ALB, and Kubernetes hit this endpoint.

### Middleware_Cors (slot 7)

Hybrid middleware handling CORS:
- **OPTIONS preflight** → short-circuit with 204 and CORS headers
- **Normal requests** → post-process: call `CallNext()`, then append CORS headers

Enabled via `--cors` (permissive, `Origin: *`) or `--cors-origin ORIGIN` (restricted).
`RunRequest()` was updated to allow the `OPTIONS` method through the method guard.

### Middleware_SecurityHeaders (slot 8)

Post-processing middleware that appends security headers to handled responses:
- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: DENY`
- `X-XSS-Protection: 1; mode=block`
- `Referrer-Policy: strict-origin-when-cross-origin`
- `Cross-Origin-Opener-Policy: same-origin`

Enabled via `--security-headers`. Default is off — users behind a reverse proxy
may already have these headers from Caddy/nginx.

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

---

## HTTPS Support

### Manual Certificates (v2.1.0+)

Provide PEM certificate and key files via CLI flags:

```bash
# Generate self-signed cert for development
openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem \
  -days 365 -nodes -subj "/CN=localhost"

# Run with TLS
./PureSimpleHTTPServer --port 8443 --root ./wwwroot \
  --tls-cert cert.pem --tls-key key.pem

# Test
curl -k https://localhost:8443/
```

Both `--tls-cert` and `--tls-key` must be specified together. When omitted,
the server runs plain HTTP as before.

**Implementation details:**

- `ReadPEMFile()` in Config.pbi reads PEM content into a string
- `UseNetworkTLS(key$, cert$)` is called before `CreateNetworkServer()`
- `#PB_Network_TLSv1` flag enables TLS 1.2/1.3 on the listener
- `RestartServer()` signals the event loop to close and reopen the listener
  (used by auto-TLS for certificate reload)

### Automatic HTTPS with acme.sh (v2.2.0+)

Zero-config HTTPS via Let's Encrypt:

```bash
# Prerequisites: acme.sh installed, port 80 open, DNS configured
./PureSimpleHTTPServer --auto-tls example.com --root /var/www
```

The server automatically:

1. Starts an HTTP listener on port 80 (ACME challenges + HTTPS redirect)
2. Issues a certificate via `acme.sh --issue` (HTTP-01 webroot challenge)
3. Loads the certificate and starts HTTPS on port 443
4. Runs a background renewal thread (checks every 12 hours)
5. Reloads certificates via `RestartServer()` on successful renewal

**Architecture:**

```
Port 80  → HttpRedirectLoop (background thread)
             → ACME challenge? → serve token file
             → Everything else → 301 redirect to https://

Port 443 → StartServer (main thread, full middleware chain)
             → Normal HTTPS request processing

Background → CertRenewalLoop (checks every 12h)
               → acme.sh --renew → reload cert → RestartServer()
```

**Key files:**

| File | Purpose |
|------|---------|
| `AutoTLS.pbi` | Certificate management, renewal thread, HTTP redirect server |
| `Config.pbi` | `ReadPEMFile()`, `--auto-tls` flag |
| `TcpServer.pbi` | `CreateServerWithTLS()`, `RestartServer()` |

**TLS modes (mutually exclusive, highest priority first):**

1. `--auto-tls DOMAIN` — automatic certificate via acme.sh
2. `--tls-cert FILE --tls-key FILE` — manual certificate files
3. Neither — plain HTTP (default)
