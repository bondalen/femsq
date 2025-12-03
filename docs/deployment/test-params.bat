@echo off
setlocal enabledelayedexpansion

echo ========================================
echo Testing parameter parsing
echo ========================================
echo.
echo Parameter 1 (raw): [%1]
echo Parameter 1 (%~1): [%~1]
echo Parameter 2 (raw): [%2]
echo Parameter 2 (%~2): [%~2]
echo Parameter 3 (raw): [%3]
echo Parameter 3 (%~3): [%~3]
echo.

set "JAVA_EXE=%~1"
set "THIN_JAR=%~2"
set "NO_LOG=%~3"

echo After parsing:
echo JAVA_EXE: [%JAVA_EXE%]
echo THIN_JAR: [%THIN_JAR%]
echo NO_LOG: [%NO_LOG%]
echo.

if "%JAVA_EXE%"=="" (
    echo ERROR: JAVA_EXE is empty!
) else (
    echo OK: JAVA_EXE is set
)

pause
