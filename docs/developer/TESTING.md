# Testing PureSimpleHTTPServer

This document describes how to run the test suite, how to write new tests, and
the pitfalls that are specific to PureBasic and the PureUnit framework as used
in this codebase.

---

## 1. Running Tests

### Full suite

From the `tests/` directory:

```
cd tests && ./run_tests.sh
```

Or from the project root:

```
./tests/run_tests.sh
```

`run_tests.sh` invokes `pureunit -i -v` on all `test_*.pb` files in the `tests/`
directory. The `-i` flag randomizes test execution order within each file; `-v`
enables verbose output showing each test name and pass/fail status.

### Single file

To run only the tests for one module:

```
pureunit -v tests/test_rewrite.pb
```

### HTML report

```
./tests/run_tests.sh --report
```

When `--report` is given, PureUnit writes an HTML summary to
`docs/test_report.html`. The path is relative to the project root (not the
`tests/` directory).

### Current test count

The suite currently contains **108 tests across 12 files**. See
[Section 5](#5-test-file-inventory) for the per-file breakdown.

---

## 2. PureUnit Basics

PureUnit is a lightweight unit-testing framework for PureBasic. It works by
compiling and executing each `.pb` file as a standalone program, injecting its
own runtime that discovers and calls every `ProcedureUnit` block.

### Test anatomy

```purebasic
ProcedureUnit MyModule_SomeBehavior()
  Protected result.i = SomeFunction(42)
  Assert(result = 100, "SomeFunction(42) should return 100")
EndProcedureUnit
```

- `ProcedureUnit` / `EndProcedureUnit` — delimit a single test case.
- `Assert(condition, message)` — fails the test if `condition` is `#False`.
  The message is shown in the output when the assertion fails.
- Any PureBasic code is valid inside a `ProcedureUnit`; `Protected` locals,
  file I/O, string operations, and calls to modules under test all work normally.
- A test with no `Assert` calls passes unconditionally; use this form only when
  you are testing that something does not crash.

### Startup and shutdown hooks

If a test file needs shared state (temp directories, initialized engines, etc.),
use `ProcedureUnitStartup` and `ProcedureUnitShutdown`:

```purebasic
Global g_TmpDir.s

ProcedureUnitStartup my_setup()
  g_TmpDir = GetTemporaryDirectory() + "pshs_test"
  CreateDirectory(g_TmpDir)
EndProcedureUnit

ProcedureUnitShutdown my_teardown()
  ; clean up temp files
  DeleteFile(g_TmpDir + "/somefile.txt")
EndProcedureUnit
```

Important syntax notes:

- The hook procedure name (`my_setup`, `my_teardown`) is arbitrary but must be
  provided — the keyword alone without a name is a syntax error.
- The hook body is terminated with `EndProcedureUnit`, not `EndProcedure`.
- `ProcedureUnitStartup` runs once before any tests in the file.
- `ProcedureUnitShutdown` runs once after all tests in the file, even when tests
  fail.
- Only one startup and one shutdown block is allowed per file.

### Randomized test order

PureUnit (when invoked with `-i`) executes test cases in randomized order. This
means every test must be fully self-contained: it must not depend on another test
having run first or having left a particular side effect in place.

The practical consequence is that any shared state — temp files, loaded rule sets,
initialized engines — must be set up in `ProcedureUnitStartup` (not in the first
test that happens to need it) and torn down in `ProcedureUnitShutdown`.

---

## 3. Writing a New Test File

### File naming and location

Place test files in `tests/` and name them `test_<module>.pb`. The `run_tests.sh`
script discovers files by the glob `tests/test_*.pb`.

### Minimal template

```purebasic
; test_myfeature.pb — unit tests for MyFeature.pbi
EnableExplicit
XIncludeFile "TestCommon.pbi"

ProcedureUnit MyFeature_BasicCase()
  Protected result.s = MyFeatureProc("input")
  Assert(result = "expected", "Basic case should return 'expected'")
EndProcedureUnit
```

`TestCommon.pbi` is the single include that pulls in all source modules from
`../src/`. You do not need to add individual `XIncludeFile` lines for every
module your test uses.

### Using temporary files and directories

PureBasic's `GetTemporaryDirectory()` returns the OS temp directory with a
trailing path separator. Use it for test fixtures that need real filesystem
paths:

```purebasic
Global g_TmpDir.s
Global g_TmpFile.s

ProcedureUnitStartup my_setup()
  g_TmpDir  = GetTemporaryDirectory() + "pshs_myfeature_test"
  g_TmpFile = g_TmpDir + "/fixture.txt"
  CreateDirectory(g_TmpDir)
  ; write a fixture
  Protected fh.i = CreateFile(#PB_Any, g_TmpFile)
  If fh
    WriteStringN(fh, "hello", #PB_Ascii)
    CloseFile(fh)
  EndIf
EndProcedureUnit

ProcedureUnitShutdown my_teardown()
  DeleteFile(g_TmpFile)
  ; Note: DeleteDirectory() is not recursive in PureBasic.
  ; Delete individual files first, then the directory.
  ; Empty temp subdirectories can be left for the OS to clean up.
EndProcedureUnit
```

### Assert patterns

```purebasic
; Boolean check
Assert(result = #True, "Should return True")

; Integer value check
Assert(count = 3, "Should load 3 rules — got: " + Str(count))

; String value check
Assert(path = "/expected/path", "Got: '" + path + "'")

; Pointer/handle check
Assert(handle <> 0, "Handle should be non-zero")

; Crash safety: no-op test
Assert(#True, "Function should not crash when called twice")
```

---

## 4. PureUnit Pitfalls

This section documents constraints that are specific to this codebase and the
PureBasic 6.x ARM64 runtime under PureUnit. Violating any of these rules will
cause the test runner to crash, typically with a segfault.

### Global NewMap and NewList crash under PureUnit

**Problem:** PureUnit compiles each test file as a standalone program but skips
the top-level `main()` initialisation that the PureBasic IDE would normally run.
Data structures declared with `Global NewList foo()` or `Global NewMap bar.s()`
at file scope have their internal descriptors left uninitialised. The first call
to `AddElement()`, `ClearList()`, or any map operation reads those zero
descriptors and crashes with a segfault inside `SYS_AllocateArray`.

**Fix:** Never place `NewList` or `NewMap` at global scope in a module that is
included into test files. Move the data structure declaration inside the
procedure that first uses it as a `Protected` or `NewList` local. `TcpServer.pbi`
demonstrates this correctly — its `accum.s()` map is declared `NewMap accum.s()`
inside `StartServer()`, not at file scope.

### Global Dim arrays crash for the same reason

**Problem:** `Global Dim foo.SomeStruct(n)` arrays with embedded string fields
(`.s`) are initialised by main-program startup code. Under PureUnit that startup
is skipped. The array descriptor stays `{0}` and any access to the array (even a
`ReDim`) crashes because the element size and type fields are both zero.

**Fix:** Replace all `Global Dim` arrays with raw `AllocateMemory` blocks
allocated inside an explicit `Init` procedure, as `RewriteEngine.pbi` does with
`InitRewriteEngine()`. Only scalar `Global` variables (`Global x.i`, `Global s.s`)
are safe because PureBasic initialises them to zero/empty at compile time.

Example of the correct pattern:

```purebasic
; WRONG — crashes under PureUnit
Global Dim g_Rules.RewriteRule(63)

; CORRECT — allocate in an init procedure
Global g_RuleTypeMem.i
Global g_RuleCount.i

Procedure InitMyModule()
  g_RuleTypeMem = AllocateMemory(64 * 8)
  g_RuleCount   = 0
EndProcedure
```

### ProgramParameter() returns PureUnit's own arguments

**Problem:** PureUnit passes its own internal flags to the test binary via
`ProgramParameter()`. When `ParseCLI()` runs inside a test, it sees those flags
as if they were server command-line arguments and returns `#False` (unrecognized
argument).

**Fix:** In test files that call `ParseCLI()`, never `Assert` on the return
value. Call `ParseCLI()` only to verify it does not crash, or to observe the
state it leaves in the config struct when called with known valid state. See
`test_config.pb` for the correct approach:

```purebasic
ProcedureUnit Config_ParseCLI_DoesNotCrash()
  Protected cfg.ServerConfig
  LoadDefaults(@cfg)
  ParseCLI(@cfg)   ; may fail — that's fine; we only check it doesn't crash
  Assert(#True, "ParseCLI should not crash when invoked from PureUnit")
EndProcedureUnit
```

### InitNetwork() does not exist in PureBasic

**Problem:** PureBasic does not have an `InitNetwork()` function. The network
subsystem is always available without explicit initialization. Any test that
calls `InitNetwork()` will fail to compile.

**Fix:** Simply do not call it. If you are writing tests that use
`NetworkServerEvent()` or `CreateNetworkServer()`, those are available without
any preceding init call.

---

## 5. Test File Inventory

| File | Module tested | Tests | What it covers |
|------|---------------|-------|----------------|
| `test_config.pb` | `Config.pbi` | 9 | `LoadDefaults()` field values; `ParseCLI()` crash safety |
| `test_date_helper.pb` | `DateHelper.pbi` | 4 | HTTP-Date format string correctness |
| `test_directory_listing.pb` | `DirectoryListing.pbi` | 9 | HTML directory index generation from real temp dirs |
| `test_embedded_assets.pb` | `EmbeddedAssets.pbi` | 4 | `OpenEmbeddedPack(0,0)` returns `#False`; `ServeEmbeddedFile` when no pack open |
| `test_file_server.pb` | `FileServer.pbi` | 8 | `ResolveIndexFile`, `BuildETag`, `IsHiddenPath`, `ServeFile` with temp files |
| `test_http_parser.pb` | `HttpParser.pbi` | 5 | GET parsing, query string splitting, header extraction, URL decoding, malformed input |
| `test_http_response.pb` | `HttpResponse.pbi` | 5 | `BuildResponseHeaders` output, `StatusText` values, `SendTextResponse` (loopback) |
| `test_logger.pb` | `Logger.pbi` | 23 | Log open/close/write, `ApacheDate` format, log level filtering, size rotation, archive pruning, daily rotation thread |
| `test_mime_types.pb` | `MimeTypes.pbi` | 6 | Common extension lookups, unknown extension fallback |
| `test_range_parser.pb` | `RangeParser.pbi` | 9 | Valid range parsing, suffix ranges, invalid/unsatisfiable ranges |
| `test_rewrite.pb` | `RewriteEngine.pbi` | 22 | Exact/glob/regex rewrite and redirect, placeholder substitution, rule precedence, per-dir cache, parse edge cases |
| `test_url_helper.pb` | `UrlHelper.pbi` | 4 | Percent-decoding, path normalization, traversal prevention |

**Total: 108 tests.**

---

## 6. Coverage Gaps and How to Add Tests

### TcpServer integration tests

`TcpServer.pbi` is currently covered only by the fact that all other integration
paths exercise it indirectly. Writing a dedicated test requires an actual
listening TCP port. The correct approach is:

1. In `ProcedureUnitStartup`, pick a high ephemeral port (e.g. 59800) and start
   the server in a background thread with `CreateThread(@StartServer(), port)`.
2. In each test, open a socket to `127.0.0.1:59800`, send a raw HTTP request,
   and read the response.
3. In `ProcedureUnitShutdown`, call `StopServer()` and wait for the thread.

The main constraint is that `CloseNetworkConnection()` must only be called from
the main thread (see the comment at the top of `TcpServer.pbi`). If you call it
from your test assertions while the server event loop is also draining the close
queue, you will get a race. Structure the teardown so `StopServer()` is called
and `WaitThread()` completes before you do any network cleanup in the test body.

### Testing embedded assets

The four existing embedded-asset tests only cover the no-pack path because
compiling an actual `.zip` into the test binary at test time would require a
separate compilation step. To test the live pack path:

1. Build a small fixture zip (one or two tiny files) using
   `scripts/pack_assets.sh`.
2. Create a separate test binary (not a PureUnit file) that includes the zip via
   `DataSection` / `IncludeBinary`, calls `OpenEmbeddedPack(?webapp, ...)`, and
   calls `ServeEmbeddedFile()` against a loopback connection.
3. Assert on the response headers and body received on the client side.

This is an end-to-end compilation test rather than a PureUnit test. It is best
driven from a shell script that compiles, runs, and checks exit codes.

### Adding tests for new modules

When you add a new source module `src/MyFeature.pbi`:

1. Add `XIncludeFile "../src/MyFeature.pbi"` to `tests/TestCommon.pbi` in the
   same position that `src/main.pb` includes it (include order matters for
   forward declarations).
2. Create `tests/test_myfeature.pb` using the template from Section 3.
3. Run `./tests/run_tests.sh` to confirm the new file is discovered and passes.
   The glob `test_*.pb` picks it up automatically.
