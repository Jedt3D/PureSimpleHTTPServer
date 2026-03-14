# PureSimpleHTTPServer v1.5.0 — Architecture Reference

## 1. Overview

PureSimpleHTTPServer is a single-binary HTTP/1.1 static file server written entirely in PureBasic 6.x, compiled with the C backend (`pbcompiler -cl -t`). The `-t` flag enables thread-safe mode, which is required by the thread-per-connection dispatch model.

The server ships as source code. Integrators compile it directly into their own binary, optionally embedding a ZIP-packed web application in a `DataSection` block so that no separate file deployment is needed.

Key design properties:

- **Single binary.** No external runtime, no configuration file required. All defaults are valid for immediate use.
- **Thread-per-connection.** Each complete HTTP request is handed off to a dedicated OS thread. The main event loop stays unblocked and continues accepting new connections.
- **C backend.** PureBasic's C backend produces portable C code before final compilation. This matters for the `ImportC ""` block used to call `getpid()` on POSIX targets, and for the `signal()` import used by the SIGHUP handler.
- **No heap allocator overhead.** Buffers are allocated with `AllocateMemory` and freed immediately after use. Strings are PureBasic managed strings; no manual string allocation is required except in `RewriteEngine.pbi`, where `Global Dim` arrays are replaced with raw memory blocks to work around a PureUnit/ARM64 initialisation bug.

---

## 2. Module Map

The inclusion order in `main.pb` determines the compile order. Each `XIncludeFile` is guarded by PureBasic's `XIncludeFile` semantics (included at most once per compilation unit).

```
main.pb
 |
 +-- Global.pbi          (constants, HTTP status codes, buffer sizes)
 +-- Types.pbi           (HttpRequest, HttpResponse, RangeSpec, ServerConfig, RewriteResult)
 +-- DateHelper.pbi      (HTTPDate — RFC 7231 date formatting)
 +-- UrlHelper.pbi       (URLDecodePath, NormalizePath)
 +-- HttpParser.pbi      (ParseHttpRequest, GetHeader)
 |     depends on: Types.pbi, UrlHelper.pbi
 +-- HttpResponse.pbi    (StatusText, BuildResponseHeaders, SendTextResponse)
 |     depends on: Global.pbi
 +-- TcpServer.pbi       (StartServer, StopServer, ConnectionThread, close-queue)
 |     depends on: Global.pbi
 +-- MimeTypes.pbi       (GetMimeType)
 +-- Logger.pbi          (OpenLogFile, LogAccess, LogError, rotation, daily thread)
 |     depends on: Global.pbi
 +-- FileServer.pbi      (ServeFile, ResolveIndexFile, BuildETag, IsHiddenPath)
 |     depends on: Global.pbi, Types.pbi, DateHelper.pbi, HttpParser.pbi,
 |                 HttpResponse.pbi, MimeTypes.pbi
 |     forward-declares: BuildDirectoryListing, ParseRangeHeader, SendPartialResponse
 +-- DirectoryListing.pbi (BuildDirectoryListing)
 |     depends on: Global.pbi, DateHelper.pbi
 +-- RangeParser.pbi     (ParseRangeHeader, SendPartialResponse)
 |     depends on: Global.pbi, Types.pbi, HttpResponse.pbi
 +-- EmbeddedAssets.pbi  (OpenEmbeddedPack, ServeEmbeddedFile, CloseEmbeddedPack)
 |     depends on: Global.pbi, MimeTypes.pbi, HttpResponse.pbi
 +-- Config.pbi          (LoadDefaults, ParseCLI)
 |     depends on: Global.pbi, Types.pbi
 +-- RewriteEngine.pbi   (InitRewriteEngine, LoadGlobalRules, ApplyRewrites,
 |                         CleanupRewriteEngine, GlobalRuleCount)
 |     depends on: Global.pbi, Types.pbi
 +-- SignalHandler.pbi   (InstallSignalHandlers, RemoveSignalHandlers)
       depends on: Logger.pbi (g_ReopenLogs)
```

`FileServer.pbi` uses forward `Declare` statements for `BuildDirectoryListing`, `ParseRangeHeader`, and `SendPartialResponse` because those modules are included after it. PureBasic resolves forward declarations at the end of the compilation unit; this is intentional and not a circular dependency.

---

## 3. Request Lifecycle

The following describes the path of a single HTTP GET request from TCP accept to final response, referencing the actual procedure names.

### 3.1 Connection accept (main thread)

`StartServer(port.i)` calls `CreateNetworkServer(#PB_Any, port, #PB_Network_TCP)` and enters a blocking `Repeat … Until g_Running = #False` loop driven by `NetworkServerEvent(serverID)`.

On `#PB_NetworkEvent_Connect`, the client ID is stored as a key in the local `accum` map with an empty accumulation string.

### 3.2 Data accumulation (main thread)

On `#PB_NetworkEvent_Data`, `ReceiveNetworkData` fills a 64 KB (`#RECV_BUFFER_SIZE`) stack-allocated buffer. The received bytes are appended to `accum(clientKey)` as an ASCII string.

Dispatch occurs when `FindString(accum(clientKey), #CRLF$ + #CRLF$)` returns a positive position, indicating that the complete request header block has arrived. The server does not wait for a body beyond the headers before dispatching.

### 3.3 Thread dispatch

An `AllocateStructure(ThreadData)` block is filled with the client connection ID and the accumulated raw string. `CreateThread(@ConnectionThread(), *td)` hands this to a new OS thread. The main thread immediately returns to the event loop.

If `CreateThread` fails (OS thread limit reached), the request is handled synchronously on the main thread as a fallback, and `CloseNetworkConnection` is called directly.

### 3.4 ConnectionThread (worker thread)

```
Procedure ConnectionThread(*data.ThreadData)
```

Extracts `client` and `raw` from `*data`, frees the `ThreadData` structure, then calls `g_Handler(client, raw)`. On return, it pushes `client` onto `g_CloseList` under `g_CloseMutex` — it does **not** call `CloseNetworkConnection` directly (see Section 4).

### 3.5 HandleRequest (worker thread, via g_Handler)

```
Procedure.i HandleRequest(connection.i, raw.s)
```

Defined in `main.pb`. This is the only place where application logic is wired together.

1. **Parse.** `ParseHttpRequest(raw, req)` fills an `HttpRequest` structure. On failure, sends a 400 and returns.

2. **Rewrite/redirect.** `ApplyRewrites(req\Path, g_Config\RootDirectory, @rwResult)` is called for every GET request. If `rwResult\Action = 2` (redirect), `BuildResponseHeaders` is used to send a 301/302 and the function returns. If `rwResult\Action = 1` (rewrite), `req\Path` is updated in place (query string split off if `?` is present).

3. **Embedded assets.** `ServeEmbeddedFile(connection, req\Path)` is tried first. It returns `#False` immediately if no pack is open, so there is no overhead when not in embedded mode.

4. **Disk serving.** `ServeFile(connection, @g_Config, @req, @bytesOut, @statusCode)` handles all remaining cases: hidden path blocking, directory index resolution, directory listing, clean URLs, pre-compressed `.gz` sidecars, ETag/304 conditional requests, Range/206 partial content, and the regular 200 path.

5. **Access log.** `LogAccess(clientIP, method, path, version, statusCode, bytesOut, referer, userAgent)` is called unconditionally after every handled request.

### 3.6 Close-queue drain (main thread)

At the top of every event loop iteration, the main thread acquires `g_CloseMutex`, iterates `g_CloseList`, calls `CloseNetworkConnection` for each queued ID, then clears the list.

---

## 4. Threading Model

### Main thread responsibilities

- `NetworkServerEvent` loop — the only thread that calls PureBasic network functions on the server socket.
- `CloseNetworkConnection` calls — see below.
- `g_CloseList` drain — every loop iteration, under `g_CloseMutex`.
- Signal handler installation (`InstallSignalHandlers`) and removal (`RemoveSignalHandlers`) — called before and after `StartServer` respectively.

### Worker threads

One thread is created per dispatched request via `CreateThread(@ConnectionThread(), *td)`. Threads are detached (PureBasic does not join them); the connection ID is the only shared resource passed out, via the close queue.

### Why CloseNetworkConnection must run on the main thread

PureBasic's `CloseNetworkConnection` internally modifies the library's connection table, which is also read and written by `NetworkServerEvent` on the main thread. Calling `CloseNetworkConnection` from a worker thread creates a race condition that produces a SIGSEGV under concurrent load. The close-queue pattern (`g_CloseList` + `g_CloseMutex`) serialises all close calls back onto the main thread, eliminating this race.

### Mutex inventory

| Mutex | Global | Protects |
|-------|--------|----------|
| `g_CloseMutex` | `TcpServer.pbi` | `g_CloseList` — worker threads push, main thread pops |
| `g_LogMutex` | `Logger.pbi` | Both log file handles (`g_LogFile`, `g_ErrorLogFile`), `g_ReopenLogs` flag, and all rotation state |
| `g_RewriteMutex` | `RewriteEngine.pbi` | All rewrite rule arrays and the per-directory cache |

The logger uses a single mutex for both the access log and the error log. This prevents interleaved lines when a worker thread calls both `LogAccess` and `LogError` in close succession, at the cost of slightly increased contention on high-traffic servers.

---

## 5. Global State

The following globals span module boundaries. Modules that define their own internal globals (such as `g_LogFile`, `g_LogMutex`, `g_GR_Count`) are documented in the Module Reference.

| Global | Type | Defined in | Purpose |
|--------|------|-----------|---------|
| `g_Handler` | `ConnectionHandlerProto` | `TcpServer.pbi` | Function pointer set to `@HandleRequest()` in `main.pb` before `StartServer` is called |
| `g_Running` | `.i` | `TcpServer.pbi` | Set to `#True` by `StartServer`; set to `#False` by `StopServer` to break the event loop |
| `g_CloseMutex` | `.i` | `TcpServer.pbi` | Mutex handle protecting `g_CloseList` |
| `g_CloseList` | `NewList .i()` | `TcpServer.pbi` | Linked list of connection IDs awaiting close on the main thread |
| `g_EmbeddedPack` | `.i` | `EmbeddedAssets.pbi` | `CatchPack` handle; 0 when no embedded assets are present |
| `g_ServerPID` | `.i` | `Logger.pbi` | Process ID written to the error log `[pid N]` field and to the PID file |
| `g_LogLevel` | `.i` | `Logger.pbi` | Minimum error log level threshold (0=none 1=error 2=warn 3=info); copied from `g_Config\LogLevel` at startup |
| `g_LogMaxBytes` | `.i` | `Logger.pbi` | Size-rotation threshold in bytes; 0 disables size-based rotation |
| `g_LogKeepCount` | `.i` | `Logger.pbi` | Maximum number of archived log files to keep per log |
| `g_ReopenLogs` | `.i` | `Logger.pbi` | Set to 1 by the SIGHUP handler; checked inside `g_LogMutex` by `LogAccess`/`LogError` |
| `g_RewriteMutex` | `.i` | `RewriteEngine.pbi` | Mutex handle protecting all rewrite rule storage |
| `g_Config` | `ServerConfig` | `main.pb` | Parsed runtime configuration; read-only after `ParseCLI` returns |

`g_Config` is declared in `main.pb` rather than a shared header because it is the only true application-level singleton. All modules that need configuration receive a `*cfg.ServerConfig` pointer argument rather than reading `g_Config` directly, which keeps them testable in isolation.

---

## 6. Memory Management

### String memory

PureBasic manages string memory automatically. `HttpRequest`, `RewriteResult`, and `ServerConfig` structures contain `.s` string fields that are reference-counted by the runtime. No explicit freeing is needed for structures allocated on the stack with `Protected`.

### Network receive buffer

`StartServer` allocates one 64 KB (`#RECV_BUFFER_SIZE`) buffer with `AllocateMemory` at server startup and frees it at shutdown. This single buffer is reused for every `ReceiveNetworkData` call, which is safe because all data is immediately copied into the PureBasic `accum` string map.

### File send buffers

`ServeFile` and `SendPartialResponse` allocate a buffer of exactly `fileSize + 1` (or `rangeLen + 1`) bytes per request, fill it with `ReadData`, send it with `SendNetworkData`, and immediately free it with `FreeMemory`. There is no pooling; each request owns its buffer for its lifetime only.

### RewriteEngine flat arrays

`RewriteEngine.pbi` does not use `Global Dim` arrays. Instead, `InitRewriteEngine()` calls `AllocateMemory` for each logical array and stores the raw pointer in a scalar `Global .i` variable. Elements are accessed via `RW_IGET`/`RW_ISET` macros that compute byte offsets manually.

This design works around three bugs in PureBasic 6.30 ARM64 under PureUnit:

1. `Global NewList` + `AddElement` inside any procedure corrupts list internal state; subsequent `ForEach` or `ClearList` segfaults.
2. `Global Dim` of structure types with embedded `.s` string fields causes memory corruption during global initialisation.
3. PureUnit skips top-level `main()` initialisation code, so `Global Dim` array descriptors remain zero. `SYS_ReAllocateArray` (used internally by `ReDim`) reads element-size and type from the descriptor — both zero — and crashes.

`AllocateMemory` called from inside `InitRewriteEngine()` runs correctly regardless of how the module is loaded, making it safe for both production and test contexts.

---

## 7. Extension Points

### Replacing the request handler

The server's dispatch point is the `g_Handler` function pointer:

```purebasic
Prototype.i ConnectionHandlerProto(connection.i, raw.s)
Global g_Handler.ConnectionHandlerProto
```

Before calling `StartServer`, assign your handler:

```purebasic
g_Handler = @MyHandleRequest()
```

`ConnectionThread` calls `g_Handler(client, raw)` on every dispatched request. The signature is fixed: `connection` is the PureBasic network connection ID (used with `SendNetworkString`/`SendNetworkData`); `raw` is the complete raw HTTP request string as received from the client.

The built-in `HandleRequest` procedure in `main.pb` shows the canonical implementation: parse, rewrite, embedded-first dispatch, disk dispatch, log. A custom handler can skip any of these steps or add new ones (e.g. a dynamic route table, WebSocket upgrade, authentication middleware) by replacing or wrapping `HandleRequest`.

### Adding rewrite rules at runtime

`LoadGlobalRules(path.s)` can be called at any time from the main thread. It acquires `g_RewriteMutex`, frees the existing global rules, and reloads from the file. Worker threads already holding the mutex will finish their current rule evaluation first.

### Embedding a web application

To ship a web application inside the binary:

1. Run `scripts/pack_assets.sh dist/ webapp.zip` to create a ZIP archive of the built application.
2. Add `UseZipPacker()` to `main.pb` and include the binary in a `DataSection`:
   ```purebasic
   DataSection
     webapp:    IncludeBinary "webapp.zip"
     webappEnd:
   EndDataSection
   ```
3. Call `OpenEmbeddedPack(?webapp, ?webappEnd - ?webapp)` in `Main()` before `StartServer`.

`ServeEmbeddedFile` is called before `ServeFile` on every GET request. When the embedded pack is open, assets are served directly from the in-memory decompressed buffer. Files not found in the pack fall through to disk serving, allowing the embedded assets to be selectively overridden from the filesystem during development.
