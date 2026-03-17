# Windows Optimization Roadmap

**Branch:** `feature/windows-optimizations`
**Base Version:** v1.5.0
**Target Platform:** Windows (ARM64/x64) - maintaining cross-platform compatibility

---

## Overview

This roadmap outlines Windows-specific enhancements and optimizations while maintaining full compatibility with macOS and Linux platforms through conditional compilation (`#PB_Compiler_OS`).

---

## Phase 1: Windows-Specific Networking (IOCP)

**Goal:** Replace the current thread-per-connection model with Windows I/O Completion Ports for better scalability.

### Tasks
- [ ] Research IOCP implementation pattern for PureBasic
- [ ] Create `TcpServerWindows.pbi` with IOCP-based server
- [ ] Implement thread pool for IOCP worker threads
- [ ] Add conditional compilation in `main.pb`:
  ```purebasic
  CompilerIf #PB_Compiler_OS = #PB_OS_Windows
    ; Use IOCP server
  CompilerElse
    ; Use existing thread-per-connection server
  CompilerEndIf
  ```
- [ ] Benchmark: Compare IOCP vs thread-per-connection performance
- [ ] Add runtime configuration: `--use-iocp` flag for Windows

**Expected Benefits:**
- Better scalability under high concurrent connections (1000+)
- Lower memory footprint
- Reduced context switching overhead

**Testing:**
- Load test with 1000+ concurrent connections
- Memory usage profiling
- Performance comparison with current implementation

---

## Phase 2: Windows Service Integration

**Goal:** Run PureSimpleHTTPServer as a native Windows service with proper service lifecycle management.

### Tasks
- [ ] Create `WindowsService.pbi` module
- [ ] Implement service callbacks:
  - ServiceMain
  - ServiceCtrlHandler (START/STOP/PAUSE/CONTINUE)
- [ ] Add service installation commands:
  ```
  PureSimpleHTTPServer.exe --install
  PureSimpleHTTPServer.exe --uninstall
  PureSimpleHTTPServer.exe --start
  PureSimpleHTTPServer.exe --stop
  ```
- [ ] Implement service status reporting
- [ ] Add Windows Event Log integration
- [ ] Create service configuration file (service.conf)

**Configuration:**
```ini
[Service]
Name=PureSimpleHTTPServer
DisplayName=PureSimple HTTP Server
Description=Lightweight HTTP/1.1 static file server
AutoStart=yes
LogPath=C:\ProgramData\PureSimpleHTTPServer\logs
```

**Testing:**
- Install/remove service cycles
- Service start/stop/restart
- Service survives system reboot
- Event Log entries appear correctly

---

## Phase 3: System Tray Application

**Goal:** Add Windows system tray icon for easy server management.

### Tasks
- [ ] Create `SystemTray.pbi` module
- [ ] Implement tray icon with popup menu:
  - Start/Stop Server
  - Open browser to localhost
  - View logs
  - Open configuration
  - Exit
- [ ] Add balloon notifications for server events
- [ ] Implement tray-only mode (run hidden at startup)
- [ ] Add `--tray` flag for tray-only operation

**UI Design:**
```
Right-click menu:
├─ Start Server
├─ Stop Server
├─ ─────────────
├─ Open in Browser
├─ View Access Log
├─ View Error Log
├─ ─────────────
├─ Settings...
├─ About...
└─ Exit
```

**Testing:**
- Tray icon appears/disappears correctly
- Menu options work as expected
- Server state changes are reflected in menu
- Balloon notifications appear for errors

---

## Phase 4: Windows Performance Optimizations

**Goal:** Implement Windows-specific performance improvements.

### Tasks

#### 4.1 Memory-Mapped File I/O
- [ ] Create `MmapFileServer.pbi` for Windows
- [ ] Use `CreateFileMapping` and `MapViewOfFile` APIs
- [ ] Zero-copy file serving for large files
- [ ] Add `--use-mmap` flag for Windows

#### 4.2 HTTP.SYS Integration (Optional - Advanced)
- [ ] Research HTTP.SYS API usage from PureBasic
- [ ] Implement HTTP.SYS listener
- [ ] Support for multiple applications on port 80
- [ ] Kernel-mode request filtering
- [ ] SSL/TLS support via HTTP.SYS

#### 4.3 Windows Cache API
- [ ] Implement `AddURLToCacheGroup` for static files
- [ ] Pre-warm cache for frequently accessed files
- [ ] Cache statistics reporting

#### 4.4 ThreadPool API
- [ ] Replace `CreateThread` with Windows ThreadPool API
- [ ] Dynamic thread pool sizing based on load
- [ ] Better CPU affinity for NUMA systems

**Benchmarking:**
- Before/after performance metrics
- Memory usage comparison
- CPU utilization under load

---

## Phase 5: Windows Build & Packaging

**Goal:** Professional Windows deployment package.

### Tasks

#### 5.1 Installer (NSIS or WiX)
- [ ] Create installer script
- [ ] Features:
  - GUI installer with license agreement
  - Optional system tray autostart
  - Service installation option
  - Start Menu shortcuts
  - Desktop shortcut (optional)
  - Automatic uninstaller
- [ ] Silent installation support (`/S` flag)
- [ ] Custom installation directory

#### 5.2 Portable Package
- [ ] Create ZIP package with:
  - PureSimpleHTTPServer.exe
  - Default wwwroot folder
  - Sample configuration files
  - README.txt
  - LICENSE.txt
- [ - No installation required

#### 5.3 Code Signing
- [ ] Obtain code signing certificate
- [ ] Sign the executable
- [ ] Verify SmartScreen reputation

#### 5.4 Auto-Update Mechanism
- [ ] Implement version check against GitHub releases
- [ ] Download and apply updates
- [ ] Add `--check-updates` flag

---

## Phase 6: Windows-Specific Features

**Goal:** Add Windows-exclusive convenience features.

### Tasks

#### 6.1 Windows Event Logging
- [ ] Replace file-based error logs with Windows Event Log
- [ ] Add `--use-event-log` flag
- [ ] Categorize events: Information/Warning/Error
- [ ] Event Log viewer integration

#### 6.2 Performance Counters
- [ ] Create Windows Performance Monitor counters:
  - Requests/sec
  - Active connections
  - Bytes sent/sec
  - Average response time
  - Cache hit rate
- [ ] Enable monitoring via perfmon.msc

#### 6.3 Firewall Configuration
- [ ] Automatic Windows Firewall rule creation
- [ ] Prompt for firewall exception during first run
- [ ] Add `--add-firewall-rule` flag

#### 6.4 Configuration GUI
- [ ] Create settings dialog using PureBasic GUI
- [ ] Real-time configuration editing
- [ ] Configuration validation
- [ - Test configuration without restart

---

## Cross-Platform Compatibility Matrix

| Feature | Windows | macOS | Linux |
|---------|---------|-------|-------|
| Thread-per-connection | ✅ | ✅ | ✅ |
| IOCP Networking | ✅ | ❌ | ❌ | (epoll/kqueue alternatives)
| System Tray | ✅ | ❌ | ❌ | (menu bar/indicator alternatives)
| Windows Service | ✅ | ❌ | ❌ | (launchd/systemd alternatives)
| Event Logging | ✅ | ❌ | ❌ | (syslog alternatives)
| Performance Counters | ✅ | ❌ | ❌ | (collectd/prometheus alternatives)

---

## Development Milestones

### Milestone 1: Foundation ✅
- [x] Branch created
- [x] Baseline Windows compilation verified
- [ ] Performance baseline established

### Milestone 2: IOCP Implementation
- [ ] IOCP server implemented
- [ ] Performance benchmarks completed
- [ ] Documentation updated

### Milestone 3: Service Integration
- [ ] Windows service support complete
- [ ] Installation/removal tested
- [ ] Service lifecycle documented

### Milestone 4: Tray Application
- [ ] System tray UI complete
- [ ] Menu functionality tested
- [ ] User documentation created

### Milestone 5: Packaging
- [ ] Installer created
- [ ] Portable package built
- [ ] Code signature applied

### Milestone 6: Polish & Release
- [ ] All features integrated
- [ ] Documentation complete
- [ ] v2.0.0 release

---

## Testing Strategy

### Unit Tests
- All existing 108 tests must pass on Windows
- Add Windows-specific test cases
- Test conditional compilation paths

### Integration Tests
- Service install/start/stop/remove cycles
- Tray application functionality
- Load testing with IOCP
- Memory leak detection

### Performance Benchmarks
```bash
# Baseline (current)
ab -n 10000 -c 100 http://localhost:8080/

# IOCP
ab -n 10000 -c 100 http://localhost:8080/

# Compare:
# - Requests per second
# - Mean response time
# - Memory usage
# - CPU utilization
```

---

## Dependencies

### Required
- PureBasic 6.30+ ✅ (already installed)
- Windows SDK (for HTTP.SYS, if needed)

### Optional
- NSIS or WiX Toolset (for installer)
- Code signing certificate
- Performance monitoring tools

---

## Documentation Requirements

- [ ] Update README.md with Windows-specific features
- [ ] Create WINDOWS_INSTALL.md
- [ ] Document `--install`, `--uninstall` flags
- [ ] API documentation for new modules
- [ ] Performance tuning guide for Windows
- [ ] Troubleshooting guide

---

## Success Criteria

1. **Performance:** 2x improvement in concurrent connection handling
2. **Compatibility:** All existing tests pass on all platforms
3. **Usability:** Seamless installation/uninstallation
4. **Reliability:** Service runs 24/7 without crashes
5. **Documentation:** Comprehensive Windows-specific docs

---

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| IOCP complexity | High | Extensive testing, fallback to thread-per-connection |
| Service permissions | Medium | Clear documentation, UAC prompts |
| Code signing cost | Low | Optional, skip for open-source builds |
| Platform fragmentation | Low | Conditional compilation, maintain cross-platform core |

---

## Notes

- All Windows-specific code must be wrapped in `CompilerIf #PB_Compiler_OS = #PB_OS_Windows`
- Maintain backward compatibility with existing command-line flags
- Default behavior should remain consistent across platforms
- Performance optimizations should benefit all platforms where possible
- Windows-specific features must be clearly documented as such

---

**Last Updated:** 2025-03-15
**Branch:** feature/windows-optimizations
**Status:** In Development
