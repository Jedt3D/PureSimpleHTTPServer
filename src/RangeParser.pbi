; RangeParser.pbi — HTTP Range header parser
; Include with: XIncludeFile "RangeParser.pbi"
; Provides: ParseRangeHeader(), SendPartialResponse()
;
; Phase C: implement Range request parsing and partial file serving
; Phase A: placeholder
; Dependencies (managed by main.pb and tests/TestCommon.pbi): Global.pbi

Structure RangeSpec
  Start.i    ; Byte offset of range start (inclusive)
  End.i      ; Byte offset of range end (inclusive); -1 = end of file
  IsValid.i  ; #True if range parsed successfully
EndStructure

; ParseRangeHeader(header.s, fileSize.i, *range.RangeSpec) — parse Range: header
; header:   value of the Range: header (e.g. "bytes=0-1023")
; fileSize: total file size in bytes (needed for suffix-range calculation)
; *range:   filled with parsed range on success
; Returns #True if range is valid, #False if range is unsatisfiable (416)
Procedure.i ParseRangeHeader(header.s, fileSize.i, *range.RangeSpec)
  ; Phase C: implement
  *range\IsValid = #False
  ProcedureReturn #False
EndProcedure
