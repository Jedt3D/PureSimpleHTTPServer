"""
Python test for xojo.pygments.py grammar
Run: python pygments/test.py

ทดสอบ token type ที่ได้จาก XojoLexer โดยตรวจ token แรก (หรือทั้งหมด)
ของแต่ละบรรทัด — เลียนแบบรูปแบบเดียวกับ codemirror/test.mjs
"""

import importlib.util
import os
import sys

# ──────────────────────────────────────────────────────────────────────────────
# โหลด XojoLexer จากไฟล์ xojo.pygments.py (dot ในชื่อไฟล์ทำให้ import ปกติไม่ได้)
# ──────────────────────────────────────────────────────────────────────────────
_lexer_path = os.path.join(os.path.dirname(__file__), 'xojo.pygments.py')
_spec = importlib.util.spec_from_file_location('xojo_pygments', _lexer_path)
_mod  = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_mod)
XojoLexer = _mod.XojoLexer

from pygments.token import (
    Comment, Keyword, Name, Number, Operator,
    Punctuation, String, Whitespace,
)


def tokenize(code: str):
    """
    Tokenize a single line of Xojo code.
    Returns list of (tokentype, value) — ไม่รวม Whitespace
    """
    lexer = XojoLexer()
    result = []
    for _, ttype, value in lexer.get_tokens_unprocessed(code):
        if ttype in (Whitespace,):
            continue
        result.append((ttype, value))
    return result


# ──────────────────────────────────────────────────────────────────────────────
# ชุดทดสอบ — แต่ละ entry เป็น dict ที่มี:
#   line  → บรรทัด Xojo code ที่จะทดสอบ
#   first → token type ที่คาดหวังสำหรับ token แรก (ไม่รวม whitespace)
#   label → คำอธิบายสำหรับ output
#   check → (optional) ฟังก์ชัน custom แทน first
# ──────────────────────────────────────────────────────────────────────────────
tests = [
    # ─── Comments ───────────────────────────────────────────────────────────
    {'line': '// hello world',         'first': Comment.Single,   'label': '// comment'},
    {'line': "' apostrophe comment",   'first': Comment.Single,   'label': "' comment"},

    # ─── Preprocessor ───────────────────────────────────────────────────────
    # ทั้งบรรทัดต้องเป็น Comment.Preproc — "Module" ใน #tag ต้องไม่เป็น Keyword
    {'line': '#pragma DisableBackgroundTasks', 'first': Comment.Preproc, 'label': '#pragma → Comment.Preproc'},
    {'line': '#tag Module, Name = Utils',      'first': Comment.Preproc, 'label': '#tag → Comment.Preproc'},
    {'line': '#if TargetMacOS',               'first': Comment.Preproc, 'label': '#if → Comment.Preproc'},
    {'line': '#region Helper Methods',         'first': Comment.Preproc, 'label': '#region → Comment.Preproc'},

    # ─── Strings ────────────────────────────────────────────────────────────
    {'line': '"Hello, World!"',        'first': String.Double,    'label': 'double-quoted string'},

    # ─── Numbers ────────────────────────────────────────────────────────────
    {'line': '&hFF00FF',               'first': Number.Hex,       'label': '&h hex literal'},
    {'line': '&HFF',                   'first': Number.Hex,       'label': '&H hex (uppercase)'},
    {'line': '&b10101010',             'first': Number.Bin,       'label': '&b binary literal'},
    {'line': '&B1010',                 'first': Number.Bin,       'label': '&B binary (uppercase)'},
    {'line': '3.14159',                'first': Number.Float,     'label': 'decimal float'},
    {'line': '1.5e-3',                 'first': Number.Float,     'label': 'scientific float'},
    {'line': '42',                     'first': Number.Integer,   'label': 'integer'},
    {'line': '1e6',                    'first': Number.Integer,   'label': 'scientific integer'},

    # ─── Keywords (case-insensitive) ────────────────────────────────────────
    {'line': 'Var',      'first': Keyword, 'label': 'Var keyword'},
    {'line': 'var',      'first': Keyword, 'label': 'var (lowercase)'},
    {'line': 'VAR',      'first': Keyword, 'label': 'VAR (uppercase)'},
    {'line': 'Sub',      'first': Keyword, 'label': 'Sub'},
    {'line': 'Function', 'first': Keyword, 'label': 'Function'},
    {'line': 'If',       'first': Keyword, 'label': 'If'},
    {'line': 'Return',   'first': Keyword, 'label': 'Return'},
    {'line': 'Class',    'first': Keyword, 'label': 'Class'},
    {'line': 'Module',   'first': Keyword, 'label': 'Module'},

    # ─── Operator keywords ───────────────────────────────────────────────────
    {'line': 'And',          'first': Operator.Word, 'label': 'And'},
    {'line': 'Or',           'first': Operator.Word, 'label': 'Or'},
    {'line': 'Not',          'first': Operator.Word, 'label': 'Not'},
    {'line': 'IsA',          'first': Operator.Word, 'label': 'IsA'},
    {'line': 'Is',           'first': Operator.Word, 'label': 'Is'},
    {'line': 'AddressOf',    'first': Operator.Word, 'label': 'AddressOf'},

    # ─── Types ──────────────────────────────────────────────────────────────
    {'line': 'Integer', 'first': Keyword.Type, 'label': 'Integer type'},
    {'line': 'String',  'first': Keyword.Type, 'label': 'String type'},
    {'line': 'Double',  'first': Keyword.Type, 'label': 'Double type'},
    {'line': 'Boolean', 'first': Keyword.Type, 'label': 'Boolean type'},
    {'line': 'UInt64',  'first': Keyword.Type, 'label': 'UInt64 type'},

    # ─── Literals ───────────────────────────────────────────────────────────
    {'line': 'True',  'first': Keyword.Constant, 'label': 'True literal'},
    {'line': 'False', 'first': Keyword.Constant, 'label': 'False literal'},
    {'line': 'Nil',   'first': Keyword.Constant, 'label': 'Nil literal'},

    # ─── Builtins ───────────────────────────────────────────────────────────
    {'line': 'Self',  'first': Name.Builtin, 'label': 'Self'},
    {'line': 'Super', 'first': Name.Builtin, 'label': 'Super'},
    {'line': 'Me',    'first': Name.Builtin, 'label': 'Me'},

    # ─── Identifiers (must NOT be keywords) ─────────────────────────────────
    {'line': 'myVariable',  'first': Name, 'label': 'plain identifier'},
    {'line': 'MyClass',     'first': Name, 'label': 'class-like identifier'},
    {'line': 'VariantX',    'first': Name, 'label': 'VariantX not a type (no word boundary)'},
    {'line': 'IsMissing',   'first': Name, 'label': 'IsMissing not Is+keyword'},

    # ─── Edge: #tag line — "Module" must NOT produce a Keyword token ─────────
    {
        'line': '#tag Module, Name = Utils',
        'label': '#tag line has NO Keyword tokens for Module',
        'check': lambda tokens: not any(t == Keyword for t, _ in tokens),
    },

    # ─── Edge: keyword in comment must NOT be highlighted as keyword ─────────
    {
        'line': '// Return value',
        'label': '// comment: Return inside is still Comment.Single',
        'check': lambda tokens: len(tokens) == 1 and tokens[0][0] == Comment.Single,
    },

    # ─── Edge: keyword in string must NOT be highlighted ────────────────────
    {
        'line': '"If True Then"',
        'label': 'string: keywords inside remain String.Double',
        'check': lambda tokens: len(tokens) == 1 and tokens[0][0] == String.Double,
    },
]


# ──────────────────────────────────────────────────────────────────────────────
# Run tests
# ──────────────────────────────────────────────────────────────────────────────
passed = 0
failed = 0

for t in tests:
    tokens = tokenize(t['line'])
    if 'check' in t:
        ok = t['check'](tokens)
    else:
        ok = bool(tokens) and tokens[0][0] == t['first']

    if ok:
        print(f"  \u2713  {t['label']}")
        passed += 1
    else:
        got = ' '.join(f'{str(ttype)}:{repr(val)}' for ttype, val in tokens)
        print(f"  \u2717  {t['label']}")
        expected = t.get('first', '(custom check)')
        print(f"       expected: {expected}")
        print(f"       got:      [{got}]")
        failed += 1

print(f"\n{passed} passed, {failed} failed")
if failed:
    sys.exit(1)
