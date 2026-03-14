# Usage Guide — PureSimpleHTTPServer

## Requirements

- PureBasic 6.x
- macOS, Windows, or Linux

## Build

Compile as a **console** application. The `-t` flag enables thread-safe mode required for thread-per-connection handling:

```bash
pbcompiler -cl -t -o PureSimpleHTTPServer src/main.pb
```

With optimizer (release build):
```bash
pbcompiler -cl -t -z -o PureSimpleHTTPServer src/main.pb
```

## Run

```bash
# Defaults: port 8080, root = wwwroot/ next to the binary
./PureSimpleHTTPServer

# Named flags
./PureSimpleHTTPServer --port 3000 --root /var/www --browse --log /var/log/access.log

# Legacy: bare port number (backward compatible)
./PureSimpleHTTPServer 3000
```

Server outputs:
```
PureSimpleHTTPServer v1.0.0
Serving:    /usr/local/bin/wwwroot
Listening:  http://localhost:8080
Press Ctrl+C to stop
```

## Command-Line Flags

| Flag | Default | Description |
|------|---------|-------------|
| `--port N` | `8080` | TCP port to listen on |
| `--root DIR` | `wwwroot/` next to binary | Document root directory |
| `--browse` | off | Enable HTML directory listing |
| `--spa` | off | Serve `index.html` for all 404s (SPA mode) |
| `--log FILE` | *(disabled)* | Append access log to FILE |

Unrecognized flags cause the server to exit with an error message.

## Default Web Root

By default the server looks for a `wwwroot/` folder **next to the executable**:

```
/your/install/dir/
  PureSimpleHTTPServer      ← binary
  wwwroot/                  ← served files (default root)
    index.html
    css/
    js/
```

Override with `--root` to serve from any path:

```bash
./PureSimpleHTTPServer --root /home/alice/public_html
```

## Features

### Static File Serving

Files are served with correct `Content-Type`, `ETag`, and `Last-Modified` headers.

- **304 Not Modified** — when the browser sends `If-None-Match` matching the ETag
- **206 Partial Content** — when the client sends a `Range` header (supports full, open-ended, and suffix ranges)
- **Pre-compressed sidecars** — if `file.html.gz` exists and the client accepts gzip, it is served automatically with `Content-Encoding: gzip`

### Directory Listing

Enable with `--browse`. Displays a sorted HTML table (directories first) with file sizes and modification dates. Links are URL-encoded.

### SPA Fallback

Enable with `--spa`. Any path that resolves to a missing file returns `index.html` from the document root instead of a 404. Useful for client-side routing (React, Vue, etc.).

### Hidden Path Blocking

Paths containing `.git`, `.env`, or `.DS_Store` segments return `403 Forbidden` by default. The pattern list is set in `LoadDefaults()` in `Config.pbi`.

### Embedded Assets

Assets can be bundled into the binary at compile time (no `wwwroot/` folder needed at runtime):

1. **Pack the assets** into a zip:
   ```bash
   scripts/pack_assets.sh dist/ src/webapp.zip
   ```
2. **Embed** in `src/main.pb`:
   ```purebasic
   UseZipPacker()
   DataSection
     webapp:    IncludeBinary "src/webapp.zip"
     webappEnd:
   EndDataSection
   ```
3. **Open** the pack in `Main()`:
   ```purebasic
   OpenEmbeddedPack(?webapp, ?webappEnd - ?webapp)
   ```

Embedded files take priority over disk files. If a path is not found in the pack, disk serving is used as fallback.

### Access Log

Enable with `--log FILE`. Each request appends one line:

```
[2026-03-14 23:30:00] 192.168.1.1 GET /index.html 200 0
```

Format: `[YYYY-MM-DD HH:MM:SS] IP METHOD /path STATUS BYTES`

The log file is created if absent and appended to if it already exists. Writes are mutex-protected for concurrent handler threads.

## Concurrency

The server uses a **thread-per-connection** model (Phase E):

- The main event loop accumulates incoming bytes per client.
- When a complete HTTP request arrives (`\r\n\r\n`), a new thread is spawned to call the request handler.
- The main loop immediately returns to accepting new connections.

Compile with `-t` (thread-safe mode) is required. Slow handlers (large files, directory scans) do not block new connections.
