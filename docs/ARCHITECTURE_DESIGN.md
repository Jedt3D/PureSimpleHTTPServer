# Architecture Design — PureSimpleHTTPServer

## Overview

PureSimpleHTTPServer is a single-binary HTTP/1.1 static file server. Each module is an independent `.pbi` include file with no global executable code — only procedures, structures, and constants. This enables every module to be unit-tested independently via PureUnit.

## Source Module Map

```
src/
  main.pb               Entry point: wires all modules, event loop
  Global.pbi            Constants, enumerations, #APP_VERSION
  Types.pbi             Shared structures: HttpRequest, HttpResponse, ServerConfig
  DateHelper.pbi        HTTPDate() — RFC 7231 date formatting
  UrlHelper.pbi         URLDecodePath(), NormalizePath()
  HttpParser.pbi        ParseHttpRequest(), GetHeader()
  HttpResponse.pbi      StatusText(), BuildResponseHeaders(), SendTextResponse()
  TcpServer.pbi         StartServer(), StopServer(), g_Handler callback
  MimeTypes.pbi         GetMimeType()  [Phase B]
  FileServer.pbi        ServeFile(), ResolveIndexFile(), BuildETag()  [Phase B]
  DirectoryListing.pbi  BuildDirectoryListing()  [Phase C]
  RangeParser.pbi       ParseRangeHeader()  [Phase C]
  Logger.pbi            LogAccess(), OpenLogFile(), CloseLogFile()  [Phase E]
  Config.pbi            LoadDefaults(), ParseCLI()  [Phase E]
  EmbeddedAssets.pbi    OpenEmbeddedPack(), ServeEmbeddedFile()  [Phase D]
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
            │       └── FileServer.pbi
            ├── DirectoryListing.pbi
            ├── RangeParser.pbi
            ├── Config.pbi
            └── EmbeddedAssets.pbi

DateHelper.pbi      (no project dependencies — pure PureBasic built-ins)
Logger.pbi ── Global.pbi
```

All `XIncludeFile` paths are relative to the file containing the directive, so any module can be included from any location (including `tests/`) and its dependencies resolve correctly.

## HTTP Request Lifecycle (Phase B — current)

```
Browser/client
  │
  ▼
TCP socket  (CreateNetworkServer → NetworkServerEvent loop in TcpServer.pbi)
  │  ReceiveNetworkData → accumulate bytes until \r\n\r\n found
  ▼
Raw HTTP string  →  ParseHttpRequest()  →  HttpRequest struct
                     (HttpParser.pbi)
  │
  ▼
HandleRequest()  (main.pb)
  │  req\Method = "GET"
  ▼
ServeFile(connection, docRoot, urlPath, indexList)
  │  (FileServer.pbi)
  ├── FileSize() = -2 (directory) → ResolveIndexFile() → 403 if no index
  ├── FileSize() < 0 (missing)    → 404
  ├── AllocateMemory + ReadData   → 500 on I/O error
  └── BuildResponseHeaders() + SendNetworkData()  → 200
        Content-Type via GetMimeType(LCase(GetExtensionPart()))
        ETag via BuildETag() = hex(size)-hex(mtime)
        Last-Modified via HTTPDate(GetFileDate())
  │
  ▼
CloseNetworkConnection()
```

## HTTP Request Lifecycle (Phase B onwards)

```
HandleRequest()
  │
  ├── Path starts with hidden pattern? → 403
  ├── ServeEmbeddedFile()              → 200 from in-memory pack (Phase D)
  ├── ServeFile() from disk             → 200 / 206 / 304 (Phase B/C)
  │     ├── ResolveIndexFile()          → serve index file if path is dir
  │     ├── BuildDirectoryListing()     → 200 HTML listing if browse=on (Phase C)
  │     └── SPA fallback               → serve index.html if spa=on (Phase C)
  └── 404 Not Found
```

## Concurrency Model

| Phase | Model |
|-------|-------|
| A–D | Single-threaded: one connection at a time (Connection: close) |
| E | Thread-per-connection: each `#PB_NetworkEvent_Connect` spawns a new thread; shared state (logger, config, asset pack) protected by mutexes |

## Embedded Asset Strategy (Phase D)

```
Build time:
  1. scripts/pack_assets.sh dist/ src/webapp.zip
  2. pbcompiler sees: DataSection / webapp: / IncludeBinary "webapp.zip" / webappEnd: / EndDataSection

Runtime:
  1. OpenEmbeddedPack()         -> CatchPack(#PB_Any, ?webapp, ?webappEnd - ?webapp)
  2. Request arrives for /app/  -> ServeEmbeddedFile() -> ExaminePack() + UncompressPackMemory()
  3. Falls back to disk if path not in pack
```

## Key Design Decisions

1. **`.pbi` modules, never `.pb`** — forces all modules to be include-file-safe (no top-level executable code), enabling PureUnit testing.
2. **No `Global NewMap`/`Global NewList` at top level** — PureUnit skips top-level initialization; map handles become null → segfault. Use `Select/Case` in procedures instead.
3. **Separation of building vs. sending** — `BuildResponseHeaders()` is pure and testable; `SendTextResponse()` and `ServeFile()` own the network I/O boundary.
4. **`Date.q` for timestamps** — PureBasic `Date()` and `GetFileDate()` return `.q` (Quad, 8-byte), not `.i`.
5. **Content-Length via `StringByteLength(s, #PB_UTF8)`** — not `Len()`, which counts characters not bytes.
6. **Binary file serving via `ReadData()`/`SendNetworkData()`** — text responses use `SendNetworkString(#PB_UTF8)`; binary file bodies use `SendNetworkData()` to avoid encoding.
