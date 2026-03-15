# Windows Installer & Portable Package Testing Checklist

## Phase A.5: Testing & Verification

This checklist is used to verify the Windows installer and portable package work correctly.

### Prerequisites

- [ ] PureBasic compiler installed at `C:\Program Files\PureBasic\`
- [ ] NSIS installed at `C:\Program Files\NSIS\`
- [ ] Windows 7 or later (test on multiple versions if possible)
- [ ] Administrator access (for service installation tests)

---

## A. Portable Package Tests

### Test A.1: Basic Extraction and Execution
**Steps:**
1. Extract `PureSimpleHTTPServer-{version}-windows-portable.zip` to a temp directory
2. Double-click `PureSimpleHTTPServer.exe`
3. Open browser to `http://localhost:8080`

**Expected Results:**
- [ ] Server starts without errors
- [ ] Console displays startup message with version
- [ ] Browser displays default page or file listing
- [ ] Server responds to HTTP requests

**Notes:** _______________________________________________________________

---

### Test A.2: Command-Line Arguments
**Steps:**
1. Open Command Prompt in portable directory
2. Run: `PureSimpleHTTPServer.exe --port 3000 --root wwwroot`
3. Open browser to `http://localhost:3000`

**Expected Results:**
- [ ] Server starts on port 3000
- [ ] Server serves from wwwroot directory
- [ ] No errors in console output

**Notes:** _______________________________________________________________

---

### Test A.3: Custom Root Directory
**Steps:**
1. Create test directory `C:\TestWeb` with `index.html`
2. Run: `PureSimpleHTTPServer.exe --root C:\TestWeb`
3. Open browser to `http://localhost:8080`

**Expected Results:**
- [ ] Server serves files from `C:\TestWeb`
- [ ] Custom index.html is displayed

**Notes:** _______________________________________________________________

---

### Test A.4: No Registry Entries
**Steps:**
1. Before running portable version, export registry:
   `reg export HKLM\Software before.reg`
2. Extract and run portable version
3. Stop server
4. Export registry: `reg export HKLM\Software after.reg`
5. Compare files: `fc before.reg after.reg`

**Expected Results:**
- [ ] No registry entries created
- [ ] before.reg and after.reg are identical

**Notes:** _______________________________________________________________

---

### Test A.5: Portable Deletion
**Steps:**
1. Extract portable package to temp directory
2. Run server, verify it works
3. Stop server
4. Delete entire portable directory

**Expected Results:**
- [ ] Directory can be deleted without errors
- [ ] No leftover files or registry entries
- [ ] No uninstaller needed

**Notes:** _______________________________________________________________

---

## B. Installer Tests

### Test B.1: Fresh Installation (All Components)
**Steps:**
1. Run `PureSimpleHTTPServer-{version}-windows-setup.exe`
2. Select all components (Main Files, Service, Start Menu, Desktop)
3. Complete installation

**Expected Results:**
- [ ] Installer launches without errors
- [ ] License agreement is displayed
- [ ] All components can be selected
- [ ] Installation completes successfully
- [ ] Success message is shown

**Notes:** _______________________________________________________________

---

### Test B.2: Installation Directory
**Steps:**
1. Start installer
2. Change installation directory to custom path
3. Complete installation

**Expected Results:**
- [ ] Custom directory is accepted
- [ ] Files are installed to custom location
- [ ] Shortcuts point to custom location

**Notes:** _______________________________________________________________

---

### Test B.3: Installation Without Service
**Steps:**
1. Start installer
2. DESELECT "Windows Service" component
3. Complete installation

**Expected Results:**
- [ ] Installation completes
- [ ] Service is NOT installed
- [ ] Application can be run from Start Menu

**Notes:** _______________________________________________________________

---

### Test B.4: Silent Installation
**Steps:**
1. Open Command Prompt as Administrator
2. Run: `PureSimpleHTTPServer-{version}-windows-setup.exe /S`
3. Check installation directory

**Expected Results:**
- [ ] Installer runs without GUI
- [ ] Files are installed to default location
- [ ] Installation completes silently

**Notes:** _______________________________________________________________

---

### Test B.5: Start Menu Shortcuts
**Steps:**
1. Complete installation with Start Menu component
2. Open Start Menu
3. Navigate to PureSimpleHTTPServer folder

**Expected Results:**
- [ ] Start Menu folder exists
- [ ] Application shortcut exists
- [ ] Uninstall shortcut exists
- [ ] Documentation shortcuts exist (README, Quick Start)
- [ ] Shortcuts launch correct targets

**Notes:** _______________________________________________________________

---

### Test B.6: Desktop Shortcut
**Steps:**
1. Install with Desktop Shortcut component
2. Check desktop

**Expected Results:**
- [ ] Desktop shortcut exists
- [ ] Shortcut has correct icon
- [ ] Double-clicking launches application

**Notes:** _______________________________________________________________

---

### Test B.7: Add/Remove Programs Entry
**Steps:**
1. Complete installation
2. Open Control Panel > Programs and Features
3. Find PureSimpleHTTPServer

**Expected Results:**
- [ ] Entry exists in Add/Remove Programs
- [ ] Display name is correct
- [ ] Version is displayed correctly
- [ ] Publisher information is shown
- [ ] Size is calculated
- [ ] Uninstall button works

**Notes:** _______________________________________________________________

---

### Test B.8: Uninstaller
**Steps:**
1. Install full version
2. Run Uninstaller from Start Menu or Add/Remove Programs
3. Confirm uninstallation

**Expected Results:**
- [ ] Uninstaller confirmation dialog appears
- [ ] All files are removed
- [ ] Start Menu shortcuts are removed
- [ ] Desktop shortcut is removed
- [ ] Registry entries are removed
- [ ] Installation directory is removed (if empty)

**Notes:** _______________________________________________________________

---

### Test B.9: Uninstaller Preserves User Data
**Steps:**
1. Install and add custom files to wwwroot
2. Run uninstaller
3. Choose "No" when asked to remove wwwroot

**Expected Results:**
- [ ] Confirmation dialog appears
- [ ] wwwroot directory is preserved
- [ ] User files remain intact

**Notes:** _______________________________________________________________

---

## C. Service Installation Tests

### Test C.1: Service Installation (with Admin)
**Steps:**
1. Run installer as Administrator
2. Select "Windows Service" component
3. Complete installation
4. Open Services MMC (`services.msc`)

**Expected Results:**
- [ ] Service "PureSimpleHTTPServer" exists
- [ ] Service display name is correct
- [ ] Service description is present
- [ ] Service startup type is Manual (default)
- [ ] Service executable path is correct

**Notes:** _______________________________________________________________

---

### Test C.2: Service Installation Fails without Admin
**Steps:**
1. Run installer WITHOUT Administrator privileges
2. Select "Windows Service" component
3. Complete installation

**Expected Results:**
- [ ] Installer shows warning about service installation
- [ ] Installation completes (service installation skipped)
- [ ] Application still runs as standalone

**Notes:** _______________________________________________________________

---

### Test C.3: Service Start/Stop
**Steps:**
1. Install service
2. Start service: `net start PureSimpleHTTPServer`
3. Browse to `http://localhost:8080`
4. Stop service: `net stop PureSimpleHTTPServer`

**Expected Results:**
- [ ] Service starts successfully
- [ ] Server responds to HTTP requests
- [ ] Service stops gracefully

**Notes:** _______________________________________________________________

---

### Test C.4: Service HTTP Requests
**Steps:**
1. Start service
2. Test various HTTP requests:
   - `GET http://localhost:8080/`
   - `GET http://localhost:8080/test.html`
   - `GET http://localhost:8080/nonexistent`

**Expected Results:**
- [ ] Normal files return 200
- [ ] Nonexistent files return 404
- [ ] Service handles multiple concurrent requests

**Notes:** _______________________________________________________________

---

## D. Upgrade Tests

### Test D.1: Upgrade Installation
**Steps:**
1. Install version N
2. Add custom configuration files
3. Install version N+1 over existing installation
4. Test server

**Expected Results:**
- [ ] Installer detects existing installation
- [ ] Configuration files are preserved
- [ ] Service is updated correctly
- [ ] New version runs without errors

**Notes:** _______________________________________________________________

---

## E. Cross-Version Compatibility Tests

### Test E.1: Windows 7
**Steps:**
1. Test installer and portable on Windows 7

**Expected Results:**
- [ ] Installer runs successfully
- [ ] Application runs correctly
- [ ] All features work

**Notes:** _______________________________________________________________

---

### Test E.2: Windows 10
**Steps:**
1. Test installer and portable on Windows 10

**Expected Results:**
- [ ] Installer runs successfully
- [ ] Application runs correctly
- [ ] All features work

**Notes:** _______________________________________________________________

---

### Test E.3: Windows 11
**Steps:**
1. Test installer and portable on Windows 11

**Expected Results:**
- [ ] Installer runs successfully
- [ ] Application runs correctly
- [ ] All features work

**Notes:** _______________________________________________________________

---

## F. Documentation Tests

### Test F.1: README.txt Accuracy
**Steps:**
1. Read README.txt
2. Follow instructions
3. Verify all examples work

**Expected Results:**
- [ ] All instructions are accurate
- [ ] All examples work as documented
- [ ] No missing information

**Notes:** _______________________________________________________________

---

### Test F.2: quickstart.txt Clarity
**Steps:**
1. Read quickstart.txt
2. Follow getting started guide

**Expected Results:**
- [ ] Guide is clear and easy to follow
- [ ] New users can start server successfully

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
