# CLI Reference — PureSimpleHTTPServer v2.3.1

This document describes every command-line flag and the legacy positional argument. Flags may appear in any order and can be freely combined.

---

## Flag Summary Table

**Server:**

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--port N` | Integer | `8080` | TCP port to listen on |
| `--root DIR` | String | `wwwroot/` next to binary | Document root directory |
| `--browse` | Boolean flag | off | Enable directory listing when no index file exists |
| `--spa` | Boolean flag | off | Serve root `index.html` for all 404 responses |

**TLS:**

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--tls-cert FILE` | String | _(disabled)_ | Path to PEM certificate file |
| `--tls-key FILE` | String | _(disabled)_ | Path to PEM private key file |
| `--auto-tls DOMAIN` | String | _(disabled)_ | Enable automatic HTTPS via acme.sh for DOMAIN |

**Compression:**

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--no-gzip` | Boolean flag | off | Disable dynamic gzip compression |

**Logging:**

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--log FILE` | String | _(disabled)_ | Path to access log (Apache Combined Log Format) |
| `--error-log FILE` | String | _(disabled)_ | Path to error log |
| `--log-level LEVEL` | Enum | `warn` | Error log verbosity: `none`, `error`, `warn`, `info` |
| `--log-size MB` | Integer | `100` | Rotate log files when they reach this size in MB (`0` = disabled) |
| `--log-keep N` | Integer | `30` | Maximum number of archived log files to retain |
| `--no-log-daily` | Boolean flag | off | Disable automatic midnight log rotation |
| `--pid-file FILE` | String | _(disabled)_ | Write the server PID to `FILE` at startup; deleted on clean exit |

**URL:**

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--clean-urls` | Boolean flag | off | Serve `/page.html` when `/page` is requested |
| `--rewrite FILE` | String | _(disabled)_ | Path to URL rewrite/redirect rule file |

---

## Flags

### `--port N`

**Type:** Integer
**Default:** `8080`

Sets the TCP port the server listens on. Any unprivileged port (1024–65535) is valid without elevated permissions. Ports below 1024 typically require root or administrator privileges.

```bash
# Listen on the standard HTTP port (requires root on Linux/macOS)
sudo ./PureSimpleHTTPServer --port 80

# Development server on a non-default port
./PureSimpleHTTPServer --port 3000

# Run a second instance alongside the first
./PureSimpleHTTPServer --root ./staging --port 8081
```

---

### `--root DIR`

**Type:** String
**Default:** `wwwroot/` in the same directory as the binary

Sets the document root — the directory from which files are served. Accepts absolute or relative paths. The directory must exist at startup.

```bash
# Serve a production build output
./PureSimpleHTTPServer --root /var/www/html

# Serve the dist/ folder relative to where the command is run
./PureSimpleHTTPServer --root ./dist

# Serve your home page files while testing locally
./PureSimpleHTTPServer --root ~/Sites/myproject
```

---

### `--browse`

**Type:** Boolean flag (presence enables it)
**Default:** off

When a request targets a directory that contains no `index.html` (or `index.htm`), the server returns a generated HTML page listing the directory's contents. Without this flag, such requests return `403 Forbidden`.

```bash
# Browse all files and folders in wwwroot/
./PureSimpleHTTPServer --browse

# Useful for sharing a downloads folder over the local network
./PureSimpleHTTPServer --root ~/Downloads --port 9000 --browse

# Combine with --root to expose an arbitrary path
./PureSimpleHTTPServer --root /mnt/data/releases --browse
```

---

### `--spa`

**Type:** Boolean flag (presence enables it)
**Default:** off

Single-Page Application mode. When a requested path does not match any file on disk, the server returns the document root's `index.html` with a `200 OK` status instead of a `404`. This allows client-side routers (React Router, Vue Router, Angular Router, etc.) to handle navigation.

`--spa` takes precedence over `--browse` for 404 responses.

```bash
# Serve a React app with client-side routing
./PureSimpleHTTPServer --root ./build --spa

# SPA on a custom port
./PureSimpleHTTPServer --root ./dist --port 4200 --spa

# SPA with access logging enabled
./PureSimpleHTTPServer --root ./public --spa --log ./logs/access.log
```

---

### `--log FILE`

**Type:** String (file path)
**Default:** disabled

Enables request logging to the specified file in **Apache Combined Log Format**. The file is created if it does not exist; parent directories must exist. Logging is disabled entirely when this flag is omitted.

Log format per line:
```
127.0.0.1 - - [15/Mar/2026:14:23:01 +0000] "GET /index.html HTTP/1.1" 200 4321 "-" "Mozilla/5.0 ..."
```

```bash
# Log to a file in the current directory
./PureSimpleHTTPServer --log access.log

# Log to an absolute path (common for production deployments)
./PureSimpleHTTPServer --log /var/log/pshs/access.log

# Combine with log rotation settings
./PureSimpleHTTPServer --log /var/log/pshs/access.log --log-size 50 --log-keep 14
```

---

### `--error-log FILE`

**Type:** String (file path)
**Default:** disabled

Enables error and diagnostic logging to the specified file. Verbosity is controlled by `--log-level`. When omitted, error messages are not written to any file (they may still appear on stderr).

```bash
# Write errors to a dedicated file
./PureSimpleHTTPServer --error-log /var/log/pshs/error.log

# Capture all diagnostic output at info level
./PureSimpleHTTPServer --error-log ./error.log --log-level info

# Separate access and error logs
./PureSimpleHTTPServer --log ./access.log --error-log ./error.log
```

---

### `--log-level LEVEL`

**Type:** Enum
**Default:** `warn`
**Values:** `none` | `error` | `warn` | `info`

Controls what is written to the error log. Each level is inclusive of all higher-severity levels:

| Level | What is logged |
|-------|---------------|
| `none` | Nothing |
| `error` | Fatal errors and request failures only |
| `warn` | Errors plus recoverable warnings (default) |
| `info` | All of the above plus informational startup and shutdown messages |

`--log-level` has no effect unless `--error-log` is also set.

```bash
# Quiet production mode — only hard errors
./PureSimpleHTTPServer --error-log ./error.log --log-level error

# Full diagnostic output for troubleshooting
./PureSimpleHTTPServer --error-log ./debug.log --log-level info

# Silence all error log output explicitly
./PureSimpleHTTPServer --error-log ./error.log --log-level none
```

---

### `--log-size MB`

**Type:** Integer (megabytes)
**Default:** `100`

Rotate the access log and error log when either file reaches this size. On rotation, the current log is renamed with a timestamp suffix and a new file is started. Set to `0` to disable size-based rotation entirely (logs grow without bound).

```bash
# Rotate at 50 MB instead of the default 100 MB
./PureSimpleHTTPServer --log access.log --log-size 50

# Disable size-based rotation (rely on daily rotation or external tools)
./PureSimpleHTTPServer --log access.log --log-size 0

# Small rotation threshold for a low-traffic internal server
./PureSimpleHTTPServer --log access.log --log-size 10
```

---

### `--log-keep N`

**Type:** Integer
**Default:** `30`

Sets the maximum number of rotated (archived) log files to keep. After a rotation, if the archive count exceeds this limit, the oldest archive is deleted. Set to `0` to keep all archives indefinitely.

```bash
# Keep only the last 7 days' worth of rotated logs
./PureSimpleHTTPServer --log access.log --log-keep 7

# Keep 90 archived files for a compliance-sensitive environment
./PureSimpleHTTPServer --log access.log --log-keep 90

# Keep all archives — manage cleanup externally
./PureSimpleHTTPServer --log access.log --log-keep 0
```

---

### `--no-log-daily`

**Type:** Boolean flag (presence enables it)
**Default:** off (daily rotation is on by default)

By default, the server rotates log files at midnight regardless of size. Pass `--no-log-daily` to disable this behavior and rely solely on size-based rotation (or no automatic rotation at all if `--log-size 0` is also set).

```bash
# Disable midnight rotation, keep only size-based rotation
./PureSimpleHTTPServer --log access.log --no-log-daily

# Disable all automatic rotation (manage logs with an external tool such as logrotate)
./PureSimpleHTTPServer --log access.log --log-size 0 --no-log-daily

# Typical setup where logrotate handles rotation
./PureSimpleHTTPServer --log /var/log/pshs/access.log --log-size 0 --no-log-daily
```

---

### `--pid-file FILE`

**Type:** String (file path)
**Default:** disabled

Writes the server's process ID (PID) to the specified file immediately after startup. The file is removed when the server exits cleanly. Useful for init systems, process supervisors, and shell scripts that need to send signals to the server process.

```bash
# Write PID to a standard location
./PureSimpleHTTPServer --pid-file /var/run/pshs.pid

# Use in a script to stop the server gracefully
./PureSimpleHTTPServer --pid-file ./server.pid &
# ... later:
kill $(cat ./server.pid)

# Combined with a systemd-style startup
./PureSimpleHTTPServer --pid-file /run/pshs/pshs.pid --port 80 --root /var/www/html
```

---

### `--clean-urls`

**Type:** Boolean flag (presence enables it)
**Default:** off

Enables extension-less URL handling. When a request arrives for `/page` and no file named `page` exists, the server looks for `/page.html` on disk. If found, it is served transparently with the original URL preserved (no redirect). This is useful for static site generators that produce `.html` files but expect clean URLs.

```bash
# Serve /about instead of /about.html
./PureSimpleHTTPServer --clean-urls

# Common combination: clean URLs with a static site generator output
./PureSimpleHTTPServer --root ./public --clean-urls

# Clean URLs alongside SPA mode
./PureSimpleHTTPServer --root ./out --clean-urls --spa
```

---

### `--rewrite FILE`

**Type:** String (file path)
**Default:** disabled

Loads URL rewrite and redirect rules from the specified file. Rules are evaluated in order for every incoming request. Supports internal rewrites (transparent path substitution) and external redirects (HTTP 301/302 responses). See [URL_REWRITING.md](URL_REWRITING.md) for the full rule syntax.

```bash
# Load rules from rewrite.conf in the current directory
./PureSimpleHTTPServer --rewrite ./rewrite.conf

# Load rules from an absolute path
./PureSimpleHTTPServer --rewrite /etc/pshs/rewrite.conf

# Combine with --root for a full site configuration
./PureSimpleHTTPServer --root /var/www/html --rewrite /etc/pshs/rewrite.conf
```

---

## TLS

### `--tls-cert FILE`

**Type:** String (file path)
**Default:** disabled

Path to a PEM-encoded TLS certificate file. Must be used together with `--tls-key`. When both are provided, the server listens over HTTPS instead of HTTP. Mutually exclusive with `--auto-tls`.

```bash
# Generate a self-signed cert for development
openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem \
  -days 365 -nodes -subj "/CN=localhost"

# Run with manual TLS
./PureSimpleHTTPServer --port 8443 --tls-cert cert.pem --tls-key key.pem

# Test
curl -k https://localhost:8443/
```

---

### `--tls-key FILE`

**Type:** String (file path)
**Default:** disabled

Path to a PEM-encoded TLS private key file. Must be used together with `--tls-cert`. Both flags are required for manual TLS; specifying only one is an error.

```bash
# Both must be specified together
./PureSimpleHTTPServer --tls-cert /etc/ssl/cert.pem --tls-key /etc/ssl/key.pem

# Typical production setup behind a reverse proxy (not recommended — let the proxy handle TLS)
./PureSimpleHTTPServer --port 8443 --root /var/www --tls-cert cert.pem --tls-key key.pem
```

---

### `--auto-tls DOMAIN`

**Type:** String (domain name)
**Default:** disabled

Enables automatic HTTPS via [acme.sh](https://acme.sh). The server issues a certificate for DOMAIN using the HTTP-01 challenge, starts an HTTP listener on port 80 for ACME challenges and HTTPS redirect, and serves HTTPS on port 443 (or the port set by `--port`). A background thread renews the certificate every 12 hours.

Prerequisites: `acme.sh` installed at `~/.acme.sh/acme.sh`, port 80 accessible from the internet, DNS A record pointing to the server. Mutually exclusive with `--tls-cert`/`--tls-key`.

```bash
# Zero-config HTTPS for a production domain
./PureSimpleHTTPServer --auto-tls example.com --root /var/www

# Auto-TLS with logging
./PureSimpleHTTPServer --auto-tls example.com --root /var/www \
  --log /var/log/pshs/access.log --error-log /var/log/pshs/error.log
```

---

## Compression

### `--no-gzip`

**Type:** Boolean flag (presence enables it)
**Default:** off (dynamic gzip is enabled by default)

Disables dynamic gzip compression. By default, the server compresses text, JSON, JavaScript, XML, and SVG responses when the client sends `Accept-Encoding: gzip` and the response body exceeds 256 bytes. Pre-compressed `.gz` sidecar files are still served regardless of this flag.

```bash
# Disable dynamic compression (useful if a reverse proxy handles compression)
./PureSimpleHTTPServer --no-gzip

# Disable gzip when serving pre-compressed content exclusively
./PureSimpleHTTPServer --root ./dist --no-gzip
```

---

## Legacy Positional Argument

For quick local use, a bare integer argument is accepted as a shorthand for `--port`:

```bash
./PureSimpleHTTPServer 3000
# Equivalent to: ./PureSimpleHTTPServer --port 3000
```

This form is provided for convenience and is not recommended for scripts or production use, as it may be ambiguous when combined with other flags. Prefer the explicit `--port` flag in all non-interactive contexts.

---

## Combining Flags

The following command illustrates a production-like invocation combining multiple concerns: a custom root, port, logging, log rotation, PID file, and URL rewriting.

```bash
./PureSimpleHTTPServer \
  --root /var/www/mysite \
  --port 8080 \
  --log /var/log/pshs/access.log \
  --error-log /var/log/pshs/error.log \
  --log-level warn \
  --log-size 100 \
  --log-keep 30 \
  --pid-file /var/run/pshs.pid \
  --clean-urls \
  --rewrite /etc/pshs/rewrite.conf
```

What each flag does in this example:

| Flag | Effect |
|------|--------|
| `--root /var/www/mysite` | Serve files from the production document root |
| `--port 8080` | Listen on port 8080 (behind a reverse proxy such as nginx) |
| `--log ...access.log` | Record every request in Apache Combined Log Format |
| `--error-log ...error.log` | Write server errors and warnings to a separate file |
| `--log-level warn` | Log errors and warnings; suppress informational messages |
| `--log-size 100` | Rotate logs when they reach 100 MB |
| `--log-keep 30` | Keep at most 30 archived log files |
| `--pid-file /var/run/pshs.pid` | Allow init scripts to send signals to the process |
| `--clean-urls` | Serve `/about` when the file on disk is `/about.html` |
| `--rewrite /etc/pshs/rewrite.conf` | Apply custom redirect and rewrite rules |

A minimal SPA deployment with just the essential flags:

```bash
./PureSimpleHTTPServer --root ./build --port 5000 --spa --log ./access.log
```

A local development server with directory browsing:

```bash
./PureSimpleHTTPServer --root . --port 8000 --browse --log-level info
```
