"""
Pygments lexer for Xojo
https://github.com/worajedt/xojo-syntax-highlight

Xojo is a programming language evolved from BASIC, supporting Desktop/Web/Mobile app development.
This file defines a lexer for Pygments to correctly highlight Xojo code.

Covers the following patterns:
  - Comments: // and ' (apostrophe)
  - Double-quoted strings
  - Decimal numbers, &h hex, &b binary
  - Xojo-specific reserved words such as Var, Nil, Self, Super, #tag
  - Case-insensitive (Xojo does not distinguish uppercase/lowercase)

Usage:
  from pygments import highlight
  from pygments.formatters import HtmlFormatter
  # Load lexer manually (not installed as a package)
  import importlib.util, os
  spec = importlib.util.spec_from_file_location("xojo_pygments", "xojo.pygments.py")
  mod  = importlib.util.module_from_spec(spec)
  spec.loader.exec_module(mod)

  html = highlight(code, mod.XojoLexer(), HtmlFormatter())

Command-line usage (no install required):
  python -m pygments -x -l xojo.pygments.py:XojoLexer input.xojo_code -f html -o out.html
"""

import re
from pygments.lexer import RegexLexer, words
from pygments.style import Style
from pygments.token import (
    Comment, Keyword, Name, Number, Operator,
    Punctuation, String, Token, Whitespace,
)

# ──────────────────────────────────────────────────────────────────────────────
# Keyword lists — defined at module level because Python does not allow
# referencing one class attribute inside the definition of another
# (class scope does not propagate)
# ──────────────────────────────────────────────────────────────────────────────

# Main reserved words → Token: Keyword
_KEYWORDS = (
    # Variable declaration
    #   Var → modern form (Xojo 2019+)   Dim → legacy form (backward compatible)
    'Var', 'Dim',

    # Function/method declaration
    #   Sub → no return value (void)   Function → has return value
    'Sub', 'Function',

    # OOP structures and modules
    'Class', 'Module', 'Interface', 'Enum',

    # Conditional control
    'If', 'Then', 'Else', 'ElseIf', 'End',

    # Loops
    'For', 'Each', 'Next', 'While', 'Wend', 'Do', 'Loop', 'Until',

    # Select-Case and flow control
    'Select', 'Case', 'Break', 'Continue',

    # Exception handling
    'Try', 'Catch', 'Finally', 'Raise', 'RaiseEvent', 'Return', 'Exit',

    # OOP — instance creation and inheritance
    'New', 'Inherits', 'Implements', 'Extends',

    # Event handler management
    'AddHandler', 'RemoveHandler',

    # Access modifiers
    #   Static → local var that retains value between calls (different from Shared)
    #   Shared → member accessible without creating an instance
    'Public', 'Private', 'Protected', 'Static', 'Shared', 'Global',

    # OOP modifiers
    'Override', 'Virtual', 'Final', 'Abstract',

    # Special class members
    #   Delegate   → function pointer for callbacks
    #   ParamArray → variadic parameter (array)
    #   Optional   → parameter that does not need to be passed
    'Property', 'Event', 'Delegate', 'ParamArray', 'Optional',

    # Keywords for parameter and type declaration
    #   As    → specify type, e.g. "Var x As Integer"
    #   ByRef → pass by reference (can modify the original value)
    #   ByVal → pass by copy (default)
    #   Of    → used with generics, e.g. Dictionary(Of String, Integer)
    'As', 'ByRef', 'ByVal', 'Of',

    # Others
    'Call', 'Using', 'Namespace',
)

# Keyword-style operators → Token: Operator.Word
# Separated from _KEYWORDS so themes can use different colors
_OPERATOR_KEYWORDS = (
    'And', 'Or', 'Not', 'Xor',         # logical operators
    'Mod',                               # modulo (remainder division)
    'In',                                # membership check (used in For Each)
    'IsA',                               # type check (covers Isa via case-insensitive)
    'Is',                                # nil check — must come after IsA in alternation
    'AddressOf', 'WeakAddressOf',        # get pointer to method (for delegates)
)

# Built-in data types → Token: Keyword.Type
_TYPES = (
    # Signed integers
    'Integer', 'Int8', 'Int16', 'Int32', 'Int64',
    # Unsigned integers
    'UInt8', 'UInt16', 'UInt32', 'UInt64',
    # Floating point
    'Single', 'Double',
    # Basic types
    'Boolean', 'String', 'Variant',
    # Special types
    'Object', 'Color', 'Ptr', 'Auto', 'CString', 'WString',
)

# Literal constants → Token: Keyword.Constant
#   True / False → boolean values
#   Nil          → Xojo's null value (equivalent to null in C# / Nothing in VB)
_LITERALS = ('True', 'False', 'Nil')

# Built-in object references → Token: Name.Builtin
#   Self  → reference to current instance (equivalent to 'this' in Java/C#)
#   Super → call parent class method
#   Me    → legacy name for Self (backward compatible)
_BUILTINS = ('Self', 'Super', 'Me')


# ──────────────────────────────────────────────────────────────────────────────
# XojoLexer — Pygments RegexLexer for the Xojo language
# ──────────────────────────────────────────────────────────────────────────────
class XojoLexer(RegexLexer):
    """
    Pygments lexer for the Xojo programming language.

    Xojo is a BASIC-based language for building Desktop / Web / Mobile applications.
    Supports case-insensitive keyword matching and Xojo-specific syntax:
      - // and ' (apostrophe) line comments
      - Double-quoted strings (no multiline)
      - Decimal, &h hex, &b binary number literals
      - Preprocessor directives: #tag, #pragma, #if, #region, ...
    """

    name = 'Xojo'
    aliases = ['xojo']
    filenames = ['*.xojo_code', '*.xojo_script']

    # re.IGNORECASE → Xojo does not distinguish uppercase/lowercase
    # re.MULTILINE  → makes ^ and $ match at the start/end of each line
    flags = re.IGNORECASE | re.MULTILINE

    tokens = {
        'root': [

            # ─── 1. Preprocessor directives ───────────────────────────────────────
            # Match the entire line starting with #<directive> to end of line.
            # Must be first to prevent words inside directives from being highlighted as keywords.
            # Example: "Module" in "#tag Module, Name = Utils" will not be highlighted as a keyword
            # because the entire line is consumed as a single Comment.Preproc token.
            (
                r'#(?:tag|pragma|if|elseif|else|endif|region|endregion)\b[^\n]*',
                Comment.Preproc,
            ),

            # ─── 2. Line comment: // ──────────────────────────────────────────────
            # Match from // to end of line (excluding newline)
            (r'//[^\n]*', Comment.Single),

            # ─── 3. Apostrophe comment: ' ─────────────────────────────────────────
            # Xojo supports ' as a legacy BASIC-style comment
            # [^\n]* → match all characters to end of line (except newline)
            (r"'[^\n]*", Comment.Single),

            # ─── 4. String literals ───────────────────────────────────────────────
            # Double-quoted string that does not span lines
            # [^"\n]* → prevents a missing " from turning all remaining code into a string
            (r'"[^"\n]*"', String.Double),

            # ─── 5. Hex literals: &hFF, &H00FF ───────────────────────────────────
            # Must come before decimal because & could be consumed as an operator
            (r'&[hH][0-9a-fA-F]+', Number.Hex),

            # ─── 6. Binary literals: &b1010, &B1010 ──────────────────────────────
            (r'&[bB][01]+', Number.Bin),

            # ─── 7. Float literals: 3.14, 1.5e-3 ────────────────────────────────
            # Must come before integer because \d+ would match the first part of a float
            (r'\d+\.\d+(?:[eE][+-]?\d+)?', Number.Float),

            # ─── 8. Integer literals: 42, 1e6 ────────────────────────────────────
            (r'\d+(?:[eE][+-]?\d+)?', Number.Integer),

            # ─── 9. Operator keywords: And, Or, Not, IsA, Is, ... ────────────────
            # Must come before _KEYWORDS because Is/IsA are not in _KEYWORDS
            # IsA comes before Is in the tuple for correct matching (safe with \b anyway)
            (words(_OPERATOR_KEYWORDS, suffix=r'\b'), Operator.Word),

            # ─── 10. Literals: True, False, Nil ──────────────────────────────────
            # Uses Keyword.Constant because these are compile-time constants, not runtime variables
            (words(_LITERALS, suffix=r'\b'), Keyword.Constant),

            # ─── 11. Built-in references: Self, Super, Me ────────────────────────
            (words(_BUILTINS, suffix=r'\b'), Name.Builtin),

            # ─── 12. Types: Integer, String, Double, ... ─────────────────────────
            # Uses Keyword.Type which is the standard token for built-in type names
            (words(_TYPES, suffix=r'\b'), Keyword.Type),

            # ─── 13. Main keywords ────────────────────────────────────────────────
            # words() automatically generates a (?:Var|Dim|Sub|...)\b pattern
            # re.IGNORECASE set in flags enables case-insensitive matching
            (words(_KEYWORDS, suffix=r'\b'), Keyword),

            # ─── 14. Identifiers ─────────────────────────────────────────────────
            # Variable names, class names, method names that are not keywords
            # Must come after all keyword rules
            (r'[a-zA-Z_][a-zA-Z0-9_]*', Name),

            # ─── 15. Symbolic operators ───────────────────────────────────────────
            # Match symbols: =, <>, <=, >=, +, -, *, /, &, <<, >>
            (r'<>|<<|>>|[<>!=+\-*/&|^]=?', Operator),

            # ─── 16. Punctuation ──────────────────────────────────────────────────
            (r'[{}()\[\].,;:]', Punctuation),

            # ─── 17. Whitespace ───────────────────────────────────────────────────
            # Consume spaces and newlines as Whitespace tokens (no special color)
            (r'\s+', Whitespace),
        ]
    }


# ──────────────────────────────────────────────────────────────────────────────
# XojoOneDarkStyle — custom Pygments style inspired by Atom One Dark
#
# Same colors as used in the highlight.js demo (Atom One Dark) and CodeMirror demo (One Dark):
#   keyword   → #c678dd (purple)
#   type      → #56b6c2 (cyan)
#   constant  → #d19a66 (orange)
#   builtin   → #e06c75 (red)
#   comment   → #5c6370 (gray + italic)
#   preproc   → #e5c07b (yellow)
#   string    → #98c379 (green)
#   number    → #d19a66 (orange)
#   operator  → #56b6c2 (cyan, same as type — semantic operators)
# ──────────────────────────────────────────────────────────────────────────────
class XojoOneDarkStyle(Style):
    """
    One Dark color scheme for Xojo — matches the highlight.js Atom One Dark demo.
    Use with XojoLexer for consistent colors across all four library demos.
    """

    name = 'xojo-one-dark'
    background_color = '#282c34'
    highlight_color  = '#2c313a'
    default_style    = '#abb2bf'

    styles = {
        Token:              '#abb2bf',           # default plain text

        # ── Comments ──────────────────────────────────────────────────────────
        Comment:            'italic #5c6370',    # gray + italic
        Comment.Preproc:    '#e5c07b',           # yellow — preprocessor lines

        # ── Keywords ──────────────────────────────────────────────────────────
        Keyword:            '#c678dd',           # purple — Var Sub If Return …
        Keyword.Constant:   '#d19a66',           # orange — True False Nil
        Keyword.Type:       '#56b6c2',           # cyan   — Integer String Double …

        # ── Names ─────────────────────────────────────────────────────────────
        Name:               '#abb2bf',           # plain identifier
        Name.Builtin:       '#e06c75',           # red    — Self Super Me

        # ── Numbers (all subtypes inherit from Number) ────────────────────────
        Number:             '#d19a66',           # orange — 42 3.14 &hFF &b1010

        # ── Operators ─────────────────────────────────────────────────────────
        Operator:           '#abb2bf',           # plain symbolic operators
        Operator.Word:      '#56b6c2',           # cyan   — And Or Not Is IsA …

        # ── Strings (all subtypes inherit from String) ────────────────────────
        String:             '#98c379',           # green

        # ── Punctuation ───────────────────────────────────────────────────────
        Punctuation:        '#abb2bf',
    }


# ──────────────────────────────────────────────────────────────────────────────
# XojoOneLightStyle — custom Pygments style inspired by Atom One Light
#
# Same colors as used in the highlight.js demo (Atom One Light):
#   keyword   → #a626a4 (purple)
#   type      → #0184bb (cyan/blue)
#   constant  → #986801 (orange/brown)
#   builtin   → #e45649 (red)
#   comment   → #a0a1a7 (gray + italic)
#   preproc   → #c18401 (amber)
#   string    → #50a14f (green)
#   number    → #986801 (orange/brown)
#   operator  → #0184bb (cyan, same as type)
# ──────────────────────────────────────────────────────────────────────────────
class XojoOneLightStyle(Style):
    """
    One Light color scheme for Xojo — matches the highlight.js Atom One Light theme.
    Use with XojoLexer for light-mode rendering.
    """

    name = 'xojo-one-light'
    background_color = '#fafafa'
    highlight_color  = '#e5e5e6'
    default_style    = '#383a42'

    styles = {
        Token:              '#383a42',           # default plain text

        # ── Comments ──────────────────────────────────────────────────────────
        Comment:            'italic #a0a1a7',    # gray + italic
        Comment.Preproc:    '#c18401',           # amber — preprocessor lines

        # ── Keywords ──────────────────────────────────────────────────────────
        Keyword:            '#a626a4',           # purple — Var Sub If Return …
        Keyword.Constant:   '#986801',           # orange — True False Nil
        Keyword.Type:       '#0184bb',           # cyan   — Integer String Double …

        # ── Names ─────────────────────────────────────────────────────────────
        Name:               '#383a42',           # plain identifier
        Name.Builtin:       '#e45649',           # red    — Self Super Me

        # ── Numbers (all subtypes inherit from Number) ────────────────────────
        Number:             '#986801',           # orange — 42 3.14 &hFF &b1010

        # ── Operators ─────────────────────────────────────────────────────────
        Operator:           '#383a42',           # plain symbolic operators
        Operator.Word:      '#0184bb',           # cyan   — And Or Not Is IsA …

        # ── Strings (all subtypes inherit from String) ────────────────────────
        String:             '#50a14f',           # green

        # ── Punctuation ───────────────────────────────────────────────────────
        Punctuation:        '#383a42',
    }
