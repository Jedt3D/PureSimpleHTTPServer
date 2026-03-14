# Changelog

All notable changes to PureSimpleHTTPServer are documented here.

Format: `## vX.Y.Z — YYYY-MM-DD HH:MM`

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
