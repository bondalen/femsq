@echo off
REM ============================================================================
REM FEMSQ: Launch Thin JAR with external libraries (Windows)
REM ============================================================================
REM Usage:
REM   start.bat [thin-jar-name] [java-path]
REM
REM Examples:
REM   start.bat
REM   start.bat femsq-web-0.1.0.1-SNAPSHOT-thin.jar
REM   start.bat femsq-web-0.1.0.1-SNAPSHOT-thin.jar "C:\Program Files\Java\jdk-21\bin\java.exe"
REM ============================================================================

REM Do not change code page - use system default (866 for Russian Windows)

setlocal enabledelayedexpansion

echo ========================================
echo FEMSQ: Launch with external libraries
echo ========================================
echo.
echo [INFO] Current directory: %CD%
echo [INFO] Script directory: %~dp0
echo.

REM Determine script directory
set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%"

REM Parameters
set "THIN_JAR=%~1"
if "%THIN_JAR%"=="" set "THIN_JAR=femsq-web-0.1.0.1-SNAPSHOT-thin.jar"

set "LIB_DIR=%SCRIPT_DIR%lib"
set "NATIVE_LIBS_DIR=%SCRIPT_DIR%native-libs"

REM ============================================================================
REM Determine Java 21 path
REM ============================================================================
set "JAVA_EXE="

REM 1. Check command line parameter
if not "%~2"=="" (
    set "JAVA_EXE=%~2"
    echo [INFO] Using Java from parameter: %JAVA_EXE%
    goto :check_java
)

REM 2. Check environment variable
if defined JAVA21_EXE (
    set "JAVA_EXE=%JAVA21_EXE%"
    echo [INFO] Using Java from JAVA21_EXE variable: %JAVA_EXE%
    goto :check_java
)

REM 3. Check configuration file
if exist "%SCRIPT_DIR%java21-config.bat" (
    echo [DEBUG] Found config file: %SCRIPT_DIR%java21-config.bat
    call "%SCRIPT_DIR%java21-config.bat"
    if defined JAVA21_EXE (
        set "JAVA_EXE=%JAVA21_EXE%"
        echo [INFO] Using Java from config file: %JAVA_EXE%
        echo [DEBUG] JAVA21_HOME from config: %JAVA21_HOME%
        echo [DEBUG] JAVA21_EXE from config: %JAVA21_EXE%
        goto :check_java
    ) else (
        echo [WARNING] Config file exists but JAVA21_EXE is not set
        echo [WARNING] Check that java21-config.bat contains: set JAVA21_EXE=...
    )
)

REM 4. Automatic search for Java 21 in standard locations
echo [INFO] Searching for Java 21 in standard locations...
set "JAVA_SEARCH_PATHS[0]=C:\Program Files\Java\jdk-21\bin\java.exe"
set "JAVA_SEARCH_PATHS[1]=C:\Program Files\Java\jdk-21.0.1\bin\java.exe"
set "JAVA_SEARCH_PATHS[2]=C:\Program Files\Java\jdk-21.0.2\bin\java.exe"
set "JAVA_SEARCH_PATHS[3]=C:\Program Files\Eclipse Adoptium\jdk-21.0.1-hotspot\bin\java.exe"
set "JAVA_SEARCH_PATHS[4]=C:\Program Files\Eclipse Adoptium\jdk-21.0.2-hotspot\bin\java.exe"
set "JAVA_SEARCH_PATHS[5]=D:\java\jdk-21\bin\java.exe"
set "JAVA_SEARCH_PATHS[6]=D:\java\jdk-21.0.1\bin\java.exe"
set "JAVA_SEARCH_PATHS[7]=C:\Program Files (x86)\Java\jdk-21\bin\java.exe"
set "JAVA_SEARCH_PATHS[8]=D:\db\jre\zulu21.46.19-ca-jre21.0.9-win_x64\bin\java.exe"

for /L %%i in (0,1,8) do (
    call set "JAVA_PATH=%%JAVA_SEARCH_PATHS[%%i]%%"
    if exist "!JAVA_PATH!" (
        set "JAVA_EXE=!JAVA_PATH!"
        echo [OK] Found Java 21: !JAVA_PATH!
        goto :check_java
    )
)

REM 5. Use system Java from PATH (with warning)
where java >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Java not found in standard locations or PATH
    goto :java_not_found
)

set "JAVA_EXE=java"
echo [WARNING] Using system Java from PATH
echo [WARNING] Make sure it is Java 21 or higher
echo [WARNING] For reliability, specify Java 21 path explicitly

:check_java
REM Check Java version
echo [INFO] Checking Java version...
echo [DEBUG] Java path: %JAVA_EXE%

if "%JAVA_EXE%"=="" (
    echo [ERROR] Java path is empty
    echo [ERROR] Java was not determined by any method
    goto :java_not_found
)

if not exist "%JAVA_EXE%" (
    echo [ERROR] Java file not found: %JAVA_EXE%
    echo.
    echo Check that Java path is specified correctly in java21-config.bat
    echo.
    echo Expected path: D:\db\jre\zulu21.46.19-ca-jre21.0.9-win_x64\bin\java.exe
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
)

echo [OK] Java file exists: %JAVA_EXE%

"%JAVA_EXE%" -version 2>&1
if errorlevel 1 (
    echo [ERROR] Failed to launch Java: %JAVA_EXE%
    echo.
    echo Check that Java is installed and available.
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
)

"%JAVA_EXE%" -version 2>&1 | findstr /C:"version" /C:"21" >nul
if errorlevel 1 (
    echo [WARNING] Could not determine Java version
    echo [WARNING] Continuing, but problems may occur
) else (
    echo [OK] Java found and available
)
echo.

REM ============================================================================
REM Check for Thin JAR
REM ============================================================================
if not exist "%THIN_JAR%" (
    echo [ERROR] Thin JAR not found: %THIN_JAR%
    echo.
    echo Make sure the file exists in current directory.
    echo Current directory: %CD%
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
)

echo [OK] Thin JAR: %THIN_JAR%

REM ============================================================================
REM Check for libraries
REM ============================================================================
if not exist "%LIB_DIR%" (
    echo [ERROR] lib directory not found: %LIB_DIR%
    echo.
    echo INSTRUCTIONS FOR EXTRACTING LIBRARIES:
    echo 1. Open old Fat JAR in archiver (WinRAR, 7-Zip)
    echo 2. Find folder BOOT-INF\lib
    echo 3. Extract it to current directory
    echo 4. Rename BOOT-INF\lib to lib
    echo.
    echo Or use command:
    echo   jar xf femsq-web-0.1.0.1-SNAPSHOT.jar BOOT-INF\lib
    echo   move BOOT-INF\lib lib
    echo   rmdir /s /q BOOT-INF
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
)

REM Count libraries
set "LIB_COUNT=0"
for %%F in ("%LIB_DIR%\*.jar") do set /a LIB_COUNT+=1

if %LIB_COUNT% EQU 0 (
    echo [ERROR] No JAR files in %LIB_DIR%
    echo.
    echo Make sure libraries are extracted from Fat JAR.
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
)

echo [OK] Libraries: %LIB_DIR% (%LIB_COUNT% files)

REM ============================================================================
REM Check and setup native-libs (for Windows Authentication)
REM ============================================================================
REM native-libs should be next to thin JAR (not in lib/)
REM Application will create this folder automatically on startup if it doesn't exist

if exist "%NATIVE_LIBS_DIR%" (
    echo [OK] Native libs: %NATIVE_LIBS_DIR%
    
    REM Add native-libs to PATH for DLL loading
    set "PATH=%NATIVE_LIBS_DIR%;%PATH%"
    echo [OK] Added to PATH for Windows Authentication
) else (
    echo [INFO] native-libs directory not found
    echo        Application will create it automatically on startup
    echo        Windows Authentication will work after first launch
)

echo.
echo ========================================
echo Launching application...
echo ========================================
echo [INFO] Using Java: %JAVA_EXE%
echo.

REM ============================================================================
REM Launch application with external libraries
REM ============================================================================
REM Build classpath manually for reliability on Windows
REM First add thin JAR, then all libraries from lib/

set "CLASSPATH=%THIN_JAR%"
for %%F in ("%LIB_DIR%\*.jar") do (
    set "CLASSPATH=!CLASSPATH!;%%F"
)

REM Launch via Spring Boot Loader with explicit classpath
echo [INFO] Launching application...
echo [INFO] Command: "%JAVA_EXE%" -cp "[classpath]" org.springframework.boot.loader.launch.JarLauncher
echo.

"%JAVA_EXE%" -cp "!CLASSPATH!" org.springframework.boot.loader.launch.JarLauncher

REM Save exit code
set "EXIT_CODE=%ERRORLEVEL%"

REM Check exit code
if %EXIT_CODE% NEQ 0 (
    echo.
    echo ========================================
    echo [ERROR] Application exited with error
    echo ========================================
    echo.
    echo Exit code: %EXIT_CODE%
    echo.
    echo Possible causes:
    echo 1. Not all libraries are in lib\ folder
    echo 2. Java version is incompatible (requires Java 21 or higher)
    echo 3. Library version conflicts
    echo 4. Path issues (spaces, special characters in paths)
    echo.
    echo For diagnostics run manually:
    echo   "%JAVA_EXE%" -version
    echo   "%JAVA_EXE%" -cp "%THIN_JAR%;%LIB_DIR%\*" org.springframework.boot.loader.launch.JarLauncher
    echo.
    echo Or check application logs in logs\ folder
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b %EXIT_CODE%
)

echo.
echo [OK] Application exited successfully
echo.
echo Press any key to exit...
pause >nul

endlocal
exit /b 0

:java_not_found
echo.
echo ========================================
echo [ERROR] Java 21 not found
echo ========================================
echo.
echo To launch application, you need to specify path to Java 21.
echo.
echo Configuration options:
echo.
echo 1. Check java21-config.bat file:
echo    - File should exist: %SCRIPT_DIR%java21-config.bat
echo    - Should contain: set JAVA21_HOME=D:\db\jre\zulu21.46.19-ca-jre21.0.9-win_x64
echo    - Should contain: set JAVA21_EXE=%%JAVA21_HOME%%\bin\java.exe
echo.
echo 2. Set JAVA21_EXE environment variable:
echo    setx JAVA21_EXE "D:\db\jre\zulu21.46.19-ca-jre21.0.9-win_x64\bin\java.exe"
echo.
echo 3. Specify path when launching:
echo    start.bat femsq-web-0.1.0.1-SNAPSHOT-thin.jar "D:\db\jre\zulu21.46.19-ca-jre21.0.9-win_x64\bin\java.exe"
echo.
echo 4. Install Java 21 in standard location:
echo    C:\Program Files\Java\jdk-21\
echo.
echo Press any key to exit...
pause >nul
exit /b 1
