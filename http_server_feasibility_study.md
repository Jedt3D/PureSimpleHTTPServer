# HTTP Server in PureBasic — Feasibility Study
**Reference Model:** Caddy `file-server`
**Target:** A simple, single-binary HTTP server that serves a compiled-in web application
**Date:** 2026-03-14
**Phase:** v1.0 (excludes HTTPS, GZip/Zstd, canonical URI enforcement)

---

## 1. Executive Summary

Building an HTTP/1.1 static file server in PureBasic is **highly feasible**. PureBasic's built-in libraries cover all the essential building blocks: raw TCP networking, multi-threading with synchronization primitives, file system access, memory buffers, hashing, Base64, regex, and URL encoding. The main implementation work is in manually writing an HTTP/1.1 request parser and response builder — since PureBasic's `Http` library is client-side only. Everything else maps cleanly to built-in functionality.

The target use case — a self-contained binary that bundles and serves a compiled web application — is well-supported by the `Packer` library's in-memory archive capabilities.

---

## 2. Scope Definition (v1.0)

### In Scope
- HTTP/1.1 request parsing over raw TCP
- Static file serving (HTML, CSS, JS, images, video, fonts, SVG)
- Directory listing (browse mode)
- Multi-threaded concurrent connections
- SPA / pass-through fallback (index.html fallback for unknown paths)
- Pre-compressed sidecar file serving (`.gz` check, no runtime compression)
- ETag & Last-Modified caching headers
- Range requests (for video/large file streaming)
- Access logging
- Bundled web application as an embedded archive
- MIME type detection via extension mapping table
- URL encoding/decoding
- Configurable port, root, index files, hidden paths

### Explicitly Excluded (Future Phases)
| Feature | Reason |
|---------|--------|
| HTTPS / TLS | Excluded from v1 (library support exists via `UseNetworkTLS`) |
| GZip runtime compression | No native GZip in Packer library |
| Zstd runtime compression | Not available in PureBasic built-ins |
| Canonical URI enforcement | Future phase |
| Jinja-style template engine | Future phase (static `.html` only for now) |

---

## 3. PureBasic Built-in Library Inventory

### 3.1 Network Library ✅ FULLY CAPABLE

| Function | Role in HTTP Server |
|----------|---------------------|
| `CreateNetworkServer()` | Create TCP listener on a port (IPv4/IPv6, TCP) |
| `NetworkServerEvent()` | Event loop for new connections and incoming data |
| `ReceiveNetworkData()` | Read raw bytes from a client connection |
| `SendNetworkData()` | Send response bytes (headers + body) |
| `SendNetworkString()` | Send response header strings |
| `GetClientIP()` / `GetClientPort()` | Logging client address info |
| `CloseNetworkConnection()` | Close connection after response |
| `CloseNetworkServer()` | Graceful shutdown |
| `UseNetworkTLS()` | TLS support (excluded v1, available for v2) |

**Verdict:** The raw TCP server foundation is complete and production-quality. HTTP must be implemented at the application layer, which is standard practice.

---

### 3.2 Http Library ⚠️ CLIENT-SIDE ONLY

| Available | Notes |
|-----------|-------|
| `HTTPRequest()`, `ReceiveHTTPFile()` | Client only — fetches remote URLs |
| `URLEncoder()` / `URLDecoder()` | ✅ Can be used for URL path decoding |
| `GetURLPart()` / `SetURLPart()` | ✅ Useful for parsing query strings |

**Verdict:** No server-side HTTP. However, `URLEncoder`/`URLDecoder` and `GetURLPart` are directly useful. The HTTP protocol logic (parsing request lines, headers, sending status codes) must be hand-implemented — this is straightforward for HTTP/1.1 and is standard practice in embedded/custom servers.

---

### 3.3 File & FileSystem Libraries ✅ FULLY CAPABLE

| Capability | Functions | Status |
|------------|-----------|--------|
| Read file into memory buffer | `OpenFile()` + `ReadData()` | ✅ |
| Get file size | `FileSize()` / `Lof()` | ✅ |
| Get file modification date | `GetFileDate()` / `DirectoryEntryDate()` | ✅ |
| List directory contents | `ExamineDirectory()`, `NextDirectoryEntry()` | ✅ |
| Check file existence | `FileSize()` (returns -1 if not found) | ✅ |
| Extract file extension | `GetExtensionPart()` | ✅ |
| Seek to byte offset | `FileSeek()` | ✅ (Range requests) |
| Get file path parts | `GetPathPart()`, `GetFilePart()` | ✅ |

**Verdict:** All file operations needed for HTTP static serving are available. Range requests (for video streaming) are supported via `FileSeek()` + `ReadData()`.

---

### 3.4 Thread Library ✅ FULLY CAPABLE

| Capability | Functions | Status |
|------------|-----------|--------|
| Spawn connection handler thread | `CreateThread()` | ✅ |
| Thread-safe shared state | `CreateMutex()`, `LockMutex()`, `UnlockMutex()` | ✅ |
| Thread signaling | `CreateSemaphore()`, `SignalSemaphore()`, `WaitSemaphore()` | ✅ |
| Kill / wait on thread | `KillThread()`, `WaitThread()` | ✅ |

**Note:** Compiler must be built with thread-safe mode (`EnableExplicit` + threaded compiler switch). The `Threaded` keyword enables per-thread variables.

**Verdict:** Full multi-threaded connection handling is possible — spawn one thread per connection or implement a thread pool using semaphores.

---

### 3.5 Packer Library ✅ (Zip — for embedded assets)

| Format | Status | Use Case |
|--------|--------|----------|
| Zip | ✅ Built-in | Bundle web app assets in a `.zip` archive embedded at compile time |
| LZMA | ✅ Built-in | Higher compression for assets (extract to memory at startup) |
| Tar | ✅ Built-in | Alternative archive format |
| GZip | ❌ Not native | Excluded v1 (would require external lib) |
| Zstd | ❌ Not native | Excluded v1 |

Key functions: `CatchPack()` — opens a pack from a memory address (perfect for `IncludeBinary` embedded data), `UncompressPackMemory()` — extract file to memory buffer.

**Verdict:** The embedded asset strategy (compile + bundle) is fully supported. Use `IncludeBinary` to embed a Zip archive at compile time, then `CatchPack()` at runtime to serve files from it.

---

### 3.6 Cipher Library ✅ USEFUL

| Capability | Functions | HTTP Use |
|------------|-----------|----------|
| MD5 hash | `StringFingerprint()` with `#PB_Cipher_MD5` | ETag generation |
| SHA-1 / SHA-256 | `StringFingerprint()` with SHA flags | Strong ETag |
| CRC32 | `CRC32Fingerprint()` | Fast checksum ETag |
| Base64 encode/decode | `Base64Encoder()`, `Base64Decoder()` | Basic Auth header parsing |
| AES | `AESEncoder()`, `AESDecoder()` | Future: session tokens |

**Verdict:** ETag generation, Basic Authentication header parsing, and future security features are all supported natively.

---

### 3.7 Regular Expression Library ✅ FULLY CAPABLE (PCRE)

| Use Case | Status |
|----------|--------|
| Parse HTTP request line (`GET /path HTTP/1.1`) | ✅ |
| Match file extension for MIME type | ✅ (or simpler: `GetExtensionPart()`) |
| Validate header format | ✅ |
| Match hidden path patterns (e.g., `.git`, `*.env`) | ✅ |
| URL path normalization | ✅ |

**Verdict:** Full PCRE support covers all pattern-matching needs for HTTP parsing.

---

### 3.8 Date Library ⚠️ PARTIALLY CAPABLE

| Capability | Status |
|------------|--------|
| Get current UTC timestamp | ✅ `DateUTC()` |
| Get file modification date | ✅ `GetFileDate()` |
| Numeric formatting (`%dd`, `%mm`, `%hh`) | ✅ `FormatDate()` |
| HTTP-date format (`Sat, 14 Mar 2026 12:00:00 GMT`) | ⚠️ **Needs custom helper** |

**Gap Detail:** `FormatDate()` lacks day-name (`Mon`, `Tue`) and month-name (`Jan`, `Feb`) tokens. HTTP `Date:` and `Last-Modified:` headers require RFC 7231 date format.

**Solution:** A small helper function using lookup arrays for day/month names — ~20 lines of PureBasic code.

```purebasic
; Example helper needed:
Procedure.s HTTPDate(timestamp.i)
  Protected days$ = "Sun,Mon,Tue,Wed,Thu,Fri,Sat"
  Protected months$ = "Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec"
  ; Extract parts using Day(), Month(), etc. and build RFC 7231 string
  ProcedureReturn FormatDate("%dd ", timestamp) +
                  StringField(months$, Month(timestamp), ",") + ...
EndProcedure
```

**Verdict:** Solvable with a simple utility function. Not a blocker.

---

### 3.9 Memory Library ✅ FULLY CAPABLE

| Capability | Use |
|------------|-----|
| `AllocateMemory()` / `FreeMemory()` | Allocate buffers for file data, request parsing |
| `ReadData()` into buffer | Load files for serving |
| `CopyMemory()` | Assemble response buffers |
| `MemorySize()` | Check buffer bounds |

**Verdict:** Full low-level memory buffer support for assembling HTTP responses efficiently.

---

### 3.10 String Library ✅ FULLY CAPABLE

All standard string operations available: `Left()`, `Right()`, `Mid()`, `Trim()`, `LCase()`, `UCase()`, `StringField()`, `FindString()`, `ReplaceString()`, `CountString()`, `Split()`, etc. Sufficient for all HTTP header parsing.

---

## 4. Feature Feasibility Matrix (v1.0 Scope)

| Feature | Caddy Equivalent | PureBasic Support | Effort | Notes |
|---------|-----------------|-------------------|--------|-------|
| TCP server listener | `--listen` | ✅ `CreateNetworkServer()` | Low | Direct mapping |
| HTTP/1.1 request parsing | Built-in | ⚠️ Manual implementation | Medium | Parse request line + headers from raw TCP data |
| HTTP/1.1 response builder | Built-in | ⚠️ Manual implementation | Medium | Assemble status line + headers + body |
| Static file serving | `file_server` | ✅ File + Network libs | Low | Read file → send via TCP |
| MIME type detection | Built-in | ⚠️ Manual lookup table | Low | ~40 extension-to-MIME mappings |
| Directory listing / browse | `--browse` | ✅ FileSystem + custom HTML | Medium | Generate HTML listing dynamically |
| Index file fallback | `index` directive | ✅ Manual check | Low | Check index.html, index.htm, etc. |
| Hide files/paths | `hide` directive | ✅ String matching + Regex | Low | Compare path against hidden patterns |
| SPA / pass-through fallback | `pass_thru` | ✅ Manual logic | Low | If file not found → serve index.html |
| ETag header | Built-in | ✅ Cipher (MD5/CRC32) | Low | Hash file content or use size+mtime |
| Last-Modified header | Built-in | ✅ FileDate + custom format | Low | Needs HTTP date helper function |
| Range requests | Built-in | ✅ `FileSeek()` + `ReadData()` | Medium | Parse Range header, seek + partial send |
| Pre-compressed sidecars | `precompressed` | ✅ Manual file check | Low | Check if `.gz` sidecar exists → serve it |
| Embedded assets (bundled app) | N/A (Caddy serves disk) | ✅ `IncludeBinary` + `CatchPack` | Medium | Zip assets → embed → serve from memory |
| Concurrent connections | Default in Caddy | ✅ Thread library | Medium | Thread-per-connection or thread pool |
| Access logging | `--access-log` | ✅ File + Date libs | Low | Write to log file with mutex |
| Configurable port | `--listen` | ✅ `CreateNetworkServer()` | Low | Direct parameter |
| HTTP date formatting | Built-in | ⚠️ Custom helper needed | Low | ~20-line utility function |
| URL decoding (percent encoding) | Built-in | ✅ `URLDecoder()` | Low | Direct function available |
| Query string parsing | Built-in | ✅ `GetURLPart()` + String | Low | Parse after `?` in URL |
| Keep-Alive connections | Default | ⚠️ Manual implementation | High | Parse `Connection:` header; reuse socket |
| Graceful shutdown | Built-in | ✅ `CloseNetworkServer()` | Low | Clean close on signal |

---

## 5. Key Implementation Challenges

### 5.1 HTTP Request Parser (Medium Complexity)
The core challenge. Must handle:
- Request line: `METHOD /path?query HTTP/1.1`
- Headers: key-value pairs, one per line, terminated by `\r\n\r\n`
- Partial reads: TCP data may arrive in chunks — need a state machine or buffer accumulator

**Approach:** Accumulate `ReceiveNetworkData()` into a growing memory buffer until `\r\n\r\n` is found, then parse line by line using `StringField()` and `FindString()`.

### 5.2 MIME Type Table (Low Complexity, Medium Effort)
No built-in MIME detection. A static `Map` of extensions is sufficient:

```purebasic
Global MimeTypes.s{256}

; Initialize map entries:
; "html" → "text/html; charset=utf-8"
; "css"  → "text/css"
; "js"   → "application/javascript"
; "png"  → "image/png"
; "jpg"  → "image/jpeg"
; "svg"  → "image/svg+xml"
; "woff2"→ "font/woff2"
; "mp4"  → "video/mp4"
; ... ~40 entries total
```

### 5.3 Embedded Asset Strategy (Medium Complexity)
The key differentiator for the target use case:

1. At build time: pack web app files into a Zip archive
2. Use `IncludeBinary "webapp.zip"` to embed the archive in the executable
3. At runtime: `CatchPack(#Pack, ?webapp, ?webapp_end - ?webapp)` to open in-memory
4. On request: `UncompressPackMemory()` to extract file into buffer → serve via TCP

This makes the final executable fully self-contained with no external file dependencies.

### 5.4 Concurrency Model (Medium Complexity)
Recommended approach for v1.0: **thread-per-connection** (simpler than a thread pool).

```
Main Thread → NetworkServerEvent() loop
  → New connection event → CreateThread(@HandleConnection, connectionID)
  → HandleConnection thread: parse request → serve response → close
```

Access to shared state (log file, config, asset pack) requires mutex protection.

### 5.5 HTTP Date Helper (Low Complexity)
As noted in §3.8, a custom `HTTPDate()` function is needed. This is a ~20-line utility — not a blocker at all.

---

## 6. What PureBasic Cannot Do Natively (v1.0 Scope)

| Limitation | Workaround |
|------------|------------|
| No server-side HTTP library | Hand-implement HTTP/1.1 parser — well-documented spec |
| No GZip / Zstd compression | Excluded from v1. Could link C library via `ImportC` in future |
| No native MIME detection | Static lookup `Map` in code |
| No RFC 7231 date format in `FormatDate()` | Custom `HTTPDate()` helper function |
| No built-in HTTP/2 | Out of scope for this tool's purpose |
| No Keep-Alive connection reuse (optional) | Simpler to close after each request in v1 |

---

## 7. Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| HTTP parser edge cases (malformed requests) | Medium | Medium | Strict input validation; return 400 on parse error |
| Memory leaks in thread-per-connection model | Medium | High | Free all allocated buffers before thread exit; use `FreeMemory()` consistently |
| Large file serving performance | Low | Medium | Use `ReadData()` in chunks (e.g., 64KB) instead of loading whole file |
| Thread-safe PureBasic compiler required | Low | High | Document build requirement; use `EnableExplicit` + threaded mode |
| Platform differences (Windows vs macOS vs Linux) | Low | Low | PureBasic is cross-platform; Network/File libs abstract OS differences |

---

## 8. v1.0 Development Roadmap

### Phase A — Foundation (Core TCP + HTTP Parser)
- [ ] Raw TCP server with `CreateNetworkServer()` event loop
- [ ] HTTP/1.1 request parser: method, path, query string, headers
- [ ] HTTP/1.1 response builder: status line, headers, body
- [ ] URL decoding via `URLDecoder()`
- [ ] Custom `HTTPDate()` RFC 7231 formatter

### Phase B — File Serving
- [ ] MIME type lookup table (~40 entries)
- [ ] Static file reading and serving from disk
- [ ] Index file fallback (`index.html`, `index.htm`)
- [ ] 404 / 403 / 500 error responses with default HTML pages
- [ ] ETag header (CRC32 of file content)
- [ ] Last-Modified header

### Phase C — Features
- [ ] Directory listing (HTML-rendered browse mode)
- [ ] SPA fallback mode (serve `index.html` for 404s)
- [ ] Hidden path filtering (`.git`, `*.env`, etc.)
- [ ] Range request support (for video streaming)
- [ ] Pre-compressed sidecar serving (check `.gz` before plain file)

### Phase D — Embedded Assets
- [ ] Zip-pack web application assets
- [ ] `IncludeBinary` embedding strategy
- [ ] `CatchPack()` + `UncompressPackMemory()` in-memory serving
- [ ] Fallback to disk serving when no embedded pack

### Phase E — Concurrency & Production
- [ ] Thread-per-connection model with mutex-protected shared state
- [ ] Access log file with timestamp, method, path, status, bytes
- [ ] Graceful shutdown handler
- [ ] Configurable settings (port, root, index list, hidden paths, browse on/off)

---

## 9. Conclusion

**Overall Feasibility: HIGH ✅**

PureBasic is well-suited for this project. All required building blocks exist in the standard library. The implementation work is primarily writing the HTTP/1.1 protocol layer from scratch — which is a well-understood, finite task. The embedded asset capability via `IncludeBinary` + `CatchPack()` is a particularly elegant fit for the stated goal of a single self-contained binary.

The total estimated scope for a working v1.0 is approximately **1,500–2,500 lines of PureBasic** covering the parser, response builder, file server logic, threading, and embedded asset serving.

The excluded features (HTTPS, GZip) are not blockers for the intended use case (local/intranet serving of a compiled web app), and both can be added in a future phase using libraries that PureBasic already ships (`UseNetworkTLS` for HTTPS, external C library link for GZip).

---

*Generated as part of PureSimpleHTTPServer project planning · 2026-03-14*
