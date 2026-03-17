# PureSimpleHTTPServer v2.5.0 — Extension Guide

This document is a developer reference for extending PureSimpleHTTPServer.
The target audience is PureBasic developers who have the source and want to
add new features — middleware, CLI flags, MIME types, or embedded asset workflows.

> **Prerequisites:** Read the [Developer Guide](../developer-guide.md) for the
> middleware architecture and [BUILD_OUR_HTTP_SERVER.md](BUILD_OUR_HTTP_SERVER.md)
> for a walkthrough of `main.pb`.

---

## 1. Adding a New CLI Flag

CLI flags are parsed in `Config.pbi` by `ParseCLI(*cfg.ServerConfig)` and stored
in the `ServerConfig` structure defined in `Types.pbi`.

### Step 1 — Add a field to `ServerConfig` in `Types.pbi`

```purebasic
Structure ServerConfig
  ; ... existing fields ...
  RateLimit.i     ; #True to enable rate limiting headers
EndStructure
```

### Step 2 — Set a default in `LoadDefaults` in `Config.pbi`

```purebasic
Procedure LoadDefaults(*cfg.ServerConfig)
  ; ... existing defaults ...
  *cfg\RateLimit = #False
EndProcedure
```

### Step 3 — Parse the flag in `ParseCLI` in `Config.pbi`

```purebasic
; Boolean flag — no argument
ElseIf param = "--rate-limit"
  *cfg\RateLimit = #True
```

### Step 4 — Use the field in your middleware or main.pb

```purebasic
If *cfg\RateLimit
  ; apply rate limit headers
EndIf
```

---

## 2. Adding a Middleware

The middleware chain is the primary extension point in v2.x. All request handling
flows through `BuildChain()` in `Middleware.pbi`.

### Step 1 — Write the procedure

All middleware share the same signature:

```purebasic
Procedure.i Middleware_YourFeature(*req.HttpRequest, *resp.ResponseBuffer, *mCtx.MiddlewareContext)
  Protected *cfg.ServerConfig = *mCtx\Config

  ; Your logic here. Use *req for the request, *cfg for configuration.

  ; Option A: short-circuit (handled)
  ;   Fill *resp, return #True.
  ;
  ; Option B: pass through
  ;   ProcedureReturn CallNext(*req, *resp, *mCtx)

  ProcedureReturn CallNext(*req, *resp, *mCtx)
EndProcedure
```

**Example — RateLimit headers (post-processing):**

```purebasic
Procedure.i Middleware_RateLimit(*req.HttpRequest, *resp.ResponseBuffer, *mCtx.MiddlewareContext)
  ; Let downstream produce the response first
  Protected result.i = CallNext(*req, *resp, *mCtx)

  ; Then append rate limit headers to whatever was produced
  If *resp\Handled
    *resp\Headers + "X-RateLimit-Remaining: 99" + #CRLF$
  EndIf

  ProcedureReturn result
EndProcedure
```

### Step 2 — Register in BuildChain()

Add one line at the correct position in `BuildChain()` (in `Middleware.pbi`):

```purebasic
Procedure BuildChain()
  g_ChainCount = 0
  RegisterMiddleware(@Middleware_Rewrite())
  RegisterMiddleware(@Middleware_HealthCheck())
  RegisterMiddleware(@Middleware_IndexFile())
  RegisterMiddleware(@Middleware_CleanUrls())
  RegisterMiddleware(@Middleware_SpaFallback())
  RegisterMiddleware(@Middleware_HiddenPath())
  RegisterMiddleware(@Middleware_Cors())
  RegisterMiddleware(@Middleware_BasicAuth())
  RegisterMiddleware(@Middleware_SecurityHeaders())
  RegisterMiddleware(@Middleware_RateLimit())       ; ← new
  RegisterMiddleware(@Middleware_ETag304())
  RegisterMiddleware(@Middleware_GzipSidecar())
  RegisterMiddleware(@Middleware_GzipCompress())
  RegisterMiddleware(@Middleware_EmbeddedAssets())
  RegisterMiddleware(@Middleware_FileServer())
  RegisterMiddleware(@Middleware_DirectoryListing())
EndProcedure
```

**Placement rules:**

- Request modifiers go first (positions 1-4).
- Access control goes after modifiers (check the final path).
- Conditional responses go before terminal handlers (avoid I/O when possible).
- Post-processing middleware call `CallNext()` first, then modify `*resp`.
- Terminal handlers go last and do NOT call `CallNext()` on success.

### Step 3 — Add tests

Create a `ProcedureUnit` in `tests/test_middleware.pb`:

```purebasic
ProcedureUnit RateLimit_AddsHeader()
  Protected cfg.ServerConfig
  InitTestCfg(@cfg)

  Protected req.HttpRequest
  req\Method = "GET" : req\Path = "/test"

  Protected resp.ResponseBuffer
  InitResp(@resp)

  Protected mCtx.MiddlewareContext
  InitMCtx(@mCtx, @cfg)

  ; Register a dummy terminal handler
  g_ChainCount = 0

  Protected result.i = Middleware_RateLimit(@req, @resp, @mCtx)
  Assert(FindString(resp\Headers, "X-RateLimit-Remaining") > 0, "Rate limit header present")
  FreeResp(@resp)
EndProcedureUnit
```

---

## 3. Adding a New MIME Type

`MimeTypes.pbi` uses a single `Select/Case` block. Add a `Case` line:

```purebasic
Case "glb"  : ProcedureReturn "model/gltf-binary"
Case "gltf" : ProcedureReturn "model/gltf+json"
```

The `extension` parameter is always lowercase without a leading dot. No other
changes needed — `GetMimeType` is called from both middleware and embedded assets.

---

## 4. Adding a Custom Response Type

For responses not covered by `BuildResponseHeaders` + body output:

```purebasic
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

---

## 5. Adding a New Module

### Naming conventions

- File name: camelcase `.pbi` (e.g., `AuthMiddleware.pbi`).
- Begin with `EnableExplicit` and a comment header.
- Private procedures use trailing underscore (e.g., `HashPassword_()`).

### `XIncludeFile` order in `main.pb`

Insert after all dependencies are included. Also add to `tests/TestCommon.pbi`.

### Global variable rules

Only scalar `Global` variables are safe in PureUnit-tested modules. See
[TESTING.md](TESTING.md) for why `Global Dim` and `Global NewMap` crash under PureUnit.

---

## 6. Thread Safety

### What is protected

| Resource | Mutex | Notes |
|---|---|---|
| Log files, rotation state | `g_LogMutex` | Both log files share one mutex |
| Rewrite rule arrays, cache | `g_RewriteMutex` | Acquired by `ApplyRewrites`, `LoadGlobalRules` |
| `g_CloseList` | `g_CloseMutex` | Worker threads push; main thread pops |

### What is safe without a mutex

- `g_Config` — written once before `StartServer`; read-only at runtime.
- `g_Handler` — set once before `StartServer`.
- `g_Chain` / `g_ChainCount` — set once by `BuildChain()` before `StartServer`.
- `g_EmbeddedPack` — set once by `OpenEmbeddedPack`.

### Adding new shared state

1. Declare a mutex as `Global .i` in your module.
2. Create it in your `Init*()` procedure.
3. Wrap every read and write with `LockMutex`/`UnlockMutex`.
4. Document in `ARCHITECTURE.md`'s mutex inventory.

---

## 7. Compiling with Embedded Assets

See [BUILDING.md](BUILDING.md) section 5 for the full embedded assets workflow:
`UseZipPacker()` + `DataSection` + `IncludeBinary` + `OpenEmbeddedPack`.
