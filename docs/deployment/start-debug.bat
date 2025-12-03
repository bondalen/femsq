@echo off
REM ============================================================================
REM FEMSQ: Launch Thin JAR with external libraries (Windows) - DEBUG version
REM ============================================================================
REM This version outputs detailed diagnostic information
REM Supports same Java 21 path specification methods as start.bat

REM Do not change code page - use system default (866 for Russian Windows)

setlocal enabledelayedexpansion

echo ========================================
echo FEMSQ: Launch with external libraries (DEBUG)
echo ========================================
echo.

set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%"

set "THIN_JAR=%~1"
if "%THIN_JAR%"=="" set "THIN_JAR=femsq-web-0.1.0.1-SNAPSHOT-thin.jar"
set "LIB_DIR=%SCRIPT_DIR%lib"

REM ============================================================================
REM Determine Java 21 path (same as start.bat)
REM ============================================================================
set "JAVA_EXE="

REM 1. Check command line parameter
if not "%~2"=="" (
    set "JAVA_EXE=%~2"
    echo [DEBUG] Using Java from parameter: %JAVA_EXE%
    goto :check_java
)

REM 2. Check environment variable
if defined JAVA21_EXE (
    set "JAVA_EXE=%JAVA21_EXE%"
    echo [DEBUG] Using Java from JAVA21_EXE variable: %JAVA_EXE%
    goto :check_java
)

REM 3. Check configuration file
if exist "%SCRIPT_DIR%java21-config.bat" (
    call "%SCRIPT_DIR%java21-config.bat"
    if defined JAVA21_EXE (
        set "JAVA_EXE=%JAVA21_EXE%"
        echo [DEBUG] Using Java from config file: %JAVA_EXE%
        goto :check_java
    )
)

REM 4. Automatic search for Java 21
echo [DEBUG] Searching for Java 21 in standard locations...
set "JAVA_SEARCH_PATHS[0]=C:\Program Files\Java\jdk-21\bin\java.exe"
set "JAVA_SEARCH_PATHS[1]=C:\Program Files\Java\jdk-21.0.1\bin\java.exe"
set "JAVA_SEARCH_PATHS[2]=C:\Program Files\Java\jdk-21.0.2\bin\java.exe"
set "JAVA_SEARCH_PATHS[3]=C:\Program Files\Eclipse Adoptium\jdk-21.0.1-hotspot\bin\java.exe"
set "JAVA_SEARCH_PATHS[4]=C:\Program Files\Eclipse Adoptium\jdk-21.0.2-hotspot\bin\java.exe"
set "JAVA_SEARCH_PATHS[5]=D:\java\jdk-21\bin\java.exe"
set "JAVA_SEARCH_PATHS[6]=D:\java\jdk-21.0.1\bin\java.exe"
set "JAVA_SEARCH_PATHS[7]=C:\Program Files (x86)\Java\jdk-21\bin\java.exe"

for /L %%i in (0,1,7) do (
    call set "JAVA_PATH=%%JAVA_SEARCH_PATHS[%%i]%%"
    if exist "!JAVA_PATH!" (
        set "JAVA_EXE=!JAVA_PATH!"
        echo [DEBUG] Found Java 21: !JAVA_PATH!
        goto :check_java
    )
)

REM 5. Use system Java from PATH
where java >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Java not found
    goto :java_not_found
)

set "JAVA_EXE=java"
echo [WARNING] Using system Java from PATH
echo [WARNING] Make sure it is Java 21 or higher

:check_java
REM Check Java
echo.
echo [DEBUG] ========================================
echo [DEBUG] Checking Java
echo [DEBUG] ========================================
echo [DEBUG] Java path: %JAVA_EXE%
echo.

if "%JAVA_EXE%"=="" (
    echo [ERROR] Java not determined
    echo.
    echo Press any key to exit...
    pause >nul
    goto :java_not_found
)

echo [DEBUG] Executing: "%JAVA_EXE%" -version
"%JAVA_EXE%" -version
if errorlevel 1 (
    echo [ERROR] Failed to launch Java
    echo [ERROR] Check path: %JAVA_EXE%
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
)

echo.
echo [DEBUG] Checking Java version...
"%JAVA_EXE%" -version 2>&1 | findstr /C:"version" /C:"21" >nul
if errorlevel 1 (
    echo [WARNING] Could not determine Java version
    echo [WARNING] Continuing, but problems may occur
) else (
    echo [OK] Java found and available
)
echo.

REM Check files
echo [DEBUG] ========================================
echo [DEBUG] Checking files
echo [DEBUG] ========================================
if not exist "%THIN_JAR%" (
    echo [ERROR] Thin JAR not found: %THIN_JAR%
    echo Current directory: %CD%
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
)
echo [OK] Thin JAR: %THIN_JAR%

if not exist "%LIB_DIR%" (
    echo [ERROR] lib directory not found: %LIB_DIR%
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
)

REM Count libraries
set "LIB_COUNT=0"
set "JAR_LIST="
for %%F in ("%LIB_DIR%\*.jar") do (
    set /a LIB_COUNT+=1
    set "JAR_LIST=!JAR_LIST!%%~nxF "
)

echo [OK] Libraries found: %LIB_COUNT%

if %LIB_COUNT% EQU 0 (
    echo [ERROR] No JAR files in %LIB_DIR%
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
)

echo [DEBUG] First 10 libraries:
set "COUNT=0"
for %%F in ("%LIB_DIR%\*.jar") do (
    set /a COUNT+=1
    if !COUNT! LEQ 10 (
        echo   !COUNT!. %%~nxF
    )
)
if %LIB_COUNT% GTR 10 (
    echo   ... and %LIB_COUNT% more libraries
)
echo.

REM Build classpath
echo [DEBUG] ========================================
echo [DEBUG] Building classpath
echo [DEBUG] ========================================
set "CLASSPATH=%THIN_JAR%"
set "CP_COUNT=1"
for %%F in ("%LIB_DIR%\*.jar") do (
    set "CLASSPATH=!CLASSPATH!;%%F"
    set /a CP_COUNT+=1
)
echo [DEBUG] Classpath contains: %CP_COUNT% elements
echo [DEBUG] First element: %THIN_JAR%
echo.

REM Attempt 1: Using wildcard
echo [DEBUG] ========================================
echo [DEBUG] Attempt 1: Using wildcard
echo [DEBUG] ========================================
echo [DEBUG] Command:
echo   "%JAVA_EXE%" -cp "%THIN_JAR%;%LIB_DIR%\*" org.springframework.boot.loader.launch.JarLauncher
echo.
echo [DEBUG] Launching...
"%JAVA_EXE%" -cp "%THIN_JAR%;%LIB_DIR%\*" org.springframework.boot.loader.launch.JarLauncher 2>&1
set "EXIT_CODE=%ERRORLEVEL%"

if %EXIT_CODE% EQU 0 (
    echo.
    echo [OK] Application launched successfully (method 1: wildcard)
    endlocal
    exit /b 0
)

echo.
echo [DEBUG] Attempt 1 failed (code: %EXIT_CODE%)
echo.

REM Attempt 2: Using explicit classpath
echo [DEBUG] ========================================
echo [DEBUG] Attempt 2: Using explicit classpath
echo [DEBUG] ========================================
echo [DEBUG] Command:
echo   "%JAVA_EXE%" -cp "!CLASSPATH!" org.springframework.boot.loader.launch.JarLauncher
echo.
echo [DEBUG] Launching...
"%JAVA_EXE%" -cp "!CLASSPATH!" org.springframework.boot.loader.launch.JarLauncher 2>&1
set "EXIT_CODE=%ERRORLEVEL%"

if %EXIT_CODE% EQU 0 (
    echo.
    echo [OK] Application launched successfully (method 2: explicit classpath)
    endlocal
    exit /b 0
)

echo.
echo [DEBUG] ========================================
echo [ERROR] Both attempts failed
echo [DEBUG] ========================================
echo.
echo Exit code: %EXIT_CODE%
echo.
echo [DEBUG] Diagnostic information:
echo   Java: %JAVA_EXE%
echo   Thin JAR: %THIN_JAR%
echo   Libraries: %LIB_DIR% (%LIB_COUNT% files)
echo.
echo [DEBUG] Check:
echo   1. Java version: "%JAVA_EXE%" -version
echo   2. All libraries in lib\
echo   3. Logs in logs\ folder (if created)
echo   4. Java 21 path is specified correctly
echo.
echo Press any key to exit...
pause >nul
exit /b %EXIT_CODE%

:java_not_found
echo.
echo [ERROR] ========================================
echo [ERROR] Java 21 not found
echo [ERROR] ========================================
echo.
echo To launch application, you need to specify path to Java 21.
echo.
echo Configuration options:
echo.
echo 1. Create java21-config.bat file in this folder:
echo    Copy java21-config.bat.example to java21-config.bat
echo    And specify Java 21 path in it
echo.
echo 2. Set JAVA21_EXE environment variable:
echo    setx JAVA21_EXE "C:\Program Files\Java\jdk-21\bin\java.exe"
echo.
echo 3. Specify path when launching:
echo    start-debug.bat femsq-web-0.1.0.1-SNAPSHOT-thin.jar "C:\Program Files\Java\jdk-21\bin\java.exe"
echo.
echo Press any key to exit...
pause >nul
exit /b 1
