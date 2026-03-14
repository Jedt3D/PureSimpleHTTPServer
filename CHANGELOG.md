# Changelog

All notable changes to PureSimpleHTTPServer are documented here.

Format: `## vX.Y.Z — YYYY-MM-DD HH:MM`

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
