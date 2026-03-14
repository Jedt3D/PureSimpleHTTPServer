# URL Rewriting — PureSimpleHTTPServer v1.5.0

This document covers the full URL rewriting and redirecting system: rule file syntax, pattern types, placeholder substitution, per-directory rules, evaluation order, and practical recipes for common deployment scenarios.

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Rule File Syntax](#2-rule-file-syntax)
3. [Exact Patterns](#3-exact-patterns)
4. [Glob Patterns](#4-glob-patterns)
5. [Regex Patterns](#5-regex-patterns)
6. [Redirect Codes](#6-redirect-codes)
7. [Per-Directory Rules](#7-per-directory-rules)
8. [Evaluation Order](#8-evaluation-order)
9. [Real-World Recipes](#9-real-world-recipes)
10. [Combining with --clean-urls](#10-combining-with---clean-urls)
11. [Troubleshooting Rewrites](#11-troubleshooting-rewrites)
12. [Limits Reference](#12-limits-reference)

---

## 1. Introduction

### What rewriting does

When a browser requests `/about`, PureSimpleHTTPServer normally looks for a file named `about` (or, with `--clean-urls`, `about.html`) in the document root. A **rewrite rule** intercepts the request before that file lookup and substitutes a different path. The substituted path is then used for the file lookup. The browser receives the file content but never learns that any substitution took place — its address bar still shows `/about`.

### What redirecting does

A **redirect rule** also intercepts the request before file serving, but instead of substituting a path, it sends the browser an HTTP redirect response (301 or 302). The browser then issues a new request to the destination URL. The address bar changes to the new URL.

### When to use each

| Situation | Use |
|-----------|-----|
| Clean URLs: hide `.html` extensions from visitors | `rewrite` |
| SPA catch-all: route all paths to `index.html` | `rewrite` |
| Map a URL hierarchy to a different file layout | `rewrite` |
| A page moved permanently to a new URL | `redir 301` |
| A page temporarily at a different URL | `redir 302` |
| Site migration: old domain structure to new | `redir 301` |
| Canonical URLs: remove trailing slashes | `redir 301` |

The practical rule of thumb: if the goal is to serve a file from a path that differs from the requested URL, use `rewrite`. If the goal is to send the browser somewhere else, use `redir`.

---

## 2. Rule File Syntax

### Loading the rule file

```bash
./PureSimpleHTTPServer --rewrite rewrite.conf
```

The path may be absolute or relative to the working directory. The file is loaded once at startup. Per-directory rule files (described in section 7) are discovered and loaded automatically at request time.

### Grammar

Each effective line in the file is one rule. The general form is:

```
<verb>  <pattern>  <destination>  [status-code]
```

Fields are separated by one or more tabs or spaces. The status code is optional and applies only to `redir` rules.

**verb** — one of:

| Verb | Effect |
|------|--------|
| `rewrite` | Internal path substitution. The client sees no change. |
| `redir` | HTTP redirect response sent to the client. |

Any line whose first token is neither `rewrite` nor `redir` is silently ignored. This makes it straightforward to comment out a rule by changing the verb to something else, though the standard mechanism is the `#` character.

**pattern** — the URL path to match against. Three pattern types are supported; see sections 3, 4, and 5.

**destination** — the target path, which may contain placeholders. See individual pattern sections for the available placeholders.

**status-code** — `301` or `302`. Applies to `redir` only. When omitted, `302` is used. Supplying a status code on a `rewrite` rule has no effect.

### Comments and blank lines

Lines starting with `#` are comments. Blank lines are ignored. Both may appear anywhere in the file.

```conf
# This is a comment

# Blank lines above and below this rule are fine
rewrite /about /about.html
```

### Annotated example file

```conf
# -------------------------------------------------------
# rewrite.conf — example with all syntax features shown
# -------------------------------------------------------

# Verb    Pattern               Destination         [Code]
# ------  --------------------  ------------------  -----

# 1. Exact rewrite — no wildcards, no regex prefix
rewrite   /about                /about.html

# 2. Exact redirect — move a page permanently
redir     /old-contact          /contact              301

# 3. Glob rewrite — * captures everything after /blog/
rewrite   /blog/*               /posts/{path}

# 4. Glob rewrite — only the filename from the captured tail
rewrite   /static/*             /assets/{file}

# 5. Glob rewrite — preserve directory structure
rewrite   /uploads/*            /store/{dir}/{file}

# 6. Regex rewrite — ~ prefix, POSIX extended regex
rewrite   ~/user/([0-9]+)       /profile/{re.1}

# 7. Regex redirect — feed URL canonicalization
redir     ~/feed(.*)            /rss{re.1}            301

# 8. Temporary redirect — no code means 302
redir     /preview              /beta
```

### Tab vs. space handling

Tabs and spaces are interchangeable as field separators. You may align columns with tabs for readability. A leading tab or space before the verb is also accepted. Trailing whitespace on any line is ignored.

### Error handling

Rules with an unrecognized verb are skipped silently. Rules with a recognized verb but fewer than two fields (pattern and destination) are also skipped. The server starts normally regardless of how many rules were skipped; it does not abort on a malformed rule file.

---

## 3. Exact Patterns

An exact pattern is a plain URL path with no special prefix and no wildcard characters. It matches only when the incoming request path equals the pattern exactly, including case.

### Syntax

```conf
rewrite  /exact-path  /destination-path
redir    /exact-path  /destination-path  [code]
```

### Examples

**Hide the `.html` extension from a single page:**

```conf
rewrite /about /about.html
```

A request for `/about` serves the file `about.html` from the document root. The browser sees `/about` throughout.

**Permanent redirect for a renamed page:**

```conf
redir /old-contact /contact 301
```

Any client that bookmarked or linked `/old-contact` is automatically sent to `/contact`. Search engines update their index to the new URL.

**Temporary redirect to a maintenance page:**

```conf
redir /checkout /maintenance 302
```

The `302` is explicit here, but would be the default if the code were omitted.

### Site migration with multiple exact redirects

When relaunching a site with a restructured URL scheme, list all the old-to-new pairs:

```conf
# -------------------------------------------------------
# Redirect map for 2025 site migration
# -------------------------------------------------------

redir /services            /what-we-do               301
redir /services/design     /what-we-do/design        301
redir /services/dev        /what-we-do/engineering   301
redir /team                /about/people             301
redir /team/alice          /about/people/alice       301
redir /contact-us          /contact                  301
redir /blog/hello-world    /articles/hello-world     301
redir /blog/second-post    /articles/second-post     301
redir /downloads/manual    /docs/manual.pdf          301
redir /pricing             /plans                    301
```

Each rule is independent. Rules are evaluated in file order; the first match wins and no further rules are checked for that request.

**Note:** Exact patterns are case-sensitive. `/About` does not match a rule for `/about`.

---

## 4. Glob Patterns

A glob pattern ends with `/*`. The `*` is a wildcard that captures the remainder of the URL path after the fixed prefix. The captured text is available in the destination via three placeholders.

### Syntax

```conf
rewrite  /prefix/*  /destination/{placeholder}
redir    /prefix/*  /destination/{placeholder}  [code]
```

The prefix must be a literal path ending in `/`. The `*` is always the last character of the pattern.

### Placeholder reference

| Placeholder | Expands to | Example: request `/static/img/logo.png` matched against `/static/*` |
|-------------|------------|----------------------------------------------------------------------|
| `{path}` | The full captured tail | `img/logo.png` |
| `{file}` | The basename of `{path}` (last path segment) | `logo.png` |
| `{dir}` | Everything before the last `/` in `{path}` | `img` |

When `{path}` contains no `/`, `{file}` equals `{path}` and `{dir}` is empty.

For example, if the request is `/static/logo.png` matched against `/static/*`, then `{path}` = `logo.png`, `{file}` = `logo.png`, and `{dir}` = `` (empty string).

### Examples

**Forward an entire path hierarchy:**

```conf
rewrite /blog/* /posts/{path}
```

| Request | Served file |
|---------|-------------|
| `/blog/hello-world` | `/posts/hello-world` |
| `/blog/2024/hello-world` | `/posts/2024/hello-world` |
| `/blog/2024/june/post` | `/posts/2024/june/post` |

**Flatten to basename only:**

```conf
rewrite /static/* /assets/{file}
```

| Request | Served file |
|---------|-------------|
| `/static/style.css` | `/assets/style.css` |
| `/static/js/app.js` | `/assets/app.js` |
| `/static/fonts/bold.woff2` | `/assets/bold.woff2` |

This discards the directory structure. All files are looked up flat inside `/assets/`.

**Preserve directory structure while changing root:**

```conf
rewrite /uploads/* /store/{dir}/{file}
```

| Request | Served file |
|---------|-------------|
| `/uploads/report.pdf` | `/store//report.pdf` (dir is empty) |
| `/uploads/2024/report.pdf` | `/store/2024/report.pdf` |
| `/uploads/2024/q1/report.pdf` | `/store/2024/q1/report.pdf` |

When the captured tail has no subdirectory, `{dir}` expands to an empty string, producing a double slash. If this matters for your use case, use `{path}` instead:

```conf
rewrite /uploads/* /store/{path}
```

**Glob redirect for a renamed directory hierarchy:**

```conf
redir /downloads/* /files/{path} 301
```

Any URL under `/downloads/` is permanently redirected to the equivalent URL under `/files/`.

**Complex example: static assets with preserved directory structure**

Scenario: The build tool outputs assets into `/assets/css/`, `/assets/js/`, `/assets/img/`. The URLs in HTML point to `/static/css/`, `/static/js/`, `/static/img/`. Rather than renaming directories, a single glob rule bridges them:

```conf
rewrite /static/* /assets/{dir}/{file}
```

| Request | Served file |
|---------|-------------|
| `/static/css/main.css` | `/assets/css/main.css` |
| `/static/js/app.js` | `/assets/js/app.js` |
| `/static/img/logo.png` | `/assets/img/logo.png` |
| `/static/img/icons/favicon.ico` | `/assets/img/icons/favicon.ico` (dir = `img/icons`) |

---

## 5. Regex Patterns

A regex pattern starts with `~`. Everything after the `~` is treated as a POSIX extended regular expression anchored to the start of the URL path.

### Syntax

```conf
rewrite  ~/regex(group)  /destination/{re.N}
redir    ~/regex(group)  /destination/{re.N}  [code]
```

Parentheses create capture groups. Up to nine groups are supported. The captured text of group N is available in the destination as `{re.N}`.

The regex is matched against the full request path starting from `/`. You do not need to add a leading `^`; the match is implicitly anchored at the start. To match only a specific complete path (not a prefix), end the pattern with `$`.

### Placeholder reference

| Placeholder | Expands to |
|-------------|------------|
| `{re.1}` | Text captured by the first `(...)` group |
| `{re.2}` | Text captured by the second `(...)` group |
| ... | |
| `{re.9}` | Text captured by the ninth `(...)` group |

If a group did not participate in the match, its placeholder expands to an empty string.

### Examples

**Map numeric user IDs to profile pages:**

```conf
rewrite ~/user/([0-9]+) /profile/{re.1}
```

| Request | Served file |
|---------|-------------|
| `/user/42` | `/profile/42` |
| `/user/1001` | `/profile/1001` |
| `/user/abc` | no match (not numeric) |

**Swap two path segments:**

```conf
rewrite ~/([a-z]+)/([0-9]+) /{re.2}/{re.1}
```

| Request | Served file |
|---------|-------------|
| `/articles/42` | `/42/articles` |
| `/posts/7` | `/7/posts` |

**Feed URL canonicalization:**

The site previously served RSS at `/feed`, `/feed.xml`, `/feed/atom`, and other variants. Redirect them all to the canonical `/rss`:

```conf
redir ~/feed(.*) /rss{re.1} 301
```

| Request | Redirects to |
|---------|-------------|
| `/feed` | `/rss` |
| `/feed.xml` | `/rss.xml` |
| `/feed/atom` | `/rss/atom` |

The `(.*)` group captures the empty string when nothing follows `/feed`, producing `/rss` exactly.

**Match only a complete path (anchored with `$`):**

```conf
rewrite ~/api/v1$ /api/v2/index.html
```

This matches `/api/v1` exactly. Without the `$`, it would also match `/api/v1/users` and other longer paths.

**Case-insensitive language prefix:**

POSIX extended regex supports character classes but not inline flags. To match both uppercase and lowercase letters in a prefix:

```conf
rewrite ~/([Ee][Nn]|[Ff][Rr]|[Dd][Ee])/(.*) /content/{re.1}/{re.2}
```

For most purposes, keeping URL paths lowercase and using a simple character-class pattern is the cleaner approach.

---

## 6. Redirect Codes

### The two codes

| Code | HTTP status text | Meaning |
|------|-----------------|---------|
| `301` | Moved Permanently | The resource has moved to the new URL permanently. |
| `302` | Found | The resource is temporarily at the new URL. |

### When to use 301

Use `301` when the move is permanent and you want:

- Search engines to transfer ranking signals (link equity) from the old URL to the new one.
- Browsers to stop asking about the old URL and go directly to the new one on repeat visits.
- HTTP clients to update any stored bookmarks or hardcoded links.

Examples: site migrations, renamed pages, canonical URL enforcement, retired product pages.

### When to use 302

Use `302` when the move is temporary and you want:

- Search engines to keep indexing the original URL.
- Browsers to continue fetching the original URL on future visits rather than caching the redirect.

Examples: maintenance pages, A/B testing, feature flags, previews.

### Default behavior

When the status code field is omitted from a `redir` rule, the server uses `302`:

```conf
redir /preview /beta          # sends 302
redir /preview /beta 302      # same effect, code made explicit
redir /old-page /new-page 301 # 301 — must be stated explicitly
```

### Browser and SEO implications

**301 caching:** Browsers cache 301 redirects aggressively and often permanently. Once a browser has seen a 301 from `/old` to `/new`, it may never request `/old` again — even after the rule is removed. During development and testing, use `302` so that the redirect remains reversible. Switch to `301` only when the change is final.

**Search engine crawl delay:** Search engines typically honour 301 redirects within a few days to a few weeks. Until then, both URLs may appear in the index.

**301 on `rewrite` rules:** Supplying a status code on a `rewrite` rule has no effect. The server ignores it.

---

## 7. Per-Directory Rules

### Placing the file

In addition to the global rule file loaded with `--rewrite`, you can place a `rewrite.conf` file inside any subdirectory of the document root. Rules in that file apply only to requests whose URL path is within that directory.

```
wwwroot/
├── index.html
├── rewrite.conf          ← this is the global file (if --rewrite points here)
├── blog/
│   ├── rewrite.conf      ← per-directory rules for /blog/*
│   ├── hello-world.html
│   └── second-post.html
└── api/
    ├── rewrite.conf      ← per-directory rules for /api/*
    └── v2/
```

### How per-directory rules are discovered

When a request arrives for `/blog/my-post`, the server:

1. Determines the URL directory: `/blog/`.
2. Maps that to a filesystem path: `<root>/blog/`.
3. Looks for `<root>/blog/rewrite.conf`.
4. If the file exists, loads and caches its rules.
5. Evaluates those rules against the full request path (e.g., `/blog/my-post`).

The per-directory `rewrite.conf` is not limited to matching paths under its directory — it can technically redirect to anywhere — but its rules are only consulted when the request falls within that directory.

### Auto-reload

Per-directory rule files are cached in memory. Each time a request triggers a lookup of a cached directory's rules, the server checks the file's modification time. If the modification time has changed since the last load, the file is reloaded automatically. There is no need to restart the server after editing a per-directory `rewrite.conf`.

The global rule file loaded at startup with `--rewrite` is not auto-reloaded. Restart the server to pick up changes to the global file.

### Priority: global rules win

Evaluation always checks global rules first. If a global rule matches, per-directory rules for that request are never consulted. This means a global rule can override a per-directory rule, but a per-directory rule can never override a global rule.

See section 8 for the full evaluation flowchart.

### Example: blog directory with its own rules

File: `wwwroot/blog/rewrite.conf`

```conf
# Per-directory rules for /blog/*
# These run only when the request is for something under /blog/

# Map slug URLs to HTML files in this directory
rewrite /blog/*            /blog/{path}.html

# Redirect an old slug that was renamed
redir   /blog/old-title    /blog/new-title   301
```

These rules are evaluated only for requests to `/blog/something`. A request for `/about` never touches this file.

### Directory cache limits

Up to 8 directories are cached simultaneously. When the cache is full and a new directory is encountered, the least-recently-used entry is evicted. The per-directory `rewrite.conf` for the evicted directory will be re-read from disk on the next matching request. For most sites with fewer than 8 directories containing rewrite rules, eviction never occurs.

---

## 8. Evaluation Order

For every incoming `GET` request, the server processes rewrite rules in this order:

```
Incoming request: GET /some/path
         |
         v
+--------------------+
| Global rules       |  (from --rewrite FILE, loaded at startup)
| Checked in order   |
| First match wins   |
+--------------------+
         |
         | No match
         v
+--------------------+
| Per-directory      |  (rewrite.conf inside the matching directory)
| rules              |  Auto-discovered from URL path
| Checked in order   |
| First match wins   |
+--------------------+
         |
         | No match
         v
+--------------------+
| Normal file        |
| serving            |
| (then --clean-urls |
|  extension lookup, |
|  then --spa, etc.) |
+--------------------+
```

**Detailed walkthrough for `GET /blog/hello-world`:**

1. Global rules are checked top to bottom.
   - If any global rule matches `/blog/hello-world`, it fires immediately. No further rules are checked.
2. If no global rule matched, the server looks for `<root>/blog/rewrite.conf`.
   - If the file exists, its rules are checked top to bottom.
   - If a rule matches, it fires. No further rules are checked.
3. If no rule matched at all, the server attempts to serve the file normally.

**First match wins:** Within any rule set (global or per-directory), rules are evaluated in the order they appear in the file. Only the first matching rule fires. Write more-specific rules before more-general ones.

```conf
# More specific first — /blog/special is handled differently
rewrite /blog/special     /special-landing.html

# General blog catch-all second
rewrite /blog/*           /blog/{path}.html
```

If the catch-all were listed first, `/blog/special` would be matched by it and the specific rule below would never be reached.

---

## 9. Real-World Recipes

### a. SPA with clean URLs

A React, Vue, or Angular application uses client-side routing. The server only has `index.html`. All URLs must serve `index.html` so the client-side router can handle them.

```conf
# rewrite.conf

# Serve existing static assets normally (no rule needed — unmatched
# requests fall through to normal file serving).

# Catch all unmatched paths and serve index.html
rewrite ~/((?!assets/|favicon\.ico).*)  /index.html
```

Alternatively, use `--spa` mode instead of a rewrite rule — it has the same effect with no rule file required. If you need to preserve specific paths (like `/api/*` passing through), the regex approach above gives finer control.

A simpler version when all assets are under `/static/` or similar:

```conf
# SPA: route everything not under /static/ to index.html
rewrite ~/(?!static/)(.*)  /index.html
```

### b. Blog with slug-to-HTML mapping

The blog posts are stored as HTML files (`hello-world.html`, `second-post.html`) but should be accessible at clean slug URLs (`/blog/hello-world`, `/blog/second-post`).

```conf
# rewrite.conf (global or placed in wwwroot/blog/ as per-directory)

rewrite /blog/* /blog/{path}.html
```

Combined with `--clean-urls`, the `.html` extension lookup happens after the rewrite, so even `rewrite /blog/* /blog/{path}` (without `.html`) would work — but being explicit avoids ambiguity.

### c. API versioning

All `/api/*` requests are internally forwarded to the v2 API directory:

```conf
rewrite /api/* /v2/{path}
```

| Request | Served from |
|---------|-------------|
| `/api/users` | `/v2/users` |
| `/api/users/42` | `/v2/users/42` |
| `/api/posts/recent` | `/v2/posts/recent` |

When v3 is ready, update the single rule and the entire API transparently migrates.

### d. Canonical redirect — trailing slash removal

Ensure that every URL without a trailing slash is canonical, redirecting the trailing-slash variant:

```conf
# Redirect trailing-slash URLs to their canonical form
redir ~/(.+)/$ /{re.1} 301
```

| Request | Redirects to |
|---------|-------------|
| `/about/` | `/about` |
| `/blog/hello-world/` | `/blog/hello-world` |

The pattern `(.+)/` requires at least one character before the slash, so the root URL `/` is not affected.

To do the opposite (enforce a trailing slash), swap the pattern and destination:

```conf
redir ~/([^/][^/]*)$ /{re.1}/ 301
```

### e. Site migration using glob

A 2024 site restructuring moved content from flat paths to a dated hierarchy. The old structure had hundreds of pages under `/articles/`. The new structure uses `/archive/YYYY/MM/slug`. However, the old short URLs can be redirected to the new section root, and the exact slug mapping can be handled by a redirect to the archive index.

For situations where the new path can be derived mechanically from the old one, glob rules handle the entire mapping in one line:

```conf
# Old: /articles/slug → New: /archive/slug (preserves slug)
redir /articles/* /archive/{path} 301
```

For a deeper reorganization where the old path structure maps cleanly to the new one:

```conf
# Old: /en/blog/slug → New: /content/en/blog/slug
redir /en/* /content/en/{path} 301
```

If you have a mix of mechanical mappings and exceptions, list the exceptions first (they are more specific) and the catch-all glob last:

```conf
# Exceptions that do not follow the pattern
redir /articles/about-us  /about         301
redir /articles/jobs      /careers       301

# General mapping for everything else
redir /articles/*         /archive/{path} 301
```

### f. Per-language routing

Route language-prefixed URLs to locale-specific content directories:

```conf
# Global rewrite.conf

rewrite /en/* /content/en/{path}
rewrite /fr/* /content/fr/{path}
rewrite /de/* /content/de/{path}
```

| Request | Served from |
|---------|-------------|
| `/en/home` | `/content/en/home` |
| `/fr/accueil` | `/content/fr/accueil` |
| `/de/startseite` | `/content/de/startseite` |

To redirect to a default language when no prefix is given, add an exact rule before the glob rules:

```conf
redir / /en/ 302
rewrite /en/* /content/en/{path}
rewrite /fr/* /content/fr/{path}
rewrite /de/* /content/de/{path}
```

The `302` on the root redirect is intentional — use temporary until you are confident the default language will not change.

---

## 10. Combining with --clean-urls

### Order of operations

When both `--rewrite` and `--clean-urls` are active, the request processing pipeline is:

```
1. Rewrite/redirect rules evaluated (global, then per-directory)
2. If a rewrite matched: the rewritten path is used for file lookup
3. File lookup: try exact path first
4. --clean-urls: if exact path not found, try path + ".html"
5. If --spa is active: serve index.html for any remaining 404
```

A `redir` rule short-circuits the pipeline at step 1 — the HTTP redirect is sent and file serving does not occur.

### Practical example

With `--clean-urls` active and this rule file:

```conf
rewrite /blog/* /blog/{path}
```

A request for `/blog/hello-world`:

1. Rule matches: path becomes `/blog/hello-world`.
2. File lookup: tries `<root>/blog/hello-world` — not found.
3. `--clean-urls`: tries `<root>/blog/hello-world.html` — found, served.

This means you can write glob rules without `.html` suffixes and rely on `--clean-urls` to resolve the final extension, which keeps the rule file cleaner.

### Writing rules that work with or without --clean-urls

If `--clean-urls` is not active, be explicit about extensions in destinations:

```conf
# Without --clean-urls: destination must include .html
rewrite /blog/* /blog/{path}.html
```

If `--clean-urls` is active, you can drop the extension:

```conf
# With --clean-urls: destination without .html is fine
rewrite /blog/* /blog/{path}
```

Either form works when `--clean-urls` is active — the explicit `.html` form simply short-circuits the extension fallback.

---

## 11. Troubleshooting Rewrites

### Rule not matching

**Symptom:** The rewrite or redirect does not fire; the server serves the original path or returns a 404.

**Checklist:**

1. **Leading slash.** Both the pattern and the destination must start with `/`. A pattern without a leading slash will never match.

   ```conf
   # Wrong — missing leading slash
   rewrite about /about.html

   # Correct
   rewrite /about /about.html
   ```

2. **Pattern type detection.** The server determines the pattern type by inspecting the pattern:
   - Starts with `~` → regex
   - Ends with `/*` → glob
   - Otherwise → exact

   A glob pattern must end with exactly `/*`. `/blog/` (without `*`) is an exact pattern that will only match `/blog/` exactly.

3. **Rule order.** The first matching rule wins. If a general rule appears before a specific one, the specific rule is never reached.

4. **Global vs. per-directory.** A per-directory rule is only consulted after all global rules have been checked and none matched. If a global rule is consuming the request, the per-directory rule will never fire.

5. **Case sensitivity.** Patterns are case-sensitive. `/About` does not match a rule for `/about`.

6. **Regex syntax.** Test the regex against your paths independently with a POSIX ERE tool. The `~` prefix must immediately precede the regex — no space between `~` and the pattern.

   ```conf
   # Wrong — space between ~ and regex
   rewrite ~ /user/([0-9]+) /profile/{re.1}

   # Correct
   rewrite ~/user/([0-9]+) /profile/{re.1}
   ```

### `{re.N}` expanding to an empty string

**Symptom:** The destination path contains a literal empty string where a capture group value was expected.

**Causes:**

- The group index is out of range. Groups are numbered from 1. `{re.0}` is not defined. `{re.10}` exceeds the nine-group limit.
- The group did not participate in the match. For example, a pattern with an alternation where only one branch has a capturing group: `~/a(foo)|b(bar)` — if the `b(bar)` branch matches, `{re.1}` is empty and `{re.2}` holds `bar`.
- The regex did not actually match but evaluation reached the rule anyway (this should not happen in normal operation).

**How to verify:** Add a temporary exact pattern with the same destination to confirm the destination syntax is correct, then re-introduce the regex.

### Per-directory rule not firing

**Symptom:** A `rewrite.conf` placed inside a directory has no effect.

**Checklist:**

1. **File location.** The file must be named exactly `rewrite.conf` (all lowercase) and placed directly inside the served directory that corresponds to the URL prefix. For `/blog/hello-world`, the file must be at `<root>/blog/rewrite.conf`.

2. **Modification time.** The server caches per-directory rules and reloads them when the file modification time changes. If the file was created or modified while the server was running, the next request to that directory will trigger a reload. If no reload occurs, verify the file's mtime has changed (some editors create a new inode with the same timestamp).

3. **Global rule taking priority.** Run a quick test by temporarily disabling all global rules to confirm the per-directory rule works in isolation.

4. **Directory cache full.** If more than 8 directories have `rewrite.conf` files, the least-recently-used entry is evicted. The evicted directory's rules are re-read on the next request. If you have more than 8 directories with rules and are seeing inconsistent behaviour, this is the likely cause.

5. **Pattern still needs to match the full path.** Per-directory rules still match against the complete URL path, not just the portion after the directory prefix. A rule of `rewrite /post /post.html` in `wwwroot/blog/rewrite.conf` needs the request to be exactly `/post` — it will not match `/blog/post`. Write the rule as `rewrite /blog/post /blog/post.html`.

---

## 12. Limits Reference

| Item | Limit |
|------|-------|
| Global rules | 64 |
| Per-directory rules per directory | 16 |
| Cached directories | 8 |
| Regex capture groups | 9 |
| Pattern length | 511 bytes |
| Destination length | 511 bytes |

Rules beyond the per-directory limit (16) are silently ignored. If you need more than 16 rules in a directory, consider consolidating patterns (globs often replace many exact rules) or moving some rules to the global file.

---

*PureSimpleHTTPServer v1.5.0 — URL Rewriting*
