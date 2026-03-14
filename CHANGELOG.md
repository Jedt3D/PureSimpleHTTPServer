# Changelog

All notable changes to PureSimpleHTTPServer are documented here.

Format: `## vX.Y.Z — YYYY-MM-DD HH:MM`

---

## v1.5.0 — 2026-03-15 04:30

### Phase G — URL Rewriting and Redirecting

**Added**
- `src/RewriteEngine.pbi` (new) — URL rewrite and redirect engine:
  - `InitRewriteEngine()` / `CleanupRewriteEngine()` — lifecycle management
  - `LoadGlobalRules(path.s)` — load/reload global rules from a `rewrite.conf` file; thread-safe
  - `GlobalRuleCount()` — return number of loaded global rules
  - `ApplyRewrites(path, docRoot, *result)` — apply global then per-directory rules; returns `#True` when a rule matched
  - Rule types: `rewrite` (internal path rewrite) and `redir` (HTTP redirect)
  - Pattern types: exact (`/path`), glob (`/prefix/*` with `{path}`, `{file}`, `{dir}` placeholders), regex (`~/pattern` with `{re.1}`..`{re.9}` capture groups)
  - Per-directory rules: `rewrite.conf` in any served directory, auto-reloaded on mtime change, cached (up to 8 directories × 16 rules)
  - Limits: 64 global rules, 8 cached directories, 16 rules/directory, 9 regex capture groups
  - Implementation: uses `AllocateMemory` + `PokeI`/`PeekI`/`PokeS`/`PeekS` instead of `Global Dim` (PureUnit compatibility — `SYS_ReAllocateArray` reads element size from the descriptor, which is zero when PureUnit skips `main()`)
- `src/main.pb`
  - `--rewrite FILE` CLI flag — path to global `rewrite.conf`
  - `--clean-urls` CLI flag — extensionless paths try `.html` fallback
  - Rewrite/redirect applied before file serving; redirect sends `Location:` header directly; rewrite updates `req\Path` (with query-string splitting) before `ServeFile`
- `docs/URL_REWRITE.md` — reference documentation for the rewrite rule syntax

**Tests**
- `tests/test_rewrite.pb` (new) — 22 unit tests covering:
  - Engine init/cleanup lifecycle
  - Exact, glob, regex rewrites and redirects
  - `{path}`, `{file}`, `{dir}`, `{re.N}` placeholder expansion
  - Default 302 redirect code; explicit 301
  - First-match-wins rule ordering
  - Comment and blank-line parsing
  - Invalid verb rejection
  - LoadGlobalRules file counting
  - Per-directory rule loading from docroot
  - Global-rules-first priority over per-directory rules
  - Double-cleanup safety
- 108 unit tests across 12 files; all pass

---

## v1.4.0 — 2026-03-15 06:00

### Phase F-4 — SIGHUP Log Reopen for logrotate Integration

**Added**
- `src/SignalHandler.pbi` (new) — POSIX signal handler for SIGHUP:
  - `#SIGHUP = 1`, `#SIG_DFL = 0`
  - `ImportC "" signal.i(signum.i, *handler) EndImport`
  - `SIGHUPHandler(signum.i)` — async-signal-safe handler: sets `g_ReopenLogs = 1` only
  - `InstallSignalHandlers()` — installs `SIGHUPHandler` via `signal(#SIGHUP, @SIGHUPHandler())`
  - `RemoveSignalHandlers()` — restores `#SIG_DFL` at shutdown
  - Windows stubs (no-ops): `CompilerElse` block ensures the binary compiles on Windows; Windows users rely on F-2/F-3 built-in rotation
  - Includes logrotate config snippet in header comments
- `src/Logger.pbi`
  - `Global g_ReopenLogs.i = 0` — set by SIGHUP handler; cleared by `ReopenLogs()`
  - `ReopenLogs()` — flushes and closes both open log files, then calls `OpenOrAppend()` at their current paths; called inside `g_LogMutex` when `g_ReopenLogs = 1`
  - `LogAccess()` and `LogError()`: check `g_ReopenLogs` first inside mutex (highest priority, before size-rotation check); also added `g_LogFile > 0` guard before size-rotation `Lof()` call

**Changed**
- `src/main.pb` — `XIncludeFile "SignalHandler.pbi"`; `InstallSignalHandlers()` called after log files are open; `RemoveSignalHandlers()` called at shutdown before `StopDailyRotation()`
- `tests/TestCommon.pbi` — `XIncludeFile "../src/SignalHandler.pbi"` added

**Tests**
- `tests/test_logger.pb` — 21 → 23 tests; 2 new F-4 tests:
  - `Logger_ReopenLogs_FlagClearedAfterWrite` — set `g_ReopenLogs = 1`, call `LogAccess`, verify flag cleared to 0
  - `Logger_ReopenLogs_NewFileReceivesEntry` — rename active log (simulating logrotate), set flag, write entry, verify entry goes to new file at original path; old renamed file retains prior entry
- 86 unit tests across 11 files; all pass

---

## v1.3.0 — 2026-03-15 05:00

### Phase F-3 — Daily Midnight UTC Rotation + PID File

**Added**
- `src/Logger.pbi`
  - `LogRotationThread(*unused)` — background thread: computes seconds to next UTC midnight via `86400 - (ConvertDate(Date(), #PB_Date_UTC) % 86400)`, sleeps 1 second at a time checking `g_StopRotation`, then acquires `g_LogMutex` and calls `RotateLog()` for both open log files
  - `StartDailyRotation()` — creates the thread; no-op if already running
  - `StopDailyRotation()` — sets `g_StopRotation = 1`, calls `WaitThread()`, resets `g_RotationThread = 0`; safe if no thread running
  - New globals: `g_RotationThread.i`, `g_StopRotation.i`
- `src/main.pb`
  - PID detection: `ImportC "" getpid.i() EndImport` for macOS/Linux; `g_ServerPID` set at startup (fills the `[pid N]` field in error log lines)
  - PID file: written at startup when `--pid-file FILE` is given; deleted at shutdown (both normal and start-server-failure paths)
  - Daily rotation: `StartDailyRotation()` called when `cfg\LogDaily = 1` and at least one log is configured; `StopDailyRotation()` called before `CloseLogFile()`

**Changed**
- `src/main.pb` — startup banner now shows `PID file: ... (PID N)` when PID file is active; comment updated to F-3

**Tests**
- `tests/test_logger.pb` — 19 → 21 tests; 2 new: thread starts and `g_RotationThread > 0`, `StopDailyRotation` safe without prior start
- Teardown now calls `StopDailyRotation()` to prevent thread leaks between tests
- 84 unit tests across 11 files; all pass

---

## v1.2.0 — 2026-03-15 04:00

### Phase F-2 — Size-Based Log Rotation

**Added**
- `src/Logger.pbi` — size-based rotation for both access log and error log:
  - `RotationStamp()` — generates `YYYYMMDD-HHMMSS-NNN` stamp (NNN = per-process sequence ensures archive uniqueness within the same second)
  - `PruneArchives(logPath.s)` — scans the log directory for date-stamped archives matching `stem.YYYYMMDD-HHMMSS[-NNN].ext`; deletes oldest files beyond `g_LogKeepCount` (oldest-first, sorted alphabetically = chronologically)
  - `RotateLog(*fh, logPath.s)` — flushes and closes the current file, renames to archive, opens new file, then calls `PruneArchives`; called inside `g_LogMutex`
  - New globals: `g_LogPath`, `g_ErrorLogPath` (saved by `Open*` functions for rotation); `g_LogMaxBytes`, `g_LogKeepCount`, `g_RotationSeq`
  - Rotation check in `LogAccess()` and `LogError()`: `FlushFileBuffers` + `Lof()` check inside mutex before write; skipped when `g_LogMaxBytes = 0`
  - `ExamineDirectory` ID 1 used for pruning (ID 0 reserved for `BuildDirectoryListing`)

**Changed**
- `src/main.pb` — sets `g_LogMaxBytes = cfg\LogSizeMB * 1024 * 1024` and `g_LogKeepCount = cfg\LogKeepCount` at startup

**Tests**
- `tests/test_logger.pb` — 15 → 19 tests; 4 new rotation tests: archive created, archive name has `YYYYMMDD-HHMMSS` stamp, oldest archives pruned to keep-count, rotation disabled when `g_LogMaxBytes = 0`
- 82 unit tests across 11 files; all pass

---

## v1.1.0 — 2026-03-15 03:00

### Phase F-1 — Apache Combined Log Format, Error Log, Log Level Filtering

**Added**
- `src/Logger.pbi` — complete rewrite with full F-1 feature set:
  - **Access log**: Apache Combined Log Format (CLF) — `IP - - [DD/Mon/YYYY:HH:MM:SS +HHMM] "METHOD /path PROTO" STATUS BYTES "Referer" "UA"`
  - **Error log**: `OpenErrorLog()`, `LogError(level, message)`, `CloseErrorLog()` — format `[timestamp] [level] [pid N] message`
  - **Log level filtering**: `g_LogLevel` threshold (0=none, 1=error, 2=warn, 3=info); messages above threshold are silently dropped
  - **UTC offset**: computed once at log init via `Date() - ConvertDate(Date(), #PB_Date_UTC)` (no `ImportC` needed), stored as `g_TZOffset` string (e.g. `"+0700"`)
  - `ApacheDate(ts.q)` — formats a PureBasic date as `[DD/Mon/YYYY:HH:MM:SS +HHMM]`
  - `EnsureLogInit()` — lazy mutex + TZ offset init; called by both `OpenLogFile()` and `OpenErrorLog()`
  - Single `g_LogMutex` covers both log file handles
  - `g_ServerPID.i` — reserved for F-3 PID file; appears in error log lines as `[pid 0]` until set
- `src/Types.pbi` — `ServerConfig` extended with F-1 fields: `ErrorLogFile`, `LogLevel`, `LogSizeMB`, `LogKeepCount`, `LogDaily`, `PidFile`
- `src/Config.pbi` — new CLI flags: `--error-log FILE`, `--log-level LEVEL`, `--log-size MB`, `--log-keep N`, `--no-log-daily`, `--pid-file FILE`; `ParseLogLevel()` helper; F-1 defaults in `LoadDefaults()`

**Changed**
- `src/main.pb` — include order: Logger.pbi moved before FileServer.pbi so `ServeFile()` can call `LogError()` directly; `g_LogLevel` applied from config; error log opened/closed; `HandleRequest()` uses full 8-argument `LogAccess()` with IP, method, path, protocol, status, bytes, referer, user-agent; usage string updated for new flags
- `src/FileServer.pbi` — `ServeFile()` gains optional output params `*bytesOut = 0, *statusOut = 0`; `LogError()` called at all error points (403 hidden, 403 directory, 404, 500 OOM, 500 file open); status and byte count written via `PokeI()` at each response path
- `tests/TestCommon.pbi` — Logger.pbi moved before FileServer.pbi to match main.pb include order
- `tests/test_logger.pb` — rewritten: 7 → 15 tests covering CLF format, zero-bytes-as-dash, OpenErrorLog lifecycle, LogError writes, log level filtering (below threshold written, above threshold skipped), ApacheDate format

**Tests**
- 78 unit tests across 11 files; all pass

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
