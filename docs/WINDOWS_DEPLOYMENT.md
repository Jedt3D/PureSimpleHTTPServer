# Windows Deployment Guide — PureSimpleHTTPServer

**Version:** 1.6.0
**Platform:** Windows 7/8/10/11 and Server editions
**Status:** Production Ready

---

## Table of Contents

1. [Overview](#overview)
2. [Installation Methods](#installation-methods)
3. [Windows Service](#windows-service)
4. [Configuration](#configuration)
5. [Management](#management)
6. [Troubleshooting](#troubleshooting)
7. [Security](#security)
8. [Performance](#performance)

---

## Overview

PureSimpleHTTPServer v1.6.0 includes comprehensive Windows deployment support:

- ✅ **Professional installer** with GUI
- ✅ **Portable package** (no installation required)
- ✅ **Windows Service** integration
- ✅ **Event Log** integration
- ✅ **Automated build scripts**
- ✅ **Service lifecycle management**

---

## Installation Methods

### Method 1: NSIS Installer (Recommended)

**File:** `PureSimpleHTTPServer-{version}-windows-setup.exe`

**Features:**
- GUI wizard with license agreement
- Component selection (Main Files, Service, Start Menu, Desktop)
- Installation directory selection
- Silent installation support
- Automatic uninstaller

**Installation Steps:**

1. **Download** the installer from [Releases](https://github.com/Jedt3D/PureSimpleHTTPServer/releases)

2. **Run** the installer (Right-click → "Run as administrator")

3. **Follow the wizard:**
   - Accept license agreement
   - Select components:
     - **Main Files** (required)
     - **Windows Service** (optional, requires admin)
     - **Start Menu Shortcuts** (recommended)
     - **Desktop Shortcut** (optional)
   - Choose installation directory (default: `C:\Program Files\PureSimpleHTTPServer`)
   - Click **Install**

4. **Complete installation:**
   - Click **Finish** when done
   - Service is installed but NOT started (manual startup)

**Silent Installation:**

```batch
PureSimpleHTTPServer-{version}-windows-setup.exe /S /D=C:\MyInstallation
```

- `/S` - Silent mode
- `/D` - Custom installation directory

---

### Method 2: Portable Package

**File:** `PureSimpleHTTPServer-{version}-windows-portable.zip`

**Installation Steps:**

1. **Download** the portable ZIP

2. **Extract** to any directory:
   ```
   C:\MyWebServer\
   ├── PureSimpleHTTPServer.exe
   ├── wwwroot\
   │   └── index.html
   ├── README.txt
   ├── LICENSE.txt
   └── quickstart.txt
   ```

3. **Run** the server:
   - Double-click `PureSimpleHTTPServer.exe`
   - Or use Command Prompt:
     ```batch
     cd C:\MyWebServer
     PureSimpleHTTPServer.exe
     ```

**Advantages:**
- ✅ No installation required
- ✅ No registry entries
- ✅ Can run from USB drive
- ✅ Easy to remove (just delete directory)

**Disadvantages:**
- ❌ Manual startup required
- ❌ No auto-start on boot
- ❌ No Windows Service support

---

### Method 3: Build from Source

**Requirements:**
- PureBasic 6.x installed
- Git (to clone repository)

**Build Steps:**

1. **Clone repository:**
   ```batch
   git clone https://github.com/Jedt3D/PureSimpleHTTPServer.git
   cd PureSimpleHTTPServer
   ```

2. **Run build script:**
   ```batch
   build.bat
   ```

3. **Create packages (optional):**
   ```batch
   package.bat
   ```

**Output:**
- `dist\PureSimpleHTTPServer.exe` - Compiled executable
- `dist\PureSimpleHTTPServer-{version}-windows-portable.zip` - Portable package
- `dist\PureSimpleHTTPServer-{version}-windows-setup.exe` - Installer

---

## Windows Service

### Overview

Windows Service allows PureSimpleHTTPServer to run in the background without requiring a user to be logged in.

**Key Benefits:**
- ✅ **Automatic startup** on system boot
- ✅ **Runs in background** (no console window)
- ✅ **Survives user logoff** - continues running when users log off
- ✅ **Professional management** via Services MMC
- ✅ **Event logging** to Windows Event Viewer
- ✅ **Graceful shutdown** on system shutdown

### Installation

#### Prerequisites
- **Administrator privileges** required
- Windows 7 or later
- PureSimpleHTTPServer v1.6.0 or later

#### Install Service

**Method 1: Using CLI (recommended)**
```batch
cd C:\Program Files\PureSimpleHTTPServer
PureSimpleHTTPServer.exe --install
```

**Method 2: Using NSIS installer**
- During installation, select "Windows Service" component
- Service will be installed automatically

**Expected Output:**
```
Service installed successfully: PureSimpleHTTPServer

Start the service with:
  net start PureSimpleHTTPServer
  Or: PureSimpleHTTPServer.exe --start

Stop the service with:
  net stop PureSimpleHTTPServer
  Or: PureSimpleHTTPServer.exe --stop

Uninstall the service with:
  PureSimpleHTTPServer.exe --uninstall
```

#### Service Details

- **Service Name:** `PureSimpleHTTPServer`
- **Display Name:** `PureSimple HTTP Server`
- **Description:** `Lightweight HTTP/1.1 static file server`
- **Service Type:** Win32 Own Process
- **Startup Type:** Manual (default)
- **Account:** Local System

### Management

#### Start Service

**Method 1: Command Prompt (as Admin)**
```batch
net start PureSimpleHTTPServer
```

**Method 2: PureSimpleHTTPServer CLI**
```batch
PureSimpleHTTPServer.exe --start
```

**Method 3: Services MMC**
1. Press `Win + R`, type: `services.msc`
2. Find "PureSimple HTTP Server"
3. Right-click → **Start**

**Expected Output:**
```
The PureSimple HTTP Server service is starting.
The PureSimpleHTTPServer service was started successfully.
```

#### Stop Service

**Method 1: Command Prompt (as Admin)**
```batch
net stop PureSimpleHTTPServer
```

**Method 2: PureSimpleHTTPServer CLI**
```batch
PureSimpleHTTPServer.exe --stop
```

**Method 3: Services MMC**
1. Open `services.msc`
2. Find "PureSimple HTTP Server"
3. Right-click → **Stop**

**Expected Output:**
```
The PureSimpleHTTPServer service is stopping.
The PureSimpleHTTPServer service was stopped successfully.
```

#### Check Service Status

```batch
sc query PureSimpleHTTPServer
```

**Output:**
```
SERVICE_NAME: PureSimpleHTTPServer
        TYPE               : 10  WIN32_OWN_PROCESS
        STATE              : 4  RUNNING
        WIN32_EXIT_CODE    : 0  (0x0)
        SERVICE_EXIT_CODE   : 0  (0x0)
        CHECKPOINT          : 0x0
        WAIT_HINT           : 0x0
```

**State Values:**
- `1` - Stopped
- `2` - Start pending
- `3` - Stop pending
- `4` - Running

### Automatic Startup on Boot

#### Configure Auto-Start

1. **Open Services MMC:**
   - Press `Win + R`
   - Type: `services.msc`

2. **Find service:**
   - Locate "PureSimple HTTP Server"

3. **Open Properties:**
   - Right-click → **Properties**

4. **Set Startup type:**
   - Change **Startup type** to **Automatic**
   - Click **Apply**

5. **Start service:**
   - Click **Start** button

**Service will now start automatically on system boot!**

#### Delayed Start (Recommended)

To prevent service startup issues:

1. Open service Properties
2. Set **Startup type** to **Automatic (Delayed Start)**
3. Click **Apply**

This waits 2 minutes after system boot before starting the service.

### Event Logging

Service events are logged to **Windows Event Viewer**:

#### View Logs

1. **Open Event Viewer:**
   - Press `Win + R`
   - Type: `eventvwr.msc`

2. **Navigate:**
   - **Windows Logs** → **Application**

3. **Filter by source:**
   - In right panel, click **Filter Current Log**
   - Select **Event sources**: `PureSimpleHTTPServer`

#### Event IDs

| Event ID | Type | Description |
|----------|------|-------------|
| **1** | Information | Service started successfully |
| **2** | Error | Service failed to start |
| **3** | Error | Failed to connect to Service Control Manager |
| **4** | Information | Service stopped |

#### Example Events

**Successful Start:**
```
Log Name:      Application
Source:        PureSimpleHTTPServer
Date:          3/15/2026 2:11:00 PM
Event ID:      1
Task Category: None
Level:         Information
Keywords:      Classic
User:          SYSTEM
Computer:      DESKTOP-ABC123
Description:
PureSimpleHTTPServer service started successfully
```

**Service Failed:**
```
Log Name:      Application
Source:        PureSimpleHTTPServer
Date:          3/15/2026 2:15:00 PM
Event ID:      2
Task Category: None
Level:         Error
Keywords:      Classic
User:          SYSTEM
Computer:      DESKTOP-ABC123
Description:
PureSimpleHTTPServer service failed to start
Port 8080 already in use
```

### Uninstallation

#### Uninstall Service

**Method 1: Using CLI (recommended)**
```batch
cd C:\Program Files\PureSimpleHTTPServer
PureSimpleHTTPServer.exe --uninstall
```

**Method 2: Services MMC**
1. Open `services.msc`
2. Find "PureSimple HTTP Server"
3. Right-click → **Delete**

**Method 3: Command Prompt**
```batch
sc delete PureSimpleHTTPServer
```

**Expected Output:**
```
Service uninstalled successfully: PureSimpleHTTPServer
```

#### Full Uninstallation

**Using NSIS uninstaller:**
1. **Control Panel** → **Programs and Features**
2. Find **PureSimpleHTTPServer**
3. Click **Uninstall**

**Manual cleanup (if needed):**
```batch
REM Stop service
net stop PureSimpleHTTPServer

REM Uninstall service
PureSimpleHTTPServer.exe --uninstall

REM Remove installation directory
rmdir /s /q "C:\Program Files\PureSimpleHTTPServer"
```

---

## Configuration

### Default Configuration

**When running as Windows Service (v1.6.0):**
- **Port:** 8080 (hardcoded)
- **Root Directory:** `wwwroot/` (relative to executable)
- **Log Files:** None (by default)
- **Startup Type:** Manual

**Current Limitations:**
- Service mode doesn't support CLI flags (`--port`, `--root`, etc.)
- Configuration is hardcoded in `WindowsService.pbi`
- Future versions will support config files

### Configure Port (Advanced)

To change the service port:

1. **Uninstall service:**
   ```batch
   PureSimpleHTTPServer.exe --uninstall
   ```

2. **Edit `src/WindowsService.pbi`:**
   ```purebasic
   ; Find ServiceMain() procedure (around line 350)
   ; Change this line:
   Protected serverPort.i = 8080
   ; To desired port:
   Protected serverPort.i = 3000
   ```

3. **Recompile:**
   ```batch
   build.bat
   ```

4. **Reinstall service:**
   ```batch
   PureSimpleHTTPServer.exe --install
   ```

### Configure Root Directory (Advanced)

**Option 1: Symlink (Recommended)**
```batch
REM Create symlink to custom directory
mklink /D "C:\Program Files\PureSimpleHTTPServer\wwwroot" "C:\MyWebsite"
```

**Option 2: Copy files**
```batch
REM Copy files to default location
xcopy /E /I "C:\MyWebsite\*" "C:\Program Files\PureSimpleHTTPServer\wwwroot\"
```

### Configure Logging

**Current limitation:** Service doesn't support log file configuration

**Workaround:** Use standalone mode with logging:
```batch
REM Run as standalone with logging
PureSimpleHTTPServer.exe --log access.log --error-log error.log
```

Or modify `WindowsService.pbi` to add logging configuration.

---

## Management

### Command-Line Interface

#### Service Management Commands

| Command | Description | Requires Admin |
|---------|-------------|----------------|
| `--install` | Install Windows service | Yes |
| `--uninstall` | Remove Windows service | Yes |
| `--start` | Start service | No |
| `--stop` | Stop service | No |
| `--service` | Run as service (used by SCM) | N/A |
| `--service-name NAME` | Custom service name | Yes |

#### Server Configuration Commands

| Flag | Default | Description |
|------|---------|-------------|
| `--port N` | 8080 | TCP port |
| `--root DIR` | wwwroot/ | Document root |
| `--browse` | off | Directory listing |
| `--spa` | off | SPA mode |
| `--log FILE` | *(disabled)* | Access log |
| `--error-log FILE` | *(disabled)* | Error log |
| `--log-level LEVEL` | warn | Log level (none/error/warn/info) |
| `--clean-urls` | off | Extensionless paths try .html |
| `--rewrite FILE` | *(disabled)* | Rewrite rules file |

**Note:** Configuration flags work in **standalone mode only** (v1.6.0). Service mode uses hardcoded defaults.

### Services MMC

Open **Services MMC** to manage the service:

**Launch:**
- `Win + R` → `services.msc`
- Or: **Control Panel** → **Administrative Tools** → **Services**

**Management Options:**
- **Start/Stop** service
- **Configure startup type** (Manual/Automatic/Disabled)
- **Recovery actions** (on failure)
- **Dependencies** (none configured)
- **Run as** (Local System)

### PowerShell Management

#### Install Service
```powershell
cd "C:\Program Files\PureSimpleHTTPServer"
.\PureSimpleHTTPServer.exe --install
```

#### Query Service Status
```powershell
Get-Service -Name "PureSimpleHTTPServer"
```

#### Start Service
```powershell
Start-Service -Name "PureSimpleHTTPServer"
```

#### Stop Service
```powershell
Stop-Service -Name "PureSimpleHTTPServer"
```

#### Restart Service
```powershell
Restart-Service -Name "PureSimpleHTTPServer"
```

#### Get Service Properties
```powershell
Get-WmiObject Win32_Service -Filter "Name='PureSimpleHTTPServer'" | Select-Object *
```

### Monitoring

#### Check if Service is Running

**Method 1: Service query**
```batch
sc query PureSimpleHTTPServer | findstr STATE
```

**Method 2: Test HTTP request**
```batch
curl http://localhost:8080
```

**Method 3: Network port check**
```batch
netstat -an | findstr :8080
```

Expected output:
```
TCP    0.0.0.0:8080           0.0.0.0:0              LISTENING
TCP    [::1]:8080              [::1]:0                 LISTENING
```

#### View Recent Events
```powershell
Get-EventLog -LogName Application -Source "PureSimpleHTTPServer" -Newest 10
```

---

## Troubleshooting

### Service Installation Fails

**Symptom:**
```
ERROR: Failed to install service
Make sure you are running as Administrator
```

**Solution:**
1. Right-click on **Command Prompt**
2. Select **"Run as administrator"**
3. Try installation again

---

### Service Won't Start

**Symptom:**
```
The PureSimpleHTTPServer service failed to start
```

**Check 1: Port Already in Use**
```batch
netstat -an | findstr :8080
```

If port 8080 is in use:
```batch
REM Find process using port 8080
netstat -ano | findstr :8080
REM Note the PID (last column)
tasklist | findstr <PID>
```

**Solution:** Stop conflicting application or change port.

**Check 2: Event Log**
1. Open `eventvwr.msc`
2. **Windows Logs** → **Application**
3. Filter by **Event Source: PureSimpleHTTPServer**
4. Look for error messages

**Common Errors:**
- "Port 8080 already in use"
- "wwwroot directory not found"
- "Access denied to configuration files"

---

### Service Stops Immediately

**Symptom:** Service starts but stops immediately

**Check 1: Configuration**
```batch
REM Test in standalone mode
cd C:\Program Files\PureSimpleHTTPServer
PureSimpleHTTPServer.exe --port 8081
```

**Check 2: File Permissions**
```batch
REM Check wwwroot permissions
icacls "C:\Program Files\PureSimpleHTTPServer\wwwroot"
```

**Check 3: Dependencies**
```batch
REM Check service dependencies
sc qc PureSimpleHTTPServer
```

---

### Can't Access Files

**Symptom:** 403 Forbidden or "Access Denied"

**Cause:** Service runs as **Local System** account

**Solution 1: Grant permissions**
```batch
REM Grant Full Control to Everyone
icacls "C:\MyWebsite" /grant "Everyone:(OI)(CI)F" /T
```

**Solution 2: Run service as different user** (future enhancement)

---

### Logs Not Working

**Symptom:** Log files not created

**Current Limitation (v1.6.0):**
- Service mode doesn't support `--log` or `--error-log` flags
- Logging must be configured in source code

**Workaround:** Use standalone mode for logging:
```batch
PureSimpleHTTPServer.exe --log access.log --error-log error.log
```

---

### Uninstallation Issues

**Symptom:** Service won't uninstall

**Check 1: Stop service first**
```batch
net stop PureSimpleHTTPServer
```

**Check 2: Use sc delete**
```batch
sc delete PureSimpleHTTPServer
```

**Check 3: Manual cleanup**
```batch
REM Remove registry entries (advanced)
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\PureSimpleHTTPServer" /f
```

---

## Security

### Service Account

**Default:** Local System

**Privileges:**
- Full system access
- Access to network resources
- Can interact with desktop (if configured)

**Security Considerations:**
- ⚠️ Runs with elevated privileges
- ⚠️ Can access any file on system
- ⚠️ Ensure proper file permissions on wwwroot

**Best Practices:**
- Restrict wwwroot permissions
- Don't serve sensitive system directories
- Use dedicated service account for production
- Regular security updates

### Firewall Configuration

**Allow Port 8080:**
```batch
REM Windows Firewall
netsh advfirewall firewall add rule name="PureSimpleHTTPServer" dir=in action=allow protocol=TCP localport=8080

REM Remove rule
netsh advfirewall firewall delete rule name="PureSimpleHTTPServer"
```

### Antivirus Exclusions

**Add exclusions to prevent scanning:**
- `C:\Program Files\PureSimpleHTTPServer\PureSimpleHTTPServer.exe` - Exclude from scanning
- `wwwroot\` - Exclude from real-time scanning (if hosting dynamic content)

---

## Performance

### Resource Usage

**Typical Usage:**
- **Memory:** ~2-5 MB (idle)
- **CPU:** <1% (idle, 10 concurrent connections)
- **Threads:** Thread-per-connection model
- **Handles:** ~50-100 (depends on connections)

### Performance Tuning

**Max Connections:** 100 (default)

**To change:**
Edit `src/Config.pbi`:
```purebasic
MaxConnections.i = 100
```

Recompile and reinstall service.

### Load Testing

**Apache Bench:**
```batch
ab -n 1000 -c 10 http://127.0.0.1:8080/
```

**Expected Results:**
- Requests: 1000/1000 (100% success)
- Mean response time: ~2 ms
- No crashes or errors

### Optimization Tips

1. **Use SSF optimization** (already enabled via `/OPTIMIZER` flag)
2. **Enable directory caching** for static content
3. **Use CDN** for large files (images, videos)
4. **Enable compression** (`.gz` files)
5. **Tune thread pool** (if implementing connection pooling)

---

## Advanced Topics

### Custom Service Name

Install multiple instances with different names:
```batch
REM Instance 1
PureSimpleHTTPServer.exe --install --service-name WebServer1

REM Instance 2
copy PureSimpleHTTPServer.exe PureSimpleHTTPServer2.exe
PureSimpleHTTPServer2.exe --install --service-name WebServer2
```

### Run as Different User

**Current limitation:** v1.6.0 runs as Local System

**Future enhancement:** Add `--service-user` parameter

### Recovery Actions

**Configure automatic recovery:**

1. Open `services.msc`
2. Open service properties
3. Go to **Recovery** tab
4. Configure:
   - **First failure:** Restart the service
   - **Second failure:** Restart the service
   - **Subsequent failures:** Run a program
   - **Reset fail count after:** 1 day
   - **Restart service after:** 1 minute

### Service Dependencies

**Current:** No dependencies configured

**Recommended:** Add TCP/IP dependency (if using network)

To add dependencies (advanced):
- Modify `CreateServiceA` call in `src/WindowsService.pbi`
- Add dependencies parameter

---

## Command Reference

### PureBasic Compiler

**Windows compiler flags:**
```
/CONSOLE       Console application
/THREAD        Thread-safe mode (required)
/OPTIMIZER     Enable code optimizer
/OUTPUT "file"  Output filename
/ICON "file"    Icon file
```

**Build example:**
```batch
pbcompiler /CONSOLE /THREAD /OPTIMIZER /OUTPUT "dist\PureSimpleHTTPServer.exe" /ICON "assets\icon.ico" src\main.pb
```

### Build Scripts

#### build.bat
- Compiles PureBasic source
- Creates output directory
- Embeds icon
- Tests executable

#### package.bat
- Runs build.bat
- Creates portable ZIP
- Builds NSIS installer
- Converts documentation

#### verify_build.bat
- Checks if build was successful
- Verifies all files exist
- Tests executable runs

---

## Migration Guide

### From Standalone to Service

**Current standalone setup:**
```batch
PureSimpleHTTPServer.exe --port 8080 --root C:\MyWebsite --log access.log
```

**Service setup (v1.6.0 limitations):**
- Port fixed at 8080
- Root fixed at wwwroot
- No logging support in service mode

**Migration steps:**

1. **Prepare directory:**
   ```batch
   copy "C:\MyWebsite\*" "C:\Program Files\PureSimpleHTTPServer\wwwroot\"
   ```

2. **Install service:**
   ```batch
   PureSimpleHTTPServer.exe --install
   ```

3. **Configure auto-start:**
   - Open `services.msc`
   - Set **Startup type** to **Automatic**

4. **Start service:**
   ```batch
   net start PureSimpleHTTPServer
   ```

### Upgrade Service

**To upgrade from v1.5.0 to v1.6.0:**

1. **Stop service:**
   ```batch
   net stop PureSimpleHTTPServer
   ```

2. **Uninstall old version:**
   ```batch
   PureSimpleHTTPServer.exe --uninstall
   ```

3. **Install new version:**
   - Run NSIS installer
   - Or extract portable package
   - Reinstall service: `--install`

4. **Start new version:**
   ```batch
   net start PureSimpleHTTPServer
   ```

---

## Best Practices

### Production Deployment

1. **Use NSIS installer** for production
2. **Enable Windows Service** for always-on servers
3. **Configure auto-start** on boot
4. **Set recovery actions** for automatic restart
5. **Monitor Event Log** regularly
6. **Use dedicated service account** (future)
7. **Restrict wwwroot permissions**
8. **Enable firewall rules** for port 8080
9. **Regular updates** for security patches
10. **Backup wwwroot** regularly

### Development/Testing

1. **Use portable package** for development
2. **Run in standalone mode** for testing
3. **Use different ports** to avoid conflicts
4. **Enable logging** during development
5. **Test service mode** before production

### Maintenance

1. **Regular log rotation** (if logging enabled)
2. **Monitor service health** via Event Viewer
3. **Check for updates** regularly
4. **Test backup/restore procedures**
5. **Document custom configurations**

---

## Appendix

### File Locations

**Default Installation Directory:**
```
C:\Program Files\PureSimpleHTTPServer\
├── PureSimpleHTTPServer.exe
├── wwwroot\
├── README.txt
├── LICENSE.txt
└── CHANGELOG.txt
```

**Service Registry Location:**
```
HKLM\SYSTEM\CurrentControlSet\Services\PureSimpleHTTPServer
```

**Uninstall Registry Location:**
```
HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\PureSimpleHTTPServer
```

### Service Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Error |

### Related Documentation

- [../README.md](../README.md) - Main README
- [../CHANGELOG.md](../CHANGELOG.md) - Version history
- [../quickstart.txt](../quickstart.txt) - Quick start guide
- [URL_REWRITE.md](URL_REWRITE.md) - URL rewriting documentation

### Support

**Issues:** https://github.com/Jedt3D/PureSimpleHTTPServer/issues

**Discussions:** https://github.com/Jedt3D/PureSimpleHTTPServer/discussions

---

**Version:** 1.6.0
**Last Updated:** March 15, 2026
**Maintainer:** PureSimpleHTTPServer Team
