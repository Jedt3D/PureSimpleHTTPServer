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
| E | v1.0.0 | Thread-per-connection, access log, full CLI | ✅ Done |

## Build

Requires PureBasic 6.x. Compile as a **console** application with thread-safe mode:

```bash
pbcompiler -cl -t -o PureSimpleHTTPServer src/main.pb
```

## Run

```bash
./PureSimpleHTTPServer [--port N] [--root DIR] [--browse] [--spa] [--log FILE]
# Default port: 8080, root: wwwroot/ next to the binary
# Legacy: ./PureSimpleHTTPServer [port]
```

| Flag | Description |
|------|-------------|
| `--port N` | Listening port (default: 8080) |
| `--root DIR` | Document root directory (default: current directory) |
| `--browse` | Enable directory listing |
| `--spa` | Serve `index.html` for all 404s (SPA mode) |
| `--log FILE` | Write access log to FILE |

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
- Access log with timestamp, IP, method, path, status, bytes

## Testing

```bash
cd tests
./run_tests.sh
```

70 unit tests across 11 test files. All tests pass.

See [docs/DEVELOPER_GUIDE.md](docs/DEVELOPER_GUIDE.md) for full developer documentation.
