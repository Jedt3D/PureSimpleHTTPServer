; Logger.pbi — access log and error log writer
; Include with: XIncludeFile "Logger.pbi"
; Provides: OpenLogFile(), LogAccess(), CloseLogFile()
;           OpenErrorLog(), LogError(), CloseErrorLog()
;           ApacheDate()
;           StartDailyRotation(), StopDailyRotation()
;
; Phase F-1: Apache Combined Log Format access log + error log + log level filtering
; Phase F-2: Size-based log rotation with date-stamped archives and keep-count pruning
; Phase F-3: Daily midnight UTC rotation via background thread
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
; Rotation (F-2 + F-3):
;   F-2 — When log size >= g_LogMaxBytes (0 = disabled), the log is renamed to a
;     date-stamped archive and a fresh file is opened. Old archives beyond
;     g_LogKeepCount are deleted (oldest first). Archive format:
;       stem.YYYYMMDD-HHMMSS-NNN.ext  (NNN = per-process sequence, ensures uniqueness)
;   F-3 — StartDailyRotation() launches a background thread that wakes at the next
;     UTC midnight and rotates both log files, then sleeps until the following midnight.
;     StopDailyRotation() signals the thread to exit and waits for it to finish.
;
; Thread safety: g_LogMutex covers both log file handles; all writes are mutex-guarded.
;   Rotation is performed inside the mutex before the write.
; Timezone: local time + local UTC offset computed once at first log open via
;   Date() - ConvertDate(Date(), #PB_Date_UTC) — no ImportC required.
;
; Dependencies (managed by main.pb and tests/TestCommon.pbi): Global.pbi

; --- Globals ---
Global g_LogFile.i       = 0   ; access log file handle (0 = not open)
Global g_ErrorLogFile.i  = 0   ; error log file handle (0 = not open)
Global g_LogMutex.i      = 0   ; single mutex covering both log files
Global g_LogLevel.i      = 2   ; min error log level (0=none 1=error 2=warn 3=info)
Global g_ServerPID.i     = 0   ; server process ID (set by main.pb; 0 until F-3)
Global g_TZOffset.s              ; local UTC offset string e.g. "+0700" (lazy-init)
Global g_LogPath.s       = ""  ; access log file path (saved for rotation)
Global g_ErrorLogPath.s  = ""  ; error log file path (saved for rotation)
Global g_LogMaxBytes.i   = 0   ; rotation threshold in bytes; 0 = disabled
Global g_LogKeepCount.i  = 30  ; max rotated archive files to keep per log
Global g_RotationSeq.i   = 0   ; per-process sequence counter for archive uniqueness
Global g_RotationThread.i = 0  ; daily rotation thread ID (0 = not running)
Global g_StopRotation.i   = 0  ; set to 1 to signal thread to exit

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

; RotationStamp() — return "YYYYMMDD-HHMMSS-NNN" for archive naming
; NNN is a per-process sequence number ensuring uniqueness within a second.
Procedure.s RotationStamp()
  Protected ts.q = Date()
  g_RotationSeq + 1
  ProcedureReturn FormatDate("%yyyy%mm%dd", ts) + "-" + FormatDate("%hh%ii%ss", ts) +
                  "-" + RSet(Str(g_RotationSeq), 3, "0")
EndProcedure

; PruneArchives(logPath.s) — delete oldest date-stamped archives beyond g_LogKeepCount
; logPath: the active log file path (used to derive stem and extension for matching).
; Must be called inside g_LogMutex (via RotateLog).
Procedure PruneArchives(logPath.s)
  If g_LogKeepCount <= 0 : ProcedureReturn : EndIf

  Protected dir.s       = GetPathPart(logPath)
  Protected base.s      = GetFilePart(logPath)
  Protected ext.s       = LCase(GetExtensionPart(base))
  Protected stemLen.i   = Len(base) - Bool(ext <> "") * (Len(ext) + 1)
  Protected stem.s      = Left(base, stemLen)
  Protected prefix.s    = stem + "."
  Protected suffix.s    = ""
  If ext <> "" : suffix = "." + ext : EndIf
  Protected prefixLen.i = Len(prefix)
  Protected suffixLen.i = Len(suffix)

  Protected NewList archives.s()
  Protected name.s, mid.s

  If ExamineDirectory(1, dir, "*")
    While NextDirectoryEntry(1)
      If DirectoryEntryType(1) = #PB_DirectoryEntry_File
        name = DirectoryEntryName(1)
        ; Archive name: prefix + stamp (>=15 chars) + suffix
        If Len(name) > prefixLen + 14 + suffixLen
          If Left(name, prefixLen) = prefix
            If suffix = "" Or Right(name, suffixLen) = suffix
              mid = Mid(name, prefixLen + 1, Len(name) - prefixLen - suffixLen)
              ; Stamp validation: at least 15 chars, position 9 must be "-"
              If Len(mid) >= 15 And Mid(mid, 9, 1) = "-"
                AddElement(archives())
                archives() = dir + name
              EndIf
            EndIf
          EndIf
        EndIf
      EndIf
    Wend
    FinishDirectory(1)
  EndIf

  SortList(archives(), #PB_Sort_Ascending)

  Protected excess.i = ListSize(archives()) - g_LogKeepCount
  If excess > 0
    FirstElement(archives())
    Protected i.i
    For i = 1 To excess
      DeleteFile(archives())
      NextElement(archives())
    Next i
  EndIf

  FreeList(archives())
EndProcedure

; RotateLog(*fh, logPath.s) — close the current log, rename to archive, open new file
; *fh: address of g_LogFile or g_ErrorLogFile (untyped pointer; use PeekI/PokeI).
; Must be called inside g_LogMutex.
Procedure RotateLog(*fh, logPath.s)
  Protected fh.i = PeekI(*fh)
  If fh > 0
    FlushFileBuffers(fh)
    CloseFile(fh)
    PokeI(*fh, 0)
  EndIf

  Protected dir.s  = GetPathPart(logPath)
  Protected base.s = GetFilePart(logPath)
  Protected ext.s  = LCase(GetExtensionPart(base))
  Protected stem.s = Left(base, Len(base) - Bool(ext <> "") * (Len(ext) + 1))
  Protected archive.s
  If ext <> ""
    archive = dir + stem + "." + RotationStamp() + "." + ext
  Else
    archive = dir + stem + "." + RotationStamp()
  EndIf

  RenameFile(logPath, archive)
  PokeI(*fh, CreateFile(#PB_Any, logPath))
  PruneArchives(logPath)
EndProcedure

; LogRotationThread(*unused) — background thread: sleep to next UTC midnight, then rotate
; Outer loop: compute seconds-to-midnight, sleep 1s at a time checking g_StopRotation,
; then acquire g_LogMutex and rotate both open log files.
Procedure LogRotationThread(*unused)
  Protected secsLeft.q, elapsed.q, utcNow.q
  While g_StopRotation = 0
    ; Compute seconds until next UTC midnight (result: 1..86400)
    utcNow   = ConvertDate(Date(), #PB_Date_UTC)
    secsLeft = 86400 - (utcNow % 86400)

    ; Sleep until midnight, waking every second to check stop flag
    elapsed = 0
    While elapsed < secsLeft And g_StopRotation = 0
      Delay(1000)
      elapsed + 1
    Wend

    ; Rotate both log files (unless shutting down)
    If g_StopRotation = 0
      LockMutex(g_LogMutex)
      If g_LogFile > 0 And g_LogPath <> ""
        RotateLog(@g_LogFile, g_LogPath)
      EndIf
      If g_ErrorLogFile > 0 And g_ErrorLogPath <> ""
        RotateLog(@g_ErrorLogFile, g_ErrorLogPath)
      EndIf
      UnlockMutex(g_LogMutex)
    EndIf
  Wend
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
  g_LogPath = path
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
  g_ErrorLogPath = path
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
; Rotation: if g_LogMaxBytes > 0 and the log file meets or exceeds the threshold,
;   the file is rotated before this line is written.
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
  If g_LogMaxBytes > 0
    FlushFileBuffers(g_LogFile)
    If Lof(g_LogFile) >= g_LogMaxBytes
      RotateLog(@g_LogFile, g_LogPath)
    EndIf
  EndIf
  If g_LogFile > 0
    WriteStringN(g_LogFile, line, #PB_Ascii)
  EndIf
  UnlockMutex(g_LogMutex)
EndProcedure

; StartDailyRotation() — launch the daily midnight UTC rotation background thread.
; No-op if the thread is already running. Call after opening log files.
Procedure StartDailyRotation()
  If g_RotationThread = 0
    g_StopRotation   = 0
    g_RotationThread = CreateThread(@LogRotationThread(), 0)
  EndIf
EndProcedure

; StopDailyRotation() — signal the rotation thread to stop and wait for it to exit.
; Safe to call when no thread is running.
Procedure StopDailyRotation()
  If g_RotationThread > 0
    g_StopRotation = 1
    WaitThread(g_RotationThread)
    g_RotationThread = 0
  EndIf
EndProcedure

; LogError(level.s, message.s) — append one error log line
; level: "error" | "warn" | "info"
; No-op if no error log file is open, or if level is above g_LogLevel threshold.
; Level integers: error=1  warn=2  info=3
; A message is written when its integer <= g_LogLevel (e.g. threshold=2 logs error+warn).
; Rotation: same size-based policy as LogAccess, applied to the error log file.
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
  If g_LogMaxBytes > 0
    FlushFileBuffers(g_ErrorLogFile)
    If Lof(g_ErrorLogFile) >= g_LogMaxBytes
      RotateLog(@g_ErrorLogFile, g_ErrorLogPath)
    EndIf
  EndIf
  If g_ErrorLogFile > 0
    WriteStringN(g_ErrorLogFile, line, #PB_Ascii)
  EndIf
  UnlockMutex(g_LogMutex)
EndProcedure
