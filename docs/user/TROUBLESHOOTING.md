# Troubleshooting

This guide covers common problems, their causes, and solutions. Start by checking the error log with `--log-level info` to see detailed diagnostic messages.

## "Address already in use" / "Bind failed"

### Symptom

Server fails to start with an error like:

```
Error: Address already in use
Bind failed on 127.0.0.1:8080
```

### Cause

Another process is already listening on the same port.

### Solution

**Find the process using the port:**

On macOS/Linux with lsof:

```bash
lsof -i :8080
```

Output example:

```
COMMAND   PID       USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
python    1234      user   3u  IPv4 0x1234...      0t0  TCP *:8080 (LISTEN)
```

On Linux with netstat:

```bash
netstat -tuln | grep :8080
```

**Kill or stop the conflicting process:**

```bash
kill 1234
```

**Or use a different port:**

```bash
./PureSimpleHTTPServer --port 8081
```

## "403 Forbidden" on a file you own

### Symptom

Requesting a file returns 403 Forbidden, even though the file exists and is readable.

### Cause

The file path is in a blocked list. PureSimpleHTTPServer hides sensitive files and directories by default:

- `.git` — Version control metadata
- `.env` — Environment variables and secrets
- `.DS_Store` — macOS metadata
- `.gitignore`, `.gitattributes` — Git configuration
- Files starting with a dot (hidden files on Unix)

### Solution

**Check if the file is hidden:**

```bash
ls -la /path/to/file
```

If the filename starts with a dot or is in the hidden list, either:

1. **Rename the file** to a public name (recommended for secrets)
2. **Move it outside the web root** (recommended for `.env`)
3. **Check your rewrite rules** — they may be blocking the path incorrectly

To serve hidden files (use with caution):

```bash
./PureSimpleHTTPServer --allow-hidden-files
```

## "404 Not Found" when file exists

### Symptom

Requesting a file returns 404 Not Found, but the file clearly exists:

```bash
ls -la /var/www/file.html
# -rw-r--r-- file.html
```

### Cause

Common causes:

1. **Wrong `--root` directory** — The server is looking in the wrong place
2. **Relative vs. absolute paths** — `--root ./www` vs. `--root /var/www`
3. **File not under root** — The file is outside the specified root directory
4. **Missing index file** — Accessing a directory without index.html

### Solution

**Verify the root directory:**

```bash
./PureSimpleHTTPServer --log-level info --root /var/www
```

Check the startup log:

```
[INFO] Server started with root: /var/www
```

**Use absolute paths in production:**

```bash
# Bad: relative path
./PureSimpleHTTPServer --root ./www

# Good: absolute path
./PureSimpleHTTPServer --root /var/www
```

**Verify the file is in root:**

```bash
# If root is /var/www, the file must be at:
/var/www/file.html     # OK
/var/file.html         # NOT OK (outside root)
```

## Directory listing shows instead of index page

### Symptom

Visiting `/` or a subdirectory shows a file listing instead of loading `index.html`.

### Cause

PureSimpleHTTPServer is not finding an `index.html` file in the directory, so it falls back to showing a listing. This happens when:

1. The index file doesn't exist
2. The index file has a different name
3. The index file is in the wrong location

### Solution

**Check for index.html:**

```bash
ls -la /var/www/
# Should include: index.html
```

**Create an index file if missing:**

```bash
echo "<h1>Welcome</h1>" > /var/www/index.html
```

**Verify the filename:**

PureSimpleHTTPServer looks specifically for `index.html` (lowercase). Ensure it's not named `Index.html` or `index.htm`.

**Check subdirectories:**

If you want a subdirectory to serve a landing page, add `index.html` to it:

```bash
echo "<h1>Subdir</h1>" > /var/www/docs/index.html
```

## SPA: Refreshing a deep route shows 404

### Symptom

A single-page application (SPA) works when navigating via internal links, but refreshing the browser on a deep route like `/dashboard/settings` shows 404 Not Found.

### Cause

The browser requests `/dashboard/settings` from the server, but there's no actual file at that path. SPAs handle routing in JavaScript, so all requests should serve `index.html` to let the client-side router work.

### Solution

Enable SPA mode:

```bash
./PureSimpleHTTPServer --root /var/www --spa
```

With `--spa`, all requests for missing files are rewritten to serve `index.html`, allowing your client-side router to handle the path.

This works for any path that isn't a real file:

```
/dashboard/settings     -> index.html (rewritten)
/api/users             -> index.html (rewritten, if no /api/users file exists)
/js/app.js             -> app.js (served directly, file exists)
```

## Clean URLs not working

### Symptom

Visiting `/about` returns 404, but `/about.html` works.

### Cause

You forgot to enable clean URLs, or the actual file doesn't have a `.html` extension.

### Solution

**Enable clean URLs:**

```bash
./PureSimpleHTTPServer --root /var/www --clean-urls
```

With `--clean-urls`, the server tries these in order:

```
/about          -> /about.html (if it exists)
                -> /about/index.html (if it exists)
                -> 404 (if neither exists)
```

**Verify files exist with .html extension:**

```bash
ls -la /var/www/
# Must have: about.html (or about/index.html)
```

Clean URLs cannot create or rename files—they only rewrite requests to existing `.html` files.

## Rewrite rule not matching

### Symptom

A rewrite rule in `rewrite.conf` isn't triggering; requests are returning 404 instead of being rewritten.

### Cause

Common issues:

1. **Wrong pattern type** — Using regex syntax in a simple pattern, or vice versa
2. **Missing leading slash** — Pattern doesn't start with `/`
3. **File exists** — If the exact file exists, rewrite rules don't apply (rewrite is a fallback)
4. **Rule syntax error** — Invalid regex or destination format

### Solution

**Enable info-level logging to see rule matching:**

```bash
./PureSimpleHTTPServer --log-level info --root /var/www
```

Check the logs for rule evaluation:

```
[INFO] Evaluating rewrite rule: /api/* -> /api.php
[INFO] /api/users matched; rewriting to /api.php
[INFO] /static/app.css did not match
```

**Check your rewrite.conf syntax:**

Simple pattern example:

```
/api/* /api.php
```

Regex pattern example (with `^`):

```
^/old/(.*) /new/$1
```

**Verify the destination file exists:**

```bash
# Rule: /api/* -> /api.php
ls -la /var/www/api.php
# Must exist and be readable
```

**Test patterns manually:**

If your destination is `/api.php`, verify it's accessible directly:

```bash
curl http://localhost:8080/api.php
```

## Log file not created

### Symptom

You set `--log /var/log/pshs/access.log`, but the file isn't created; instead, the server shows a warning or fails to start.

### Cause

1. **Directory doesn't exist** — `/var/log/pshs/` wasn't created
2. **No write permission** — The process user can't write to the directory
3. **Path error** — Typo in the path

### Solution

**Create the log directory:**

```bash
mkdir -p /var/log/pshs
```

**Set correct ownership and permissions:**

Replace `www-data` with the user running the server:

```bash
chown www-data:www-data /var/log/pshs
chmod 750 /var/log/pshs
```

**Verify write permission:**

```bash
touch /var/log/pshs/access.log
chmod 640 /var/log/pshs/access.log
```

**Check the full path:**

Use absolute paths; relative paths may not work as expected:

```bash
# Bad: relative
./PureSimpleHTTPServer --log ./logs/access.log

# Good: absolute
./PureSimpleHTTPServer --log /var/log/pshs/access.log
```

## Server stops after terminal closes

### Symptom

The server runs fine while the terminal is open, but stops as soon as you close the terminal or disconnect.

### Cause

The process is attached to the terminal session. When the terminal exits, the process receives SIGHUP and terminates.

### Solution

**Use nohup:**

```bash
nohup ./PureSimpleHTTPServer --root /var/www > /tmp/server.log 2>&1 &
```

This detaches the process from the terminal.

**Or use a service manager (recommended):**

**On systemd (Linux):**

Create `/etc/systemd/system/pshs.service`:

```ini
[Unit]
Description=PureSimpleHTTPServer
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/opt/pshs
ExecStart=/opt/pshs/PureSimpleHTTPServer --root /var/www --log /var/log/pshs/access.log
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
```

Enable and start:

```bash
sudo systemctl enable pshs
sudo systemctl start pshs
```

**On launchd (macOS):**

Create `~/Library/LaunchAgents/com.pshs.server.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.pshs.server</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/PureSimpleHTTPServer</string>
        <string>--root</string>
        <string>/var/www</string>
        <string>--log</string>
        <string>/var/log/pshs/access.log</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
```

Load the agent:

```bash
launchctl load ~/Library/LaunchAgents/com.pshs.server.plist
```

## High CPU under load

### Symptom

CPU usage spikes to 100% when handling many concurrent connections, even though the requests themselves are simple.

### Cause

This is often normal behavior—handling many connections requires CPU work. However, logging can amplify this:

- Every request generates a log entry
- Disk I/O for logging is slower than request handling
- High concurrency means many log writes per second

### Solution

**Reduce logging overhead:**

Use `--log-level none` to disable error logging and keep only access logs:

```bash
./PureSimpleHTTPServer --log /var/log/pshs/access.log --log-level none
```

Or disable access logging entirely if you don't need it (e.g., for internal APIs):

```bash
./PureSimpleHTTPServer --log-level warn
```

**Monitor actual bottleneck:**

Use profiling tools to identify the real bottleneck:

```bash
# On macOS with Activity Monitor:
# 1. Start the server
# 2. Open Activity Monitor
# 3. Sort by CPU and check context switches, threads, I/O
```

**Consider your hardware:**

High CPU on many concurrent connections is normal. Upgrade to a faster CPU or multi-core machine if needed.

## Binary not executable

### Symptom

Trying to run the server shows "Permission denied" or "command not found":

```bash
./PureSimpleHTTPServer
# bash: ./PureSimpleHTTPServer: Permission denied
```

### Cause

The binary doesn't have execute permission.

### Solution

Add execute permission:

```bash
chmod +x ./PureSimpleHTTPServer
```

Verify:

```bash
ls -la PureSimpleHTTPServer
# Should show: -rwxr-xr-x (executable bit set)
```

## Wrong files served / wrong --root path

### Symptom

The server is serving files from the wrong directory, or paths are being resolved incorrectly.

### Cause

The `--root` path is relative or contains symlinks that resolve differently than expected.

### Solution

**Always use absolute paths in production:**

```bash
# Bad
./PureSimpleHTTPServer --root ./www

# Good
./PureSimpleHTTPServer --root /var/www
```

Relative paths depend on the current working directory, which can change. Absolute paths are unambiguous.

**Check the actual root being used:**

```bash
./PureSimpleHTTPServer --log-level info --root /var/www | head -20
```

Look for the startup log message:

```
[INFO] Server started with root: /var/www
```

**Verify symlinks resolve correctly:**

If your root directory contains symlinks:

```bash
# See the real path
realpath /var/www
```

**Test a specific file:**

```bash
curl http://localhost:8080/index.html -v
```

The log will show which file was actually served.

## SIGHUP not working for logrotate

### Symptom

You ran `kill -HUP $(cat /var/run/pshs.pid)`, but the log file wasn't reopened or logrotate still reports an error.

### Cause

1. **PID file not set** — The server was started without `--pid-file`, so no PID file exists
2. **Wrong PID** — The PID file contains an old PID; the process isn't running
3. **Log file path** — The server was started without `--log`, so there are no logs to reopen

### Solution

**Start the server with `--pid-file`:**

```bash
./PureSimpleHTTPServer \
    --root /var/www \
    --log /var/log/pshs/access.log \
    --pid-file /var/run/pshs.pid
```

**Verify the PID file exists and is valid:**

```bash
cat /var/run/pshs.pid
# Should output a number

ps aux | grep $(cat /var/run/pshs.pid)
# Should show the running process
```

**Test SIGHUP manually:**

```bash
kill -HUP $(cat /var/run/pshs.pid)
echo "Exit code: $?"
```

If the command shows "No such process", the PID is stale.

**Check logrotate configuration:**

Ensure `/etc/logrotate.d/pshs` references the correct PID file:

```ini
postrotate
    kill -HUP $(cat /var/run/pshs.pid) 2>/dev/null || true
endscript
```

## Per-directory rewrite.conf not picked up

### Symptom

You created a `rewrite.conf` file in a subdirectory, but the rules aren't being applied.

### Cause

1. **File not inside `--root`** — Rewrite rules are only loaded from within the root directory
2. **File not found** — The path doesn't exist or is misspelled
3. **File not readable** — The process user doesn't have read permission
4. **Old rules cached** — The server loaded rules at startup; changes require a restart

### Solution

**Verify the file is in the root directory:**

```bash
# If --root is /var/www
ls -la /var/www/subdir/rewrite.conf
# Must exist and be readable
```

**Check file permissions:**

```bash
chmod 644 /var/www/subdir/rewrite.conf
```

**Restart the server to reload rules:**

```bash
kill $(cat /var/run/pshs.pid)
./PureSimpleHTTPServer --root /var/www --log-level info
```

**Check startup logs for rewrite rules:**

```bash
./PureSimpleHTTPServer --log-level info | grep -i rewrite
```

You should see:

```
[INFO] Loaded rewrite rules from /var/www/rewrite.conf
[INFO] Loaded rewrite rules from /var/www/subdir/rewrite.conf
```

If a file is missing, you'll see:

```
[WARN] Rewrite file not found: /var/www/subdir/rewrite.conf
```

---

## "Certificate file not found" / TLS startup error

### Symptom

Server fails to start with:

```
ERROR: Cannot read TLS certificate file: cert.pem
```

or

```
ERROR: Cannot read TLS key file: key.pem
```

### Cause

The `--tls-cert` or `--tls-key` path does not point to a readable file, or both flags were not specified together.

### Solution

**Verify both files exist and are readable:**

```bash
ls -la cert.pem key.pem
```

**Both flags must be specified together:**

```bash
# Wrong — only one flag
./PureSimpleHTTPServer --tls-cert cert.pem

# Correct — both flags
./PureSimpleHTTPServer --tls-cert cert.pem --tls-key key.pem
```

**Use absolute paths in production:**

```bash
./PureSimpleHTTPServer --tls-cert /etc/ssl/certs/server.pem --tls-key /etc/ssl/private/server.key
```

---

## "acme.sh not installed" / Auto-TLS errors

### Symptom

Server fails to start with:

```
ERROR: Failed to obtain TLS certificate
       Make sure acme.sh is installed (~/.acme.sh/acme.sh)
       and port 80 is accessible from the internet
```

### Cause

1. **acme.sh is not installed** at `~/.acme.sh/acme.sh`
2. **Port 80 is blocked** by a firewall or another process
3. **DNS is not configured** — the domain doesn't resolve to this server's IP

### Solution

**Install acme.sh:**

```bash
curl https://get.acme.sh | sh
```

**Check port 80 is available:**

```bash
lsof -i :80
```

If another process is using port 80, stop it or reconfigure it.

**Verify DNS:**

```bash
dig +short example.com
# Should return this server's public IP
```

---

## "Port 80 already in use" (ACME challenge)

### Symptom

Auto-TLS fails because port 80 is already occupied (e.g., by Apache, nginx, or another web server).

### Cause

The `--auto-tls` feature starts an HTTP listener on port 80 to serve ACME HTTP-01 challenge files and redirect other traffic to HTTPS. If port 80 is already in use, this fails.

### Solution

**Stop the process using port 80:**

```bash
# Find and stop the conflicting process
lsof -i :80
sudo kill <PID>
```

**Or use manual TLS instead:**

If you cannot free port 80, obtain your certificate separately and use manual TLS:

```bash
# Obtain cert with acme.sh standalone mode (temporarily binds port 80)
~/.acme.sh/acme.sh --issue -d example.com --standalone

# Then start with manual TLS
./PureSimpleHTTPServer --port 443 \
  --tls-cert ~/.acme.sh/example.com_ecc/fullchain.cer \
  --tls-key ~/.acme.sh/example.com_ecc/example.com.key
```

---

## Certificate renewal failed

### Symptom

The server logs show renewal errors, or after 90 days the certificate expires.

### Cause

The background renewal thread checks every 12 hours and calls `acme.sh --renew`. This can fail if:

1. Port 80 is no longer accessible from the internet
2. The acme.sh installation was removed or corrupted
3. DNS changed and no longer points to this server

### Solution

**Test renewal manually:**

```bash
~/.acme.sh/acme.sh --renew -d example.com --force
```

**Check the error log for renewal messages:**

```bash
grep -i "renew\|tls\|cert" /var/log/pshs/error.log
```

**Restart the server** after fixing the underlying issue — the renewal thread will attempt renewal on the next 12-hour cycle.

---

## Getting Help

If you've worked through this guide and still have issues:

1. **Check the README** — See `/Users/worajedt/PureBasic_Projects/PureSimpleHTTPServer/README.md` for quick-start examples and flag reference

2. **Review other documentation** — See the `/docs/user/` directory for guides on:
   - `LOGGING.md` — How to set up and monitor logs
   - Configuration flags and rewrite rules

3. **Enable detailed logging** — Start the server with `--log-level info` and `--error-log` to see what's happening:

   ```bash
   ./PureSimpleHTTPServer \
       --root /var/www \
       --log /var/log/pshs/access.log \
       --error-log /var/log/pshs/error.log \
       --log-level info
   ```

4. **Check system logs** — On systemd systems:

   ```bash
   journalctl -u pshs -f
   ```

5. **Report issues** — If you believe you've found a bug:
   - Note your command line and OS version
   - Include relevant log excerpts
   - Try to reproduce with the simplest possible setup
   - Visit the project repository to file an issue
