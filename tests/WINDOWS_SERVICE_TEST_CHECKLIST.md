# Windows Service Integration Testing Checklist

## Phase C.5: Windows Service Testing & Verification

This checklist is used to verify the Windows Service integration works correctly.

### Prerequisites

- [ ] PureBasic compiler installed
- [ ] Windows 7 or later (Windows 10/11 recommended)
- [ ] Administrator access (for service installation)
- [ ] Built PureSimpleHTTPServer.exe

---

## A. Service Installation Tests

### Test A.1: Service Installation (with Admin)
**Steps:**
1. Open Command Prompt as Administrator
2. Run: `PureSimpleHTTPServer.exe --install`
3. Open Services MMC (`services.msc`)
4. Find "PureSimpleHTTPServer" in the list

**Expected Results:**
- [ ] Command prints "Service installed successfully"
- [ ] Service appears in Services MMC
- [ ] Service display name is "PureSimple HTTP Server"
- [ ] Service startup type is "Manual"
- [ ] Service executable path is correct
- [ ] Service status is "Stopped"

**Notes:** _______________________________________________________________

---

### Test A.2: Service Installation Fails without Admin
**Steps:**
1. Open Command Prompt WITHOUT Administrator privileges
2. Run: `PureSimpleHTTPServer.exe --install`

**Expected Results:**
- [ ] Command prints "ERROR: Failed to install service"
- [ ] Message indicates Administrator privileges required
- [ ] Service is NOT installed

**Notes:** _______________________________________________________________

---

### Test A.3: Service Installation with Custom Name
**Steps:**
1. Open Command Prompt as Administrator
2. Run: `PureSimpleHTTPServer.exe --install --service-name MyWebServer`
3. Check Services MMC for "MyWebServer"

**Expected Results:**
- [ ] Service installed with custom name
- [ ] Service appears as "MyWebServer" in Services MMC

**Notes:** _______________________________________________________________

---

## B. Service Lifecycle Tests

### Test B.1: Service Start (via CLI)
**Steps:**
1. Install service (if not already installed)
2. Run: `PureSimpleHTTPServer.exe --start`
3. Check service status in Services MMC
4. Browse to `http://localhost:8080`

**Expected Results:**
- [ ] Service status changes to "Running"
- [ ] Server responds to HTTP requests
- [ ] Default page or file listing is displayed
- [ ] No errors in Event Viewer

**Notes:** _______________________________________________________________

---

### Test B.2: Service Start (via net start)
**Steps:**
1. Ensure service is installed and stopped
2. Run: `net start PureSimpleHTTPServer`
3. Browse to `http://localhost:8080`

**Expected Results:**
- [ ] Service starts successfully
- [ ] Server responds to HTTP requests

**Notes:** _______________________________________________________________

---

### Test B.3: Service HTTP Requests
**Steps:**
1. Start service
2. Test various HTTP requests:
   - `GET http://localhost:8080/`
   - `GET http://localhost:8080/test.html`
   - `GET http://localhost:8080/nonexistent`
3. Check Event Viewer for service startup event

**Expected Results:**
- [ ] Normal files return 200
- [ ] Nonexistent files return 404
- [ ] Service handles multiple concurrent requests
- [ ] Event Viewer shows "Service started successfully" event

**Notes:** _______________________________________________________________

---

### Test B.4: Service Stop (via CLI)
**Steps:**
1. Ensure service is running
2. Run: `PureSimpleHTTPServer.exe --stop`
3. Check service status in Services MMC

**Expected Results:**
- [ ] Service status changes to "Stopped"
- [ ] Active connections are closed gracefully
- [ ] No errors in Event Viewer

**Notes:** _______________________________________________________________

---

### Test B.5: Service Stop (via net stop)
**Steps:**
1. Ensure service is running
2. Run: `net stop PureSimpleHTTPServer`
3. Check service status

**Expected Results:**
- [ ] Service stops successfully
- [ ] No errors in Event Viewer

**Notes:** _______________________________________________________________

---

### Test B.6: Service Survives System Reboot
**Steps:**
1. Install service
2. Change service startup type to "Automatic" via Services MMC
3. Reboot computer
4. Check service status after reboot
5. Browse to `http://localhost:8080`

**Expected Results:**
- [ ] Service starts automatically after reboot
- [ ] Server responds to HTTP requests

**Notes:** _______________________________________________________________

---

### Test B.7: Service Shutdown on System Shutdown
**Steps:**
1. Start service
2. Make HTTP request to verify it's working
3. Shutdown/restart computer
4. Check Event Viewer → System logs

**Expected Results:**
- [ ] Service stops gracefully when system shuts down
- [ ] No errors or warnings in Event Viewer
- [ ] Service starts cleanly on next boot

**Notes:** _______________________________________________________________

---

## C. Service Command Tests

### Test C.1: --install Flag Works
**Steps:**
1. Uninstall any existing service
2. Run: `PureSimpleHTTPServer.exe --install`
3. Verify service exists

**Expected Results:**
- [ ] Service is installed
- [ ] Command exits with code 0

**Notes:** _______________________________________________________________

---

### Test C.2: --uninstall Flag Works
**Steps:**
1. Install service
2. Run: `PureSimpleHTTPServer.exe --uninstall`
3. Verify service removed from Services MMC

**Expected Results:**
- [ ] Service is removed
- [ ] Command prints "Service uninstalled successfully"
- [ ] Command exits with code 0

**Notes:** _______________________________________________________________

---

### Test C.3: --start Flag Works
**Steps:**
1. Install service
2. Ensure service is stopped
3. Run: `PureSimpleHTTPServer.exe --start`

**Expected Results:**
- [ ] Service starts
- [ ] Command exits with code 0

**Notes:** _______________________________________________________________

---

### Test C.4: --stop Flag Works
**Steps:**
1. Install and start service
2. Run: `PureSimpleHTTPServer.exe --stop`

**Expected Results:**
- [ ] Service stops
- [ ] Command exits with code 0

**Notes:** _______________________________________________________________

---

## D. Event Log Tests

### Test D.1: Service Startup Logged
**Steps:**
1. Open Event Viewer (Windows Logs → Application)
2. Start service
3. Refresh Event Viewer
4. Look for "PureSimpleHTTPServer" source

**Expected Results:**
- [ ] Event logged with source "PureSimpleHTTPServer"
- [ ] Event ID is 1
- [ ] Event type is "Information"
- [ ] Message contains "Service started successfully"

**Notes:** _______________________________________________________________

---

### Test D.2: Service Shutdown Logged
**Steps:**
1. Start service
2. Stop service
3. Check Event Viewer

**Expected Results:**
- [ ] Event logged with source "PureSimpleHTTPServer"
- [ ] Event ID is 4
- [ ] Event type is "Information"
- [ ] Message contains service shutdown information

**Notes:** _______________________________________________________________

---

### Test D.3: Errors Logged
**Steps:**
1. Corrupt wwwroot directory (make it inaccessible)
2. Start service
3. Check Event Viewer for errors

**Expected Results:**
- [ ] Error events logged
- [ ] Event type is "Error"
- [ ] Error message is descriptive

**Notes:** _______________________________________________________________

---

## E. Backward Compatibility Tests

### Test E.1: Standalone Mode Still Works
**Steps:**
1. Run: `PureSimpleHTTPServer.exe` (without --service)
2. Browse to `http://localhost:8080`

**Expected Results:**
- [ ] Server starts in standalone mode
- [ ] Server responds to HTTP requests
- [ ] Console shows startup message
- [ ] Pressing Ctrl+C stops the server

**Notes:** _______________________________________________________________

---

### Test E.2: All Existing CLI Flags Work in Standalone Mode
**Steps:**
1. Run: `PureSimpleHTTPServer.exe --port 3000 --root wwwroot --browse`
2. Browse to `http://localhost:3000`

**Expected Results:**
- [ ] All flags work as expected
- [ ] Server starts on custom port
- [ ] Directory browsing enabled
- [ ] No breaking changes

**Notes:** _______________________________________________________________

---

### Test E.3: --service Flag Activates Service Mode
**Steps:**
1. Run: `PureSimpleHTTPServer.exe --service` (without installing service first)

**Expected Results:**
- [ ] Server attempts to connect to Service Control Manager
- [ ] Fails gracefully if service not installed
- [ ] Appropriate error message shown

**Notes:** _______________________________________________________________

---

## F. Configuration Tests

### Test F.1: Service Uses Default Configuration
**Steps:**
1. Install and start service
2. Place test.html in wwwroot
3. Browse to `http://localhost:8080/test.html`

**Expected Results:**
- [ ] Service uses default port 8080
- [ ] Service serves from wwwroot
- [ ] test.html is served correctly

**Notes:** _______________________________________________________________

---

### Test F.2: Custom Service Name
**Steps:**
1. Install with custom name: `--install --service-name MyService`
2. Start: `--start --service-name MyService`
3. Stop: `--stop --service-name MyService`
4. Uninstall: `--uninstall --service-name MyService`

**Expected Results:**
- [ ] All commands work with custom service name
- [ ] Service appears with custom name in Services MMC

**Notes:** _______________________________________________________________

---

## G. Stress Tests

### Test G.1: Multiple Concurrent Requests
**Steps:**
1. Start service
2. Run Apache Bench: `ab -n 1000 -c 10 http://127.0.0.1:8080/`
3. Check Event Viewer for errors

**Expected Results:**
- [ ] Service handles 1000 requests
- [ ] No crashes or errors
- [ ] Response time is acceptable (< 100ms average)

**Notes:** _______________________________________________________________

---

### Test G.2: Long-Running Service Stability
**Steps:**
1. Start service
2. Make periodic HTTP requests over 1 hour
3. Monitor service stability
4. Check memory usage

**Expected Results:**
- [ ] Service remains stable
- [ ] No memory leaks
- [ ] Response times remain consistent

**Notes:** _______________________________________________________________

---

## Summary

**Total Tests:** ___
**Passed:** ___
**Failed:** ___
**Blocked:** ___

**Overall Status:** [ ] PASS [ ] FAIL

**Tester:** ___________________
**Date:** ___________________
**Windows Version:** ___________________
**Build Version:** ___________________

---

## Additional Notes

___________________________________________________________________________________
___________________________________________________________________________________
___________________________________________________________________________________
___________________________________________________________________________________
