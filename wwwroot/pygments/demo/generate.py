"""
Generates pygments/demo/index.html — the static Pygments demo page.
Run: python3 pygments/demo/generate.py
"""

import importlib.util, os, textwrap
from pygments import highlight
from pygments.formatters import HtmlFormatter
from pygments.lexers import PythonLexer, get_lexer_by_name

# ── Load XojoLexer, XojoOneDarkStyle, XojoOneLightStyle from parent directory ─
_lexer_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'xojo.pygments.py')
_spec = importlib.util.spec_from_file_location('xojo_pygments', _lexer_path)
_mod  = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_mod)
XojoLexer         = _mod.XojoLexer
XojoOneDarkStyle  = _mod.XojoOneDarkStyle
XojoOneLightStyle = _mod.XojoOneLightStyle

# ── Sample Xojo code (identical to the other three demos) ────────────────────
XOJO_CODE = """\
// Fibonacci — Xojo syntax demo
' Apostrophe comments work too

#pragma DisableBackgroundTasks
#tag Module, Name = MathUtils

Function Fibonacci(n As Integer) As Integer
  If n <= 1 Then Return n
  Return Fibonacci(n - 1) + Fibonacci(n - 2)
End Function

#tag EndModule

Class MyWindow
  Inherits DesktopWindow

  Property Title As String = "My App"

  Sub Opening()
    Var btn As New DesktopButton
    btn.Caption = "Click Me"
    btn.Left = 20
    btn.Top = 20

    Var mask  As Integer = &hFF00FF    // hex literal
    Var flags As Integer = &b10101010  // binary literal
    Var pi    As Double  = 3.14159

    If mask = Nil Or flags = 0 Then
      Raise New RuntimeException("Error")
    End If

    AddHandler btn.Pressed, AddressOf ButtonPressed
  End Sub

  Sub ButtonPressed(sender As DesktopButton)
    Self.Title = "Clicked!"
  End Sub

End Class
"""

USAGE_PY = """\
import importlib.util
from pygments import highlight
from pygments.formatters import HtmlFormatter

# Load lexer — no pip install required, just copy xojo.pygments.py
spec = importlib.util.spec_from_file_location("xojo_pygments", "xojo.pygments.py")
mod  = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

html = highlight(
    code,
    mod.XojoLexer(),
    HtmlFormatter(style=mod.XojoOneDarkStyle),
)
"""

USAGE_CLI = """\
# Terminal output (256-colour themes)
python3 -m pygments -x -l xojo.pygments.py:XojoLexer file.xojo_code

# Full self-contained HTML with One Dark style
python3 -m pygments -x -l xojo.pygments.py:XojoLexer file.xojo_code \\
  -f html -O full -o output.html
"""

# ── Render all code blocks with Pygments (dark and light) ────────────────────
dark_args  = dict(style=XojoOneDarkStyle,  cssclass='xojo-code xojo-dark')
light_args = dict(style=XojoOneLightStyle, cssclass='xojo-code xojo-light')

xojo_dark_html  = highlight(XOJO_CODE, XojoLexer(), HtmlFormatter(**dark_args))
xojo_light_html = highlight(XOJO_CODE, XojoLexer(), HtmlFormatter(**light_args))

py_dark_html    = highlight(USAGE_PY,  PythonLexer(), HtmlFormatter(**dark_args))
py_light_html   = highlight(USAGE_PY,  PythonLexer(), HtmlFormatter(**light_args))

bash_dark_html  = highlight(USAGE_CLI, get_lexer_by_name('bash'), HtmlFormatter(**dark_args))
bash_light_html = highlight(USAGE_CLI, get_lexer_by_name('bash'), HtmlFormatter(**light_args))

# CSS for both styles
dark_css  = HtmlFormatter(style=XojoOneDarkStyle,  cssclass='xojo-dark').get_style_defs('.xojo-dark')
light_css = HtmlFormatter(style=XojoOneLightStyle, cssclass='xojo-light').get_style_defs('.xojo-light')

# ── Assemble full HTML page ───────────────────────────────────────────────────
PAGE = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Xojo · Pygments Demo</title>

  <!-- Apply stored theme before paint to avoid flash -->
  <script>(function(){{var t=localStorage.getItem('xojo-theme')||'dark';document.documentElement.setAttribute('data-theme',t);}})();</script>

  <style>
    *, *::before, *::after {{ box-sizing: border-box; margin: 0; padding: 0; }}

    /* ── Theme variables ───────────────────────────────────────────────────── */
    :root {{
      --bg-page:       #0d1117;
      --bg-card:       #161b22;
      --bg-inner:      #21262d;
      --border:        #21262d;
      --border-2:      #30363d;
      --text:          #c9d1d9;
      --text-muted:    #8b949e;
      --text-heading:  #f0f6fc;
      --active-bg:     rgba(31,111,235,0.15);
      --active-text:   #58a6ff;
      --active-border: #1f6feb;
    }}
    [data-theme="light"] {{
      --bg-page:       #ffffff;
      --bg-card:       #f6f8fa;
      --bg-inner:      #eaeef2;
      --border:        #d0d7de;
      --border-2:      #d0d7de;
      --text:          #24292f;
      --text-muted:    #57606a;
      --text-heading:  #1f2328;
      --active-bg:     rgba(9,105,218,0.1);
      --active-text:   #0969da;
      --active-border: #0969da;
    }}

    body {{
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background: var(--bg-page);
      color: var(--text);
      padding: 2.5rem 2rem;
      line-height: 1.6;
    }}

    /* ── Navigation ────────────────────────────────────────────────────────── */
    .lib-nav {{
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-bottom: 2.5rem;
      padding-bottom: 1rem;
      border-bottom: 1px solid var(--border);
      flex-wrap: wrap;
      gap: 0.75rem;
    }}
    .nav-home {{ color: var(--text-muted); text-decoration: none; font-size: 0.85rem; }}
    .nav-home:hover {{ color: var(--text); }}
    .nav-right {{ display: flex; align-items: center; gap: 0.5rem; flex-wrap: wrap; }}
    .nav-libs  {{ display: flex; gap: 0.5rem; flex-wrap: wrap; }}
    .nav-lib {{
      font-size: 0.78rem; padding: 2px 10px; border-radius: 20px;
      text-decoration: none; color: var(--text-muted);
      background: var(--bg-inner); border: 1px solid var(--border-2); white-space: nowrap;
    }}
    .nav-lib:hover {{ color: var(--text); border-color: var(--text-muted); }}
    .nav-lib.active {{ color: var(--active-text); background: var(--active-bg); border-color: var(--active-border); }}

    /* ── Theme toggle ──────────────────────────────────────────────────────── */
    .theme-toggle {{
      background: none; border: 1px solid var(--border-2); border-radius: 6px;
      padding: 4px 7px; cursor: pointer; color: var(--text-muted);
      display: flex; align-items: center; flex-shrink: 0; line-height: 0;
    }}
    .theme-toggle:hover {{ color: var(--text); border-color: var(--text-muted); }}
    .icon-moon {{ display: none; }}
    .icon-sun  {{ display: block; }}
    [data-theme="light"] .icon-moon {{ display: block; }}
    [data-theme="light"] .icon-sun  {{ display: none; }}

    /* ── Page header ───────────────────────────────────────────────────────── */
    .page-header {{ display: flex; align-items: baseline; gap: 1rem; margin-bottom: 0.4rem; }}
    h1 {{ font-size: 1.8rem; color: var(--text-heading); }}
    .lib-badge {{
      font-size: 0.8rem; background: var(--bg-inner); border: 1px solid var(--border-2);
      border-radius: 20px; padding: 3px 12px; color: var(--text-muted);
    }}
    .subtitle {{ color: var(--text-muted); font-size: 0.9rem; margin-bottom: 2.5rem; }}

    h2 {{
      font-size: 1rem; font-weight: 600; color: var(--text-muted);
      text-transform: uppercase; letter-spacing: 0.08em; margin: 2.5rem 0 0.85rem;
    }}
    h2:first-of-type {{ margin-top: 0; }}

    /* ── Pygments code blocks ─────────────────────────────────────────────── */
    .xojo-code {{
      border-radius: 8px;
      font-size: 0.85rem;
      line-height: 1.65;
      overflow: auto;
    }}
    .xojo-code pre {{
      margin: 0;
      padding: 1.2rem 1.4rem;
      font-family: 'JetBrains Mono', 'Fira Code', 'Cascadia Code', 'SF Mono', Menlo, monospace;
      font-size: 0.85rem;
      line-height: 1.65;
    }}

    /* ── Dark / Light code block visibility ───────────────────────────────── */
    .xojo-light {{ display: none; }}
    [data-theme="light"] .xojo-dark  {{ display: none; }}
    [data-theme="light"] .xojo-light {{ display: block; }}

    /* ── Token coverage grid ─────────────────────────────────────────────── */
    .token-grid {{
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
      gap: 0.5rem;
    }}
    .token-row {{
      display: flex; align-items: center; gap: 0.6rem;
      background: var(--bg-card); border: 1px solid var(--border);
      border-radius: 6px; padding: 0.45rem 0.75rem; font-size: 0.82rem;
    }}
    .token-row .swatch {{ width: 10px; height: 10px; border-radius: 50%; flex-shrink: 0; }}
    .token-row .label   {{ color: var(--text-muted); }}
    .token-row .examples {{ color: var(--text); font-family: monospace; }}

    .sw-keyword  {{ background: #c678dd; }}
    .sw-constant {{ background: #d19a66; }}
    .sw-type     {{ background: #56b6c2; }}
    .sw-builtin  {{ background: #e06c75; }}
    .sw-comment  {{ background: #5c6370; }}
    .sw-preproc  {{ background: #e5c07b; }}
    .sw-string   {{ background: #98c379; }}
    .sw-number   {{ background: #d19a66; }}
    .sw-operator {{ background: #56b6c2; }}

    p.note {{ color: var(--text-muted); font-size: .85rem; margin-bottom: .5rem; }}
    p.note + p.note {{ margin-top: -.25rem; margin-bottom: .5rem; }}

    /* ── Pygments generated CSS ──────────────────────────────────────────── */
    {dark_css}
    {light_css}
  </style>
</head>
<body>

<nav class="lib-nav">
  <a href="/" class="nav-home">&#8592; Xojo Syntax Highlight</a>
  <div class="nav-right">
    <div class="nav-libs">
      <a href="/highlightjs/demo/" class="nav-lib">highlight.js</a>
      <a href="/prismjs/demo/"     class="nav-lib">Prism.js</a>
      <a href="/codemirror/demo/"  class="nav-lib">CodeMirror 6</a>
      <a href="/pygments/demo/"    class="nav-lib active">Pygments</a>
    </div>
    <button class="theme-toggle" onclick="toggleTheme()" title="Toggle light/dark theme">
      <svg class="icon-sun" xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="5"/><line x1="12" y1="1" x2="12" y2="3"/><line x1="12" y1="21" x2="12" y2="23"/><line x1="4.22" y1="4.22" x2="5.64" y2="5.64"/><line x1="18.36" y1="18.36" x2="19.78" y2="19.78"/><line x1="1" y1="12" x2="3" y2="12"/><line x1="21" y1="12" x2="23" y2="12"/><line x1="4.22" y1="19.78" x2="5.64" y2="18.36"/><line x1="18.36" y1="5.64" x2="19.78" y2="4.22"/></svg>
      <svg class="icon-moon" xmlns="http://www.w3.org/2000/svg" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/></svg>
    </button>
  </div>
</nav>

<div class="page-header">
  <h1>Xojo Syntax Highlighting</h1>
  <span class="lib-badge">Pygments</span>
</div>
<p class="subtitle">Python RegexLexer — server-side rendering with One Dark / One Light color schemes.</p>

<h2>Preview</h2>
{xojo_dark_html}
{xojo_light_html}

<h2>Token Coverage</h2>
<div class="token-grid">
  <div class="token-row"><span class="swatch sw-keyword"></span><span class="label">Keyword</span><span class="examples">Var Sub If Return…</span></div>
  <div class="token-row"><span class="swatch sw-constant"></span><span class="label">Keyword.Constant</span><span class="examples">True False Nil</span></div>
  <div class="token-row"><span class="swatch sw-type"></span><span class="label">Keyword.Type</span><span class="examples">Integer String Double…</span></div>
  <div class="token-row"><span class="swatch sw-builtin"></span><span class="label">Name.Builtin</span><span class="examples">Self Super Me</span></div>
  <div class="token-row"><span class="swatch sw-comment"></span><span class="label">Comment.Single</span><span class="examples">// line  ' apostrophe</span></div>
  <div class="token-row"><span class="swatch sw-preproc"></span><span class="label">Comment.Preproc</span><span class="examples">#pragma #tag #if #endif</span></div>
  <div class="token-row"><span class="swatch sw-string"></span><span class="label">String.Double</span><span class="examples">"double quoted"</span></div>
  <div class="token-row"><span class="swatch sw-number"></span><span class="label">Number.*</span><span class="examples">42  3.14  &amp;hFF  &amp;b1010</span></div>
  <div class="token-row"><span class="swatch sw-operator"></span><span class="label">Operator.Word</span><span class="examples">And Or Not Is IsA…</span></div>
</div>

<h2>Usage</h2>
<p class="note">1. Python — load the lexer and render to HTML:</p>
{py_dark_html}
{py_light_html}

<p class="note" style="margin-top:1rem;">2. Command line — no install required:</p>
{bash_dark_html}
{bash_light_html}

<script>
function toggleTheme() {{
  var n = document.documentElement.getAttribute('data-theme') === 'dark' ? 'light' : 'dark';
  document.documentElement.setAttribute('data-theme', n);
  localStorage.setItem('xojo-theme', n);
}}
</script>

</body>
</html>
"""

# ── Write output ──────────────────────────────────────────────────────────────
out_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'index.html')
with open(out_path, 'w', encoding='utf-8') as f:
    f.write(PAGE)

print(f"Generated: {out_path}")
