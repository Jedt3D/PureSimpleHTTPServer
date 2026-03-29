# CLAUDE.md — Development Guidelines for PureSimpleHTTPServer

## Project Overview

PureSimpleHTTPServer is a cross-platform, single-binary HTTP/1.1 static file server written
entirely in **PureBasic 6.x**. It targets **Windows, macOS, and Linux** equally. The architecture
is a 15-stage middleware chain with thread-per-connection dispatch, HTTPS support, and a native
Windows Service mode.

- **Version:** Defined in `src/Global.pbi` as `#APP_VERSION`. Must stay in sync with
  `build.bat`, `package.bat`, and `verify_build.bat` (the `VERSION=` variable in each).
- **Reference model:** Caddy's `file-server` — simple, secure, zero-config defaults.

## Build

```bash
# macOS / Linux
pbcompiler -cl -t -o PureSimpleHTTPServer src/main.pb

# Windows (via build.bat, or manually):
pbcompiler.exe /CONSOLE /THREAD /OPTIMIZER /OUTPUT dist\PureSimpleHTTPServer.exe src\main.pb
```

Required compiler flags:
- `-cl` / `/CONSOLE` — console application (not GUI)
- `-t` / `/THREAD` — thread-safe mode (required for networking and thread-per-connection model)

## Test

Tests use the **PureUnit** framework. Each test file is in `tests/test_*.pb` and includes
`tests/TestCommon.pbi` for shared setup.

```bash
cd tests
./run_tests.sh          # run all tests
./run_tests.sh --report # generate HTML report at docs/test_report.html
```

148 unit tests across 14 test files. Assertions use `Assert(condition, message.s)`.

---

## Cross-Platform Development Rules

**Every code change must compile and work correctly on Windows, macOS, and Linux.**

### 1. Path Separator: `#SEP`

`#SEP` is a compile-time constant in `src/Global.pbi` — `"\"` on Windows, `"/"` elsewhere.
Zero runtime cost (inlined by compiler). Follows PureBasic idiom alongside `#CRLF$`, `#LF$`, `#TAB$`.

**Rule: Use `#SEP` for all filesystem path concatenation:**

```purebasic
; CORRECT — filesystem path
fsPath = directory + #SEP + filename
configPath = GetHomeDirectory() + ".config" + #SEP + "settings.ini"

; CORRECT — URL path (HTTP protocol, always forward slash)
redirectUrl = "https://" + domain + "/" + path
contentRange = "bytes " + Str(start) + "-" + Str(end) + "/" + Str(total)

; WRONG — hardcoded "/" for filesystem path
fsPath = directory + "/" + filename
```

**When to use `BuildFsPath()` instead of `#SEP`:**
Use `BuildFsPath(docRoot, urlPath)` from `Middleware.pbi` when converting a URL path
(which contains embedded `/`) to a filesystem path. It strips trailing separators and
does bulk `ReplaceString("/", "\")` on Windows. Use `#SEP` for everything else.

### 2. Platform-Conditional Code: `CompilerIf`

PureBasic's `CompilerIf` excludes code at compile time (zero runtime cost):

```purebasic
CompilerIf #PB_Compiler_OS = #PB_OS_Windows
  ; Windows-only code
CompilerElseIf #PB_Compiler_OS = #PB_OS_MacOS
  ; macOS-only code
CompilerElse
  ; Linux / other
CompilerEndIf
```

**Rule: Always provide stubs for other platforms** so the code compiles everywhere.
See `SignalHandler.pbi` and `WindowsService.pbi` for examples of the stub pattern.

### 3. Existing Platform Splits

| Feature | Windows | macOS / Linux | File |
|---------|---------|---------------|------|
| Process ID | `GetCurrentProcessId()` (kernel32) | `getpid()` (libc) | `main.pb` |
| Signal handling | No-op stubs | SIGHUP for logrotate | `SignalHandler.pbi` |
| Windows Service | Full SCM integration | Stub returns `#False` | `WindowsService.pbi` |
| Path conversion | `ReplaceString("/", "\")` | Pass-through | `Middleware.pbi` `BuildFsPath()` |
| Auto-TLS | Blocked with error message | acme.sh integration | `main.pb`, `AutoTLS.pbi` |

### 4. Things That Are Already Cross-Platform (Don't Reinvent)

PureBasic abstracts these — use the built-in APIs, not OS-specific calls:
- **Networking:** `CreateNetworkServer()`, `SendNetworkData()`, `ReceiveNetworkData()`
- **Threading:** `CreateThread()`, `CreateMutex()`, `LockMutex()`, `WaitThread()`
- **File I/O:** `ReadFile()`, `CreateFile()`, `FileSize()`, `CreateDirectory()`
- **Date/Time:** `Date()`, `FormatDate()` (UTC-based)
- **Home directory:** `GetHomeDirectory()` (returns native path with trailing separator)
- **Executable path:** `ProgramFilename()`, `GetPathPart()`

### 5. Auto-TLS Limitation

`AutoTLS.pbi` depends on `acme.sh` (a bash script) — unavailable on Windows.
`main.pb` blocks `--auto-tls` on Windows with a `CompilerIf` guard directing users to
`--tls-cert`/`--tls-key` instead. If adding alternative ACME clients for Windows in
the future, update this guard.

---

## Architecture Quick Reference

### Module Map (inclusion order in main.pb)

```
main.pb
 +-- Global.pbi           Constants, #SEP, HTTP status codes, buffer sizes
 +-- Types.pbi            HttpRequest, ResponseBuffer, MiddlewareContext, ServerConfig
 +-- DateHelper.pbi       RFC 7231 date formatting
 +-- UrlHelper.pbi        URL decoding, path normalization
 +-- HttpParser.pbi       Parse raw HTTP into HttpRequest
 +-- HttpResponse.pbi     Build response headers, send text responses
 +-- TcpServer.pbi        TCP server, TLS, event loop, thread dispatch
 +-- MimeTypes.pbi        File extension -> MIME type lookup
 +-- Logger.pbi           Access log (CLF), error log, rotation, daily thread
 +-- FileServer.pbi       Static file serving, ETag, index resolution
 +-- DirectoryListing.pbi HTML directory index generation
 +-- RangeParser.pbi      HTTP Range header parsing, 206 responses
 +-- EmbeddedAssets.pbi   In-memory asset serving via IncludeBinary
 +-- Config.pbi           CLI argument parsing, defaults, PEM file reading
 +-- RewriteEngine.pbi    URL rewriting (exact/glob/regex patterns)
 +-- Middleware.pbi        Chain infrastructure + all 15 middleware handlers
 +-- AutoTLS.pbi          acme.sh certificate management, HTTP redirect server
 +-- SignalHandler.pbi    SIGHUP handler (POSIX), no-op stubs (Windows)
 +-- WindowsService.pbi   Windows Service SCM integration, Event Log, stubs
```

### Middleware Chain (15 stages)

```
Client -> TCP -> RunRequest() -> [chain] -> send -> free -> log

 #   Middleware              Pattern
 1   Rewrite                 Request modifier (URL rewrite from rewrite.conf)
 2   HealthCheck             Short-circuit (load balancer probes)
 3   IndexFile               Request modifier (/dir/ -> /dir/index.html)
 4   CleanUrls               Request modifier (/about -> /about.html)
 5   SpaFallback             Request modifier (SPA 404 -> index.html)
 6   HiddenPath              Access control (block .git, .env, .DS_Store)
 7   Cors                    Hybrid (OPTIONS preflight + CORS headers)
 8   BasicAuth               Short-circuit (HTTP Basic Authentication)
 9   SecurityHeaders         Post-processing (X-Content-Type-Options, etc.)
10   ETag304                 Conditional (304 Not Modified)
11   GzipSidecar             Response sidecar (serve pre-compressed .gz)
12   GzipCompress            Post-processing (dynamic gzip compression)
13   EmbeddedAssets          Terminal handler (in-memory pack)
14   FileServer              Terminal handler (disk file serving)
15   DirectoryListing        Terminal handler (HTML directory index)
```

### Middleware Patterns

- **Pre-process:** Modify `*req\Path`, then `CallNext()`.
- **Short-circuit:** Fill `*resp` and return `#True` without `CallNext()`.
- **Post-process:** `CallNext()` first, then modify `*resp`.
- **Terminal:** Fill `*resp` from disk/memory, return `#True`.

### Memory Rules

1. The chain runner (`RunRequest`) owns `resp\Body` and always frees it after sending.
2. A middleware that replaces `resp\Body` must free the old one first.
3. A middleware that short-circuits must set `resp\Body` or leave it 0.
4. Middleware **never** call `SendNetwork*` directly — single point of I/O is `RunRequest`.

### Connection Model

- **Main thread:** Event loop, data accumulation, dispatch to worker threads
- **Worker threads:** One per complete HTTP request (`CreateThread`)
- **Close queue:** Workers push connection IDs to `g_CloseList` (mutex-protected);
  main thread drains queue each iteration (only main thread closes connections)

---

## Adding New Features Checklist

1. **New CLI flag:** Add field to `ServerConfig` in `Types.pbi`, default in `Config.pbi`
   `LoadDefaults()`, parse in `ParseCLI()`. See `docs/developer/EXTENDING.md`.
2. **New middleware:** Create handler matching `MiddlewareHandler` prototype, register in
   `BuildChain()` at the correct position. Never call `SendNetwork*` directly.
3. **New MIME type:** Add to the `Select LCase(ext)` block in `MimeTypes.pbi`.
4. **Platform-specific feature:** Use `CompilerIf`, provide stubs, use `#SEP` for paths.
5. **Version bump:** Update `#APP_VERSION` in `Global.pbi` AND `VERSION=` in all `.bat` files.

## File Conventions

| Pattern | Purpose |
|---------|---------|
| `src/*.pb` | Main source (entry point: `main.pb`) |
| `src/*.pbi` | Include files (modules) |
| `tests/test_*.pb` | PureUnit test files |
| `tests/TestCommon.pbi` | Shared test setup |
| `*.bat` | Windows build/package/verify scripts |
| `installer/*.nsi` | NSIS installer script |
| `docs/user/` | End-user documentation |
| `docs/developer/` | Developer documentation |
| `.gitattributes` | Line endings: `.pb`/`.pbi` = LF, `.bat`/`.nsi` = CRLF |

## Key Documentation

- **Architecture:** `docs/developer/ARCHITECTURE.md`
- **Extending:** `docs/developer/EXTENDING.md`
- **Module API:** `docs/developer/MODULE_REFERENCE.md`
- **Building:** `docs/developer/BUILDING.md`
- **Testing:** `docs/developer/TESTING.md`
- **Windows deployment:** `docs/WINDOWS_DEPLOYMENT.md`
- **CLI reference:** `docs/user/CLI_REFERENCE.md`
