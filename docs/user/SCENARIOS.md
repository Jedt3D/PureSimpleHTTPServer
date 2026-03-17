# Scenarios Guide — PureSimpleHTTPServer v2.5.0

Real-world configurations for common deployment patterns. Each scenario is self-contained: read only what you need. Every example assumes the binary is named `PureSimpleHTTPServer` and is in your current directory or `PATH`. Adjust paths to match your environment.

---

## Table of Contents

**1. Zero-Config Quick Start**
- [Scenario 1: Serve a Folder on Port 8080](#scenario-1-serve-a-folder-on-port-8080)
- [Scenario 2: Serve on a Different Port](#scenario-2-serve-on-a-different-port)
- [Scenario 3: Serve from a Specific Directory Path](#scenario-3-serve-from-a-specific-directory-path)

**2. Development Workflows**
- [Scenario 4: React, Vue, or Angular SPA on Port 3000](#scenario-4-react-vue-or-angular-spa-on-port-3000)
- [Scenario 5: SPA Alongside Vite or webpack-dev-server](#scenario-5-spa-alongside-vite-or-webpack-dev-server)
- [Scenario 6: Multi-Port Staging vs Production](#scenario-6-multi-port-staging-vs-production)
- [Scenario 7: Clean URLs for a Static Site Generator Output](#scenario-7-clean-urls-for-a-static-site-generator-output)

**3. Static Site Hosting**
- [Scenario 8: Simple Static Site with Clean URLs](#scenario-8-simple-static-site-with-clean-urls)
- [Scenario 9: Documentation Site with Directory Listing](#scenario-9-documentation-site-with-directory-listing)
- [Scenario 10: Blog with URL Rewrites](#scenario-10-blog-with-url-rewrites)
- [Scenario 11: Image Gallery with Directory Listing](#scenario-11-image-gallery-with-directory-listing)

**4. API Mock Server**
- [Scenario 12: JSON Files as Mock API Endpoints](#scenario-12-json-files-as-mock-api-endpoints)
- [Scenario 13: Versioned API Path Rewrite](#scenario-13-versioned-api-path-rewrite)
- [Scenario 14: REST-Style Redirects](#scenario-14-rest-style-redirects)

**5. Logging Configurations**
- [Scenario 15: Development — No Logging](#scenario-15-development--no-logging)
- [Scenario 16: Staging — Access Log and Info-Level Error Log](#scenario-16-staging--access-log-and-info-level-error-log)
- [Scenario 17: Production — Access and Error Logs with Rotation](#scenario-17-production--access-and-error-logs-with-rotation)
- [Scenario 18: High-Traffic — Aggressive Rotation, No Daily Cycle](#scenario-18-high-traffic--aggressive-rotation-no-daily-cycle)
- [Scenario 19: Minimal — Error-Only Log Level](#scenario-19-minimal--error-only-log-level)
- [Scenario 20: logrotate Integration with PID File and SIGHUP](#scenario-20-logrotate-integration-with-pid-file-and-sighup)

**6. URL Rewriting Scenarios**
- [Scenario 21: Clean URLs with --clean-urls Only](#scenario-21-clean-urls-with---clean-urls-only)
- [Scenario 22: Custom Blog Slug Routing](#scenario-22-custom-blog-slug-routing)
- [Scenario 23: Redirect Old to New URL Structure (301)](#scenario-23-redirect-old-to-new-url-structure-301)
- [Scenario 24: Redirect www to Non-www](#scenario-24-redirect-www-to-non-www)
- [Scenario 25: API Versioning Redirect](#scenario-25-api-versioning-redirect)
- [Scenario 26: Regex-Based User Profile URLs](#scenario-26-regex-based-user-profile-urls)

**7. Deployment Patterns**
- [Scenario 27: macOS launchd Plist](#scenario-27-macos-launchd-plist)
- [Scenario 28: Linux systemd Unit File](#scenario-28-linux-systemd-unit-file)
- [Scenario 29: Docker CMD Line](#scenario-29-docker-cmd-line)
- [Scenario 30: nginx Reverse Proxy Frontend](#scenario-30-nginx-reverse-proxy-frontend)
- [Scenario 31: Run as a Non-Root User on Port 8080](#scenario-31-run-as-a-non-root-user-on-port-8080)

**8. Multiple Instances**
- [Scenario 32: Two Sites on Different Ports](#scenario-32-two-sites-on-different-ports)
- [Scenario 33: A/B Test Setup](#scenario-33-ab-test-setup)

**9. Embedded Assets Build**
- [Scenario 34: Compile-Time Asset Embedding](#scenario-34-compile-time-asset-embedding)

**10. Security Notes**
- [Scenario 35: Hidden Path Blocking](#scenario-35-hidden-path-blocking)
- [Scenario 36: TLS and Auth via nginx or Caddy](#scenario-36-tls-and-auth-via-nginx-or-caddy)
- [Scenario 37: Network Exposure Warning](#scenario-37-network-exposure-warning)

**11. Authentication and Error Pages (v2.5.0+)**
- [Scenario 38: Basic Auth for a Staging Site](#scenario-38-basic-auth-for-a-staging-site)
- [Scenario 39: Custom Error Pages for a Branded Site](#scenario-39-custom-error-pages-for-a-branded-site)
- [Scenario 40: Cache-Control for Fingerprinted Assets](#scenario-40-cache-control-for-fingerprinted-assets)

---

## 1. Zero-Config Quick Start

These three scenarios cover the fastest ways to get a server running with no configuration beyond the essentials.

---

### Scenario 1: Serve a Folder on Port 8080

Serve the `wwwroot/` folder next to the binary on the default port. No flags needed. Open `http://localhost:8080/` in a browser.

```bash
./PureSimpleHTTPServer
```

**What is happening:** The server uses built-in defaults — port 8080, document root `wwwroot/` next to the binary, no logging, no directory listing, no SPA mode. If `wwwroot/index.html` exists, it is served at `/`. If not, every request to the root returns `403 Forbidden` (directory listing is off by default).

**Tip:** Add `--browse` if you want to navigate the folder structure without an `index.html`:

```bash
./PureSimpleHTTPServer --browse
```

---

### Scenario 2: Serve on a Different Port

You want port 3000 or any other port because 8080 is already occupied, or because you prefer a different convention.

```bash
./PureSimpleHTTPServer --port 3000
```

Open `http://localhost:3000/`. Any unprivileged port (1024–65535) works without root. Ports below 1024 require elevated permissions:

```bash
sudo ./PureSimpleHTTPServer --port 80
```

**Note:** You can also pass the port as a bare integer (legacy form):

```bash
./PureSimpleHTTPServer 3000
```

This shorthand only works when it is the single argument. For any more complex invocation, use `--port` explicitly.

---

### Scenario 3: Serve from a Specific Directory Path

The binary is installed globally (e.g. `/usr/local/bin/`) or you want to serve a project directory that is unrelated to the binary's location.

```bash
# Serve an absolute path
./PureSimpleHTTPServer --root /home/alice/public_html

# Serve relative to the current working directory
./PureSimpleHTTPServer --root ./dist

# Serve a macOS user Sites folder (shell expands ~)
./PureSimpleHTTPServer --root ~/Sites/myproject
```

**What is happening:** `--root` overrides the default `wwwroot/` lookup. The path can be absolute or relative to the current working directory at the time of launch. The directory must exist; if it does not, the server starts but every request returns `404`.

**Verification:** After starting, confirm the root is correct in the startup banner:

```
PureSimpleHTTPServer v2.3.1
Serving:    /home/alice/public_html
Listening:  http://localhost:8080
```

---

## 2. Development Workflows

---

### Scenario 4: React, Vue, or Angular SPA on Port 3000

You have built a single-page application. The production build is a static folder containing one `index.html` and bundled assets. All client-side routes (`/dashboard`, `/users/42`, etc.) must return `index.html` so the JavaScript router can handle them.

```bash
# React (Create React App or Vite)
npm run build
./PureSimpleHTTPServer --root ./build --port 3000 --spa

# Vue CLI
npm run build
./PureSimpleHTTPServer --root ./dist --port 3000 --spa

# Angular
ng build
./PureSimpleHTTPServer --root ./dist/my-app --port 3000 --spa
```

**What `--spa` does:** Any request whose path does not match a file on disk returns `index.html` with status `200 OK`. Static assets (JS bundles, CSS, images) are served normally — the fallback only activates when no file is found.

```
GET /dashboard          → no file → serve index.html (200)
GET /static/main.js     → file found → serve main.js (200)
GET /favicon.ico        → file found → serve favicon (200)
```

**Why port 3000?** Convention matching the default dev server ports of Vite and Create React App. You can use any port.

---

### Scenario 5: SPA Alongside Vite or webpack-dev-server

During active development you use Vite (or webpack-dev-server, Parcel, etc.) for hot-module replacement. PureSimpleHTTPServer is not a replacement for these tools during development — use it to preview the final production build instead.

```bash
# Start your dev server for active coding
npm run dev      # Vite on :5173 (or similar)

# When you want to verify the production build exactly
npm run build
./PureSimpleHTTPServer --root ./dist --port 4173 --spa
```

**Recommended workflow:**

1. Develop with `npm run dev` (HMR, source maps, fast refresh).
2. Before deploying, run `npm run build` and verify the production build with PureSimpleHTTPServer on a separate port.
3. Test routing, asset paths, and SPA fallback in the production build before pushing.

**Note:** PureSimpleHTTPServer does not support proxying API requests to a backend. If your SPA makes API calls during local testing, either run a local API server separately, or point your API URL to a staging endpoint.

---

### Scenario 6: Multi-Port Staging vs Production

Two copies of your site are running on the same machine: a stable production build and a staging build under test. They are identical in configuration except for the root directory and port.

```bash
# Production — stable build, port 8080
./PureSimpleHTTPServer \
  --root /var/www/production \
  --port 8080 \
  --log /var/log/pshs/prod-access.log \
  --error-log /var/log/pshs/prod-error.log \
  --pid-file /var/run/pshs-prod.pid &

# Staging — candidate build, port 8081
./PureSimpleHTTPServer \
  --root /var/www/staging \
  --port 8081 \
  --log /var/log/pshs/staging-access.log \
  --error-log /var/log/pshs/staging-error.log \
  --pid-file /var/run/pshs-staging.pid &
```

**Key rules when running multiple instances:**

- Each instance needs a unique port.
- Each instance needs separate log file paths (shared log files produce interleaved, corrupted output).
- Each instance needs a separate `--pid-file` path if PID files are used.
- Each instance is a fully independent process with no shared state.

Promote staging to production by stopping the prod instance, replacing the document root, and restarting:

```bash
kill $(cat /var/run/pshs-prod.pid)
rsync -a /var/www/staging/ /var/www/production/
./PureSimpleHTTPServer --root /var/www/production --port 8080 \
  --log /var/log/pshs/prod-access.log \
  --error-log /var/log/pshs/prod-error.log \
  --pid-file /var/run/pshs-prod.pid &
```

---

### Scenario 7: Clean URLs for a Static Site Generator Output

Hugo, Jekyll, Eleventy, and Next.js static export all produce `.html` files that are intended to be accessed at extensionless URLs. Without `--clean-urls`, `/about` returns `404` because the file is named `about.html`.

```bash
# Hugo
hugo
./PureSimpleHTTPServer --root ./public --port 8080 --clean-urls

# Jekyll
jekyll build
./PureSimpleHTTPServer --root ./_site --port 8080 --clean-urls

# Eleventy
npx @11ty/eleventy
./PureSimpleHTTPServer --root ./_site --port 8080 --clean-urls

# Next.js static export
next build && next export
./PureSimpleHTTPServer --root ./out --port 8080 --clean-urls
```

**How it works:** When a request arrives for `/about` and no file named `about` exists at that path, the server appends `.html` and tries again. The browser URL stays `/about` — there is no redirect.

```
GET /blog/my-post
  Lookup 1: /public/blog/my-post       → not found
  Lookup 2: /public/blog/my-post.html  → found → 200 OK
```

**Combining with rewrite rules:** `--clean-urls` applies after rewrite rules. A rewrite destination of `/blog/my-post` (without `.html`) will still resolve if the `.html` file exists on disk and `--clean-urls` is active. Being explicit about the extension in rewrite destinations avoids ambiguity.

---

## 3. Static Site Hosting

---

### Scenario 8: Simple Static Site with Clean URLs

A static site where all pages are `.html` files and internal links use extensionless paths (`/about`, `/contact`). No rewrite rules needed — `--clean-urls` alone handles the extension resolution.

```bash
./PureSimpleHTTPServer \
  --root ./public \
  --port 8080 \
  --clean-urls \
  --log /var/log/pshs/access.log
```

**What to expect:**

| Request | File served | Status |
|---------|-------------|--------|
| `GET /` | `public/index.html` | 200 |
| `GET /about` | `public/about.html` | 200 |
| `GET /contact` | `public/contact.html` | 200 |
| `GET /blog/` | `public/blog/index.html` | 200 |
| `GET /missing` | — | 404 |

**When to use this:** Any site where pages are flat `.html` files and you do not need URL path remapping. If you need to map `/blog/slug` to `/posts/slug.html` (different directory), use `--rewrite` instead (see Scenario 10).

---

### Scenario 9: Documentation Site with Directory Listing

An internal documentation site or file archive where users should be able to browse the directory structure freely. There is no `index.html` in most subdirectories, so directory listing must be enabled.

```bash
./PureSimpleHTTPServer \
  --root /var/www/docs \
  --port 9000 \
  --browse \
  --log /var/log/pshs/docs-access.log
```

**What `--browse` does:** When a request targets a directory that has no `index.html`, the server renders an HTML page listing the directory contents with file names, sizes, and modification dates. Without `--browse`, such requests return `403 Forbidden`.

**Note:** `--browse` and `--spa` interact — `--spa` takes precedence for 404 responses. Do not combine them unless you intentionally want the SPA fallback to override directory listing for missing paths.

**Security note:** `--browse` exposes all non-hidden files under the document root. Run this only on trusted networks for internal use, not on a public-facing server.

---

### Scenario 10: Blog with URL Rewrites

Blog posts are stored as `.html` files in a `posts/` directory but must be accessible under a `/blog/` URL prefix. A rewrite rule maps `/blog/<slug>` to `/posts/<slug>.html`.

**Directory layout:**

```
wwwroot/
    index.html
    posts/
        first-look.html
        deep-dive.html
        hello-world.html
```

**rewrite.conf:**

```conf
# Map /blog/<slug> to the HTML file in posts/
rewrite /blog/* /posts/{path}.html
```

**Command:**

```bash
./PureSimpleHTTPServer \
  --root ./wwwroot \
  --port 8080 \
  --rewrite ./rewrite.conf
```

**How it works:** The glob `*` captures everything after `/blog/`. For a request to `/blog/first-look`, the captured `{path}` is `first-look`, and the server looks for `posts/first-look.html`.

```
GET /blog/first-look
  pattern:  /blog/*
  {path}:   first-look
  rewrite:  /posts/first-look.html
  file:     wwwroot/posts/first-look.html  → 200 OK
```

**What to expect:**

| Request | Served from | Status |
|---------|-------------|--------|
| `GET /blog/first-look` | `posts/first-look.html` | 200 |
| `GET /blog/deep-dive` | `posts/deep-dive.html` | 200 |
| `GET /blog/not-there` | — | 404 |

---

### Scenario 11: Image Gallery with Directory Listing

A photo gallery where images are organised in subdirectories by album. There is no HTML front-end — the directory listing is the interface.

```bash
./PureSimpleHTTPServer \
  --root /mnt/photos \
  --port 9001 \
  --browse
```

**Directory layout example:**

```
/mnt/photos/
    2024-summer/
        IMG_0001.jpg
        IMG_0002.jpg
    2024-winter/
        IMG_0100.jpg
    2025-travel/
        DSC_0042.jpg
        DSC_0043.jpg
```

**Behaviour:** Browsing `http://host:9001/` shows the album list. Clicking an album shows the individual files. Clicking an image serves it with the correct `Content-Type` (`image/jpeg`, `image/png`, etc.).

**Tip:** Add `--log` to record which images were accessed:

```bash
./PureSimpleHTTPServer \
  --root /mnt/photos \
  --port 9001 \
  --browse \
  --log ./gallery-access.log
```

---

## 4. API Mock Server

Use PureSimpleHTTPServer to serve static JSON files as a mock REST API during front-end development or testing. No special server-side logic is required.

---

### Scenario 12: JSON Files as Mock API Endpoints

JSON response files are placed in an `api/` directory. Rewrite rules map clean REST-style URLs to the corresponding files.

**Directory layout:**

```
mock/
    api/
        users.json
        products.json
        orders/
            list.json
            detail.json
```

**rewrite.conf:**

```conf
# Serve JSON for clean API paths
rewrite /api/users           /api/users.json
rewrite /api/products        /api/products.json
rewrite /api/orders          /api/orders/list.json
rewrite /api/orders/detail   /api/orders/detail.json
```

**Command:**

```bash
./PureSimpleHTTPServer \
  --root ./mock \
  --port 3001 \
  --rewrite ./rewrite.conf
```

**What to expect:** A fetch to `http://localhost:3001/api/users` returns the contents of `mock/api/users.json` with `Content-Type: application/json`. The browser or fetch client does not see the `.json` extension.

**Tip:** For any endpoints not covered by explicit rules, `--clean-urls` can resolve `/api/users` to `api/users.json` if you prefer not to write a rule per file:

```bash
./PureSimpleHTTPServer --root ./mock --port 3001 --clean-urls
```

This works because `--clean-urls` appends `.html` — not `.json` — so it will not help here. Use explicit rewrite rules for JSON endpoints.

---

### Scenario 13: Versioned API Path Rewrite

The public API path is `/api/v1/*` but the files on disk are organised under `/v1/`. A single glob rule handles all endpoints transparently.

**rewrite.conf:**

```conf
# Forward all /api/v1/ requests to the /v1/ directory
rewrite /api/v1/* /v1/{path}
```

**Command:**

```bash
./PureSimpleHTTPServer \
  --root ./mock \
  --port 3001 \
  --rewrite ./rewrite.conf \
  --clean-urls
```

**What to expect:**

| Request | Rewritten to | File served |
|---------|-------------|-------------|
| `GET /api/v1/users` | `/v1/users` | `mock/v1/users.json` (via `--clean-urls`) |
| `GET /api/v1/products` | `/v1/products` | `mock/v1/products.json` |
| `GET /api/v1/orders/list` | `/v1/orders/list` | `mock/v1/orders/list.json` |

Wait — `--clean-urls` appends `.html`, not `.json`. For JSON mocking, append the extension explicitly in the rewrite destination:

```conf
# Explicit .json extension in destination
rewrite /api/v1/* /v1/{path}.json
```

**When you add v2:** Update the single rule to point at `/v2/` and the entire API migrates without changing any client-facing URLs.

---

### Scenario 14: REST-Style Redirects

During a mock API migration, old endpoint paths must redirect to new ones. Use `redir` rules so client code discovers the new paths automatically.

**rewrite.conf:**

```conf
# Redirect removed endpoints to their replacements
redir /api/v1/users/list    /api/v1/users       301
redir /api/v1/item/*        /api/v1/products/{path}  301

# Temporary redirect: endpoint is under maintenance
redir /api/v1/checkout      /api/v1/maintenance  302
```

**Command:**

```bash
./PureSimpleHTTPServer \
  --root ./mock \
  --port 3001 \
  --rewrite ./rewrite.conf
```

**Choosing between 301 and 302:**

- Use `301` (permanent) when the old path is retired and clients should update their bookmarks and code.
- Use `302` (temporary) when the destination may change again or while testing — browsers do not cache `302` responses.

**Caution:** Browsers cache `301` responses aggressively. Use `302` during development and switch to `301` only when the redirect is final.

---

## 5. Logging Configurations

---

### Scenario 15: Development — No Logging

During local development, logging to disk is unnecessary overhead. Omitting both `--log` and `--error-log` keeps all logging disabled.

```bash
./PureSimpleHTTPServer \
  --root ./dist \
  --port 3000 \
  --spa
```

No files are written. No startup message about logs. This is the zero-noise configuration for local iteration.

**If you want minimal diagnostic output in the terminal** without writing to a file, that output goes to stderr when the process is running interactively. No flag is needed for that.

---

### Scenario 16: Staging — Access Log and Info-Level Error Log

On a staging server you want visibility into every request and all diagnostic messages, including server startup events and rule matching. The `info` level is verbose enough to trace any unexpected behaviour.

```bash
./PureSimpleHTTPServer \
  --root /var/www/staging \
  --port 8081 \
  --log /var/log/pshs/staging-access.log \
  --error-log /var/log/pshs/staging-error.log \
  --log-level info
```

**What `--log-level info` records:**

```
[INFO] Server started on 0.0.0.0:8081
[INFO] Root directory: /var/www/staging
[INFO] GET /index.html → 200 (4321 bytes)
[INFO] Rewrite rule matched: /blog/* → /posts/first-look.html
[WARN] File not found: /var/www/staging/missing.css
[INFO] Server stopped cleanly
```

**What `--log-level warn` (the default) records:** Errors and warnings only — no startup/shutdown or per-request info lines.

**Why info on staging but not production:** Info-level logging generates one log entry per request in the error log on top of the access log entry. On a high-traffic production server this doubles the write load. On staging it is acceptable and valuable.

---

### Scenario 17: Production — Access and Error Logs with Rotation

The standard production setup: access log in Combined Log Format, separate error log, automatic rotation at 100 MB, keep 30 archives, and a PID file for signal delivery.

```bash
./PureSimpleHTTPServer \
  --root /var/www/mysite \
  --port 8080 \
  --log /var/log/pshs/access.log \
  --error-log /var/log/pshs/error.log \
  --log-level warn \
  --log-size 100 \
  --log-keep 30 \
  --pid-file /var/run/pshs.pid
```

**Create the log directory before starting:**

```bash
sudo mkdir -p /var/log/pshs
sudo chown www-data:www-data /var/log/pshs
```

**Flag breakdown:**

| Flag | Effect |
|------|--------|
| `--log-level warn` | Record errors and warnings; skip verbose info messages |
| `--log-size 100` | Rotate logs when they reach 100 MB |
| `--log-keep 30` | Keep at most 30 archived log files; delete oldest when exceeded |
| `--pid-file` | Write the server PID so init scripts and logrotate can signal it |

**Maximum disk usage:** `100 MB × (30 archives + 1 active) = 3.1 GB` for each log type. Budget accordingly.

**Daily rotation** is active by default alongside size-based rotation. At midnight, the server rotates regardless of size. To rely solely on size-based rotation, add `--no-log-daily`.

---

### Scenario 18: High-Traffic — Aggressive Rotation, No Daily Cycle

On a high-traffic server, a 100 MB log file may fill up several times per day. You want smaller, more frequent archives and no midnight rotation (the size threshold makes it redundant).

```bash
./PureSimpleHTTPServer \
  --root /var/www/mysite \
  --port 8080 \
  --log /var/log/pshs/access.log \
  --error-log /var/log/pshs/error.log \
  --log-size 50 \
  --log-keep 10 \
  --no-log-daily \
  --pid-file /var/run/pshs.pid
```

**What changes:**

- `--log-size 50` — rotate every 50 MB instead of 100 MB.
- `--log-keep 10` — keep only 10 archives (500 MB total cap per log type).
- `--no-log-daily` — disable midnight rotation; rely entirely on size thresholds.

**Maximum disk usage:** `50 MB × (10 + 1) = 550 MB` per log type.

**When to use this:** When disk space is constrained and you do not need long log retention. Analysis tools can still process the rotated archives before they are deleted.

---

### Scenario 19: Minimal — Error-Only Log Level

You need an access log for traffic analysis but want the error log to contain only hard failures — not warnings about `404`s or missing assets. This reduces noise in automated monitoring.

```bash
./PureSimpleHTTPServer \
  --root /var/www/mysite \
  --port 8080 \
  --log /var/log/pshs/access.log \
  --error-log /var/log/pshs/error.log \
  --log-level error
```

**What `--log-level error` records:** Fatal I/O failures, failed port binds, and other conditions that prevent the server from functioning correctly. `404` responses, missing files, and permission denials at the request level are not written.

**Variation — access log only, no error log file:**

```bash
./PureSimpleHTTPServer \
  --root /var/www/mysite \
  --port 8080 \
  --log /var/log/pshs/access.log
```

Omitting `--error-log` entirely disables error file logging. The `--log-level` flag has no effect unless `--error-log` is also set.

---

### Scenario 20: logrotate Integration with PID File and SIGHUP

Your organisation uses `logrotate` as the standard log management daemon. You want PureSimpleHTTPServer to participate in the standard cycle: logrotate renames the log file, sends `SIGHUP`, and the server reopens the log at the original path. No server restart is needed.

**Server startup command:**

```bash
./PureSimpleHTTPServer \
  --root /var/www/mysite \
  --port 8080 \
  --log /var/log/pshs/access.log \
  --error-log /var/log/pshs/error.log \
  --pid-file /var/run/pshs.pid \
  --log-size 0 \
  --no-log-daily
```

Disable built-in rotation (`--log-size 0` and `--no-log-daily`) to avoid conflicts with logrotate.

**logrotate configuration — save as `/etc/logrotate.d/puresimplehttpserver`:**

```conf
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
        kill -HUP $(cat /var/run/pshs.pid 2>/dev/null) 2>/dev/null || true
    endscript
}
```

**How SIGHUP log reopen works:**

```
logrotate runs (via cron at midnight):
  1. Renames access.log → access.log.1
  2. Creates a new empty access.log
  3. Sends SIGHUP to the PID in /var/run/pshs.pid

Server receives SIGHUP:
  1. Sets an internal reopen flag
  2. On the next log write, flushes and closes the current file handles
  3. Reopens access.log and error.log at their original paths
  4. All subsequent writes go to the new files
  5. logrotate compresses access.log.1 in the background
```

No log lines are lost. The mutex-protected reopen ensures writes to the renamed file continue until the flag is processed.

**Test the configuration:**

```bash
# Dry run — no changes, shows what would happen
logrotate -d /etc/logrotate.d/puresimplehttpserver

# Force rotation immediately
logrotate -f /etc/logrotate.d/puresimplehttpserver
```

---

## 6. URL Rewriting Scenarios

---

### Scenario 21: Clean URLs with --clean-urls Only

The simplest clean URL solution: no rewrite rules, no extra configuration. The `--clean-urls` flag handles the `.html` extension fallback for every request.

```bash
./PureSimpleHTTPServer \
  --root ./public \
  --port 8080 \
  --clean-urls
```

**When to use this vs. `--rewrite`:** Use `--clean-urls` when your files are organised the same as your URL structure (the URL `/about` maps to the file `about.html` in the same directory). Use `--rewrite` when you need to map URLs to files in a different directory or with a different naming pattern.

**Example file layout:**

```
public/
    index.html         → served at /
    about.html         → served at /about
    contact.html       → served at /contact
    blog/
        index.html     → served at /blog/
        first-post.html → served at /blog/first-post
```

---

### Scenario 22: Custom Blog Slug Routing

Blog posts are stored at `posts/<slug>.html` but must be accessible at `/blog/<slug>`. A glob rewrite rule maps the URL namespace to the file namespace.

**rewrite.conf:**

```conf
# Map /blog/<slug> → /posts/<slug>.html
rewrite /blog/* /posts/{path}.html

# Redirect requests to the old /articles/ prefix
redir /articles/* /blog/{path} 301
```

**Command:**

```bash
./PureSimpleHTTPServer \
  --root ./wwwroot \
  --port 8080 \
  --rewrite ./rewrite.conf
```

**Rule order matters:** More specific rules must come before more general ones. If you have a special landing page for one post, add it before the catch-all glob:

```conf
# Special case: this post has a custom landing page
rewrite /blog/featured    /landing/featured.html

# General case: all other posts
rewrite /blog/*           /posts/{path}.html
```

---

### Scenario 23: Redirect Old to New URL Structure (301)

A site migration moved pages from a flat structure to a categorised hierarchy. Old bookmarked and indexed URLs must redirect permanently to the new locations.

**rewrite.conf:**

```conf
# Exact redirects for renamed pages
redir /about-us          /company/about        301
redir /contact-us        /contact              301
redir /products          /shop                 301

# Glob redirect for an entire section that moved
redir /old-blog/*        /articles/{path}      301

# Regex redirect: old dated blog paths to flat slugs
redir ~/posts/([0-9]{4})/([0-9]{2})/(.+)   /articles/{re.3}   301
```

**Command:**

```bash
./PureSimpleHTTPServer \
  --root ./wwwroot \
  --port 8080 \
  --rewrite ./rewrite.conf
```

**What to expect:**

```
GET /about-us
  HTTP/1.1 301 Moved Permanently
  Location: /company/about

GET /old-blog/my-post
  HTTP/1.1 301 Moved Permanently
  Location: /articles/my-post

GET /posts/2023/06/my-post
  HTTP/1.1 301 Moved Permanently
  Location: /articles/my-post
```

**Caution with 301:** Browsers cache permanent redirects indefinitely. Use `302` while verifying that the destinations are correct. Promote to `301` only after the new URL structure is confirmed final.

---

### Scenario 24: Redirect www to Non-www

PureSimpleHTTPServer does not inspect the `Host` header in rewrite rules, so hostname-level redirects (www vs. non-www) must be handled by a reverse proxy. The correct approach is to put nginx or Caddy in front.

**nginx configuration for www → non-www redirect:**

```nginx
# Redirect all www traffic to the canonical non-www domain
server {
    listen 80;
    server_name www.example.com;
    return 301 $scheme://example.com$request_uri;
}

# Forward all non-www traffic to PureSimpleHTTPServer
server {
    listen 80;
    server_name example.com;
    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

**Path-based equivalent (if applicable):** If your situation involves a URL path prefix rather than a hostname, a glob redirect handles it:

```conf
# Move everything under /www/ to the root (path-based only)
redir /www/* /{path} 301
```

This is a different situation from hostname redirects, but the pattern is useful for migrating content from a subdirectory to the root.

---

### Scenario 25: API Versioning Redirect

The public API is currently at `/api/*`. You want requests to `/api/*` to redirect to `/api/v1/*` so clients that do not specify a version see the current default. This is a redirect (the client's URL changes), not a rewrite (the client would not see the versioned URL).

**rewrite.conf:**

```conf
# Redirect unversioned /api/ requests to v1
redir /api/*    /api/v1/{path}    302

# Internal rewrite: /api/v1/* → actual files in /v1/
rewrite /api/v1/* /v1/{path}
```

**Command:**

```bash
./PureSimpleHTTPServer \
  --root ./mock \
  --port 3001 \
  --rewrite ./rewrite.conf
```

**What to expect:**

```
GET /api/users
  HTTP/1.1 302 Found
  Location: /api/v1/users

GET /api/v1/users
  (matched by rewrite rule, served from /v1/users)
```

**Why 302 and not 301:** During the period when you are still deciding on versioning strategy, a temporary redirect lets you change the default version without fighting browser caches.

---

### Scenario 26: Regex-Based User Profile URLs

User profile pages are stored at `/profile/<id>.html` but you want clean URLs like `/user/42` where the ID must be numeric. A regex pattern enforces the numeric constraint.

**rewrite.conf:**

```conf
# Rewrite /user/<numeric-id> to /profile/<id>.html
# Non-numeric IDs do not match and fall through to normal file serving
rewrite ~/user/([0-9]+)$ /profile/{re.1}.html
```

**Command:**

```bash
./PureSimpleHTTPServer \
  --root ./wwwroot \
  --port 8080 \
  --rewrite ./rewrite.conf
```

**What to expect:**

| Request | Result |
|---------|--------|
| `GET /user/42` | serves `profile/42.html` |
| `GET /user/1001` | serves `profile/1001.html` |
| `GET /user/alice` | no match — falls through to normal file serving |

**Regex notes:**
- The `~` prefix marks the pattern as a regex. There must be no space between `~` and the first character.
- `[0-9]+` matches one or more digits.
- The trailing `$` anchors the match so `/user/42/settings` does not match.
- `{re.1}` expands to the text captured by the first parenthesised group.

---

## 7. Deployment Patterns

---

### Scenario 27: macOS launchd Plist

On macOS, `launchd` is the native service manager. A user-level LaunchAgent starts at login and restarts automatically on crash.

**Save as `~/Library/LaunchAgents/com.example.pshs.plist`:**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
    "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.example.pshs</string>

    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/PureSimpleHTTPServer</string>
        <string>--port</string>
        <string>8080</string>
        <string>--root</string>
        <string>/Users/alice/Sites/mysite</string>
        <string>--log</string>
        <string>/Users/alice/Library/Logs/pshs/access.log</string>
        <string>--error-log</string>
        <string>/Users/alice/Library/Logs/pshs/error.log</string>
        <string>--pid-file</string>
        <string>/tmp/pshs.pid</string>
        <string>--log-size</string>
        <string>50</string>
        <string>--log-keep</string>
        <string>14</string>
    </array>

    <key>RunAtLoad</key>
    <true/>

    <key>KeepAlive</key>
    <true/>

    <key>StandardOutPath</key>
    <string>/Users/alice/Library/Logs/pshs/stdout.log</string>

    <key>StandardErrorPath</key>
    <string>/Users/alice/Library/Logs/pshs/stderr.log</string>
</dict>
</plist>
```

**Create the log directory and load the agent:**

```bash
mkdir -p ~/Library/Logs/pshs

# Load and start immediately; also enables at next login
launchctl load ~/Library/LaunchAgents/com.example.pshs.plist

# Check status
launchctl list | grep com.example.pshs

# Stop and disable
launchctl unload ~/Library/LaunchAgents/com.example.pshs.plist
```

**Key plist keys:**

- `RunAtLoad: true` — start immediately when loaded.
- `KeepAlive: true` — restart automatically if the process exits for any reason.
- `StandardOutPath` / `StandardErrorPath` — capture the startup banner and any unhandled output.

For a system-wide daemon (starts at boot, runs as root or a dedicated user), copy the plist to `/Library/LaunchDaemons/` and adjust all paths to absolute system paths. Load with `sudo launchctl load`.

---

### Scenario 28: Linux systemd Unit File

On Linux, systemd is the standard service manager. This unit file runs the server as `www-data`, restarts it on failure, and enables `systemctl reload` for SIGHUP-based log reopening.

**Save as `/etc/systemd/system/pshs.service`:**

```ini
[Unit]
Description=PureSimpleHTTPServer static file server
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data

ExecStart=/usr/local/bin/PureSimpleHTTPServer \
    --port 8080 \
    --root /var/www/mysite \
    --log /var/log/pshs/access.log \
    --error-log /var/log/pshs/error.log \
    --pid-file /var/run/pshs.pid \
    --log-size 100 \
    --log-keep 30

ExecReload=/bin/kill -HUP $MAINPID

Restart=on-failure
RestartSec=5s
LimitNOFILE=65536
WorkingDirectory=/usr/local/bin

[Install]
WantedBy=multi-user.target
```

**Set up directories and enable the service:**

```bash
# Create log directory with correct ownership
sudo mkdir -p /var/log/pshs
sudo chown www-data:www-data /var/log/pshs

# Load, enable, and start
sudo systemctl daemon-reload
sudo systemctl enable pshs
sudo systemctl start pshs

# Verify
sudo systemctl status pshs
```

**Day-to-day management:**

```bash
# Graceful log reopen (sends SIGHUP, no request interruption)
sudo systemctl reload pshs

# View recent output
journalctl -u pshs -f

# Restart (brief downtime)
sudo systemctl restart pshs

# Stop
sudo systemctl stop pshs
```

**What `ExecReload` does:** `systemctl reload pshs` sends SIGHUP to the process, which triggers a log file reopen (see Scenario 20). This is the correct way to rotate logs with logrotate on a systemd-managed service.

---

### Scenario 29: Docker CMD Line

PureSimpleHTTPServer is a single static binary with no runtime dependencies, making it well suited for minimal container images.

**Dockerfile:**

```dockerfile
FROM scratch

COPY PureSimpleHTTPServer /PureSimpleHTTPServer
COPY dist/ /wwwroot/

EXPOSE 8080

CMD ["/PureSimpleHTTPServer", \
     "--port", "8080", \
     "--root", "/wwwroot", \
     "--log", "/var/log/access.log", \
     "--error-log", "/var/log/error.log", \
     "--log-size", "50", \
     "--log-keep", "7"]
```

**Build and run:**

```bash
docker build -t mysite .
docker run -p 8080:8080 mysite
```

**Notes:**

- `FROM scratch` produces an extremely small image because the binary is statically compiled with no libc dependency.
- Mount a volume for logs if you need them outside the container:
  ```bash
  docker run -p 8080:8080 -v /host/logs:/var/log mysite
  ```
- Pass rewrite rules via a mounted volume:
  ```bash
  docker run -p 8080:8080 \
    -v /host/rewrite.conf:/etc/pshs/rewrite.conf \
    mysite \
    --rewrite /etc/pshs/rewrite.conf
  ```
  (Requires using `ENTRYPOINT` instead of `CMD` in the Dockerfile.)
- The SPA flag works identically in a container:
  ```bash
  docker run -p 3000:3000 mysite --port 3000 --spa
  ```

---

### Scenario 30: nginx Reverse Proxy Frontend

PureSimpleHTTPServer handles file serving; nginx sits in front to terminate TLS, add authentication headers, handle www redirects, and apply rate limiting or caching policies that PureSimpleHTTPServer does not implement.

**nginx configuration:**

```nginx
server {
    listen 443 ssl;
    server_name example.com;

    ssl_certificate     /etc/ssl/certs/example.com.crt;
    ssl_certificate_key /etc/ssl/private/example.com.key;

    location / {
        proxy_pass         http://127.0.0.1:8080;
        proxy_set_header   Host $host;
        proxy_set_header   X-Real-IP $remote_addr;
        proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;
        proxy_read_timeout 30s;
    }
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name example.com;
    return 301 https://$host$request_uri;
}
```

**PureSimpleHTTPServer startup:**

```bash
./PureSimpleHTTPServer \
  --root /var/www/mysite \
  --port 8080 \
  --log /var/log/pshs/access.log \
  --error-log /var/log/pshs/error.log \
  --pid-file /var/run/pshs.pid
```

**Division of responsibilities:**

| Concern | Handled by |
|---------|-----------|
| TLS termination | nginx |
| HTTP → HTTPS redirect | nginx |
| www → non-www redirect | nginx |
| Rate limiting | nginx |
| Static file serving | PureSimpleHTTPServer |
| URL rewrites / clean URLs | PureSimpleHTTPServer |
| Access log (per-file) | PureSimpleHTTPServer |

**Access log note:** With a reverse proxy, the client IP in PureSimpleHTTPServer's access log is `127.0.0.1` (the proxy) rather than the real client. The real IP is available in the nginx access log, or you can configure nginx to forward it and parse it from the `X-Forwarded-For` header in post-processing.

---

### Scenario 31: Run as a Non-Root User on Port 8080

Ports below 1024 require root on most systems, but port 8080 and above do not. Running as a non-root user limits the blast radius of any vulnerability.

```bash
# Create a dedicated system user (Linux — run once as root)
sudo useradd --system --no-create-home --shell /usr/sbin/nologin pshs

# Transfer ownership of the document root and log directory
sudo chown -R pshs:pshs /var/www/mysite
sudo mkdir -p /var/log/pshs && sudo chown pshs:pshs /var/log/pshs

# Run the server as the dedicated user
sudo -u pshs /usr/local/bin/PureSimpleHTTPServer \
  --root /var/www/mysite \
  --port 8080 \
  --log /var/log/pshs/access.log \
  --error-log /var/log/pshs/error.log \
  --pid-file /var/run/pshs.pid
```

**Why this matters:** If the server process is exploited, the attacker gains only the privileges of the `pshs` user — not root. Combined with a minimal document root (no sensitive files), the exposure is contained.

**macOS equivalent:** Use a dedicated local user account. For production macOS servers, use the launchd plist from Scenario 27 with a `UserName` key set to a non-privileged user.

---

## 8. Multiple Instances

---

### Scenario 32: Two Sites on Different Ports from One Machine

You need to serve two distinct sites from one machine — for example, a public site and an internal admin panel.

```bash
# Public site — port 8080
./PureSimpleHTTPServer \
  --root /var/www/public \
  --port 8080 \
  --log /var/log/pshs/public-access.log \
  --error-log /var/log/pshs/public-error.log \
  --pid-file /var/run/pshs-public.pid \
  --clean-urls &

# Internal admin — port 9090
./PureSimpleHTTPServer \
  --root /var/www/admin \
  --port 9090 \
  --browse \
  --log /var/log/pshs/admin-access.log \
  --error-log /var/log/pshs/admin-error.log \
  --pid-file /var/run/pshs-admin.pid &
```

**Firewall tip:** Restrict port 9090 to internal IP ranges only. PureSimpleHTTPServer has no built-in IP filtering — use the OS firewall (`iptables`, `ufw`, `pf`) to limit access.

**Verify both are listening:**

```bash
ss -tlnp | grep PureSimple
# or
lsof -i :8080 -i :9090
```

---

### Scenario 33: A/B Test Setup

Two slightly different builds of the same site are served on different ports. Traffic is split upstream (by nginx, a load balancer, or a feature flag service), and you compare analytics between the two versions.

```bash
# Variant A — control
./PureSimpleHTTPServer \
  --root /var/www/variant-a \
  --port 8080 \
  --spa \
  --log /var/log/pshs/variant-a.log \
  --pid-file /var/run/pshs-a.pid &

# Variant B — treatment
./PureSimpleHTTPServer \
  --root /var/www/variant-b \
  --port 8081 \
  --spa \
  --log /var/log/pshs/variant-b.log \
  --pid-file /var/run/pshs-b.pid &
```

**nginx upstream split (50/50):**

```nginx
upstream ab_backends {
    server 127.0.0.1:8080;
    server 127.0.0.1:8081;
}

server {
    listen 80;
    server_name example.com;
    location / {
        proxy_pass http://ab_backends;
    }
}
```

By default nginx round-robins between the two backends. More sophisticated splits (by cookie, by IP hash, by percentage) are available with `nginx_http_split_clients` or an upstream proxy like Caddy.

**Analysing the logs separately:** Each variant writes its own access log. Use `goaccess` or `awk` to compare request counts, error rates, and page views between the two.

---

## 9. Embedded Assets Build

---

### Scenario 34: Compile-Time Asset Embedding

You want a true zero-dependency deployment: a single binary that contains the entire website. No `wwwroot/` folder, no external files — just the executable. Useful for distributing web-based tools, control panels, or documentation that users run with a single command.

This is a **compile-time feature** that requires access to the PureBasic compiler and the project source. End users of a pre-built binary do not need to do anything special.

**Overview of the build process:**

**Step 1 — Build your site:**

```bash
hugo --destination ./dist
```

**Step 2 — Pack the assets into a zip archive:**

```bash
./scripts/pack_assets.sh ./dist ./src/webapp.zip
```

**Step 3 — Embed the zip in `main.pb`:**

```purebasic
UseZipPacker()

DataSection
  webapp:    IncludeBinary "src/webapp.zip"
  webappEnd:
EndDataSection
```

And in `Main()`:

```purebasic
OpenEmbeddedPack(?webapp, ?webappEnd - ?webapp)
```

**Step 4 — Compile:**

```bash
pbcompiler -cl -t -o PureSimpleHTTPServer src/main.pb
```

**Step 5 — Run (no wwwroot/ needed):**

```bash
./PureSimpleHTTPServer --port 8080
```

**Runtime behaviour of an embedded build:**

- Files are decompressed from the in-memory zip on demand. There are no disk reads for content after startup.
- Files larger than 4 MB cannot be served from the embedded pack; serve those from disk by providing a `--root`.
- If a path is not found in the embedded pack, the server falls back to a disk `wwwroot/` next to the binary. This lets you mix embedded and disk-served files.
- `--clean-urls`, `--spa`, and `--rewrite` all work identically with embedded assets.

**When to use embedded vs. disk-based root:**

| Situation | Recommendation |
|-----------|----------------|
| Distributable single-file tool | Embedded |
| Frequently updated content | Disk (`--root`) — rebuild not required |
| Files larger than 4 MB | Disk |
| CI/CD pipeline deploying assets | Disk — easier to rsync |
| Cross-platform desktop utility | Embedded — drag-and-drop simplicity |

---

## 10. Security Notes

---

### Scenario 35: Hidden Path Blocking

PureSimpleHTTPServer blocks requests to hidden paths by default — any path component starting with a `.` (dot) returns `403 Forbidden`, regardless of whether the file exists on disk.

```bash
./PureSimpleHTTPServer --root /var/www/mysite --port 8080
```

No additional flag is needed. The following requests are blocked unconditionally:

| Request | Response |
|---------|----------|
| `GET /.env` | `403 Forbidden` |
| `GET /.git/config` | `403 Forbidden` |
| `GET /.DS_Store` | `403 Forbidden` |
| `GET /.htpasswd` | `403 Forbidden` |
| `GET /subdir/.ssh/id_rsa` | `403 Forbidden` |

**What this protects against:** Accidental exposure of version control metadata (`.git/`), environment files (`.env`, `.env.local`), macOS metadata (`.DS_Store`), SSH keys, and other files that are commonly present in development directories but must never be served over HTTP.

**Limitation:** This protection only applies to paths with a leading dot in any path segment. Files that are sensitive but do not start with a dot (e.g. `database.yml`, `config.php`) are not automatically blocked. Review your document root and exclude sensitive files before pointing the server at it.

---

### Scenario 36: TLS and Auth via nginx or Caddy

PureSimpleHTTPServer supports built-in HTTP Basic Authentication (via `--basic-auth`) for simple use cases. For advanced authentication, IP-based access control, or additional security layers on public-facing deployments, use a reverse proxy.

**With Caddy (automatic TLS via Let's Encrypt):**

```
example.com {
    reverse_proxy 127.0.0.1:8080
}
```

Caddy automatically obtains and renews a TLS certificate. This is a complete, production-ready configuration for a single-domain site.

**With Caddy + basic auth:**

```
example.com {
    basicauth {
        alice $2a$14$...hashed_password...
    }
    reverse_proxy 127.0.0.1:8080
}
```

**With nginx (manual TLS certificate):**

See Scenario 30 for the full nginx configuration including TLS termination.

**With nginx + IP allowlist:**

```nginx
location / {
    allow 203.0.113.0/24;   # office IP range
    allow 127.0.0.1;
    deny all;
    proxy_pass http://127.0.0.1:8080;
}
```

**Summary:** Keep PureSimpleHTTPServer on a loopback or internal port. Let the proxy handle all concerns that require inspection of the connection (TLS certificates, client certificates, auth headers, rate limiting, IP blocking). PureSimpleHTTPServer's responsibility is file serving and URL routing.

---

### Scenario 37: Network Exposure Warning

By default, PureSimpleHTTPServer binds to all interfaces (`0.0.0.0`), making it reachable from any network interface on the machine.

```bash
# This is reachable from other machines on the network
./PureSimpleHTTPServer --root ./dist --port 8080
```

**Risks on untrusted networks:**

- **Public Wi-Fi:** Anyone on the same network can connect to your laptop on port 8080 and access any file in the document root.
- **Cloud VMs with public IPs:** The server is reachable from the internet unless blocked by a firewall.
- **Corporate networks:** Other users on the same VLAN can reach the server.

**Mitigations:**

1. **Firewall rules:** Block the port at the OS level when external access is not needed:
   ```bash
   # Linux (ufw)
   sudo ufw deny 8080

   # Linux (iptables)
   sudo iptables -A INPUT -p tcp --dport 8080 -j DROP
   ```

2. **Reverse proxy only:** Bind PureSimpleHTTPServer to localhost and let nginx or Caddy handle external traffic. Only the proxy port (80/443) is exposed:
   ```bash
   # The server only listens on loopback
   # (Bind-address configuration is a future feature; use firewall rules for now)
   ```

3. **Hidden paths are still protected:** Even if the server is exposed, `.git/`, `.env`, and other dot-prefixed paths return `403 Forbidden` (see Scenario 35).

4. **Authentication:** Use `--basic-auth USER:PASS` to gate all requests behind HTTP Basic Authentication. For untrusted networks, combine with TLS (via reverse proxy) to protect credentials in transit.

5. **Shut down when done:** For temporary local sharing sessions, stop the server as soon as you are finished:
   ```bash
   # If started with --pid-file
   kill $(cat ./server.pid)

   # Otherwise, Ctrl+C in the terminal where it is running
   ```

---

## Self-Signed Certificate for Development

Use HTTPS locally to test certificate handling, mixed-content warnings, or service workers that require a secure context.

### Setup

```bash
# Generate a self-signed certificate valid for 365 days
openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem \
  -days 365 -nodes -subj "/CN=localhost"

# Start the server with HTTPS
./PureSimpleHTTPServer --port 8443 --root ./dist \
  --tls-cert cert.pem --tls-key key.pem
```

### Verify

```bash
curl -k https://localhost:8443/
```

Browsers will show a certificate warning for self-signed certs. In Chrome, type `thisisunsafe` to proceed. In Firefox, click "Advanced" → "Accept the Risk and Continue".

---

## Auto-TLS with Let's Encrypt

Zero-config HTTPS for a public-facing server. The server obtains and renews certificates automatically.

### Prerequisites

1. Install acme.sh: `curl https://get.acme.sh | sh`
2. Ensure port 80 is open (for ACME HTTP-01 challenge)
3. DNS A record pointing `example.com` to your server's IP

### Setup

```bash
./PureSimpleHTTPServer --auto-tls example.com --root /var/www \
  --log /var/log/pshs/access.log --error-log /var/log/pshs/error.log
```

The server will:
- Start an HTTP listener on port 80 (ACME challenges + HTTPS redirect)
- Issue a certificate via `acme.sh --issue`
- Start HTTPS on port 443
- Renew the certificate every 12 hours in the background

### What the user sees

- `http://example.com` → 301 redirect to `https://example.com`
- `https://example.com` → your site with a valid Let's Encrypt certificate

---

## Reverse Proxy with Caddy (4 Instances)

Run multiple PureSimpleHTTPServer instances behind Caddy for high throughput and automatic TLS.

### Start 4 backend instances

```bash
for port in 8081 8082 8083 8084; do
  ./PureSimpleHTTPServer --port $port --root /var/www \
    --log /var/log/pshs/access-$port.log &
done
```

### Caddyfile

```
example.com {
    reverse_proxy localhost:8081 localhost:8082 localhost:8083 localhost:8084 {
        lb_policy round_robin
        health_uri /
        health_interval 30s
    }
}
```

### Benefits

Caddy handles TLS, HTTP/2, keep-alive, and slow-client buffering. Each PureSimpleHTTPServer instance handles ~5k req/sec, giving 15k-20k req/sec aggregate.

See [../deployment.md](../deployment.md) for the full deployment guide with systemd templates and launch scripts.

---

## Disable Gzip for Pre-Compressed Content

When your build pipeline pre-compresses all assets (e.g., with `gzip -k`), disable dynamic compression to avoid redundant CPU work.

### Setup

```bash
# Pre-compress during build
find dist/ -type f \( -name "*.html" -o -name "*.css" -o -name "*.js" \) -exec gzip -k {} \;

# Serve with dynamic gzip disabled — .gz sidecars are still served
./PureSimpleHTTPServer --root ./dist --no-gzip
```

### How it works

- `--no-gzip` disables the `Middleware_GzipCompress` dynamic compression
- Pre-compressed `.gz` sidecar files (e.g., `app.js.gz`) are still served by `Middleware_GzipSidecar` with `Content-Encoding: gzip`
- This is optimal when every compressible file has a `.gz` sidecar — zero CPU spent on compression at request time

---

## 11. Authentication and Error Pages (v2.5.0+)

---

### Scenario 38: Basic Auth for a Staging Site

You want to protect a staging environment so only your team can access it. HTTP Basic Authentication gates every request behind a username and password.

```bash
./PureSimpleHTTPServer \
  --root /var/www/staging \
  --port 8080 \
  --basic-auth staging:s3cret \
  --log /var/log/pshs/staging-access.log
```

**What happens:**

- Every request without a valid `Authorization: Basic` header receives `401 Unauthorized` with a `WWW-Authenticate: Basic realm="Restricted"` header.
- Browsers show a native login dialog. After entering `staging` / `s3cret`, the browser caches the credentials for the session.
- Passwords may contain colons — only the first colon separates username from password. For example, `--basic-auth admin:pass:word` means username `admin`, password `pass:word`.

**Testing:**

```bash
# Without credentials → 401
curl -I http://localhost:8080/
# HTTP/1.1 401 Unauthorized

# With credentials → 200
curl -u staging:s3cret http://localhost:8080/
# HTTP/1.1 200 OK
```

**Combining with CORS:** CORS preflight (OPTIONS) requests are handled before BasicAuth in the middleware chain, so cross-origin API clients can still negotiate CORS without credentials on the preflight request:

```bash
./PureSimpleHTTPServer --root ./api-docs --basic-auth admin:secret --cors
```

---

### Scenario 39: Custom Error Pages for a Branded Site

You want a polished user experience when visitors encounter errors — a styled 404 page with your site's header, footer, and navigation instead of a bare "404 Not Found" text response.

**Directory structure:**

```
my-site/
├── wwwroot/
│   ├── index.html
│   └── style.css
└── errors/
    ├── 403.html    (custom "Access Denied" page)
    ├── 404.html    (custom "Page Not Found" page)
    └── 500.html    (custom "Server Error" page)
```

**Command:**

```bash
./PureSimpleHTTPServer \
  --root ./wwwroot \
  --error-pages ./errors \
  --security-headers
```

**What happens:**

- A request for a non-existent file (e.g., `/missing`) serves `errors/404.html` with status code `404`.
- A request for a hidden path (e.g., `/.env`) serves `errors/403.html` with status code `403`.
- If `errors/404.html` does not exist, the server falls back to the default plain-text response.
- The error pages directory is separate from the document root, so error pages are not directly accessible via URL.

**Tip:** Include your site's CSS in the error pages using absolute paths (`/style.css`) so the styling loads from the document root even when the error page comes from a different directory.

---

### Scenario 40: Cache-Control for Fingerprinted Assets

Modern build tools (webpack, Vite, esbuild) produce output files with content hashes in their names (e.g., `app.3f2a1b.js`). These files never change — if the content changes, the filename changes. You can safely cache them for a very long time.

**Command:**

```bash
./PureSimpleHTTPServer \
  --root ./dist \
  --cache-max-age 31536000 \
  --clean-urls
```

**What this does:**

- Every response includes `Cache-Control: max-age=31536000` (1 year).
- Browsers and CDN proxies cache static assets aggressively.
- The ETag/304 mechanism still works — on revalidation, unchanged files return `304 Not Modified` without transferring the body.

**When NOT to use a long max-age:**

- If your files are not fingerprinted, a long max-age means users see stale content until the cache expires.
- For development, use the default `--cache-max-age 0` (always revalidate).

**Typical production combination:**

```bash
./PureSimpleHTTPServer \
  --root /var/www/mysite \
  --port 8080 \
  --cache-max-age 86400 \
  --error-pages /var/www/errors \
  --security-headers \
  --health /healthz \
  --log /var/log/pshs/access.log
```

---

*PureSimpleHTTPServer v2.5.0 — Scenarios Guide*
