; SignalHandler.pbi — POSIX signal handling for log reopen on SIGHUP
; Include with: XIncludeFile "SignalHandler.pbi"
; Provides: InstallSignalHandlers(), RemoveSignalHandlers()
;
; Phase F-4: logrotate integration via SIGHUP
;
; On SIGHUP (signal 1), sets g_ReopenLogs = 1.
; Logger.pbi's LogAccess() and LogError() detect this flag inside g_LogMutex
; and reopen both log files, allowing logrotate to rename the old logs freely.
;
; logrotate config snippet (/etc/logrotate.d/puresimplehttpserver):
;   /var/log/pshs/access.log /var/log/pshs/error.log {
;       daily
;       rotate 30
;       compress
;       delaycompress
;       missingok
;       notifempty
;       sharedscripts
;       postrotate
;           kill -HUP $(cat /var/run/pshs.pid) 2>/dev/null || true
;       endscript
;   }
;
; Windows: SIGHUP does not exist; InstallSignalHandlers() and
;   RemoveSignalHandlers() are no-ops. Use built-in F-2/F-3 rotation instead.
;
; Dependencies (managed by main.pb and tests/TestCommon.pbi): Logger.pbi (g_ReopenLogs)

CompilerIf #PB_Compiler_OS = #PB_OS_Linux Or #PB_Compiler_OS = #PB_OS_MacOS

  #SIGHUP  = 1   ; POSIX — same value on macOS and Linux
  #SIG_DFL = 0   ; default signal disposition

  ImportC ""
    signal.i(signum.i, *handler)
  EndImport

  ; SIGHUPHandler — async signal handler; only safe operation: set an integer flag
  Procedure SIGHUPHandler(signum.i)
    g_ReopenLogs = 1
  EndProcedure

  ; InstallSignalHandlers() — install SIGHUP handler
  ; Call once at startup, before StartServer().
  Procedure InstallSignalHandlers()
    signal(#SIGHUP, @SIGHUPHandler())
  EndProcedure

  ; RemoveSignalHandlers() — restore SIGHUP to default disposition
  ; Call at shutdown, before CloseLogFile().
  Procedure RemoveSignalHandlers()
    signal(#SIGHUP, #SIG_DFL)
  EndProcedure

CompilerElse

  ; Windows stubs — SIGHUP not available
  Procedure InstallSignalHandlers()
  EndProcedure

  Procedure RemoveSignalHandlers()
  EndProcedure

CompilerEndIf
