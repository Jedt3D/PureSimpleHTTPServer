/**
 * CodeMirror 6 StreamParser for Xojo
 * https://github.com/worajedt/xojo-syntax-highlight
 *
 * Xojo เป็นภาษาโปรแกรมที่พัฒนาต่อมาจาก BASIC รองรับการสร้างแอป Desktop/Web/Mobile
 * ไฟล์นี้ export `xojoStreamParser` สำหรับใช้งานกับ CodeMirror 6
 *
 * ไม่มี dependency ภายนอก — ไม่ import จาก @codemirror/language หรือ package ใดๆ
 * ผู้ใช้ต้อง wrap ด้วย StreamLanguage.define() จาก @codemirror/language เอง:
 *
 *   import { StreamLanguage } from "@codemirror/language"
 *   import { xojoStreamParser } from "./xojo.codemirror.js"
 *   const xojoLang = StreamLanguage.define(xojoStreamParser)
 *
 * หลักการทำงาน:
 *   CodeMirror 6 เรียก token(stream, state) ซ้ำๆ จนสุดบรรทัด
 *   แต่ละครั้งที่เรียก stream จะชี้ไปยังตำแหน่งที่ยังไม่ได้ประมวลผล
 *   token() อ่านตัวอักษร consume เข้าไป แล้วคืนค่า token type หรือ null
 *
 * Token types ที่ใช้ → mapping ไปยัง Lezer highlight tags:
 *   'keyword'  → tags.keyword         (สีม่วง ใน One Dark)
 *   'operator' → tags.operator        (สีฟ้า)
 *   'atom'     → tags.atom            (สีส้ม)
 *   'type'     → tags.typeName        (สีฟ้าอ่อน)
 *   'builtin'  → tags.standard(name)  (สีแดง)
 *   'comment'  → tags.lineComment     (สีเทา)
 *   'string'   → tags.string          (สีเขียว)
 *   'number'   → tags.number          (สีส้ม)
 *   'meta'     → tags.meta            (สีเหลือง)
 *   null       → ไม่มีสี (plain text)
 */

// ────────────────────────────────────────────────────────────────────────────
// ชุดคำสงวน (Keyword sets) — ใช้ Set เพื่อ lookup O(1)
//
// ทุก entry เป็น lowercase เพราะ Xojo ไม่แยก case
// เมื่อ match identifier จะแปลงเป็น lowercase ก่อน lookup
// ────────────────────────────────────────────────────────────────────────────

// คำสงวนหลัก — จะได้รับ token type 'keyword'
const KEYWORDS = new Set([
  // การประกาศตัวแปร
  //   var → รูปแบบใหม่ (Xojo 2019+)   dim → รูปแบบเก่า (backward compatible)
  'var', 'dim',

  // ฟังก์ชันและเมธอด:
  //   sub      → ไม่มีค่าคืนกลับ (void)
  //   function → มีค่าคืนกลับ
  'sub', 'function',

  // โครงสร้าง OOP และโมดูล
  'class', 'module', 'interface', 'enum',

  // การควบคุมเงื่อนไข (If/Then/Else/ElseIf/End If)
  'if', 'then', 'else', 'elseif', 'end',

  // ลูป (For-Next, While-Wend, Do-Loop-Until)
  'for', 'each', 'next', 'while', 'wend', 'do', 'loop', 'until',

  // Select-Case และการควบคุม flow
  'select', 'case', 'break', 'continue',

  // Exception handling
  //   raise      → โยน exception
  //   raiseevent → ยิง event ออกไป
  //   return     → คืนค่าและออกจาก function
  //   exit       → ออกจาก loop/sub
  'try', 'catch', 'finally', 'raise', 'raiseevent', 'return', 'exit',

  // OOP — สร้าง instance และ inheritance
  'new', 'inherits', 'implements', 'extends',

  // Event handler management
  //   addhandler    → เพิ่ม event handler ณ runtime
  //   removehandler → ลบ event handler ออก
  'addhandler', 'removehandler',

  // Access modifiers — ระดับการเข้าถึง
  //   static → ตัวแปร local ที่ยังมีค่าระหว่าง call (ต่างจาก Shared)
  //   shared → member ใช้งานได้โดยไม่ต้องสร้าง instance
  'public', 'private', 'protected', 'static', 'shared', 'global',

  // OOP modifiers
  //   override → override method จาก parent class
  //   final    → ป้องกันไม่ให้ subclass override ต่อ
  //   abstract → method ที่ต้องถูก override โดย subclass
  'override', 'virtual', 'final', 'abstract',

  // สมาชิกพิเศษของ class
  //   delegate   → function pointer สำหรับ callback
  //   paramarray → พารามิเตอร์แบบ array (variadic function)
  //   optional   → พารามิเตอร์ที่ไม่จำเป็นต้องส่ง
  'property', 'event', 'delegate', 'paramarray', 'optional',

  // Keyword ในการประกาศพารามิเตอร์และชนิดข้อมูล
  //   as    → กำหนดชนิด เช่น "Var x As Integer"
  //   byref → ส่งแบบ reference (แก้ไขค่าต้นทางได้)
  //   byval → ส่งแบบ copy (default)
  //   of    → ใช้กับ generic เช่น Dictionary(Of String, Integer)
  'as', 'byref', 'byval', 'of',

  // อื่นๆ
  'call', 'using', 'namespace',
]);

// ตัวดำเนินการแบบ keyword — จะได้รับ token type 'operator'
// แยกออกมาเพื่อให้ theme สามารถใช้สีต่างจาก keyword ปกติได้
const OPERATOR_KEYWORDS = new Set([
  'and', 'or', 'not', 'xor',      // logical operators (เชิงตรรกะ)
  'mod',                           // modulo (หารเอาเศษ)
  'in',                            // membership check (ใช้ใน For Each)
  'is', 'isa',                     // Is = nil check, IsA = type check
  'addressof', 'weakaddressof',    // ได้ pointer ไปยัง method (สำหรับ delegate)
]);

// ชนิดข้อมูลพื้นฐาน — จะได้รับ token type 'type'
const TYPES = new Set([
  'integer', 'int8', 'int16', 'int32', 'int64',    // signed integers
  'uint8', 'uint16', 'uint32', 'uint64',            // unsigned integers
  'single', 'double',                               // floating point (32/64-bit)
  'boolean', 'string', 'variant',                   // ชนิดพื้นฐาน
  'object', 'color', 'ptr', 'auto', 'cstring', 'wstring',  // ชนิดพิเศษ
]);

// ค่าคงที่ boolean — จะได้รับ token type 'atom'
// (atom ใน CodeMirror หมายถึง literal value ที่ไม่สามารถ drill-down ได้)
//   true / false → ค่า boolean ปกติ
//   nil          → ค่า null ของ Xojo (เทียบเท่า null ใน C#)
const LITERALS = new Set(['true', 'false', 'nil']);

// Built-in references — จะได้รับ token type 'builtin'
//   self  → อ้างอิง instance ปัจจุบัน (เทียบเท่า 'this' ใน Java/C#)
//   super → เรียก method ของ parent class
//   me    → ชื่อเก่าของ self (ยังใช้ได้เพื่อ backward compatibility)
const BUILTINS = new Set(['self', 'super', 'me']);

// Preprocessor directives ที่รู้จัก
// เมื่อพบ # ตามด้วยคำใน Set นี้ → ทั้งบรรทัดจะเป็น token 'meta'
const PREPROCESSOR = new Set([
  'tag',       // #tag — IDE metadata blocks (project file structure markers)
  'pragma',    // #pragma — compiler hints เช่น DisableBackgroundTasks
  'if',        // #if — conditional compilation เริ่มต้น
  'elseif',    // #elseif — conditional compilation branch
  'else',      // #else — conditional compilation fallback
  'endif',     // #endif — จบ conditional compilation block
  'region',    // #region — เปิด code folding region
  'endregion', // #endregion — ปิด code folding region
]);

// ────────────────────────────────────────────────────────────────────────────
// xojoStreamParser — implements StreamParser interface ของ CodeMirror 6
//
// Interface ที่ต้องมี:
//   startState() → คืนค่า initial state object (ใช้เก็บ state ระหว่างบรรทัด)
//   token(stream, state) → คืน token type string หรือ null
//
// หมายเหตุ: parser นี้ไม่มี state ระหว่างบรรทัด (stateless)
// เพราะ Xojo ไม่มี multiline token เช่น block comment หรือ multiline string
// ────────────────────────────────────────────────────────────────────────────
export const xojoStreamParser = {
  name: 'xojo',

  // startState() → คืนค่า state เริ่มต้น
  // CodeMirror เรียก startState() ครั้งเดียวเมื่อเริ่ม parse
  // และส่ง state object นี้ไปยัง token() ทุกครั้ง
  // ในกรณีนี้เป็น empty object เพราะไม่มี state ระหว่างบรรทัด
  startState() {
    return {};
  },

  // ────────────────────────────────────────────────────────────────────────────
  // token(stream, state) — ฟังก์ชันหลักของ StreamParser
  //
  // Parameters:
  //   stream → StringStream ชี้ไปยังตำแหน่งปัจจุบันในบรรทัด
  //   state  → state object จาก startState() (ไม่ใช้ในกรณีนี้)
  //
  // Returns:
  //   string → token type เช่น 'keyword', 'comment', 'string'
  //   null   → ไม่มีสีพิเศษ (plain text / whitespace)
  //
  // StringStream API ที่ใช้:
  //   stream.eatSpace()     → กินช่องว่าง/tab ทั้งหมด คืน true ถ้ากินได้
  //   stream.match(pattern) → ถ้า match ที่ตำแหน่งปัจจุบัน: consume + คืน match
  //                           ถ้าไม่ match: คืน false (ไม่ขยับตำแหน่ง)
  //   stream.peek()         → อ่านตัวอักษรถัดไปโดยไม่ consume
  //   stream.next()         → consume และคืนตัวอักษรถัดไป
  //   stream.skipToEnd()    → กินจนสุดบรรทัด
  //   stream.eol()          → true ถ้าถึงสุดบรรทัดแล้ว
  //   stream.current()      → string ที่ consume ไปแล้วตั้งแต่ start ของ token นี้
  // ────────────────────────────────────────────────────────────────────────────
  token(stream, _state) {

    // ─── Step 1: ข้ามช่องว่าง (Whitespace) ─────────────────────────────────────
    // eatSpace() กิน space/tab ทั้งหมด แล้วคืน null (ไม่มีสี)
    // CodeMirror จะเรียก token() ซ้ำทันทีที่ตำแหน่งใหม่หลังช่องว่าง
    if (stream.eatSpace()) return null;

    // ─── Step 2: Line comment แบบ // ────────────────────────────────────────────
    // match('//') → ถ้าตำแหน่งปัจจุบันขึ้นต้นด้วย // จะ consume ทั้งคู่
    // skipToEnd() → กินตัวอักษรที่เหลือจนสุดบรรทัด
    // คืน 'comment' → CodeMirror map ไปยัง tags.lineComment
    if (stream.match('//')) {
      stream.skipToEnd();
      return 'comment';
    }

    // ─── Step 3: Line comment แบบ ' (apostrophe) ────────────────────────────────
    // peek() อ่านตัวอักษรถัดไปโดยไม่ consume ก่อน
    // ถ้าเป็น ' → skipToEnd() กินทั้งบรรทัด (รวม ' ที่เป็น start ด้วย)
    // หมายเหตุ: ไม่ต้องเรียก next() ก่อน เพราะ skipToEnd() กินตั้งแต่ตำแหน่งปัจจุบัน
    if (stream.peek() === "'") {
      stream.skipToEnd();
      return 'comment';
    }

    // ─── Step 4: Preprocessor directives (#tag, #pragma, #if ...) ───────────────
    // ตรวจสอบว่าตำแหน่งปัจจุบันเป็น # หรือไม่
    if (stream.peek() === '#') {
      // พยายาม match #<word> เช่น #tag, #pragma, #if
      if (stream.match(/#([a-zA-Z]+)/)) {
        // stream.current() คืน "#tag", "#pragma" ฯลฯ
        // .slice(1) ตัด # ออก เหลือ "tag", "pragma"
        // .toLowerCase() แปลงเป็น lowercase เพื่อ lookup ใน PREPROCESSOR Set
        const directive = stream.current().slice(1).toLowerCase();
        if (PREPROCESSOR.has(directive)) {
          // พบ directive ที่รู้จัก → กินทั้งบรรทัดที่เหลือ
          // สำคัญ: skipToEnd() ทำให้ "Module" ใน "#tag Module, Name = Utils"
          // ไม่ถูก match เป็น keyword — ทั้งบรรทัดเป็น token 'meta' เดียว
          stream.skipToEnd();
          return 'meta';
        }
      } else {
        // พบ # แต่ match /#([a-zA-Z]+)/ ไม่ได้
        // (เช่น # ตามด้วยตัวเลขหรือสัญลักษณ์)
        // กิน # ทิ้ง 1 ตัว แล้วคืน null (ไม่มีสีพิเศษ)
        stream.next();
      }
      return null;
    }

    // ─── Step 5: String ในเครื่องหมายคำพูดคู่ ───────────────────────────────────
    // Xojo string เริ่มและจบด้วย " และไม่ข้ามบรรทัด
    // loop จนสุดบรรทัด (eol) หรือจนพบ " ปิด
    if (stream.peek() === '"') {
      stream.next(); // consume " เปิด
      while (!stream.eol()) {
        // next() กินทีละตัว: ถ้าเจอ " ปิด ออกจาก loop ทันที
        if (stream.next() === '"') break;
      }
      return 'string';
    }

    // ─── Step 6: Hex literal (&h...) ─────────────────────────────────────────────
    // &[hH][0-9a-fA-F]+ match &h หรือ &H ตามด้วยเลข hex
    // ต้องตรวจก่อน identifier เพราะ h ใน &hFF อาจถูก match เป็น identifier ได้
    if (stream.match(/&[hH][0-9a-fA-F]+/)) return 'number';

    // ─── Step 7: Binary literal (&b...) ──────────────────────────────────────────
    // &[bB][01]+ match &b หรือ &B ตามด้วยเลข binary (0 และ 1 เท่านั้น)
    if (stream.match(/&[bB][01]+/)) return 'number';

    // ─── Step 8: Decimal / float literal ─────────────────────────────────────────
    // \d+             → จำนวนเต็ม เช่น 42
    // (?:\.\d+)?      → ส่วนทศนิยม เช่น .14 (optional)
    // (?:[eE][+-]?\d+)? → scientific notation เช่น e6, E-3 (optional)
    if (stream.match(/\d+(?:\.\d+)?(?:[eE][+-]?\d+)?/)) return 'number';

    // ─── Step 9: Identifiers และ keyword matching ─────────────────────────────────
    // match identifier: ขึ้นต้นด้วย letter หรือ _ ตามด้วย letter/digit/_
    // word[0] คือ string ที่ match ได้
    const word = stream.match(/[a-zA-Z_][a-zA-Z0-9_]*/);
    if (word) {
      // แปลงเป็น lowercase ก่อน lookup เพราะ Xojo ไม่แยก case
      // Sets ทั้งหมดใช้ lowercase entries
      const w = word[0].toLowerCase();
      if (KEYWORDS.has(w))          return 'keyword';   // คำสงวนหลัก
      if (OPERATOR_KEYWORDS.has(w)) return 'operator';  // ตัวดำเนินการแบบคำ
      if (TYPES.has(w))             return 'type';      // ชนิดข้อมูล
      if (LITERALS.has(w))          return 'atom';      // literal value
      if (BUILTINS.has(w))          return 'builtin';   // built-in reference

      // identifier ทั่วไป (ชื่อตัวแปร, ชื่อ class, ฯลฯ) → ไม่มีสีพิเศษ
      return null;
    }

    // ─── Step 10: Fallback — กินตัวอักษรที่ไม่รู้จัก ─────────────────────────────
    // ตัวอักษรที่ไม่ match pattern ใดเลย (เช่น +, -, =, (, ), ,)
    // ใช้ next() กิน 1 ตัว แล้วคืน null (ไม่มีสีพิเศษ)
    // CodeMirror จะเรียก token() ซ้ำที่ตำแหน่งถัดไปทันที
    stream.next();
    return null;
  },
};
