================================================================================
PureSimpleHTTPServer v2.4.0 - Windows Distribution
================================================================================

A fast, single-binary HTTP/1.1 static file server with middleware architecture,
HTTPS, and dynamic gzip compression -- written in PureBasic.

Reference model: Caddy file-server


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

  PureSimpleHTTPServer.exe --port 8443 --tls-cert cert.pem --tls-key key.pem
    Start with HTTPS using manual certificates


COMMAND-LINE OPTIONS
================================================================================

Server:
  --port N           Set port number (default: 8080)
  --root DIR         Set web root directory (default: wwwroot)
  --browse           Enable directory listing
  --spa              Enable Single Page Application mode

TLS:
  --tls-cert FILE    Path to PEM certificate file
  --tls-key FILE     Path to PEM private key file
  --auto-tls DOMAIN  Automatic HTTPS via acme.sh

Compression:
  --no-gzip          Disable dynamic gzip compression

Logging:
  --log FILE         Enable access log to FILE
  --error-log FILE   Enable error log to FILE
  --log-level LEVEL  Set log level: none, error, warn (default), info
  --log-size MB      Rotate log when it exceeds MB (default: 100; 0 = disabled)
  --log-keep N       Max rotated archive files to keep (default: 30)
  --no-log-daily     Disable daily log rotation at midnight
  --pid-file FILE    Write process ID to FILE at startup

URL:
  --clean-urls       Enable clean URLs (extensionless paths try .html)
  --rewrite FILE     Load rewrite rules from FILE

Security & API:
  --health PATH      Health check endpoint returning {"status":"ok"}
  --cors             Enable CORS (Access-Control-Allow-Origin: *)
  --cors-origin URL  Enable CORS restricted to specific origin
  --security-headers Add security headers to all responses

Windows Service:
  --install          Install as Windows service (requires Administrator)
  --uninstall        Uninstall Windows service
  --start            Start Windows service
  --stop             Stop Windows service
  --service          Run as Windows service (called by SCM)
  --service-name N   Custom service name (default: PureSimpleHTTPServer)


FEATURES
================================================================================

- HTTP/1.1 static file serving with Content-Type, ETag, Last-Modified
- 304 Not Modified via If-None-Match
- 206 Partial Content via Range header
- Middleware architecture with 14-stage ordered chain
- HTTPS with manual certificates or automatic via acme.sh
- Dynamic gzip compression for text, JSON, JS, XML, SVG
- Pre-compressed .gz sidecar support (Content-Encoding: gzip)
- Directory listing (opt-in via --browse)
- SPA fallback (opt-in via --spa)
- Hidden path blocking (.git, .env, .DS_Store by default)
- Embedded asset serving (opt-in at build time)
- Thread-per-connection for concurrent request handling
- Access log in Apache Combined Log Format (CLF)
- Error log with level filtering
- URL rewriting and redirecting via rewrite.conf
- Per-directory rewrite rules
- Clean URLs (--clean-urls: /page -> /page.html)
- Health check endpoint for load balancer probes (--health PATH)
- CORS support with OPTIONS preflight (--cors, --cors-origin ORIGIN)
- Security headers (--security-headers)
- Native Windows Service support with Event Log integration


SYSTEM REQUIREMENTS
================================================================================

- Windows 7 or later
- 512 MB RAM minimum
- 10 MB disk space


SUPPORT
================================================================================

For detailed documentation, see README.md (Markdown format)
See docs/ directory for user guides and developer reference


LICENSE
================================================================================

MIT License - See LICENSE.txt for details


CHANGELOG
================================================================================

See CHANGELOG.txt for version history and changes.
