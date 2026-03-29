/**
 * CodeMirror 6 StreamParser for Xojo
 * https://github.com/worajedt/xojo-syntax-highlight
 *
 * Xojo is a programming language evolved from BASIC, supporting Desktop/Web/Mobile app development.
 * This file exports `xojoStreamParser` for use with CodeMirror 6.
 *
 * No external dependencies — does not import from @codemirror/language or any other package.
 * Users must wrap with StreamLanguage.define() from @codemirror/language:
 *
 *   import { StreamLanguage } from "@codemirror/language"
 *   import { xojoStreamParser } from "./xojo.codemirror.js"
 *   const xojoLang = StreamLanguage.define(xojoStreamParser)
 *
 * How it works:
 *   CodeMirror 6 calls token(stream, state) repeatedly until end of line.
 *   Each call, stream points to the current unprocessed position.
 *   token() reads and consumes characters, then returns a token type or null.
 *
 * Token types used → mapping to Lezer highlight tags:
 *   'keyword'  → tags.keyword         (purple in One Dark)
 *   'operator' → tags.operator        (blue)
 *   'atom'     → tags.atom            (orange)
 *   'type'     → tags.typeName        (light blue)
 *   'builtin'  → tags.standard(name)  (red)
 *   'comment'  → tags.lineComment     (gray)
 *   'string'   → tags.string          (green)
 *   'number'   → tags.number          (orange)
 *   'meta'     → tags.meta            (yellow)
 *   null       → no color (plain text)
 */

// ────────────────────────────────────────────────────────────────────────────
// Keyword sets — uses Set for O(1) lookup
//
// All entries are lowercase because Xojo is case-insensitive.
// When matching identifiers, they are converted to lowercase before lookup.
// ────────────────────────────────────────────────────────────────────────────

// Main reserved words — will receive token type 'keyword'
const KEYWORDS = new Set([
  // Variable declaration
  //   var → modern form (Xojo 2019+)   dim → legacy form (backward compatible)
  'var', 'dim',

  // Functions and methods:
  //   sub      → no return value (void)
  //   function → has return value
  'sub', 'function',

  // OOP structures and modules
  'class', 'module', 'interface', 'enum',

  // Conditional control (If/Then/Else/ElseIf/End If)
  'if', 'then', 'else', 'elseif', 'end',

  // Loops (For-Next, While-Wend, Do-Loop-Until)
  'for', 'each', 'next', 'while', 'wend', 'do', 'loop', 'until',

  // Select-Case and flow control
  'select', 'case', 'break', 'continue',

  // Exception handling
  //   raise      → throw an exception
  //   raiseevent → fire an event
  //   return     → return a value and exit the function
  //   exit       → exit a loop/sub
  'try', 'catch', 'finally', 'raise', 'raiseevent', 'return', 'exit',

  // OOP — instance creation and inheritance
  'new', 'inherits', 'implements', 'extends',

  // Event handler management
  //   addhandler    → add an event handler at runtime
  //   removehandler → remove an event handler
  'addhandler', 'removehandler',

  // Access modifiers
  //   static → local variable that retains value between calls (different from Shared)
  //   shared → member accessible without creating an instance
  'public', 'private', 'protected', 'static', 'shared', 'global',

  // OOP modifiers
  //   override → override a method from parent class
  //   final    → prevent subclass from further overriding
  //   abstract → method that must be overridden by subclass
  'override', 'virtual', 'final', 'abstract',

  // Special class members
  //   delegate   → function pointer for callbacks
  //   paramarray → variadic array parameter
  //   optional   → parameter that does not need to be passed
  'property', 'event', 'delegate', 'paramarray', 'optional',

  // Keywords for parameter and type declaration
  //   as    → specify type, e.g. "Var x As Integer"
  //   byref → pass by reference (can modify the original value)
  //   byval → pass by copy (default)
  //   of    → used with generics, e.g. Dictionary(Of String, Integer)
  'as', 'byref', 'byval', 'of',

  // Others
  'call', 'using', 'namespace',
]);

// Keyword-style operators — will receive token type 'operator'
// Separated so themes can use different colors from regular keywords
const OPERATOR_KEYWORDS = new Set([
  'and', 'or', 'not', 'xor',      // logical operators
  'mod',                           // modulo (remainder division)
  'in',                            // membership check (used in For Each)
  'is', 'isa',                     // Is = nil check, IsA = type check
  'addressof', 'weakaddressof',    // get pointer to method (for delegates)
]);

// Built-in data types — will receive token type 'type'
const TYPES = new Set([
  'integer', 'int8', 'int16', 'int32', 'int64',    // signed integers
  'uint8', 'uint16', 'uint32', 'uint64',            // unsigned integers
  'single', 'double',                               // floating point (32/64-bit)
  'boolean', 'string', 'variant',                   // basic types
  'object', 'color', 'ptr', 'auto', 'cstring', 'wstring',  // special types
]);

// Boolean constants — will receive token type 'atom'
// (atom in CodeMirror means a literal value that cannot be drilled down further)
//   true / false → standard boolean values
//   nil          → Xojo's null value (equivalent to null in C#)
const LITERALS = new Set(['true', 'false', 'nil']);

// Built-in references — will receive token type 'builtin'
//   self  → reference to current instance (equivalent to 'this' in Java/C#)
//   super → call parent class method
//   me    → legacy name for self (still supported for backward compatibility)
const BUILTINS = new Set(['self', 'super', 'me']);

// Known preprocessor directives
// When # is found followed by a word in this Set → the entire line becomes a 'meta' token
const PREPROCESSOR = new Set([
  'tag',       // #tag — IDE metadata blocks (project file structure markers)
  'pragma',    // #pragma — compiler hints e.g. DisableBackgroundTasks
  'if',        // #if — start conditional compilation
  'elseif',    // #elseif — conditional compilation branch
  'else',      // #else — conditional compilation fallback
  'endif',     // #endif — end conditional compilation block
  'region',    // #region — open code folding region
  'endregion', // #endregion — close code folding region
]);

// ────────────────────────────────────────────────────────────────────────────
// xojoStreamParser — implements CodeMirror 6's StreamParser interface
//
// Required interface:
//   startState() → return initial state object (used to store state between lines)
//   token(stream, state) → return token type string or null
//
// Note: this parser has no state between lines (stateless)
// because Xojo has no multiline tokens such as block comments or multiline strings
// ────────────────────────────────────────────────────────────────────────────
export const xojoStreamParser = {
  name: 'xojo',

  // startState() → return initial state
  // CodeMirror calls startState() once when parsing begins
  // and passes this state object to token() every time
  // In this case it's an empty object because there is no state between lines
  startState() {
    return {};
  },

  // ────────────────────────────────────────────────────────────────────────────
  // token(stream, state) — main StreamParser function
  //
  // Parameters:
  //   stream → StringStream pointing to the current position in the line
  //   state  → state object from startState() (unused in this case)
  //
  // Returns:
  //   string → token type e.g. 'keyword', 'comment', 'string'
  //   null   → no special color (plain text / whitespace)
  //
  // StringStream API used:
  //   stream.eatSpace()     → consume all spaces/tabs, return true if any consumed
  //   stream.match(pattern) → if match at current position: consume + return match
  //                           if no match: return false (position unchanged)
  //   stream.peek()         → read next character without consuming
  //   stream.next()         → consume and return next character
  //   stream.skipToEnd()    → consume to end of line
  //   stream.eol()          → true if at end of line
  //   stream.current()      → string consumed since start of this token
  // ────────────────────────────────────────────────────────────────────────────
  token(stream, _state) {

    // ─── Step 1: Skip whitespace ─────────────────────────────────────────────
    // eatSpace() consumes all spaces/tabs, then returns null (no color)
    // CodeMirror will call token() again immediately at the new position after whitespace
    if (stream.eatSpace()) return null;

    // ─── Step 2: Line comment: // ────────────────────────────────────────────
    // match('//') → if current position starts with //, consume both
    // skipToEnd() → consume remaining characters to end of line
    // Returns 'comment' → CodeMirror maps to tags.lineComment
    if (stream.match('//')) {
      stream.skipToEnd();
      return 'comment';
    }

    // ─── Step 3: Line comment: ' (apostrophe) ────────────────────────────────
    // peek() reads next character without consuming
    // If it's ' → skipToEnd() consumes the entire line (including the starting ')
    // Note: no need to call next() first because skipToEnd() consumes from current position
    if (stream.peek() === "'") {
      stream.skipToEnd();
      return 'comment';
    }

    // ─── Step 4: Preprocessor directives (#tag, #pragma, #if ...) ───────────
    // Check if current position is #
    if (stream.peek() === '#') {
      // Try to match #<word> e.g. #tag, #pragma, #if
      if (stream.match(/#([a-zA-Z]+)/)) {
        // stream.current() returns "#tag", "#pragma" etc.
        // .slice(1) removes the # leaving "tag", "pragma"
        // .toLowerCase() converts to lowercase for lookup in PREPROCESSOR Set
        const directive = stream.current().slice(1).toLowerCase();
        if (PREPROCESSOR.has(directive)) {
          // Found a known directive → consume the rest of the line
          // Important: skipToEnd() ensures "Module" in "#tag Module, Name = Utils"
          // is not matched as a keyword — the entire line is a single 'meta' token
          stream.skipToEnd();
          return 'meta';
        }
      } else {
        // Found # but /#([a-zA-Z]+)/ did not match
        // (e.g. # followed by a number or symbol)
        // Consume the single # and return null (no special color)
        stream.next();
      }
      return null;
    }

    // ─── Step 5: Double-quoted string ────────────────────────────────────────
    // Xojo strings start and end with " and do not span lines
    // Loop until end of line (eol) or closing " is found
    if (stream.peek() === '"') {
      stream.next(); // consume opening "
      while (!stream.eol()) {
        // next() consumes one character at a time: if closing " is found, exit loop
        if (stream.next() === '"') break;
      }
      return 'string';
    }

    // ─── Step 6: Hex literal (&h...) ─────────────────────────────────────────
    // &[hH][0-9a-fA-F]+ matches &h or &H followed by hex digits
    // Must be checked before identifiers because h in &hFF could be matched as an identifier
    if (stream.match(/&[hH][0-9a-fA-F]+/)) return 'number';

    // ─── Step 7: Binary literal (&b...) ──────────────────────────────────────
    // &[bB][01]+ matches &b or &B followed by binary digits (0 and 1 only)
    if (stream.match(/&[bB][01]+/)) return 'number';

    // ─── Step 8: Decimal / float literal ─────────────────────────────────────
    // \d+             → integer e.g. 42
    // (?:\.\d+)?      → decimal part e.g. .14 (optional)
    // (?:[eE][+-]?\d+)? → scientific notation e.g. e6, E-3 (optional)
    if (stream.match(/\d+(?:\.\d+)?(?:[eE][+-]?\d+)?/)) return 'number';

    // ─── Step 9: Identifiers and keyword matching ────────────────────────────
    // Match identifier: starts with letter or _ followed by letter/digit/_
    // word[0] is the matched string
    const word = stream.match(/[a-zA-Z_][a-zA-Z0-9_]*/);
    if (word) {
      // Convert to lowercase before lookup because Xojo is case-insensitive
      // All Sets use lowercase entries
      const w = word[0].toLowerCase();
      if (KEYWORDS.has(w))          return 'keyword';   // main reserved words
      if (OPERATOR_KEYWORDS.has(w)) return 'operator';  // keyword-style operators
      if (TYPES.has(w))             return 'type';      // data types
      if (LITERALS.has(w))          return 'atom';      // literal values
      if (BUILTINS.has(w))          return 'builtin';   // built-in references

      // Regular identifier (variable name, class name, etc.) → no special color
      return null;
    }

    // ─── Step 10: Fallback — consume unknown character ───────────────────────
    // Characters that don't match any pattern (e.g. +, -, =, (, ), ,)
    // Use next() to consume 1 character and return null (no special color)
    // CodeMirror will call token() again immediately at the next position
    stream.next();
    return null;
  },
};
