# Building Your Own HTTP Server with PureSimpleHTTPServer Libraries

This document walks through `main.pb` — the server's entry point — as a complete, annotated tutorial. By the end you will understand exactly how every library in `src/` fits together and how to assemble your own server using the same building blocks.

---

## 1. The Big Picture

PureSimpleHTTPServer is not a monolithic program. It is a set of independent library modules (`*.pbi`) that each solve one well-defined problem:

```
TCP sockets        →  TcpServer.pbi
HTTP parsing       →  HttpParser.pbi
HTTP responses     →  HttpResponse.pbi
File serving       →  FileServer.pbi
Directory listing  →  DirectoryListing.pbi
Range requests     →  RangeParser.pbi
MIME types         →  MimeTypes.pbi
URL rewriting      →  RewriteEngine.pbi
Logging            →  Logger.pbi
Embedded assets    →  EmbeddedAssets.pbi
Configuration      →  Config.pbi
Signal handling    →  SignalHandler.pbi
Date formatting    →  DateHelper.pbi
URL decoding       →  UrlHelper.pbi
Shared constants   →  Global.pbi
Shared types       →  Types.pbi
```

`main.pb` is the glue. It includes all these modules, defines `HandleRequest` (the callback that processes every HTTP request), and calls them in the correct startup sequence.

You can use any subset of these modules in your own programs. Want a minimal echo server? Use only `TcpServer.pbi` and `HttpResponse.pbi`. Want to add HTTP serving to an existing PureBasic application? Embed the same modules and call `StartServer()` on a background thread.

---

## 2. How HTTP/1.1 Works (What the Libraries Implement)

An HTTP/1.1 exchange has three steps:

```
Client                          Server
  |                               |
  |── TCP connect ───────────────>|
  |                               |
  |── GET /index.html HTTP/1.1 ──>|  ← raw bytes, accumulated until \r\n\r\n
  |   Host: localhost             |
  |   Connection: close           |
  |   \r\n\r\n                    |
  |                               |
  |<── HTTP/1.1 200 OK ──────────|  ← status line + headers + blank line + body
  |    Content-Type: text/html    |
  |    Content-Length: 42         |
  |    \r\n\r\n                   |
  |    <html>...</html>           |
  |                               |
  |── TCP disconnect ────────────>|
```

`TcpServer.pbi` handles the TCP layer. `HttpParser.pbi` parses the raw request string. `HttpResponse.pbi` builds and sends the response. `FileServer.pbi` decides what file to serve.

---

## 3. Include Order Matters

PureBasic resolves identifiers at compile time in the order they appear. The `XIncludeFile` order in `main.pb` is not arbitrary:

```purebasic
XIncludeFile "Global.pbi"         ; constants: #HTTP_200, #RECV_BUFFER_SIZE, etc.
XIncludeFile "Types.pbi"          ; structures: HttpRequest, ServerConfig, RewriteResult
XIncludeFile "DateHelper.pbi"     ; HTTPDate() — used by FileServer
XIncludeFile "UrlHelper.pbi"      ; URLDecodePath() — used by HttpParser
XIncludeFile "HttpParser.pbi"     ; ParseHttpRequest(), GetHeader()
XIncludeFile "HttpResponse.pbi"   ; BuildResponseHeaders(), SendTextResponse()
XIncludeFile "TcpServer.pbi"      ; StartServer(), StopServer(), g_Handler
XIncludeFile "MimeTypes.pbi"      ; GetMimeType()
XIncludeFile "Logger.pbi"         ; OpenLogFile(), LogAccess(), LogError()
XIncludeFile "FileServer.pbi"     ; ServeFile() — forward-declares DirectoryListing + RangeParser
XIncludeFile "DirectoryListing.pbi"
XIncludeFile "RangeParser.pbi"
XIncludeFile "EmbeddedAssets.pbi" ; OpenEmbeddedPack(), ServeEmbeddedFile()
XIncludeFile "Config.pbi"         ; LoadDefaults(), ParseCLI()
XIncludeFile "RewriteEngine.pbi"  ; InitRewriteEngine(), LoadGlobalRules(), ApplyRewrites()
XIncludeFile "SignalHandler.pbi"  ; InstallSignalHandlers() — depends on Logger.pbi globals
```

**Rule:** include leaf modules before the modules that depend on them. `FileServer.pbi` uses `BuildDirectoryListing` and `ParseRangeHeader`, which are defined in modules included after it — it resolves this with `Declare` forward declarations at its top.

### Why `XIncludeFile` instead of `IncludeFile`

`XIncludeFile` includes a file at most once per compilation unit, like `#pragma once` in C. This prevents duplicate definition errors if multiple modules try to include a shared dependency (for example, both `HttpParser.pbi` and `FileServer.pbi` depend on `Types.pbi`).

Always use `XIncludeFile` in your own modules.

---

## 4. The Two Global Structures

Before any procedures run, `main.pb` declares one global:

```purebasic
Global g_Config.ServerConfig
```

`ServerConfig` (defined in `Types.pbi`) holds every runtime setting — port, root directory, log paths, feature flags. It is populated by `LoadDefaults()` and `ParseCLI()`, then passed as a pointer into `ServeFile()` on every request.

Why a single global instead of passing it everywhere? `HandleRequest` is a callback assigned to `g_Handler` — a function pointer with a fixed signature `(connection.i, raw.s)`. It cannot accept extra parameters. Making `g_Config` global lets the callback reach it without changing the signature.

The other key global — `g_Handler.ConnectionHandlerProto` — lives in `TcpServer.pbi`. It holds the address of your request handler. You assign it before calling `StartServer()`:

```purebasic
g_Handler = @HandleRequest()
StartServer(g_Config\Port)
```

---

## 5. The Startup Sequence (Main Procedure)

`Main()` performs eight steps in a fixed order. Each step uses one or more library modules.

### Step 1 — Load defaults and parse CLI

```purebasic
LoadDefaults(@g_Config)       ; Config.pbi: fills g_Config with safe defaults
ParseCLI(@g_Config)           ; Config.pbi: overrides with --port, --root, etc.
```

`LoadDefaults` sets port=8080, root="wwwroot/", log level=warn, rotation size=100 MB, and so on. `ParseCLI` walks `ProgramParameter()` calls and patches the fields the user specified. If an unknown or malformed flag is found, `ParseCLI` returns `#False` and `Main()` prints usage and exits.

**To add a flag:** add a field to `ServerConfig` in `Types.pbi`, set its default in `LoadDefaults()`, and parse it in `ParseCLI()`. See `EXTENDING.md` for the full pattern.

### Step 2 — Initialize the rewrite engine

```purebasic
InitRewriteEngine()                        ; RewriteEngine.pbi
If g_Config\RewriteFile <> ""
  LoadGlobalRules(g_Config\RewriteFile)    ; RewriteEngine.pbi
EndIf
```

`InitRewriteEngine()` allocates the flat memory blocks that hold up to 64 global rules and 8 × 16 per-directory rules. This **must** happen before any request arrives. The allocated memory is freed by `CleanupRewriteEngine()` at shutdown.

`LoadGlobalRules` reads the `.conf` file, parses each `rewrite`/`redir` line, and fills the global rule table. Per-directory rules are loaded on demand (lazily) by `ApplyRewrites()` when a request hits a directory that contains a `rewrite.conf`.

### Step 3 — Configure logging

```purebasic
g_LogLevel     = g_Config\LogLevel
g_LogMaxBytes  = g_Config\LogSizeMB * 1024 * 1024
g_LogKeepCount = g_Config\LogKeepCount
```

These three globals live in `Logger.pbi`. Setting them here, before `OpenLogFile()`, tells the logger what rotation policy to use. The logger is self-contained: once opened, it handles size-based and daily rotation internally, with no interaction required from `HandleRequest`.

```purebasic
OpenLogFile(g_Config\LogFile)       ; Logger.pbi: opens access log
OpenErrorLog(g_Config\ErrorLogFile) ; Logger.pbi: opens error log
```

Both calls are no-ops when the path is `""`.

### Step 4 — Write PID file

```purebasic
CompilerIf #PB_Compiler_OS <> #PB_OS_Windows
  g_ServerPID = getpid()   ; libc call via ImportC ""
CompilerEndIf

If g_Config\PidFile <> ""
  ; write Str(g_ServerPID) to g_Config\PidFile
EndIf
```

The PID file enables `logrotate` integration: after rotating the logs, `logrotate` sends `SIGHUP` to the process ID in the file, triggering `ReopenLogs()` inside the logger.

### Step 5 — Start daily rotation thread and install signal handler

```purebasic
StartDailyRotation()         ; Logger.pbi: background thread wakes at midnight UTC
InstallSignalHandlers()      ; SignalHandler.pbi: on SIGHUP, sets g_ReopenLogs = 1
```

`StartDailyRotation()` spawns a thread that sleeps until the next UTC midnight, then calls `RotateLog()` for both log files and goes back to sleep. It runs independently of the main event loop.

`InstallSignalHandlers()` on macOS/Linux registers a minimal `signal()` handler that sets `g_ReopenLogs = 1`. Logger checks this flag inside `g_LogMutex` on every `LogAccess()` call and reopens the files when the flag is set. On Windows, `InstallSignalHandlers()` is a no-op.

### Step 6 — Open embedded assets

```purebasic
OpenEmbeddedPack()   ; EmbeddedAssets.pbi
```

If the binary was compiled with an embedded ZIP pack (see Section 9), `OpenEmbeddedPack()` decompresses it into memory and the server can serve files from it without touching the disk. Without embedded assets this is a no-op.

### Step 7 — Assign handler and start the server (blocking)

```purebasic
g_Handler = @HandleRequest()   ; register our callback
StartServer(g_Config\Port)     ; blocks until StopServer() or SIGTERM
```

`StartServer()` creates the TCP server socket, allocates a 64 KB receive buffer, and enters a `Repeat … Until g_Running = #False` event loop. It returns only when `StopServer()` is called (or the process receives a termination signal).

### Step 8 — Clean shutdown

```purebasic
RemoveSignalHandlers()
StopDailyRotation()
CloseLogFile()
CloseErrorLog()
DeleteFile(g_Config\PidFile)
CleanupRewriteEngine()
CloseEmbeddedPack()
```

Mirror of startup — resources are released in reverse order. Every `Open*` call has a matching `Close*`. Every `Init*` has a matching `Cleanup*`. This keeps the process clean for tools like Valgrind and makes in-process embedding safe.

---

## 6. The Request Lifecycle Inside HandleRequest

`HandleRequest(connection.i, raw.s)` is called once per complete HTTP request, on a worker thread spawned by `ConnectionThread` inside `TcpServer.pbi`. Here is what it does, step by step.

### 6.1 Parse the request

```purebasic
Protected req.HttpRequest
If Not ParseHttpRequest(raw, req)
  SendTextResponse(connection, #HTTP_400, "text/plain; charset=utf-8", "400 Bad Request")
  ProcedureReturn #False
EndIf
```

`ParseHttpRequest` (in `HttpParser.pbi`) splits the raw string into `req\Method`, `req\Path`, `req\Version`, `req\RawHeaders`, and `req\Body`. It URL-decodes the path via `URLDecodePath()` and normalizes it (`/a/../b` → `/b`, double slashes collapsed). If the request is structurally invalid, it returns `#False`.

After parsing, headers are still in raw string form (`req\RawHeaders`). Use `GetHeader(req\RawHeaders, "Header-Name")` to extract individual values:

```purebasic
referer   = GetHeader(req\RawHeaders, "Referer")
userAgent = GetHeader(req\RawHeaders, "User-Agent")
```

### 6.2 Apply rewrite rules (GET only)

```purebasic
If ApplyRewrites(req\Path, g_Config\RootDirectory, @rwResult)
  If rwResult\Action = 2   ; redirect
    ; send Location header and return
  ElseIf rwResult\Action = 1   ; rewrite
    req\Path = rwResult\NewPath   ; silently change the path
  EndIf
EndIf
```

`ApplyRewrites` (in `RewriteEngine.pbi`) checks the request path against global rules first, then per-directory rules from any `rewrite.conf` files found on the filesystem. It fills a `RewriteResult` structure:

| Field | Value | Meaning |
|-------|-------|---------|
| `Action` | `0` | No rule matched — serve normally |
| `Action` | `1` | Rewrite — use `NewPath` instead |
| `Action` | `2` | Redirect — send `RedirCode` to `RedirURL` |

A redirect is sent immediately and `HandleRequest` returns. A rewrite simply updates `req\Path` — the rest of the function sees the new path as if it were the original.

### 6.3 Try embedded assets

```purebasic
If ServeEmbeddedFile(connection, req\Path)
  LogAccess(...)
  ProcedureReturn #True
EndIf
```

`ServeEmbeddedFile` (in `EmbeddedAssets.pbi`) checks whether the path exists in the in-memory ZIP pack. If it does, it serves the file from memory and returns `#True`. If there is no embedded pack, or the path is not in the pack, it returns `#False` immediately and disk serving proceeds.

### 6.4 Serve from disk

```purebasic
result = ServeFile(connection, @g_Config, @req, @bytesOut, @statusCode)
```

`ServeFile` (in `FileServer.pbi`) handles everything else:

```
request path
  │
  ├── IsHiddenPath? → 403 Forbidden
  │
  ├── directory?
  │     ├── ResolveIndexFile found → serve that file
  │     ├── BrowseEnabled → BuildDirectoryListing → 200 HTML
  │     └── else → 403 Forbidden
  │
  ├── not found?
  │     ├── CleanUrls + no extension → try path.html
  │     ├── SpaFallback → serve root index.html
  │     └── else → 404 Not Found
  │
  ├── client has matching ETag (If-None-Match) → 304 Not Modified
  │
  ├── client sent Range header → ParseRangeHeader + SendPartialResponse → 206
  │
  ├── client accepts gzip + .gz sidecar exists → 200 with Content-Encoding: gzip
  │
  └── regular file → AllocateMemory + ReadData + SendNetworkData → 200 OK
```

### 6.5 Log the access

```purebasic
LogAccess(clientIP, req\Method, req\Path, req\Version, statusCode, bytesOut, referer, userAgent)
```

`LogAccess` (in `Logger.pbi`) writes one Apache Combined Log Format line, acquires `g_LogMutex`, checks for rotation triggers (size or daily schedule), and releases the mutex. It is thread-safe.

---

## 7. How TcpServer.pbi Calls Your Handler

Understanding the thread model prevents the most common pitfall.

```
Main thread                        Worker threads (one per request)
─────────────────────────────────  ──────────────────────────────────────
CreateNetworkServer()

Repeat
  drain g_CloseList               ← CloseNetworkConnection() here, nowhere else
  event = NetworkServerEvent()

  Case Connect:
    accum(key) = ""

  Case Data:
    accum(key) += received bytes
    if \r\n\r\n found:
      *td = AllocateStructure(ThreadData)
      *td\raw = accum(key)
      DeleteMapElement(accum, key)
      CreateThread(@ConnectionThread(), *td)
                                   ConnectionThread(*td):
                                     g_Handler(*td\client, *td\raw)
                                     ; ← your HandleRequest runs here
                                     LockMutex(g_CloseMutex)
                                     AddElement(g_CloseList(), client)
                                     UnlockMutex(g_CloseMutex)

  Case Disconnect:
    DeleteMapElement(accum, key)

Until g_Running = #False
```

**Key constraint:** `CloseNetworkConnection()` must only be called from the main thread. Worker threads push finished connection IDs into `g_CloseList`; the main loop drains it on every iteration. Violating this rule causes `SIGSEGV` under load because PureBasic's internal connection table has no mutex.

Your `HandleRequest` implementation must never call `CloseNetworkConnection()`. Just send your response and return — `ConnectionThread` handles the close.

---

## 8. Building a Minimal Server

Here is the smallest possible server using just four modules:

```purebasic
; minimal_server.pb
; Compile: pbcompiler -cl -t -o minimal_server minimal_server.pb
EnableExplicit

XIncludeFile "src/Global.pbi"
XIncludeFile "src/Types.pbi"
XIncludeFile "src/HttpParser.pbi"
XIncludeFile "src/HttpResponse.pbi"
XIncludeFile "src/TcpServer.pbi"

Procedure.i MyHandler(connection.i, raw.s)
  Protected req.HttpRequest

  If Not ParseHttpRequest(raw, req)
    SendTextResponse(connection, #HTTP_400, "text/plain; charset=utf-8", "Bad request")
    ProcedureReturn #False
  EndIf

  Protected body.s = "Hello from " + req\Path + "!"
  SendTextResponse(connection, #HTTP_200, "text/plain; charset=utf-8", body)
  ProcedureReturn #True
EndProcedure

g_Handler = @MyHandler()
PrintN("Listening on http://localhost:8080")
StartServer(8080)
```

This is the exact pattern `main.pb` uses — the only difference is `main.pb` has more feature flags and delegates to `ServeFile()` instead of sending a hard-coded response.

---

## 9. Adding Logging

Replace `MyHandler` with:

```purebasic
XIncludeFile "src/Logger.pbi"

Procedure.i MyHandler(connection.i, raw.s)
  Protected req.HttpRequest
  Protected clientIP.s = IPString(GetClientIP(connection))

  If Not ParseHttpRequest(raw, req)
    SendTextResponse(connection, #HTTP_400, "text/plain; charset=utf-8", "Bad request")
    LogAccess(clientIP, "?", "/", "HTTP/1.1", #HTTP_400, 0, "", "")
    ProcedureReturn #False
  EndIf

  Protected body.s = "Hello from " + req\Path + "!"
  SendTextResponse(connection, #HTTP_200, "text/plain; charset=utf-8", body)
  LogAccess(clientIP, req\Method, req\Path, req\Version, #HTTP_200, Len(body), "", "")
  ProcedureReturn #True
EndProcedure

; Open log before starting server
g_LogLevel = 2   ; warn
OpenLogFile("access.log")
OpenErrorLog("error.log")
g_Handler = @MyHandler()
StartServer(8080)
CloseLogFile()
CloseErrorLog()
```

`Logger.pbi` handles its own mutex — you never need to lock anything yourself.

---

## 10. Adding File Serving

Swap the echo handler for the full static file stack:

```purebasic
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

Global g_Config.ServerConfig
g_Config\Port          = 8080
g_Config\RootDirectory = "/srv/www"
g_Config\IndexFiles    = "index.html,index.htm"
g_Config\HiddenPatterns = ".git,.env,.DS_Store"

Procedure.i MyHandler(connection.i, raw.s)
  Protected req.HttpRequest
  Protected bytesOut.i, statusCode.i
  Protected clientIP.s = IPString(GetClientIP(connection))

  If Not ParseHttpRequest(raw, req)
    SendTextResponse(connection, #HTTP_400, "text/plain; charset=utf-8", "400 Bad Request")
    ProcedureReturn #False
  EndIf

  If req\Method = "GET"
    ServeFile(connection, @g_Config, @req, @bytesOut, @statusCode)
    LogAccess(clientIP, req\Method, req\Path, req\Version, statusCode, bytesOut, "", "")
    ProcedureReturn #True
  EndIf

  SendTextResponse(connection, #HTTP_400, "text/plain; charset=utf-8", "400 Bad Request")
  ProcedureReturn #False
EndProcedure

g_Handler = @MyHandler()
StartServer(g_Config\Port)
```

This is structurally identical to `main.pb` minus the rewrite engine, embedded assets, signal handling, and CLI parsing — which you can add back one module at a time.

---

## 11. Embedding Assets at Compile Time

To produce a truly single-file binary that carries its own web content:

**Step 1 — Pack your wwwroot into a ZIP:**
```bash
cd wwwroot && zip -r ../webapp.zip . && cd ..
```

**Step 2 — Add a DataSection to your source:**
```purebasic
XIncludeFile "src/EmbeddedAssets.pbi"

DataSection
  webapp:
  IncludeBinary "webapp.zip"
  webappEnd:
EndDataSection
```

**Step 3 — Call `OpenEmbeddedPack` before `StartServer`:**
```purebasic
UseZipPacker()   ; required — links the ZIP decompressor
OpenEmbeddedPack(?webapp, ?webappEnd - ?webapp)
```

**Step 4 — In your handler, try embedded assets first:**
```purebasic
If ServeEmbeddedFile(connection, req\Path)
  ProcedureReturn #True
EndIf
; fall through to disk serving
ServeFile(connection, @g_Config, @req, @bytesOut, @statusCode)
```

`ServeEmbeddedFile` returns `#False` if the pack was not opened (development builds without `IncludeBinary`) so the disk fallback always works for local development. Only the release binary carries the embedded data.

---

## 12. Adding URL Rewriting

```purebasic
XIncludeFile "src/RewriteEngine.pbi"

; In Main():
InitRewriteEngine()
LoadGlobalRules("rewrite.conf")

; In HandleRequest(), before ServeFile():
Protected rwResult.RewriteResult
If ApplyRewrites(req\Path, g_Config\RootDirectory, @rwResult)
  If rwResult\Action = 2
    ; send redirect and return
    Protected h.s = "Location: " + rwResult\RedirURL + #CRLF$
    SendNetworkString(connection, BuildResponseHeaders(rwResult\RedirCode, h, 0), #PB_Ascii)
    ProcedureReturn #True
  ElseIf rwResult\Action = 1
    req\Path = rwResult\NewPath
  EndIf
EndIf

; At shutdown:
CleanupRewriteEngine()
```

`rewrite.conf` syntax:
```conf
rewrite /about /about.html
rewrite /blog/* /blog/posts/{path}.html
rewrite ~/user/([0-9]+) /profile/{re.1}
redir   /old-page /new-page 301
```

---

## 13. The Complete main.pb in Context

With all the above sections in mind, every line of `main.pb` maps to a specific module and responsibility:

| Lines | What it does | Module |
|-------|-------------|--------|
| `EnableExplicit` + `ImportC getpid` | Compile guard + POSIX PID | — |
| `XIncludeFile` (16 lines) | Pull in all library modules | All |
| `Global g_Config` | Shared runtime config | Types.pbi |
| `HandleRequest()` | Default request callback | Uses all serving modules |
| `LoadDefaults` + `ParseCLI` | Populate g_Config | Config.pbi |
| `InitRewriteEngine` + `LoadGlobalRules` | Rewrite rule setup | RewriteEngine.pbi |
| `g_LogLevel` / `g_LogMaxBytes` / `g_LogKeepCount` | Logger config | Logger.pbi |
| `getpid()` + PID file write | Process identity | libc / file I/O |
| `OpenLogFile` + `OpenErrorLog` | Log file handles | Logger.pbi |
| `StartDailyRotation` | Midnight rotation thread | Logger.pbi |
| `InstallSignalHandlers` | SIGHUP → reopen logs | SignalHandler.pbi |
| `OpenEmbeddedPack` | In-memory asset ZIP | EmbeddedAssets.pbi |
| Print startup banner | User feedback | — |
| `g_Handler = @HandleRequest()` | Register callback | TcpServer.pbi |
| `StartServer()` | Blocking event loop | TcpServer.pbi |
| Reverse cleanup sequence | Graceful shutdown | All |

---

## 14. Summary: Module Responsibilities at a Glance

| Module | What it owns | What it does NOT own |
|--------|-------------|---------------------|
| `Global.pbi` | HTTP status constants, buffer sizes | No procedures |
| `Types.pbi` | `HttpRequest`, `ServerConfig`, `RewriteResult` | No procedures |
| `TcpServer.pbi` | TCP socket, event loop, thread dispatch | HTTP parsing, file serving |
| `HttpParser.pbi` | Raw string → `HttpRequest` | Response building |
| `HttpResponse.pbi` | Status lines, header assembly, `SendTextResponse` | File I/O |
| `FileServer.pbi` | Path resolution, ETag, 304, range, gz, SPA, hidden | Directory HTML |
| `DirectoryListing.pbi` | Directory HTML generation | File serving |
| `RangeParser.pbi` | `Range:` header parsing, 206 sending | Full-file serving |
| `MimeTypes.pbi` | Extension → `Content-Type` mapping | Everything else |
| `Logger.pbi` | Access + error log, rotation, daily thread, SIGHUP reopen | Request handling |
| `EmbeddedAssets.pbi` | In-memory ZIP decompression and serving | Disk serving |
| `Config.pbi` | `ServerConfig` defaults + CLI parsing | Runtime behavior |
| `RewriteEngine.pbi` | Rule loading, matching, `ApplyRewrites` | HTTP sending |
| `DateHelper.pbi` | `HTTPDate()` — RFC 7231 format | Everything else |
| `UrlHelper.pbi` | `URLDecodePath()`, `NormalizePath()` | Everything else |
| `SignalHandler.pbi` | `signal()` registration, `g_ReopenLogs` flag | Log I/O |

Each module is independently testable. The 108 unit tests in `tests/` verify them without running a real TCP server.
