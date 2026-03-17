# Building PureSimpleHTTPServer

This document covers everything you need to compile PureSimpleHTTPServer v2.3.1
from source, including prerequisites, build commands, compiler flag explanations,
the source layout, and how to produce a self-contained binary with embedded web
application assets.

---

## 1. Prerequisites

### PureBasic 6.x

PureSimpleHTTPServer requires **PureBasic 6.x**. The codebase uses
`EnableExplicit`, `XIncludeFile`, structured types, threads, regular expressions,
and network primitives that are all standard in PureBasic 6.

Download PureBasic from [https://www.purebasic.com](https://www.purebasic.com).
The compiler binary is named `pbcompiler` on macOS and Linux, and `pbcompiler.exe`
on Windows. All examples below use `pbcompiler` without the `.exe` suffix.

### macOS

After installing PureBasic, add the compiler to your PATH. With a typical
installation in `/Applications`:

```
export PATH="/Applications/PureBasic.app/Contents/MacOS:$PATH"
```

Verify:

```
pbcompiler --version
```

### Linux

PureBasic ships as a tarball on Linux. After extracting to, say,
`~/purebasic`, add it to your PATH:

```
export PATH="$HOME/purebasic:$PATH"
```

Verify:

```
pbcompiler --version
```

### Windows

After installation the IDE registers the compiler. Add its directory (e.g.
`C:\Program Files\PureBasic`) to the system `PATH` environment variable, then
use a Developer Command Prompt or PowerShell session.

---

## 2. Building

All build commands are run from the **project root directory** — the directory
that contains `src/`, `tests/`, `docs/`, etc.

### Development Build

```
pbcompiler -cl -t -o PureSimpleHTTPServer src/main.pb
```

This produces a `PureSimpleHTTPServer` binary (or `PureSimpleHTTPServer.exe` on
Windows) in the project root. It is suitable for day-to-day development and test
runs.

### Release Build (with optimizer)

```
pbcompiler -cl -t -z -o PureSimpleHTTPServer src/main.pb
```

Adding `-z` enables the PureBasic optimizer. Use this flag for binaries you
intend to distribute or deploy; it produces smaller, faster code but gives the
compiler more latitude to reorder and inline operations. Do not mix `-z` with
`-l` (line numbering) because the line-number metadata conflicts with optimizer
output.

### Debug Build (with OnError line numbers)

```
pbcompiler -cl -t -l -o PureSimpleHTTPServer_debug src/main.pb
```

Adding `-l` embeds source-line information used by PureBasic's `OnError` library.
When a runtime crash occurs, PureBasic can report the exact source file and line
number. Useful when investigating a crash that only happens in a running server and
cannot be reproduced under the IDE debugger.

### Cross-Platform Output Names

| OS      | Output binary              |
|---------|----------------------------|
| macOS   | `PureSimpleHTTPServer`     |
| Linux   | `PureSimpleHTTPServer`     |
| Windows | `PureSimpleHTTPServer.exe` |

Pass the platform-appropriate name to `-o`, or let PureBasic append `.exe`
automatically on Windows.

---

## 3. Build Flags Explained

| Flag | What it does | Required? |
|------|--------------|-----------|
| `-cl` | Compiles as a **console application**. Without this flag `PrintN()` output is discarded on Windows and the startup banner never appears on any platform. | Yes, always |
| `-t` | Enables **thread-safe mode**. PureBasic's string handling, list operations, and memory manager use per-thread scratch buffers instead of shared globals. Required because TcpServer.pbi spawns one OS thread per HTTP connection. Without `-t` concurrent requests corrupt string state. | Yes, always |
| `-z` | Enables the **optimizer**. Reduces binary size and improves runtime performance. Incompatible with `-l`. Use for release builds only. | Release only |
| `-l` | Embeds **source line numbers** for PureBasic's `OnError` library. Useful for crash diagnosis in production when you cannot attach a debugger. Do not combine with `-z`. | Debug builds only |

There is no `-d` macro or conditional compilation constant used in this codebase
to distinguish build types; the distinction is entirely in which flags you pass.

### Runtime Dependencies

The following PureBasic compiler directives are used at the top level and must
be linked:

- `UseZipPacker()` — Required for embedded assets (`CatchPack`) and dynamic gzip compression (`CompressMemory` with `#PB_PackerPlugin_Zip`).
- `UseCRC32Fingerprint()` — Required for gzip trailer CRC32 computation via `Fingerprint(*buf, size, #PB_Cipher_CRC32)`.

TLS uses PureBasic's built-in `UseNetworkTLS()` called from `CreateServerWithTLS()` in `TcpServer.pbi` — no external OpenSSL installation is needed.

---

## 4. Directory Structure

```
PureSimpleHTTPServer/
  src/                  Source modules (main entry point + .pbi includes)
    main.pb             Entry point — includes all modules, starts middleware chain
    Global.pbi          Application-wide constants and HTTP status codes
    Types.pbi           Shared structure definitions (HttpRequest, ServerConfig, etc.)
    Config.pbi          CLI argument parsing and default configuration
    TcpServer.pbi       Thread-per-connection TCP server loop
    HttpParser.pbi      Raw HTTP/1.1 request parser
    HttpResponse.pbi    Response header builder and SendTextResponse()
    FileServer.pbi      Static file serving, ETag, Range, directory handling
    MimeTypes.pbi       File extension to MIME type mapping
    DirectoryListing.pbi HTML directory index generator
    RangeParser.pbi     HTTP Range header parser for partial content (206)
    UrlHelper.pbi       URL percent-decoding and path normalization
    DateHelper.pbi      HTTP-Date formatting and date helpers
    Logger.pbi          Apache Combined Log Format access log + error log + rotation
    RewriteEngine.pbi   URL rewrite and redirect rules (Caddy-compatible subset)
    EmbeddedAssets.pbi  In-memory asset serving via CatchPack/UncompressPackMemory
    Middleware.pbi       Middleware chain infrastructure + all 11 middleware
    AutoTLS.pbi         Automatic HTTPS via acme.sh integration
    SignalHandler.pbi   SIGHUP handler for logrotate integration (macOS/Linux)
    WindowsService.pbi  Windows Service API wrapper (stubs on non-Windows)

  tests/                PureUnit test files
    TestCommon.pbi      Shared XIncludeFile chain for all test files
    run_tests.sh        Run all test_*.pb files; optional --report flag
    test_*.pb           One test file per module

  docs/                 Documentation
    developer/          This directory — developer reference files
    test_report.html    Generated by run_tests.sh --report (not in VCS)

  wwwroot/              Demo web content served when no --root flag is given
  scripts/
    pack_assets.sh      Pack a directory of web assets into a .zip for embedding
```

All module includes are handled by `XIncludeFile` chains starting in `src/main.pb`
for the main binary and `tests/TestCommon.pbi` for tests. You do not need to pass
include paths to the compiler — PureBasic resolves `XIncludeFile` paths relative
to the including file.

---

## 5. Embedded Assets Build

The server can serve a web application entirely from memory — no filesystem
access required at runtime. This is done by compiling a `.zip` of your web app
directly into the binary using PureBasic's `DataSection` / `IncludeBinary`
mechanism.

### Step 1 — Pack the web application

Build your frontend into a distribution directory (e.g. `dist/`), then pack it:

```
./scripts/pack_assets.sh dist/ src/webapp.zip
```

The script calls `zip -r` from inside the `dist/` directory, so paths inside the
archive are relative (e.g. `index.html`, `css/app.css`, `js/bundle.js`) — not
prefixed with `dist/`.

### Step 2 — Add the DataSection to main.pb

Open `src/main.pb` and make two changes.

Add `UseZipPacker()` near the top, before `Main()`:

```purebasic
UseZipPacker()
```

Add a `DataSection` block after the `XIncludeFile` declarations:

```purebasic
DataSection
  webapp:    IncludeBinary "webapp.zip"
  webappEnd:
EndDataSection
```

The labels `webapp:` and `webappEnd:` mark the start and end of the packed data.
The expression `?webappEnd - ?webapp` gives the byte size at compile time.

### Step 3 — Open the pack at startup

In `Main()`, replace the existing `OpenEmbeddedPack()` no-argument call with the
two-argument form:

```purebasic
OpenEmbeddedPack(?webapp, ?webappEnd - ?webapp)
```

`EmbeddedAssets.pbi` exports `OpenEmbeddedPack(*packData = 0, packSize.i = 0)`.
When called with `(0, 0)` (the default) it returns `#False` and disk serving
proceeds normally — this is how the server behaves without embedded assets and
is also how `EmbeddedAssets.pbi` behaves in unit tests.

### Step 4 — Recompile

```
pbcompiler -cl -t -z -o PureSimpleHTTPServer src/main.pb
```

After a successful build, `OpenEmbeddedPack()` opens the zip from the embedded
data and `ServeEmbeddedFile()` is called first for every GET request before
falling back to disk. The startup banner will print:

```
Mode:       embedded assets (in-memory)
```

### Development Mode Fallback

When you are iterating on the frontend during development, you do not need to
repack and recompile on every change. Simply leave `OpenEmbeddedPack()` called
with no arguments (or `(0, 0)`) and point `--root` at your live build output
directory. The server serves directly from disk and hot-reload workflows work
as normal.

### UseZipPacker() Requirement

`UseZipPacker()` is a PureBasic compiler directive that links the zip packer
library. It must appear at the top level of the compiled file (not inside a
`Procedure`). If you forget it, `CatchPack()` inside `OpenEmbeddedPack()` will
always return 0 and embedded serving will silently fall back to disk.
