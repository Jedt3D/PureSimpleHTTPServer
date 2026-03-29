/**
 * highlight.js language definition for Xojo
 * https://github.com/worajedt/xojo-syntax-highlight
 *
 * Xojo is a programming language evolved from BASIC, supporting Desktop/Web/Mobile app development.
 * This file defines a grammar for highlight.js to correctly highlight Xojo code.
 *
 * Covers the following patterns:
 *   - Comments: // and ' (apostrophe)
 *   - Double-quoted strings
 *   - Decimal numbers, &h hex, &b binary
 *   - Xojo-specific reserved words such as Var, Nil, Self, Super, #tag
 *
 * Usage:
 *   import xojo from './xojo.highlight.js';
 *   hljs.registerLanguage('xojo', xojo);
 *   hljs.highlightAll();
 */
export default function(hljs) {

  // ────────────────────────────────────────────────────────────────────────────
  // Xojo reserved words (Keywords)
  //
  // highlight.js will automatically match these as "keyword" tokens.
  // Since case_insensitive: true is set, Var, VAR, var all match the same way.
  // ────────────────────────────────────────────────────────────────────────────
  const KEYWORDS = [
    // Variable declaration:
    //   Var → modern form (Xojo 2019+)
    //   Dim → legacy form still supported for backward compatibility
    'Var', 'Dim',

    // Function/method declaration:
    //   Sub      → no return value (void)
    //   Function → has return value
    'Sub', 'Function',

    // OOP structures and modules:
    //   Class     → define a class
    //   Module    → group of functions/constants (no instances)
    //   Interface → define an interface
    //   Enum      → define an enumeration
    'Class', 'Module', 'Interface', 'Enum',

    // Conditional control:
    //   If/Then/Else/ElseIf/End → block-style If
    'If', 'Then', 'Else', 'ElseIf', 'End',

    // Loops:
    //   For/Each/Next  → For-Next and For Each
    //   While/Wend     → While loop
    //   Do/Loop/Until  → Do-Loop with optional Until/While
    'For', 'Each', 'Next', 'While', 'Wend', 'Do', 'Loop', 'Until',

    // Select-Case and flow control:
    //   Select/Case    → equivalent to switch-case
    //   Break/Continue → exit loop / skip to next iteration
    'Select', 'Case', 'Break', 'Continue',

    // Exception handling:
    //   Try/Catch/Finally → error handling block
    //   Raise             → throw an exception
    //   RaiseEvent        → fire an event
    //   Return            → return a value and exit the function
    //   Exit              → exit a loop/sub
    'Try', 'Catch', 'Finally', 'Raise', 'RaiseEvent', 'Return', 'Exit',

    // OOP:
    //   New        → create an instance of a class
    //   Inherits   → specify parent class
    //   Implements → implement an interface
    //   Extends    → extend (used with generic types)
    'New', 'Inherits', 'Implements', 'Extends',

    // Event handler:
    //   AddHandler    → add an event handler at runtime
    //   RemoveHandler → remove an event handler
    'AddHandler', 'RemoveHandler',

    // Access modifiers:
    //   Public/Private/Protected → control visibility
    //   Static                   → local variable that retains value between calls
    //   Shared                   → shared member accessible without creating an instance
    //   Global                   → global variable (used in modules)
    'Public', 'Private', 'Protected', 'Static', 'Shared', 'Global',

    // OOP modifiers:
    //   Override → override a method from parent class
    //   Virtual  → method that subclasses can override
    //   Final    → prevent further overriding
    //   Abstract → method that must be overridden by subclass
    'Override', 'Virtual', 'Final', 'Abstract',

    // Special class members:
    //   Property   → getter/setter property
    //   Event      → define an event
    //   Delegate   → function pointer
    //   ParamArray → variadic array parameter
    //   Optional   → parameter that does not need to be passed
    'Property', 'Event', 'Delegate', 'ParamArray', 'Optional',

    // Parameter declaration keywords:
    //   As    → specify data type, e.g. "Var x As Integer"
    //   ByRef → pass parameter by reference (can modify the original value)
    //   ByVal → pass parameter by copy (default)
    //   Of    → used with generic types, e.g. Dictionary(Of String, Integer)
    'As', 'ByRef', 'ByVal', 'Of',

    // Others
    'Call', 'Using', 'Namespace',
  ];

  // ────────────────────────────────────────────────────────────────────────────
  // Literal constants
  //
  // highlight.js highlights these with "literal" color (different from regular keywords)
  //   True / False → boolean values
  //   Nil          → Xojo's null value (equivalent to null in C# / Nothing in VB)
  // ────────────────────────────────────────────────────────────────────────────
  const LITERALS = ['True', 'False', 'Nil'];

  // ────────────────────────────────────────────────────────────────────────────
  // Built-in data types
  //
  // highlight.js highlights these as "type" tokens
  // ────────────────────────────────────────────────────────────────────────────
  const TYPES = [
    // Signed integers:
    //   Integer = Int32 (32-bit), Int8 = byte, Int64 = long
    'Integer', 'Int8', 'Int16', 'Int32', 'Int64',

    // Unsigned integers:
    'UInt8', 'UInt16', 'UInt32', 'UInt64',

    // Common data types:
    'Single',    // single-precision floating point (32-bit float)
    'Double',    // double-precision floating point (64-bit float)
    'Boolean',   // True/False value
    'String',    // Unicode text
    'Variant',   // flexible data type (can hold any type)

    // Xojo-specific special types:
    'Object',    // generic object reference
    'Color',     // color (ARGB)
    'Ptr',       // raw pointer
    'Auto',      // automatically inferred type
    'CString',   // null-terminated C string for C API interop
    'WString',   // null-terminated wide string
  ];

  // ────────────────────────────────────────────────────────────────────────────
  // Keyword-style operators (Operator keywords)
  //
  // These words function as operators but are written as English words.
  // highlight.js does not have an "operator" category in the keywords object,
  // so they are included in the keyword array and share the same CSS class.
  // ────────────────────────────────────────────────────────────────────────────
  const OPERATORS = [
    'And', 'Or', 'Not', 'Xor',          // logical operators
    'Mod',                               // modulo (remainder division)
    'In',                                // membership check (used in For Each)
    'Is', 'IsA', 'Isa',                  // nil check / type check
    'AddressOf', 'WeakAddressOf',        // get pointer to method (for delegates/handlers)
  ];

  // ────────────────────────────────────────────────────────────────────────────
  // Built-in object references
  //
  // References to current object or parent class:
  //   Self  → equivalent to 'this' in Java/C#
  //   Super → call parent class method (equivalent to 'super' in Java)
  //   Me    → legacy name for Self before Xojo renamed it
  // ────────────────────────────────────────────────────────────────────────────
  const BUILTINS = ['Self', 'Super', 'Me'];

  // ────────────────────────────────────────────────────────────────────────────
  // Language definition object — returned from the factory function
  // highlight.js uses this object to highlight code each time
  // ────────────────────────────────────────────────────────────────────────────
  return {
    name: 'Xojo',
    aliases: ['xojo'],       // name used in code fences: ```xojo
    case_insensitive: true,  // Xojo does not distinguish uppercase/lowercase

    // ─── keywords object ──────────────────────────────────────────────────────
    // Each key maps to a different CSS class:
    //   keyword  → .hljs-keyword
    //   literal  → .hljs-literal
    //   type     → .hljs-type
    //   built_in → .hljs-built_in
    //
    // highlight.js performs keyword matching automatically (whole-word, case-insensitive)
    // No need to write regex manually
    // ─────────────────────────────────────────────────────────────────────────
    keywords: {
      keyword: [...KEYWORDS, ...OPERATORS],  // include operator-keywords together
      literal: LITERALS,
      type: TYPES,
      built_in: BUILTINS,
    },

    // ─── contains array ───────────────────────────────────────────────────────
    // List of "modes" that highlight.js will try to match in order.
    // Earlier modes have higher priority — order matters!
    //
    // Example: comment comes before string
    //   // "this is a comment" → // is matched as comment first
    //   " // not a comment"  → " is matched as string first
    // ─────────────────────────────────────────────────────────────────────────
    contains: [
      // ─── 1. Line comment: // ─────────────────────────────────────────────
      // hljs.COMMENT(begin, end) is a helper that creates a comment mode
      // '$' in end means end-of-line (highlight.js adds the m flag automatically)
      // → Result: text from // to end of line gets class "hljs-comment"
      hljs.COMMENT('//', '$'),

      // ─── 2. Line comment: ' (apostrophe) ─────────────────────────────────
      // Xojo supports ' as a legacy BASIC-style comment
      // Works the same way: ' highlights to end of line
      hljs.COMMENT("'", '$'),

      // ─── 3. String (quoted text) ──────────────────────────────────────────
      // begin: '"' starts matching when " is found
      // end: '"'   ends matching when closing " is found
      // illegal: '\\n' → if highlight.js finds a newline before closing ", it cancels the match
      //   because Xojo does not support multiline strings
      //   prevents a missing " from turning all remaining code into a string
      {
        scope: 'string',
        begin: '"',
        end: '"',
        illegal: '\\n',
      },

      // ─── 4. Number literals ────────────────────────────────────────────────
      // Match pattern supports 3 Xojo formats:
      //
      //   &[hH][0-9a-fA-F]+\b  → hex literal e.g. &hFF00FF, &HFFFFFF
      //   &[bB][01]+\b          → binary literal e.g. &b10101010
      //   \b\d+(?:\.\d+)?(?:[eE][+-]?\d+)?\b → decimal e.g. 42, 3.14, 1e6
      //
      // Order matters: &h must come first; otherwise & could be seen as an operator
      // relevance: 0 → do not count this match for language auto-detection
      {
        scope: 'number',
        match: /&[hH][0-9a-fA-F]+\b|&[bB][01]+\b|\b\d+(?:\.\d+)?(?:[eE][+-]?\d+)?\b/,
        relevance: 0,
      },

      // ─── 5. Preprocessor directives (#tag, #pragma, #if ...) ────────────────
      // Match only the #<directive> token, ending at \b (word boundary)
      // The /i flag → case-insensitive (#TAG, #Pragma also match)
      //
      // Note: this pattern matches only "#tag", not the entire line.
      // Therefore "Module" in "#tag Module, Name = Utils" will still be highlighted as a keyword
      // (unlike Prism.js and CodeMirror which consume the entire line as a meta token)
      {
        scope: 'meta',
        match: /#(tag|pragma|if|else|elseif|endif|region|endregion)\b/i,
      },
    ],
  };
}
