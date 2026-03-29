/**
 * Prism.js language definition for Xojo
 * https://github.com/worajedt/xojo-syntax-highlight
 *
 * Xojo is a programming language evolved from BASIC, supporting Desktop/Web/Mobile app development.
 * This file defines a grammar for Prism.js to correctly highlight Xojo code.
 *
 * Covers the following patterns:
 *   - Comments: // and ' (apostrophe)
 *   - Double-quoted strings
 *   - Decimal numbers, &h hex, &b binary
 *   - Xojo-specific reserved words such as Var, Nil, Self, Super, #tag
 *
 * Usage:
 *   Load this file after prism.js, then use language 'xojo' in code blocks
 *   <pre><code class="language-xojo">...</code></pre>
 *
 * How Prism.js works:
 *   Prism matches patterns in the order defined in the object below.
 *   Earlier patterns have higher priority (first match wins).
 *   greedy: true prevents Prism from re-tokenizing already matched text.
 */
(function (Prism) {
  Prism.languages['xojo'] = {

    // ────────────────────────────────────────────────────────────────────────────
    // 1. Comments — must always come first
    //
    // Must come before string and keyword to prevent:
    //   - Keywords in comments being highlighted (e.g. // Return this value)
    //   - Strings in comments being matched as string tokens
    //
    // greedy: true → once matched, Prism will not try to match other patterns inside
    // ────────────────────────────────────────────────────────────────────────────
    'comment': [
      // // line comment — match from // to end of line
      { pattern: /\/\/.*/, greedy: true },

      // ' apostrophe comment — Xojo supports ' as a legacy BASIC-style comment
      // Uses [^\r\n]* instead of .* because Prism 1.29+ does not support flags option on pattern objects
      // (using /.*/m or flags: 'm' will be silently ignored)
      { pattern: /'[^\r\n]*/, greedy: true },
    ],

    // ────────────────────────────────────────────────────────────────────────────
    // 2. String (quoted text)
    //
    // Match "..." without spanning lines ([^"\n]*)
    // Xojo does not support multiline strings — if an opening " has no closing " on the same line
    // the pattern will stop at end of line
    //
    // greedy: true prevents Prism from matching keywords/numbers inside the string
    // ────────────────────────────────────────────────────────────────────────────
    'string': {
      pattern: /"[^"\n]*"/,
      greedy: true,
    },

    // ────────────────────────────────────────────────────────────────────────────
    // 3. Preprocessor directives (#tag, #pragma, #if, ...)
    //
    // Match the entire line starting with # followed by a known directive to end of line
    // Pattern: /#(?:tag|pragma|if|elseif|else|endif|region|endregion)\b[^\r\n]*/i
    //
    // greedy: true → critical! Prevents Prism from matching other patterns inside
    //   the preprocessor line, e.g. "Module" in "#tag Module, Name = Utils"
    //   will not be highlighted as a keyword because the entire line is a single token
    //
    // alias: 'meta' → makes Prism use CSS class .token.meta for special coloring
    //   You need to add a CSS rule .token.meta { color: ... } since Prism themes don't include it
    //
    // inside → defines sub-patterns within the already matched token
    //   Enables additional highlighting within the context of the preprocessor token
    // ────────────────────────────────────────────────────────────────────────────
    'preprocessor': {
      pattern: /#(?:tag|pragma|if|elseif|else|endif|region|endregion)\b[^\r\n]*/i,
      greedy: true,
      alias: 'meta',
      inside: {
        // ─── Sub-highlight: directive keyword ─────────────────────────────────
        // After matching the entire line as preprocessor,
        // inside additionally highlights just the #directive portion with keyword color
        //
        // /^#\w+/ matches from start of token (^) to end of word
        // alias: 'keyword' → uses the same color as keywords (brighter than meta color)
        // ─────────────────────────────────────────────────────────────────────
        'directive': {
          pattern: /^#\w+/,
          alias: 'keyword',
        },
      },
    },

    // ────────────────────────────────────────────────────────────────────────────
    // 4. Keywords — Xojo reserved words
    //
    // \b...\b is a word boundary ensuring only standalone words match
    // e.g. "Integer" will match but "MyInteger" will not
    // The /i flag enables case-insensitive matching
    // ────────────────────────────────────────────────────────────────────────────
    'keyword': {
      pattern: /\b(?:Var|Dim|Sub|Function|Class|Module|Interface|Enum|If|Then|Else|ElseIf|End|For|Each|Next|While|Wend|Do|Loop|Until|Select|Case|Break|Continue|Try|Catch|Finally|Raise|RaiseEvent|Return|Exit|New|Inherits|Implements|Extends|AddHandler|RemoveHandler|Public|Private|Protected|Static|Shared|Global|Override|Virtual|Final|Abstract|Property|Event|Delegate|ParamArray|Optional|As|ByRef|ByVal|Of|Call|Using|Namespace)\b/i,
    },

    // ────────────────────────────────────────────────────────────────────────────
    // 5. Operator keywords — word-based operators
    //
    // And, Or, Not, Xor → logical operators
    // Mod               → modulo (remainder division)
    // In                → membership check (used in For Each)
    // Is, IsA, Isa      → type/nil checking
    // AddressOf         → get pointer to method
    //
    // alias: 'operator' → Prism uses CSS class .token.operator
    //   giving it a different color from regular keywords in some themes
    // ────────────────────────────────────────────────────────────────────────────
    'operator-keyword': {
      pattern: /\b(?:And|Or|Not|Xor|Mod|In|Is|IsA|Isa|AddressOf|WeakAddressOf)\b/i,
      alias: 'operator',
    },

    // ────────────────────────────────────────────────────────────────────────────
    // 6. Built-in references — references to the current object
    //
    //   Self  → equivalent to 'this' in Java/C# — reference to current instance
    //   Super → call parent class method
    //   Me    → legacy name for Self (still supported for backward compatibility)
    //
    // alias: 'keyword' → uses the same color as regular keywords
    // ────────────────────────────────────────────────────────────────────────────
    'builtin': {
      pattern: /\b(?:Self|Super|Me)\b/i,
      alias: 'keyword',
    },

    // ────────────────────────────────────────────────────────────────────────────
    // 7. Boolean literals — boolean constant values
    //
    //   True / False → standard boolean values
    //   Nil          → Xojo's null value (equivalent to null in C#)
    // ────────────────────────────────────────────────────────────────────────────
    'boolean': {
      pattern: /\b(?:True|False|Nil)\b/i,
    },

    // ────────────────────────────────────────────────────────────────────────────
    // 8. Data types
    //
    // Covers all Xojo built-in types:
    //   Integer, Int8-Int64 → signed integers
    //   UInt8-UInt64        → unsigned integers
    //   Single, Double      → 32/64-bit floating point
    //   Boolean, String     → basic types
    //   Variant             → flexible data type
    //   Object, Color, Ptr  → special types
    //   CString, WString    → strings for C API interop
    //
    // alias: 'class-name' → Prism themes usually have a color for .token.class-name (e.g. cyan)
    //   more suitable for type names than .token.type which isn't in all themes
    // ────────────────────────────────────────────────────────────────────────────
    'type': {
      pattern: /\b(?:Integer|Int8|Int16|Int32|Int64|UInt8|UInt16|UInt32|UInt64|Single|Double|Boolean|String|Variant|Object|Color|Ptr|Auto|CString|WString)\b/i,
      alias: 'class-name',
    },

    // ────────────────────────────────────────────────────────────────────────────
    // 9. Number literals
    //
    // Supports all Xojo formats:
    //   &hFF00FF   → hex literal (prefixed with &h or &H)
    //   &b10101010 → binary literal (prefixed with &b or &B)
    //   42         → integer
    //   3.14       → decimal float
    //   1e6        → scientific notation
    //
    // Important: &h and &b must come first in the alternation (|)
    //   because & could be matched as an operator if Prism processes character by character
    // ────────────────────────────────────────────────────────────────────────────
    'number': {
      pattern: /&[hH][0-9a-fA-F]+\b|&[bB][01]+\b|\b\d+(?:\.\d+)?(?:[eE][+-]?\d+)?\b/,
    },

    // ────────────────────────────────────────────────────────────────────────────
    // 10. Symbolic operators
    //
    // Match symbols: <, >, !, +, -, *, /, &, |, ^, =
    // Including compound: <=, >=, <>, <<, >>
    // ────────────────────────────────────────────────────────────────────────────
    'operator': /[<>!=+\-*\/&|^]=?|[<>]{2}/,

    // ────────────────────────────────────────────────────────────────────────────
    // 11. Punctuation
    //
    // { } ( ) [ ] . , ; : — not highlighted with a special color but must be matched
    // so Prism processes these tokens correctly and they don't remain as plain text
    // ────────────────────────────────────────────────────────────────────────────
    'punctuation': /[{}()\[\].,;:]/,
  };
}(Prism));
