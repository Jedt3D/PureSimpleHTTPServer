# URL Rewriting — PureSimpleHTTPServer

PureSimpleHTTPServer supports Caddy-compatible URL rewriting and redirecting via a simple rule file. Rules apply to every `GET` request before the file is served.

## Quick start

```bash
./PureSimpleHTTPServer --rewrite rewrite.conf
```

## Rule file syntax

Each non-blank, non-comment line is one rule:

```
rewrite  <pattern>  <destination>
redir    <pattern>  <destination>  [status-code]
```

| Verb | Effect |
|------|--------|
| `rewrite` | Internally rewrites the path — the client sees nothing, a different file is served |
| `redir` | Sends an HTTP redirect response to the client |

Lines starting with `#` are comments and are ignored.

## Pattern types

| Prefix | Type | Example |
|--------|------|---------|
| _(none)_ | Exact | `/about` — matches only `/about` exactly |
| Trailing `*` | Glob | `/blog/*` — `*` captures everything after the prefix |
| Leading `~` | Regex | `~/user/([0-9]+)` — POSIX regex, groups captured |

## Destination placeholders

| Placeholder | Expands to |
|-------------|-----------|
| `{path}` | The text captured by `*` in a glob pattern |
| `{file}` | The basename (last segment) of `{path}` |
| `{dir}` | The directory portion (everything before the last `/`) of `{path}` |
| `{re.1}` … `{re.9}` | Regex capture groups 1–9 |

## Examples

```conf
# Exact rewrite — serve /about.html when /about is requested
rewrite /about /about.html

# Glob rewrite — rewrite /blog/post-slug to /posts/post-slug
rewrite /blog/* /posts/{path}

# Glob rewrite — only keep the filename part
rewrite /static/* /assets/{file}

# Glob rewrite — keep dir and file separate
rewrite /uploads/* /store/{dir}/{file}

# Regex rewrite — rewrite /user/42 to /profile/42
rewrite ~/user/([0-9]+) /profile/{re.1}

# Permanent redirect (301)
redir /old-page /new-page 301

# Temporary redirect (302) — default when code is omitted
redir /old /new

# Glob redirect
redir /downloads/* /files/{path} 301

# Regex redirect
redir ~/feed(.*) /rss{re.1} 301
```

## Per-directory rules

Place a `rewrite.conf` file inside any served directory. Rules in that file apply to requests whose URL path falls within that directory.

**Evaluation order:** global rules (from `--rewrite FILE`) are checked first; per-directory rules second. The first matching rule wins.

Per-directory rule files are cached in memory and automatically reloaded when the file's modification time changes.

## Redirect status codes

| Code | Meaning |
|------|---------|
| `301` | Moved Permanently — browsers and search engines cache this |
| `302` | Found (temporary redirect) — **default when omitted** |

## Limits

| Item | Limit |
|------|-------|
| Global rules | 64 |
| Per-directory rules per directory | 16 |
| Cached directories | 8 |
| Pattern / destination length | 511 bytes (ASCII) |
| Regex capture groups | 9 |

## Integration with `--clean-urls`

Rewrite rules are applied **before** the clean-URL extension lookup. A rewrite to `/page` will then benefit from the `.html` extension fallback if the file `/page` does not exist but `/page.html` does.

---

## ⚠️ CRITICAL: Rewrite Rules and Index Files

### The Problem

**Rewrite rules are evaluated BEFORE the server checks for index files.**

PureSimpleHTTPServer has built-in support for serving index files (`index.html`, `index.htm`) when a directory is requested. However, rewrite rules take priority in the request processing pipeline:

```
Request received
    ↓
1. ApplyRewrites() ← Rewrite rules evaluated HERE
    ↓
2. ServeFile()     ← Index file check happens HERE
```

### Common Pitfall

**Incorrect configuration** — This will break directory index pages:

```conf
# ❌ BROKEN: Catch-all catches everything, including index requests
rewrite /blog/* /blog/posts/{path}.html
```

**What happens:**
- Request: `/blog/`
- Rewrite rule matches: `/blog/*` captures empty `*`
- Path becomes: `/blog/posts/.html` ❌ (doesn't exist)
- Result: **404 Not Found**

### The Solution

**Correct configuration** — Add explicit index rules BEFORE the catch-all:

```conf
# ✅ CORRECT: Explicit rules first, catch-all last

# Serve directory index page explicitly
rewrite /blog/ /blog/index.html
rewrite /blog/index.html /blog/index.html

# Rewrite blog post slugs to the posts/ directory
rewrite /blog/* /blog/posts/{path}.html
```

**Rules are evaluated in order; first match wins:**
- `/blog/` → matches line 1 → serves `blog/index.html` ✅
- `/blog/index.html` → matches line 2 → serves `blog/index.html` ✅
- `/blog/hello-world` → skips to line 4 → serves `posts/hello-world.html` ✅

### Real-World Example

**wwwroot/blog/rewrite.conf** — Proper index file handling:

```conf
# Per-directory rewrite rules for /blog/
# Rules evaluated in order; first match wins.

# IMPORTANT: Explicit index rules must come BEFORE wildcard patterns
rewrite /blog/ /blog/index.html
rewrite /blog/index.html /blog/index.html
rewrite /blog/index.htm /blog/index.htm

# Rewrite blog post slugs to the posts/ subdirectory
# Example: /blog/hello-world → /blog/posts/hello-world.html
rewrite /blog/* /blog/posts/{path}.html
```

### Best Practices

1. **Always list specific paths before wildcards** — More specific patterns should come first
2. **Explicitly handle index files** — If using wildcards that match directories, add explicit index rules
3. **Test with trailing slashes** — Test both `/dir` and `/dir/` to ensure both work
4. **Use per-directory rules for subdirectory rewrites** — This keeps rules scoped to their relevant paths

### Request Processing Order

For reference, here's the complete request processing pipeline in PureSimpleHTTPServer:

1. **Parse HTTP request** (main.pb line 65)
2. **Apply rewrite/redirect rules** (main.pb line 76) ← **Rewrites happen here**
3. **Try embedded assets** (main.pb line 94)
4. **Serve file from disk** (main.pb line 98)
   - Check if path is a directory
   - **Resolve index file** (FileServer.pbi line 122) ← **Index check happens here**
   - Generate directory listing (if `--browse` enabled)
5. **Return response**

### Summary

| Feature | Applied When | Priority |
|---------|--------------|----------|
| Rewrite rules | **First** (before file serving) | **Highest** |
| Index file lookup | Second (only for directories) | Medium |
| Clean URLs (`--clean-urls`) | Third (if rewrite doesn't match) | Low |
| SPA fallback (`--spa`) | Last (on 404 only) | Lowest |

**Key takeaway:** If your rewrite rules use wildcard patterns (`*`) that could match directory requests, you must explicitly handle index files BEFORE the wildcard rule.
