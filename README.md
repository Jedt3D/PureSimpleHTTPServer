# PureSimpleHTTPServer

A simple, single-binary HTTP/1.1 static file server written in PureBasic.

**Reference model:** Caddy `file-server`
**Goal:** Self-contained executable that bundles and serves a compiled web application.

## Status

| Phase | Version | Feature | Status |
|-------|---------|---------|--------|
| A | v0.1.0 | TCP server + HTTP/1.1 parser + response builder | ✅ Done |
| B | v0.2.0 | Static file serving from disk | 🔲 Planned |
| C | v0.3.0 | Directory listing, SPA fallback, Range requests | 🔲 Planned |
| D | v0.4.0 | Embedded assets (IncludeBinary + CatchPack) | 🔲 Planned |
| E | v1.0.0 | Thread-per-connection, access log, graceful shutdown | 🔲 Planned |

## Build

Requires PureBasic 6.x. Compile as a **console** application:

```bash
pbcompiler -cl -o PureSimpleHTTPServer src/main.pb
```

## Run

```bash
./PureSimpleHTTPServer [port]
# Default port: 8080
```

## Testing

```bash
cd tests
./run_tests.sh
```

See [docs/DEVELOPER_GUIDE.md](docs/DEVELOPER_GUIDE.md) for full developer documentation.
