# Quick Start — PureSimpleHTTPServer v1.5.0

## What Is PureSimpleHTTPServer?

PureSimpleHTTPServer is a fast, single-binary static file server for macOS, Linux, and Windows. Drop the binary next to your website files and it is ready to serve — no runtime, no interpreter, no package manager, and no configuration files required. It supports directory listing, single-page application (SPA) mode, clean URLs, URL rewriting, and structured access logging, all controlled through straightforward command-line flags.

---

## System Requirements

| Platform | Minimum Version | Notes |
|----------|----------------|-------|
| macOS    | 11 (Big Sur)   | ARM and x86-64 binaries available |
| Linux    | glibc 2.17+    | Covers most distributions from 2013 onward (RHEL 7, Ubuntu 14.04, Debian 8) |
| Windows  | 10             | x86-64 only |

No external dependencies are needed. The binary is fully self-contained.

---

## Download and First Run

Place the binary in the same directory as your `wwwroot/` folder (or any folder you want to serve):

```
my-site/
├── PureSimpleHTTPServer   (or PureSimpleHTTPServer.exe on Windows)
└── wwwroot/
    ├── index.html
    └── style.css
```

Make the binary executable on macOS and Linux:

```bash
chmod +x ./PureSimpleHTTPServer
```

Start the server:

```bash
./PureSimpleHTTPServer
```

The server listens on port **8080** by default and serves files from the `wwwroot/` subdirectory next to the binary.

On Windows, run from a Command Prompt or PowerShell:

```bat
.\PureSimpleHTTPServer.exe
```

---

## Verify It Works

**With curl:**

```bash
curl -I http://localhost:8080/
```

A successful response returns `HTTP/1.1 200 OK` along with headers.

**In a browser:**

Open `http://localhost:8080/` — your `index.html` (or a directory listing if `--browse` is enabled) will appear.

---

## Serve a Specific Folder

Use `--root` to point the server at any directory on your machine:

```bash
./PureSimpleHTTPServer --root /path/to/site
```

The path can be absolute or relative to the current working directory:

```bash
./PureSimpleHTTPServer --root ./dist
```

---

## Five Useful Flags to Know

These five flags cover the most common scenarios. Each is covered in full in the [CLI Reference](CLI_REFERENCE.md).

| Flag | What It Does |
|------|-------------|
| `--port N` | Change the listening port from the default 8080 |
| `--browse` | Show a file listing when a directory has no index file |
| `--spa` | SPA mode: return `index.html` for every 404 (React, Vue, Angular) |
| `--log FILE` | Write an Apache Combined Log Format access log to `FILE` |
| `--rewrite FILE` | Load URL rewrite and redirect rules from `FILE` |

**Quick examples:**

```bash
# Run on port 3000
./PureSimpleHTTPServer --port 3000

# Enable directory listing
./PureSimpleHTTPServer --browse

# Serve a React app — all client-side routes return index.html
./PureSimpleHTTPServer --root ./build --spa

# Log every request to access.log
./PureSimpleHTTPServer --log ./logs/access.log

# Apply URL rewrite rules
./PureSimpleHTTPServer --rewrite ./rewrite.conf
```

---

## Where to Go Next

- **[CLI_REFERENCE.md](CLI_REFERENCE.md)** — Every flag documented with types, defaults, and examples.
- **[SCENARIOS.md](SCENARIOS.md)** — End-to-end recipes for common deployment patterns (SPA, reverse proxy companion, CI preview server, etc.).
- **[URL_REWRITING.md](URL_REWRITING.md)** — Syntax and examples for the `rewrite.conf` rule file.
