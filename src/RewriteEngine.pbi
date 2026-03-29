; RewriteEngine.pbi — URL rewrite and redirect rules (Caddy-compatible subset)
; Include with: XIncludeFile "RewriteEngine.pbi"
;
; Rule file syntax (rewrite.conf):
;   rewrite <pattern>  <destination>
;   redir   <pattern>  <destination>  [301|302]
;
; Pattern types:
;   /exact/path           exact URL match
;   /prefix/*             glob: * captures everything after the prefix
;   ~/regex(group)/       regex match (~ prefix); groups as {re.1}..{re.9}
;
; Destination placeholders:
;   {path}   — text captured by * in glob patterns
;   {file}   — basename (after last /) of {path}
;   {dir}    — dirname (before last /) of {path}
;   {re.N}   — Nth regex capture group (1-based, up to 9)
;
; Global rules:  loaded from --rewrite FILE (applies to all requests)
; Per-dir rules: rewrite.conf inside any served directory (applies to requests
;                whose URL path is in that directory or deeper)
;
; Evaluation order: global rules first; per-dir rules second; first match wins.
; Dependencies: Global.pbi, Types.pbi
;
; IMPLEMENTATION NOTES — PureBasic 6.30 ARM64 / PureUnit workarounds:
;
;  Bug 1: Global NewList + AddElement inside ANY procedure corrupts the list's
;  internal state; subsequent ForEach / ClearList segfaults. Fix: no NewList.
;
;  Bug 2: Global Dim of STRUCTURE types with embedded string fields (.s) causes
;  memory corruption during global initialisation. Fix: no struct arrays.
;
;  Bug 3 (PureUnit): PureUnit skips top-level main() initialisation code, so
;  all Global Dim array descriptors stay as {0}.  SYS_ReAllocateArray (ReDim)
;  reads element-size and type from the descriptor — both zero — and crashes.
;  Fix: replace ALL Global Dim arrays with AllocateMemory blocks allocated
;  inside InitRewriteEngine().  Only scalar Global variables (Global x.i / .s)
;  are safe under PureUnit — they are initialised by the compiler, not main().
EnableExplicit

; ── Rule-type constants ────────────────────────────────────────────────────────
#RULE_REWRITE = 0   ; internal path rewrite — no HTTP response change
#RULE_REDIR   = 1   ; HTTP redirect — sends 301 or 302 to client

; ── Match-type constants ───────────────────────────────────────────────────────
#MATCH_EXACT = 0    ; /exact/path
#MATCH_GLOB  = 1    ; /prefix/*
#MATCH_REGEX = 2    ; ~/pattern(group)/

; ── Capacity limits ───────────────────────────────────────────────────────────
#MAX_GLOBAL_RULES = 63    ; 0..63 — up to 64 global rules
#MAX_DIR_CACHE    = 7     ; 0..7  — up to 8 cached directories
#MAX_DIR_RULES    = 15    ; 0..15 — up to 16 rules per directory
#DR_STRIDE        = 16    ; #MAX_DIR_RULES + 1  (flat index stride)
; flat dir-rule index: di * #DR_STRIDE + ri → max = 7*16+15 = 127

; ── String buffer size ─────────────────────────────────────────────────────────
; URL patterns and destinations are ASCII paths — 512 bytes per slot is generous.
#RURL_LEN = 512

; ── Public result structure ────────────────────────────────────────────────────
Structure RewriteResult
  Action.i          ; 0 = no match, 1 = rewrite (NewPath set), 2 = redirect
  NewPath.s         ; rewritten URL path (Action = 1)
  RedirURL.s        ; redirect destination (Action = 2)
  RedirCode.i       ; redirect HTTP status code — 301 or 302 (Action = 2)
EndStructure

; ── Private structures (used only as Protected locals — never in Global Dim) ───
Structure RewriteRule
  RuleType.i     ; #RULE_REWRITE or #RULE_REDIR
  MatchType.i    ; #MATCH_EXACT, #MATCH_GLOB, #MATCH_REGEX
  Pattern.s
  Destination.s
  Code.i
  RegexHandle.i
EndStructure

; ── Globals — scalar pointer variables only (safe under PureUnit) ──────────────
; Integer array memory blocks: (count) * 8 bytes each element
Global g_GR_RuleTypeMem.i       ; (#MAX_GLOBAL_RULES+1) * 8
Global g_GR_MatchTypeMem.i
Global g_GR_CodeMem.i
Global g_GR_RegexMem.i
; String array memory blocks: (count) * #RURL_LEN bytes each element (ASCII)
Global g_GR_PatternMem.i        ; (#MAX_GLOBAL_RULES+1) * #RURL_LEN
Global g_GR_DestMem.i
Global g_GR_Count.i

; Per-directory cache
Global g_DC_DirPathMem.i        ; (#MAX_DIR_CACHE+1) * #RURL_LEN
Global g_DC_FileMtimeMem.i      ; (#MAX_DIR_CACHE+1) * 8  (Quad stored as 8 bytes)
Global g_DC_RuleCountMem.i      ; (#MAX_DIR_CACHE+1) * 8
Global g_DC_Count.i

; Per-directory rules (flat: index = di * #DR_STRIDE + ri, max 128 entries)
Global g_DR_RuleTypeMem.i       ; 128 * 8
Global g_DR_MatchTypeMem.i
Global g_DR_CodeMem.i
Global g_DR_RegexMem.i
Global g_DR_PatternMem.i        ; 128 * #RURL_LEN
Global g_DR_DestMem.i

Global g_RewriteMutex.i

; ── Memory access macros ───────────────────────────────────────────────────────
; Integer element (8 bytes on ARM64):
Macro RW_IGET(mem, i)
  PeekI((mem) + (i) * 8)
EndMacro
Macro RW_ISET(mem, i, v)
  PokeI((mem) + (i) * 8, (v))
EndMacro
; Quad element (8 bytes):
Macro RW_QGET(mem, i)
  PeekQ((mem) + (i) * 8)
EndMacro
Macro RW_QSET(mem, i, v)
  PokeQ((mem) + (i) * 8, (v))
EndMacro
; ASCII string element (#RURL_LEN bytes per slot):
Macro RW_SGET(mem, i)
  PeekS((mem) + (i) * #RURL_LEN, -1, #PB_Ascii)
EndMacro
Macro RW_SSET(mem, i, s)
  PokeS((mem) + (i) * #RURL_LEN, (s), #RURL_LEN - 1, #PB_Ascii)
EndMacro

; ── Private helpers ────────────────────────────────────────────────────────────

; URLLastSlash_ — 1-based index of last '/' in path; 0 if none
Procedure.i URLLastSlash_(path.s)
  Protected i.i
  For i = Len(path) To 1 Step -1
    If Mid(path, i, 1) = "/"
      ProcedureReturn i
    EndIf
  Next
  ProcedureReturn 0
EndProcedure

; URLBasename_ — component after the last '/'
Procedure.s URLBasename_(path.s)
  Protected pos.i = URLLastSlash_(path)
  If pos > 0 : ProcedureReturn Mid(path, pos + 1) : EndIf
  ProcedureReturn path
EndProcedure

; URLDirname_ — component before the last '/' (returns "/" for root)
Procedure.s URLDirname_(path.s)
  Protected pos.i = URLLastSlash_(path)
  If pos > 1 : ProcedureReturn Left(path, pos - 1) : EndIf
  ProcedureReturn "/"
EndProcedure

; SubstPlaceholders_ — expand {path},{file},{dir},{re.1..9} in dest template
Procedure.s SubstPlaceholders_(tmpl.s, captured.s,
                                g1.s, g2.s, g3.s, g4.s, g5.s,
                                g6.s, g7.s, g8.s, g9.s)
  Protected r.s = tmpl
  r = ReplaceString(r, "{path}", captured)
  r = ReplaceString(r, "{file}", URLBasename_(captured))
  r = ReplaceString(r, "{dir}",  URLDirname_(captured))
  r = ReplaceString(r, "{re.1}", g1)
  r = ReplaceString(r, "{re.2}", g2)
  r = ReplaceString(r, "{re.3}", g3)
  r = ReplaceString(r, "{re.4}", g4)
  r = ReplaceString(r, "{re.5}", g5)
  r = ReplaceString(r, "{re.6}", g6)
  r = ReplaceString(r, "{re.7}", g7)
  r = ReplaceString(r, "{re.8}", g8)
  r = ReplaceString(r, "{re.9}", g9)
  ProcedureReturn r
EndProcedure

; ParseRule_ — parse one config line into *rule; returns #True on success.
; Uses only local Protected variables — no globals written except via *rule.
Procedure.i ParseRule_(line.s, *rule.RewriteRule)
  line = Trim(line)
  If Len(line) = 0 Or Left(line, 1) = "#" : ProcedureReturn #False : EndIf

  ; Inline tokenization — no global scratch arrays
  line = ReplaceString(line, Chr(9), " ")
  Protected t0.s = "", t1.s = "", t2.s = "", t3.s = ""
  Protected tcount.i = 0
  Protected ti.i, tn.i = CountString(line, " ") + 1
  Protected tok.s
  For ti = 1 To tn
    tok = Trim(StringField(line, ti, " "))
    If Len(tok) > 0
      Select tcount
        Case 0 : t0 = tok
        Case 1 : t1 = tok
        Case 2 : t2 = tok
        Case 3 : t3 = tok
      EndSelect
      tcount + 1
      If tcount >= 4 : Break : EndIf
    EndIf
  Next
  If tcount < 3 : ProcedureReturn #False : EndIf

  Protected verb.s = LCase(t0)
  Protected ruleType.i
  Select verb
    Case "rewrite" : ruleType = #RULE_REWRITE
    Case "redir"   : ruleType = #RULE_REDIR
    Default        : ProcedureReturn #False
  EndSelect

  Protected code.i = 0
  If ruleType = #RULE_REDIR
    code = Val(t3)
    If code = 0 : code = 302 : EndIf
  EndIf

  Protected matchType.i
  Protected cleanPat.s
  If Left(t1, 1) = "~"
    matchType = #MATCH_REGEX
    cleanPat  = Mid(t1, 2)
  ElseIf Right(t1, 1) = "*"
    matchType = #MATCH_GLOB
    cleanPat  = Left(t1, Len(t1) - 1)
  Else
    matchType = #MATCH_EXACT
    cleanPat  = t1
  EndIf

  Protected regexHandle.i = 0
  If matchType = #MATCH_REGEX
    regexHandle = CreateRegularExpression(#PB_Any, cleanPat)
    If regexHandle = 0 : ProcedureReturn #False : EndIf
  EndIf

  *rule\RuleType    = ruleType
  *rule\MatchType   = matchType
  *rule\Pattern     = cleanPat
  *rule\Destination = t2
  *rule\Code        = code
  *rule\RegexHandle = regexHandle
  ProcedureReturn #True
EndProcedure

; LoadDirRulesIfNeeded_ — load / refresh per-dir rule cache for a URL directory.
; Called inside g_RewriteMutex. Returns slot index (>=0) or -1 if unavailable.
Procedure.i LoadDirRulesIfNeeded_(dirPath.s, docRoot.s)
  Protected dirFS.s = docRoot + dirPath
  If Right(dirFS, 1) <> "/" : dirFS + "/" : EndIf
  Protected confPath.s = dirFS + "rewrite.conf"

  Protected mtime.q = GetFileDate(confPath, #PB_Date_Modified)
  If mtime <= 0 : ProcedureReturn -1 : EndIf

  Protected i.i, j.i, ri.i, f.i
  Protected tmp.RewriteRule
  Protected rcount.i

  ; Search existing cache
  For i = 0 To g_DC_Count - 1
    If RW_SGET(g_DC_DirPathMem, i) = dirPath
      If RW_QGET(g_DC_FileMtimeMem, i) <> mtime
        ; Stale — free old regex handles
        rcount = RW_IGET(g_DC_RuleCountMem, i)
        For j = 0 To rcount - 1
          ri = i * #DR_STRIDE + j
          If RW_IGET(g_DR_RegexMem, ri) > 0
            FreeRegularExpression(RW_IGET(g_DR_RegexMem, ri))
            RW_ISET(g_DR_RegexMem, ri, 0)
          EndIf
        Next
        RW_ISET(g_DC_RuleCountMem, i, 0)
        ; Reload
        f = ReadFile(#PB_Any, confPath)
        If f
          While Not Eof(f) And RW_IGET(g_DC_RuleCountMem, i) < #DR_STRIDE
            If ParseRule_(ReadString(f), @tmp)
              j = i * #DR_STRIDE + RW_IGET(g_DC_RuleCountMem, i)
              RW_ISET(g_DR_RuleTypeMem,  j, tmp\RuleType)
              RW_ISET(g_DR_MatchTypeMem, j, tmp\MatchType)
              RW_SSET(g_DR_PatternMem,   j, tmp\Pattern)
              RW_SSET(g_DR_DestMem,      j, tmp\Destination)
              RW_ISET(g_DR_CodeMem,      j, tmp\Code)
              RW_ISET(g_DR_RegexMem,     j, tmp\RegexHandle)
              RW_ISET(g_DC_RuleCountMem, i, RW_IGET(g_DC_RuleCountMem, i) + 1)
            EndIf
          Wend
          CloseFile(f)
        EndIf
        RW_QSET(g_DC_FileMtimeMem, i, mtime)
      EndIf
      ProcedureReturn i
    EndIf
  Next

  ; New entry
  If g_DC_Count > #MAX_DIR_CACHE : ProcedureReturn -1 : EndIf
  i = g_DC_Count
  RW_SSET(g_DC_DirPathMem,   i, dirPath)
  RW_QSET(g_DC_FileMtimeMem, i, mtime)
  RW_ISET(g_DC_RuleCountMem, i, 0)
  f = ReadFile(#PB_Any, confPath)
  If f
    Protected tmp2.RewriteRule
    While Not Eof(f) And RW_IGET(g_DC_RuleCountMem, i) < #DR_STRIDE
      If ParseRule_(ReadString(f), @tmp2)
        j = i * #DR_STRIDE + RW_IGET(g_DC_RuleCountMem, i)
        RW_ISET(g_DR_RuleTypeMem,  j, tmp2\RuleType)
        RW_ISET(g_DR_MatchTypeMem, j, tmp2\MatchType)
        RW_SSET(g_DR_PatternMem,   j, tmp2\Pattern)
        RW_SSET(g_DR_DestMem,      j, tmp2\Destination)
        RW_ISET(g_DR_CodeMem,      j, tmp2\Code)
        RW_ISET(g_DR_RegexMem,     j, tmp2\RegexHandle)
        RW_ISET(g_DC_RuleCountMem, i, RW_IGET(g_DC_RuleCountMem, i) + 1)
      EndIf
    Wend
    CloseFile(f)
  EndIf
  g_DC_Count + 1
  ProcedureReturn i
EndProcedure

; ── Public API ─────────────────────────────────────────────────────────────────

; InitRewriteEngine() — allocate storage and create mutex.
; Uses AllocateMemory (not Global Dim) so it works under PureUnit:
; PureUnit skips main() so Global Dim descriptors stay as {0}; AllocateMemory
; called here runs correctly regardless of how the program was started.
Procedure InitRewriteEngine()
  Protected n.i

  ; Global rules (up to #MAX_GLOBAL_RULES+1 = 64 entries)
  n = (#MAX_GLOBAL_RULES + 1) * 8
  g_GR_RuleTypeMem  = AllocateMemory(n)
  g_GR_MatchTypeMem = AllocateMemory(n)
  g_GR_CodeMem      = AllocateMemory(n)
  g_GR_RegexMem     = AllocateMemory(n)
  g_GR_PatternMem   = AllocateMemory((#MAX_GLOBAL_RULES + 1) * #RURL_LEN)
  g_GR_DestMem      = AllocateMemory((#MAX_GLOBAL_RULES + 1) * #RURL_LEN)
  g_GR_Count = 0

  ; Per-directory cache (up to #MAX_DIR_CACHE+1 = 8 entries)
  n = (#MAX_DIR_CACHE + 1) * 8
  g_DC_FileMtimeMem  = AllocateMemory(n)
  g_DC_RuleCountMem  = AllocateMemory(n)
  g_DC_DirPathMem    = AllocateMemory((#MAX_DIR_CACHE + 1) * #RURL_LEN)
  g_DC_Count = 0

  ; Per-directory rules (128 flat entries: di * #DR_STRIDE + ri)
  n = 128 * 8
  g_DR_RuleTypeMem  = AllocateMemory(n)
  g_DR_MatchTypeMem = AllocateMemory(n)
  g_DR_CodeMem      = AllocateMemory(n)
  g_DR_RegexMem     = AllocateMemory(n)
  g_DR_PatternMem   = AllocateMemory(128 * #RURL_LEN)
  g_DR_DestMem      = AllocateMemory(128 * #RURL_LEN)

  g_RewriteMutex = CreateMutex()
EndProcedure

; CleanupRewriteEngine() — release all regex handles, memory blocks, and mutex
Procedure CleanupRewriteEngine()
  Protected i.i, j.i, ri.i, rcount.i

  If g_GR_RuleTypeMem = 0 : ProcedureReturn : EndIf   ; already cleaned / never init'd

  ; Free global-rule regex handles
  For i = 0 To g_GR_Count - 1
    If RW_IGET(g_GR_RegexMem, i) > 0
      FreeRegularExpression(RW_IGET(g_GR_RegexMem, i))
    EndIf
  Next
  g_GR_Count = 0

  ; Free per-dir-rule regex handles
  For i = 0 To g_DC_Count - 1
    rcount = RW_IGET(g_DC_RuleCountMem, i)
    For j = 0 To rcount - 1
      ri = i * #DR_STRIDE + j
      If RW_IGET(g_DR_RegexMem, ri) > 0
        FreeRegularExpression(RW_IGET(g_DR_RegexMem, ri))
      EndIf
    Next
  Next
  g_DC_Count = 0

  ; Free all memory blocks
  FreeMemory(g_GR_RuleTypeMem)  : g_GR_RuleTypeMem  = 0
  FreeMemory(g_GR_MatchTypeMem) : g_GR_MatchTypeMem = 0
  FreeMemory(g_GR_CodeMem)      : g_GR_CodeMem      = 0
  FreeMemory(g_GR_RegexMem)     : g_GR_RegexMem     = 0
  FreeMemory(g_GR_PatternMem)   : g_GR_PatternMem   = 0
  FreeMemory(g_GR_DestMem)      : g_GR_DestMem      = 0
  FreeMemory(g_DC_DirPathMem)   : g_DC_DirPathMem   = 0
  FreeMemory(g_DC_FileMtimeMem) : g_DC_FileMtimeMem = 0
  FreeMemory(g_DC_RuleCountMem) : g_DC_RuleCountMem = 0
  FreeMemory(g_DR_RuleTypeMem)  : g_DR_RuleTypeMem  = 0
  FreeMemory(g_DR_MatchTypeMem) : g_DR_MatchTypeMem = 0
  FreeMemory(g_DR_CodeMem)      : g_DR_CodeMem      = 0
  FreeMemory(g_DR_RegexMem)     : g_DR_RegexMem     = 0
  FreeMemory(g_DR_PatternMem)   : g_DR_PatternMem   = 0
  FreeMemory(g_DR_DestMem)      : g_DR_DestMem      = 0

  If g_RewriteMutex
    FreeMutex(g_RewriteMutex)
    g_RewriteMutex = 0
  EndIf
EndProcedure

; LoadGlobalRules(path.s) — load (or reload) global rules from a rewrite.conf file
Procedure LoadGlobalRules(path.s)
  LockMutex(g_RewriteMutex)
  Protected i.i
  ; Free existing regex handles
  For i = 0 To g_GR_Count - 1
    If RW_IGET(g_GR_RegexMem, i) > 0
      FreeRegularExpression(RW_IGET(g_GR_RegexMem, i))
      RW_ISET(g_GR_RegexMem, i, 0)
    EndIf
  Next
  g_GR_Count = 0
  Protected f.i = ReadFile(#PB_Any, path)
  If f
    Protected tmp.RewriteRule
    While Not Eof(f) And g_GR_Count <= #MAX_GLOBAL_RULES
      If ParseRule_(ReadString(f), @tmp)
        RW_ISET(g_GR_RuleTypeMem,  g_GR_Count, tmp\RuleType)
        RW_ISET(g_GR_MatchTypeMem, g_GR_Count, tmp\MatchType)
        RW_SSET(g_GR_PatternMem,   g_GR_Count, tmp\Pattern)
        RW_SSET(g_GR_DestMem,      g_GR_Count, tmp\Destination)
        RW_ISET(g_GR_CodeMem,      g_GR_Count, tmp\Code)
        RW_ISET(g_GR_RegexMem,     g_GR_Count, tmp\RegexHandle)
        g_GR_Count + 1
      EndIf
    Wend
    CloseFile(f)
  EndIf
  UnlockMutex(g_RewriteMutex)
EndProcedure

; GlobalRuleCount() — return number of loaded global rules
Procedure.i GlobalRuleCount()
  LockMutex(g_RewriteMutex)
  Protected n.i = g_GR_Count
  UnlockMutex(g_RewriteMutex)
  ProcedureReturn n
EndProcedure

; ApplyRewrites(path, docRoot, *result) — apply global then per-directory rules.
; Returns #True when a rule matched and *result is filled.
Procedure.i ApplyRewrites(path.s, docRoot.s, *result.RewriteResult)
  *result\Action = 0
  LockMutex(g_RewriteMutex)

  Protected i.i, k.i
  Protected captured.s, pfx.s, dest.s
  Protected hit.i
  Protected g1.s, g2.s, g3.s, g4.s, g5.s, g6.s, g7.s, g8.s, g9.s
  Protected rxh.i

  ; 1. Global rules
  For i = 0 To g_GR_Count - 1
    captured = ""
    g1 = "" : g2 = "" : g3 = "" : g4 = "" : g5 = ""
    g6 = "" : g7 = "" : g8 = "" : g9 = ""
    hit = #False

    Select RW_IGET(g_GR_MatchTypeMem, i)
      Case #MATCH_EXACT
        If path = RW_SGET(g_GR_PatternMem, i)
          hit = #True
        EndIf
      Case #MATCH_GLOB
        pfx = RW_SGET(g_GR_PatternMem, i)
        If Left(path, Len(pfx)) = pfx
          captured = Mid(path, Len(pfx) + 1)
          hit = #True
        EndIf
      Case #MATCH_REGEX
        rxh = RW_IGET(g_GR_RegexMem, i)
        If rxh > 0
          If ExamineRegularExpression(rxh, path)
            If NextRegularExpressionMatch(rxh)
              g1 = RegularExpressionGroup(rxh, 1)
              g2 = RegularExpressionGroup(rxh, 2)
              g3 = RegularExpressionGroup(rxh, 3)
              g4 = RegularExpressionGroup(rxh, 4)
              g5 = RegularExpressionGroup(rxh, 5)
              g6 = RegularExpressionGroup(rxh, 6)
              g7 = RegularExpressionGroup(rxh, 7)
              g8 = RegularExpressionGroup(rxh, 8)
              g9 = RegularExpressionGroup(rxh, 9)
              hit = #True
            EndIf
          EndIf
        EndIf
    EndSelect

    If hit
      dest = SubstPlaceholders_(RW_SGET(g_GR_DestMem, i), captured,
                                 g1, g2, g3, g4, g5, g6, g7, g8, g9)
      If RW_IGET(g_GR_RuleTypeMem, i) = #RULE_REWRITE
        *result\Action  = 1
        *result\NewPath = dest
      Else
        *result\Action    = 2
        *result\RedirURL  = dest
        *result\RedirCode = RW_IGET(g_GR_CodeMem, i)
      EndIf
      UnlockMutex(g_RewriteMutex)
      ProcedureReturn #True
    EndIf
  Next

  ; 2. Per-directory rules
  Protected dirPath.s = URLDirname_(path)
  Protected slot.i = LoadDirRulesIfNeeded_(dirPath, docRoot)
  If slot >= 0
    Protected ri.i, rcount.i = RW_IGET(g_DC_RuleCountMem, slot)
    For k = 0 To rcount - 1
      ri = slot * #DR_STRIDE + k
      captured = ""
      g1 = "" : g2 = "" : g3 = "" : g4 = "" : g5 = ""
      g6 = "" : g7 = "" : g8 = "" : g9 = ""
      hit = #False

      Select RW_IGET(g_DR_MatchTypeMem, ri)
        Case #MATCH_EXACT
          If path = RW_SGET(g_DR_PatternMem, ri)
            hit = #True
          EndIf
        Case #MATCH_GLOB
          pfx = RW_SGET(g_DR_PatternMem, ri)
          If Left(path, Len(pfx)) = pfx
            captured = Mid(path, Len(pfx) + 1)
            hit = #True
          EndIf
        Case #MATCH_REGEX
          rxh = RW_IGET(g_DR_RegexMem, ri)
          If rxh > 0
            If ExamineRegularExpression(rxh, path)
              If NextRegularExpressionMatch(rxh)
                g1 = RegularExpressionGroup(rxh, 1)
                g2 = RegularExpressionGroup(rxh, 2)
                g3 = RegularExpressionGroup(rxh, 3)
                g4 = RegularExpressionGroup(rxh, 4)
                g5 = RegularExpressionGroup(rxh, 5)
                g6 = RegularExpressionGroup(rxh, 6)
                g7 = RegularExpressionGroup(rxh, 7)
                g8 = RegularExpressionGroup(rxh, 8)
                g9 = RegularExpressionGroup(rxh, 9)
                hit = #True
              EndIf
            EndIf
          EndIf
      EndSelect

      If hit
        dest = SubstPlaceholders_(RW_SGET(g_DR_DestMem, ri), captured,
                                   g1, g2, g3, g4, g5, g6, g7, g8, g9)
        If RW_IGET(g_DR_RuleTypeMem, ri) = #RULE_REWRITE
          *result\Action  = 1
          *result\NewPath = dest
        Else
          *result\Action    = 2
          *result\RedirURL  = dest
          *result\RedirCode = RW_IGET(g_DR_CodeMem, ri)
        EndIf
        UnlockMutex(g_RewriteMutex)
        ProcedureReturn #True
      EndIf
    Next
  EndIf

  UnlockMutex(g_RewriteMutex)
  ProcedureReturn #False
EndProcedure
