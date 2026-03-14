# Logging

PureSimpleHTTPServer provides comprehensive logging capabilities for both access and error events. Logs help you monitor traffic, diagnose problems, and comply with audit requirements.

## Access Log

### Enabling the Access Log

Use the `--log` flag to write access logs to a file:

```bash
./PureSimpleHTTPServer --log /var/log/pshs/access.log
```

Every HTTP request—successful or failed—is logged with detailed information about the client, request, and response.

### Log Format

Access logs use the **Apache Combined Log Format**, a widely-recognized standard compatible with log analysis tools.

Example access log line:

```
127.0.0.1 - - [15/Mar/2026:04:00:01 +0000] "GET /index.html HTTP/1.1" 200 9300 "-" "curl/7.88"
```

### Field Reference

| Field | Example | Description |
|-------|---------|-------------|
| Client IP | `127.0.0.1` | IP address of the requesting client |
| Remote identity | `-` | Usually `-` (from RFC 1413 ident protocol, rarely used) |
| Remote user | `-` | Username for authenticated requests; `-` if none |
| Timestamp | `[15/Mar/2026:04:00:01 +0000]` | Date and time in UTC (day/month/year:hour:minute:second timezone) |
| HTTP method | `GET` | Request method: GET, POST, PUT, DELETE, HEAD, OPTIONS, etc. |
| Request URI | `/index.html` | Path and query string requested by the client |
| HTTP version | `HTTP/1.1` | HTTP protocol version used by the client |
| Status code | `200` | HTTP response code (200=OK, 404=Not Found, 500=Error, etc.) |
| Response size | `9300` | Number of bytes sent to the client in the response body |
| Referrer | `-` | Referring page (Referer header); `-` if not present |
| User-Agent | `curl/7.88` | Browser or client software identifier |

## Error Log

### Enabling the Error Log

Use the `--error-log` flag to write server errors and warnings to a file:

```bash
./PureSimpleHTTPServer --error-log /var/log/pshs/error.log
```

### Log Levels

Control the verbosity of error logging with `--log-level`:

| Level | Flag | Behavior |
|-------|------|----------|
| `none` | `--log-level none` | No error logging (silent operation) |
| `error` | `--log-level error` | Only critical failures (file I/O, crashes) |
| `warn` | `--log-level warn` | Default; includes warnings (missing files, permission issues) |
| `info` | `--log-level info` | Informational messages (startup, configuration, request handling details) |

### Example Error Log Output

**warn level (default):**

```
2026-03-15 04:00:01 [WARN] File not found: /var/www/nonexistent.html
2026-03-15 04:00:02 [WARN] Permission denied reading /root/.ssh/id_rsa
2026-03-15 04:00:03 [WARN] Rewrite rule pattern invalid: [invalid regex]
```

**error level:**

```
2026-03-15 04:00:01 [ERROR] Failed to open access log: /var/log/pshs/access.log
2026-03-15 04:00:02 [ERROR] Out of memory allocating buffer
```

**info level:**

```
2026-03-15 04:00:00 [INFO] Server started on 127.0.0.1:8080
2026-03-15 04:00:00 [INFO] Root directory: /var/www
2026-03-15 04:00:01 [INFO] GET /index.html matched SPA rewrite rule
2026-03-15 04:00:02 [WARN] File not found: /var/www/style.css
2026-03-15 04:00:03 [INFO] Serving index.html as fallback
```

### Choosing a Log Level

- **Production:** Use `warn` (default) to catch issues without verbose output
- **Debugging:** Use `info` to trace request handling and rule matching
- **Performance-critical:** Use `error` or `none` to minimize logging I/O overhead
- **Silent operation:** Use `none` (combine with `--log` for access-only logging)

## Log Rotation — Size-Based

### Configuration

PureSimpleHTTPServer can automatically rotate log files based on size:

```bash
./PureSimpleHTTPServer --log /var/log/pshs/access.log --log-size 100 --log-keep 30
```

| Flag | Default | Description |
|------|---------|-------------|
| `--log-size MB` | 100 | Rotate when log file reaches this size in megabytes; 0 disables |
| `--log-keep N` | 30 | Number of archived log files to retain |

### Archive Naming

When a log file reaches the size limit, it is renamed with a timestamp suffix, and a new log file is created:

```
access.log                           (current, actively written)
access.log.2026-03-15T04:00:01       (archived)
access.log.2026-03-15T03:50:23       (archived)
access.log.2026-03-14T23:45:12       (archived)
```

The timestamp format is ISO 8601: `YYYY-MM-DDTHH:MM:SS`.

### Archive Pruning

After rotation, PureSimpleHTTPServer automatically deletes the oldest archives to keep only `--log-keep` files. For example, with `--log-keep 30`:

- When the 31st archive is created, the oldest archive is deleted
- Effective retention is approximately 30 * 100 MB = 3 GB (at default settings)

## Log Rotation — Daily

### Automatic Daily Rotation

When you enable the access log with `--log`, PureSimpleHTTPServer automatically rotates logs at midnight UTC:

```bash
./PureSimpleHTTPServer --log /var/log/pshs/access.log
```

Daily rotation occurs in addition to size-based rotation—both mechanisms are active simultaneously.

### Disabling Daily Rotation

To disable daily rotation (keeping size-based rotation if set):

```bash
./PureSimpleHTTPServer --log /var/log/pshs/access.log --no-log-daily
```

This is useful when you prefer to manage rotation entirely with logrotate or another external tool.

## Logrotate Integration (Linux/macOS)

### How It Works

PureSimpleHTTPServer supports the `SIGHUP` signal for graceful log file reopening. This allows logrotate to rotate logs without losing data or restarting the server.

When the server receives `SIGHUP`, it:

1. Flushes and closes the current access and error log files
2. Reopens the log files (which logrotate has moved and recreated)
3. Continues operation without interruption

### Sample Logrotate Configuration

Create `/etc/logrotate.d/pshs`:

```
/var/log/pshs/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 0640 www-data www-data
    sharedscripts
    postrotate
        kill -HUP $(cat /var/run/pshs.pid) 2>/dev/null || true
    endscript
}
```

### Key Configuration Details

- `daily`: Rotate once per day (adjust as needed)
- `rotate 30`: Keep 30 archived logs
- `compress`: Gzip old logs to save space
- `delaycompress`: Delay compression until the next rotation cycle
- `missingok`: Don't error if the log file doesn't exist
- `notifempty`: Don't rotate empty log files
- `create 0640 www-data www-data`: Create new log file with specified permissions and ownership
- `postrotate/endscript`: Run command after rotation; `kill -HUP` sends SIGHUP to the server process

### Running Logrotate

Manually test the configuration (dry run):

```bash
logrotate -d /etc/logrotate.d/pshs
```

Force an immediate rotation:

```bash
logrotate -f /etc/logrotate.d/pshs
```

### Testing SIGHUP Manually

If you start the server with a PID file:

```bash
./PureSimpleHTTPServer --log /var/log/pshs/access.log --pid-file /var/run/pshs.pid
```

Then send SIGHUP:

```bash
kill -HUP $(cat /var/run/pshs.pid)
```

Check that the log file was closed and reopened:

```bash
tail -f /var/log/pshs/access.log
```

You should see no interruption in request logging.

## Best Practices

### Log Directory Setup

Ensure the log directory exists with proper permissions:

```bash
sudo mkdir -p /var/log/pshs
sudo chown www-data:www-data /var/log/pshs
sudo chmod 750 /var/log/pshs
```

(Replace `www-data` with the user running the server.)

### Process Management

Combine `--log` and `--pid-file` for effective process management:

```bash
./PureSimpleHTTPServer \
    --root /var/www \
    --log /var/log/pshs/access.log \
    --error-log /var/log/pshs/error.log \
    --pid-file /var/run/pshs.pid
```

You can then signal the server safely:

```bash
kill -HUP $(cat /var/run/pshs.pid)  # Reload logs
kill -TERM $(cat /var/run/pshs.pid) # Graceful shutdown
```

### Real-Time Log Monitoring

Watch access logs in real time during testing or debugging:

```bash
tail -f /var/log/pshs/access.log
```

Or filter for a specific status code:

```bash
tail -f /var/log/pshs/access.log | grep " 404 "
```

### Log Analysis Tools

The Apache Combined Log Format is compatible with standard log analysis tools:

- **goaccess**: Interactive terminal log viewer
- **awstats**: Advanced web statistics
- **webalizer**: Log analysis and reporting
- **Apache tools**: logparse, logscan, etc.

Example with goaccess:

```bash
goaccess /var/log/pshs/access.log --log-format=COMBINED
```

### Performance Considerations

- Logging to a local SSD is fast; network mounts may cause slowdowns
- Use `--log-level none` if you only need access logs and want to reduce I/O
- Archive old logs regularly to prevent disk space exhaustion
- On high-traffic servers, consider writing logs to `/dev/shm` (RAM disk) and syncing periodically
