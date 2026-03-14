; test_logger.pb — Unit tests for Logger.pbi
; Phase E: full tests for OpenLogFile, LogAccess, CloseLogFile
EnableExplicit
XIncludeFile "TestCommon.pbi"

Global g_TmpLog.s

ProcedureUnitStartup setup()
  g_TmpLog = GetTemporaryDirectory() + "pshs_test_logger.log"
  DeleteFile(g_TmpLog)
EndProcedureUnit

ProcedureUnitShutdown teardown()
  CloseLogFile()
  DeleteFile(g_TmpLog)
EndProcedureUnit

ProcedureUnit Logger_OpenFile_ReturnsTrue()
  Assert(OpenLogFile(g_TmpLog) = #True, "OpenLogFile should return #True for valid path")
  CloseLogFile()
EndProcedureUnit

ProcedureUnit Logger_OpenInvalidPath_ReturnsFalse()
  Assert(OpenLogFile("/nonexistent_dir_pshs_test/log.txt") = #False,
         "OpenLogFile should return #False for non-existent directory")
EndProcedureUnit

ProcedureUnit Logger_CloseWithoutOpen_IsHarmless()
  CloseLogFile()  ; g_LogFile may already be 0 — must not crash
  Assert(#True, "CloseLogFile on closed file should not crash")
EndProcedureUnit

ProcedureUnit Logger_LogAccess_NoOpWhenClosed()
  CloseLogFile()  ; ensure no file is open
  LogAccess("GET", "/test.html", 200, 512, "127.0.0.1")
  Assert(#True, "LogAccess with no log file open should not crash")
EndProcedureUnit

ProcedureUnit Logger_LogLine_ContainsFields()
  Protected tmpLog.s = GetTemporaryDirectory() + "pshs_log_t5.log"
  DeleteFile(tmpLog)
  OpenLogFile(tmpLog)
  LogAccess("GET", "/hello.html", 200, 512, "192.168.1.1")
  CloseLogFile()

  Protected content.s = "", f.i
  f = ReadFile(#PB_Any, tmpLog)
  If f > 0
    While Not Eof(f)
      content = content + ReadString(f) + #LF$
    Wend
    CloseFile(f)
  EndIf
  DeleteFile(tmpLog)

  Assert(FindString(content, "GET")         > 0, "Log line should contain method")
  Assert(FindString(content, "/hello.html") > 0, "Log line should contain path")
  Assert(FindString(content, "200")         > 0, "Log line should contain status code")
  Assert(FindString(content, "192.168.1.1") > 0, "Log line should contain client IP")
EndProcedureUnit

ProcedureUnit Logger_LogLine_StartsWithTimestamp()
  Protected tmpLog.s = GetTemporaryDirectory() + "pshs_log_t6.log"
  DeleteFile(tmpLog)
  OpenLogFile(tmpLog)
  LogAccess("POST", "/api/submit", 404, 0, "10.0.0.1")
  CloseLogFile()

  Protected line.s = "", f.i
  f = ReadFile(#PB_Any, tmpLog)
  If f > 0
    line = ReadString(f)
    CloseFile(f)
  EndIf
  DeleteFile(tmpLog)

  ; Format: [YYYY-MM-DD HH:MM:SS] IP METHOD /path STATUS BYTES
  Assert(Left(line, 1) = "[",                "Log line should start with '['")
  Assert(FindString(line, "] 10.0.0.1") > 0, "IP should follow closing ']'")
  Assert(FindString(line, "POST")        > 0, "Method should appear in log line")
  Assert(FindString(line, "404")         > 0, "Status code should appear in log line")
EndProcedureUnit

ProcedureUnit Logger_MultipleLines_BothWritten()
  Protected tmpLog.s = GetTemporaryDirectory() + "pshs_log_t7.log"
  DeleteFile(tmpLog)
  OpenLogFile(tmpLog)
  LogAccess("GET", "/first.html",  200, 100, "1.1.1.1")
  LogAccess("GET", "/second.html", 404, 0,   "2.2.2.2")
  CloseLogFile()

  Protected content.s = "", f.i
  f = ReadFile(#PB_Any, tmpLog)
  If f > 0
    While Not Eof(f)
      content = content + ReadString(f) + #LF$
    Wend
    CloseFile(f)
  EndIf
  DeleteFile(tmpLog)

  Assert(FindString(content, "/first.html")  > 0, "First log entry should be in file")
  Assert(FindString(content, "/second.html") > 0, "Second log entry should be in file")
EndProcedureUnit
