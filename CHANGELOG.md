# Changelog

All notable changes to PureSimpleHTTPServer are documented here.

Format: `## vX.Y.Z — YYYY-MM-DD HH:MM`

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
