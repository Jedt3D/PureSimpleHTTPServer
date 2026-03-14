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

PureUnit exits with code `0` if all tests pass, `1` if any fail.

## Writing a New Test

1. Create `tests/test_<module>.pb`
2. `XIncludeFile` only the top-level module under test (transitive includes happen automatically)
3. Write `ProcedureUnit` procedures — no arguments, descriptive names
4. Use `Assert(condition, "message")` for all assertions
5. Use `ProcedureUnitStartup` / `ProcedureUnitShutdown` for setup/teardown of shared state

```purebasic
EnableExplicit

XIncludeFile "../src/MyModule.pbi"

ProcedureUnitStartup Setup()
  ; create temp files, init globals
EndProcedureUnit

ProcedureUnitShutdown Teardown()
  ; delete temp files
EndProcedureUnit

ProcedureUnit Test_MyFunction_HappyPath()
  Assert(MyFunction("input") = "expected", "Unexpected result")
EndProcedureUnit
```

## Adding a New Module

1. Create `src/MyModule.pbi` with:
   - `XIncludeFile` for its dependencies at the top
   - `EnableExplicit` (redundant but explicit)
   - Only `Procedure`, `Structure`, `Enumeration`, constants — **no top-level executable code**
2. `XIncludeFile "MyModule.pbi"` in `src/main.pb` in dependency order
3. Create `tests/test_my_module.pb` with at least one `ProcedureUnit`

## End-of-Phase Checklist

After completing each phase:

```
1. pureunit -i tests/test_*.pb   →  exit code 0 (all pass)
2. Bump #APP_VERSION in src/Global.pbi
3. Add entry to CHANGELOG.md: ## vX.Y.Z — YYYY-MM-DD HH:MM
4. Update /Users/worajedt/.claude/skills/purebasic/resources/common-pitfalls.md
   if any new PureBasic gotcha was discovered
5. git add -p && git commit -m "vX.Y.Z: Phase X — description"
6. Update docs/USAGE_GUIDE.md, ARCHITECTURE_DESIGN.md, DEVELOPER_GUIDE.md
7. Save session state to Claude memory system
```

## PureBasic Gotchas Specific to This Project

### Date type is `.q` not `.i`
```purebasic
; WRONG — Date() returns Quad (8 bytes)
Protected ts.i = Date(2026, 1, 1, 0, 0, 0)

; CORRECT
Protected ts.q = Date(2026, 1, 1, 0, 0, 0)
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
Code outside any `ProcedureUnit` procedure is **not executed** by PureUnit — only compiled. Use `ProcedureUnitStartup` for initialization code.

### `NetworkServerEvent()` needs a server ID when using `#PB_Any`
```purebasic
; CreateNetworkServer returns the auto-assigned ID when #PB_Any is used
Protected serverID.i = CreateNetworkServer(#PB_Any, port, #PB_Network_TCP)

; Pass that ID to NetworkServerEvent — do NOT pass #PB_Any here
event = NetworkServerEvent(serverID)
```

## Project Structure Quick Reference

```
src/main.pb        Entry point — wires modules, starts server
src/Global.pbi     #APP_VERSION, HTTP status codes, buffer size constants
src/Types.pbi      HttpRequest, HttpResponse, ServerConfig structures
src/*.pbi          One module per file — see ARCHITECTURE_DESIGN.md
tests/test_*.pb    One test file per module
tests/run_tests.sh pureunit -i -v [--report] tests/test_*.pb
docs/              USAGE_GUIDE, ARCHITECTURE_DESIGN, DEVELOPER_GUIDE
scripts/           pack_assets.sh (Phase D)
```
