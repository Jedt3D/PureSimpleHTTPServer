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

## Testing

```bash
cd tests
./run_tests.sh
```

82 unit tests across 11 test files. All tests pass.

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
