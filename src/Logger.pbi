; Logger.pbi — access log and error log writer
; Include with: XIncludeFile "Logger.pbi"
; Provides: OpenLogFile(), LogAccess(), CloseLogFile()
;           OpenErrorLog(), LogError(), CloseErrorLog()
;           ApacheDate()
;
; Phase F-1: Apache Combined Log Format access log + error log + log level filtering
;
; Access log format (CLF Combined):
;   IP - - [DD/Mon/YYYY:HH:MM:SS +HHMM] "METHOD /path PROTO" STATUS BYTES "Referer" "UA"
;
; Error log format:
;   [DD/Mon/YYYY:HH:MM:SS +HHMM] [level] [pid N] message
;
; Log levels: none=0  error=1  warn=2  info=3  (default threshold: 2=warn)
;   A message is written if its level integer <= g_LogLevel threshold.
;
; Thread safety: g_LogMutex covers both log file handles; all writes are mutex-guarded.
; Timezone: local time + local UTC offset computed once at first log open via
;   Date() - ConvertDate(Date(), #PB_Date_UTC) — no ImportC required.
;
; Dependencies (managed by main.pb and tests/TestCommon.pbi): Global.pbi

; --- Globals ---
Global g_LogFile.i      = 0   ; access log file handle (0 = not open)
Global g_ErrorLogFile.i = 0   ; error log file handle (0 = not open)
Global g_LogMutex.i     = 0   ; single mutex covering both log files
Global g_LogLevel.i     = 2   ; min error log level (0=none 1=error 2=warn 3=info)
Global g_ServerPID.i    = 0   ; server process ID (set by main.pb; 0 until F-3)
Global g_TZOffset.s             ; local UTC offset string e.g. "+0700" (lazy-init)

; --- Internal helpers ---

; EnsureLogInit() — create mutex and compute timezone offset on first log open
Procedure EnsureLogInit()
  If g_LogMutex = 0
    g_LogMutex = CreateMutex()
    ; Compute local UTC offset once: Date() is local, ConvertDate gives UTC.
    ; delta > 0 means east of UTC (e.g. +0700), delta < 0 means west (e.g. -0500).
    Protected delta.q = Date() - ConvertDate(Date(), #PB_Date_UTC)
    Protected sign.s = "+"
    If delta < 0 : sign = "-" : delta = -delta : EndIf
    Protected h.i = delta / 3600
    Protected m.i = (delta % 3600) / 60
    g_TZOffset = sign + RSet(Str(h), 2, "0") + RSet(Str(m), 2, "0")
  EndIf
EndProcedure

; OpenOrAppend(path.s) — open a file for appending, create if absent
; Returns the file handle or 0 on failure.
Procedure.i OpenOrAppend(path.s)
  Protected fh.i = 0
  If FileSize(path) >= 0
    fh = OpenFile(#PB_Any, path)
    If fh > 0
      FileSeek(fh, Lof(fh))
    EndIf
  EndIf
  If fh = 0
    fh = CreateFile(#PB_Any, path)
  EndIf
  ProcedureReturn fh
EndProcedure

; --- Public API ---

; ApacheDate(ts.q) — format a PureBasic date as [DD/Mon/YYYY:HH:MM:SS +HHMM]
; Requires EnsureLogInit() to have been called (for g_TZOffset).
Procedure.s ApacheDate(ts.q)
  Protected months.s = "Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec"
  Protected mon.i    = Val(FormatDate("%mm", ts))
  Protected monStr.s = StringField(months, mon, " ")
  ProcedureReturn "[" + FormatDate("%dd", ts) + "/" + monStr + "/" +
                  FormatDate("%yyyy", ts) + ":" + FormatDate("%hh:%ii:%ss", ts) +
                  " " + g_TZOffset + "]"
EndProcedure

; OpenLogFile(path.s) — open the access log file for appending (creates if absent)
; Returns #True on success, #False if the path cannot be opened or created.
Procedure.i OpenLogFile(path.s)
  EnsureLogInit()
  If g_LogFile > 0
    CloseFile(g_LogFile)
    g_LogFile = 0
  EndIf
  g_LogFile = OpenOrAppend(path)
  ProcedureReturn Bool(g_LogFile > 0)
EndProcedure

; CloseLogFile() — flush and close the access log file
; Safe to call when no file is open.
Procedure CloseLogFile()
  If g_LogFile > 0
    FlushFileBuffers(g_LogFile)
    CloseFile(g_LogFile)
    g_LogFile = 0
  EndIf
EndProcedure

; OpenErrorLog(path.s) — open the error log file for appending (creates if absent)
; Returns #True on success, #False if the path cannot be opened or created.
Procedure.i OpenErrorLog(path.s)
  EnsureLogInit()
  If g_ErrorLogFile > 0
    CloseFile(g_ErrorLogFile)
    g_ErrorLogFile = 0
  EndIf
  g_ErrorLogFile = OpenOrAppend(path)
  ProcedureReturn Bool(g_ErrorLogFile > 0)
EndProcedure

; CloseErrorLog() — flush and close the error log file
; Safe to call when no file is open.
Procedure CloseErrorLog()
  If g_ErrorLogFile > 0
    FlushFileBuffers(g_ErrorLogFile)
    CloseFile(g_ErrorLogFile)
    g_ErrorLogFile = 0
  EndIf
EndProcedure

; LogAccess(ip, method, path, protocol, status, bytes, referer, userAgent)
; Append one Combined Log Format line to the access log.
; No-op if no access log file is open.
;
; bytes   : body bytes sent; pass 0 for 304/empty responses (logged as "-")
; referer : Referer header value, or "" (logged as "-")
; userAgent: User-Agent header value, or "" (logged as "-")
Procedure LogAccess(ip.s, method.s, path.s, protocol.s, status.i, bytes.i, referer.s, userAgent.s)
  If g_LogFile = 0
    ProcedureReturn
  EndIf

  Protected ref.s = referer   : If ref = "" : ref = "-" : EndIf
  Protected ua.s  = userAgent : If ua  = "" : ua  = "-" : EndIf
  Protected byt.s = Str(bytes): If bytes = 0 : byt = "-" : EndIf

  Protected line.s = ip + " - - " + ApacheDate(Date()) +
                     " " + Chr(34) + method + " " + path + " " + protocol + Chr(34) +
                     " " + Str(status) +
                     " " + byt +
                     " " + Chr(34) + ref + Chr(34) +
                     " " + Chr(34) + ua  + Chr(34)

  LockMutex(g_LogMutex)
  WriteStringN(g_LogFile, line, #PB_Ascii)
  UnlockMutex(g_LogMutex)
EndProcedure

; LogError(level.s, message.s) — append one error log line
; level: "error" | "warn" | "info"
; No-op if no error log file is open, or if level is below g_LogLevel threshold.
; Level integers: error=1  warn=2  info=3
; A message is written when its integer <= g_LogLevel (e.g. threshold=2 logs error+warn).
Procedure LogError(level.s, message.s)
  If g_ErrorLogFile = 0
    ProcedureReturn
  EndIf

  Protected levelInt.i
  Select LCase(level)
    Case "error" : levelInt = 1
    Case "warn"  : levelInt = 2
    Case "info"  : levelInt = 3
    Default      : levelInt = 1  ; treat unknown as error
  EndSelect

  If levelInt > g_LogLevel
    ProcedureReturn  ; below configured threshold
  EndIf

  Protected line.s = ApacheDate(Date()) + " [" + level + "] [pid " +
                     Str(g_ServerPID) + "] " + message

  LockMutex(g_LogMutex)
  WriteStringN(g_ErrorLogFile, line, #PB_Ascii)
  UnlockMutex(g_LogMutex)
EndProcedure
