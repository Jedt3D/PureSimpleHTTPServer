"""
Xojo Pygments Lexer — Demo
Run: python pygments/demo/demo.py
Generates demo/output.html with syntax-highlighted Xojo code.
"""

import importlib.util
import os
from pygments import highlight
from pygments.formatters import HtmlFormatter

# ──────────────────────────────────────────────────────────────────────────────
# โหลด XojoLexer จาก xojo.pygments.py
# ──────────────────────────────────────────────────────────────────────────────
_lexer_path = os.path.join(os.path.dirname(__file__), '..', 'xojo.pygments.py')
_spec = importlib.util.spec_from_file_location('xojo_pygments', _lexer_path)
_mod  = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_mod)
XojoLexer = _mod.XojoLexer


# ──────────────────────────────────────────────────────────────────────────────
# Sample Xojo code — ครอบคลุม token types ทั้งหมด
# ──────────────────────────────────────────────────────────────────────────────
SAMPLE_CODE = '''\
#pragma DisableBackgroundTasks
#tag Module, Name = MathUtils

// A sample Xojo module demonstrating various language features

Class Calculator
  Inherits Object

  Private mTotal As Integer

  Sub Constructor()
    mTotal = 0
  End Sub

  Function Add(a As Integer, b As Integer) As Integer
    ' apostrophe-style comment
    Return a + b
  End Function

  Function IsValid(value As Integer) As Boolean
    If value < 0 Or value > &hFFFF Then
      Return False
    End If
    Return True
  End Function

  Function ToHex(value As UInt32) As String
    Var result As String = "&h" + Hex(value)
    Return result
  End Function

  Sub ProcessItems(items() As String)
    For Each item As String In items
      If item = Nil Or item = "" Then
        Continue
      End If
      Var upper As String = item.Uppercase
    Next
  End Sub

  Property Total As Integer
    Get
      Return mTotal
    End Get
    Set(value As Integer)
      If IsA Integer Then
        mTotal = value
      End If
    End Set
  End Property

End Class

#tag EndModule
'''

# ──────────────────────────────────────────────────────────────────────────────
# Generate HTML output
# ──────────────────────────────────────────────────────────────────────────────
formatter = HtmlFormatter(
    style='monokai',
    full=True,
    title='Xojo Syntax Highlight — Pygments Demo',
    linenos=True,
)

highlighted = highlight(SAMPLE_CODE, XojoLexer(), formatter)

out_path = os.path.join(os.path.dirname(__file__), 'output.html')
with open(out_path, 'w', encoding='utf-8') as f:
    f.write(highlighted)

print(f"Generated: {out_path}")
print(f"Open in browser: file://{os.path.abspath(out_path)}")
print()
print("Available Pygments styles:")
from pygments.styles import get_all_styles
print("  " + ", ".join(sorted(get_all_styles())))
print()
print("To use a different style, change `style='monokai'` in demo.py")
