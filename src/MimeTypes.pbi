; MimeTypes.pbi — MIME type lookup table
; Include with: XIncludeFile "MimeTypes.pbi"
; Provides: GetMimeType(extension.s) -> String
;
; Phase B: implement full ~40-entry extension map
; Phase A: placeholder returning application/octet-stream
; Dependencies (managed by main.pb and tests/TestCommon.pbi): Global.pbi

; GetMimeType(extension.s) — return MIME type for a file extension
; extension: lowercase, without leading dot (e.g. "html", "css", "js", "png")
; Returns "application/octet-stream" for unknown extensions.
Procedure.s GetMimeType(extension.s)
  ; Phase B: replace with full Map lookup
  ProcedureReturn "application/octet-stream"
EndProcedure
