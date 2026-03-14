# Architecture Design — PureSimpleHTTPServer

## Overview

PureSimpleHTTPServer is a single-binary HTTP/1.1 static file server. Each module is an independent `.pbi` include file with no global executable code — only procedures, structures, and constants. This enables every module to be unit-tested independently via PureUnit.

## Source Module Map

```
src/
  main.pb               Entry point: wires all modules, event loop
  Global.pbi            Constants, enumerations, #APP_VERSION
  Types.pbi             Shared structures: HttpRequest, HttpResponse, ServerConfig, RangeSpec
  DateHelper.pbi        HTTPDate() — RFC 7231 date formatting
  UrlHelper.pbi         URLDecodePath(), NormalizePath()
  HttpParser.pbi        ParseHttpRequest(), GetHeader()
  HttpResponse.pbi      StatusText(), BuildResponseHeaders(), SendTextResponse()
  TcpServer.pbi         StartServer(), StopServer(), g_Handler, ConnectionThread
  MimeTypes.pbi         GetMimeType()
  FileServer.pbi        ServeFile(), ResolveIndexFile(), BuildETag(), IsHiddenPath()
  DirectoryListing.pbi  BuildDirectoryListing()
  RangeParser.pbi       ParseRangeHeader(), SendPartialResponse()
  EmbeddedAssets.pbi    OpenEmbeddedPack(), ServeEmbeddedFile(), CloseEmbeddedPack()
  Logger.pbi            OpenLogFile(), LogAccess(), CloseLogFile()
  Config.pbi            LoadDefaults(), ParseCLI()
```

## Dependency Graph

```
Global.pbi
    └── Types.pbi
            ├── UrlHelper.pbi
            │       └── HttpParser.pbi
            ├── HttpResponse.pbi
            ├── TcpServer.pbi
            ├── MimeTypes.pbi
            │       └── FileServer.pbi ──► DirectoryListing.pbi (Declare)
            │                        └──► RangeParser.pbi      (Declare)
            ├── EmbeddedAssets.pbi
            ├── Config.pbi
            └── (Logger.pbi — depends on Global.pbi only)

DateHelper.pbi      (no project dependencies — pure PureBasic built-ins)
Logger.pbi ── Global.pbi
```

All `XIncludeFile` paths are relative to the file containing the directive, so any module can be included from any location (including `tests/`) and its dependencies resolve correctly.

## HTTP Request Lifecycle

```
Browser/client
  │
  ▼
TCP socket  (CreateNetworkServer → NetworkServerEvent loop in TcpServer.pbi)
  │  ReceiveNetworkData → accumulate bytes per client until \r\n\r\n found
  │  Complete request → AllocateStructure(ThreadData) → CreateThread(@ConnectionThread())
  ▼
ConnectionThread  (one per request, runs concurrently)
  │
  ▼
HandleRequest()  (main.pb)
  │  clientIP = NetworkClientIP(connection)
  │  ParseHttpRequest(raw, req)  →  HttpRequest struct
  │  req\Method = "GET"
  │
  ├── ServeEmbeddedFile(connection, req\Path)
  │     └── UncompressPackMemory() from in-memory CatchPack  →  200
  │
  ├── ServeFile(connection, *cfg, *req)  (FileServer.pbi)
  │     ├── IsHiddenPath()                        → 403
  │     ├── FileSize() = -2  (directory)
  │     │     ├── ResolveIndexFile()              → serve index file
  │     │     ├── cfg\BrowseEnabled               → BuildDirectoryListing() → 200 HTML
  │     │     └── otherwise                       → 403
  │     ├── FileSize() < 0  (missing)
  │     │     ├── cfg\SpaFallback                 → serve root index.html
  │     │     └── otherwise                       → 404
  │     ├── .gz sidecar + Accept-Encoding:gzip    → 200 gzip
  │     ├── If-None-Match matches ETag             → 304 Not Modified
  │     ├── Range header present                  → 206 Partial Content
  │     └── ReadData → SendNetworkData            → 200
  │
  └── LogAccess(method, path, status, 0, clientIP)  →  Logger.pbi (mutex-protected)
       │
       ▼
  CloseNetworkConnection(client)
```

## Concurrency Model

```
Main event loop  (single-threaded)
  │  NewMap accum.s() — per-client byte accumulation (main-thread only, no mutex needed)
  │  On \r\n\r\n found:
  │    AllocateStructure(ThreadData)  →  {client, raw}
  │    CreateThread(@ConnectionThread(), *td)
  │    DeleteMapElement(accum(), clientKey)
  │
  ├── ConnectionThread A  →  HandleRequest() → LogAccess() → CloseNetworkConnection()
  ├── ConnectionThread B  →  HandleRequest() → LogAccess() → CloseNetworkConnection()
  └── ...  (unbounded; falls back to synchronous if CreateThread fails)

Shared state safety:
  - g_Handler, g_Config, g_EmbeddedPack : read-only after startup — no mutex needed
  - g_LogFile / WriteStringN()          : protected by g_LogMutex (created in OpenLogFile)
  - NewMap accum                         : accessed from main loop only — no mutex needed
  - File / directory I/O                 : thread-safe under -t compiler flag
```

Compile with `-t` (thread-safe mode) is required for Phase E.

## Embedded Asset Strategy

```
Build time:
  1. scripts/pack_assets.sh dist/ src/webapp.zip
  2. In main.pb: UseZipPacker()
                 DataSection
                   webapp:    IncludeBinary "src/webapp.zip"
                   webappEnd:
                 EndDataSection

Runtime:
  1. Main() → OpenEmbeddedPack(?webapp, ?webappEnd - ?webapp)
              → CatchPack(#PB_Any, *addr, size)
  2. Request → ServeEmbeddedFile() → UncompressPackMemory(pack, *buf, maxSize, filename)
  3. Falls back to disk if filename not in pack
```

Without a `DataSection`, `OpenEmbeddedPack()` (called with default args 0, 0) returns `#False` and disk serving is used exclusively.

## Key Design Decisions

1. **`.pbi` modules, never `.pb`** — forces all modules to be include-file-safe (no top-level executable code), enabling PureUnit testing.
2. **No `Global NewMap`/`Global NewList` at top level** — PureUnit skips top-level initialization; map handles become null → segfault. Use `Select/Case` in procedures instead.
3. **Separation of building vs. sending** — `BuildResponseHeaders()` is pure and testable; `SendTextResponse()` and `ServeFile()` own the network I/O boundary.
4. **`Date.q` for timestamps** — PureBasic `Date()` and `GetFileDate()` return `.q` (Quad, 8-byte), not `.i`.
5. **Content-Length via `StringByteLength(s, #PB_UTF8)`** — not `Len()`, which counts characters not bytes.
6. **Binary file serving via `ReadData()`/`SendNetworkData()`** — text responses use `SendNetworkString(#PB_UTF8)`; binary file bodies use `SendNetworkData()` to avoid encoding.
7. **`Declare` for cross-module forward references** — FileServer.pbi calls `BuildDirectoryListing`, `ParseRangeHeader`, `SendPartialResponse` which are defined in later-included files. `Declare` statements at the top of FileServer.pbi tell the compiler the signatures; the linker resolves them from the same compilation unit.
8. **Thread-per-connection data hand-off via `AllocateStructure`** — The main event loop captures the client ID and accumulated raw string into a `ThreadData` structure, spawns the thread, then deletes the map entry. The thread owns the structure and frees it via `FreeStructure` before processing, preventing any use-after-free and keeping the accum map main-thread-only.
9. **Logger mutex pattern** — `g_LogMutex` is created once in `OpenLogFile()` and never freed; `LogAccess()` guards `WriteStringN()` with `LockMutex`/`UnlockMutex` to prevent interleaved log lines from concurrent handler threads.
10. **Default root via `GetPathPart(ProgramFilename())`** — the default web root is `wwwroot/` next to the binary, not the working directory. This ensures consistent behaviour regardless of where the server is launched from.
