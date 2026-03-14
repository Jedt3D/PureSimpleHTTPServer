# Extending PureSimpleHTTPServer

This document is a developer reference for extending PureSimpleHTTPServer v1.5.0.
It covers the four primary extension points — custom request handlers, new CLI
flags, new source modules, and middleware layers — as well as the embedded asset
workflow for shipping a compiled-in web application.

---

## 1. Overview

The server's architecture is deliberately flat. There is no plugin system or
framework — the extension points are simply call sites in `src/main.pb` where
you swap in your own procedure, add a branch, or insert a new module. The
relevant extension points are:

| What you want to do | Where to touch |
|---------------------|----------------|
| Replace or augment the HTTP request handler | `g_Handler` function pointer in `main.pb` |
| Add a new command-line flag | `Types.pbi`, `Config.pbi`, startup banner in `main.pb`, test in `test_config.pb` |
| Add a new source module | `src/NewModule.pbi`, include in `main.pb` and `tests/TestCommon.pbi` |
| Insert processing between parse and file-serve | `HandleRequest()` in `main.pb` |
| Serve a compiled-in web application | `DataSection` / `IncludeBinary` + `OpenEmbeddedPack()` |

---

## 2. Adding a Custom Request Handler

### The g_Handler function pointer

`TcpServer.pbi` declares a global function pointer with a typed prototype:

```purebasic
Prototype.i ConnectionHandlerProto(connection.i, raw.s)
Global g_Handler.ConnectionHandlerProto
```

`StartServer()` dispatches every complete HTTP request to this pointer. You assign
it in `main.pb` before calling `StartServer()`:

```purebasic
g_Handler = @HandleRequest()
```

To replace the handler entirely, write a procedure with the same signature,
assign it to `g_Handler`, and remove (or call from within) the original:

```purebasic
Procedure.i MyHandler(connection.i, raw.s)
  Protected req.HttpRequest

  If Not ParseHttpRequest(raw, req)
    SendTextResponse(connection, #HTTP_400, "text/plain; charset=utf-8", "400 Bad Request")
    ProcedureReturn #False
  EndIf

  ; ... your handling logic ...
  ProcedureReturn #True
EndProcedure

; In Main():
g_Handler = @MyHandler()
```

### Accessing the parsed request

`ParseHttpRequest(raw, req)` fills an `HttpRequest` structure (defined in
`Types.pbi`):

```purebasic
Structure HttpRequest
  Method.s           ; "GET", "POST", "HEAD", etc.
  Path.s             ; Decoded, normalized URL path — no query string
  QueryString.s      ; Raw query string (after "?"), or ""
  Version.s          ; "HTTP/1.1" or "HTTP/1.0"
  RawHeaders.s       ; Raw header lines, CRLF-separated
  ContentLength.i    ; Value of Content-Length, or 0
  Body.s             ; Request body (POST data), or ""
  IsValid.i          ; #True if parsed successfully
  ErrorCode.i        ; 400 on parse failure
EndStructure
```

Extract individual header values with `GetHeader()` from `HttpParser.pbi`:

```purebasic
Protected authHeader.s = GetHeader(req\RawHeaders, "Authorization")
Protected accept.s     = GetHeader(req\RawHeaders, "Accept")
```

`GetHeader()` is case-insensitive on the header name and returns `""` when the
header is absent.

### Sending a custom response

**For text responses** (HTML, JSON, plain text), use `SendTextResponse()` from
`HttpResponse.pbi`. It handles UTF-8 byte length correctly and adds
`Content-Length`:

```purebasic
Protected body.s = ~"{\"status\":\"ok\"}"
SendTextResponse(connection, #HTTP_200, "application/json; charset=utf-8", body)
```

**For responses requiring extra headers** (redirects, custom cache control, etc.),
build the header block manually and send it with `SendNetworkString()`:

```purebasic
Protected extra.s = "Location: /new-path" + #CRLF$ + "Cache-Control: no-store" + #CRLF$
SendNetworkString(connection, BuildResponseHeaders(#HTTP_301, extra, 0), #PB_Ascii)
```

`BuildResponseHeaders(statusCode, extraHeaders, bodyLen)` always appends the
`Server:`, `Content-Length:`, and `Connection: close` headers. Each line in
`extraHeaders` must end with `#CRLF$`.

**For binary responses** (files, buffers), send the header block as ASCII and
the body with `SendNetworkData()`:

```purebasic
Protected *buffer = ...   ; pointer to binary data
Protected size.i  = ...   ; byte count
Protected extra.s = "Content-Type: image/png" + #CRLF$
SendNetworkString(connection, BuildResponseHeaders(#HTTP_200, extra, size), #PB_Ascii)
SendNetworkData(connection, *buffer, size)
FreeMemory(*buffer)
```

---

## 3. Adding a New CLI Flag

Adding a flag requires changes in four places and a matching test.

### Step 1 — Add a field to ServerConfig in Types.pbi

Open `src/Types.pbi` and add your field to `Structure ServerConfig`:

```purebasic
Structure ServerConfig
  ; ... existing fields ...
  MyNewOption.i    ; #True if --my-flag was passed
EndStructure
```

Use `.i` for booleans and integers, `.s` for file paths or string values.
Place the field after the existing fields; PureBasic structures are sequential
and there is no padding issue.

### Step 2 — Set the default in LoadDefaults() in Config.pbi

Open `src/Config.pbi` and add a default assignment in `LoadDefaults()`:

```purebasic
Procedure LoadDefaults(*cfg.ServerConfig)
  ; ... existing defaults ...
  *cfg\MyNewOption = #False
EndProcedure
```

Always set a safe default so the server works correctly when the flag is
absent.

### Step 3 — Parse the flag in ParseCLI() in Config.pbi

Add an `ElseIf` branch in the `While i < count` parsing loop:

```purebasic
ElseIf param = "--my-flag"
  *cfg\MyNewOption = #True
```

For flags that take a value, consume the next parameter:

```purebasic
ElseIf param = "--my-value"
  i + 1
  If i >= count : ProcedureReturn #False : EndIf
  *cfg\MyStringValue = ProgramParameter(i)
```

Always guard the lookahead with `If i >= count : ProcedureReturn #False : EndIf`
to return a clean error when the flag is given without a value.

For numeric flags, validate the range before accepting:

```purebasic
ElseIf param = "--timeout"
  i + 1
  If i >= count : ProcedureReturn #False : EndIf
  Protected tval.i = Val(ProgramParameter(i))
  If tval < 1 Or tval > 3600 : ProcedureReturn #False : EndIf
  *cfg\TimeoutSecs = tval
```

### Step 4 — Print the value in the startup banner in main.pb

Find the startup banner section in `Main()` (the `PrintN(#APP_NAME ...)` block)
and add a line for your flag so operators can see it is active:

```purebasic
If g_Config\MyNewOption
  PrintN("My flag:    enabled")
EndIf
```

### Step 5 — Write a test in test_config.pb

Add a `ProcedureUnit` that confirms the default value:

```purebasic
ProcedureUnit Config_LoadDefaults_MyNewOption()
  Protected cfg.ServerConfig
  LoadDefaults(@cfg)
  Assert(cfg\MyNewOption = #False, "MyNewOption should be #False by default")
EndProcedureUnit
```

Do not write a test that calls `ParseCLI()` and asserts on its return value —
see the `ProgramParameter()` pitfall in `TESTING.md`.

---

## 4. Adding a New Module

### File naming and placement

Create the file as `src/MyFeature.pbi`. PureBasic convention in this project is
that `.pbi` files are includes (not standalone compilable units) and `.pb` files
are entry points. All modules use `EnableExplicit` at the top and declare their
public API as top-level `Procedure` definitions (no namespacing — PureBasic does
not have modules/namespaces).

```purebasic
; MyFeature.pbi — brief description of what this module provides
; Include with: XIncludeFile "MyFeature.pbi"
; Provides: MyFeatureInit(), MyFeatureProc(), MyFeatureCleanup()
; Dependencies (managed by main.pb and tests/TestCommon.pbi): Global.pbi, Types.pbi
EnableExplicit

Procedure.i MyFeatureProc(input.s)
  ; ...
  ProcedureReturn result
EndProcedure
```

### Include order

PureBasic resolves names at the point they are declared — there is no link-time
symbol resolution. The `XIncludeFile` chain in `src/main.pb` is the authoritative
include order. Add your module's include after any modules it depends on:

```purebasic
; In src/main.pb, after your dependencies:
XIncludeFile "MyFeature.pbi"
```

Then add the same line in the same relative position in `tests/TestCommon.pbi`:

```purebasic
; In tests/TestCommon.pbi:
XIncludeFile "../src/MyFeature.pbi"
```

The paths in `TestCommon.pbi` use `../src/` because PureUnit runs from the
`tests/` directory.

### Forward declarations for circular dependencies

If your module calls a procedure defined in a module that is included *after* it
(because that later module depends on yours), you must forward-declare the called
procedure. `FileServer.pbi` demonstrates this:

```purebasic
; Forward declarations for modules included after this file
Declare.s BuildDirectoryListing(dirPath.s, urlPath.s)
Declare.i ParseRangeHeader(header.s, fileSize.i, *range.RangeSpec)
Declare.i SendPartialResponse(connection.i, fsPath.s, *range.RangeSpec, mimeType.s, fileSize.i)
```

Place `Declare` statements at the top of the file that needs them, before the
first procedure that uses the forward-declared name.

### PureUnit-compatible global storage

If your module needs global data structures beyond scalar variables, follow the
`AllocateMemory` pattern from `RewriteEngine.pbi` — never use `Global Dim` or
`Global NewList`/`Global NewMap` at file scope. See `TESTING.md` section 4 for
the full explanation. The pattern in brief:

```purebasic
; WRONG — crashes under PureUnit
Global Dim g_Items.MyStruct(99)

; CORRECT
Global g_ItemsMem.i    ; raw pointer to memory block
Global g_ItemCount.i

Procedure InitMyFeature()
  g_ItemsMem  = AllocateMemory(100 * SizeOf(MyStruct))
  g_ItemCount = 0
EndProcedure

Procedure CleanupMyFeature()
  If g_ItemsMem = 0 : ProcedureReturn : EndIf
  FreeMemory(g_ItemsMem)
  g_ItemsMem  = 0
  g_ItemCount = 0
EndProcedure
```

Call `InitMyFeature()` from `Main()` in `main.pb` before `StartServer()`, and
`CleanupMyFeature()` in both the success and failure shutdown paths.

---

## 5. Adding a Middleware Layer

"Middleware" in this codebase means code that runs inside `HandleRequest()` after
`ParseHttpRequest()` and before `ServeFile()`. There is no formal middleware
interface — you simply add code in the right place.

### Existing middleware: rewrite engine and logger

`HandleRequest()` in `main.pb` already contains two middleware-like layers:

1. **RewriteEngine** — applied before serving; can rewrite the path or redirect
   the client entirely.
2. **Logger** — called after serving to write the access log line.

### Example: auth header check

To require a bearer token on all requests, insert the check after parsing and
before the rewrite engine:

```purebasic
Procedure.i HandleRequest(connection.i, raw.s)
  Protected req.HttpRequest
  Protected clientIP.s = IPString(GetClientIP(connection))
  ; ...

  If Not ParseHttpRequest(raw, req)
    SendTextResponse(connection, #HTTP_400, "text/plain; charset=utf-8", "400 Bad Request")
    ProcedureReturn #False
  EndIf

  ; --- Auth middleware ---
  Protected auth.s = GetHeader(req\RawHeaders, "Authorization")
  If auth <> "Bearer mysecrettoken"
    SendTextResponse(connection, #HTTP_403, "text/plain; charset=utf-8", "403 Forbidden")
    LogAccess(clientIP, req\Method, req\Path, req\Version, #HTTP_403, 0, "", "")
    ProcedureReturn #False
  EndIf
  ; --- End auth middleware ---

  ; ... rewrite engine, ServeFile, etc. ...
EndProcedure
```

### Example: request logging middleware

The existing logger is already an "after" middleware — it runs after `ServeFile()`
to record the status and byte count. The pattern for a "before" logger (e.g. for
debugging) would insert a `LogError("info", ...)` call before the rewrite engine:

```purebasic
LogError("info", req\Method + " " + req\Path + " from " + clientIP)
```

This writes to the error log (not the access log) because `LogError()` is the
only logging call available before the response status and byte count are known.

### Inserting between rewrite and file serving

The exact call sequence in `HandleRequest()` is:

1. `ParseHttpRequest()` — produces the `req` structure.
2. `ApplyRewrites()` — may modify `req\Path` or send a redirect.
3. `ServeEmbeddedFile()` — tries the in-memory asset pack.
4. `ServeFile()` — serves from disk.
5. `LogAccess()` — records the access log entry.

To insert processing between the rewrite engine and file serving, add your code
between steps 2 and 3. You have access to the fully parsed and rewritten `req`
at that point.

---

## 6. Embedding a Web Application

This section covers the full workflow for shipping a web application inside the
server binary. The build mechanics are also described in `BUILDING.md`; this
section focuses on the code-level integration.

### Workflow overview

1. Build your frontend into a distribution directory (e.g. `dist/`).
2. Pack it into a `.zip` with `scripts/pack_assets.sh`.
3. Add `UseZipPacker()`, a `DataSection` block, and update the
   `OpenEmbeddedPack()` call in `main.pb`.
4. Recompile.

### OpenEmbeddedPack() / ServeEmbeddedFile() / CloseEmbeddedPack()

All three procedures are in `src/EmbeddedAssets.pbi`.

**Opening the pack at startup:**

```purebasic
UseZipPacker()

DataSection
  webapp:    IncludeBinary "webapp.zip"
  webappEnd:
EndDataSection

; In Main(), before StartServer():
OpenEmbeddedPack(?webapp, ?webappEnd - ?webapp)
```

`OpenEmbeddedPack()` calls `CatchPack(#PB_Any, *packData, packSize)` from
PureBasic's packer library. The `g_EmbeddedPack` global is set to the returned
handle, which is checked by `ServeEmbeddedFile()` on every request.

**Serving a file from the pack:**

`ServeEmbeddedFile(connection, urlPath)` is already called in `HandleRequest()`
before `ServeFile()`. It strips the leading `/` from the URL path to get the
pack-relative path and calls `UncompressPackMemory()` with a 4 MB ceiling buffer.

```purebasic
; In HandleRequest():
If ServeEmbeddedFile(connection, req\Path)
  LogAccess(...)
  ProcedureReturn #True
EndIf
; Falls through to ServeFile() if not in pack
```

If the file is not found in the pack (e.g. a path that only exists on disk),
`ServeEmbeddedFile()` returns `#False` and normal disk serving proceeds. This
means you can mix embedded and disk assets — embedded assets are tried first.

**Closing the pack at shutdown:**

```purebasic
; Already called in Main() on both success and failure exit paths:
CloseEmbeddedPack()
```

`CloseEmbeddedPack()` calls `ClosePack()` and resets `g_EmbeddedPack` to 0. It
is safe to call when no pack is open.

### Fallback to disk (development mode)

During frontend development you do not want to repack and recompile on every
change. Leave `OpenEmbeddedPack()` called with the default zero arguments (or
simply do not add the `DataSection` block). When `g_EmbeddedPack` is 0,
`ServeEmbeddedFile()` returns `#False` immediately without touching the pack,
and all requests fall through to `ServeFile()`. Point `--root` at your live
build output directory and edit freely.

### scripts/pack_assets.sh usage

```
./scripts/pack_assets.sh <assets_dir> <output_zip>
```

Example — build a React app and pack it:

```
npm run build                                       # produces dist/
./scripts/pack_assets.sh dist/ src/webapp.zip
pbcompiler -cl -t -z -o PureSimpleHTTPServer src/main.pb
```

The script runs `zip -r` from inside `<assets_dir>`, so the archive contains
paths relative to that directory. A file at `dist/css/app.css` becomes
`css/app.css` in the zip, and `ServeEmbeddedFile()` serves it when the client
requests `/css/app.css`.

The script excludes `.DS_Store` files and `__MACOSX/` metadata that macOS adds
to zips. If your frontend build tool produces other unwanted files (source maps,
`.map` files, etc.), pass additional `--exclude` patterns directly to `zip` by
modifying the script or using `zip` manually.

### Path mapping

| URL path | Pack path looked up |
|----------|---------------------|
| `/` | `index.html` (hardcoded fallback in `ServeEmbeddedFile`) |
| `/index.html` | `index.html` |
| `/css/app.css` | `css/app.css` |
| `/js/bundle.js.map` | `js/bundle.js.map` |

The 4 MB per-file buffer ceiling in `ServeEmbeddedFile()` is suitable for most
web application assets. If you embed very large files (video, large WASM blobs),
you will need to increase `maxSize` in `EmbeddedAssets.pbi`.
