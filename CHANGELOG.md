# Changelog

All notable changes to PureSimpleHTTPServer are documented here.

Format: `## vX.Y.Z — YYYY-MM-DD HH:MM`

---

## v1.0.3 — 2026-03-15 02:00

### Fix crash under concurrent load: move CloseNetworkConnection() to main thread

**Fixed**
- `src/TcpServer.pbi` — `CloseNetworkConnection(client)` was called from worker threads while the main thread was inside `NetworkServerEvent()`. Both access PureBasic's internal connection table, causing heap corruption and `EXC_BAD_ACCESS (SIGSEGV)` after ~500–700 requests with `ab -c 10`. Fix: worker threads now push the connection ID into `g_CloseList` (protected by `g_CloseMutex`); the main event loop drains the queue at the top of every iteration and calls `CloseNetworkConnection()` exclusively from the main thread.

**Verified**
- `ab -n 1000 -c 10 http://127.0.0.1:9999/` — 1000/1000 requests successful, no crash, mean 2 ms, 38 MB/s transfer rate

**Pitfalls documented** (common-pitfalls.md #22)
- `CloseNetworkConnection()` must only be called from the main thread (the thread running `NetworkServerEvent()`); calling it from worker threads races on PureBasic's internal connection table

---

## v1.0.2 — 2026-03-15 01:00

### Fix compile error: replace `NetworkClientIP()` with `IPString(GetClientIP())`

**Fixed**
- `src/main.pb` — `NetworkClientIP(connection)` does not exist in PureBasic 6.x. Replaced with `IPString(GetClientIP(connection))`: `GetClientIP(Client)` returns the numeric IP of a connected client; `IPString()` converts it to a dotted string (`"127.0.0.1"`). This fixes the compile error `NetworkClientIP() is not a function, array, list, map or macro` on line 33.

**Pitfalls documented** (common-pitfalls.md #21)
- `NetworkClientIP()` does not exist; use `IPString(GetClientIP(Client))` for dotted-decimal client IP

**Docs**
- `docs/DEVELOPER_GUIDE.md` — added `NetworkClientIP` → `IPString(GetClientIP())` gotcha

---

## v1.0.1 — 2026-03-15 00:30

### Default web root changed from CWD to `wwwroot/` next to binary

**Changed**
- `src/Config.pbi` — `LoadDefaults()` now sets `RootDirectory` to `GetPathPart(ProgramFilename()) + "wwwroot"` instead of `GetCurrentDirectory()`. The server now always looks for content in a `wwwroot/` folder beside the executable, regardless of the working directory at launch time. Override with `--root DIR` as before.
- `docs/USAGE_GUIDE.md`, `docs/ARCHITECTURE_DESIGN.md`, `docs/DEVELOPER_GUIDE.md` — fully updated to reflect v1.0.0/v1.0.1 state (USAGE_GUIDE was still Phase A vintage; ARCHITECTURE_DESIGN had duplicate sections and a stale lifecycle diagram; DEVELOPER_GUIDE updated test count to 70, added pitfall notes for threads and PureUnit)
- `README.md` — fixed `--root` flag description

---

## v1.0.0 — 2026-03-14 23:59

### Phase E — Thread-per-Connection, Logger, Full CLI Parsing

**Added**
- `src/Logger.pbi` — `OpenLogFile()`, `LogAccess()`, `CloseLogFile()`
  - Mutex-protected writes for concurrent access from handler threads
  - Format: `[YYYY-MM-DD HH:MM:SS] IP METHOD /path STATUS BYTES`
  - `OpenLogFile()`: creates log file if absent, appends if existing; returns `#False` for invalid paths
  - `LogAccess()`: no-op if no log file is open (safe to call unconditionally)
  - `CloseLogFile()`: flushes buffers before closing; harmless if file not open
- `tests/test_logger.pb` — 7 unit tests: open/close lifecycle, no-op when closed, field presence, timestamp format, multi-line append

**Changed**
- `src/TcpServer.pbi` — thread-per-connection model
  - Data accumulation remains in the main event loop (single-threaded, no map mutex needed)
  - Complete requests are handed off to `ConnectionThread` via `AllocateStructure(ThreadData)`
  - Synchronous fallback if `CreateThread()` fails
  - Requires `-t` compiler flag for thread-safe memory allocation
- `src/Config.pbi` — full CLI argument parsing
  - `ParseCLI()` supports: `--port N`, `--root DIR`, `--browse`, `--spa`, `--log FILE`
  - Legacy bare port number (`8080`) still supported for backward compatibility
  - Returns `#False` for unrecognized or malformed arguments
- `src/main.pb` — integrates Logger; updated `HandleRequest()` calls `LogAccess()` after each response; updated `Main()` opens/closes log file from `g_Config\LogFile`; updated compile comment to include `-t` flag; updated usage string
- `src/Global.pbi` — version bumped to 1.0.0
- `tests/test_config.pb` — replaced placeholder with 9 unit tests: all `LoadDefaults()` fields, ParseCLI crash-safety tests (noted: PureUnit injects runtime args, so return value not asserted)

**Pitfalls documented** (common-pitfalls.md #20)
- `ProgramParameter()` returns PureUnit's own runtime arguments inside test binaries; do not Assert on `ParseCLI()` return value in PureUnit tests

---

## v0.4.0 — 2026-03-14 23:00

### Phase D — Embedded Assets via CatchPack/UncompressPackMemory

**Added**
- `src/EmbeddedAssets.pbi` — `OpenEmbeddedPack(*packData=0, packSize.i=0)`, `ServeEmbeddedFile()`, `CloseEmbeddedPack()`
  - `OpenEmbeddedPack()` with default 0,0 args returns `#False` (graceful no-pack fallback)
  - `ServeEmbeddedFile()` decompresses directly by filename via `UncompressPackMemory()` with a 4 MB ceiling buffer
  - `CloseEmbeddedPack()` releases the `CatchPack` handle; safe to call when no pack is open
- `tests/test_embedded_assets.pb` — 4 unit tests: no-pack fallback, serve-without-open, close-harmless, invalid-pointer/size guard

**Changed**
- `src/main.pb` — `HandleRequest()` tries `ServeEmbeddedFile()` before `ServeFile()`; `Main()` calls `OpenEmbeddedPack()` / `CloseEmbeddedPack()` on startup/shutdown
- `src/Global.pbi` — version bumped to 0.4.0

**Design notes**
- `g_EmbeddedPack.i` is a plain integer Global (safe in PureUnit — scalar, compiler-zeroed, no runtime init)
- To embed assets: add `UseZipPacker()` + `DataSection webapp: IncludeBinary "webapp.zip" webappEnd: EndDataSection` in main.pb, then call `OpenEmbeddedPack(?webapp, ?webappEnd - ?webapp)`
- Without DataSection labels the default `OpenEmbeddedPack()` call returns `#False` and disk serving is used

---

## v0.3.0 — 2026-03-14 22:00

### Phase C — Range Requests, Directory Listing, SPA Fallback, Hidden Paths, .gz Sidecars

**Added**
- `src/DirectoryListing.pbi` — `BuildDirectoryListing()`: sorted HTML table (dirs first), URLEncoder hrefs, parent ".." link, file size and Last-Modified columns
- `src/RangeParser.pbi` — `ParseRangeHeader()`: full/open-ended/suffix range parsing; `SendPartialResponse()`: 206 Partial Content with Content-Range
- `src/FileServer.pbi` — `IsHiddenPath()`: blocks hidden path segments (e.g. `.git`, `.env`)
- `src/Types.pbi` — `Structure RangeSpec` moved here so FileServer and RangeParser can share it

**Changed**
- `src/FileServer.pbi` — `ServeFile(connection, *cfg, *req)` signature (reads all config + headers internally):
  - Checks `cfg\HiddenPatterns` (403 if matched)
  - Directory browsing via `BuildDirectoryListing` when `cfg\BrowseEnabled`
  - SPA fallback: serves root index for 404s when `cfg\SpaFallback`
  - Pre-compressed `.gz` sidecar: served with `Content-Encoding: gzip` when client accepts gzip
  - `If-None-Match` / ETag → 304 Not Modified
  - `Range` header → 206 Partial Content via `SendPartialResponse()`
  - Forward `Declare` statements for `BuildDirectoryListing`, `ParseRangeHeader`, `SendPartialResponse` (defined in later-included files)
- `src/main.pb` — updated to include DirectoryListing and RangeParser; passes `@g_Config, @req` to ServeFile
- `src/Global.pbi` — version bumped to 0.3.0

**Tests**
- `tests/test_range_parser.pb` — 9 unit tests: full/open/suffix/clamped ranges, start-beyond-EOF, invalid formats
- `tests/test_directory_listing.pb` — 9 unit tests: HTML structure, filenames, subdir links, parent link (root vs non-root), `IsHiddenPath()` (3 cases)

---

## v0.2.0 — 2026-03-14 21:00

### Phase B — Static File Serving

**Added**
- `src/MimeTypes.pbi` — `GetMimeType(ext)` via `Select/Case`, ~45 extension mappings
- `src/FileServer.pbi` — `ServeFile()`, `ResolveIndexFile()`, `BuildETag()`
  - `ServeFile()` reads file into memory, sends with Content-Type, ETag, Last-Modified headers
  - Directory requests → index file resolution; 403 if no index found; 404 for missing files
  - ETag = quoted hex(size)-hex(mtime) for browser caching
- `src/main.pb` — updated to serve static files via `ServeFile()` (replaces Phase A hello-world)
- `tests/test_mime_types.pb` — 6 unit tests: text, script, image, font, archive, unknown types
- `tests/test_file_server.pb` — 8 unit tests: `ResolveIndexFile` (4 cases), `BuildETag` (4 cases)

**Changed**
- `src/main.pb` — now loads config via `LoadDefaults()` + `ParseCLI()`, serves files from `cfg\RootDirectory`
- `src/Global.pbi` — version bumped to 0.2.0

**Pitfalls documented** (common-pitfalls.md #18, #19)
- `Global NewMap`/`Global NewList` at top level causes segfault in PureUnit
- `ProcedureUnitStartup`/`Shutdown` require a procedure name

---

## v0.1.0 — 2026-03-14 18:00

### Phase A — Foundation

**Added**
- `src/Global.pbi` — application-wide constants, enumerations, version
- `src/Types.pbi` — `HttpRequest`, `HttpResponse`, `ServerConfig` structures
- `src/DateHelper.pbi` — `HTTPDate(ts.q)` RFC 7231 date formatter
- `src/UrlHelper.pbi` — `URLDecodePath()`, `NormalizePath()` with safe traversal handling
- `src/HttpParser.pbi` — HTTP/1.1 request parser: method, path, query string, headers
- `src/HttpResponse.pbi` — response builder: `StatusText()`, `BuildResponseHeaders()`, `SendTextResponse()`
- `src/TcpServer.pbi` — single-threaded TCP server with request accumulation loop
- `src/main.pb` — entry point: Hello World HTTP response with parsed request info
- Skeleton source modules for Phases B–E: `MimeTypes`, `FileServer`, `DirectoryListing`, `RangeParser`, `Logger`, `Config`, `EmbeddedAssets`
- `tests/test_date_helper.pb` — 4 unit tests for `HTTPDate()`
- `tests/test_url_helper.pb` — 4 unit tests for URL decode and path normalization
- `tests/test_http_parser.pb` — 5 unit tests for HTTP request parsing
- `tests/test_http_response.pb` — 5 unit tests for response building
- Placeholder unit tests for Phases B–E
- `tests/run_tests.sh` — PureUnit test runner
- `docs/` — USAGE_GUIDE, ARCHITECTURE_DESIGN, DEVELOPER_GUIDE

---

## v0.0.1 — 2026-03-14 17:00

### Scaffold

**Added**
- Project directory structure: `src/`, `tests/`, `docs/`, `scripts/`
- Git repository initialization
- `.gitignore`, `README.md`, `CHANGELOG.md`
