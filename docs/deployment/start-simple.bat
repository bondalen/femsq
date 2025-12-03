@echo off

REM ============================================================================
REM FEMSQ: Simple test batch script (Step 4 - Final)
REM ============================================================================
REM Usage: start-simple.bat [java-path] [thin-jar]
REM ============================================================================

REM Check parameter
if "%~1"=="" (
    echo [ERROR] Java path is required
    echo Usage: start-simple.bat "path\to\java.exe" [thin-jar]
    pause
    exit /b 1
)

REM Set variables
set "JAVA_EXE=%~1"
set "THIN_JAR=%~2"
set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%"
set "LIB_DIR=%SCRIPT_DIR%lib"
set "NATIVE_LIBS_DIR=%SCRIPT_DIR%native-libs"

REM Generate timestamp for log filename
for /f "delims=" %%i in ('powershell -command "Get-Date -Format \"yy-MMdd-HHmm\""') do set "DATETIME=%%i"
set "LOG_FILE=%SCRIPT_DIR%start_%DATETIME%.log"

REM Create log file
echo ======================================== > "%LOG_FILE%"
echo FEMSQ: Simple Test Step 4 - Final >> "%LOG_FILE%"
echo Date: %DATE% %TIME% >> "%LOG_FILE%"
echo ======================================== >> "%LOG_FILE%"
echo. >> "%LOG_FILE%"

REM Output to console
echo ========================================
echo FEMSQ: Simple Test Step 4 - Final
echo ========================================
echo.

REM Enable delayed expansion for loops (after parameter check)
setlocal enabledelayedexpansion

REM Step 1: Check Java executable
echo [STEP 1] Checking Java executable...
echo Java path: %JAVA_EXE%
echo Java path: %JAVA_EXE% >> "%LOG_FILE%"

if not exist "%JAVA_EXE%" (
    echo [ERROR] Java executable not found: %JAVA_EXE%
    echo [ERROR] Java executable not found: %JAVA_EXE% >> "%LOG_FILE%"
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
)

echo [OK] Java executable found
echo [OK] Java executable found >> "%LOG_FILE%"
echo.

REM Step 2: Auto-detect thin JAR if not specified
echo [STEP 2] Checking thin JAR...
if "%THIN_JAR%"=="" (
    echo Thin JAR not specified, searching...
    echo Thin JAR not specified, searching... >> "%LOG_FILE%"
    
    for %%F in (femsq-web-*-thin.jar) do (
        if exist "%%F" (
            set "THIN_JAR=%%F"
            echo [OK] Auto-detected thin JAR: %%F
            echo [OK] Auto-detected thin JAR: %%F >> "%LOG_FILE%"
            goto :jar_found
        )
    )
    
    echo [ERROR] Thin JAR not found in current directory
    echo [ERROR] Thin JAR not found in current directory >> "%LOG_FILE%"
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
) else (
    echo Thin JAR specified: %THIN_JAR%
    echo Thin JAR specified: %THIN_JAR% >> "%LOG_FILE%"
)

:jar_found

REM Remove quotes if present
set "THIN_JAR=%THIN_JAR:"=%"

REM Check if thin JAR exists
if not exist "%THIN_JAR%" (
    echo [ERROR] Thin JAR file not found: %THIN_JAR%
    echo [ERROR] Thin JAR file not found: %THIN_JAR% >> "%LOG_FILE%"
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
)

echo [OK] Thin JAR found: %THIN_JAR%
echo [OK] Thin JAR found: %THIN_JAR% >> "%LOG_FILE%"
echo.

REM Step 3: Check lib directory
echo [STEP 3] Checking lib directory...
echo Lib directory: %LIB_DIR%
echo Lib directory: %LIB_DIR% >> "%LOG_FILE%"

if not exist "%LIB_DIR%" (
    echo [ERROR] lib directory not found: %LIB_DIR%
    echo [ERROR] lib directory not found: %LIB_DIR% >> "%LOG_FILE%"
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
)

echo [OK] lib directory found
echo [OK] lib directory found >> "%LOG_FILE%"

REM Count JAR files in lib directory
set "LIB_COUNT=0"
for %%F in ("%LIB_DIR%\*.jar") do set /a LIB_COUNT+=1

if %LIB_COUNT% EQU 0 (
    echo [ERROR] No JAR files found in %LIB_DIR%
    echo [ERROR] No JAR files found in %LIB_DIR% >> "%LOG_FILE%"
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
)

echo [OK] Found %LIB_COUNT% JAR file(s) in lib directory
echo [OK] Found %LIB_COUNT% JAR file(s) in lib directory >> "%LOG_FILE%"
echo.

REM Step 4: Check native-libs (optional)
echo [STEP 4] Checking native-libs directory (optional)...
echo Native libs directory: %NATIVE_LIBS_DIR%
echo Native libs directory: %NATIVE_LIBS_DIR% >> "%LOG_FILE%"

if exist "%NATIVE_LIBS_DIR%" (
    echo [OK] native-libs directory found
    echo [OK] native-libs directory found >> "%LOG_FILE%"
) else (
    echo [INFO] native-libs directory not found (optional, for Windows Authentication)
    echo [INFO] native-libs directory not found (optional, for Windows Authentication) >> "%LOG_FILE%"
)
echo.

REM Summary
echo ========================================
echo Summary
echo ========================================
echo Java: %JAVA_EXE%
echo Thin JAR: %THIN_JAR%
echo Lib directory: %LIB_DIR%
echo Libraries found: %LIB_COUNT%
echo Native libs: %NATIVE_LIBS_DIR%
echo Script directory: %SCRIPT_DIR%
echo Log file: %LOG_FILE%
echo.
echo ======================================== >> "%LOG_FILE%"
echo Summary >> "%LOG_FILE%"
echo ======================================== >> "%LOG_FILE%"
echo Java: %JAVA_EXE% >> "%LOG_FILE%"
echo Thin JAR: %THIN_JAR% >> "%LOG_FILE%"
echo Lib directory: %LIB_DIR% >> "%LOG_FILE%"
echo Libraries found: %LIB_COUNT% >> "%LOG_FILE%"
echo Native libs: %NATIVE_LIBS_DIR% >> "%LOG_FILE%"
echo Script directory: %SCRIPT_DIR% >> "%LOG_FILE%"
echo Log file: %LOG_FILE% >> "%LOG_FILE%"
echo.
echo Test successful! All checks passed.
echo Test successful! All checks passed. >> "%LOG_FILE%"
echo.

REM Step 5: Build classpath and launch application
echo ========================================
echo [STEP 5] Launching application...
echo ========================================
echo.
echo ======================================== >> "%LOG_FILE%"
echo [STEP 5] Launching application... >> "%LOG_FILE%"
echo ======================================== >> "%LOG_FILE%"
echo. >> "%LOG_FILE%"

REM Add native-libs to PATH if exists
if exist "%NATIVE_LIBS_DIR%" (
    set "PATH=%NATIVE_LIBS_DIR%;%PATH%"
    echo [INFO] Added native-libs to PATH
    echo [INFO] Added native-libs to PATH >> "%LOG_FILE%"
)

REM Build classpath: start with thin JAR
set "CLASSPATH=!THIN_JAR!"

REM Add all JAR files from lib directory
for %%F in ("%LIB_DIR%\*.jar") do (
    set "CLASSPATH=!CLASSPATH!;%%F"
)

echo [INFO] Classpath built (thin JAR + %LIB_COUNT% libraries)
echo [INFO] Classpath built (thin JAR + %LIB_COUNT% libraries) >> "%LOG_FILE%"
echo [INFO] Using Java: %JAVA_EXE%
echo [INFO] Using Java: %JAVA_EXE% >> "%LOG_FILE%"
echo [INFO] Launching: org.springframework.boot.loader.launch.JarLauncher
echo [INFO] Launching: org.springframework.boot.loader.launch.JarLauncher >> "%LOG_FILE%"
echo.

REM Launch application
"%JAVA_EXE%" -cp "!CLASSPATH!" org.springframework.boot.loader.launch.JarLauncher >> "%LOG_FILE%" 2>&1

set "EXIT_CODE=%ERRORLEVEL%"

if %EXIT_CODE% NEQ 0 (
    echo.
    echo ========================================
    echo [ERROR] Application exited with error
    echo ========================================
    echo.
    echo Exit code: %EXIT_CODE%
    echo See details in log file: %LOG_FILE%
    echo.
    echo ======================================== >> "%LOG_FILE%"
    echo [ERROR] Application exited with error >> "%LOG_FILE%"
    echo Exit code: %EXIT_CODE% >> "%LOG_FILE%"
    echo ======================================== >> "%LOG_FILE%"
    echo.
    echo Press any key to exit...
    pause >nul
    endlocal
    exit /b %EXIT_CODE%
)

echo.
echo ========================================
echo [OK] Application exited successfully
echo ========================================
echo.
echo Log saved to: %LOG_FILE%
echo.
echo ======================================== >> "%LOG_FILE%"
echo [OK] Application exited successfully >> "%LOG_FILE%"
echo ======================================== >> "%LOG_FILE%"
echo.
echo Press any key to exit...
pause >nul

endlocal
exit /b 0
