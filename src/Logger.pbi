; Logger.pbi — access log writer
; Include with: XIncludeFile "Logger.pbi"
; Provides: OpenLogFile(), LogAccess(), CloseLogFile()
;
; Phase E: mutex-protected file writing for thread-per-connection model
; Format:  [YYYY-MM-DD HH:MM:SS] IP METHOD /path STATUS BYTES
; Dependencies (managed by main.pb and tests/TestCommon.pbi): Global.pbi

; g_LogFile  — file handle (0 = not open)
; g_LogMutex — mutex handle for thread-safe writes (0 = not created)
Global g_LogFile.i  = 0
Global g_LogMutex.i = 0

; OpenLogFile(path.s) — open the log file for appending (creates if absent)
; Returns #True on success, #False if the path cannot be opened or created.
Procedure.i OpenLogFile(path.s)
  If g_LogMutex = 0
    g_LogMutex = CreateMutex()
  EndIf

  If g_LogFile > 0
    CloseFile(g_LogFile)
    g_LogFile = 0
  EndIf

  ; Append to existing file, or create a new one
  If FileSize(path) >= 0
    g_LogFile = OpenFile(#PB_Any, path)
    If g_LogFile > 0
      FileSeek(g_LogFile, Lof(g_LogFile))
    EndIf
  EndIf

  If g_LogFile = 0
    g_LogFile = CreateFile(#PB_Any, path)
  EndIf

  ProcedureReturn Bool(g_LogFile > 0)
EndProcedure

; LogAccess(method, path, status, bytes, ip) — append one access log line
; No-op if no log file is open.
Procedure LogAccess(method.s, path.s, status.i, bytes.i, ip.s)
  If g_LogFile = 0
    ProcedureReturn
  EndIf

  Protected line.s = "[" + FormatDate("%yyyy-%mm-%dd %hh:%ii:%ss", Date()) + "] " +
                     ip + " " + method + " " + path + " " + Str(status) + " " + Str(bytes)

  If g_LogMutex > 0 : LockMutex(g_LogMutex) : EndIf
  WriteStringN(g_LogFile, line, #PB_Ascii)
  If g_LogMutex > 0 : UnlockMutex(g_LogMutex) : EndIf
EndProcedure

; CloseLogFile() — flush and close the log file
; Safe to call when no file is open.
Procedure CloseLogFile()
  If g_LogFile > 0
    FlushFileBuffers(g_LogFile)
    CloseFile(g_LogFile)
    g_LogFile = 0
  EndIf
EndProcedure
