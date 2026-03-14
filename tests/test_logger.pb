; test_logger.pb — Unit tests for Logger.pbi
; Phase F-1: CLF access log, error log, ApacheDate, log level filtering
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
  CloseLogFile()
  CloseErrorLog()
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
