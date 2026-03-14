# Proposal: Log Management — PureSimpleHTTPServer

**Status:** Decisions captured — ready for implementation
**Date:** 2026-03-15
**Scope:** Access log format upgrade, error log introduction, log rotation

---

## 1. Current State

| Item | Current behaviour |
|------|-------------------|
| Access log format | `[YYYY-MM-DD HH:MM:SS] IP METHOD /path STATUS BYTES` (custom) |
| Error log | None — errors go to `Debug` output only (invisible in production) |
| Log rotation | None — single file grows forever |
| CLI flags | `--log FILE` (single file for access log only) |
| Implementation | `Logger.pbi` — mutex-protected `WriteStringN()` |

**Problems with the current format:**
- Not compatible with standard log analysis tools (GoAccess, AWStats, Webalizer, fail2ban, etc.)
- No error log means 404s, 500s, and server errors are silent in production
- No rotation means unbounded disk usage

---

## 2. Proposed Log Formats

### 2.1 Access Log — Apache Combined Log Format

The industry standard. Accepted by every log analysis tool.

**Format string:** `%h %l %u %t "%r" %>s %b "%{Referer}i" "%{User-Agent}i"`

**Example line:**
```
192.168.1.10 - - [15/Mar/2026:14:32:00 +0000] "GET /index.html HTTP/1.1" 200 4321 "https://example.com/" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"
```

**Field mapping:**

| Field | Apache token | Value in PureSimpleHTTPServer |
|-------|-------------|-------------------------------|
| Client IP | `%h` | `IPString(GetClientIP(connection))` |
| Ident | `%l` | Always `-` (ident protocol not implemented) |
| Auth user | `%u` | Always `-` (HTTP auth not implemented) |
| Timestamp | `%t` | `[DD/Mon/YYYY:HH:MM:SS +HHMM]` — local time + local UTC offset via `ApacheDate()` |
| Request line | `"%r"` | `"METHOD /path HTTP/1.1"` from parsed request |
| Status code | `%>s` | Actual HTTP status (200, 304, 404, etc.) |
| Bytes sent | `%b` | Approximate file size in bytes, or `-` if zero/304 |
| Referer | `"%{Referer}i"` | `GetHeader("Referer", req\RawHeaders)` or `-` |
| User-Agent | `"%{User-Agent}i"` | `GetHeader("User-Agent", req\RawHeaders)` or `-` |

**Timestamp format detail:**
Apache uses `[DD/Mon/YYYY:HH:MM:SS +HHMM]`, e.g. `[15/Mar/2026:14:32:00 +0700]`.
Month abbreviations: Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec.
A new `ApacheDate()` function will be added using `FormatDate()` (local time) + the local UTC offset string (e.g. `+0700`). No `ImportC` required — see §9.1.

**Byte count implementation:**
`ServeFile()` already calls `FileSize()` internally. An optional output parameter `*bytesOut.i = 0` will be added so the caller receives the approximate byte count with zero extra overhead. `HandleRequest()` passes `@bytesOut` and logs the value (or `-` for 0/304 responses). This is valid CLF — `-` is correct for zero-body responses.

### 2.2 Error Log — Apache Error Log Format

**Format:**
```
[DD/Mon/YYYY:HH:MM:SS +0000] [level] [pid NNNN] message
```

**Example lines:**
```
[15/Mar/2026:14:32:05 +0000] [error] [pid 12345] File does not exist: /var/www/wwwroot/favicon.ico
[15/Mar/2026:14:32:10 +0000] [warn]  [pid 12345] Directory listing blocked (browse=off): /var/www/wwwroot/private/
[15/Mar/2026:14:33:00 +0000] [info]  [pid 12345] Server started on port 8080
[15/Mar/2026:14:33:01 +0000] [error] [pid 12345] Cannot open log file: /var/log/pshs/access.log
```

**Log levels (decided: configurable INFO / WARN / ERROR / NONE):**

| Level | Integer | When to use |
|-------|---------|-------------|
| `info`  | 3 | Server start/stop, config summary, PID file written |
| `warn`  | 2 | Degraded behaviour (thread fallback, log write failures) |
| `error` | 1 | 4xx/5xx responses, I/O failures, memory allocation failures |
| `none`  | 0 | Error log file disabled entirely |

Only messages at or above `--log-level` are written to the error log file.
Startup errors (before the log file is open) always print to stdout regardless of level.

---

## 3. Log Rotation Strategies

All three built-in strategies will be implemented (decisions from §8):

### 3.1 Size-Based Rotation (F-2)

The server rotates the log file automatically when it exceeds `--log-size` MB.

**Behaviour:**
1. On each `LogAccess()` or `LogError()` write, check `Lof(g_LogFile) >= g_LogMaxBytes` inside the mutex
2. If over limit: rename `access.log` → `access.YYYYMMDD-HHMMSS.log`, open new `access.log`
3. Delete archives beyond `--log-keep` count (oldest first)

**Archive naming:** date-stamped to avoid conflicts with daily rotation:
```
access.log              ← current
access.20260315-143200.log   ← rotated by size at 14:32:00
access.20260314-000000.log   ← rotated by daily at midnight
```

**Pros:** Zero external dependencies, cross-platform (works on Windows).

### 3.2 Daily Rotation (F-3)

Background `LogRotationThread` wakes at midnight UTC and rotates both log files.

**Behaviour:**
- Thread sleeps until `SecondsToMidnightUTC()` seconds have elapsed
- On wake: acquire log mutex → rename `access.log` → `access.YYYYMMDD-000000.log` → open new `access.log` → release mutex
- Applies to both access log and error log
- Old archives beyond `--log-keep` are deleted

**Both daily + size rotation enabled simultaneously:**
Both use the same date-stamped naming scheme and the same `--log-keep` limit, so they are fully compatible. The mutex prevents race conditions between the rotation thread and request handler threads.

### 3.3 External Rotation via `logrotate` + SIGHUP (F-4)

For deployments managed by systemd/init.d/supervisor that expect the standard `kill -HUP` protocol.

**Flow:**
```
logrotate renames access.log → access.log.1 (with compress/delaycompress)
logrotate sends SIGHUP to server process (via pid file)
server catches SIGHUP → acquires log mutex → reopens access.log + error.log → releases mutex
new log entries go to the new empty access.log
logrotate compresses access.log.1 in the background
```

**`/etc/logrotate.d/puresimplehttpserver`:**
```
/var/log/pshs/access.log
/var/log/pshs/error.log {
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

**PureBasic implementation (macOS/Linux only):**
A `SignalHandler.pbi` module installs a `SIGHUP` handler via `ImportC` calling `signal(SIGHUP, handler)`. The C handler sets a global integer flag `g_ReopenLogs`. The log write path checks this flag and reopens files when set.

```purebasic
CompilerIf #PB_Compiler_OS = #PB_OS_Linux Or #PB_Compiler_OS = #PB_OS_MacOS
  ImportC ""
    signal(*signum, *handler)
  EndImport
  ; ... install handler at startup
CompilerEndIf
```

On Windows: SIGHUP does not exist. Built-in rotation (§3.1 + §3.2) handles Windows. No Windows-specific signal mechanism is planned.

---

## 4. Revised CLI Flags

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--log FILE` | existing | *(disabled)* | Access log file path |
| `--error-log FILE` | new | *(disabled)* | Error log file path |
| `--log-level LEVEL` | new | `warn` | Minimum error log level: `info` \| `warn` \| `error` \| `none` |
| `--log-size MB` | new | `100` | Rotate when log file exceeds N MB; 0 = disabled |
| `--log-keep N` | new | `30` | Max rotated archive files to keep |
| `--log-daily` | new | on† | Rotate access + error logs daily at midnight UTC |
| `--pid-file FILE` | new | *(none)* | Write server PID to FILE on startup (required for logrotate) |

† `--log-daily` is on by default when `--log` or `--error-log` is set. Pass `--log-daily=off` to disable.

**Removed from original proposal:**
- `--log-format FORMAT` — Combined Log Format is decided; no runtime selection needed.

---

## 5. Implementation Plan

All four phases are now **required** (not optional).

### Phase F-1 — Apache Format + Error Log + Log Level

**Effort: medium** | **Prerequisite for all other phases**

1. `src/Logger.pbi`
   - Rewrite `LogAccess()` → Combined Log Format
   - Add `ApacheDate(ts.q)` for UTC timestamp formatting (see §9.1)
   - Add separate `g_ErrorLogFile.i` handle and `g_LogLevel.i`
   - Add `OpenErrorLog(path.s)`, `CloseErrorLog()`, `LogError(level.s, message.s)`
   - Keep existing `g_LogMutex` covering both file handles
2. `src/FileServer.pbi`
   - Call `LogError("error", ...)` on 404 / 403 / 500
   - Add optional `*bytesOut.i = 0` output parameter to `ServeFile()`
3. `src/Config.pbi`
   - Add `ErrorLogFile.s`, `LogLevel.i`, `LogSizeMB.i`, `LogKeepCount.i`, `LogDaily.i`, `PidFile.s` to `ServerConfig`
   - Parse new flags
4. `src/main.pb`
   - Open/close error log; pass `@bytesOut` through `HandleRequest()`
5. `tests/test_logger.pb`
   - New tests: Combined Log Format structure, UTC timestamp format, `LogError()` format, log level filtering

### Phase F-2 — Size-Based Rotation

**Effort: small–medium**

1. `src/Logger.pbi`
   - Add `RotateIfNeeded(*fileHandle.i, path.s)` — rename to date-stamped archive, open new file, delete oldest if over `--log-keep`; called inside mutex from `LogAccess()` and `LogError()`
2. `tests/test_logger.pb`
   - Test rotation trigger (mock large file size), archive naming, keep-count enforcement

### Phase F-3 — Daily Rotation + PID File

**Effort: medium**

1. `src/Logger.pbi`
   - Add `LogRotationThread(*unused)` — background thread, sleeps to next midnight UTC, calls `RotateIfNeeded()` for both log files
   - Start thread in `OpenLogFile()` when `g_LogDaily = #True`; stop on `CloseLogFile()`
2. `src/main.pb`
   - Write PID file at startup: `CreateFile` → `WriteString(Str(GetCurrentProcessID()))` → `CloseFile`
   - Delete PID file at shutdown

### Phase F-4 — SIGHUP Log Reopen

**Effort: high** | **Linux/macOS only**

1. `src/SignalHandler.pbi` (new)
   - `InstallSignalHandlers()` / `RemoveSignalHandlers()` — guarded by `CompilerIf`
   - Sets global `g_ReopenLogs.i` flag on SIGHUP
2. `src/Logger.pbi`
   - Check `g_ReopenLogs` at top of `LogAccess()` / `LogError()`; if set, reopen both files and clear flag (inside mutex)
3. `src/main.pb`
   - Call `InstallSignalHandlers()` before `StartServer()`

---

## 6. Revised Implementation Order

All phases required; recommended sequence:

| Step | Phase | Delivers |
|------|-------|----------|
| 1 | F-1 | Combined Log Format, error log, log level filtering — makes logs useful immediately |
| 2 | F-2 | Size-based rotation (1 GB default, 30 archives) — prevents disk fill |
| 3 | F-3 | Daily rotation at midnight UTC + PID file — predictable daily archives |
| 4 | F-4 | SIGHUP + logrotate integration — for systemd/init.d deployments |

---

## 7. Log Analysis Tooling (available after F-1)

```bash
# Real-time dashboard (GoAccess — macOS: brew install goaccess)
goaccess access.log --log-format=COMBINED

# Top requested paths
awk '{print $7}' access.log | sort | uniq -c | sort -rn | head 20

# All 404s
awk '$9 == 404' access.log

# Unique IPs today
awk '{print $1}' access.log | sort -u | wc -l

# fail2ban — standard filter works out of the box with Combined format
# /etc/fail2ban/filter.d/apache-auth.conf applies unchanged
```

---

## 8. Decisions Summary

| # | Question | Decision |
|---|----------|----------|
| 1 | Byte count accuracy | **Approximate** (file size from existing `FileSize()` call, `-` for 304/empty) |
| 2 | Timestamp timezone | **Local time** with correct UTC offset string (e.g. `+0700`). No `ImportC` needed. |
| 3 | Rotation scope | **Daily + size-based, both required from start.** Default size: **100 MB** |
| 4 | SIGHUP priority | **Required.** Built-in daily + size rotation + SIGHUP all implemented |
| 5 | Error log verbosity | **Configurable:** `info` / `warn` / `error` / `none` via `--log-level` |
| 6 | Windows compatibility | **Required but lower priority** than Linux/macOS |

---

## 9. Concerns & Clarifications

### 9.1 ⚠️ UTC Timestamps Require Platform-Specific Code

**Issue:** PureBasic's `FormatDate()` formats using the *local* timezone, not UTC. Simply writing `+0000` in the format string would be misleading if the server runs in a non-UTC timezone.

**Required solution:** A new `ApacheDate()` helper that calls the OS UTC time API via `ImportC`:
- **macOS/Linux:** `gmtime_r()` (POSIX, always available)
- **Windows:** `GetSystemTime()` (Win32)

This adds ~10 lines of platform-guarded `ImportC` code to `DateHelper.pbi` or `Logger.pbi`. Without this, logs would silently contain local timestamps labelled as UTC — a subtle but harmful bug for log analysis across timezone-aware systems.

**Risk if deferred:** Accepting local time is valid (Apache itself defaults to local time). If `ImportC` complexity is unwanted, local time + correct timezone offset string (e.g. `+0700`) is a safe fallback.

**Decision:** Use **local time** with the correct local timezone offset string. No `ImportC` required. `ApacheDate()` will call `FormatDate()` and append the local UTC offset (e.g. `+0700`). This avoids all platform-specific code while keeping the timestamp honest.

### 9.2 ⚠️ 1 GB Default Size Is Very Large

**Issue:** The decided default of 1 GB per log file means the server could write for days or weeks before rotating on low-traffic deployments — and for only hours on busy ones. At ~500 bytes per CLF line:
- 1 GB ≈ **2 million log entries**
- At 100 req/s: fills in ~5.5 hours
- At 1 req/min: fills in ~7 months

**Concern:** A 1 GB unrotated log is large to tail, grep, or transfer. Standard production defaults:
- Apache httpd default via logrotate: weekly, no size limit
- Nginx: `10m` (10 MB) via `logrotate`
- Caddy: 100 MB

**Decision:** Default changed to **100 MB**. `--log-size 100` in `LoadDefaults()`. Still overridable via `--log-size N`.

### 9.3 ℹ️ "Automatically Restart" Clarified as "Auto-Rotate"

The answer to Q4 says "automatically restart." For clarity: the server process itself does **not** restart. Only the log file handles are closed and reopened (the server keeps running and serving requests throughout). The term is "rotate" or "reopen." No implementation impact — just confirming the interpretation.

### 9.4 ℹ️ `--log-level none` Scope

**Clarification:** `--log-level none` disables writing to the **error log file** only. Startup messages, startup errors, and the `WARNING: Cannot open log file` notice always print to `stdout` regardless of level — otherwise a misconfigured server could fail silently with no indication of the problem.

**Recommendation:** Document this clearly in `USAGE_GUIDE.md`.

### 9.5 ℹ️ Default `--log-level` Set to `warn`

The decided configurable range is `info / warn / error / none`. The default should be `warn` (not `info` and not `error`):
- `info` would log every server start/stop — noisy for long-running services
- `error` would miss degraded-but-recoverable states (e.g. thread fallback)
- `warn` is the Apache httpd default and a reasonable balance

### 9.6 ℹ️ `--log-daily` Default Behaviour

When `--log` or `--error-log` is given, daily rotation is enabled by default (no extra flag needed). Users who want size-only rotation must pass `--no-log-daily`. This is the most ergonomic default given that daily rotation was decided as a baseline requirement.

### 9.7 ℹ️ Windows and SIGHUP

On Windows, F-4 (SIGHUP) will be compiled out via `CompilerIf`. Windows users rely on F-2 (size rotation) and F-3 (daily rotation) exclusively. `logrotate` is not available on Windows, so the `--pid-file` flag is Linux/macOS only.

No action needed — just confirming the Windows behaviour is intentional.
