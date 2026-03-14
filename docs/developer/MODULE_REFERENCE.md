# PureSimpleHTTPServer v1.5.0 — Module Reference

This document describes every `.pbi` module in `src/` and the entry-point `main.pb`. For each module the public API (procedures and exported globals), the compile-time dependencies, and implementation details worth knowing when extending the server are listed.

Inclusion order follows `main.pb` and `tests/TestCommon.pbi`. The `XIncludeFile`
directive is idempotent — each file is compiled at most once per compilation unit.

> **Tutorial:** For a step-by-step walkthrough of how all modules fit together, see
> [`BUILD_OUR_HTTP_SERVER.md`](BUILD_OUR_HTTP_SERVER.md).

---

## Global.pbi

**Purpose:** Application-wide constants, HTTP status codes, and buffer size
definitions. No procedures. No globals.

### Constants

| Constant | Value | Meaning |
|---|---|---|
| `#APP_NAME` | `"PureSimpleHTTPServer"` | Used in `Server:` response header |
| `#APP_VERSION` | `"1.5.0"` | Used in `Server:` response header |
| `#HTTP_200` ... `#HTTP_500` | 200-500 | HTTP status code shorthand |
| `#RECV_BUFFER_SIZE` | 65536 | Per-connection TCP receive buffer (64 KB) |
| `#SEND_CHUNK_SIZE` | 65536 | File send chunk size (64 KB) |
| `#MAX_HEADER_SIZE` | 8192 | Maximum accepted request header block (8 KB) |
| `#DEFAULT_PORT` | 8080 | Listening port when none is specified |
| `#DEFAULT_INDEX` | `"index.html"` | Default index file name |

### Dependencies

None. Must be the first `XIncludeFile` in any compilation unit.

---

## Types.pbi

**Purpose:** Shared structure definitions used across multiple modules. No
procedures.

### Structures

#### `HttpRequest`

Filled by `ParseHttpRequest` in `HttpParser.pbi`.

| Field | Type | Description |
|---|---|---|
| `Method` | `.s` | HTTP method: `"GET"`, `"POST"`, `"HEAD"`, etc. |
| `Path` | `.s` | Decoded, normalized URL path — no query string |
| `QueryString` | `.s` | Raw query string (text after `?`), or `""` |
| `Version` | `.s` | `"HTTP/1.1"` or `"HTTP/1.0"` |
| `RawHeaders` | `.s` | Raw header lines after the request line, without the blank terminator |
| `ContentLength` | `.i` | Value of `Content-Length` header, or 0 |
| `Body` | `.s` | Request body (POST data), if any |
| `IsValid` | `.i` | `#True` when parsing succeeded |
| `ErrorCode` | `.i` | HTTP status code on parse failure (typically 400); 0 on success |

#### `HttpResponse`

A convenience struct for assembling responses. Not consumed directly by the
dispatch path — see `HttpResponse.pbi` for the builder procedures.

| Field | Type | Description |
|---|---|---|
| `StatusCode` | `.i` | HTTP status code |
| `StatusText` | `.s` | HTTP reason phrase |
| `ExtraHeaders` | `.s` | Additional header lines (each ending with `#CRLF$`) |
| `Body` | `.s` | Response body as string |
| `BodyBuffer` | `.i` | Pointer to binary buffer (file responses); 0 if unused |
| `BodyBufferSize` | `.i` | Size of `BodyBuffer` in bytes |

#### `RangeSpec`

Filled by `ParseRangeHeader` in `RangeParser.pbi`.

| Field | Type | Description |
|---|---|---|
| `Start` | `.i` | First byte to serve (inclusive) |
| `End` | `.i` | Last byte to serve (inclusive) |
| `IsValid` | `.i` | `#True` if range is satisfiable |

#### `ServerConfig`

Populated by `LoadDefaults` and `ParseCLI` in `Config.pbi`. Passed as a
pointer to every procedure that needs configuration; no module reads a
`g_Config` global directly.

| Field | Type | Description |
|---|---|---|
| `Port` | `.i` | Listening port |
| `RootDirectory` | `.s` | Document root directory |
| `IndexFiles` | `.s` | Comma-separated index file names |
| `BrowseEnabled` | `.i` | `#True` to enable directory listing |
| `SpaFallback` | `.i` | `#True` to serve root index for all 404s |
| `HiddenPatterns` | `.s` | Comma-separated path segments to block (403) |
| `LogFile` | `.s` | Access log file path (`""` to disable) |
| `MaxConnections` | `.i` | Maximum concurrent connections |
| `ErrorLogFile` | `.s` | Error log file path (`""` to disable) |
| `LogLevel` | `.i` | Minimum error log level: 0=none 1=error 2=warn 3=info |
| `LogSizeMB` | `.i` | Size-rotation threshold in MB; 0 disables |
| `LogKeepCount` | `.i` | Maximum archived log files to keep |
| `LogDaily` | `.i` | 1 = daily midnight UTC rotation |
| `PidFile` | `.s` | PID file path (`""` to disable) |
| `CleanUrls` | `.i` | `#True` to try `path.html` for extensionless misses |
| `RewriteFile` | `.s` | Path to global `rewrite.conf` (`""` to disable) |

### Dependencies

`Global.pbi`

---

## DateHelper.pbi

**Purpose:** RFC 7231 HTTP date formatting for `Last-Modified` and `Date`
response headers.

### Public Procedures

#### `HTTPDate(ts.q) -> .s`

Formats a PureBasic timestamp as an RFC 7231 HTTP date string.

| Parameter | Type | Description |
|---|---|---|
| `ts` | `.q` | PureBasic timestamp from `Date()`, `GetFileDate()`, etc. |

Returns a string of the form `"Sat, 14 Mar 2026 00:00:00 GMT"`.

PureBasic's `FormatDate()` provides no day-name or month-name tokens; the
implementation builds those components with lookup strings and `StringField()`.

### Dependencies

None.

---

## UrlHelper.pbi

**Purpose:** URL percent-decoding and path normalization. Called by
`HttpParser.pbi` before storing `HttpRequest\Path`.

### Public Procedures

#### `URLDecodePath(s.s) -> .s`

Percent-decodes a URL path using PureBasic's built-in `URLDecoder()`.

#### `NormalizePath(s.s) -> .s`

Resolves `.` and `..` path segments and enforces a leading `/`.

- Empty segments (double slashes) and `.` segments are discarded.
- `..` pops the last segment from a stack; traversal above root is silently
  ignored (prevents path traversal attacks).
- A trailing slash is preserved if the input had one.
- An empty input returns `"/"`.

Examples:

```
NormalizePath("/foo/./bar")  => "/foo/bar"
NormalizePath("/foo/../bar") => "/bar"
NormalizePath("/../etc")     => "/etc"
NormalizePath("")            => "/"
```

### Dependencies

None.

---

## HttpParser.pbi

**Purpose:** HTTP/1.1 request parser. Splits raw TCP data into a structured
`HttpRequest`.

### Public Procedures

#### `ParseHttpRequest(raw.s, *req.HttpRequest) -> .i`

Parses the raw request string into `*req`.

| Parameter | Type | Description |
|---|---|---|
| `raw` | `.s` | Complete raw HTTP request string including `\r\n\r\n` |
| `*req` | `*HttpRequest` | Pointer to caller-allocated structure to fill |

Returns `#True` on success; `#False` on failure (`req\IsValid = #False`,
`req\ErrorCode = 400`).

Locates the `\r\n\r\n` header terminator, parses the request line (method,
request-target, version), splits the target at `?` to separate path from query
string, calls `URLDecodePath` and `NormalizePath` on the path, and reads
`Content-Length` if present.

#### `GetHeader(rawHeaders.s, name.s) -> .s`

Extracts a single header value by name from a raw header block.

| Parameter | Type | Description |
|---|---|---|
| `rawHeaders` | `.s` | `HttpRequest\RawHeaders` string |
| `name` | `.s` | Header name to find (case-insensitive) |

Returns the trimmed header value, or `""` if not found.

### Dependencies

`Types.pbi`, `UrlHelper.pbi`

---

## HttpResponse.pbi

**Purpose:** HTTP/1.1 response builder. Assembles header blocks and sends
string bodies.

### Public Procedures

#### `StatusText(code.i) -> .s`

Returns the standard HTTP reason phrase for a numeric status code. Codes not
in the table return `"Unknown"`.

#### `BuildResponseHeaders(statusCode.i, extraHeaders.s, bodyLen.i) -> .s`

Assembles a complete HTTP response header block as a string ending with
`\r\n\r\n`. Does not send anything — a pure string function, fully testable
without a network connection.

| Parameter | Type | Description |
|---|---|---|
| `statusCode` | `.i` | HTTP status code |
| `extraHeaders` | `.s` | Additional headers; each line must end with `#CRLF$`; may be `""` |
| `bodyLen` | `.i` | Value to write into `Content-Length` |

Always adds `Server:`, `Content-Length:`, and `Connection: close` headers.

#### `SendTextResponse(connection.i, statusCode.i, contentType.s, body.s)`

Sends a complete HTTP response with a UTF-8 string body. Uses
`StringByteLength(body, #PB_UTF8)` for correct `Content-Length` on non-ASCII
content.

### Dependencies

`Global.pbi`

---

## TcpServer.pbi

**Purpose:** TCP server event loop and thread-per-connection dispatch.

### Public Globals

| Global | Type | Description |
|---|---|---|
| `g_Handler` | `ConnectionHandlerProto` | Assign `@YourHandler()` before calling `StartServer()` |
| `g_Running` | `.i` | `#True` while the server loop is active; `#False` after `StopServer()` |
| `g_CloseMutex` | `.i` | Mutex protecting `g_CloseList` |
| `g_CloseList` | `NewList .i()` | Queue of connection IDs awaiting `CloseNetworkConnection` on the main thread |

### Prototype

```purebasic
Prototype.i ConnectionHandlerProto(connection.i, raw.s)
```

The handler receives the PureBasic network connection ID and the complete raw
HTTP request string.

### Public Procedures

#### `StartServer(port.i) -> .i`

Creates the TCP server and enters a blocking event loop. Returns `#True` on
clean shutdown, `#False` if the server socket could not be created or if
`g_Handler` is not assigned.

On each complete request (detected by `\r\n\r\n` in the accumulated per-client
buffer), a `ThreadData` structure is allocated, filled with the connection ID
and raw string, and passed to a new OS thread via
`CreateThread(@ConnectionThread(), *td)`. If thread creation fails, the request
is handled synchronously on the main thread as a fallback.

The main loop drains `g_CloseList` at the top of every iteration under
`g_CloseMutex`. `CloseNetworkConnection` is only ever called from the main
thread.

#### `StopServer()`

Sets `g_Running = #False`, which causes the event loop to exit on its next
iteration.

### Dependencies

`Global.pbi`

### Notable Implementation Details

Worker threads must not call `CloseNetworkConnection` directly. PureBasic's
network library modifies its internal connection table from both
`NetworkServerEvent` (main thread) and any thread that calls
`CloseNetworkConnection`. The resulting race produces a SIGSEGV under concurrent
load. The close-queue pattern (`g_CloseList` + `g_CloseMutex`) serialises all
close calls back onto the main thread, eliminating this race entirely.

---

## MimeTypes.pbi

**Purpose:** MIME type lookup by file extension.

### Public Procedures

#### `GetMimeType(extension.s) -> .s`

Returns the MIME type string for a lowercase file extension without the leading
dot (e.g., `"html"`, `"css"`, `"js"`, `"png"`).

Returns `"application/octet-stream"` for unrecognized extensions.

The implementation is a single `Select/Case` block with no globals. To add a
new type, add a `Case` line — see `EXTENDING.md` for the pattern.

Covered categories: text (html, htm, css, txt, xml, csv, md, ics, vcf),
scripts (js, mjs, json, jsonld, wasm, webmanifest, appcache), images (png, jpg,
jpeg, gif, svg, webp, ico, bmp, avif, tif, tiff), fonts (woff, woff2, ttf,
otf, eot), audio/video (mp3, ogg, wav, mp4, webm, ogv), archives/binary
(zip, gz, tar, pdf).

### Dependencies

None.

---

## Logger.pbi

**Purpose:** Apache Combined Log Format access log, structured error log,
size-based rotation, daily midnight UTC rotation thread, and SIGHUP-triggered
log reopen.

### Public Globals

| Global | Type | Default | Description |
|---|---|---|---|
| `g_LogFile` | `.i` | 0 | Access log file handle; 0 = not open |
| `g_ErrorLogFile` | `.i` | 0 | Error log file handle; 0 = not open |
| `g_LogMutex` | `.i` | 0 | Single mutex covering both log files and all rotation state |
| `g_LogLevel` | `.i` | 2 | Minimum error log level (0=none 1=error 2=warn 3=info) |
| `g_ServerPID` | `.i` | 0 | Written to `[pid N]` field; set by `main.pb` at startup |
| `g_LogPath` | `.s` | `""` | Access log file path (saved for rotation) |
| `g_ErrorLogPath` | `.s` | `""` | Error log file path (saved for rotation) |
| `g_LogMaxBytes` | `.i` | 0 | Rotation threshold in bytes; 0 disables size rotation |
| `g_LogKeepCount` | `.i` | 30 | Maximum archived log files to keep per log |
| `g_RotationThread` | `.i` | 0 | Daily rotation thread ID; 0 = not running |
| `g_StopRotation` | `.i` | 0 | Set to 1 to signal the rotation thread to exit |
| `g_ReopenLogs` | `.i` | 0 | Set to 1 by SIGHUP handler; cleared inside `g_LogMutex` |

### Public Procedures

#### `OpenLogFile(path.s) -> .i`

Opens the access log for appending, creating the file if it does not exist.
Returns `#True` on success, `#False` if the path cannot be opened or created.

#### `CloseLogFile()`

Flushes and closes the access log. Safe to call when no file is open.

#### `OpenErrorLog(path.s) -> .i`

Opens the error log for appending. Returns `#True` on success, `#False` on
failure.

#### `CloseErrorLog()`

Flushes and closes the error log. Safe to call when no file is open.

#### `LogAccess(ip.s, method.s, path.s, protocol.s, status.i, bytes.i, referer.s, userAgent.s)`

Appends one Combined Log Format (CLF) line to the access log. No-op if no
access log file is open. Pass `bytes = 0` for 304/empty responses; it is
logged as `"-"`.

Format: `IP - - [DD/Mon/YYYY:HH:MM:SS +HHMM] "METHOD /path PROTO" STATUS BYTES "Referer" "UA"`

If `g_LogMaxBytes > 0` and the current file size meets or exceeds the
threshold, the log is rotated (renamed to a date-stamped archive and a new
file is opened) before writing. Also checks `g_ReopenLogs` inside
`g_LogMutex` and calls `ReopenLogs()` if set.

#### `LogError(level.s, message.s)`

Appends one structured error log line. `level` must be `"error"`, `"warn"`, or
`"info"`. No-op if no error log is open, or if the level's integer exceeds
`g_LogLevel`.

Format: `[DD/Mon/YYYY:HH:MM:SS +HHMM] [level] [pid N] message`

Applies the same size-rotation and reopen logic as `LogAccess`.

#### `ApacheDate(ts.q) -> .s`

Formats a timestamp as `[DD/Mon/YYYY:HH:MM:SS +HHMM]` for log line prefixes.
Requires `EnsureLogInit()` to have been called, which `OpenLogFile` and
`OpenErrorLog` both do automatically.

#### `StartDailyRotation()`

Launches the daily midnight UTC rotation background thread. No-op if already
running. Call after opening log files.

#### `StopDailyRotation()`

Signals the rotation thread to exit and waits for it with `WaitThread`. Safe
to call when no thread is running.

### Dependencies

`Global.pbi`

### Notable Implementation Details

- `g_LogMutex` covers both log file handles with a single mutex. This prevents
  interleaved lines when a worker thread calls `LogAccess` and `LogError` in
  close succession, at the cost of slightly higher contention on high-traffic
  servers.
- The timezone offset string (`g_TZOffset`) is computed once at first log open
  using `Date() - ConvertDate(Date(), #PB_Date_UTC)`. No `ImportC` is required.
- Archive file names follow the pattern
  `stem.YYYYMMDD-HHMMSS-NNN.ext` where `NNN` is a per-process sequence counter
  ensuring uniqueness within a single second.
- `PruneArchives` uses a local `NewList` (not a `Global NewList`) and is only
  called from inside `RotateLog`, which is already inside `g_LogMutex`.

---

## FileServer.pbi

**Purpose:** Static file serving from disk. Handles directory index resolution,
directory listing, SPA fallback, pre-compressed `.gz` sidecars, ETag/304
conditional requests, and Range/206 partial content.

### Public Procedures

#### `ServeFile(connection.i, *cfg.ServerConfig, *req.HttpRequest, *bytesOut = 0, *statusOut = 0) -> .i`

Main entry point. Serves the request described by `*req` from
`*cfg\RootDirectory`.

| Parameter | Type | Description |
|---|---|---|
| `connection` | `.i` | PureBasic network connection ID |
| `*cfg` | `*ServerConfig` | Server configuration (read-only) |
| `*req` | `*HttpRequest` | Parsed HTTP request (read-only) |
| `*bytesOut` | `.i` (optional) | Receives body byte count sent; 0 for 304/empty |
| `*statusOut` | `.i` (optional) | Receives actual HTTP status code sent |

Returns `#True` on a 2xx or 3xx response, `#False` if an error response was
sent.

Request handling order:

1. Hidden path check: 403 if any URL segment matches `HiddenPatterns`.
2. Directory: try `ResolveIndexFile` against `IndexFiles`. If no index found
   and `BrowseEnabled`, call `BuildDirectoryListing`. If not browseable,
   send 403.
3. Clean URLs: if `CleanUrls` is set, the path has no extension, and the file
   is missing, retry with `.html` appended to the filesystem path.
4. File not found: if `SpaFallback` is set, serve the root index file; otherwise
   send 404.
5. Pre-compressed `.gz` sidecar: if `Accept-Encoding` contains `"gzip"` and
   `fsPath + ".gz"` exists, serve it with `Content-Encoding: gzip`.
6. ETag/304: if `If-None-Match` equals the computed ETag, send 304.
7. Range request (206): delegate to `ParseRangeHeader` and
   `SendPartialResponse`. Send 416 if the range is not satisfiable.
8. Regular 200: read entire file into an `AllocateMemory` buffer, send, free.

#### `ResolveIndexFile(dirPath.s, indexList.s) -> .s`

Searches `indexList` (comma-separated filenames) left-to-right for the first
file that exists inside `dirPath`. Returns the full filesystem path, or `""`
if none found.

#### `BuildETag(filePath.s) -> .s`

Generates a strong ETag as a quoted hex string `"<size_hex>-<mtime_hex>"`.
Returns `""` if the file does not exist.

#### `IsHiddenPath(urlPath.s, hiddenPatterns.s) -> .i`

Returns `#True` if any URL segment (split on `/`) exactly matches any entry
in the comma-separated `hiddenPatterns` string.

### Dependencies

`Global.pbi`, `Types.pbi`, `DateHelper.pbi`, `HttpParser.pbi`,
`HttpResponse.pbi`, `MimeTypes.pbi`.

Forward-declares `BuildDirectoryListing`, `ParseRangeHeader`, and
`SendPartialResponse` because `DirectoryListing.pbi` and `RangeParser.pbi` are
included after this file. PureBasic resolves forward declarations at the end of
the compilation unit; this is intentional and not a circular dependency.

---

## DirectoryListing.pbi

**Purpose:** HTML directory browse page generator.

### Public Procedures

#### `BuildDirectoryListing(dirPath.s, urlPath.s) -> .s`

Generates an HTML page listing the contents of `dirPath` with links relative
to `urlPath`.

| Parameter | Type | Description |
|---|---|---|
| `dirPath` | `.s` | Absolute filesystem path to the directory |
| `urlPath` | `.s` | URL path used for `href` links (e.g. `"/"` or `"/docs/"`) |

Returns the complete HTML string, or `""` on `ExamineDirectory` failure.

Directories are listed before files. Both lists are sorted ascending
case-insensitively using local `NewList` structures. File sizes are formatted
as bytes, KB, or MB. Modified dates use `HTTPDate`. A parent-directory `../`
link is included for all paths except `"/"`. The page footer includes
`#APP_NAME v#APP_VERSION`.

### Dependencies

`Global.pbi`, `DateHelper.pbi`

---

## RangeParser.pbi

**Purpose:** HTTP `Range:` header parser and 206 Partial Content sender.

### Public Procedures

#### `ParseRangeHeader(header.s, fileSize.i, *range.RangeSpec) -> .i`

Parses a `Range:` header value (without the `Range:` field name) and fills
`*range`.

| Parameter | Type | Description |
|---|---|---|
| `header` | `.s` | Header value only, e.g. `"bytes=0-1023"` |
| `fileSize` | `.i` | Total file size in bytes |
| `*range` | `*RangeSpec` | Filled on success |

Returns `#True` if the range is satisfiable; `#False` if the caller should
send 416. Supports full ranges (`bytes=0-1023`), open-ended ranges
(`bytes=500-`), and suffix ranges (`bytes=-200`). Clamps the end byte to
`fileSize - 1`.

#### `SendPartialResponse(connection.i, fsPath.s, *range.RangeSpec, mimeType.s, fileSize.i) -> .i`

Sends a 206 Partial Content response for the byte range described by `*range`.
Allocates a buffer of exactly `rangeLen + 1` bytes, seeks to `*range\Start`,
reads `rangeLen` bytes, sends headers and data, and frees the buffer.

Returns `#True` on success, `#False` on I/O error or zero-length range.

### Dependencies

`Global.pbi`, `Types.pbi` (`RangeSpec`), `HttpResponse.pbi`

---

## EmbeddedAssets.pbi

**Purpose:** In-memory asset serving from a ZIP archive compiled into the binary
with `IncludeBinary` and opened with `CatchPack`.

### Public Globals

| Global | Type | Description |
|---|---|---|
| `g_EmbeddedPack` | `.i` | `CatchPack` handle; 0 = no pack open |

### Public Procedures

#### `OpenEmbeddedPack(*packData = 0, packSize.i = 0) -> .i`

Opens the in-memory ZIP pack. Default arguments `(0, 0)` return `#False`
without error, making this safe to call unconditionally in unit tests.

| Parameter | Type | Description |
|---|---|---|
| `*packData` | `.i` | Memory address of the embedded data (e.g. `?webapp`) |
| `packSize` | `.i` | Size in bytes (e.g. `?webappEnd - ?webapp`) |

Returns `#True` if the pack was opened successfully. No-op if a pack is already
open. Calls `UseZipPacker()` and `CatchPack(#PB_Any, *packData, packSize)`
internally.

#### `ServeEmbeddedFile(connection.i, urlPath.s) -> .i`

Attempts to serve `urlPath` from the open pack. Strips the leading `/` to
form the pack-relative path; an empty path maps to `"index.html"`.

Returns `#True` if the file was found and a 200 response was sent; `#False`
if the pack is not open or the file is not in the pack (in which case the
caller falls through to disk serving). Assets are decompressed into a 4 MB
heap buffer using `UncompressPackMemory`.

#### `CloseEmbeddedPack()`

Releases the pack handle with `ClosePack`. Safe to call when no pack is open.

### Dependencies

`Global.pbi`, `MimeTypes.pbi`, `HttpResponse.pbi`

---

## Config.pbi

**Purpose:** Server configuration defaults and CLI argument parsing.

### Public Procedures

#### `LoadDefaults(*cfg.ServerConfig)`

Populates a `ServerConfig` structure with safe default values.

| Field | Default |
|---|---|
| `Port` | 8080 |
| `RootDirectory` | `<binary directory>/wwwroot` |
| `IndexFiles` | `"index.html,index.htm"` |
| `BrowseEnabled` | `#False` |
| `SpaFallback` | `#False` |
| `HiddenPatterns` | `".git,.env,.DS_Store"` |
| `LogFile` | `""` (disabled) |
| `MaxConnections` | 100 |
| `ErrorLogFile` | `""` (disabled) |
| `LogLevel` | 2 (warn) |
| `LogSizeMB` | 100 |
| `LogKeepCount` | 30 |
| `LogDaily` | 1 (enabled) |
| `PidFile` | `""` (disabled) |
| `CleanUrls` | `#False` |
| `RewriteFile` | `""` (disabled) |

#### `ParseCLI(*cfg.ServerConfig) -> .i`

Reads `ProgramParameter()` tokens and applies recognized flags to `*cfg`.
Returns `#True` on success; `#False` if any argument is invalid or unrecognized.

Recognized flags:

| Flag | Argument | Effect |
|---|---|---|
| `--port N` | integer | Set listening port (1-65535) |
| `--root DIR` | path | Set document root |
| `--browse` | none | Enable directory listing |
| `--spa` | none | Enable SPA fallback |
| `--log FILE` | path | Set access log path |
| `--error-log FILE` | path | Set error log path |
| `--log-level LEVEL` | none/error/warn/info | Set error log level threshold |
| `--log-size MB` | integer | Set size-rotation threshold in MB |
| `--log-keep N` | integer | Set archive keep count |
| `--no-log-daily` | none | Disable daily midnight rotation |
| `--pid-file FILE` | path | Set PID file path |
| `--clean-urls` | none | Enable clean URL extension inference |
| `--rewrite FILE` | path | Set global rewrite.conf path |
| `N` (bare integer) | none | Legacy: set port directly |

#### `ParseLogLevel(s.s) -> .i`

Converts a level name to its integer: `"none"` = 0, `"error"` = 1,
`"warn"` = 2, `"info"` = 3. Returns -1 for unrecognized input.

### Dependencies

`Global.pbi`, `Types.pbi`

---

## RewriteEngine.pbi

**Purpose:** URL rewrite and redirect rule evaluation. Supports exact, glob
(`/prefix/*`), and regex (`~/pattern/`) matching. Evaluates global rules loaded
from a file, then per-directory `rewrite.conf` files with mtime-based cache
invalidation. Thread-safe via `g_RewriteMutex`.

### Public Constants

| Constant | Value | Meaning |
|---|---|---|
| `#RULE_REWRITE` | 0 | Internal path rewrite; no HTTP change |
| `#RULE_REDIR` | 1 | HTTP redirect (301 or 302) |
| `#MATCH_EXACT` | 0 | Exact URL match |
| `#MATCH_GLOB` | 1 | Prefix + `*` glob |
| `#MATCH_REGEX` | 2 | Regex match (pattern prefixed with `~`) |
| `#MAX_GLOBAL_RULES` | 63 | Capacity: 64 global rules (slots 0-63) |
| `#MAX_DIR_CACHE` | 7 | Capacity: 8 cached directories (slots 0-7) |
| `#MAX_DIR_RULES` | 15 | Capacity: 16 rules per directory (slots 0-15) |

### Structure: `RewriteResult`

| Field | Type | Description |
|---|---|---|
| `Action` | `.i` | 0 = no match, 1 = rewrite (`NewPath` set), 2 = redirect |
| `NewPath` | `.s` | Rewritten path when `Action = 1` |
| `RedirURL` | `.s` | Redirect destination URL when `Action = 2` |
| `RedirCode` | `.i` | 301 or 302 when `Action = 2` |

### Public Globals

All storage is allocated inside `InitRewriteEngine()` as raw `AllocateMemory`
blocks. The `Global` variables below are scalar integer pointers to those
blocks, plus one counter and one mutex — all safe under PureUnit:

Global-rule arrays: `g_GR_RuleTypeMem`, `g_GR_MatchTypeMem`, `g_GR_CodeMem`,
`g_GR_RegexMem`, `g_GR_PatternMem`, `g_GR_DestMem`, `g_GR_Count`

Per-directory cache: `g_DC_DirPathMem`, `g_DC_FileMtimeMem`,
`g_DC_RuleCountMem`, `g_DC_Count`

Per-directory rules (flat, indexed `di * #DR_STRIDE + ri`):
`g_DR_RuleTypeMem`, `g_DR_MatchTypeMem`, `g_DR_CodeMem`, `g_DR_RegexMem`,
`g_DR_PatternMem`, `g_DR_DestMem`

`g_RewriteMutex` — mutex protecting all of the above.

### Public Procedures

#### `InitRewriteEngine()`

Allocates all memory blocks with `AllocateMemory` and creates `g_RewriteMutex`.
Must be called once before any other rewrite procedure. Safe to call from test
setup code without a running server.

#### `CleanupRewriteEngine()`

Frees all regex handles, memory blocks, and the mutex. Safe to call even if
`InitRewriteEngine` was never called or was already cleaned up.

#### `LoadGlobalRules(path.s)`

Loads (or reloads) global rules from a `rewrite.conf` file under
`g_RewriteMutex`. Frees existing regex handles before replacing the rule set.
Passing an empty string or a nonexistent path effectively clears all global
rules.

#### `GlobalRuleCount() -> .i`

Returns the number of loaded global rules. Acquires `g_RewriteMutex`.

#### `ApplyRewrites(path.s, docRoot.s, *result.RewriteResult) -> .i`

Evaluates global rules first, then per-directory rules for the URL's parent
directory. First matching rule wins. Fills `*result` and returns `#True` on a
match; sets `result\Action = 0` and returns `#False` when no rule matches.

Per-directory rules are loaded from `docRoot + dirPath + "/rewrite.conf"`. The
cache entry is invalidated automatically when the file's mtime changes.

### Dependencies

`Global.pbi`, `Types.pbi`

### Notable Implementation Details

`RewriteEngine.pbi` avoids `Global Dim` arrays and `Global NewList` entirely.
All storage is allocated with `AllocateMemory` called from inside
`InitRewriteEngine()`. This works around three bugs in PureBasic 6.30 ARM64
under PureUnit — see `TESTING.md` section 4 for the full explanation.

Elements are accessed via four macros that compute byte offsets manually:
`RW_IGET`/`RW_ISET` (8-byte integer), `RW_QGET`/`RW_QSET` (8-byte quad), and
`RW_SGET`/`RW_SSET` (512-byte ASCII string slot, `#RURL_LEN`).

---

## SignalHandler.pbi

**Purpose:** POSIX SIGHUP handler for logrotate integration (Phase F-4).
Provides no-op stubs on Windows.

### Public Procedures

#### `InstallSignalHandlers()`

On Linux and macOS: installs `SIGHUPHandler` using an `ImportC ""` `signal()`
call. The handler body sets only `g_ReopenLogs = 1` — the only async-signal-
safe operation here. Call once at startup before `StartServer()`.

On Windows: no-op.

#### `RemoveSignalHandlers()`

On Linux and macOS: restores SIGHUP to its default disposition (`SIG_DFL`).
Call at shutdown before `CloseLogFile()`.

On Windows: no-op.

### Dependencies

`Logger.pbi` (for `g_ReopenLogs` global)

### Notable Implementation Details

`LogAccess` and `LogError` in `Logger.pbi` check `g_ReopenLogs` inside
`g_LogMutex` on every call. When it is set, `ReopenLogs()` closes the current
file handle and opens a new one at the same path before writing, allowing an
external `logrotate` to rename the old log file freely.

`#SIGHUP = 1` is identical on macOS and Linux, so no per-platform constant
is needed inside the `CompilerIf` block.

---

## main.pb

**Purpose:** Application entry point. Includes all `.pbi` modules, defines
`HandleRequest` (the default `g_Handler` implementation), and runs the startup /
shutdown sequence.

`main.pb` is not a reusable library module — it is never `XIncludeFile`'d. It is
documented here because it defines the only public procedure not covered by a `.pbi`.

### Public Globals

| Global | Type | Description |
|--------|------|-------------|
| `g_Config` | `ServerConfig` | Runtime configuration; populated by `LoadDefaults` + `ParseCLI`, then read by `HandleRequest` on every request |

### Public Procedures

#### `HandleRequest(connection.i, raw.s) → i`

The default HTTP request handler assigned to `g_Handler` before `StartServer()` is called.

| Parameter | Type | Description |
|-----------|------|-------------|
| `connection` | `.i` | Client connection ID from `EventClient()` |
| `raw` | `.s` | Complete raw HTTP request string (accumulated through `\r\n\r\n`) |

Returns `#True` on a successful response (2xx/3xx sent), `#False` if an error response was sent.

**What it does, in order:**

1. `ParseHttpRequest(raw, req)` — parse method, path, version, headers
2. `GetHeader(req\RawHeaders, ...)` — extract `Referer` and `User-Agent` for logging
3. `ApplyRewrites(req\Path, ...)` — apply global and per-directory rewrite rules; redirect or silently change the path
4. `ServeEmbeddedFile(connection, req\Path)` — try the in-memory ZIP pack; skip if no pack
5. `ServeFile(connection, @g_Config, @req, ...)` — serve from disk with full feature set
6. `LogAccess(...)` — write one Apache CLF line

Only `GET` requests proceed past step 2. All other methods receive a `400 Bad Request`.

**To replace this handler:** assign any procedure matching `ConnectionHandlerProto` to `g_Handler` before calling `StartServer()`. See `EXTENDING.md` and `BUILD_OUR_HTTP_SERVER.md` for worked examples.

### Startup Sequence

```
LoadDefaults → ParseCLI → InitRewriteEngine → LoadGlobalRules
→ configure Logger globals → getpid → OpenLogFile → OpenErrorLog
→ write PID file → StartDailyRotation → InstallSignalHandlers
→ OpenEmbeddedPack → g_Handler = @HandleRequest → StartServer
```

### Shutdown Sequence (reverse of startup)

```
StartServer returns → RemoveSignalHandlers → StopDailyRotation
→ CloseLogFile → CloseErrorLog → DeleteFile(PidFile)
→ CleanupRewriteEngine → CloseEmbeddedPack
```
