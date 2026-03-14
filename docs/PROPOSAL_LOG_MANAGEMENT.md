# Proposal: Log Management — PureSimpleHTTPServer

**Status:** Draft for review
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
| Timestamp | `%t` | `[DD/Mon/YYYY:HH:MM:SS +0000]` — UTC, using `FormatDate()` |
| Request line | `"%r"` | `"METHOD /path HTTP/1.1"` from parsed request |
| Status code | `%>s` | Actual HTTP status (200, 304, 404, etc.) |
| Bytes sent | `%b` | Response body bytes, or `-` if zero |
| Referer | `"%{Referer}i"` | `GetHeader("Referer", req\RawHeaders)` or `-` |
| User-Agent | `"%{User-Agent}i"` | `GetHeader("User-Agent", req\RawHeaders)` or `-` |

**Timestamp format detail:**
Apache uses `[DD/Mon/YYYY:HH:MM:SS ±HHMM]`, e.g. `[15/Mar/2026:14:32:00 +0000]`.
Month abbreviations: Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec.
`FormatDate()` does not produce abbreviated month names directly — a `Select/Case` lookup on `Month(Date())` is needed (same pattern as `DateHelper.pbi`).

**Implementation note on bytes:**
`ServeFile()` currently returns `#True`/`#False`, not bytes sent. To log accurate byte counts, `ServeFile()` and `ServeEmbeddedFile()` would need to return the number of bytes written, or `HandleRequest()` would need to be passed a pointer to accumulate the count. The alternative is to log `-` for zero / unknown bytes (valid in CLF — `%b` uses `-` when zero bytes are sent, e.g. for 304 responses).

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

**Log levels:**

| Level | When to use |
|-------|-------------|
| `error` | 4xx/5xx responses, I/O failures, failed memory allocation |
| `warn`  | Degraded behaviour (thread creation failed → sync fallback, log file not writable) |
| `info`  | Server start/stop, config summary |
| `debug` | Detailed per-request tracing (only when compiled with `-d`) |

---

## 3. Log Rotation Strategies

Three complementary approaches are proposed. They are not mutually exclusive.

### 3.1 External Rotation via `logrotate` (Recommended for Linux/macOS)

No code changes needed. Handled entirely by the OS log management daemon.

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
        # Send SIGHUP to reopen log files after rotation
        kill -HUP $(cat /var/run/pshs.pid) 2>/dev/null || true
    endscript
}
```

**Requires:**
Signal handling (SIGHUP) in the server — see §3.2.
A PID file written at startup (e.g. `/var/run/pshs.pid`).

**Pros:** Battle-tested, cron-driven, compresses old logs, keeps N files automatically.
**Cons:** Requires OS-level setup; not self-contained.

### 3.2 Signal-Based Log Reopen (SIGHUP)

The server catches `SIGHUP` and calls `CloseLogFile()` + `OpenLogFile()` to reopen both log files. This is the standard mechanism used by Apache, Nginx, and Caddy to support external rotation.

```
logrotate renames access.log → access.log.1
logrotate sends SIGHUP to server
server receives SIGHUP → reopens "access.log" (creates new empty file)
logrotate compresses access.log.1
```

**PureBasic implementation:**
Signal handling on macOS/Linux via a background thread polling `sigtimedwait()` or via `OnErrorCall()` — or more simply, a periodic check flag set by a `signal()` handler installed with inline C via `ImportC`.

This is the most complex part of log management to implement in PureBasic (no built-in UNIX signal API). See §5 for implementation options.

### 3.3 Built-in Size-Based Rotation

The server rotates the log file automatically when it exceeds a configured size limit, requiring no external tools and working on all platforms including Windows.

**Behaviour:**
1. On each `LogAccess()` or `LogError()` call, check `Lof(g_LogFile) > g_LogMaxSize`
2. If over limit: close current file, rename `access.log` → `access.log.1` (shifting older files), open new `access.log`
3. Keep a configurable number of archived files (default: 5)

**New CLI flags:**
```
--log-size  <MB>   Rotate when log file exceeds N megabytes (default: 0 = disabled)
--log-keep  <N>    Number of rotated files to keep (default: 5)
```

**Example rotation sequence:**
```
access.log.4  →  deleted
access.log.3  →  access.log.4
access.log.2  →  access.log.3
access.log.1  →  access.log.2
access.log    →  access.log.1
              →  new access.log
```

**Pros:** Zero external dependencies, cross-platform, self-contained.
**Cons:** No compression; rotation happens mid-request (needs mutex); check on every write adds minor overhead.

### 3.4 Built-in Time-Based Rotation

The server rotates at midnight UTC, creating date-stamped archive files.

**Behaviour:**
- Background timer thread checks once per minute if the date has changed
- On date change: close current file, rename to `access.2026-03-14.log`, open new `access.log`

**New CLI flag:**
```
--log-daily        Rotate access and error logs daily at midnight UTC
```

**Pros:** Predictable file sizes for daily traffic; archive filenames are human-readable.
**Cons:** Requires a background thread; file accumulation without a keep-count limit.

---

## 4. Proposed New CLI Flags

| Flag | Type | Default | Description |
|------|------|---------|-------------|
| `--log FILE` | existing | *(disabled)* | Access log file path (keep existing) |
| `--error-log FILE` | new | *(disabled)* | Error log file path |
| `--log-format FORMAT` | new | `combined` | `combined` \| `common` \| `custom` |
| `--log-size MB` | new | `0` | Size-based rotation threshold in MB (0 = off) |
| `--log-keep N` | new | `5` | Max rotated files to keep (for size rotation) |
| `--log-daily` | new | off | Time-based daily rotation at midnight UTC |
| `--pid-file FILE` | new | *(none)* | Write PID to FILE on startup (needed for logrotate postrotate) |

---

## 5. Implementation Plan

### Phase F-1 — Format & Error Log (no rotation)

**Effort: medium**

Changes:
1. **`src/Logger.pbi`** — rewrite `LogAccess()` to emit Combined Log Format; add `LogError(level.s, message.s)` for the error log; separate file handles `g_AccessLogFile` / `g_ErrorLogFile`; add `OpenErrorLog(path.s)` / `CloseErrorLog()`
2. **`src/DateHelper.pbi`** or `Logger.pbi` — add `ApacheDate(ts.q)` returning `[DD/Mon/YYYY:HH:MM:SS +0000]` (Select/Case month abbreviation lookup)
3. **`src/FileServer.pbi`** — call `LogError("error", ...)` on 404/403/500 instead of returning silently
4. **`src/Config.pbi`** — add `ErrorLogFile.s` field to `ServerConfig`; parse `--error-log` flag
5. **`src/main.pb`** — open/close error log; pass actual HTTP status from `ServeFile()` (change return type to status code integer)
6. **`tests/test_logger.pb`** — new tests for Combined Log Format line structure, `LogError()` format

**Signature change for `ServeFile()`:**
Return the actual HTTP status code (200, 206, 304, 403, 404, 500) instead of `#True`/`#False`. This is a breaking change to the internal API — all callers in `main.pb` must be updated, but there are no external users of this function.

### Phase F-2 — Size-Based Rotation

**Effort: small–medium**

Changes:
1. **`src/Logger.pbi`** — add `RotateLogIfNeeded(path.s, *file.i, maxBytes.i, keepCount.i)` helper; call from `LogAccess()` and `LogError()` inside the mutex lock
2. **`src/Config.pbi`** — add `LogMaxSizeMB.i`, `LogKeepCount.i` fields; parse `--log-size` and `--log-keep`
3. **`tests/test_logger.pb`** — test rotation trigger and file renaming

### Phase F-3 — Daily Rotation + PID File

**Effort: medium**

Changes:
1. **`src/Logger.pbi`** — add background `LogRotationThread` that sleeps until next midnight and renames files
2. **`src/Config.pbi`** — add `LogDaily.i`, `PidFile.s`; parse `--log-daily`, `--pid-file`
3. **`src/main.pb`** — write PID file on startup, delete on shutdown

### Phase F-4 — SIGHUP Log Reopen (Linux/macOS only)

**Effort: high**

Changes:
1. **`src/SignalHandler.pbi`** (new) — install `SIGHUP` handler using PureBasic's `ImportC` block to call `signal(SIGHUP, handler)` with a C shim; set a global flag `g_ReopenLogs.i`
2. **`src/Logger.pbi`** — check `g_ReopenLogs` flag in the log write path; if set, reopen both log files and clear the flag
3. **`src/Config.pbi`** — `--pid-file` (shared with Phase F-3)
4. **`CompilerIf #PB_Compiler_OS = #PB_OS_Linux Or #PB_Compiler_OS = #PB_OS_MacOS`** — guard all signal code

---

## 6. Recommended Implementation Order

| Priority | Phase | What you get |
|----------|-------|-------------|
| **High** | F-1 | Standard log format compatible with GoAccess, AWStats, fail2ban; visible error log |
| **Medium** | F-2 | Self-contained rotation, works on all platforms, no external dependencies |
| **Low** | F-3 | Daily named archives; clean disk usage without manual cron |
| **Optional** | F-4 | Full logrotate integration; only needed for systemd/init.d deployments |

For a self-contained single-binary server, **F-1 + F-2** covers the majority of real-world needs.
F-4 (SIGHUP) is only worth the complexity if the server will be managed by a system daemon that expects the standard `kill -HUP` reload protocol.

---

## 7. Log Analysis Tooling (no server changes needed after F-1)

Once the Combined Log Format is in place:

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

## 8. Open Questions for Review

1. **Byte count accuracy** — Should `ServeFile()` return the actual bytes sent (requires API change), or is `-` acceptable for 304/empty responses and approximate for others?
2. **Timestamp timezone** — UTC (`+0000`) always, or local timezone? Apache defaults to local time; UTC is safer for distributed analysis.
3. **Rotation scope** — Is size-based rotation (F-2) sufficient, or is daily rotation (F-3) also needed from the start?
4. **SIGHUP priority** — Is logrotate integration (F-4) required, or will manual restart / size-based rotation suffice?
5. **Error log verbosity** — Should `info`-level entries (server start/stop, config echo) go to the error log, or to stdout only?
6. **Windows compatibility** — F-4 (SIGHUP) is Linux/macOS only. Is Windows a target platform for production deployments?
