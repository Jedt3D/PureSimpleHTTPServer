@echo off
REM ============================================================================
REM PureSimpleHTTPServer - Packaging Script
REM ============================================================================
REM Creates Windows installer and portable package
REM
REM Requirements:
REM   - PureBasic compiler (for build.bat)
REM   - NSIS installed at: C:\Program Files\NSIS\
REM   - PowerShell (for ZIP creation - built into Windows)
REM
REM Outputs:
REM   - dist\PureSimpleHTTPServer-{version}-windows-portable.zip
REM   - dist\PureSimpleHTTPServer-{version}-windows-setup.exe
REM ============================================================================

setlocal EnableDelayedExpansion

REM Configuration
set VERSION=2.5.0
set APP_NAME=PureSimpleHTTPServer
set OUTPUT_DIR=dist
set NSIS_COMPILER=C:\Program Files\NSIS\makensis.exe
set PORTABLE_DIR=dist\portable

REM Colors
set "INFO=[92m"
set "WARN=[93m"
set "ERROR=[91m"
set "RESET=[0m"

echo.
echo %INFO%===========================================================================%RESET%
echo %INFO%PureSimpleHTTPServer Packaging Script%RESET%
echo %INFO%===========================================================================%RESET%
echo.
echo Version: %VERSION%
echo.

REM Step 1: Build executable
echo %INFO%Step 1: Building executable...%RESET%
call build.bat
if errorlevel 1 (
    echo %ERROR%ERROR: Build failed!%RESET%
    echo.
    pause
    exit /b 1
)
echo.

REM Step 2: Prepare portable package
echo %INFO%Step 2: Creating portable package...%RESET%

REM Create portable directory
if exist %PORTABLE_DIR% rmdir /s /q %PORTABLE_DIR%
mkdir %PORTABLE_DIR%

REM Copy executable
copy "%OUTPUT_DIR%\%APP_NAME%.exe" "%PORTABLE_DIR%\" >nul
if errorlevel 1 (
    echo %ERROR%ERROR: Failed to copy executable!%RESET%
    pause
    exit /b 1
)

REM Copy wwwroot directory
if exist wwwroot (
    xcopy /E /I /Y wwwroot "%PORTABLE_DIR%\wwwroot\" >nul
) else (
    echo %WARN%WARNING: wwwroot directory not found, creating placeholder...%RESET%
    mkdir "%PORTABLE_DIR%\wwwroot%"
    echo ^<html^> > "%PORTABLE_DIR%\wwwroot\index.html"
    echo ^<head^>^<title^>PureSimpleHTTPServer^</title^>^</head^> >> "%PORTABLE_DIR%\wwwroot\index.html"
    echo ^<body^>^<h1^>Welcome to PureSimpleHTTPServer!^</h1^>^</body^> >> "%PORTABLE_DIR%\wwwroot\index.html"
    echo ^</html^> >> "%PORTABLE_DIR%\wwwroot\index.html"
)

REM Convert and copy documentation
echo %INFO%Converting documentation to text format...%RESET%

REM Convert README.md to README.txt
powershell -Command "Get-Content README.md | Out-File -Encoding ASCII %PORTABLE_DIR%\README.txt" 2>nul
if not exist "%PORTABLE_DIR%\README.txt" (
    echo %WARN%WARNING: Could not convert README.md, copying as-is...%RESET%
    copy README.md "%PORTABLE_DIR%\README.txt" >nul 2>&1
)

REM Copy LICENSE as LICENSE.txt
copy LICENSE "%PORTABLE_DIR%\LICENSE.txt" >nul 2>&1

REM Convert CHANGELOG.md to CHANGELOG.txt
powershell -Command "Get-Content CHANGELOG.md | Out-File -Encoding ASCII %PORTABLE_DIR%\CHANGELOG.txt" 2>nul
if not exist "%PORTABLE_DIR%\CHANGELOG.txt" (
    copy CHANGELOG.md "%PORTABLE_DIR%\CHANGELOG.txt" >nul 2>&1
)

REM Create quickstart.txt
echo %INFO%Creating quick start guide...%RESET%
(
echo PureSimpleHTTPServer v%VERSION% - Quick Start Guide
echo ==================================================
echo.
echo Getting Started:
echo ----------------
echo 1. Double-click PureSimpleHTTPServer.exe to start the server
echo 2. Open your web browser to: http://localhost:8080
echo 3. The server will serve files from the wwwroot directory
echo.
echo Command-Line Options:
echo ---------------------
echo --port N           : Set port number ^(default: 8080^)
echo --root DIR         : Set web root directory ^(default: wwwroot^)
echo --browse           : Enable directory browsing
echo --spa              : Enable Single Page Application mode
echo --log FILE         : Enable access log to FILE
echo --error-log FILE   : Enable error log to FILE
echo --log-level LEVEL  : Set log level ^(0=none, 1=error, 2=warn, 3=info, 4=debug^)
echo --clean-urls       : Enable clean URLs ^(extensionless paths try .html^)
echo --rewrite FILE     : Load rewrite rules from FILE
echo --help             : Show all options
echo.
echo Examples:
echo ---------
echo PureSimpleHTTPServer.exe
echo   Start on port 8080 serving wwwroot
echo.
echo PureSimpleHTTPServer.exe --port 3000 --root C:\MyWebsite
echo   Start on port 3000 serving C:\MyWebsite
echo.
echo PureSimpleHTTPServer.exe --browse --log access.log
echo   Start with directory browsing and access logging
echo.
echo Stopping the Server:
echo --------------------
echo Press Ctrl+C in the console window to stop the server
echo.
echo Support:
echo --------
echo GitHub: https://github.com/woraj/PureSimpleHTTPServer
echo Documentation: See README.txt for complete documentation
echo.
echo License: MIT License - See LICENSE.txt
echo.
) > "%PORTABLE_DIR%\quickstart.txt"

REM Create ZIP archive
echo %INFO%Creating portable ZIP archive...%RESET%
set ZIP_NAME=%APP_NAME%-%VERSION%-windows-portable.zip

REM Remove existing ZIP if it exists
if exist "%OUTPUT_DIR%\%ZIP_NAME%" del "%OUTPUT_DIR%\%ZIP_NAME%"

REM Create ZIP using PowerShell
powershell -Command "Compress-Archive -Path '%PORTABLE_DIR%\*' -DestinationPath '%OUTPUT_DIR%\%ZIP_NAME%' -Force"
if errorlevel 1 (
    echo %ERROR%ERROR: Failed to create ZIP archive!%RESET%
    pause
    exit /b 1
)

echo.
echo %INFO%Portable package created: %OUTPUT_DIR%\%ZIP_NAME%%RESET%

REM Step 3: Create installer
echo.
echo %INFO%Step 3: Creating installer...%RESET%

REM Check if NSIS is installed
if not exist "%NSIS_COMPILER%" (
    echo %ERROR%ERROR: NSIS compiler not found!%RESET%
    echo %ERROR%Expected location: %NSIS_COMPILER%%RESET%
    echo.
    echo Please install NSIS from: https://nsis.sourceforge.io/
    echo.
    echo Skipping installer creation...
    goto skip_installer
)

REM Check if NSIS script exists
if not exist installer\PureSimpleHTTPServer.nsi (
    echo %ERROR%ERROR: NSIS script not found: installer\PureSimpleHTTPServer.nsi%RESET%
    goto skip_installer
)

REM Build installer
"%NSIS_COMPILER%" installer\PureSimpleHTTPServer.nsi
if errorlevel 1 (
    echo %ERROR%ERROR: Installer creation failed!%RESET%
    pause
    exit /b 1
)

skip_installer:

echo.
echo %INFO%===========================================================================%RESET%
echo %INFO%Packaging complete!%RESET%
echo %INFO%===========================================================================%RESET%
echo.
echo Output files:
echo -------------
if exist "%OUTPUT_DIR%\%ZIP_NAME%" (
    echo [+] Portable: %OUTPUT_DIR%\%ZIP_NAME%
    for %%A in ("%OUTPUT_DIR%\%ZIP_NAME%") do echo     Size: %%~zA bytes
)
if exist "%OUTPUT_DIR%\%APP_NAME%-%VERSION%-windows-setup.exe" (
    echo [+] Installer: %OUTPUT_DIR%\%APP_NAME%-%VERSION%-windows-setup.exe
    for %%A in ("%OUTPUT_DIR%\%APP_NAME%-%VERSION%-windows-setup.exe") do echo     Size: %%~zA bytes
)
echo.

REM Cleanup portable directory
if exist %PORTABLE_DIR% rmdir /s /q %PORTABLE_DIR%

echo %INFO%Package creation complete!%RESET%
echo.
echo Distribution files are ready in the %OUTPUT_DIR% directory.
echo.

pause
exit /b 0
