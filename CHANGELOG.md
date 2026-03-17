# Changelog

All notable changes to PureSimpleHTTPServer are documented here.

Format: `## vX.Y.Z — YYYY-MM-DD HH:MM`

---

## v2.5.0 — 2026-03-18

### Custom Error Pages, Basic Auth, and Cache-Control

**Added**
- `FillErrorResponse()` helper — serves custom HTML error pages from `--error-pages DIR` with plain-text fallback
- `Middleware_BasicAuth` — HTTP Basic Authentication middleware (short-circuit after Cors, before SecurityHeaders)
- `#HTTP_401 = 401` status code in `Global.pbi`; `Case 401 : "Unauthorized"` in `StatusText()`
- 4 new `ServerConfig` fields: `ErrorPagesDir.s`, `BasicAuthUser.s`, `BasicAuthPass.s`, `CacheMaxAge.i`
- 3 new CLI flags: `--error-pages DIR`, `--basic-auth USER:PASS`, `--cache-max-age N`

**Changed**
- 7 error response call sites in Middleware.pbi now use `FillErrorResponse()` instead of `FillTextResponse()`
- 4 hardcoded `max-age=0` values replaced with configurable `max-age=` + `Str(*cfg\CacheMaxAge)`
- `RunRequest()` 404 fallback now uses `FillErrorResponse()` and unified PlainWriter path
- `BuildChain()` registers 15 middleware (was 14): BasicAuth at slot 8
- Version bumped to `"2.5.0"`
- 148 unit tests across 13 test files; all pass (was 136)

**Tests**
- 12 new tests in `test_middleware.pb`:
  - Custom error pages: custom 404 served, custom 403 via HiddenPath, fallback when file missing, disabled uses plain text
  - Basic auth: disabled passes through, no header → 401, wrong creds → 401, correct creds pass through, password with colon works
  - Cache-control: default max-age=0, custom 3600 in ETag304, FileServer uses configured value

---

## v2.4.0 — 2026-03-17

### Health Check, CORS, and Security Headers Middleware

**Added**
- `Middleware_HealthCheck` — short-circuits requests matching `--health PATH` with `200 {"status":"ok"}` for load balancer probes (Caddy, nginx, AWS ALB, Kubernetes)
- `Middleware_Cors` — hybrid middleware: OPTIONS preflight returns 204 with CORS headers; GET responses get `Access-Control-Allow-Origin` appended (post-processing)
- `Middleware_SecurityHeaders` — post-processing middleware appending `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `X-XSS-Protection: 1; mode=block`, `Referrer-Policy: strict-origin-when-cross-origin`, `Cross-Origin-Opener-Policy: same-origin`
- `#HTTP_204 = 204` status code in `Global.pbi`; `Case 204 : "No Content"` in `StatusText()`
- 4 new `ServerConfig` fields: `HealthPath.s`, `CorsEnabled.i`, `CorsOrigin.s`, `SecurityHeaders.i`
- 4 new CLI flags: `--health PATH`, `--cors`, `--cors-origin ORIGIN`, `--security-headers`
- `RunRequest()` method guard now allows `OPTIONS` method (for CORS preflight)

**Changed**
- `BuildChain()` registers 14 middleware (was 11): HealthCheck at slot 2, Cors at slot 7, SecurityHeaders at slot 8
- Version bumped to `"2.4.0"`
- 136 unit tests across 13 test files; all pass (was 124)

**Tests**
- 12 new tests in `test_middleware.pb`:
  - Health check: match returns 200 JSON, non-match passes through, disabled passes through, custom path works
  - CORS: OPTIONS returns 204 with wildcard, OPTIONS with specific origin, GET gets CORS headers, disabled OPTIONS passes through, disabled GET has no headers
  - Security headers: enabled adds all 5 headers, disabled adds none, enabled + not-handled adds none

---

## v2.3.1 — 2026-03-17

### Phase 7 — Production Deployment Configs

**Added**
- `deploy/Caddyfile` — Reverse proxy configuration for 4 backend instances with health checks
- `deploy/launch.sh` — Multi-instance launcher script (start/stop/status)
- `deploy/pshs@.service` — systemd template unit for multi-instance management
- `docs/deployment.md` — Comprehensive deployment guide covering standalone, HTTPS direct, and reverse proxy modes
- Capacity estimates table for 1-8 instances

**Documentation**
- `docs/deployment.md` (new) — Three deployment modes with decision table and capacity estimates

---

## v2.3.0 — 2026-03-17

### Phase 6 — ResponseWriter Abstraction and Dynamic Gzip Compression

**Added**
- `ResponseWriter` vtable-based abstraction in `Types.pbi` — decouples byte production from byte destination
- `PlainWriter` implementation — sends bytes directly to TCP socket via `SendNetworkData`
- `Middleware_GzipCompress` — post-processing middleware that compresses response bodies dynamically
- `GzipCompressBuffer()` — converts PureBasic `CompressMemory()` (zlib) to valid gzip format
- `IsCompressibleType()` — checks MIME type for text, JSON, JS, XML, SVG
- `--no-gzip` CLI flag to disable dynamic compression
- `NoGzip` field in `ServerConfig`
- Runtime dependencies: `UseZipPacker()`, `UseCRC32Fingerprint()`

**Changed**
- `RunRequest()` now uses `PlainWriter` for all body output instead of direct `SendNetworkData`
- `BuildChain()` registers `Middleware_GzipCompress` between GzipSidecar and EmbeddedAssets (position 8)
- Middleware chain is now 11 middleware (was 10)

**Documentation**
- `docs/developer-guide.md` — Added ResponseWriter and dynamic gzip sections

---

## v2.2.0 — 2026-03-17

### Phase 5 — Automatic HTTPS via acme.sh Integration

**Added**
- `src/AutoTLS.pbi` (new) — Certificate management via acme.sh:
  - `IssueCertificate(domain, webroot)` — HTTP-01 webroot challenge
  - `RenewCertificate(domain)` — Certificate renewal
  - `CertRenewalLoop()` — Background thread checking every 12 hours
  - `HttpRedirectLoop()` — Port 80 listener serving ACME challenges + HTTPS redirect
  - `StartHttpRedirect()` / `StopHttpRedirect()` — Manage port 80 redirect server
  - `StartCertRenewal()` / `StopCertRenewal()` — Manage renewal thread
- `--auto-tls DOMAIN` CLI flag
- `AutoTlsDomain` field in `ServerConfig`
- Default port changes to 443 when `--auto-tls` is active

**Changed**
- `main.pb` — TLS mode priority: auto-tls > manual tls > plain http
- `TcpServer.pbi` — Added `RestartServer()` for certificate reload without downtime

**Documentation**
- `docs/developer-guide.md` — Added Auto-TLS architecture section

---

## v2.1.0 — 2026-03-16

### Phase 4 — HTTPS with Manual Certificates

**Added**
- Manual TLS support via `--tls-cert FILE` and `--tls-key FILE` CLI flags
- `ReadPEMFile()` in `Config.pbi` — reads PEM certificate/key content
- `TlsCert`, `TlsKey` fields in `ServerConfig`
- `g_TlsEnabled`, `g_TlsKey`, `g_TlsCert` globals in `TcpServer.pbi`
- `CreateServerWithTLS(port)` — creates TLS-enabled network server using `#PB_Network_TLSv1`

**Changed**
- `TcpServer.pbi` — `StartServer()` now calls `CreateServerWithTLS()` when TLS globals are set
- `main.pb` — TLS setup section between log init and startup banner
- Startup banner shows `https://` scheme and certificate paths when TLS is enabled

---

## v2.0.0 — 2026-03-16

### Phase 3 — Middleware Cleanup, Isolation Tests, Developer Guide

**Added**
- `tests/test_middleware.pb` (new) — 16 middleware isolation tests covering all 10 middleware
- `docs/developer-guide.md` (new) — Middleware architecture developer guide with chain diagram, memory rules, testing patterns, and extension tutorial

**Changed**
- Removed `Middleware_HandleAll` — all request handling now goes through the 10 individual middleware
- Removed unused `HttpResponse` structure from `Types.pbi` (replaced by `ResponseBuffer`)
- 124 unit tests across 13 test files; all pass

---

## v2.0.0-alpha.2 — 2026-03-16

### Phases 1b-1k — Extract All 10 Middleware from HandleAll

**Changed**
- Extracted `Middleware_Rewrite` from HandleAll (URL rewriting/redirects)
- Extracted `Middleware_IndexFile` from HandleAll (directory → index resolution)
- Extracted `Middleware_CleanUrls` from HandleAll (extensionless → .html)
- Extracted `Middleware_SpaFallback` from HandleAll (404 → index.html for SPAs)
- Extracted `Middleware_HiddenPath` from HandleAll (access control)
- Extracted `Middleware_ETag304` from HandleAll (conditional responses)
- Extracted `Middleware_GzipSidecar` from HandleAll (pre-compressed .gz files)
- Extracted `Middleware_EmbeddedAssets` from HandleAll (in-memory assets)
- Extracted `Middleware_FileServer` from HandleAll (disk files + range requests)
- Extracted `Middleware_DirectoryListing` from HandleAll (HTML directory browser)
- `HandleAll` reduced to empty passthrough, then removed entirely

---

## v2.0.0-alpha.1 — 2026-03-16

### Phase 1a — Middleware Chain Foundation

**Added**
- `ResponseBuffer` structure in `Types.pbi` — StatusCode, Headers, *Body, BodySize, Handled
- `MiddlewareContext` structure in `Types.pbi` — ChainIndex, Connection, *Config, BytesSent
- `src/Middleware.pbi` (new) — Chain infrastructure:
  - `RegisterMiddleware()` — add a middleware to the chain during startup
  - `CallNext()` — advance to the next middleware
  - `RunRequest()` — chain runner with single-point network I/O and memory cleanup
  - `BuildChain()` — register all middleware in directive order
- `FillTextResponse()` in `HttpResponse.pbi` — fill a ResponseBuffer with UTF-8 text
- `BuildFsPath()` in `Middleware.pbi` — filesystem path builder for middleware
- `RunRequestWrapper()` in `main.pb` — bridges g_Handler to RunRequest with g_Config

**Changed**
- `main.pb` — replaced `g_Handler = @HandleRequest()` with `BuildChain()` + `g_Handler = @RunRequestWrapper()`
- Request flow: `ConnectionThread → g_Handler → RunRequestWrapper → RunRequest → middleware chain`

---

## v1.6.1 — 2026-03-15 15:30

### Bug Fixes — wwwroot Navigation and Rewrite Rules

**Fixed**
- **wwwroot gitlink issue** — Converted wwwroot from git submodule (gitlink) to regular tracked directory
- **wwwroot/index.html navigation** — Enhanced and fixed navigation links
- **Blog rewrite rules** — Fixed critical index file serving issue with wildcard patterns

---

## v1.6.0 — 2026-03-15 14:00

### Phase A & C — Windows Build & Packaging, Windows Service Integration

**Added**
- **Phase A: Build & Packaging** — Professional Windows deployment:
  - `installer/PureSimpleHTTPServer.nsi` (new) — NSIS installer script:
    - GUI installer with license agreement, component selection
    - Installation directory selection (default: %ProgramFiles%\PureSimpleHTTPServer)
    - Optional Windows Service installation (requires admin)
    - Start Menu shortcuts creation
    - Optional Desktop shortcut
    - Automatic uninstaller with user data preservation
    - Silent installation support (/S flag)
    - Add/Remove Programs entry
  - `build.bat` (new) — Automated build script:
    - PureBasic compilation with console mode, thread-safe, optimizer
    - Icon embedding support
    - Color-coded output and error handling
    - Executable testing after build
  - `package.bat` (new) — Automated packaging script:
    - Creates portable ZIP package
    - Builds NSIS installer
    - Converts documentation to Windows-friendly text format
    - Generates `quickstart.txt` user guide
  - `verify_build.bat` (new) — Build verification script
  - `assets/icon.svg` (new) — Application icon (vector source)
  - Windows documentation:
    - `README.txt` — Windows-friendly user guide (plain text)
    - `LICENSE.txt` — License file
    - `CHANGELOG.txt` — Version history (plain text)
    - `quickstart.txt` — Comprehensive quick start guide
  - `tests/WINDOWS_INSTALLER_TEST_CHECKLIST.md` (new) — 24 installation tests
  - Portable package structure with Windows-friendly text files
  - Support for custom installation directories

- **Phase C: Windows Service Integration** — Native Windows Service support:
  - `src/WindowsService.pbi` (new) — Complete Windows Service API wrapper (400+ lines):
    - `InstallService()` — Install as Windows service
    - `UninstallService()` — Remove Windows service
    - `RunAsService()` — Connect to Service Control Manager
    - `ServiceMain()` — Service entry point
    - `ServiceCtrlHandler()` — Handle service control requests (STOP, SHUTDOWN)
    - `LogToEventLog()` — Write to Windows Event Log
    - Service status reporting (START_PENDING, RUNNING, STOP_PENDING, STOPPED)
    - Platform stubs for non-Windows (cross-platform compatibility)
  - Service management CLI flags:
    - `--install` — Install service (requires admin)
    - `--uninstall` — Remove service (requires admin)
    - `--start` — Start service via sc.exe
    - `--stop` — Stop service via sc.exe
    - `--service` — Run as Windows service (called by SCM)
    - `--service-name NAME` — Custom service name
  - `src/Types.pbi` — Added service configuration fields:
    - `ServiceMode.i` — Run as Windows service flag
    - `ServiceName.s` — Service name (default: "PureSimpleHTTPServer")
  - `src/Config.pbi` — Service CLI flag parsing
  - `src/main.pb` — Service integration:
    - Service command handling (--install, --uninstall, --start, --stop)
    - Service mode detection and execution
    - Helper functions: `ArgContains()`, `GetFullExePath()`
  - Windows Event Log integration:
    - Event source: "PureSimpleHTTPServer"
    - Event IDs: 1=Started, 2=Failed, 3=SCM Error, 4=Stopped
    - Event types: ERROR, WARNING, INFORMATION
  - Service lifecycle management:
    - Graceful shutdown on STOP/SHUTDOWN
    - Server startup/shutdown logged to Event Log
    - Service Control Manager integration
  - `tests/WINDOWS_SERVICE_TEST_CHECKLIST.md` (new) — 24 service tests
  - 100% backward compatible with standalone mode

**Changed**
- `src/main.pb` — Added WindowsService.pbi include and service integration
- `src/Types.pbi` — Added ServiceMode and ServiceName fields to ServerConfig structure
- `src/Config.pbi` — Added --service and --service-name CLI flag parsing

**Documentation**
- `PHASE_A_COMPLETION.md` (new) — Phase A implementation report
- `PHASE_C_COMPLETION.md` (new) — Phase C implementation report
- `WINDOWS_OPTIMIZATION_FINAL_REPORT.md` (new) — Comprehensive completion report
- `NEXT_PHASES.md` — Updated to reflect completion status
- Updated README.md with Windows deployment and service information

**Features**
- Professional Windows installer with all standard features
- Portable ZIP distribution (no installation required)
- Native Windows Service support with full lifecycle management
- Windows Event Log integration for service events
- Automated build and packaging scripts
- Windows-friendly documentation (plain text format)
- Comprehensive testing coverage (48 tests: 24 installation + 24 service)
- 100% backward compatible with existing functionality
- Cross-platform compatibility maintained (platform-specific code properly guarded)

**Testing**
- Phase A: 24 comprehensive installation tests
- Phase C: 24 comprehensive service tests
- All existing 108 unit tests continue to pass
- Backward compatibility verified

**Platform Support**
- Windows: Full installer + service support
- macOS/Linux: Unchanged (all Windows code properly stubbed)

**Usage Examples**
```bash
# Install as Windows Service (Windows only, requires admin)
PureSimpleHTTPServer.exe --install
net start PureSimpleHTTPServer

# Run standalone (all platforms)
PureSimpleHTTPServer.exe --port 3000 --root C:\MyWebsite

# Build Windows packages (Windows only)
build.bat       # Compile executable
package.bat     # Create installer + portable ZIP
```

---

## v1.6.1 — 2026-03-15 15:30

### Bug Fixes — wwwroot Navigation and Rewrite Rules

**Fixed**
- **wwwroot gitlink issue** — Converted wwwroot from git submodule (gitlink) to regular tracked directory:
  - Removed git submodule reference (mode 160000)
  - Added all wwwroot content as regular files
  - Prevents future issues with submodule synchronization
- **wwwroot/index.html navigation** — Enhanced and fixed navigation links:
  - Added navigation cards for all subdirectories: About, API, Blog, Documentation
  - Fixed /blog/ link to work properly with rewrite rules
  - Removed non-functional /assets/ and /figma-plugin/ links
- **Blog rewrite rules** — Fixed critical index file serving issue:
  - Problem: `/blog/*` wildcard pattern caught directory requests, preventing index.html from loading
  - Solution: Added explicit index rules BEFORE catch-all wildcard in `wwwroot/blog/rewrite.conf`
  - Pattern: `rewrite /blog/ /blog/index.html` then `rewrite /blog/* /blog/posts/{path}.html`
  - Rules evaluated in order; first match wins

**Changed**
- `wwwroot/index.html` — Removed broken links, fixed /blog/ navigation
- `wwwroot/blog/rewrite.conf` — Added explicit index file handling with warning comments
- `wwwroot/rewrite.conf` — Added educational warning comments about wildcard patterns

**Documentation**
- `docs/URL_REWRITE.md` — Added **"⚠️ CRITICAL: Rewrite Rules and Index Files"** section:
  - Explains request processing pipeline (rewrites → index lookup → clean URLs → SPA fallback)
  - Documents common pitfall with wildcard patterns catching directories
  - Provides best practices for rewrite rule ordering
  - Includes real-world examples and comparison table
  - Shows wrong vs correct pattern configurations
- `wwwroot/rewrite.conf` — Added warning comments and educational examples
- `wwwroot/blog/rewrite.conf` — Added critical warning with reference to documentation

**Impact**
- `/blog/` now serves index.html correctly instead of returning 404
- Blog posts still rewrite properly (`/blog/hello-world` → `posts/hello-world.html`)
- All wwwroot content now tracked as regular git files (not submodule)
- Users can reference documentation to avoid similar issues with their own rewrite rules

**Technical Details**
The issue occurred because rewrite rules are evaluated **before** the server checks for index files. The wildcard pattern `/blog/*` matched the directory request `/blog/` with an empty capture, rewriting it to `/blog/posts/.html` which doesn't exist, causing a 404. The fix adds explicit rules that match `/blog/` and `/blog/index.html` before the wildcard, ensuring the index file is served.

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
