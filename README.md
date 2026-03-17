# PureSimpleHTTPServer

A fast, single-binary HTTP/1.1 static file server with middleware architecture, HTTPS, and dynamic gzip compression — written in PureBasic.

**Reference model:** Caddy `file-server`

## Quick Start

```bash
# 1. Build
pbcompiler -cl -t -o PureSimpleHTTPServer src/main.pb

# 2. Run
./PureSimpleHTTPServer --root ./wwwroot --port 8080

# 3. Verify
curl -I http://localhost:8080/
```

## Features

**Serving**
- HTTP/1.1 static file serving with `Content-Type`, `ETag`, `Last-Modified`
- `304 Not Modified` via `If-None-Match`
- `206 Partial Content` via `Range` header
- Directory listing (opt-in via `--browse`)
- SPA fallback (opt-in via `--spa`)
- Hidden path blocking (`.git`, `.env`, `.DS_Store` by default)
- Embedded asset serving via `IncludeBinary` + `CatchPack` (opt-in at build time)
- Thread-per-connection for concurrent request handling

**Middleware Architecture (v2.0.0+)**
- 11-stage ordered middleware chain (Rewrite → IndexFile → CleanUrls → SpaFallback → HiddenPath → ETag304 → GzipSidecar → GzipCompress → EmbeddedAssets → FileServer → DirectoryListing)
- Post-processing middleware pattern (GzipCompress wraps downstream)
- ResponseWriter abstraction for pluggable body output

**TLS / HTTPS (v2.1.0+)**
- Manual certificate support (`--tls-cert`, `--tls-key`)
- Automatic HTTPS via acme.sh (`--auto-tls DOMAIN`)
- Background certificate renewal (12-hour check interval)
- HTTP→HTTPS redirect with ACME challenge serving on port 80

**Compression (v2.3.0+)**
- Dynamic gzip compression for text, JSON, JS, XML, SVG responses
- Pre-compressed `.gz` sidecar support (`Content-Encoding: gzip`)
- Disable with `--no-gzip`

**URL Processing**
- URL rewriting and redirecting via `rewrite.conf` (exact, glob, regex patterns)
- Per-directory rewrite rules (auto-reloaded on change)
- Clean URLs (`--clean-urls`: `/page` → `/page.html`)

**Logging**
- Access log in Apache Combined Log Format (CLF)
- Error log with level filtering (`none`/`error`/`warn`/`info`)
- Size-based and daily log rotation
- SIGHUP log reopen for logrotate integration

**Windows**
- Native Windows Service support with Event Log integration
- Professional NSIS installer with service installation
- Portable ZIP package

## CLI Flags

**Server:**

| Flag | Default | Description |
|------|---------|-------------|
| `--port N` | `8080` | Listening port |
| `--root DIR` | `wwwroot/` next to binary | Document root directory |
| `--browse` | off | Enable directory listing |
| `--spa` | off | SPA mode: serve `index.html` for all 404s |

**TLS:**

| Flag | Default | Description |
|------|---------|-------------|
| `--tls-cert FILE` | _(disabled)_ | Path to PEM certificate file |
| `--tls-key FILE` | _(disabled)_ | Path to PEM private key file |
| `--auto-tls DOMAIN` | _(disabled)_ | Enable automatic HTTPS via acme.sh for DOMAIN |

**Compression:**

| Flag | Default | Description |
|------|---------|-------------|
| `--no-gzip` | off | Disable dynamic gzip compression |

**Logging:**

| Flag | Default | Description |
|------|---------|-------------|
| `--log FILE` | _(disabled)_ | Write access log (Apache Combined Log Format) |
| `--error-log FILE` | _(disabled)_ | Write error log |
| `--log-level LEVEL` | `warn` | Error log threshold: `none`, `error`, `warn`, `info` |
| `--log-size MB` | `100` | Rotate log when it exceeds MB (0 = disabled) |
| `--log-keep N` | `30` | Max rotated archive files to keep |
| `--no-log-daily` | off | Disable daily midnight log rotation |
| `--pid-file FILE` | _(disabled)_ | Write process ID to FILE at startup |

**URL:**

| Flag | Default | Description |
|------|---------|-------------|
| `--clean-urls` | off | Serve `/page.html` when `/page` is requested |
| `--rewrite FILE` | _(disabled)_ | Load URL rewrite/redirect rules from FILE |

**Windows Service (Windows only):**

| Flag | Description |
|------|-------------|
| `--install` | Install as Windows service (requires Administrator) |
| `--uninstall` | Uninstall Windows service |
| `--start` | Start Windows service |
| `--stop` | Stop Windows service |
| `--service` | Run as Windows service (called by SCM) |
| `--service-name NAME` | Custom service name (default: "PureSimpleHTTPServer") |

## Deployment Modes

| Mode | When to use |
|------|------------|
| Standalone | Development, low-traffic sites |
| HTTPS Direct | Single-server production with TLS |
| Reverse Proxy | Production behind Caddy/nginx (recommended) |

See [docs/deployment.md](docs/deployment.md) for configuration details, capacity estimates, and multi-instance management.

## Testing

```bash
cd tests
./run_tests.sh
```

124 unit tests across 13 test files. All tests pass.

## Architecture

Every HTTP request flows through an ordered middleware chain:

```
Client → TCP → RunRequest() → [chain] → send → free → log

Chain:  Rewrite → IndexFile → CleanUrls → SpaFallback → HiddenPath
        → ETag304 → GzipSidecar → GzipCompress → EmbeddedAssets
        → FileServer → DirectoryListing
```

See [docs/developer-guide.md](docs/developer-guide.md) for the full middleware architecture documentation.

## Documentation

**User Guides** (`docs/user/`)
- [Quick Start](docs/user/QUICKSTART.md) — Get running in 2 minutes
- [CLI Reference](docs/user/CLI_REFERENCE.md) — Every flag with examples
- [Scenarios](docs/user/SCENARIOS.md) — Real-world deployment recipes
- [URL Rewriting](docs/user/URL_REWRITING.md) — Rewrite rule syntax and examples
- [Logging](docs/user/LOGGING.md) — Access/error logs, rotation, logrotate
- [Troubleshooting](docs/user/TROUBLESHOOTING.md) — Common problems and fixes

**Developer Guides** (`docs/developer/`)
- [Architecture](docs/developer/ARCHITECTURE.md) — Module map, request lifecycle, threading
- [Extending](docs/developer/EXTENDING.md) — Add flags, middleware, MIME types
- [Module Reference](docs/developer/MODULE_REFERENCE.md) — Full API for every module
- [Build Tutorial](docs/developer/BUILD_OUR_HTTP_SERVER.md) — Build a server from scratch
- [Building](docs/developer/BUILDING.md) — Compile from source
- [Testing](docs/developer/TESTING.md) — PureUnit framework and test patterns

**Deployment & Operations**
- [Deployment Guide](docs/deployment.md) — Standalone, HTTPS, reverse proxy modes
- [Developer Guide](docs/developer-guide.md) — Middleware architecture deep dive
- [Windows Deployment](docs/WINDOWS_DEPLOYMENT.md) — Installer, service, portable

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

```bash
build.bat          # Build executable
package.bat        # Create installer and portable package
verify_build.bat   # Verify build
```

Requirements: PureBasic 6.x compiler, NSIS (for installer creation)

## Build

Requires PureBasic 6.x. Compile as a **console** application with thread-safe mode:

```bash
pbcompiler -cl -t -o PureSimpleHTTPServer src/main.pb
```

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
