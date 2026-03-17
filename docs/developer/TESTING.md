# PureSimpleHTTPServer v2.5.0 — Testing Guide

This document describes how to run the test suite, how to write new tests, and
the pitfalls specific to PureBasic and the PureUnit framework as used in this
codebase.

---

## 1. Running Tests

```bash
cd tests
./run_tests.sh
```

To generate an HTML report at `docs/test_report.html`:

```bash
cd tests
./run_tests.sh --report
```

`run_tests.sh` passes the `-i` (interpret) and `-v` (verbose) flags to PureUnit
and globs every `test_*.pb` file in the `tests/` directory:

```bash
pureunit -i -v $REPORT_FLAG "$SCRIPT_DIR"/test_*.pb
```

The script exits with a non-zero status if any test fails (due to `set -e`).

---

## 2. PureUnit Framework Overview

PureUnit is a unit-testing tool for PureBasic. It reads source files directly,
parses `ProcedureUnit` and `ProcedureUnitStartup`/`ProcedureUnitShutdown`
blocks, runs them in sequence, and reports pass/fail per procedure.

### Test procedure syntax

Test procedures use `ProcedureUnit`/`EndProcedureUnit` instead of
`Procedure`/`EndProcedure`:

```purebasic
ProcedureUnit MyModule_SomeBehavior()
  Protected result.s = MyFunction("input")
  Assert(result = "expected", "MyFunction should return 'expected'")
EndProcedureUnit
```

`Assert(condition, message.s)` is the only assertion macro. It fails the test
if `condition` evaluates to `#False` (zero). There is no `AssertEquals` or
similar — compute the condition inline.

### Setup and teardown

Each test file may define one startup and one shutdown procedure. PureUnit runs
the startup before any test in that file and the shutdown after all tests in
that file:

```purebasic
ProcedureUnitStartup setup()
  ; runs before the first test in this file
EndProcedureUnit

ProcedureUnitShutdown teardown()
  ; runs after the last test in this file
EndProcedureUnit
```

Both blocks use `ProcedureUnit`/`EndProcedureUnit` syntax. The name argument
is required — see pitfall 3 below.

---

## 3. Test File Structure

Every test file follows this template:

```purebasic
; test_mymodule.pb — Unit tests for MyModule.pbi
EnableExplicit
XIncludeFile "TestCommon.pbi"

; Optional: module-level globals used across tests
Global g_TmpDir.s

ProcedureUnitStartup setup()
  g_TmpDir = GetTemporaryDirectory() + "pshs_mymod_test"
  CreateDirectory(g_TmpDir)
EndProcedureUnit

ProcedureUnitShutdown teardown()
  ; clean up files, resources
EndProcedureUnit

ProcedureUnit MyModule_Behavior_ExpectedOutcome()
  Protected result.i = MyFunction("input")
  Assert(result = 42, "MyFunction should return 42 for 'input'")
EndProcedureUnit
```

### File naming

Test files must be named `test_*.pb` to be picked up by `run_tests.sh`.

### Naming convention for test procedures

Use `ModuleName_Context_ExpectedBehavior` — for example:
`Logger_LogAccess_ZeroBytesAsDash` or `Config_LoadDefaults_Port`. This
produces readable output in PureUnit's verbose mode.

### `TestCommon.pbi`

All test files include `TestCommon.pbi` as their first `XIncludeFile`. This
file includes every `src/*.pbi` module in the correct dependency order so that
tests can call any public procedure without managing their own include chain.

```purebasic
; tests/TestCommon.pbi
XIncludeFile "../src/Global.pbi"
XIncludeFile "../src/Types.pbi"
XIncludeFile "../src/DateHelper.pbi"
; ... (all modules in dependency order)
```

---

## 4. Critical PureUnit Pitfalls

PureUnit runs test code in an interpreter that does not execute the `main()`
body of your program. This affects global variable initialization in several
ways that will cause crashes if not handled carefully.

### Pitfall 1 — `Global NewMap` and `Global NewList` at top level

**What happens:** A `Global NewMap` or `Global NewList` declared at the top
level of a module (outside any procedure) allocates its descriptor in the
data segment. When a test procedure then calls `AddElement` or
`AddMapElement`, PureUnit's runtime environment may not have correctly set
up the associated internal state, leading to memory corruption. Subsequent
`ForEach`, `ClearList`, or `ClearMap` calls segfault.

**Fix:** Do not use `Global NewMap` or `Global NewList` in modules that are
tested. Replace them with one of:

- A `Select/Case` lookup (as in `MimeTypes.pbi` — no map at all).
- Lazy initialization with `AllocateMemory`, accessed via `PeekI`/`PokeI`.
- A local `Protected NewList` declared inside the procedure that needs it
  (as in `DirectoryListing.pbi` and `PruneArchives` in `Logger.pbi`).
- Inline tokenization with `StringField` (as in `RewriteEngine.pbi`'s
  `ParseRule_`).

### Pitfall 2 — `Global Dim` arrays with structure types or any type

**What happens:** `Global Dim array.SomeStructure(N)` and
`Global Dim array.i(N)` both cause problems under PureUnit. PureBasic
generates `SYS_AllocateArray` calls for `Dim` inside the compiler-generated
`main()` entry point. PureUnit skips `main()`, so the array descriptor block
remains as zeroed memory `{0}`.

Attempting to use `ReDim` to fix this does not work. `ReDim` calls
`SYS_ReAllocateArray(N, &descriptor)`, which reads the element size and type
tag from the descriptor — both zero — and crashes.

Structure types with embedded `.s` string fields are additionally dangerous
because global initialization for managed strings is also skipped, leading to
use-after-free behavior when the first string assignment fires the reference
counter code on a garbage pointer.

**Fix:** Replace all `Global Dim` arrays with `AllocateMemory` blocks
allocated inside an `Init*()` procedure, stored in a `Global .i` scalar
pointer. Access elements via `PeekI`/`PokeI`/`PeekQ`/`PokeQ`/`PeekS`/`PokeS`
with manual byte-offset arithmetic. This is exactly the pattern used by
`RewriteEngine.pbi`:

```purebasic
; WRONG — crashes under PureUnit:
Global Dim g_Rules.RewriteRule(63)

; CORRECT — works under PureUnit:
Global g_RuleTypeMem.i   ; pointer to AllocateMemory block

Procedure InitMyModule()
  g_RuleTypeMem = AllocateMemory(64 * 8)
EndProcedure

; Access element i:
; read:  PeekI(g_RuleTypeMem + i * 8)
; write: PokeI(g_RuleTypeMem + i * 8, value)
```

Scalar `Global` variables of any type (`.i`, `.s`, `.q`, etc.) are safe — the
compiler initializes them statically, not through `main()`.

### Pitfall 3 — `ProcedureUnitStartup` requires a name argument

**What happens:** Writing `ProcedureUnitStartup()` (empty parentheses) causes a
PureUnit parse error. PureUnit requires a name for the startup and shutdown
procedures.

**Fix:** Always provide a name:

```purebasic
; WRONG:
ProcedureUnitStartup()

; CORRECT:
ProcedureUnitStartup my_setup()
```

The name is arbitrary but must be present.

### Pitfall 4 — `ProgramParameter()` returns PureUnit's own arguments

**What happens:** `ParseCLI(*cfg)` calls `ProgramParameter(i)` in a loop.
When run under PureUnit, `ProgramParameter(0)` returns one of PureUnit's own
flags (e.g. `-v`, `-i`, or a file path), not a server flag. Asserting that
`ParseCLI` returns `#True` in a test will therefore always fail, because
PureUnit's flags are unrecognized by the server's argument parser.

**Fix:** In tests, only assert that `ParseCLI` does not crash, not that it
succeeds. Verify the state of individual fields that `ParseCLI` cannot affect
via PureUnit's flags:

```purebasic
ProcedureUnit Config_ParseCLI_DoesNotCrash()
  Protected cfg.ServerConfig
  LoadDefaults(@cfg)
  ParseCLI(@cfg)   ; return value intentionally ignored
  Assert(#True, "ParseCLI should not crash when invoked from PureUnit")
EndProcedureUnit

ProcedureUnit Config_ParseCLI_ConfigRemainsValid()
  Protected cfg.ServerConfig
  LoadDefaults(@cfg)
  ParseCLI(@cfg)
  ; MaxConnections is not a valid CLI flag, so it stays at the default
  Assert(cfg\MaxConnections = 100, "MaxConnections unchanged after ParseCLI")
EndProcedureUnit
```

To test specific flag parsing, set `cfg` fields directly and assert on those
values — do not rely on `ParseCLI` receiving controlled input during a PureUnit
run.

---

## 5. Middleware Isolation Testing Pattern

Middleware can be tested in isolation by calling them directly with crafted
structures. The `test_middleware.pb` file demonstrates the standard pattern:

```purebasic
ProcedureUnit MyMiddleware_Test()
  Protected cfg.ServerConfig
  cfg\RootDirectory = g_TestRoot
  cfg\IndexFiles    = "index.html"

  Protected req.HttpRequest
  req\Method = "GET" : req\Path = "/test"

  Protected resp.ResponseBuffer
  resp\StatusCode = 0 : resp\Body = 0 : resp\Handled = #False

  Protected mCtx.MiddlewareContext
  mCtx\ChainIndex = 0 : mCtx\Config = @cfg

  ; Empty chain so CallNext returns #False
  g_ChainCount = 0

  Protected result.i = Middleware_YourFeature(@req, @resp, @mCtx)
  Assert(...)

  If resp\Body : FreeMemory(resp\Body) : EndIf
EndProcedureUnit
```

Helper patterns used in test_middleware.pb:
- **InitTestCfg** — set up a `ServerConfig` with test root and defaults
- **InitResp** — zero-initialize a `ResponseBuffer`
- **InitMCtx** — initialize a `MiddlewareContext` with config pointer
- **FreeResp** — safely free `resp\Body` if allocated

---

## 6. Current Test Files

There are 13 test files with 148 tests covering all modules:

| File | Module(s) tested | Key behaviors |
|---|---|---|
| `test_date_helper.pb` | `DateHelper.pbi` | RFC 7231 format, day/month name lookup |
| `test_url_helper.pb` | `UrlHelper.pbi` | Percent-decode, `.`/`..` normalization, path traversal rejection |
| `test_http_parser.pb` | `HttpParser.pbi` | GET/POST parsing, query string split, URL decode, header extraction, malformed request rejection |
| `test_http_response.pb` | `HttpResponse.pbi` | Status text lookup, header block assembly, `Content-Length` accuracy |
| `test_mime_types.pb` | `MimeTypes.pbi` | Known extension lookup, unknown extension fallback |
| `test_file_server.pb` | `FileServer.pbi` | Index file resolution, ETag generation and stability, hidden path detection |
| `test_range_parser.pb` | `RangeParser.pbi` | Full, open-ended, and suffix range parsing; unsatisfiable range rejection |
| `test_directory_listing.pb` | `DirectoryListing.pbi` | HTML generation, parent link, directory/file ordering |
| `test_embedded_assets.pb` | `EmbeddedAssets.pbi` | No-pack no-op, `OpenEmbeddedPack` with invalid args |
| `test_config.pb` | `Config.pbi` | `LoadDefaults` field values, `ParseCLI` crash-safety |
| `test_logger.pb` | `Logger.pbi` | CLF format, zero-byte dash, level filtering, size rotation, archive naming, keep-count pruning, SIGHUP reopen, daily thread start/stop |
| `test_rewrite.pb` | `RewriteEngine.pbi` | Exact/glob/regex rewrite and redirect, placeholder substitution, first-rule-wins, per-directory rules, mtime cache, comment/blank-line skipping |
| `test_middleware.pb` | `Middleware.pbi` | Middleware isolation tests: HiddenPath 403, ETag304 match/miss, IndexFile resolution, CleanUrls fallback, SpaFallback, GzipSidecar, FileServer 200/404, DirectoryListing, Rewrite/redirect, chain ordering, HealthCheck 200/passthrough, Cors preflight/headers, SecurityHeaders append, custom error pages (404/403/fallback/disabled), BasicAuth (disabled/no-header/wrong-creds/correct/colon-password), Cache-Control (default/custom/FileServer) |

---

## 6. Adding a New Test File

1. Create `tests/test_mymodule.pb` following the template in section 3.

2. Name it `test_*.pb` — `run_tests.sh` picks up all matching files
   automatically. No manual registration is needed:

   ```bash
   pureunit -i -v "$SCRIPT_DIR"/test_*.pb
   ```

3. Add setup and teardown if your tests create temporary files or call
   `Init*()` procedures:

   ```purebasic
   ProcedureUnitStartup setup()
     InitMyModule()
   EndProcedureUnit

   ProcedureUnitShutdown teardown()
     CleanupMyModule()
   EndProcedureUnit
   ```

4. Use `GetTemporaryDirectory()` for any files created during tests. Clean them
   up in the shutdown procedure to avoid leaving state that could affect other
   test files run in the same session.

5. Run the full suite to confirm no regressions:

   ```bash
   cd tests && ./run_tests.sh
   ```
