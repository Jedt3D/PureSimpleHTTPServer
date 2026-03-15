"""
Pygments lexer for Xojo
https://github.com/worajedt/xojo-syntax-highlight

Xojo เป็นภาษาโปรแกรมที่พัฒนาต่อมาจาก BASIC รองรับการสร้างแอป Desktop/Web/Mobile
ไฟล์นี้กำหนด lexer สำหรับ Pygments เพื่อ highlight code Xojo ได้ถูกต้อง

ครอบคลุมรูปแบบต่อไปนี้:
  - ความคิดเห็น // และ ' (apostrophe)
  - String ในเครื่องหมายคำพูดคู่
  - ตัวเลขแบบทศนิยม, &h hex, &b binary
  - คำสงวน Xojo เฉพาะ เช่น Var, Nil, Self, Super, #tag
  - Case-insensitive (Xojo ไม่แยก uppercase/lowercase)

วิธีใช้:
  from pygments import highlight
  from pygments.formatters import HtmlFormatter
  # Load lexer manually (ไม่ได้ install เป็น package)
  import importlib.util, os
  spec = importlib.util.spec_from_file_location("xojo_pygments", "xojo.pygments.py")
  mod  = importlib.util.module_from_spec(spec)
  spec.loader.exec_module(mod)

  html = highlight(code, mod.XojoLexer(), HtmlFormatter())

วิธีใช้ผ่าน command line (ไม่ต้อง install):
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
# Keyword lists — กำหนดที่ module level เพราะ Python ไม่อนุญาตให้อ้างอิง
# class attribute ภายในนิยาม class attribute ตัวอื่น (class scope ไม่ propagate)
# ──────────────────────────────────────────────────────────────────────────────

# คำสงวนหลัก → Token: Keyword
_KEYWORDS = (
    # การประกาศตัวแปร
    #   Var → รูปแบบใหม่ (Xojo 2019+)   Dim → รูปแบบเก่า (backward compatible)
    'Var', 'Dim',

    # การประกาศฟังก์ชัน/เมธอด
    #   Sub → ไม่มีค่าคืนกลับ (void)   Function → มีค่าคืนกลับ
    'Sub', 'Function',

    # โครงสร้าง OOP และโมดูล
    'Class', 'Module', 'Interface', 'Enum',

    # การควบคุมเงื่อนไข (Conditional)
    'If', 'Then', 'Else', 'ElseIf', 'End',

    # ลูป (Loops)
    'For', 'Each', 'Next', 'While', 'Wend', 'Do', 'Loop', 'Until',

    # Select-Case และการควบคุม flow
    'Select', 'Case', 'Break', 'Continue',

    # Exception handling
    'Try', 'Catch', 'Finally', 'Raise', 'RaiseEvent', 'Return', 'Exit',

    # OOP — สร้าง instance และ inheritance
    'New', 'Inherits', 'Implements', 'Extends',

    # Event handler management
    'AddHandler', 'RemoveHandler',

    # ระดับการเข้าถึง (Access modifiers)
    #   Static → local var ที่ยังมีค่าระหว่าง call (ต่างจาก Shared)
    #   Shared → member ใช้ได้โดยไม่ต้องสร้าง instance
    'Public', 'Private', 'Protected', 'Static', 'Shared', 'Global',

    # OOP modifiers
    'Override', 'Virtual', 'Final', 'Abstract',

    # สมาชิกพิเศษของ class
    #   Delegate   → function pointer สำหรับ callback
    #   ParamArray → พารามิเตอร์แบบ variadic (array)
    #   Optional   → พารามิเตอร์ที่ไม่จำเป็นต้องส่ง
    'Property', 'Event', 'Delegate', 'ParamArray', 'Optional',

    # Keyword ในการประกาศพารามิเตอร์และชนิดข้อมูล
    #   As    → กำหนดชนิด เช่น "Var x As Integer"
    #   ByRef → ส่งแบบ reference (แก้ไขค่าต้นทางได้)
    #   ByVal → ส่งแบบ copy (default)
    #   Of    → ใช้กับ generic เช่น Dictionary(Of String, Integer)
    'As', 'ByRef', 'ByVal', 'Of',

    # อื่นๆ
    'Call', 'Using', 'Namespace',
)

# ตัวดำเนินการแบบ keyword → Token: Operator.Word
# แยกออกจาก _KEYWORDS เพื่อให้ theme ใช้สีต่างกันได้
_OPERATOR_KEYWORDS = (
    'And', 'Or', 'Not', 'Xor',         # logical operators
    'Mod',                               # modulo (หารเอาเศษ)
    'In',                                # membership check (ใช้ใน For Each)
    'IsA',                               # type check (ครอบคลุม Isa ด้วย case-insensitive)
    'Is',                                # nil check — ต้องอยู่หลัง IsA ใน alternation
    'AddressOf', 'WeakAddressOf',        # ได้ pointer ไปยัง method (สำหรับ delegate)
)

# ชนิดข้อมูลพื้นฐาน → Token: Keyword.Type
_TYPES = (
    # จำนวนเต็มมีเครื่องหมาย (Signed integers)
    'Integer', 'Int8', 'Int16', 'Int32', 'Int64',
    # จำนวนเต็มไม่มีเครื่องหมาย (Unsigned integers)
    'UInt8', 'UInt16', 'UInt32', 'UInt64',
    # ทศนิยม
    'Single', 'Double',
    # ชนิดพื้นฐาน
    'Boolean', 'String', 'Variant',
    # ชนิดพิเศษ
    'Object', 'Color', 'Ptr', 'Auto', 'CString', 'WString',
)

# ค่าคงที่ literal → Token: Keyword.Constant
#   True / False → ค่า boolean
#   Nil          → ค่า null ของ Xojo (เทียบเท่า null ใน C# / Nothing ใน VB)
_LITERALS = ('True', 'False', 'Nil')

# Built-in object references → Token: Name.Builtin
#   Self  → อ้างอิง instance ปัจจุบัน (เทียบเท่า 'this' ใน Java/C#)
#   Super → เรียก method ของ parent class
#   Me    → ชื่อเก่าของ Self (backward compatible)
_BUILTINS = ('Self', 'Super', 'Me')


# ──────────────────────────────────────────────────────────────────────────────
# XojoLexer — Pygments RegexLexer สำหรับภาษา Xojo
# ──────────────────────────────────────────────────────────────────────────────
class XojoLexer(RegexLexer):
    """
    Pygments lexer for the Xojo programming language.

    Xojo เป็นภาษา BASIC-based สำหรับสร้างแอปพลิเคชัน Desktop / Web / Mobile
    รองรับ case-insensitive keyword matching และ Xojo-specific syntax:
      - // และ ' (apostrophe) line comments
      - Double-quoted strings (no multiline)
      - Decimal, &h hex, &b binary number literals
      - Preprocessor directives: #tag, #pragma, #if, #region, ...
    """

    name = 'Xojo'
    aliases = ['xojo']
    filenames = ['*.xojo_code', '*.xojo_script']

    # re.IGNORECASE → Xojo ไม่แยก uppercase/lowercase
    # re.MULTILINE  → ให้ ^ และ $ match ที่ต้น/ท้ายแต่ละบรรทัด
    flags = re.IGNORECASE | re.MULTILINE

    tokens = {
        'root': [

            # ─── 1. Preprocessor directives ───────────────────────────────────────
            # match ทั้งบรรทัดที่ขึ้นต้นด้วย #<directive> จนถึงสุดบรรทัด
            # ต้องอยู่อันดับแรกสุด เพื่อป้องกันคำใน directive ถูก highlight เป็น keyword
            # ตัวอย่าง: "Module" ใน "#tag Module, Name = Utils" จะไม่ถูก highlight เป็น keyword
            # เพราะทั้งบรรทัดถูก consume เป็น Comment.Preproc token เดียว
            (
                r'#(?:tag|pragma|if|elseif|else|endif|region|endregion)\b[^\n]*',
                Comment.Preproc,
            ),

            # ─── 2. Line comment: // ──────────────────────────────────────────────
            # match ตั้งแต่ // จนสุดบรรทัด (ไม่รวม newline)
            (r'//[^\n]*', Comment.Single),

            # ─── 3. Apostrophe comment: ' ─────────────────────────────────────────
            # Xojo รองรับ ' เป็น comment แบบ BASIC ดั้งเดิม
            # [^\n]* → match ทุกตัวอักษรจนสุดบรรทัด (ยกเว้น newline)
            (r"'[^\n]*", Comment.Single),

            # ─── 4. String literals ───────────────────────────────────────────────
            # Double-quoted string ที่ไม่ข้ามบรรทัด
            # [^"\n]* → ป้องกัน " ที่หายไปทำให้ code ทั้งหมดกลายเป็น string
            (r'"[^"\n]*"', String.Double),

            # ─── 5. Hex literals: &hFF, &H00FF ───────────────────────────────────
            # ต้องอยู่ก่อน decimal เพราะ & อาจถูก consume เป็น operator
            (r'&[hH][0-9a-fA-F]+', Number.Hex),

            # ─── 6. Binary literals: &b1010, &B1010 ──────────────────────────────
            (r'&[bB][01]+', Number.Bin),

            # ─── 7. Float literals: 3.14, 1.5e-3 ────────────────────────────────
            # ต้องอยู่ก่อน integer เพราะ \d+ จะ match ส่วนแรกของ float ได้
            (r'\d+\.\d+(?:[eE][+-]?\d+)?', Number.Float),

            # ─── 8. Integer literals: 42, 1e6 ────────────────────────────────────
            (r'\d+(?:[eE][+-]?\d+)?', Number.Integer),

            # ─── 9. Operator keywords: And, Or, Not, IsA, Is, ... ────────────────
            # ต้องอยู่ก่อน _KEYWORDS เพราะ Is/IsA ไม่อยู่ใน _KEYWORDS
            # IsA อยู่ก่อน Is ใน tuple เพื่อให้ match ถูกต้องก่อน (ผ่าน \b ก็ปลอดภัยอยู่แล้ว)
            (words(_OPERATOR_KEYWORDS, suffix=r'\b'), Operator.Word),

            # ─── 10. Literals: True, False, Nil ──────────────────────────────────
            # ใช้ Keyword.Constant เพราะเป็น compile-time constant ไม่ใช่ runtime variable
            (words(_LITERALS, suffix=r'\b'), Keyword.Constant),

            # ─── 11. Built-in references: Self, Super, Me ────────────────────────
            (words(_BUILTINS, suffix=r'\b'), Name.Builtin),

            # ─── 12. Types: Integer, String, Double, ... ─────────────────────────
            # ใช้ Keyword.Type ซึ่งเป็น standard token สำหรับ built-in type names
            (words(_TYPES, suffix=r'\b'), Keyword.Type),

            # ─── 13. Main keywords ────────────────────────────────────────────────
            # words() สร้าง pattern (?:Var|Dim|Sub|...)\b โดยอัตโนมัติ
            # re.IGNORECASE ที่ตั้งไว้ใน flags ทำให้ match แบบ case-insensitive
            (words(_KEYWORDS, suffix=r'\b'), Keyword),

            # ─── 14. Identifiers ─────────────────────────────────────────────────
            # ชื่อตัวแปร, ชื่อ class, ชื่อ method ที่ไม่ใช่ keyword
            # ต้องอยู่หลัง keyword rules ทั้งหมด
            (r'[a-zA-Z_][a-zA-Z0-9_]*', Name),

            # ─── 15. Symbolic operators ───────────────────────────────────────────
            # match สัญลักษณ์: =, <>, <=, >=, +, -, *, /, &, <<, >>
            (r'<>|<<|>>|[<>!=+\-*/&|^]=?', Operator),

            # ─── 16. Punctuation ──────────────────────────────────────────────────
            (r'[{}()\[\].,;:]', Punctuation),

            # ─── 17. Whitespace ───────────────────────────────────────────────────
            # consume ช่องว่างและ newline เป็น Whitespace token (ไม่มีสีพิเศษ)
            (r'\s+', Whitespace),
        ]
    }


# ──────────────────────────────────────────────────────────────────────────────
# XojoOneDarkStyle — custom Pygments style เลียนแบบ Atom One Dark
#
# สีเดียวกับที่ใช้ใน highlight.js demo (Atom One Dark) และ CodeMirror demo (One Dark):
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
# XojoOneLightStyle — custom Pygments style เลียนแบบ Atom One Light
#
# สีเดียวกับที่ใช้ใน highlight.js demo (Atom One Light):
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
