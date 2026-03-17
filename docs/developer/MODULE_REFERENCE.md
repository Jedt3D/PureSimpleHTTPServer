# PureSimpleHTTPServer v2.4.0 — Module Reference

This document describes every `.pbi` module in `src/` and the entry-point `main.pb`. For each module the public API (procedures and exported globals), the compile-time dependencies, and notable implementation details are listed.

Inclusion order follows `main.pb` and `tests/TestCommon.pbi`. The `XIncludeFile`
directive is idempotent — each file is compiled at most once per compilation unit.

> **Tutorial:** For a step-by-step walkthrough of how all modules fit together, see
> [`BUILD_OUR_HTTP_SERVER.md`](BUILD_OUR_HTTP_SERVER.md).

---

## Global.pbi

**Purpose:** Application-wide constants, HTTP status codes, and buffer size
definitions. No procedures. No globals.

### Constants

| Constant | Value | Meaning |
|---|---|---|
| `#APP_NAME` | `"PureSimpleHTTPServer"` | Used in `Server:` response header |
| `#APP_VERSION` | `"2.4.0"` | Used in startup banner |
| `#HTTP_200` ... `#HTTP_500` | 200-500 | HTTP status code shorthand. `#HTTP_204` (204 No Content) added in v2.4.0 |
| `#RECV_BUFFER_SIZE` | 65536 | Per-connection TCP receive buffer (64 KB) |
| `#SEND_CHUNK_SIZE` | 65536 | File send chunk size (64 KB) |
| `#MAX_HEADER_SIZE` | 8192 | Maximum accepted request header block (8 KB) |
| `#DEFAULT_PORT` | 8080 | Listening port when none is specified |
| `#DEFAULT_INDEX` | `"index.html"` | Default index file name |

### Dependencies

None. Must be the first `XIncludeFile` in any compilation unit.

---

## Types.pbi

**Purpose:** Shared structure definitions used across multiple modules.

### Structures

#### `HttpRequest`

Filled by `ParseHttpRequest` in `HttpParser.pbi`.

| Field | Type | Description |
|---|---|---|
| `Method` | `.s` | HTTP method |
| `Path` | `.s` | Decoded, normalized URL path |
| `QueryString` | `.s` | Raw query string or `""` |
| `Version` | `.s` | `"HTTP/1.1"` or `"HTTP/1.0"` |
| `RawHeaders` | `.s` | Raw header lines |
| `ContentLength` | `.i` | Value of `Content-Length`, or 0 |
| `Body` | `.s` | Request body, if any |
| `IsValid` | `.i` | `#True` when parsing succeeded |
| `ErrorCode` | `.i` | HTTP status code on parse failure |

#### `ResponseBuffer` (v2.0.0+)

Used by middleware to build responses. The chain runner (`RunRequest`) owns the
final `*Body` and frees it.

| Field | Type | Description |
|---|---|---|
| `StatusCode` | `.i` | HTTP status code |
| `Headers` | `.s` | Response headers (each line ends with `#CRLF$`) |
| `*Body` | `.i` | Pointer to allocated body buffer |
| `BodySize` | `.i` | Body size in bytes |
| `Handled` | `.i` | `#True` if a middleware produced a response |

#### `MiddlewareContext` (v2.0.0+)

Passed through the middleware chain.

| Field | Type | Description |
|---|---|---|
| `ChainIndex` | `.i` | Current position in the chain (-1 initially) |
| `Connection` | `.i` | TCP connection ID |
| `*Config` | `.i` | Pointer to `ServerConfig` |
| `BytesSent` | `.i` | Set by `RunRequest` after sending |

#### `ResponseWriter` (v2.3.0+)

Vtable-based writer abstraction for body output.

| Field | Type | Description |
|---|---|---|
| `Write` | `ProtoWrite` | Function pointer: write bytes |
| `Flush` | `ProtoFlush` | Function pointer: flush/finalize |
| `*inner` | `*ResponseWriter` | Wrapped writer (0 for terminal) |
| `*ctx` | `.i` | Opaque state pointer |
| `connection` | `.i` | TCP connection ID (PlainWriter) |

#### `RangeSpec`

| Field | Type | Description |
|---|---|---|
| `Start` | `.i` | First byte (inclusive) |
| `End` | `.i` | Last byte (inclusive) |
| `IsValid` | `.i` | `#True` if satisfiable |

#### `ServerConfig`

| Field | Type | Description |
|---|---|---|
| `Port` | `.i` | Listening port |
| `RootDirectory` | `.s` | Document root |
| `IndexFiles` | `.s` | Comma-separated index file names |
| `BrowseEnabled` | `.i` | Directory listing flag |
| `SpaFallback` | `.i` | SPA mode flag |
| `HiddenPatterns` | `.s` | Comma-separated blocked segments |
| `LogFile` | `.s` | Access log path |
| `MaxConnections` | `.i` | Max concurrent connections |
| `ErrorLogFile` | `.s` | Error log path |
| `LogLevel` | `.i` | Error log threshold |
| `LogSizeMB` | `.i` | Size-rotation threshold |
| `LogKeepCount` | `.i` | Archive keep count |
| `LogDaily` | `.i` | Daily rotation flag |
| `PidFile` | `.s` | PID file path |
| `CleanUrls` | `.i` | Clean URL flag |
| `RewriteFile` | `.s` | Rewrite conf path |
| `ServiceMode` | `.i` | Windows service flag |
| `ServiceName` | `.s` | Windows service name |
| `TlsCert` | `.s` | TLS certificate path (v2.1.0+) |
| `TlsKey` | `.s` | TLS key path (v2.1.0+) |
| `AutoTlsDomain` | `.s` | Auto-TLS domain (v2.2.0+) |
| `NoGzip` | `.i` | Disable gzip flag (v2.3.0+) |
| `HealthPath` | `.s` | Health check endpoint path (v2.4.0+) |
| `CorsEnabled` | `.i` | CORS enabled flag (v2.4.0+) |
| `CorsOrigin` | `.s` | CORS specific origin (v2.4.0+) |
| `SecurityHeaders` | `.i` | Security headers flag (v2.4.0+) |

### Dependencies

`Global.pbi`

---

## DateHelper.pbi

**Purpose:** RFC 7231 HTTP date formatting.

#### `HTTPDate(ts.q) -> .s`

Returns a string like `"Sat, 14 Mar 2026 00:00:00 GMT"`.

### Dependencies: None.

---

## UrlHelper.pbi

**Purpose:** URL percent-decoding and path normalization.

#### `URLDecodePath(s.s) -> .s` — Percent-decode a URL path.
#### `NormalizePath(s.s) -> .s` — Resolve `.`/`..`, enforce leading `/`.

### Dependencies: None.

---

## HttpParser.pbi

**Purpose:** HTTP/1.1 request parser.

#### `ParseHttpRequest(raw.s, *req.HttpRequest) -> .i` — Parse raw → `HttpRequest`.
#### `GetHeader(rawHeaders.s, name.s) -> .s` — Extract header by name (case-insensitive).

### Dependencies: `Types.pbi`, `UrlHelper.pbi`

---

## HttpResponse.pbi

**Purpose:** HTTP/1.1 response builder.

#### `StatusText(code.i) -> .s` — HTTP reason phrase.
#### `BuildResponseHeaders(statusCode.i, extraHeaders.s, bodyLen.i) -> .s` — Assemble header block.
#### `SendTextResponse(connection.i, statusCode.i, contentType.s, body.s)` — Send complete response.
#### `FillTextResponse(*resp.ResponseBuffer, statusCode.i, contentType.s, body.s)` — Fill a `ResponseBuffer` with UTF-8 text (v2.0.0+). Allocates the body buffer.

### Dependencies: `Global.pbi`

---

## TcpServer.pbi

**Purpose:** TCP server event loop, thread-per-connection dispatch, TLS support.

### Public Globals

| Global | Type | Description |
|---|---|---|
| `g_Handler` | `ConnectionHandlerProto` | Request handler function pointer |
| `g_Running` | `.i` | Server loop active flag |
| `g_CloseMutex` | `.i` | Close queue mutex |
| `g_CloseList` | `NewList .i()` | Close queue |
| `g_TlsEnabled` | `.i` | TLS active flag (v2.1.0+) |
| `g_TlsKey` | `.s` | PEM key content (v2.1.0+) |
| `g_TlsCert` | `.s` | PEM cert content (v2.1.0+) |
| `g_ServerID` | `.i` | Network server handle |
| `g_ServerPort` | `.i` | Current listening port |
| `g_RestartFlag` | `.i` | Server restart signal (v2.2.0+) |

### Public Procedures

#### `StartServer(port.i) -> .i` — Create server, enter blocking event loop.
#### `StopServer()` — Signal event loop to exit.
#### `CreateServerWithTLS(port.i) -> .i` — Create server with optional TLS (v2.1.0+).
#### `RestartServer()` — Signal server restart for TLS cert reload (v2.2.0+).

### Dependencies: `Global.pbi`

---

## MimeTypes.pbi

**Purpose:** MIME type lookup by file extension.

#### `GetMimeType(extension.s) -> .s` — Returns MIME type; `"application/octet-stream"` for unknown.

### Dependencies: None.

---

## Logger.pbi

**Purpose:** Access log (Apache CLF), error log, rotation, SIGHUP reopen.

### Key Procedures

- `OpenLogFile(path.s) -> .i` / `CloseLogFile()`
- `OpenErrorLog(path.s) -> .i` / `CloseErrorLog()`
- `LogAccess(ip, method, path, protocol, status, bytes, referer, userAgent)`
- `LogError(level.s, message.s)`
- `StartDailyRotation()` / `StopDailyRotation()`

### Dependencies: `Global.pbi`

---

## FileServer.pbi

**Purpose:** Utility functions used by middleware for file serving.

#### `ResolveIndexFile(dirPath.s, indexList.s) -> .s` — Find first existing index file.
#### `BuildETag(filePath.s) -> .s` — Generate `"<size_hex>-<mtime_hex>"` ETag.
#### `IsHiddenPath(urlPath.s, hiddenPatterns.s) -> .i` — Check blocked segments.

### Dependencies: `Global.pbi`, `Types.pbi`, `DateHelper.pbi`, `HttpParser.pbi`, `HttpResponse.pbi`, `MimeTypes.pbi`

---

## DirectoryListing.pbi

**Purpose:** HTML directory listing generator.

#### `BuildDirectoryListing(dirPath.s, urlPath.s) -> .s` — Generate HTML page.

### Dependencies: `Global.pbi`, `DateHelper.pbi`

---

## RangeParser.pbi

**Purpose:** HTTP Range header parser.

#### `ParseRangeHeader(header.s, fileSize.i, *range.RangeSpec) -> .i`
#### `SendPartialResponse(connection.i, fsPath.s, *range.RangeSpec, mimeType.s, fileSize.i) -> .i`

### Dependencies: `Global.pbi`, `Types.pbi`, `HttpResponse.pbi`

---

## EmbeddedAssets.pbi

**Purpose:** In-memory asset serving from compiled-in ZIP archive.

#### `OpenEmbeddedPack(*packData = 0, packSize.i = 0) -> .i`
#### `ServeEmbeddedFile(connection.i, urlPath.s) -> .i`
#### `CloseEmbeddedPack()`

### Dependencies: `Global.pbi`, `MimeTypes.pbi`, `HttpResponse.pbi`

---

## Config.pbi

**Purpose:** Configuration defaults, CLI parsing, PEM file reading.

#### `LoadDefaults(*cfg.ServerConfig)` — Set all defaults.
#### `ParseCLI(*cfg.ServerConfig) -> .i` — Parse command-line flags.
#### `ParseLogLevel(s.s) -> .i` — Convert level name to integer.
#### `ReadPEMFile(path.s) -> .s` — Read PEM file content (v2.1.0+).

Recognized flags: `--port`, `--root`, `--browse`, `--spa`, `--log`, `--error-log`,
`--log-level`, `--log-size`, `--log-keep`, `--no-log-daily`, `--pid-file`,
`--clean-urls`, `--rewrite`, `--tls-cert`, `--tls-key`, `--auto-tls`, `--no-gzip`,
`--health`, `--cors`, `--cors-origin`, `--security-headers`,
`--service`, `--service-name`.

### Dependencies: `Global.pbi`, `Types.pbi`

---

## RewriteEngine.pbi

**Purpose:** URL rewrite/redirect rule evaluation. Thread-safe via `g_RewriteMutex`.

#### `InitRewriteEngine()` — Allocate memory, create mutex.
#### `CleanupRewriteEngine()` — Free all resources.
#### `LoadGlobalRules(path.s)` — Load rules from file.
#### `GlobalRuleCount() -> .i` — Count loaded global rules.
#### `ApplyRewrites(path.s, docRoot.s, *result.RewriteResult) -> .i` — Evaluate rules.

### Dependencies: `Global.pbi`, `Types.pbi`

---

## Middleware.pbi (v2.0.0+)

**Purpose:** Middleware chain infrastructure, all 14 middleware, and utility functions.

### Chain Infrastructure

#### `RegisterMiddleware(*handler)` — Add middleware to chain during startup.
#### `CallNext(*req, *resp, *mCtx) -> .i` — Advance to next middleware.
#### `RunRequest(connection.i, raw.s, *cfg.ServerConfig) -> .i` — Chain runner: parse → chain → send → free → log.
#### `BuildChain()` — Register all 14 middleware in directive order.

### Middleware (in chain order)

1. `Middleware_Rewrite` — URL rewrite/redirect rules
2. `Middleware_HealthCheck` — Short-circuit health check endpoint (200 JSON)
3. `Middleware_IndexFile` — Directory → index file resolution
4. `Middleware_CleanUrls` — Extensionless → `.html` fallback
5. `Middleware_SpaFallback` — 404 → root index for SPAs
6. `Middleware_HiddenPath` — Block `.git`/`.env` paths (403)
7. `Middleware_Cors` — CORS preflight (204) and header post-processing
8. `Middleware_SecurityHeaders` — Append security headers to responses
9. `Middleware_ETag304` — Return 304 on ETag match
10. `Middleware_GzipSidecar` — Serve pre-compressed `.gz` files
11. `Middleware_GzipCompress` — Dynamic gzip compression (post-processing)
12. `Middleware_EmbeddedAssets` — Serve from in-memory pack
13. `Middleware_FileServer` — Serve from disk (200 + 206 range)
14. `Middleware_DirectoryListing` — HTML directory listing

### Utility Functions

#### `BuildFsPath(docRoot.s, urlPath.s) -> .s` — Build filesystem path from doc root + URL.
#### `InitPlainWriter(*w.ResponseWriter, connection.i)` — Initialize PlainWriter for TCP output.
#### `GzipCompressBuffer(*input, inputSize.i, *outSize.Integer) -> .i` — Compress to gzip format. Caller must `FreeMemory()`.
#### `IsCompressibleType(headers.s) -> .i` — Check MIME type for compressibility.

### Dependencies

`Global.pbi`, `Types.pbi`, `HttpParser.pbi`, `HttpResponse.pbi`, `MimeTypes.pbi`,
`DateHelper.pbi`, `Logger.pbi`, `FileServer.pbi`, `DirectoryListing.pbi`,
`RangeParser.pbi`, `EmbeddedAssets.pbi`, `RewriteEngine.pbi`

---

## AutoTLS.pbi (v2.2.0+)

**Purpose:** Automatic TLS certificate management via acme.sh.

### Public Globals

| Global | Type | Description |
|---|---|---|
| `g_AutoTlsDomain` | `.s` | Domain for auto-TLS |
| `g_AcmeChallengeDir` | `.s` | ACME challenge directory path |

### Public Procedures

#### `GetCertPath(domain.s) -> .s` — Return acme.sh ECC certificate path.
#### `GetKeyPath(domain.s) -> .s` — Return acme.sh ECC key path.
#### `CertificateExists(domain.s) -> .i` — Check if certificate files exist.
#### `IssueCertificate(domain.s, webroot.s) -> .i` — Issue via HTTP-01 challenge.
#### `RenewCertificate(domain.s) -> .i` — Renew existing certificate.
#### `StartCertRenewal()` / `StopCertRenewal()` — Manage background renewal thread (12h interval).
#### `StartHttpRedirect(port.i)` / `StopHttpRedirect()` — Manage port 80 ACME + redirect server.

### Dependencies: `Config.pbi`

---

## WindowsService.pbi (v1.6.0+)

**Purpose:** Windows Service API wrapper. Provides no-op stubs on non-Windows platforms.

### Public Procedures (Windows only)

#### `InstallService(name.s, displayName.s, binaryPath.s, description.s) -> .i`
#### `UninstallService(name.s) -> .i`
#### `RunAsService()` — Connect to Service Control Manager, never returns until service stops.

### Dependencies: `Global.pbi`

---

## SignalHandler.pbi

**Purpose:** POSIX SIGHUP handler for logrotate integration. No-op on Windows.

#### `InstallSignalHandlers()` — Install SIGHUP handler (sets `g_ReopenLogs = 1`).
#### `RemoveSignalHandlers()` — Restore default SIGHUP disposition.

### Dependencies: `Logger.pbi`

---

## main.pb

**Purpose:** Application entry point. Includes all modules, defines
`RunRequestWrapper`, and runs the startup/shutdown sequence.

### Public Globals

| Global | Type | Description |
|--------|------|-------------|
| `g_Config` | `ServerConfig` | Runtime configuration |

### Key Procedures

#### `RunRequestWrapper(connection.i, raw.s) -> .i` — Bridges `g_Handler` to `RunRequest` with `g_Config`.
#### `ArgContains(arg.s) -> .i` — Check if CLI argument exists.
#### `Main()` — Entry point: ParseCLI → TLS setup → BuildChain → StartServer → shutdown.

### Startup Sequence

```
LoadDefaults → ParseCLI → Windows service handling
→ InitRewriteEngine → LoadGlobalRules
→ configure Logger globals → getpid
→ OpenLogFile → OpenErrorLog → write PID file
→ StartDailyRotation → InstallSignalHandlers
→ TLS setup (auto-tls or manual)
→ startup banner → BuildChain → g_Handler = @RunRequestWrapper()
→ StartServer (blocks)
```

### Shutdown Sequence

```
StopCertRenewal → StopHttpRedirect (if auto-tls)
→ RemoveSignalHandlers → StopDailyRotation
→ CloseLogFile → CloseErrorLog → DeleteFile(PidFile)
→ CleanupRewriteEngine → CloseEmbeddedPack
```
