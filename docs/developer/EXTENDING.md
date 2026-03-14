# PureSimpleHTTPServer v1.5.0 — Extension Guide

This document is a developer reference for extending PureSimpleHTTPServer v1.5.0.
The target audience is PureBasic developers who have the source SDK and want to
add new features — flags, handlers, MIME types, middleware, new modules, or
embedded asset workflows.

---

## 1. Adding a New CLI Flag

CLI flags are parsed in `Config.pbi` by `ParseCLI(*cfg.ServerConfig)` and stored
in the `ServerConfig` structure defined in `Types.pbi`.

### Step 1 — Add a field to `ServerConfig` in `Types.pbi`

```purebasic
Structure ServerConfig
  ; ... existing fields ...
  CorsEnabled.i    ; #True to add CORS headers to every response
EndStructure
```

### Step 2 — Set a default in `LoadDefaults` in `Config.pbi`

```purebasic
Procedure LoadDefaults(*cfg.ServerConfig)
  ; ... existing defaults ...
  *cfg\CorsEnabled = #False
EndProcedure
```

### Step 3 — Parse the flag in `ParseCLI` in `Config.pbi`

Add an `ElseIf` branch in the `While i < count` loop, following the existing
pattern. Boolean flags take no argument; value flags advance `i` first:

```purebasic
; Boolean flag — no argument
ElseIf param = "--cors"
  *cfg\CorsEnabled = #True

; Value flag — advance i and read next token
ElseIf param = "--cors-origin"
  i + 1
  If i >= count : ProcedureReturn #False : EndIf
  *cfg\CorsOrigin = ProgramParameter(i)
```

### Step 4 — Use the field in `main.pb`

After `ParseCLI` returns, read the new field from `g_Config` and apply it
before calling `StartServer`:

```purebasic
If g_Config\CorsEnabled
  ; configure CORS headers, etc.
EndIf
```

---

## 2. Adding a New HTTP Handler

The server's single dispatch point is the `g_Handler` function pointer defined
in `TcpServer.pbi`:

```purebasic
Prototype.i ConnectionHandlerProto(connection.i, raw.s)
Global g_Handler.ConnectionHandlerProto
```

`HandleRequest` in `main.pb` is the built-in implementation. It follows this
sequence for every request:

1. `ParseHttpRequest(raw, req)` — parse into `HttpRequest`.
2. `ApplyRewrites(req\Path, ...)` — rewrite or redirect.
3. `ServeEmbeddedFile(connection, req\Path)` — serve from embedded pack.
4. `ServeFile(connection, @g_Config, @req, ...)` — serve from disk.
5. `LogAccess(...)` — write access log entry.

### Adding a handler before the disk-serve step

To intercept requests before `ServeFile` — for example, to implement a simple
dynamic route — write a wrapper around `HandleRequest`:

```purebasic
Procedure.i MyHandleRequest(connection.i, raw.s)
  Protected req.HttpRequest
  If Not ParseHttpRequest(raw, req) : ProcedureReturn #False : EndIf

  ; Custom route
  If req\Method = "GET" And req\Path = "/api/status"
    SendTextResponse(connection, #HTTP_200, "application/json", ~"{\"status\":\"ok\"}")
    LogAccess(NetworkClientIP(connection), req\Method, req\Path,
              req\Version, #HTTP_200, 14, "", "")
    ProcedureReturn #True
  EndIf

  ; Fall through to built-in handler for everything else
  ProcedureReturn HandleRequest(connection, raw)
EndProcedure
```

Then assign it before `StartServer`:

```purebasic
g_Handler = @MyHandleRequest()
StartServer(g_Config\Port)
```

Because `g_Handler` is a function pointer, the original `HandleRequest` remains
callable as a named procedure from your wrapper at no extra cost.

### Replacing the handler entirely

If you do not need the built-in disk-serve logic, assign your own procedure
directly and implement the full parse-respond-log cycle yourself. The built-in
`HandleRequest` body in `main.pb` serves as the canonical example.

---

## 3. Adding Middleware-Style Processing Before `ServeFile`

`ServeFile` is a regular procedure called from `HandleRequest`. To run
middleware logic before it — header injection, authentication checks, rate
limiting — insert calls between `ApplyRewrites` and `ServeFile` in your custom
handler:

```purebasic
; After rewrite, before disk serve:
If Not CheckAuthentication(@req)
  SendTextResponse(connection, #HTTP_403, "text/plain; charset=utf-8", "403 Forbidden")
  ProcedureReturn #False
EndIf

; Proceed to normal file serving
ServeFile(connection, @g_Config, @req, @bytesOut, @statusCode)
```

`ServeFile` accepts optional `*bytesOut` and `*statusOut` pointer arguments.
Pass pointers to local variables if you need the byte count and final status
for your access log call.

---

## 4. How Rewrite Rules Integrate

`ApplyRewrites` is called in `HandleRequest` before both embedded-asset and
disk-serve steps. Its full signature:

```purebasic
Procedure.i ApplyRewrites(path.s, docRoot.s, *result.RewriteResult)
```

Returns `#True` when a rule matched; fills `*result\Action`:

- `Action = 1` (rewrite): update `req\Path` to `result\NewPath` and continue
  to `ServeFile`. Strip a query string from `NewPath` if `?` is present and
  preserve it in `req\QueryString`.
- `Action = 2` (redirect): send a 301 or 302 using `BuildResponseHeaders` and
  a `Location:` header and return immediately.

The built-in `HandleRequest` in `main.pb` demonstrates both cases. To add
rewrite rules at runtime without restarting, call:

```purebasic
LoadGlobalRules("/etc/pshs/rewrite.conf")
```

This acquires `g_RewriteMutex`, frees the existing global rule set, and loads
from the file. Worker threads already evaluating rules will finish their current
evaluation first.

Per-directory `rewrite.conf` files are loaded automatically on demand by
`ApplyRewrites` when a file exists at `docRoot + urlDir + "/rewrite.conf"`.
The cache is invalidated by mtime change, so per-directory rules update without
a server restart.

---

## 5. Adding a New MIME Type

`MimeTypes.pbi` uses a single `Select/Case` block. Add a `Case` line in the
appropriate group:

```purebasic
Procedure.s GetMimeType(extension.s)
  Select extension
    ; ... existing cases ...
    Case "glb"           : ProcedureReturn "model/gltf-binary"
    Case "gltf"          : ProcedureReturn "model/gltf+json"
    Default              : ProcedureReturn "application/octet-stream"
  EndSelect
EndProcedure
```

The `extension` parameter is always lowercase and without a leading dot, as
normalized by `LCase(GetExtensionPart(fsPath))` in `ServeFile`. No other
changes are needed — `GetMimeType` is called from both `ServeFile` and
`ServeEmbeddedFile`.

---

## 6. Adding a Custom Response Type

If you need a response type that `BuildResponseHeaders` + `SendNetworkData`
does not cover (for example, chunked transfer encoding or server-sent events),
write a new procedure in `HttpResponse.pbi` following the existing pattern:

```purebasic
; SendBinaryResponse — send a binary buffer with a custom content type
Procedure SendBinaryResponse(connection.i, statusCode.i, contentType.s,
                              *data, dataLen.i)
  Protected extra.s = "Content-Type: " + contentType + #CRLF$
  SendNetworkString(connection, BuildResponseHeaders(statusCode, extra, dataLen),
                    #PB_Ascii)
  If dataLen > 0
    SendNetworkData(connection, *data, dataLen)
  EndIf
EndProcedure
```

`BuildResponseHeaders` always adds `Connection: close`, so the client will
close after the response. If you need keep-alive, bypass `BuildResponseHeaders`
and assemble the header block manually.

---

## 7. Adding a New Module

### Naming conventions

- File name: lowercase with camelcase, `.pbi` extension (e.g.
  `AuthMiddleware.pbi`).
- Begin with `EnableExplicit` and a comment header giving the module name,
  purpose, provided symbols, and dependencies.
- Name all private (module-internal) procedures with a trailing underscore
  (e.g. `HashPassword_()`). PureBasic has no visibility modifiers; the
  underscore is a convention.

### `EnableExplicit`

Every module must begin with `EnableExplicit`. This requires every variable to
be declared before use, preventing typo-induced bugs that are otherwise silent
in PureBasic.

### `XIncludeFile` order in `main.pb`

Insert the `XIncludeFile` line at the point in `main.pb`'s include list where
all your module's dependencies are already included. Refer to the module map in
`ARCHITECTURE.md` for the current order. Because `XIncludeFile` is idempotent,
the position only matters for forward-declaration resolution.

If your module calls procedures from a module that appears later in the include
list, add forward `Declare` statements at the top of your module, as
`FileServer.pbi` does for `BuildDirectoryListing`, `ParseRangeHeader`, and
`SendPartialResponse`.

### Add the module to `TestCommon.pbi`

```purebasic
; tests/TestCommon.pbi — add after its last dependency:
XIncludeFile "../src/AuthMiddleware.pbi"
```

Then create `tests/test_authmiddleware.pb` and verify with `run_tests.sh`.

### Global variable rules

Only scalar `Global` variables (`.i`, `.s`, `.q`, etc.) are safe in modules
that will be unit-tested with PureUnit. See `TESTING.md` section 4 for the
full explanation of why `Global Dim` arrays and `Global NewList`/`Global NewMap`
crash under PureUnit, and how to replace them with `AllocateMemory` blocks.

---

## 8. Thread Safety

### What is protected

| Resource | Mutex | Notes |
|---|---|---|
| `g_LogFile`, `g_ErrorLogFile`, all rotation state | `g_LogMutex` | Both log files share one mutex |
| All rewrite rule arrays and per-directory cache | `g_RewriteMutex` | Acquired by `ApplyRewrites`, `LoadGlobalRules`, `GlobalRuleCount` |
| `g_CloseList` | `g_CloseMutex` | Worker threads push; main thread pops |

### What is safe to read without a mutex

- `g_Config` — written once by `ParseCLI` on the main thread before
  `StartServer` is called; treated as read-only from that point. All modules
  receive a `*cfg.ServerConfig` pointer; no module reads `g_Config` directly
  except `HandleRequest` in `main.pb`.
- `g_Handler` — set once before `StartServer`. Never written by worker threads.
- `g_EmbeddedPack` — set once by `OpenEmbeddedPack` before `StartServer`.
  `ServeEmbeddedFile` reads it from worker threads; no write happens at runtime.

### Adding new shared state

If your extension requires state that is read and written by both the main
thread and worker threads:

1. Declare a mutex as a `Global .i` variable in your module.
2. Create it in your `Init*()` procedure with `CreateMutex()`.
3. Wrap every read and write (not just writes) that could race with
   `LockMutex` / `UnlockMutex`.
4. Document the mutex in the module's comment header and in `ARCHITECTURE.md`'s
   mutex inventory.

Do not call `CloseNetworkConnection` from worker threads. See `ARCHITECTURE.md`
section 4 for the explanation of the close-queue pattern.

---

## 9. Compiling with Embedded Assets

Embedded assets allow you to ship a compiled-in web application so that the
binary requires no separate file deployment.

### Build time

Pack your web application's dist directory into a ZIP archive. The scripts
directory provides a helper:

```bash
scripts/pack_assets.sh dist/ webapp.zip
```

### Source changes in `main.pb`

Add `UseZipPacker()` near the top of `main.pb` (before any `DataSection`) and
embed the archive in a `DataSection` block:

```purebasic
UseZipPacker()

DataSection
  webapp:    IncludeBinary "webapp.zip"
  webappEnd:
EndDataSection
```

The `?webapp` and `?webappEnd` label addresses let PureBasic compute the
embedded data pointer and size at compile time.

### Opening the pack at startup

In `Main()`, call `OpenEmbeddedPack` before `StartServer`:

```purebasic
OpenEmbeddedPack(?webapp, ?webappEnd - ?webapp)
StartServer(g_Config\Port)
```

### Runtime behavior

`HandleRequest` calls `ServeEmbeddedFile(connection, req\Path)` before
`ServeFile`. `ServeEmbeddedFile` strips the leading `/` to form a
pack-relative path (e.g. `"/css/app.css"` becomes `"css/app.css"`), and calls
`UncompressPackMemory` to decompress directly into a 4 MB heap buffer. If the
path is not found in the pack, the function returns `#False` and `HandleRequest`
falls through to disk serving.

This means filesystem files always override embedded assets during development:
place your overrides in the document root directory and they will be served
instead of the packed versions.

### Closing the pack at shutdown

Call `CloseEmbeddedPack()` in your shutdown sequence after `StopServer` returns.

---

## 10. Embedding the Server In-Process

You can incorporate PureSimpleHTTPServer into a larger PureBasic application
(for example, to expose an HTTP API alongside a GUI).

### Include order

In your application's main file, include all server modules in the same
dependency order used by `main.pb`:

```purebasic
XIncludeFile "src/Global.pbi"
XIncludeFile "src/Types.pbi"
; ... all modules in order ...
XIncludeFile "src/SignalHandler.pbi"
```

### Startup sequence

```purebasic
; 1. Load and apply configuration
Protected cfg.ServerConfig
LoadDefaults(@cfg)
cfg\Port          = 9000
cfg\RootDirectory = "/srv/www"
; (set any other fields as needed)

; 2. Open log files (optional)
If cfg\LogFile <> "" : OpenLogFile(cfg\LogFile) : EndIf
If cfg\ErrorLogFile <> "" : OpenErrorLog(cfg\ErrorLogFile) : EndIf
g_ServerPID = GetPID()   ; requires your own ImportC or platform call

; 3. Initialize rewrite engine if using rewrite rules
InitRewriteEngine()
If cfg\RewriteFile <> "" : LoadGlobalRules(cfg\RewriteFile) : EndIf

; 4. Open embedded pack if using one
OpenEmbeddedPack(?webapp, ?webappEnd - ?webapp)

; 5. Assign request handler and start server
g_Handler = @HandleRequest()
InstallSignalHandlers()
StartServer(cfg\Port)   ; blocks until StopServer() is called
```

### Shutdown sequence

`StartServer` blocks. To stop the server from another thread or a signal
handler, call `StopServer()`. After `StartServer` returns:

```purebasic
RemoveSignalHandlers()
StopDailyRotation()
CloseLogFile()
CloseErrorLog()
CloseEmbeddedPack()
CleanupRewriteEngine()
```

### Running `StartServer` on a background thread

If your application has its own main loop (e.g. a PureBasic window event loop),
run the server on a background thread:

```purebasic
Global g_ServerThread.i

Procedure ServerThreadProc(*unused)
  g_Handler = @HandleRequest()
  StartServer(g_Config\Port)
EndProcedure

g_ServerThread = CreateThread(@ServerThreadProc(), 0)
```

To shut the server down cleanly, call `StopServer()` from your main thread and
then `WaitThread(g_ServerThread)`.

Note that `CloseNetworkConnection` is called from the main server event loop
inside `StartServer`. When the server runs on a background thread, that
background thread becomes the "main thread" for network close operations.
Do not call `CloseNetworkConnection` from any other thread.
