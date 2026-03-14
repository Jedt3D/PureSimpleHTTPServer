; test_logger.pb — Unit tests for Logger.pbi
; Phase F-1: CLF access log, error log, ApacheDate, log level filtering
; Phase F-2: Size-based rotation, archive naming, keep-count pruning
EnableExplicit
XIncludeFile "TestCommon.pbi"

Global g_TmpLog.s
Global g_TmpErrLog.s

ProcedureUnitStartup setup()
  g_TmpLog    = GetTemporaryDirectory() + "pshs_test_access.log"
  g_TmpErrLog = GetTemporaryDirectory() + "pshs_test_error.log"
  DeleteFile(g_TmpLog)
  DeleteFile(g_TmpErrLog)
EndProcedureUnit

ProcedureUnitShutdown teardown()
  StopDailyRotation()
  CloseLogFile()
  CloseErrorLog()
  g_LogMaxBytes  = 0   ; restore: don't leave rotation enabled for other tests
  g_LogKeepCount = 30
  DeleteFile(g_TmpLog)
  DeleteFile(g_TmpErrLog)
EndProcedureUnit

; --- Access log ---

ProcedureUnit Logger_OpenLogFile_ReturnsTrue()
  Assert(OpenLogFile(g_TmpLog) = #True, "OpenLogFile should return #True for valid path")
  CloseLogFile()
EndProcedureUnit

ProcedureUnit Logger_OpenLogFile_InvalidPath_ReturnsFalse()
  Assert(OpenLogFile("/nonexistent_dir_pshs_test/log.txt") = #False,
         "OpenLogFile should return #False for non-existent directory")
EndProcedureUnit

ProcedureUnit Logger_CloseLogFile_IsHarmless()
  CloseLogFile()  ; already closed — must not crash
  Assert(#True, "CloseLogFile on closed file should not crash")
EndProcedureUnit

ProcedureUnit Logger_LogAccess_NoOpWhenClosed()
  CloseLogFile()
  LogAccess("127.0.0.1", "GET", "/test.html", "HTTP/1.1", 200, 512, "", "")
  Assert(#True, "LogAccess with no log file open should not crash")
EndProcedureUnit

ProcedureUnit Logger_LogAccess_CLFFormat()
  Protected tmpLog.s = GetTemporaryDirectory() + "pshs_log_clf.log"
  DeleteFile(tmpLog)
  OpenLogFile(tmpLog)
  LogAccess("192.168.1.1", "GET", "/hello.html", "HTTP/1.1", 200, 512, "-", "TestAgent/1.0")
  CloseLogFile()

  Protected content.s = "", f.i = ReadFile(#PB_Any, tmpLog)
  If f > 0
    content = ReadString(f)
    CloseFile(f)
  EndIf
  DeleteFile(tmpLog)

  ; CLF Combined: IP - - [timestamp] "METHOD /path PROTO" STATUS BYTES "Referer" "UA"
  Assert(Left(content, 11) = "192.168.1.1",                         "CLF line should start with IP")
  Assert(FindString(content, " - - [")                         > 0, "CLF should have '- -' identifiers after IP")
  Assert(FindString(content, ~"\"GET /hello.html HTTP/1.1\"") > 0, "CLF request field should be quoted")
  Assert(FindString(content, " 200 ")                          > 0, "CLF should contain status code")
  Assert(FindString(content, "512")                            > 0, "CLF should contain byte count")
  Assert(FindString(content, ~"\"TestAgent/1.0\"")             > 0, "CLF should quote user agent")
EndProcedureUnit

ProcedureUnit Logger_LogAccess_ZeroBytesAsDash()
  Protected tmpLog.s = GetTemporaryDirectory() + "pshs_log_zero.log"
  DeleteFile(tmpLog)
  OpenLogFile(tmpLog)
  LogAccess("10.0.0.1", "GET", "/notfound", "HTTP/1.1", 404, 0, "", "")
  CloseLogFile()

  Protected content.s = "", f.i = ReadFile(#PB_Any, tmpLog)
  If f > 0
    content = ReadString(f)
    CloseFile(f)
  EndIf
  DeleteFile(tmpLog)

  Assert(FindString(content, " 404 - ") > 0, "Zero bytes should appear as '-' in CLF")
EndProcedureUnit

ProcedureUnit Logger_LogAccess_MultipleLines()
  Protected tmpLog.s = GetTemporaryDirectory() + "pshs_log_multi.log"
  DeleteFile(tmpLog)
  OpenLogFile(tmpLog)
  LogAccess("1.1.1.1", "GET", "/first.html",  "HTTP/1.1", 200, 100, "", "")
  LogAccess("2.2.2.2", "GET", "/second.html", "HTTP/1.1", 404, 0,   "", "")
  CloseLogFile()

  Protected content.s = "", f.i = ReadFile(#PB_Any, tmpLog)
  If f > 0
    While Not Eof(f)
      content + ReadString(f) + #LF$
    Wend
    CloseFile(f)
  EndIf
  DeleteFile(tmpLog)

  Assert(FindString(content, "/first.html")  > 0, "First log entry should be in file")
  Assert(FindString(content, "/second.html") > 0, "Second log entry should be in file")
EndProcedureUnit

; --- Error log ---

ProcedureUnit Logger_OpenErrorLog_ReturnsTrue()
  Assert(OpenErrorLog(g_TmpErrLog) = #True, "OpenErrorLog should return #True for valid path")
  CloseErrorLog()
EndProcedureUnit

ProcedureUnit Logger_OpenErrorLog_InvalidPath_ReturnsFalse()
  Assert(OpenErrorLog("/nonexistent_dir_pshs_test/error.txt") = #False,
         "OpenErrorLog should return #False for non-existent directory")
EndProcedureUnit

ProcedureUnit Logger_CloseErrorLog_IsHarmless()
  CloseErrorLog()  ; already closed — must not crash
  Assert(#True, "CloseErrorLog on closed file should not crash")
EndProcedureUnit

ProcedureUnit Logger_LogError_NoOpWhenClosed()
  CloseErrorLog()
  LogError("error", "This should not crash")
  Assert(#True, "LogError with no error log open should not crash")
EndProcedureUnit

ProcedureUnit Logger_LogError_WritesLine()
  Protected tmpLog.s = GetTemporaryDirectory() + "pshs_errlog_t1.log"
  DeleteFile(tmpLog)
  g_LogLevel = 3  ; info — accept all levels
  OpenErrorLog(tmpLog)
  LogError("error", "Something went wrong")
  CloseErrorLog()

  Protected content.s = "", f.i = ReadFile(#PB_Any, tmpLog)
  If f > 0
    content = ReadString(f)
    CloseFile(f)
  EndIf
  DeleteFile(tmpLog)

  ; Error log format: [timestamp] [level] [pid N] message
  Assert(Left(content, 1) = "[",                    "Error log line should start with '['")
  Assert(FindString(content, "] [error] [pid") > 0, "Error log should contain level and pid tags")
  Assert(FindString(content, "Something went wrong") > 0, "Error log should contain the message")
EndProcedureUnit

ProcedureUnit Logger_LogError_LevelFilter_BelowThreshold_Written()
  Protected tmpLog.s = GetTemporaryDirectory() + "pshs_errlog_t2.log"
  DeleteFile(tmpLog)
  g_LogLevel = 2  ; warn threshold — error (1) should still be written
  OpenErrorLog(tmpLog)
  LogError("error", "Critical failure")
  CloseErrorLog()

  Protected content.s = "", f.i = ReadFile(#PB_Any, tmpLog)
  If f > 0
    content = ReadString(f)
    CloseFile(f)
  EndIf
  DeleteFile(tmpLog)

  Assert(FindString(content, "Critical failure") > 0,
         "error-level message should be written when threshold=warn")
EndProcedureUnit

ProcedureUnit Logger_LogError_LevelFilter_AboveThreshold_Skipped()
  Protected tmpLog.s = GetTemporaryDirectory() + "pshs_errlog_t3.log"
  DeleteFile(tmpLog)
  g_LogLevel = 2  ; warn threshold — info (3) should be skipped
  OpenErrorLog(tmpLog)
  LogError("info", "Verbose detail")
  CloseErrorLog()

  Protected size.i = FileSize(tmpLog)
  DeleteFile(tmpLog)

  Assert(size = 0, "info-level message should be skipped when threshold=warn (file stays empty)")
EndProcedureUnit

; --- Rotation (F-2) ---

; CountArchives(dir.s, stem.s, ext.s) — count date-stamped archive files in dir
; Used by rotation tests to verify archive creation and pruning.
Procedure.i CountArchives(dir.s, stem.s, ext.s)
  Protected prefix.s   = stem + "."
  Protected suffix.s   = ""
  If ext <> "" : suffix = "." + LCase(ext) : EndIf
  Protected prefixLen.i = Len(prefix)
  Protected suffixLen.i = Len(suffix)
  Protected count.i = 0, name.s, mid.s

  If ExamineDirectory(2, dir, "*")
    While NextDirectoryEntry(2)
      If DirectoryEntryType(2) = #PB_DirectoryEntry_File
        name = DirectoryEntryName(2)
        If Len(name) > prefixLen + 14 + suffixLen
          If Left(name, prefixLen) = prefix
            If suffix = "" Or Right(name, suffixLen) = suffix
              mid = Mid(name, prefixLen + 1, Len(name) - prefixLen - suffixLen)
              If Len(mid) >= 15 And Mid(mid, 9, 1) = "-"
                count + 1
              EndIf
            EndIf
          EndIf
        EndIf
      EndIf
    Wend
    FinishDirectory(2)
  EndIf
  ProcedureReturn count
EndProcedure

ProcedureUnit Logger_Rotation_CreatesArchive()
  Protected tmpLog.s = GetTemporaryDirectory() + "pshs_rot_t1.log"
  Protected dir.s    = GetTemporaryDirectory()
  DeleteFile(tmpLog)
  g_LogMaxBytes  = 1     ; 1-byte threshold: any write triggers rotation on next call
  g_LogKeepCount = 10
  OpenLogFile(tmpLog)
  LogAccess("1.2.3.4", "GET", "/a", "HTTP/1.1", 200, 100, "", "")  ; fill the file
  LogAccess("1.2.3.4", "GET", "/b", "HTTP/1.1", 200, 100, "", "")  ; triggers rotation
  CloseLogFile()
  g_LogMaxBytes = 0

  Protected archives.i = CountArchives(dir, "pshs_rot_t1", "log")
  ; Clean up archives
  If ExamineDirectory(2, dir, "pshs_rot_t1.*")
    While NextDirectoryEntry(2) : DeleteFile(dir + DirectoryEntryName(2)) : Wend
    FinishDirectory(2)
  EndIf
  DeleteFile(tmpLog)

  Assert(archives >= 1, "At least one archive should be created after rotation")
EndProcedureUnit

ProcedureUnit Logger_Rotation_ArchiveHasDateStampFormat()
  Protected tmpLog.s = GetTemporaryDirectory() + "pshs_rot_t2.log"
  Protected dir.s    = GetTemporaryDirectory()
  DeleteFile(tmpLog)
  g_LogMaxBytes  = 1
  g_LogKeepCount = 10
  OpenLogFile(tmpLog)
  LogAccess("1.2.3.4", "GET", "/a", "HTTP/1.1", 200, 50, "", "")
  LogAccess("1.2.3.4", "GET", "/b", "HTTP/1.1", 200, 50, "", "")
  CloseLogFile()
  g_LogMaxBytes = 0

  ; Find the archive and check its name format: pshs_rot_t2.YYYYMMDD-HHMMSS-NNN.log
  Protected found.i = #False, name.s
  If ExamineDirectory(2, dir, "pshs_rot_t2.*")
    While NextDirectoryEntry(2)
      name = DirectoryEntryName(2)
      If name <> "pshs_rot_t2.log" And Left(name, 12) = "pshs_rot_t2."
        found = #True
        ; Verify mid part contains a dash at position 9
        Protected mid.s = Mid(name, 13, Len(name) - 12 - 4)  ; strip prefix and ".log"
        Assert(Len(mid) >= 15,          "Archive stamp should be at least 15 chars")
        Assert(Mid(mid, 9, 1) = "-",    "Archive stamp should have '-' at position 9")
      EndIf
    Wend
    FinishDirectory(2)
  EndIf
  ; Clean up
  If ExamineDirectory(2, dir, "pshs_rot_t2.*")
    While NextDirectoryEntry(2) : DeleteFile(dir + DirectoryEntryName(2)) : Wend
    FinishDirectory(2)
  EndIf
  DeleteFile(tmpLog)

  Assert(found, "An archive file with date-stamp name should exist")
EndProcedureUnit

ProcedureUnit Logger_Rotation_PrunesOldestArchives()
  Protected tmpLog.s = GetTemporaryDirectory() + "pshs_rot_t3.log"
  Protected dir.s    = GetTemporaryDirectory()
  DeleteFile(tmpLog)

  ; Pre-create two "old" fake archives (lexicographically before any real stamp)
  Protected fakeA.s = dir + "pshs_rot_t3.20200101-000000-000.log"
  Protected fakeB.s = dir + "pshs_rot_t3.20200101-000001-000.log"
  Protected fh.i = CreateFile(#PB_Any, fakeA) : If fh > 0 : CloseFile(fh) : EndIf
  fh = CreateFile(#PB_Any, fakeB) : If fh > 0 : CloseFile(fh) : EndIf

  g_LogMaxBytes  = 1
  g_LogKeepCount = 2   ; keep at most 2 archives total
  OpenLogFile(tmpLog)
  LogAccess("1.2.3.4", "GET", "/a", "HTTP/1.1", 200, 50, "", "")
  LogAccess("1.2.3.4", "GET", "/b", "HTTP/1.1", 200, 50, "", "")  ; triggers rotation → 3 archives → prune to 2
  CloseLogFile()
  g_LogMaxBytes = 0

  Protected archives.i = CountArchives(dir, "pshs_rot_t3", "log")
  ; Clean up
  If ExamineDirectory(2, dir, "pshs_rot_t3.*")
    While NextDirectoryEntry(2) : DeleteFile(dir + DirectoryEntryName(2)) : Wend
    FinishDirectory(2)
  EndIf
  DeleteFile(tmpLog)

  Assert(archives <= 2, "Archives should be pruned to g_LogKeepCount (2)")
EndProcedureUnit

ProcedureUnit Logger_Rotation_DisabledWhenMaxBytesZero()
  Protected tmpLog.s = GetTemporaryDirectory() + "pshs_rot_t4.log"
  Protected dir.s    = GetTemporaryDirectory()
  DeleteFile(tmpLog)
  g_LogMaxBytes  = 0   ; rotation disabled
  g_LogKeepCount = 10
  OpenLogFile(tmpLog)
  Protected i.i
  For i = 1 To 5
    LogAccess("1.2.3.4", "GET", "/page" + Str(i), "HTTP/1.1", 200, 1000, "", "")
  Next i
  CloseLogFile()

  Protected archives.i = CountArchives(dir, "pshs_rot_t4", "log")
  If ExamineDirectory(2, dir, "pshs_rot_t4.*")
    While NextDirectoryEntry(2) : DeleteFile(dir + DirectoryEntryName(2)) : Wend
    FinishDirectory(2)
  EndIf
  DeleteFile(tmpLog)

  Assert(archives = 0, "No archives should be created when rotation is disabled (g_LogMaxBytes=0)")
EndProcedureUnit

; --- SIGHUP log reopen (F-4) ---

ProcedureUnit Logger_ReopenLogs_FlagClearedAfterWrite()
  ; Set g_ReopenLogs = 1 and verify LogAccess clears it inside the mutex
  OpenLogFile(g_TmpLog)
  g_ReopenLogs = 1
  LogAccess("1.1.1.1", "GET", "/reopen", "HTTP/1.1", 200, 100, "", "")
  Protected flagAfter.i = g_ReopenLogs
  CloseLogFile()
  Assert(flagAfter = 0, "g_ReopenLogs should be cleared to 0 after LogAccess processes it")
EndProcedureUnit

ProcedureUnit Logger_ReopenLogs_NewFileReceivesEntry()
  ; Simulate logrotate: write entry A, rename log, set flag, write entry B
  ; Entry B should appear in the freshly created file at the original path
  Protected tmpLog.s  = GetTemporaryDirectory() + "pshs_reopen_t2.log"
  Protected oldLog.s  = GetTemporaryDirectory() + "pshs_reopen_t2.log.old"
  DeleteFile(tmpLog)
  DeleteFile(oldLog)

  OpenLogFile(tmpLog)
  LogAccess("1.1.1.1", "GET", "/before", "HTTP/1.1", 200, 10, "", "")
  FlushFileBuffers(g_LogFile)  ; ensure entry A is on disk

  ; Simulate logrotate renaming the log — server's file handle still points to old inode
  RenameFile(tmpLog, oldLog)

  ; Signal reopen: next write will close old handle, open new file at tmpLog
  g_ReopenLogs = 1
  LogAccess("2.2.2.2", "GET", "/after", "HTTP/1.1", 200, 20, "", "")
  CloseLogFile()

  ; New file should contain entry B ("/after"), not entry A ("/before")
  Protected newContent.s = "", f.i = ReadFile(#PB_Any, tmpLog)
  If f > 0 : newContent = ReadString(f) : CloseFile(f) : EndIf

  ; Old file should contain entry A ("/before")
  Protected oldContent.s = "", g.i = ReadFile(#PB_Any, oldLog)
  If g > 0 : oldContent = ReadString(g) : CloseFile(g) : EndIf

  DeleteFile(tmpLog)
  DeleteFile(oldLog)

  Assert(FindString(newContent, "/after")  > 0, "New log file should receive entry written after reopen")
  Assert(FindString(oldContent, "/before") > 0, "Renamed old file should retain entry written before reopen")
EndProcedureUnit

; --- Daily rotation thread (F-3) ---

ProcedureUnit Logger_StartDailyRotation_ThreadStarted()
  OpenLogFile(g_TmpLog)
  StartDailyRotation()
  Protected running.i = Bool(g_RotationThread > 0)
  StopDailyRotation()
  CloseLogFile()
  Assert(running,                 "StartDailyRotation should create a running thread")
  Assert(g_RotationThread = 0,    "StopDailyRotation should clear g_RotationThread")
EndProcedureUnit

ProcedureUnit Logger_StopDailyRotation_WhenNotStarted_IsHarmless()
  StopDailyRotation()  ; thread was never started — must not crash
  Assert(#True, "StopDailyRotation without prior start should not crash")
EndProcedureUnit

; --- ApacheDate ---

ProcedureUnit Logger_ApacheDate_Format()
  ; Trigger EnsureLogInit() so g_TZOffset is computed
  OpenLogFile(g_TmpLog)
  CloseLogFile()

  Protected result.s = ApacheDate(Date())

  ; Expected: [DD/Mon/YYYY:HH:MM:SS +HHMM]  (min 28 chars)
  Assert(Left(result, 1)  = "[", "ApacheDate should start with '['")
  Assert(Right(result, 1) = "]", "ApacheDate should end with ']'")
  Assert(FindString(result, "/")  > 0, "ApacheDate should contain '/' date separators")
  Assert(FindString(result, ":")  > 0, "ApacheDate should contain ':' time separators")
  Assert(Len(result) >= 28,           "ApacheDate minimum length: [DD/Mon/YYYY:HH:MM:SS +HHMM]")
EndProcedureUnit
