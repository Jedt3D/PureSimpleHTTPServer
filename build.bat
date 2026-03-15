@echo off
REM ============================================================================
REM PureSimpleHTTPServer - Build Script
REM ============================================================================
REM Compiles the PureBasic source code into a Windows executable
REM
REM Requirements:
REM   - PureBasic compiler installed at: C:\Program Files\PureBasic\
REM   - Source code in: src\main.pb
REM
REM Output:
REM   - dist\PureSimpleHTTPServer.exe
REM ============================================================================

setlocal EnableDelayedExpansion

REM Configuration
set PB_COMPILER=C:\Program Files\PureBasic\Compilers\pbcompiler.exe
set OUTPUT_DIR=dist
set SOURCE_FILE=src\main.pb
set EXE_NAME=PureSimpleHTTPServer.exe
set VERSION=1.5.0

REM Colors for output (Windows 10+)
set "INFO=[92m"    ; Green
set "WARN=[93m"    ; Yellow
set "ERROR=[91m"   ; Red
set "RESET=[0m"    ; Reset

echo.
echo %INFO%===========================================================================%RESET%
echo %INFO%PureSimpleHTTPServer Build Script%RESET%
echo %INFO%===========================================================================%RESET%
echo.
echo Compiler: %PB_COMPILER%
echo Source:   %SOURCE_FILE%
echo Output:   %OUTPUT_DIR%\%EXE_NAME%
echo Version:  %VERSION%
echo.

REM Check if PureBasic compiler exists
if not exist "%PB_COMPILER%" (
    echo %ERROR%ERROR: PureBasic compiler not found!%RESET%
    echo %ERROR%Expected location: %PB_COMPILER%%RESET%
    echo.
    echo Please install PureBasic or update PB_COMPILER in this script.
    echo.
    pause
    exit /b 1
)

REM Clean and create output directory
echo %INFO%Creating output directory...%RESET%
if exist %OUTPUT_DIR% (
    rmdir /s /q %OUTPUT_DIR%
)
mkdir %OUTPUT_DIR%

REM Check if source file exists
if not exist "%SOURCE_FILE%" (
    echo %ERROR%ERROR: Source file not found: %SOURCE_FILE%%RESET%
    echo.
    pause
    exit /b 1
)

REM Compile executable
echo %INFO%Compiling...%RESET%
echo.

REM Compiler flags:
REM   -cl        : Console application
REM   -t         : Thread-safe mode (required for networking)
REM   -z         : Enable optimizer
REM   -o         : Output filename
REM   -n         : Icon file (if exists)
set "ICON_FLAG="
if exist "assets\icon.ico" (
    set "ICON_FLAG=--n "assets\icon.ico""
    echo %INFO%Using icon: assets\icon.ico%RESET%
)

"%PB_COMPILER%" -cl -t -z -o "%OUTPUT_DIR%\%EXE_NAME%" %ICON_FLAG% %SOURCE_FILE%

if errorlevel 1 (
    echo.
    echo %ERROR%ERROR: Compilation failed!%RESET%
    echo.
    pause
    exit /b 1
)

echo.
echo %INFO%===========================================================================%RESET%
echo %INFO%Build successful!%RESET%
echo %INFO%===========================================================================%RESET%
echo.
echo Output: %OUTPUT_DIR%\%EXE_NAME%
echo Size:   %~z1 bytes
echo.

REM Display executable info
echo Executable information:
echo =======================
dir "%OUTPUT_DIR%\%EXE_NAME%" | findstr /C:"%EXE_NAME%"
echo.

REM Test if executable runs
echo %INFO%Testing executable...%RESET%
"%OUTPUT_DIR%\%EXE_NAME%" --help >nul 2>&1
if errorlevel 1 (
    echo %WARN%WARNING: Executable may not run correctly. Test manually.%RESET%
) else (
    echo %INFO%Executable appears to run correctly.%RESET%
)
echo.

echo %INFO%Build complete!%RESET%
echo.
echo Next steps:
echo   1. Test the executable: %OUTPUT_DIR%\%EXE_NAME%
echo   2. Run package.bat to create installer and portable package
echo.

pause
exit /b 0
