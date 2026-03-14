# PureSimpleHTTPServer v1.5.0 — Module Reference

Modules are listed in dependency order, from leaf modules (no dependencies) to the entry point. Each module is a `.pbi` file included with `XIncludeFile` by `main.pb`. Tests include them through `tests/TestCommon.pbi`, which provides the same include chain without the application entry point.

---

## 1. Global.pbi

**Purpose:** Application-wide constants, HTTP status code names, and buffer-size constants. Every other module depends on this file.

### Constants

#### Application identity

| Constant | Value | Purpose |
|----------|-------|---------|
| `#APP_NAME` | `"PureSimpleHTTPServer"` | Appears in the `Server:` response header and directory listing footer |
| `#APP_VERSION` | `"1.5.0"` | Appears alongside `#APP_NAME` |

#### HTTP status codes

| Constant | Value | Meaning |
|----------|-------|---------|
| `#HTTP_200` | 200 | OK |
| `#HTTP_206` | 206 | Partial Content |
| `#HTTP_301` | 301 | Moved Permanently |
| `#HTTP_302` | 302 | Found (temporary redirect) |
| `#HTTP_304` | 304 | Not Modified |
| `#HTTP_400` | 400 | Bad Request |
| `#HTTP_403` | 403 | Forbidden |
| `#HTTP_404` | 404 | Not Found |
| `#HTTP_416` | 416 | Range Not Satisfiable |
| `#HTTP_500` | 500 | Internal Server Error |

#### Buffer sizes

| Constant | Value | Purpose |
|----------|-------|---------|
| `#RECV_BUFFER_SIZE` | 65536 | Bytes in the network receive buffer allocated by `StartServer` |
| `#SEND_CHUNK_SIZE` | 65536 | Reserved for future chunked sending; not currently used as a chunk limit |
| `#MAX_HEADER_SIZE` | 8192 | Informational limit on request header size; enforced by the TCP accumulation logic dispatching on `\r\n\r\n` |

#### Server defaults

| Constant | Value | Purpose |
|----------|-------|---------|
| `#DEFAULT_PORT` | 8080 | Listening port when `--port` is not specified |
| `#DEFAULT_INDEX` | `"index.html"` | Used historically; `LoadDefaults` now sets `IndexFiles` to `"index.html,index.htm"` |

### Design notes

`Global.pbi` contains only constants — no procedures, no globals. This ensures it is safe to include in any order relative to the modules that use it, and that including it in a test harness has no side effects.

---

## 2. Types.pbi

**Purpose:** All shared `Structure` definitions. Keeping structures in a single file prevents circular include dependencies between modules that both produce and consume the same types.

### Structures

#### HttpRequest

Populated by `ParseHttpRequest` and consumed by `ServeFile`, `ApplyRewrites`, and `HandleRequest`.

```purebasic
Structure HttpRequest
  Method.s           ; "GET", "POST", "HEAD", etc.
  Path.s             ; Decoded, normalized URL path (no query string)
  QueryString.s      ; Raw query string (content after ? in request target)
  Version.s          ; "HTTP/1.1" or "HTTP/1.0"
  RawHeaders.s       ; Raw header lines after the request line
  ContentLength.i    ; Value of Content-Length header, or 0
  Body.s             ; Request body (POST data), if any
  IsValid.i          ; #True if parsed successfully
  ErrorCode.i        ; HTTP status code on parse failure (400)
EndStructure
```

`Path` is always the result of `URLDecodePath` followed by `NormalizePath`, so it is safe to concatenate directly with the document root. `RawHeaders` does not include the blank terminating line; use `GetHeader` to extract individual values.

#### HttpResponse

Used internally by response-building code. Not currently passed across module boundaries as a structure; `BuildResponseHeaders` and `SendTextResponse` assemble responses inline.

```purebasic
Structure HttpResponse
  StatusCode.i
  StatusText.s
  ExtraHeaders.s     ; Each line must end with #CRLF$
  Body.s
  BodyBuffer.i       ; Pointer to binary buffer; 0 if unused
  BodyBufferSize.i
EndStructure
```

#### RangeSpec

Filled by `ParseRangeHeader` and consumed by `SendPartialResponse`.

```purebasic
Structure RangeSpec
  Start.i    ; First byte to serve (inclusive)
  End.i      ; Last byte to serve (inclusive)
  IsValid.i  ; #True if range is satisfiable
EndStructure
```

#### ServerConfig

Populated by `LoadDefaults` and `ParseCLI`; passed as a pointer to `ServeFile` and read directly by `HandleRequest` through the global `g_Config`.

```purebasic
Structure ServerConfig
  Port.i
  RootDirectory.s
  IndexFiles.s          ; Comma-separated, e.g. "index.html,index.htm"
  BrowseEnabled.i       ; #True to enable directory listing
  SpaFallback.i         ; #True to serve index.html for all 404s
  HiddenPatterns.s      ; Comma-separated segment names to block
  LogFile.s             ; Access log path; "" to disable
  MaxConnections.i      ; Default 100 (not yet enforced at connection level)
  ErrorLogFile.s
  LogLevel.i            ; 0=none 1=error 2=warn 3=info
  LogSizeMB.i           ; Size-rotation threshold; 0 disables
  LogKeepCount.i        ; Max archived log files to keep
  LogDaily.i            ; 1 = rotate daily at midnight UTC
  PidFile.s             ; PID file path; "" to disable
  CleanUrls.i           ; #True: try path + ".html" for extensionless paths
  RewriteFile.s         ; Global rewrite.conf path; "" to disable
EndStructure
```

#### RewriteResult

Filled by `ApplyRewrites` and read by `HandleRequest`.

```purebasic
Structure RewriteResult
  Action.i      ; 0 = no match, 1 = rewrite, 2 = redirect
  NewPath.s     ; Rewritten URL path (Action = 1)
  RedirURL.s    ; Redirect destination (Action = 2)
  RedirCode.i   ; 301 or 302 (Action = 2)
EndStructure
```

### Design notes

`Types.pbi` has no dependencies of its own (it follows `Global.pbi` in include order but uses no constants from it). This makes it usable as a standalone type library for test helpers that need to construct request or config objects without including the full module chain.

---

## 3. DateHelper.pbi

**Purpose:** RFC 7231 HTTP date formatting for `Last-Modified` and `Date` response headers.

### Procedures

```purebasic
Procedure.s HTTPDate(ts.q)
```

Formats a PureBasic timestamp (seconds since 2000-01-01 UTC, as returned by `Date()`) as an RFC 7231 compliant date string.

- **Input:** PureBasic `.q` (quad/64-bit) timestamp value
- **Output:** String in the form `"Day, DD Mon YYYY HH:MM:SS GMT"`, e.g. `"Sat, 14 Mar 2026 00:00:00 GMT"`
- **No side effects.** Pure function; safe to call from any thread.

### Design notes

PureBasic's `FormatDate()` does not provide day-name or month-name tokens. `HTTPDate` builds these using comma-delimited lookup strings (`"Sun,Mon,Tue,..."`) and `StringField()` with a 1-based index derived from `DayOfWeek()` and `Month()`. This avoids runtime array allocation and keeps the function free of global state.

---

## 4. UrlHelper.pbi

**Purpose:** URL percent-decoding and path traversal normalization, called by `ParseHttpRequest` before paths are stored in `HttpRequest`.

### Procedures

```purebasic
Procedure.s URLDecodePath(s.s)
```

Wraps PureBasic's built-in `URLDecoder(s)`. Converts percent-encoded sequences (e.g. `%20` → space, `%2F` → `/`) in URL paths.

```purebasic
Procedure.s NormalizePath(s.s)
```

Resolves `.` and `..` path segments and removes double slashes.

- Ensures the result always starts with `/`.
- Preserves a trailing `/` if the input had one.
- Silently discards `..` segments that would traverse above the root, protecting against path traversal attacks.
- Examples:
  - `NormalizePath("/foo/./bar")` → `"/foo/bar"`
  - `NormalizePath("/foo/../bar")` → `"/bar"`
  - `NormalizePath("/../etc")` → `"/etc"`
  - `NormalizePath("")` → `"/"`

### Design notes

`NormalizePath` allocates a `NewList segments.s()` on the stack and populates it with valid path segments. After the loop, the list is serialised back to a string. PureBasic frees the list when the procedure returns. No global state is involved; the function is safe to call from any thread.

---

## 5. HttpParser.pbi

**Purpose:** Parse a raw HTTP/1.1 request string (as received from TCP) into an `HttpRequest` structure.

**Dependencies:** `Types.pbi`, `UrlHelper.pbi`

### Procedures

```purebasic
Procedure.s GetHeader(rawHeaders.s, name.s)
```

Extracts a single header value from the raw header block stored in `HttpRequest\RawHeaders`.

- **rawHeaders:** The `\r\n`-separated header lines (no terminating blank line).
- **name:** Header name to search for. Case-insensitive.
- **Returns:** Trimmed header value string, or `""` if the header is not present.
- The function scans linearly; it does not build a map. For the two to four headers accessed per request (Range, Accept-Encoding, If-None-Match, Referer, User-Agent), linear scan is faster than map construction.

```purebasic
Procedure.i ParseHttpRequest(raw.s, *req.HttpRequest)
```

Parses a complete raw HTTP request string.

- **raw:** Must contain the `\r\n\r\n` header terminator. The function does not block waiting for more data.
- **`*req`:** Pointer to a caller-allocated `HttpRequest` structure. All fields are initialised to empty/zero before parsing begins.
- **Returns:** `#True` on success. On failure, `*req\IsValid = #False` and `*req\ErrorCode = 400`.

Parsing steps:

1. Locate `\r\n\r\n`. Fail if absent.
2. Extract the request line (first `\r\n`-delimited field) and split into method, request-target, and version.
3. Validate that version starts with `"HTTP/"`.
4. Split the request-target on `?` to separate path from query string.
5. Apply `URLDecodePath` then `NormalizePath` to the path component.
6. Store the remaining header lines (after the request line) in `RawHeaders`.
7. Call `GetHeader` to extract `Content-Length`.
8. Extract body (everything after `\r\n\r\n`).

### Design notes

The parser is a pure string function — no network I/O, no file I/O, no global state. This makes it directly testable with `Assert` calls without a running server. The only external calls are to `URLDecodePath` and `NormalizePath`, both of which are equally side-effect free.

---

## 6. HttpResponse.pbi

**Purpose:** Assemble and send HTTP/1.1 response header blocks and text-body responses.

**Dependencies:** `Global.pbi`

### Procedures

```purebasic
Procedure.s StatusText(code.i)
```

Returns the standard HTTP reason phrase for a status code (e.g. `200` → `"OK"`, `404` → `"Not Found"`). Returns `"Unknown"` for unrecognized codes.

```purebasic
Procedure.s BuildResponseHeaders(statusCode.i, extraHeaders.s, bodyLen.i)
```

Assembles a complete HTTP response header block.

- **extraHeaders:** Additional headers to include. Each line must end with `#CRLF$`. Pass `""` for no extra headers.
- **bodyLen:** The `Content-Length` value in bytes.
- **Returns:** A complete header block string ending with `#CRLF$ + #CRLF$`, ready to pass directly to `SendNetworkString`.

The function always emits:

```
HTTP/1.1 <statusCode> <reason>\r\n
Server: PureSimpleHTTPServer/1.5.0\r\n
Content-Length: <bodyLen>\r\n
Connection: close\r\n
<extraHeaders>
\r\n
```

This is a pure string function — it does not call any network function. This makes it testable in isolation.

```purebasic
Procedure SendTextResponse(connection.i, statusCode.i, contentType.s, body.s)
```

Sends a complete HTTP response with a UTF-8 string body.

- Uses `StringByteLength(body, #PB_UTF8)` for the correct `Content-Length` value when the body contains non-ASCII characters.
- Sends the header block with `SendNetworkString(..., #PB_Ascii)` and the body with `SendNetworkString(..., #PB_UTF8)`.
- Does not send a body when `byteLen = 0` (important for 304 responses, though `SendTextResponse` is not used for 304s in practice).

### Design notes

`BuildResponseHeaders` is separated from `SendTextResponse` so that callers that send binary bodies (file data, partial content) can build the header independently and send data via `SendNetworkData`. This pattern is used throughout `FileServer.pbi` and `RangeParser.pbi`.

---

## 7. TcpServer.pbi

**Purpose:** TCP server lifecycle, event loop, per-request thread dispatch, and the close-queue pattern.

**Dependencies:** `Global.pbi`

### Globals

| Global | Type | Purpose |
|--------|------|---------|
| `g_Handler` | `ConnectionHandlerProto` | Function pointer to the request handler; must be set before `StartServer` |
| `g_Running` | `.i` | Event loop control flag |
| `g_CloseMutex` | `.i` | Mutex protecting `g_CloseList` |
| `g_CloseList` | `NewList .i()` | Queue of connection IDs to be closed by the main thread |

### Prototype

```purebasic
Prototype.i ConnectionHandlerProto(connection.i, raw.s)
```

The required signature for any function assigned to `g_Handler`. `connection` is the PureBasic client connection ID; `raw` is the complete raw HTTP request string.

### Procedures

```purebasic
Procedure.i StartServer(port.i)
```

Creates a TCP server on `port` and enters a blocking event loop. Returns `#True` on clean shutdown (`StopServer` called), `#False` if `CreateNetworkServer` fails or `g_Handler` is not set.

The event loop handles three events:

- `#PB_NetworkEvent_Connect` — initialises an accumulation buffer for the client.
- `#PB_NetworkEvent_Data` — appends received bytes to the buffer; dispatches to `ConnectionThread` when `\r\n\r\n` is detected.
- `#PB_NetworkEvent_Disconnect` — cleans up the accumulation buffer if the client disconnected before sending a complete request.

When no event is pending (`event = 0`), `Delay(1)` avoids a busy-wait loop.

```purebasic
Procedure StopServer()
```

Sets `g_Running = #False`. The event loop exits on its next iteration. `StopServer` is not called from within the server itself; it must be called from a signal handler or a control thread.

```purebasic
Procedure ConnectionThread(*data.ThreadData)
```

Internal thread entry point. Not intended for direct use. Calls `g_Handler`, then queues `client` onto `g_CloseList`.

### Key structure

```purebasic
Structure ThreadData
  client.i
  raw.s
EndStructure
```

Allocated with `AllocateStructure` on the heap before `CreateThread`, freed with `FreeStructure` inside `ConnectionThread` before `g_Handler` is called.

### Design notes

The `accum` map is a local `NewMap accum.s()` inside `StartServer`. It is only ever accessed on the main thread, so it needs no mutex. Using a map keyed on the string representation of the connection ID handles the case where a new connection reuses an ID that was recently freed.

The thread-creation fallback (synchronous handling when `CreateThread` returns 0) ensures the server degrades gracefully under OS thread exhaustion rather than silently dropping requests.

---

## 8. MimeTypes.pbi

**Purpose:** Map a lowercase file extension to its MIME type string.

**Dependencies:** None.

### Procedures

```purebasic
Procedure.s GetMimeType(extension.s)
```

- **extension:** Lowercase file extension without a leading dot, e.g. `"html"`, `"css"`, `"js"`, `"png"`.
- **Returns:** MIME type string, e.g. `"text/html; charset=utf-8"`. Returns `"application/octet-stream"` for any unrecognized extension.

Recognized extensions include: `html`, `htm`, `css`, `txt`, `xml`, `csv`, `md`, `ics`, `vcf`, `js`, `mjs`, `json`, `jsonld`, `wasm`, `webmanifest`, `appcache`, `png`, `jpg`, `jpeg`, `gif`, `svg`, `webp`, `ico`, `bmp`, `avif`, `tif`, `tiff`, `woff`, `woff2`, `ttf`, `otf`, `eot`, `mp3`, `ogg`, `wav`, `mp4`, `webm`, `ogv`, `zip`, `gz`, `tar`, `pdf`.

### Design notes

The implementation uses a `Select/Case` block rather than a `NewMap`. A map would require global initialisation (which is unsafe under PureUnit, as documented in `RewriteEngine.pbi`), and `Select/Case` compiles to a jump table or series of comparisons that is equally fast for the small number of cases here. There is no runtime allocation. Adding new types requires only adding a `Case` line.

---

## 9. Logger.pbi

**Purpose:** Apache Combined Log Format access log writer, structured error log writer, size-based and daily log rotation, and SIGHUP-triggered log reopen.

**Dependencies:** `Global.pbi`

### Globals

| Global | Type | Default | Purpose |
|--------|------|---------|---------|
| `g_LogFile` | `.i` | 0 | Access log file handle |
| `g_ErrorLogFile` | `.i` | 0 | Error log file handle |
| `g_LogMutex` | `.i` | 0 | Single mutex covering both handles |
| `g_LogLevel` | `.i` | 2 | Minimum error-log level (0=none 1=error 2=warn 3=info) |
| `g_ServerPID` | `.i` | 0 | Set by `main.pb` to the process ID for error log lines |
| `g_TZOffset` | `.s` | `""` | Local UTC offset string, e.g. `"+0700"` (lazy-initialised) |
| `g_LogPath` | `.s` | `""` | Saved access log path for rotation and reopen |
| `g_ErrorLogPath` | `.s` | `""` | Saved error log path |
| `g_LogMaxBytes` | `.i` | 0 | Rotation threshold in bytes; 0 disables size rotation |
| `g_LogKeepCount` | `.i` | 30 | Maximum archive files to keep per log |
| `g_RotationSeq` | `.i` | 0 | Per-process sequence counter for archive name uniqueness |
| `g_RotationThread` | `.i` | 0 | Daily rotation thread ID; 0 when not running |
| `g_StopRotation` | `.i` | 0 | Set to 1 to signal the rotation thread to exit |
| `g_ReopenLogs` | `.i` | 0 | Set to 1 by SIGHUP handler; triggers reopen inside `g_LogMutex` |

### Log formats

**Access log** (Apache Combined Log Format):

```
IP - - [DD/Mon/YYYY:HH:MM:SS +HHMM] "METHOD /path PROTO" STATUS BYTES "Referer" "UA"
```

**Error log:**

```
[DD/Mon/YYYY:HH:MM:SS +HHMM] [level] [pid N] message
```

### Public procedures

```purebasic
Procedure.s ApacheDate(ts.q)
```

Formats a timestamp as `[DD/Mon/YYYY:HH:MM:SS +HHMM]` using the locally computed timezone offset. Requires `EnsureLogInit()` to have been called first (done automatically by `OpenLogFile` / `OpenErrorLog`).

```purebasic
Procedure.i OpenLogFile(path.s)
```

Opens the access log for appending. Creates the file if it does not exist. Returns `#True` on success. Calls `EnsureLogInit()` to create `g_LogMutex` and compute `g_TZOffset` on first call.

```purebasic
Procedure CloseLogFile()
```

Flushes and closes the access log. Safe to call when no file is open.

```purebasic
Procedure.i OpenErrorLog(path.s)
```

Opens the error log for appending. Same behaviour as `OpenLogFile`.

```purebasic
Procedure CloseErrorLog()
```

Flushes and closes the error log.

```purebasic
Procedure LogAccess(ip.s, method.s, path.s, protocol.s, status.i, bytes.i, referer.s, userAgent.s)
```

Appends one Combined Log Format line. No-op if `g_LogFile = 0`. Acquires `g_LogMutex` for the duration of the write. If `g_ReopenLogs` is set, calls `ReopenLogs()` inside the mutex before writing. If `g_LogMaxBytes > 0` and the file has reached the threshold, rotates before writing.

- `bytes`: Pass 0 for 304 and empty responses; logged as `"-"`.
- `referer`, `userAgent`: Pass `""` for absent headers; logged as `"-"`.

```purebasic
Procedure LogError(level.s, message.s)
```

Appends one error log line. No-op if `g_ErrorLogFile = 0` or if the numeric level of `level` exceeds `g_LogLevel`.

- `level`: `"error"` (1), `"warn"` (2), or `"info"` (3).
- Rotation and SIGHUP reopen are applied inside `g_LogMutex` in the same way as `LogAccess`.

```purebasic
Procedure StartDailyRotation()
```

Launches `LogRotationThread` as a background thread. No-op if the thread is already running. The thread computes seconds until the next UTC midnight, sleeps one second at a time (checking `g_StopRotation`), then acquires `g_LogMutex` and rotates both open log files.

```purebasic
Procedure StopDailyRotation()
```

Sets `g_StopRotation = 1` and calls `WaitThread` to join the rotation thread. Safe to call when no thread is running.

### Rotation mechanics

When a log file meets or exceeds `g_LogMaxBytes` (size-based) or when the daily thread fires (time-based), `RotateLog(*fh, logPath.s)` is called inside `g_LogMutex`:

1. The file is flushed and closed.
2. It is renamed to `stem.YYYYMMDD-HHMMSS-NNN.ext` where NNN is an incrementing per-process sequence number.
3. A new file is created at the original path.
4. `PruneArchives` deletes the oldest archives until the count is at most `g_LogKeepCount`.

### Design notes

The timezone offset is computed once at first log open using the expression `Date() - ConvertDate(Date(), #PB_Date_UTC)`. This requires no `ImportC` and works on all platforms. The offset is fixed for the life of the process; servers that run across a DST boundary will log the pre-DST offset until restarted.

A single mutex covers both log file handles. This is intentional: a worker thread that calls both `LogAccess` and `LogError` (which happens on every request that produces a file error) acquires the mutex twice in sequence. Using a single mutex rather than two ensures the two lines appear consecutively in the logs with no interleaving from other threads.

---

## 10. FileServer.pbi

**Purpose:** Serve static files from disk. This is the largest module and implements the full HTTP feature set for file serving.

**Dependencies:** `Global.pbi`, `Types.pbi`, `DateHelper.pbi`, `HttpParser.pbi`, `HttpResponse.pbi`, `MimeTypes.pbi`; uses forward-declared `BuildDirectoryListing`, `ParseRangeHeader`, `SendPartialResponse`.

### Procedures

```purebasic
Procedure.s ResolveIndexFile(dirPath.s, indexList.s)
```

Finds the first existing index file in `dirPath` by checking each name in the comma-separated `indexList` left-to-right.

- **Returns:** Full filesystem path to the first matching file, or `""` if none exists.

```purebasic
Procedure.s BuildETag(filePath.s)
```

Generates a strong ETag for a file.

- **Returns:** A quoted string of the form `"<hex-size>-<hex-mtime>"`, e.g. `"1a2b-3c4d5e6f"`. Returns `""` if the file does not exist.
- The ETag is derived from `FileSize` and `GetFileDate(filePath, #PB_Date_Modified)`. It is not a hash of the file contents; it changes on size or modification time change.

```purebasic
Procedure.i IsHiddenPath(urlPath.s, hiddenPatterns.s)
```

Checks whether any URL path segment exactly matches a name in the comma-separated `hiddenPatterns` string.

- **Returns:** `#True` if the path contains a hidden segment (e.g. `.git`, `.env`, `.DS_Store`).
- Matching is exact (case-sensitive). Patterns are segment names, not glob patterns.

```purebasic
Procedure.i ServeFile(connection.i, *cfg.ServerConfig, *req.HttpRequest, *bytesOut = 0, *statusOut = 0)
```

The primary file-serving procedure. Handles the complete request life cycle from path resolution to response sending.

- **`*bytesOut`** (optional, pointer to `.i`): Receives the body byte count sent (0 for 304, directory listings are not counted here).
- **`*statusOut`** (optional, pointer to `.i`): Receives the HTTP status code actually sent.
- **Returns:** `#True` if a 2xx or 3xx response was sent, `#False` if a 4xx or 5xx was sent.

Decision tree (in evaluation order):

1. **Hidden path** — if `IsHiddenPath` returns `#True`, send 403 and return.
2. **Directory** — if `FileSize(fsPath) = -2` (directory):
   - Try `ResolveIndexFile`. If found, continue to step 5 with the index file path.
   - If `BrowseEnabled`, call `BuildDirectoryListing` and send 200 HTML.
   - Otherwise, send 403.
3. **Clean URLs** — if file not found and `CleanUrls` is enabled and the path has no extension, retry with `.html` appended.
4. **Not found** — if file still not found:
   - If `SpaFallback` is enabled, resolve the root index file and serve it as 200.
   - Otherwise, send 404.
5. **Pre-compressed sidecar** — if the `Accept-Encoding` header contains `"gzip"` and a `.gz` file exists alongside the requested file, serve the compressed file with `Content-Encoding: gzip`.
6. **304 Not Modified** — if `If-None-Match` matches the computed ETag, send 304 (no body).
7. **Range request** — if a `Range` header is present, call `ParseRangeHeader`. On success, dispatch to `SendPartialResponse` (206). On failure, send 416.
8. **200 response** — allocate a buffer of `fileSize + 1` bytes, read the file, send headers + binary data, free the buffer.

### Design notes

`ServeFile` receives `*cfg` and `*req` as pointers rather than copies to avoid copying the relatively large `ServerConfig` structure (which contains many string fields) on every request. The `*bytesOut` and `*statusOut` optional pointer parameters are checked with `If *bytesOut : PokeI(*bytesOut, ...) : EndIf` before writing, so passing 0 (the default) is always safe.

The `.gz` sidecar mechanism does not use `Content-Encoding` negotiation through `Accept-Encoding` scoring; it simply checks for the presence of `"gzip"` in the header value. This is sufficient for all current browser clients.

---

## 11. DirectoryListing.pbi

**Purpose:** Generate an HTML directory browse page.

**Dependencies:** `Global.pbi`, `DateHelper.pbi`

### Procedures

```purebasic
Procedure.s BuildDirectoryListing(dirPath.s, urlPath.s)
```

- **dirPath:** Absolute filesystem path to the directory to list.
- **urlPath:** URL path used to generate `<a href>` links.
- **Returns:** Complete HTML page as a string, or `""` on `ExamineDirectory` failure.

The listing separates directories from files (directories first), sorts each group case-insensitively in ascending order, and formats file sizes as B/KB/MB. Modification times are formatted with `HTTPDate`. Entry names in `<a href>` links are URL-encoded with `URLEncoder`.

The page uses a minimal inline `<style>` block and no external resources, making it safe to serve in any context including when the document root contains no CSS files.

### Design notes

Directory entries are collected into two `NewList` variables (`dirs` and `files`) allocated on the stack inside the procedure. PureBasic frees these automatically at procedure exit. `ExamineDirectory` is called with a fixed handle of `0`; this is an internal procedure and the handle does not conflict with `PruneArchives`, which uses handle `1`. If the server ever calls these concurrently, the handle usage should be reviewed.

---

## 12. RangeParser.pbi

**Purpose:** Parse HTTP `Range` headers and send 206 Partial Content responses.

**Dependencies:** `Global.pbi`, `Types.pbi` (for `RangeSpec`), `HttpResponse.pbi`

### Procedures

```purebasic
Procedure.i ParseRangeHeader(header.s, fileSize.i, *range.RangeSpec)
```

Parses the value of a `Range:` header (not including the header name).

- **header:** e.g. `"bytes=0-1023"`, `"bytes=500-"`, `"bytes=-200"`.
- **fileSize:** Total file size in bytes, needed to resolve open-ended and suffix ranges.
- **`*range`:** Filled with `Start`, `End`, and `IsValid` on success.
- **Returns:** `#True` if the range is satisfiable, `#False` if the caller should send 416.

Supported range forms:
- `bytes=start-end` — explicit range; `end` is clamped to `fileSize - 1` if larger.
- `bytes=start-` — open-ended; serves from `start` to end of file.
- `bytes=-N` — suffix; serves the last `N` bytes.

```purebasic
Procedure.i SendPartialResponse(connection.i, fsPath.s, *range.RangeSpec, mimeType.s, fileSize.i)
```

Sends a 206 Partial Content response.

- Opens `fsPath`, seeks to `*range\Start`, reads `rangeLen` bytes into an `AllocateMemory` buffer, sends headers and data, then frees the buffer.
- The `Content-Range` header is set to `bytes start-end/total`.
- **Returns:** `#True` on success, `#False` on I/O failure.

### Design notes

RFC 9110 allows multi-range requests (`Range: bytes=0-499,600-999`). This implementation supports only a single range per request. Multi-range requests receive a response for the first range only; the server does not detect or reject them. This is compliant — the RFC permits servers to respond to multi-range requests with a single-range or full response.

---

## 13. Config.pbi

**Purpose:** Populate `ServerConfig` with defaults and override from command-line arguments.

**Dependencies:** `Global.pbi`, `Types.pbi`

### Procedures

```purebasic
Procedure LoadDefaults(*cfg.ServerConfig)
```

Populates `*cfg` with production-safe defaults:

| Field | Default |
|-------|---------|
| `Port` | `#DEFAULT_PORT` (8080) |
| `RootDirectory` | `<executable directory>/wwwroot` |
| `IndexFiles` | `"index.html,index.htm"` |
| `BrowseEnabled` | `#False` |
| `SpaFallback` | `#False` |
| `HiddenPatterns` | `".git,.env,.DS_Store"` |
| `LogFile` | `""` (logging disabled) |
| `MaxConnections` | 100 |
| `ErrorLogFile` | `""` |
| `LogLevel` | 2 (warn) |
| `LogSizeMB` | 100 |
| `LogKeepCount` | 30 |
| `LogDaily` | 1 |
| `PidFile` | `""` |
| `CleanUrls` | `#False` |
| `RewriteFile` | `""` |

```purebasic
Procedure.i ParseLogLevel(s.s)
```

Converts a level name string to its integer value: `"none"` → 0, `"error"` → 1, `"warn"` → 2, `"info"` → 3. Returns `-1` for unrecognized values.

```purebasic
Procedure.i ParseCLI(*cfg.ServerConfig)
```

Iterates `ProgramParameter()` and applies overrides to `*cfg`. Returns `#True` on success, `#False` if any argument is unrecognized or its value is invalid (e.g. a port outside 1–65535, an unrecognized log level).

Supported flags:

| Flag | Argument | Effect |
|------|----------|--------|
| `--port N` | integer 1–65535 | Sets `Port` |
| `--root DIR` | string | Sets `RootDirectory` |
| `--browse` | — | Sets `BrowseEnabled = #True` |
| `--spa` | — | Sets `SpaFallback = #True` |
| `--log FILE` | path | Sets `LogFile` |
| `--error-log FILE` | path | Sets `ErrorLogFile` |
| `--log-level LEVEL` | none/error/warn/info | Sets `LogLevel` |
| `--log-size MB` | integer >= 0 | Sets `LogSizeMB` |
| `--log-keep N` | integer >= 0 | Sets `LogKeepCount` |
| `--no-log-daily` | — | Sets `LogDaily = 0` |
| `--pid-file FILE` | path | Sets `PidFile` |
| `--clean-urls` | — | Sets `CleanUrls = #True` |
| `--rewrite FILE` | path | Sets `RewriteFile` |
| `N` (bare integer) | — | Legacy: sets `Port` (same validation as `--port`) |

### Design notes

`ParseCLI` returns `#False` on the first unrecognized argument. There is no partial-success mode. This is intentional: an unrecognized argument usually indicates a typo or version mismatch, and silently ignoring it would give the user no feedback.

`LoadDefaults` uses `GetPathPart(ProgramFilename()) + "wwwroot"` for the default root so that the server is usable out-of-the-box when run from a directory containing a `wwwroot` folder, without requiring any command-line arguments.

---

## 14. RewriteEngine.pbi

**Purpose:** URL rewrite and redirect rule evaluation. Supports exact, glob, and regex patterns with destination placeholder substitution. Manages both global rules (loaded from a file) and per-directory rules (loaded from `rewrite.conf` files found inside served directories, cached and reloaded on modification).

**Dependencies:** `Global.pbi`, `Types.pbi`

### Rule file syntax

```
# Comment lines start with #
rewrite <pattern>  <destination>
redir   <pattern>  <destination>  [301|302]
```

Pattern forms:

| Prefix | Type | Example |
|--------|------|---------|
| (none) | Exact match | `/about` |
| `*` suffix | Glob (prefix match, captures remainder) | `/blog/*` |
| `~` prefix | Regex (POSIX ERE via PureBasic `CreateRegularExpression`) | `~/posts/(\d+)/` |

Destination placeholders:

| Placeholder | Expands to |
|-------------|-----------|
| `{path}` | Text captured by `*` in a glob pattern |
| `{file}` | Basename portion of `{path}` |
| `{dir}` | Directory portion of `{path}` |
| `{re.1}` … `{re.9}` | Numbered regex capture groups |

Evaluation order: global rules (from `--rewrite FILE`) first, then per-directory rules (from `rewrite.conf` in the request's URL directory). First match wins.

### Capacity limits

| Constant | Value | Meaning |
|----------|-------|---------|
| `#MAX_GLOBAL_RULES` | 63 | Maximum global rules (0-based index: slots 0–63) |
| `#MAX_DIR_CACHE` | 7 | Maximum cached directories (slots 0–7) |
| `#MAX_DIR_RULES` | 15 | Maximum rules per directory (slots 0–15) |
| `#DR_STRIDE` | 16 | Flat index stride for per-directory rules |
| `#RURL_LEN` | 512 | Bytes per string slot in pattern/destination arrays |

### Key structures

```purebasic
Structure RewriteResult
  Action.i      ; 0 = no match, 1 = rewrite (NewPath set), 2 = redirect
  NewPath.s     ; Rewritten path (Action = 1)
  RedirURL.s    ; Redirect target (Action = 2)
  RedirCode.i   ; 301 or 302 (Action = 2)
EndStructure
```

`RewriteRule` is a private structure used only as `Protected` locals inside parsing and loading procedures; it is never stored in a `Global Dim` array.

### Public procedures

```purebasic
Procedure InitRewriteEngine()
```

Allocates all raw memory blocks for rule storage and creates `g_RewriteMutex`. Must be called once at startup before any other rewrite function. Uses `AllocateMemory` rather than `Global Dim` — see design notes below.

```purebasic
Procedure CleanupRewriteEngine()
```

Frees all regex handles, all memory blocks, and `g_RewriteMutex`. Safe to call if `InitRewriteEngine` was never called (checks `g_GR_RuleTypeMem = 0`). Must be called at shutdown.

```purebasic
Procedure LoadGlobalRules(path.s)
```

Loads (or reloads) global rules from a `rewrite.conf` file. Acquires `g_RewriteMutex`, frees existing regex handles, clears the count, reads and parses lines from the file, and releases the mutex. Thread-safe; can be called at runtime to hot-reload rules.

```purebasic
Procedure.i GlobalRuleCount()
```

Returns the number of currently loaded global rules. Thread-safe.

```purebasic
Procedure.i ApplyRewrites(path.s, docRoot.s, *result.RewriteResult)
```

Evaluates all applicable rules against `path` and fills `*result`.

- Acquires `g_RewriteMutex` for the entire evaluation.
- Evaluates global rules in order. On first match, fills `*result` and returns `#True`.
- If no global rule matches, derives the URL directory from `path` (via `URLDirname_`), calls `LoadDirRulesIfNeeded_` to load or refresh the per-directory rule cache, then evaluates those rules.
- Returns `#False` if no rule matches (`*result\Action` remains 0).

### Memory layout and access macros

Integer array elements are 8 bytes on ARM64 (PureBasic `.i` on 64-bit targets). String slots are `#RURL_LEN = 512` bytes each. Access is via macros:

```purebasic
Macro RW_IGET(mem, i)   ; read integer element i
  PeekI((mem) + (i) * 8)
EndMacro
Macro RW_ISET(mem, i, v)
  PokeI((mem) + (i) * 8, (v))
EndMacro
Macro RW_SGET(mem, i)   ; read ASCII string from slot i
  PeekS((mem) + (i) * #RURL_LEN, -1, #PB_Ascii)
EndMacro
Macro RW_SSET(mem, i, s)
  PokeS((mem) + (i) * #RURL_LEN, (s), #RURL_LEN - 1, #PB_Ascii)
EndMacro
```

### Design notes: AllocateMemory pattern

`RewriteEngine.pbi` documents three bugs in PureBasic 6.30 ARM64 that affect global data structures:

1. `Global NewList` + `AddElement` inside any procedure corrupts the list's internal state; subsequent `ForEach` or `ClearList` segfaults.
2. `Global Dim` of structure types with embedded `.s` string fields causes memory corruption during global initialisation.
3. PureUnit skips top-level `main()` code, leaving `Global Dim` array descriptors zeroed. `SYS_ReAllocateArray` (used by `ReDim`) reads element-size and type from the descriptor — both zero — and crashes.

The fix is to replace all `Global Dim` arrays with `AllocateMemory` blocks allocated inside `InitRewriteEngine()`. Only scalar `Global .i` and `Global .s` variables are safe under PureUnit, because the compiler initialises them statically without any runtime code.

This pattern — `InitXxx()` / `CleanupXxx()` bracketing `AllocateMemory` / `FreeMemory` calls — should be followed by any future module that needs persistent, mutable, shared array state.

---

## 15. EmbeddedAssets.pbi

**Purpose:** Serve files from a ZIP archive embedded in the binary's `DataSection` using PureBasic's `CatchPack`/`UncompressPackMemory` API.

**Dependencies:** `Global.pbi`, `MimeTypes.pbi`, `HttpResponse.pbi`

### Globals

| Global | Type | Purpose |
|--------|------|---------|
| `g_EmbeddedPack` | `.i` | `CatchPack` handle; 0 when no pack is open |

### Procedures

```purebasic
Procedure.i OpenEmbeddedPack(*packData = 0, packSize.i = 0)
```

Opens the in-memory pack.

- Default arguments `(0, 0)` return `#False` immediately — this is the intended behaviour when no embedded assets are compiled in.
- If `g_EmbeddedPack > 0`, returns `#True` without reopening (idempotent).
- Calls `UseZipPacker()` internally; the caller does not need to call it separately (though calling `UseZipPacker()` in `main.pb` before the `DataSection` is required to link the packer library).

```purebasic
Procedure.i ServeEmbeddedFile(connection.i, urlPath.s)
```

Serves a file from the open pack.

- Strips the leading `/` from `urlPath` to get the pack-relative path. Requests for `/` look for `"index.html"` in the pack.
- Allocates a 4 MB working buffer with `AllocateMemory`, calls `UncompressPackMemory` by filename, sends a 200 response with the correct MIME type, and frees the buffer.
- Returns `#False` immediately if `g_EmbeddedPack = 0` (no pack open) or if the file is not found in the pack (`UncompressPackMemory` returns -1).
- The 4 MB ceiling is a per-request allocation limit. Assets larger than 4 MB are not served from the embedded pack; they must be placed on disk.

```purebasic
Procedure CloseEmbeddedPack()
```

Releases the pack handle with `ClosePack`. Sets `g_EmbeddedPack = 0`. Safe to call when no pack is open.

### Usage pattern in main.pb

```purebasic
UseZipPacker()
DataSection
  webapp:    IncludeBinary "webapp.zip"
  webappEnd:
EndDataSection

; In Main():
OpenEmbeddedPack(?webapp, ?webappEnd - ?webapp)
```

### Design notes

Embedded assets take priority over disk files. `HandleRequest` calls `ServeEmbeddedFile` before `ServeFile`. This means that if a file exists both in the pack and on disk, the pack version is served. During development, disable the pack (do not call `OpenEmbeddedPack` with a non-zero address) to serve directly from disk without recompiling.

The 4 MB limit is hardcoded in `ServeEmbeddedFile`. For applications with large embedded assets, this constant should be adjusted before compiling. A future version could inspect the uncompressed size from the pack's central directory before allocating.

---

## 16. SignalHandler.pbi

**Purpose:** Install a SIGHUP handler that sets `g_ReopenLogs = 1`, enabling integration with external log rotation tools such as `logrotate`.

**Dependencies:** `Logger.pbi` (for `g_ReopenLogs`)

### Platform behaviour

On Linux and macOS, the module imports the C `signal()` function and installs a minimal signal handler. On Windows, `InstallSignalHandlers` and `RemoveSignalHandlers` are compiled as empty stubs — SIGHUP does not exist on Windows. Use the built-in size-based (F-2) or daily (F-3) rotation instead.

### Procedures

```purebasic
Procedure InstallSignalHandlers()
```

Installs `SIGHUPHandler` as the handler for `SIGHUP` (signal 1). Call once at startup, before `StartServer`.

```purebasic
Procedure RemoveSignalHandlers()
```

Restores `SIGHUP` to its default disposition (`SIG_DFL`). Call at shutdown, before `CloseLogFile`.

### SIGHUP handler

```purebasic
Procedure SIGHUPHandler(signum.i)
  g_ReopenLogs = 1
EndProcedure
```

The handler only sets an integer flag. This is the only async-signal-safe operation. The actual file close and reopen is performed inside `g_LogMutex` by `LogAccess` or `LogError` on the next log write after the flag is detected.

### logrotate integration

The following snippet is suitable for `/etc/logrotate.d/puresimplehttpserver`:

```
/var/log/pshs/access.log /var/log/pshs/error.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    sharedscripts
    postrotate
        kill -HUP $(cat /var/run/pshs.pid) 2>/dev/null || true
    endscript
}
```

This requires `--pid-file /var/run/pshs.pid` in the server startup arguments.

### Design notes

The POSIX `signal()` function is imported via `ImportC ""` rather than `ImportC "libc.so"` or similar. PureBasic's C backend links against the platform C library automatically; an empty string in `ImportC` resolves symbols from the already-linked libc. This approach is portable between macOS and Linux without conditional library names.

The flag variable `g_ReopenLogs` is `Global .i` (an integer). Integer reads and writes are atomic on x86-64 and ARM64; no mutex is needed in the signal handler itself. The mutex is only required in `LogAccess`/`LogError` to prevent the reopen from racing with an in-progress log write.
