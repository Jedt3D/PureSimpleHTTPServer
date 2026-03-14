# Developer Guide — PureSimpleHTTPServer

## Prerequisites

- PureBasic 6.x installed at `/Applications/PureBasic.app` (macOS)
- PureUnit 1.4 in `$PATH` (at `/Applications/PureBasic.app/Contents/Resources/sdk/pureunit/pureunit`)
- `pbcompiler` in `$PATH`

Verify setup:
```bash
pbcompiler --version
pureunit --version
```

## Running Tests

```bash
# Run all tests (stop on first failure)
cd tests && ./run_tests.sh

# Run all tests (continue through failures, generate HTML report)
cd tests && ./run_tests.sh --report

# Run a single test file
pureunit -v tests/test_date_helper.pb
```

PureUnit exits with code `0` if all tests pass, `1` if any fail. Currently **70 tests across 11 files**.

## Writing a New Test

1. Create `tests/test_<module>.pb`
2. `XIncludeFile "TestCommon.pbi"` — this includes all `../src/` modules in dependency order
3. Write `ProcedureUnit` procedures — no arguments, descriptive names
4. Use `Assert(condition, "message")` for all assertions
5. Use `ProcedureUnitStartup name()` / `ProcedureUnitShutdown name()` for setup/teardown

```purebasic
EnableExplicit
XIncludeFile "TestCommon.pbi"

Global g_TmpFile.s

ProcedureUnitStartup setup()
  g_TmpFile = GetTemporaryDirectory() + "pshs_test.tmp"
  DeleteFile(g_TmpFile)
EndProcedureUnit

ProcedureUnitShutdown teardown()
  DeleteFile(g_TmpFile)
EndProcedureUnit

ProcedureUnit MyModule_HappyPath()
  Assert(MyFunction("input") = "expected", "Unexpected result")
EndProcedureUnit
```

## Adding a New Module

1. Create `src/MyModule.pbi` with:
   - `XIncludeFile` for its dependencies at the top
   - Only `Procedure`, `Structure`, `Enumeration`, constants — **no top-level executable code**
2. Add `XIncludeFile "MyModule.pbi"` to `src/main.pb` in dependency order
3. Add `XIncludeFile "../src/MyModule.pbi"` to `tests/TestCommon.pbi`
4. Create `tests/test_my_module.pb` with at least one `ProcedureUnit`

## Project Structure Quick Reference

```
src/main.pb        Entry point — wires modules, starts server
src/Global.pbi     #APP_VERSION, HTTP status codes, buffer size constants
src/Types.pbi      HttpRequest, HttpResponse, ServerConfig, RangeSpec structures
src/*.pbi          One module per file — see ARCHITECTURE_DESIGN.md
tests/TestCommon.pbi  Shared includes for all test files
tests/test_*.pb    One test file per module (70 tests total)
tests/run_tests.sh pureunit -i -v [--report] tests/test_*.pb
docs/              USAGE_GUIDE, ARCHITECTURE_DESIGN, DEVELOPER_GUIDE
scripts/           pack_assets.sh (build embedded asset zip)
```

## PureBasic Gotchas Specific to This Project

### Date type is `.q` not `.i`
```purebasic
; WRONG — Date() and GetFileDate() return Quad (8 bytes)
Protected ts.i = Date()

; CORRECT
Protected ts.q = Date()
Protected mtime.q = GetFileDate(path, #PB_Date_Modified)
```

### Content-Length needs byte count, not character count
```purebasic
; WRONG — Len() counts characters, not bytes
"Content-Length: " + Str(Len(body))

; CORRECT — StringByteLength() counts UTF-8 bytes
"Content-Length: " + Str(StringByteLength(body, #PB_UTF8))
```

### `g_Handler` must be set before `StartServer()`
```purebasic
; WRONG — StartServer checks g_Handler = 0 and returns #False
StartServer(8080)

; CORRECT
g_Handler = @HandleRequest()
StartServer(8080)
```

### `XIncludeFile` paths are relative to the file containing the directive
If `src/HttpParser.pbi` contains `XIncludeFile "UrlHelper.pbi"`, that resolves to `src/UrlHelper.pbi` regardless of where the main compiled file is. Test files in `tests/` that include `"../src/HttpParser.pbi"` get transitive includes resolved correctly.

### PureUnit: all test code must be inside `ProcedureUnit` blocks
Code outside any `ProcedureUnit` procedure is **not executed** by PureUnit — only compiled. Use `ProcedureUnitStartup name()` for initialization code.

### PureUnit: `ProcedureUnitStartup` / `Shutdown` require a procedure name
```purebasic
; WRONG — parser error:
ProcedureUnitStartup
  ...
EndProcedureUnit

; CORRECT:
ProcedureUnitStartup setup()
  ...
EndProcedureUnit
```

### PureUnit: `Global NewMap` / `Global NewList` at top level causes segfault
PureUnit skips top-level initialization code, leaving map/list handles null. Use `Select/Case` inside a procedure instead (see `GetMimeType()` in MimeTypes.pbi).

### PureUnit: `ProgramParameter()` returns PureUnit's own runtime args
Do not assert on the return value of `ParseCLI()` inside PureUnit tests — PureUnit may pass its own internal arguments to the test binary, causing `ParseCLI` to see unrecognized flags and return `#False`. Only test that it doesn't crash and that config fields remain valid.

### `NetworkServerEvent()` needs a server ID when using `#PB_Any`
```purebasic
; CreateNetworkServer returns the auto-assigned ID when #PB_Any is used
Protected serverID.i = CreateNetworkServer(#PB_Any, port, #PB_Network_TCP)

; Pass that ID to NetworkServerEvent — do NOT pass #PB_Any here
event = NetworkServerEvent(serverID)
```

### `NetworkClientIP()` does not exist — use `IPString(GetClientIP(Client))`
```purebasic
; WRONG — compile error: not a function
Protected clientIP.s = NetworkClientIP(connection)

; CORRECT — two-step: get numeric IP, convert to dotted string
Protected clientIP.s = IPString(GetClientIP(connection))
```
`GetClientIP(Client)` returns the numeric IP; `IPString()` converts it to `"127.0.0.1"` form.
For IPv6 connections, call `FreeIP()` on the value returned by `GetClientIP()` when done.

### Thread-safe mode requires `-t` compiler flag
`CreateThread()`, `CreateMutex()`, `LockMutex()` are always available, but safe concurrent memory allocation and most library internals require `-t`:
```bash
pbcompiler -cl -t -o PureSimpleHTTPServer src/main.pb
```
