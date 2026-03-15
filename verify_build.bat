@echo off
REM ============================================================================
REM PureSimpleHTTPServer - Build Verification Script
REM ============================================================================
REM Tests that the build and packaging process works correctly
REM
REM This script performs basic verification tests without requiring
REM full installation testing
REM ============================================================================

setlocal EnableDelayedExpansion

REM Configuration
set VERSION=1.5.0
set APP_NAME=PureSimpleHTTPServer
set OUTPUT_DIR=dist
set EXE_NAME=%APP_NAME%.exe

REM Colors
set "INFO=[92m"
set "WARN=[93m"
set "ERROR=[91m"
set "RESET=[0m"

echo.
echo %INFO%===========================================================================%RESET%
echo %INFO%PureSimpleHTTPServer - Build Verification%RESET%
echo %INFO%===========================================================================%RESET%
echo.

REM Test counters
set TOTAL=0
set PASSED=0
set FAILED=0

REM Function to run a test
:RUN_TEST
set /a TOTAL+=1
echo.
echo %INFO%Test %TOTAL%: %~1%RESET%
echo %INFO%--------------------------------------------------------------------------%RESET%
shift
goto :EOF

REM Function to record test result
:PASS
echo %INFO%[PASS]%RESET% %~1
set /a PASSED+=1
goto :EOF

:FAIL
echo %ERROR%[FAIL]%RESET% %~1
set /a FAILED+=1
goto :EOF

REM ============================================================================
REM TEST 1: Check if executable exists
REM ============================================================================
echo %INFO%Test 1: Check if executable exists%RESET%
echo %INFO%--------------------------------------------------------------------------%RESET%

if exist "%OUTPUT_DIR%\%EXE_NAME%" (
    call :PASS "Executable found: %OUTPUT_DIR%\%EXE_NAME%"
    for %%A in ("%OUTPUT_DIR%\%EXE_NAME%") do echo     Size: %%~zA bytes
) else (
    call :FAIL "Executable not found: %OUTPUT_DIR%\%EXE_NAME%"
    echo     Run build.bat first!
)

REM ============================================================================
REM TEST 2: Check if executable is valid PE file
REM ============================================================================
echo.
echo %INFO%Test 2: Check if executable is valid PE file%RESET%
echo %INFO%--------------------------------------------------------------------------%RESET%

where findstr >nul 2>&1
if errorlevel 1 (
    echo %WARN%[SKIP] findstr not available%RESET%
    goto skip_pe_test
)

findstr /C:"MZ" "%OUTPUT_DIR%\%EXE_NAME%" >nul 2>&1
if errorlevel 1 (
    call :FAIL "Executable does not have PE header"
) else (
    call :PASS "Executable has valid PE header"
)

:skip_pe_test

REM ============================================================================
REM TEST 3: Check if documentation files exist
REM ============================================================================
echo.
echo %INFO%Test 3: Check if documentation files exist%RESET%
echo %INFO%--------------------------------------------------------------------------%RESET%

set DOC_FILES=README.txt LICENSE.txt CHANGELOG.txt quickstart.txt
set ALL_DOC_OK=1

for %%F in (%DOC_FILES%) do (
    if exist "%%F" (
        echo     [OK] %%F
    ) else (
        echo     [MISSING] %%F
        set ALL_DOC_OK=0
    )
)

if !ALL_DOC_OK! == 1 (
    call :PASS "All documentation files present"
) else (
    call :FAIL "Some documentation files missing"
)

REM ============================================================================
REM TEST 4: Check if assets directory exists
REM ============================================================================
echo.
echo %INFO%Test 4: Check if assets directory exists%RESET%
echo %INFO%--------------------------------------------------------------------------%RESET%

if exist "assets" (
    call :PASS "Assets directory exists"
    if exist "assets\icon.svg" (
        echo     [OK] icon.svg
    ) else (
        echo     [MISSING] icon.svg
    )
) else (
    call :FAIL "Assets directory not found"
)

REM ============================================================================
REM TEST 5: Check if installer script exists
REM ============================================================================
echo.
echo %INFO%Test 5: Check if installer script exists%RESET%
echo %INFO%--------------------------------------------------------------------------%RESET%

if exist "installer\PureSimpleHTTPServer.nsi" (
    call :PASS "Installer script exists: installer\PureSimpleHTTPServer.nsi"
) else (
    call :FAIL "Installer script not found: installer\PureSimpleHTTPServer.nsi"
)

REM ============================================================================
REM TEST 6: Check if build scripts exist
REM ============================================================================
echo.
echo %INFO%Test 6: Check if build scripts exist%RESET%
echo %INFO%--------------------------------------------------------------------------%RESET%

set BUILD_OK=1
if exist "build.bat" (
    echo     [OK] build.bat
) else (
    echo     [MISSING] build.bat
    set BUILD_OK=0
)

if exist "package.bat" (
    echo     [OK] package.bat
) else (
    echo     [MISSING] package.bat
    set BUILD_OK=0
)

if !BUILD_OK! == 1 (
    call :PASS "All build scripts present"
) else (
    call :FAIL "Some build scripts missing"
)

REM ============================================================================
REM TEST 7: Check if wwwroot exists
REM ============================================================================
echo.
echo %INFO%Test 7: Check if wwwroot exists%RESET%
echo %INFO%--------------------------------------------------------------------------%RESET%

if exist "wwwroot" (
    call :PASS "wwwroot directory exists"
) else (
    echo %WARN%[WARN] wwwroot directory not found (will be created)%RESET%
)

REM ============================================================================
REM TEST 8: Try to run executable with --help
REM ============================================================================
echo.
echo %INFO%Test 8: Test executable with --help flag%RESET%
echo %INFO%--------------------------------------------------------------------------%RESET%

if exist "%OUTPUT_DIR%\%EXE_NAME%" (
    "%OUTPUT_DIR%\%EXE_NAME%" --help >nul 2>&1
    if errorlevel 1 (
        echo %WARN%[WARN] Executable may not support --help or exited with error%RESET%
    ) else (
        call :PASS "Executable runs without crashing"
    )
) else (
    echo %WARN%[SKIP] Executable not found%RESET%
)

REM ============================================================================
REM Summary
REM ============================================================================
echo.
echo %INFO%===========================================================================%RESET%
echo %INFO%Verification Summary%RESET%
echo %INFO%===========================================================================%RESET%
echo.
echo Total Tests: %TOTAL%
echo %INFO%Passed: %PASSED%%RESET%
if %FAILED% GTR 0 (
    echo %ERROR%Failed: %FAILED%%RESET%
) else (
    echo Failed: %FAILED%
)
echo.

if %FAILED% EQU 0 (
    echo %INFO%===========================================================================%RESET%
    echo %INFO%All basic tests passed!%RESET%
    echo %INFO%===========================================================================%RESET%
    echo.
    echo Next steps:
    echo   1. Manually test the executable: %OUTPUT_DIR%\%EXE_NAME%
    echo   2. Run full installer tests using the test checklist
    echo   3. Test on multiple Windows versions if possible
    echo.
) else (
    echo %ERROR%===========================================================================%RESET%
    echo %ERROR%Some tests failed! Please review the output above.%RESET%
    echo %ERROR%===========================================================================%RESET%
    echo.
)

pause
exit /b 0
