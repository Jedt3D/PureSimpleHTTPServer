# Usage Guide — PureSimpleHTTPServer

## Requirements

- PureBasic 6.x
- macOS, Windows, or Linux

## Build

Compile as a **console** application (required for `PrintN` output and proper signal handling):

```bash
pbcompiler -cl -o PureSimpleHTTPServer src/main.pb
```

With optimizer (release build):
```bash
pbcompiler -cl -z -o PureSimpleHTTPServer src/main.pb
```

## Run

```bash
# Default port 8080
./PureSimpleHTTPServer

# Custom port
./PureSimpleHTTPServer 3000
```

Server outputs:
```
PureSimpleHTTPServer v0.1.0
Listening on http://localhost:8080
Press Ctrl+C to stop
```

## Phase A Behavior (v0.1.0)

Phase A responds to any HTTP request with an informational HTML page showing:
- Request method, path, query string, HTTP version
- Current server time (RFC 7231 format)

This validates the full TCP → parse → respond → close cycle.

## Planned Features

| Feature | Phase | Version |
|---------|-------|---------|
| Static file serving from disk | B | v0.2.0 |
| Directory listing | C | v0.3.0 |
| SPA fallback mode | C | v0.3.0 |
| HTTP Range requests (video) | C | v0.3.0 |
| Embedded asset bundle | D | v0.4.0 |
| Multi-threaded connections | E | v1.0.0 |
| Access logging | E | v1.0.0 |
| Graceful shutdown | E | v1.0.0 |

## Configuration (Phase E)

In Phase E, configuration will be passed via command-line flags:

```
PureSimpleHTTPServer [options]

  --port    <n>      Listening port (default: 8080)
  --root    <dir>    Document root directory (default: current directory)
  --browse           Enable directory listing
  --spa              Enable SPA fallback (serve index.html for unknown paths)
  --log     <file>   Access log file path
  --hide    <pat>    Comma-separated hidden path patterns (e.g. ".git,.env")
  --index   <list>   Comma-separated index file names (default: index.html,index.htm)
```
