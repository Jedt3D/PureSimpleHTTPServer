/**
 * Node.js test for xojo.codemirror.js grammar
 * Run: node codemirror/test.mjs
 */
import { xojoStreamParser } from './xojo.codemirror.js';

// Minimal StringStream mock that matches CodeMirror's API
function makeStream(line) {
  const s = {
    text: line, pos: 0, start: 0,
    peek()    { return s.pos < s.text.length ? s.text[s.pos] : null; },
    next()    { return s.pos < s.text.length ? s.text[s.pos++] : undefined; },
    eol()     { return s.pos >= s.text.length; },
    sol()     { return s.pos === 0; },
    skipToEnd() { s.pos = s.text.length; },
    current() { return s.text.slice(s.start, s.pos); },
    eatSpace() {
      const from = s.pos;
      while (s.pos < s.text.length && /[ \t]/.test(s.text[s.pos])) s.pos++;
      return s.pos > from;
    },
    match(pattern, consume = true) {
      if (typeof pattern === 'string') {
        if (s.text.slice(s.pos).startsWith(pattern)) {
          if (consume) s.pos += pattern.length;
          return [pattern];
        }
        return false;
      }
      const m = pattern.exec(s.text.slice(s.pos));
      if (m && m.index === 0) {
        if (consume) s.pos += m[0].length;
        return m;
      }
      return false;
    },
  };
  return s;
}

function tokenize(line) {
  const state = xojoStreamParser.startState();
  const stream = makeStream(line);
  const tokens = [];
  while (!stream.eol()) {
    stream.start = stream.pos;
    const type = xojoStreamParser.token(stream, state);
    const text = stream.current();
    if (text.length > 0) {
      tokens.push({ text, type });
    } else {
      stream.pos++; // safety advance
    }
  }
  return tokens.filter(t => t.type !== null); // only typed tokens
}

// ─── Tests ───────────────────────────────────────────────────────────────────
const tests = [
  // Comments
  { line: '// hello world',                first: 'comment',  label: '// comment' },
  { line: "' apostrophe",                  first: 'comment',  label: "' comment" },

  // Preprocessor — whole line is meta, Module should NOT be keyword
  { line: '#pragma DisableBackgroundTasks',first: 'meta',     label: '#pragma → meta' },
  { line: '#tag Module, Name = Utils',     first: 'meta',     label: '#tag → meta (Module not keyword)' },
  { line: '#if TargetMacOS',              first: 'meta',     label: '#if → meta' },

  // Strings
  { line: '"Hello, World!"',              first: 'string',   label: 'string' },

  // Numbers
  { line: '&hFF00FF',                     first: 'number',   label: '&h hex' },
  { line: '&b10101010',                   first: 'number',   label: '&b binary' },
  { line: '3.14159',                      first: 'number',   label: 'decimal float' },
  { line: '42',                           first: 'number',   label: 'integer' },
  { line: '1e6',                          first: 'number',   label: 'scientific' },

  // Keywords (case-insensitive)
  { line: 'Var',   first: 'keyword', label: 'Var keyword' },
  { line: 'var',   first: 'keyword', label: 'var (lowercase)' },
  { line: 'Sub',   first: 'keyword', label: 'Sub' },
  { line: 'If',    first: 'keyword', label: 'If' },
  { line: 'Return',first: 'keyword', label: 'Return' },
  { line: 'Class', first: 'keyword', label: 'Class' },

  // Operator-keywords
  { line: 'And',          first: 'operator', label: 'And' },
  { line: 'Or',           first: 'operator', label: 'Or' },
  { line: 'Not',          first: 'operator', label: 'Not' },
  { line: 'AddressOf',    first: 'operator', label: 'AddressOf' },
  { line: 'IsA',          first: 'operator', label: 'IsA' },

  // Types
  { line: 'Integer', first: 'type', label: 'Integer type' },
  { line: 'String',  first: 'type', label: 'String type' },
  { line: 'Double',  first: 'type', label: 'Double type' },
  { line: 'Boolean', first: 'type', label: 'Boolean type' },

  // Literals
  { line: 'True',  first: 'atom', label: 'True literal' },
  { line: 'False', first: 'atom', label: 'False literal' },
  { line: 'Nil',   first: 'atom', label: 'Nil literal' },

  // Builtins
  { line: 'Self',  first: 'builtin', label: 'Self' },
  { line: 'Super', first: 'builtin', label: 'Super' },
  { line: 'Me',    first: 'builtin', label: 'Me' },

  // Edge: #tag Module → Module must NOT produce a keyword token (whole line is meta)
  {
    line: '#tag Module, Name = Utils',
    check(tokens) {
      const hasKw = tokens.some(t => t.type === 'keyword');
      return !hasKw;
    },
    label: '#tag line has NO keyword tokens for Module',
  },
];

let passed = 0, failed = 0;

for (const t of tests) {
  const tokens = tokenize(t.line);
  let ok;
  if (t.check) {
    ok = t.check(tokens);
  } else {
    ok = tokens[0]?.type === t.first;
  }
  if (ok) {
    console.log(`  ✓  ${t.label}`);
    passed++;
  } else {
    const got = tokens.map(x => `${x.text}:${x.type}`).join(' ');
    console.log(`  ✗  ${t.label}`);
    console.log(`       expected first=${t.first ?? '(custom)'}, got: [${got}]`);
    failed++;
  }
}

console.log(`\n${passed} passed, ${failed} failed`);
if (failed > 0) process.exit(1);
