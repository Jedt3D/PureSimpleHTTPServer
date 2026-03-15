# PureSimpleHTTPServer

A simple, single-binary HTTP/1.1 static file server written in PureBasic.

**Reference model:** Caddy `file-server`
**Goal:** Self-contained executable that bundles and serves a compiled web application.

## Status

| Phase | Version | Feature | Status |
|-------|---------|---------|--------|
| A | v0.1.0 | TCP server + HTTP/1.1 parser + response builder | ✅ Done |
| B | v0.2.0 | Static file serving from disk | ✅ Done |
| C | v0.3.0 | Directory listing, SPA fallback, Range requests | ✅ Done |
| D | v0.4.0 | Embedded assets (IncludeBinary + CatchPack) | ✅ Done |
| E | v1.0.3 | Thread-per-connection, access log, full CLI | ✅ Done |
| F-1 | v1.1.0 | Apache Combined Log, error log, log level filtering | ✅ Done |
| F-2 | v1.2.0 | Size-based log rotation with archive naming + keep-count | ✅ Done |
| F-3 | v1.3.0 | Daily midnight UTC rotation thread + PID file | ✅ Done |
| F-4 | v1.4.0 | SIGHUP log reopen for logrotate integration | ✅ Done |
| G   | v1.5.0 | URL rewriting and redirecting (`rewrite.conf`, `--clean-urls`) | ✅ Done |
| A & C | v1.6.0 | **Windows Build & Packaging, Windows Service Integration** | ✅ Done |
| — | v1.6.1 | **Bug fixes: wwwroot navigation, rewrite rule index handling** | ✅ Done |

## Build

Requires PureBasic 6.x. Compile as a **console** application with thread-safe mode:

```bash
pbcompiler -cl -t -o PureSimpleHTTPServer src/main.pb
```

## Run

```bash
./PureSimpleHTTPServer [--port N] [--root DIR] [--browse] [--spa]
                       [--log FILE] [--error-log FILE] [--log-level LEVEL]
                       [--log-size MB] [--log-keep N] [--no-log-daily]
                       [--pid-file FILE]
                       [--clean-urls] [--rewrite FILE]
# Default port: 8080, root: wwwroot/ next to the binary
# Legacy: ./PureSimpleHTTPServer [port]
```

| Flag | Description |
|------|-------------|
| `--port N` | Listening port (default: 8080) |
| `--root DIR` | Document root directory (default: `wwwroot/` next to binary) |
| `--browse` | Enable directory listing |
| `--spa` | Serve `index.html` for all 404s (SPA mode) |
| `--log FILE` | Write access log (Apache Combined Log Format) to FILE |
| `--error-log FILE` | Write error log to FILE |
| `--log-level LEVEL` | Error log threshold: `none`, `error`, `warn` (default), `info` |
| `--log-size MB` | Rotate log when it exceeds MB (default: 100; 0 = disabled) |
| `--log-keep N` | Max rotated archive files to keep (default: 30) |
| `--no-log-daily` | Disable daily log rotation at midnight |
| `--pid-file FILE` | Write process ID to FILE at startup |
| `--clean-urls` | Serve `/page.html` when `/page` is requested |
| `--rewrite FILE` | Load URL rewrite/redirect rules from FILE (see `docs/URL_REWRITE.md`) |

**Windows Service flags (Windows only):**
| `--install` | Install as Windows service (requires Administrator) |
| `--uninstall` | Uninstall Windows service (requires Administrator) |
| `--start` | Start Windows service |
| `--stop` | Stop Windows service |
| `--service` | Run as Windows service (called by Service Control Manager) |
| `--service-name NAME` | Custom service name (default: "PureSimpleHTTPServer") |

## Windows Deployment

### Windows Installer

PureSimpleHTTPServer includes a professional Windows installer with:
- GUI installer with license agreement
- Optional Windows Service installation
- Start Menu & Desktop shortcuts
- Automatic uninstaller
- Silent installation support

Download `PureSimpleHTTPServer-{version}-windows-setup.exe` and run the installer.

### Portable Version

A portable ZIP package is available for Windows - no installation required:
- Download `PureSimpleHTTPServer-{version}-windows-portable.zip`
- Extract to any directory
- Run `PureSimpleHTTPServer.exe`

### Windows Service

Run PureSimpleHTTPServer as a native Windows service:

```bash
# Install service (requires Administrator)
PureSimpleHTTPServer.exe --install

# Start service
net start PureSimpleHTTPServer

# Stop service
net stop PureSimpleHTTPServer

# Uninstall service
PureSimpleHTTPServer.exe --uninstall
```

Service features:
- Automatic startup on boot (if configured)
- Runs in background without console window
- Integrated with Windows Event Log
- Graceful shutdown on system shutdown
- Full Service Control Manager integration

### Building on Windows

Automated build scripts are included for Windows:

```bash
# Build executable
build.bat

# Create installer and portable package
package.bat

# Verify build
verify_build.bat
```

Requirements:
- PureBasic 6.x compiler
- NSIS (for installer creation)

## Features

- HTTP/1.1 static file serving with `Content-Type`, `ETag`, `Last-Modified`
- `304 Not Modified` via `If-None-Match`
- `206 Partial Content` via `Range` header
- Directory listing (opt-in via `--browse`)
- SPA fallback (opt-in via `--spa`)
- Hidden path blocking (`.git`, `.env`, `.DS_Store` by default)
- Pre-compressed `.gz` sidecar support (`Content-Encoding: gzip`)
- Embedded asset serving via `IncludeBinary` + `CatchPack` (opt-in at build time)
- Thread-per-connection for concurrent request handling
- Access log in Apache Combined Log Format (CLF) with IP, method, path, status, bytes, Referer, User-Agent
- Error log with level filtering (`none`/`error`/`warn`/`info`)
- URL rewriting and redirecting via `rewrite.conf` (exact, glob, regex patterns; `{path}`, `{file}`, `{dir}`, `{re.N}` placeholders)
- Per-directory rewrite rules (`rewrite.conf` in any served directory, auto-reloaded on change)
- Clean URLs (`--clean-urls`: `/page` → `/page.html`)
- **Windows Service support** (Windows only) — Run as native Windows service with Event Log integration
- **Professional Windows installer** — GUI installer with service installation, shortcuts, and uninstaller
- **Portable Windows package** — No installation required

## Testing

```bash
cd tests
./run_tests.sh
```

108 unit tests across 12 test files. All tests pass.

## Load Testing

Verified with Apache Bench on macOS ARM64 (Apple M4 Pro):

```bash
ab -n 1000 -c 10 http://127.0.0.1:8080/
```

| Metric | Result |
|--------|--------|
| Requests | 1000 / 1000 (no failures) |
| Concurrency | 10 simultaneous connections |
| Mean response time | 2 ms |
| Transfer rate | ~38 MB/s |
| Crashes | None |

See [docs/DEVELOPER_GUIDE.md](docs/DEVELOPER_GUIDE.md) for full developer documentation.
