# Building Your Own HTTP Server with PureSimpleHTTPServer Libraries

This document walks through `main.pb` — the server's entry point — as a complete, annotated tutorial. By the end you will understand exactly how every library in `src/` fits together and how to assemble your own server using the same building blocks.

---

## 1. The Big Picture

PureSimpleHTTPServer is a set of independent library modules (`*.pbi`) that each solve one well-defined problem:

```
TCP sockets        →  TcpServer.pbi
HTTP parsing       →  HttpParser.pbi
HTTP responses     →  HttpResponse.pbi
Middleware chain   →  Middleware.pbi      ← central architecture (v2.0.0+)
File serving       →  FileServer.pbi     (utility functions for middleware)
Directory listing  →  DirectoryListing.pbi
Range requests     →  RangeParser.pbi
MIME types         →  MimeTypes.pbi
URL rewriting      →  RewriteEngine.pbi
Logging            →  Logger.pbi
Embedded assets    →  EmbeddedAssets.pbi
Configuration      →  Config.pbi
Auto-TLS           →  AutoTLS.pbi         (v2.2.0+)
Signal handling    →  SignalHandler.pbi
Windows Service    →  WindowsService.pbi  (v1.6.0+)
Date formatting    →  DateHelper.pbi
URL decoding       →  UrlHelper.pbi
Shared constants   →  Global.pbi
Shared types       →  Types.pbi
```

`main.pb` is the glue. It includes all modules, sets up the middleware chain, configures TLS, and starts the server.

---

## 2. The Middleware Chain (v2.0.0+)

In v2.x, all request handling flows through a middleware chain. There is no single `HandleRequest` procedure; instead, `RunRequest()` in `Middleware.pbi` orchestrates 11 middleware in a fixed order:

```
Client → TCP → RunRequest() → [chain] → send → free → log

Chain:  Rewrite → IndexFile → CleanUrls → SpaFallback → HiddenPath
        → ETag304 → GzipSidecar → GzipCompress → EmbeddedAssets
        → FileServer → DirectoryListing
```

Each middleware can:
- **Pre-process:** modify `req\Path` and call `CallNext()`
- **Short-circuit:** fill `resp` and return `#True`
- **Post-process:** call `CallNext()` first, then modify the response (e.g., GzipCompress)

`RunRequest` is the single point of network I/O and memory cleanup. Middleware never call `SendNetwork*` directly.

---

## 3. The Current main.pb Flow

### Step 1 — Parse CLI and handle Windows service commands

```purebasic
LoadDefaults(@g_Config)
ParseCLI(@g_Config)

; Windows: handle --install, --uninstall, --start, --stop, --service
```

### Step 2 — Initialize subsystems

```purebasic
InitRewriteEngine()
LoadGlobalRules(g_Config\RewriteFile)
; Configure logger globals, open log files, write PID file
; Start daily rotation thread, install SIGHUP handler
```

### Step 3 — TLS setup

```purebasic
If g_Config\AutoTlsDomain <> ""
  ; Start HTTP redirect on port 80, issue certificate, start renewal thread
  ; Load cert into g_TlsKey/g_TlsCert, set g_TlsEnabled = #True
ElseIf g_Config\TlsCert <> "" And g_Config\TlsKey <> ""
  ; Read PEM files into g_TlsKey/g_TlsCert, set g_TlsEnabled = #True
EndIf
```

### Step 4 — Build chain and start server

```purebasic
BuildChain()                              ; register 11 middleware in order
g_Handler = @RunRequestWrapper()          ; bridge to RunRequest with g_Config
StartServer(g_Config\Port)                ; blocks until StopServer()
```

### Step 5 — Clean shutdown (reverse order)

```purebasic
StopCertRenewal() / StopHttpRedirect()    ; if auto-tls
RemoveSignalHandlers()
StopDailyRotation()
CloseLogFile() / CloseErrorLog()
DeleteFile(PidFile)
CleanupRewriteEngine()
CloseEmbeddedPack()
```

---

## 4. RunRequest — The Chain Runner

`RunRequest(connection, raw, *cfg)` is the core of the v2.x architecture:

1. **Parse** — `ParseHttpRequest(raw, req)`. Bad request → 400.
2. **Method check** — Only GET proceeds. Others → 400.
3. **Init** — Empty `ResponseBuffer` and `MiddlewareContext`.
4. **Run chain** — `CallNext(@req, @resp, @mCtx)` starts the middleware chain.
5. **Send** — If `resp\Handled`, send headers via `BuildResponseHeaders` and body via `PlainWriter`.
6. **Fallback** — If no middleware handled, send 404.
7. **Free** — `FreeMemory(resp\Body)` if allocated.
8. **Log** — `LogAccess(...)` unconditionally.

---

## 5. How TcpServer Dispatches Requests

```
Main thread                        Worker threads (one per request)
─────────────────────────────────  ──────────────────────────────────
CreateServerWithTLS()  (optional TLS)

Repeat
  drain g_CloseList               ← CloseNetworkConnection here only
  event = NetworkServerEvent()

  Case Data:
    accum(key) += received bytes
    if \r\n\r\n found:
      *td = AllocateStructure(ThreadData)
      CreateThread(@ConnectionThread(), *td)
                                   ConnectionThread:
                                     g_Handler(client, raw)
                                     → RunRequestWrapper → RunRequest
                                     → middleware chain
                                     push client to g_CloseList

Until g_Running = #False
```

**Key constraint:** `CloseNetworkConnection()` must only be called from the main thread.

---

## 6. Building a Minimal Server

The simplest server using the middleware chain:

```purebasic
; minimal_middleware_server.pb
EnableExplicit

XIncludeFile "src/Global.pbi"
XIncludeFile "src/Types.pbi"
XIncludeFile "src/DateHelper.pbi"
XIncludeFile "src/UrlHelper.pbi"
XIncludeFile "src/HttpParser.pbi"
XIncludeFile "src/HttpResponse.pbi"
XIncludeFile "src/TcpServer.pbi"
XIncludeFile "src/MimeTypes.pbi"
XIncludeFile "src/Logger.pbi"
XIncludeFile "src/FileServer.pbi"
XIncludeFile "src/DirectoryListing.pbi"
XIncludeFile "src/RangeParser.pbi"
XIncludeFile "src/EmbeddedAssets.pbi"
XIncludeFile "src/Config.pbi"
XIncludeFile "src/RewriteEngine.pbi"
XIncludeFile "src/Middleware.pbi"

Global g_Config.ServerConfig

Procedure.i RunRequestWrapper(connection.i, raw.s)
  ProcedureReturn RunRequest(connection, raw, @g_Config)
EndProcedure

LoadDefaults(@g_Config)
g_Config\Port = 8080
g_Config\RootDirectory = "/srv/www"

InitRewriteEngine()
OpenEmbeddedPack()
BuildChain()
g_Handler = @RunRequestWrapper()

PrintN("Listening on http://localhost:8080")
StartServer(8080)

CleanupRewriteEngine()
CloseEmbeddedPack()
```

This gives you the full 11-middleware chain with file serving, ETag, directory listing, gzip, etc.

---

## 7. Module Responsibilities at a Glance

| Module | What it owns |
|--------|-------------|
| `Global.pbi` | HTTP status constants, buffer sizes |
| `Types.pbi` | `HttpRequest`, `ResponseBuffer`, `MiddlewareContext`, `ResponseWriter`, `ServerConfig` |
| `TcpServer.pbi` | TCP socket, event loop, thread dispatch, TLS |
| `HttpParser.pbi` | Raw string → `HttpRequest` |
| `HttpResponse.pbi` | Header assembly, `SendTextResponse`, `FillTextResponse` |
| `Middleware.pbi` | Chain infra, all 11 middleware, `RunRequest`, gzip, PlainWriter |
| `FileServer.pbi` | `ResolveIndexFile`, `BuildETag`, `IsHiddenPath` |
| `DirectoryListing.pbi` | HTML directory listing |
| `RangeParser.pbi` | Range header parsing, 206 sending |
| `MimeTypes.pbi` | Extension → Content-Type |
| `Logger.pbi` | Access + error log, rotation, SIGHUP reopen |
| `EmbeddedAssets.pbi` | In-memory ZIP serving |
| `Config.pbi` | Defaults + CLI parsing + `ReadPEMFile` |
| `RewriteEngine.pbi` | Rule loading, matching, `ApplyRewrites` |
| `AutoTLS.pbi` | acme.sh integration, cert renewal, port 80 redirect |
| `SignalHandler.pbi` | SIGHUP registration |
| `WindowsService.pbi` | Windows Service API wrapper |
| `DateHelper.pbi` | RFC 7231 date formatting |
| `UrlHelper.pbi` | URL decoding, path normalization |

Each module is independently testable. The 124 unit tests in `tests/` verify them without running a real TCP server.
