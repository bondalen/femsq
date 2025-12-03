@echo off

REM ============================================================================
REM FEMSQ: Launch Thin JAR (Windows) - Simplified
REM ============================================================================
REM Usage: start-with-logging.bat [java-path] [thin-jar] [nolog]
REM
REM Parameters:
REM   java-path - Path to Java 21 executable (REQUIRED)
REM   thin-jar  - Path to thin JAR (optional, auto-detected if not specified)
REM   nolog     - Disable logging to file (optional)
REM ============================================================================

REM 1. Validate Java path FIRST (before setlocal to avoid parameter issues)
if "%~1"=="" (
    echo.
    echo ========================================
    echo [ERROR] Java 21 path is REQUIRED
    echo ========================================
    echo.
    echo Usage:
    echo   start-with-logging.bat [java-path] [thin-jar] [nolog]
    echo.
    echo Parameters:
    echo   java-path - Path to Java 21 executable (REQUIRED)
    echo   thin-jar  - Path to thin JAR (optional, auto-detected if not specified)
    echo   nolog     - Disable logging to file (optional)
    echo.
    echo Examples:
    echo   start-with-logging.bat "D:\java\jdk-21\bin\java.exe"
    echo   start-with-logging.bat "D:\java\jdk-21\bin\java.exe" femsq-web-0.1.0.19-SNAPSHOT-thin.jar
    echo   start-with-logging.bat "D:\java\jdk-21\bin\java.exe" "" nolog
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
)

REM 2. Now enable delayed expansion AFTER parameter validation
setlocal enabledelayedexpansion

REM 3. Setup directories
set "SCRIPT_DIR=%~dp0"
cd /d "!SCRIPT_DIR!"
set "LIB_DIR=!SCRIPT_DIR!lib"
set "NATIVE_LIBS_DIR=!SCRIPT_DIR!native-libs"

REM 4. Parse parameters (new order: java-path, thin-jar, nolog)
set "JAVA_EXE=%~1"
set "THIN_JAR=%~2"
set "NO_LOG=%~3"

REM Quotes are already removed by %~1
REM Do not remove spaces - they may be part of the path

REM 5. Setup logging (with timestamp if enabled)
set "LOG_TO_FILE=true"
if /i "%NO_LOG%"=="nolog" (
    set "LOG_TO_FILE=false"
)

REM Generate timestamp for log filename (if logging enabled)
if "!LOG_TO_FILE!"=="true" (
    REM Use PowerShell for reliable date/time formatting
    for /f "delims=" %%i in ('powershell -command "Get-Date -Format \"yy-MMdd-HHmm\""') do set "DATETIME=%%i"
    set "LOG_FILE=!SCRIPT_DIR!start_!DATETIME!.log"
    
    REM Initialize log file
    echo ======================================== > "!LOG_FILE!"
    echo FEMSQ: Launch Thin JAR >> "!LOG_FILE!"
    echo Date: %DATE% %TIME% >> "!LOG_FILE!"
    echo ======================================== >> "!LOG_FILE!"
    echo. >> "!LOG_FILE!"
) else (
    set "LOG_FILE="
)

REM Function for output (to console and optionally to file)
goto :skip_log_func
:log
if not "%~1"=="" (
    echo %~1
    if "!LOG_TO_FILE!"=="true" (
        if defined LOG_FILE (
            echo %~1 >> "!LOG_FILE!"
        )
    )
)
exit /b
:skip_log_func

call :log "========================================"
call :log "FEMSQ: Launch Thin JAR"
call :log "========================================"
call :log ""

if "!LOG_TO_FILE!"=="true" (
    call :log "[INFO] Log file: !LOG_FILE!"
) else (
    call :log "[INFO] Logging to file is DISABLED (nolog parameter)"
)
call :log "[INFO] Current directory: %CD%"
call :log "[INFO] Script directory: !SCRIPT_DIR!"
call :log "[DEBUG] Java path parameter: !JAVA_EXE!"
call :log "[DEBUG] Thin JAR parameter: !THIN_JAR!"
call :log "[DEBUG] No log parameter: !NO_LOG!"
call :log ""

REM 6. Auto-detect thin JAR if not specified
if "!THIN_JAR!"=="" (
    call :log "[INFO] Thin JAR not specified, searching in current directory..."
    
    for %%F in (femsq-web-*-thin.jar) do (
        if exist "%%F" (
            set "THIN_JAR=%%F"
            call :log "[OK] Auto-detected thin JAR: %%F"
            goto :jar_found
        )
    )
    
    call :log "[ERROR] Thin JAR not found in current directory"
    call :log "[ERROR] Please specify thin JAR as second parameter"
    call :log ""
    call :log "Press any key to exit..."
    pause >nul
    exit /b 1
)
:jar_found

REM Remove quotes if present
set "THIN_JAR=!THIN_JAR:"=!"

REM 7. Validate Java executable
if not exist "!JAVA_EXE!" (
    call :log "[ERROR] Java executable not found: !JAVA_EXE!"
    call :log "[ERROR] Please check the path and try again"
    call :log ""
    call :log "Press any key to exit..."
    pause >nul
    exit /b 1
)

call :log "[OK] Java executable found: !JAVA_EXE!"
call :log ""

REM 8. Check thin JAR
if not exist "!THIN_JAR!" (
    call :log "[ERROR] Thin JAR not found: !THIN_JAR!"
    call :log ""
    call :log "Current directory: %CD%"
    call :log ""
    call :log "Press any key to exit..."
    pause >nul
    exit /b 1
)

call :log "[OK] Thin JAR: !THIN_JAR!"

REM 9. Check libraries directory
if not exist "!LIB_DIR!" (
    call :log "[ERROR] lib directory not found: !LIB_DIR!"
    call :log ""
    call :log "Press any key to exit..."
    pause >nul
    exit /b 1
)

set "LIB_COUNT=0"
for %%F in ("!LIB_DIR!\*.jar") do set /a LIB_COUNT+=1

if !LIB_COUNT! EQU 0 (
    call :log "[ERROR] No JAR files in !LIB_DIR!"
    call :log ""
    call :log "Press any key to exit..."
    pause >nul
    exit /b 1
)

call :log "[OK] Libraries: !LIB_DIR! (!LIB_COUNT! files)"

REM 10. Check native-libs (optional)
if exist "!NATIVE_LIBS_DIR!" (
    call :log "[OK] Native libs: !NATIVE_LIBS_DIR!"
    set "PATH=!NATIVE_LIBS_DIR!;%PATH%"
) else (
    call :log "[INFO] native-libs directory not found (optional, for Windows Authentication)"
)

call :log ""
call :log "========================================"
call :log "Launching application..."
call :log "========================================"
call :log "[INFO] Using Java: !JAVA_EXE!"
call :log ""

REM 11. Build classpath
set "CLASSPATH=!THIN_JAR!"
for %%F in ("!LIB_DIR!\*.jar") do (
    set "CLASSPATH=!CLASSPATH!;%%F"
)

REM 12. Launch application
call :log "[INFO] Launching application..."
call :log "[INFO] Command: !JAVA_EXE! -cp [classpath] org.springframework.boot.loader.launch.JarLauncher"
call :log ""

if "!LOG_TO_FILE!"=="true" (
    "!JAVA_EXE!" -cp "!CLASSPATH!" org.springframework.boot.loader.launch.JarLauncher >> "!LOG_FILE!" 2>&1
) else (
    "!JAVA_EXE!" -cp "!CLASSPATH!" org.springframework.boot.loader.launch.JarLauncher
)

set "EXIT_CODE=%ERRORLEVEL%"

if %EXIT_CODE% NEQ 0 (
    call :log ""
    call :log "========================================"
    call :log "[ERROR] Application exited with error"
    call :log "========================================"
    call :log ""
    call :log "Exit code: %EXIT_CODE%"
    call :log ""
    if "!LOG_TO_FILE!"=="true" (
        call :log "See details in log file: !LOG_FILE!"
    )
    call :log ""
    call :log "Press any key to exit..."
    pause >nul
    exit /b %EXIT_CODE%
)

call :log ""
call :log "[OK] Application exited successfully"
call :log ""
if "!LOG_TO_FILE!"=="true" (
    call :log "Log saved to: !LOG_FILE!"
)
call :log ""
call :log "Press any key to exit..."
pause >nul

endlocal
exit /b 0
