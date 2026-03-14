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
