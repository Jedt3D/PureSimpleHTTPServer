; Logger.pbi — access log writer
; Include with: XIncludeFile "Logger.pbi"
; Provides: LogAccess(), OpenLogFile(), CloseLogFile()
;
; Phase E: mutex-protected concurrent file writing
; Phase A: placeholder writing to Debug output only
; Dependencies (managed by main.pb and tests/TestCommon.pbi): Global.pbi

; LogAccess(method.s, path.s, status.i, bytes.i, ip.s) — log one HTTP access
; Format (Phase E): [ISO-timestamp] IP METHOD /path STATUS BYTES
Procedure LogAccess(method.s, path.s, status.i, bytes.i, ip.s)
  ; Phase E: write to log file with mutex protection
  Debug ip + " [" + method + "] " + path + " -> " + Str(status) + " (" + Str(bytes) + " bytes)"
EndProcedure

; OpenLogFile(path.s) — open the log file for writing
; Returns #True on success
Procedure.i OpenLogFile(path.s)
  ; Phase E: implement
  ProcedureReturn #False
EndProcedure

; CloseLogFile() — flush and close the log file
Procedure CloseLogFile()
  ; Phase E: implement
EndProcedure
