================================================================================
PureSimpleHTTPServer - Windows Distribution
================================================================================

A simple, single-binary HTTP/1.1 static file server written in PureBasic.

Reference model: Caddy file-server
Goal: Self-contained executable that bundles and serves a compiled web application


CURRENT STATUS
================================================================================

Phase  Version  Feature                                    Status
------ -------- -----------------------------------------  --------
A      v0.1.0   TCP server + HTTP/1.1 parser + response   Done
B      v0.2.0   Static file serving from disk             Done
C      v0.3.0   Directory listing, SPA fallback, Range    Done
D      v0.4.0   Embedded assets (IncludeBinary)           Done
E      v1.0.3   Thread-per-connection, access log, CLI    Done
F-1    v1.1.0   Apache Combined Log, error log, filtering  Done
F-2    v1.2.0   Size-based log rotation                   Done
F-3    v1.3.0   Daily rotation + PID file                 Done
F-4    v1.4.0   SIGHUP log reopen for logrotate           Done
G      v1.5.0   URL rewriting and redirecting             Done


QUICK START
================================================================================

1. Double-click PureSimpleHTTPServer.exe to start the server
2. Open your web browser to: http://localhost:8080
3. The server will serve files from the wwwroot directory

Command-line examples:

  PureSimpleHTTPServer.exe
    Start on port 8080 serving wwwroot

  PureSimpleHTTPServer.exe --port 3000 --root C:\MyWebsite
    Start on port 3000 serving C:\MyWebsite

  PureSimpleHTTPServer.exe --browse --log access.log
    Start with directory browsing and access logging


COMMAND-LINE OPTIONS
================================================================================

--port N           Set port number (default: 8080)
--root DIR         Set web root directory (default: wwwroot)
--browse           Enable directory listing
--spa              Enable Single Page Application mode
--log FILE         Enable access log to FILE
--error-log FILE   Enable error log to FILE
--log-level LEVEL  Set log level (0=none, 1=error, 2=warn, 3=info, 4=debug)
--log-size MB      Rotate log when it exceeds MB (default: 100; 0 = disabled)
--log-keep N       Max rotated archive files to keep (default: 30)
--no-log-daily     Disable daily log rotation at midnight
--pid-file FILE    Write process ID to FILE at startup
--clean-urls       Enable clean URLs (extensionless paths try .html)
--rewrite FILE     Load rewrite rules from FILE
--help             Show all options


FEATURES
================================================================================

- HTTP/1.1 static file serving with Content-Type, ETag, Last-Modified
- 304 Not Modified via If-None-Match
- 206 Partial Content via Range header
- Directory listing (opt-in via --browse)
- SPA fallback (opt-in via --spa)
- Hidden path blocking (.git, .env, .DS_Store by default)
- Pre-compressed .gz sidecar support (Content-Encoding: gzip)
- Embedded asset serving (opt-in at build time)
- Thread-per-connection for concurrent request handling
- Access log in Apache Combined Log Format (CLF)
- Error log with level filtering
- URL rewriting and redirecting via rewrite.conf
- Per-directory rewrite rules (rewrite.conf in any served directory)
- Clean URLs (--clean-urls: /page -> /page.html)


LOAD TESTING
================================================================================

Verified with Apache Bench:

  ab -n 1000 -c 10 http://127.0.0.1:8080/

Metric              Result
------------------- ------------------------------------------
Requests            1000 / 1000 (no failures)
Concurrency         10 simultaneous connections
Mean response time  2 ms
Transfer rate       ~38 MB/s
Crashes             None


SYSTEM REQUIREMENTS
================================================================================

- Windows 7 or later
- 512 MB RAM minimum
- 10 MB disk space


SUPPORT
================================================================================

GitHub: https://github.com/woraj/PureSimpleHTTPServer

For detailed developer documentation, see README.md (Markdown format)


LICENSE
================================================================================

MIT License - See LICENSE.txt for details


CHANGELOG
================================================================================

See CHANGELOG.txt for version history and changes.
