# PureSimpleHTTPServer v2.3.1 — Architecture Reference

> **New to the codebase?** Start with [`BUILD_OUR_HTTP_SERVER.md`](BUILD_OUR_HTTP_SERVER.md) —
> a step-by-step tutorial that builds a server from scratch using the same libraries.

## 1. Overview

PureSimpleHTTPServer is a single-binary HTTP/1.1 static file server written entirely in PureBasic 6.x, compiled with the C backend (`pbcompiler -cl -t`). The `-t` flag enables thread-safe mode, which is required by the thread-per-connection dispatch model.

Key design properties:

- **Single binary.** No external runtime, no configuration file required.
- **Middleware chain.** Every request flows through an ordered chain of 11 middleware. Each middleware can pre-process, short-circuit, or post-process the request/response.
- **Thread-per-connection.** Each complete HTTP request is handed off to a dedicated OS thread.
- **C backend.** PureBasic's C backend produces portable C code. This matters for `ImportC ""` blocks used for `getpid()` and `signal()`.
- **TLS support.** Manual certificates or automatic HTTPS via acme.sh integration.

---

## 2. Module Map

The inclusion order in `main.pb` determines the compile order. Each `XIncludeFile` is guarded by PureBasic's idempotent semantics.

```
main.pb
 |
 +-- Global.pbi          (constants, HTTP status codes, buffer sizes)
 +-- Types.pbi           (HttpRequest, ResponseBuffer, MiddlewareContext,
 |                         ResponseWriter, RangeSpec, ServerConfig, RewriteResult)
 +-- DateHelper.pbi      (HTTPDate — RFC 7231 date formatting)
 +-- UrlHelper.pbi       (URLDecodePath, NormalizePath)
 +-- HttpParser.pbi      (ParseHttpRequest, GetHeader)
 |     depends on: Types.pbi, UrlHelper.pbi
 +-- HttpResponse.pbi    (StatusText, BuildResponseHeaders, SendTextResponse,
 |                         FillTextResponse)
 |     depends on: Global.pbi
 +-- TcpServer.pbi       (StartServer, StopServer, CreateServerWithTLS,
 |                         RestartServer, ConnectionThread, close-queue)
 |     depends on: Global.pbi
 +-- MimeTypes.pbi       (GetMimeType)
 +-- Logger.pbi          (OpenLogFile, LogAccess, LogError, rotation, daily thread)
 |     depends on: Global.pbi
 +-- FileServer.pbi      (ResolveIndexFile, BuildETag, IsHiddenPath)
 |     depends on: Global.pbi, Types.pbi, DateHelper.pbi, HttpParser.pbi,
 |                 HttpResponse.pbi, MimeTypes.pbi
 |     forward-declares: BuildDirectoryListing, ParseRangeHeader, SendPartialResponse
 +-- DirectoryListing.pbi (BuildDirectoryListing)
 |     depends on: Global.pbi, DateHelper.pbi
 +-- RangeParser.pbi     (ParseRangeHeader, SendPartialResponse)
 |     depends on: Global.pbi, Types.pbi, HttpResponse.pbi
 +-- EmbeddedAssets.pbi  (OpenEmbeddedPack, ServeEmbeddedFile, CloseEmbeddedPack)
 |     depends on: Global.pbi, MimeTypes.pbi, HttpResponse.pbi
 +-- Config.pbi          (LoadDefaults, ParseCLI, ReadPEMFile)
 |     depends on: Global.pbi, Types.pbi
 +-- RewriteEngine.pbi   (InitRewriteEngine, LoadGlobalRules, ApplyRewrites,
 |                         CleanupRewriteEngine, GlobalRuleCount)
 |     depends on: Global.pbi, Types.pbi
 +-- Middleware.pbi       (RegisterMiddleware, CallNext, RunRequest, BuildChain,
 |                         all 11 middleware, PlainWriter, GzipCompressBuffer)
 |     depends on: Global.pbi, Types.pbi, HttpParser.pbi, HttpResponse.pbi,
 |                 MimeTypes.pbi, DateHelper.pbi, Logger.pbi, FileServer.pbi,
 |                 DirectoryListing.pbi, RangeParser.pbi, EmbeddedAssets.pbi,
 |                 RewriteEngine.pbi
 +-- AutoTLS.pbi          (IssueCertificate, RenewCertificate, CertRenewalLoop,
 |                         HttpRedirectLoop, StartHttpRedirect, StopHttpRedirect,
 |                         StartCertRenewal, StopCertRenewal)
 |     depends on: Config.pbi
 +-- SignalHandler.pbi   (InstallSignalHandlers, RemoveSignalHandlers)
 |     depends on: Logger.pbi (g_ReopenLogs)
 +-- WindowsService.pbi  (InstallService, UninstallService, RunAsService)
       depends on: Global.pbi (Windows-only, stubs on other platforms)
```

---

## 3. Middleware Chain

The middleware chain is the central architectural pattern (v2.0.0+). It replaces the monolithic `HandleRequest`/`ServeFile` dispatch path from v1.x.

### Chain Diagram

```
Client → TCP → RunRequest() → [chain] → send → free → log

Chain:
 Pos  Middleware              Type               Why this position
 ───  ──────────────────────  ─────────────────  ─────────────────────────────
  1   Middleware_Rewrite      Request modifier   Rewrite path BEFORE anything
                                                 checks the filesystem
  2   Middleware_IndexFile    Request modifier   Resolve /dir/ → /dir/index.html
  3   Middleware_CleanUrls    Request modifier   Try /about → /about.html
  4   Middleware_SpaFallback  Request modifier   Last-resort path rewrite
  5   Middleware_HiddenPath   Access control     Block .git/.env AFTER path finalized
  6   Middleware_ETag304      Conditional resp   Return 304 BEFORE reading file
  7   Middleware_GzipSidecar  Response sidecar   Serve .gz BEFORE full file read
  8   Middleware_GzipCompress Post-processing    Compress resp\Body after downstream
  9   Middleware_EmbedAssets  Terminal handler   Try in-memory pack BEFORE disk
 10   Middleware_FileServer   Terminal handler   Read file from disk
 11   Middleware_DirListing   Terminal handler   Directory listing — last resort
```

### How middleware work

Each middleware receives `(*req.HttpRequest, *resp.ResponseBuffer, *mCtx.MiddlewareContext)` and can:

- **Pre-process:** Modify `*req\Path`, then call `CallNext()`.
- **Short-circuit:** Fill `*resp` and return `#True` without calling `CallNext()`.
- **Post-process:** Call `CallNext()` first, then modify `*resp` (e.g., GzipCompress).
- **Pass through:** Just call `CallNext()` and return its result.

The chain runner (`RunRequest`) is the **single point** of network I/O and memory cleanup. Middleware never call `SendNetwork*` directly.

---

## 4. Request Lifecycle

### 4.1 Connection accept (main thread)

`StartServer(port)` calls `CreateServerWithTLS(port)` (which uses `CreateNetworkServer` with optional `#PB_Network_TLSv1`) and enters a blocking event loop.

### 4.2 Data accumulation (main thread)

On `#PB_NetworkEvent_Data`, received bytes are appended to the per-client accumulation string. Dispatch occurs when `\r\n\r\n` is found.

### 4.3 Thread dispatch

A `ThreadData` structure is passed to `CreateThread(@ConnectionThread(), *td)`. The main thread returns to the event loop.

### 4.4 ConnectionThread (worker thread)

Calls `g_Handler(client, raw)`, which invokes `RunRequestWrapper` → `RunRequest`.

### 4.5 RunRequest (worker thread)

1. Parse request via `ParseHttpRequest`
2. Reject non-GET with 400
3. Initialize empty `ResponseBuffer` and `MiddlewareContext`
4. Run middleware chain via `CallNext`
5. Send response via `PlainWriter` (headers + body)
6. Free `resp\Body`
7. Log access via `LogAccess`

### 4.6 Close-queue drain (main thread)

Worker threads push finished connection IDs into `g_CloseList`. The main thread drains the queue and calls `CloseNetworkConnection` exclusively from the main thread.

---

## 5. Threading Model

### Main thread responsibilities

- `NetworkServerEvent` loop
- `CloseNetworkConnection` calls (via close-queue drain)
- Signal handler installation/removal
- Certificate renewal restart (`RestartServer`)

### Worker threads

One thread per dispatched request via `CreateThread`. Threads push the connection ID onto `g_CloseList` and never call `CloseNetworkConnection` directly.

### Why CloseNetworkConnection must run on the main thread

PureBasic's `CloseNetworkConnection` modifies the library's internal connection table, which `NetworkServerEvent` also accesses on the main thread. The close-queue pattern serialises all close calls.

### Mutex inventory

| Mutex | Global | Protects |
|-------|--------|----------|
| `g_CloseMutex` | `TcpServer.pbi` | `g_CloseList` — worker threads push, main thread pops |
| `g_LogMutex` | `Logger.pbi` | Both log file handles, `g_ReopenLogs` flag, all rotation state |
| `g_RewriteMutex` | `RewriteEngine.pbi` | All rewrite rule arrays and per-directory cache |

---

## 6. TLS Lifecycle

### TLS modes (mutually exclusive, highest priority first)

1. `--auto-tls DOMAIN` — automatic certificate via acme.sh
2. `--tls-cert FILE --tls-key FILE` — manual certificate files
3. Neither — plain HTTP (default)

### Auto-TLS architecture

```
Port 80  → HttpRedirectLoop (background thread)
             → ACME challenge? → serve token file
             → Everything else → 301 redirect to https://

Port 443 → StartServer (main thread, full middleware chain)
             → Normal HTTPS request processing

Background → CertRenewalLoop (checks every 12h)
               → acme.sh --renew → reload cert → RestartServer()
```

### Certificate reload

`RestartServer()` sets `g_RestartFlag`, which causes the main event loop to close the listener and recreate it with updated TLS globals. In-flight requests complete before the restart.

---

## 7. Global State

| Global | Type | Defined in | Purpose |
|--------|------|-----------|---------|
| `g_Handler` | `ConnectionHandlerProto` | `TcpServer.pbi` | Function pointer set to `@RunRequestWrapper()` |
| `g_Running` | `.i` | `TcpServer.pbi` | `#True` while event loop is active |
| `g_CloseMutex` | `.i` | `TcpServer.pbi` | Mutex for close queue |
| `g_CloseList` | `NewList .i()` | `TcpServer.pbi` | Connection IDs awaiting close |
| `g_TlsEnabled` | `.i` | `TcpServer.pbi` | TLS active flag |
| `g_TlsKey` / `g_TlsCert` | `.s` | `TcpServer.pbi` | PEM content for TLS |
| `g_RestartFlag` | `.i` | `TcpServer.pbi` | Signal server restart for cert reload |
| `g_EmbeddedPack` | `.i` | `EmbeddedAssets.pbi` | CatchPack handle; 0 = no pack |
| `g_ServerPID` | `.i` | `Logger.pbi` | Process ID for logs and PID file |
| `g_LogLevel` | `.i` | `Logger.pbi` | Error log threshold |
| `g_LogMaxBytes` | `.i` | `Logger.pbi` | Size-rotation threshold |
| `g_ReopenLogs` | `.i` | `Logger.pbi` | Set by SIGHUP handler |
| `g_Chain` / `g_ChainCount` | `Dim`/`.i` | `Middleware.pbi` | Middleware chain array |
| `g_Config` | `ServerConfig` | `main.pb` | Parsed runtime configuration |

---

## 8. Memory Management

### ResponseBuffer ownership

Three rules prevent leaks (see [developer-guide.md](../developer-guide.md)):

1. The chain runner (`RunRequest`) always frees `resp\Body`.
2. A middleware replacing `resp\Body` must free the old one first.
3. Short-circuit middleware set `resp\Body` or leave it at 0.

### RewriteEngine flat arrays

`RewriteEngine.pbi` uses `AllocateMemory` blocks instead of `Global Dim` arrays to work around PureUnit/ARM64 initialization bugs.

---

## 9. Extension Points

### Adding a new middleware

Write a procedure matching the `MiddlewareHandler` prototype, register it in `BuildChain()` at the correct position. See [EXTENDING.md](EXTENDING.md) and [developer-guide.md](../developer-guide.md).

### Replacing the request handler

Assign any `ConnectionHandlerProto` to `g_Handler` before calling `StartServer`.

### Embedding a web application

Use `DataSection` + `IncludeBinary` + `OpenEmbeddedPack`. See [BUILDING.md](BUILDING.md).
