@echo off
REM ============================================================================
REM FEMSQ: Тестовая версия скрипта для диагностики проблем
REM ============================================================================
REM Этот скрипт выводит максимально подробную информацию для диагностики

chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion

echo ========================================
echo FEMSQ: Тестовая версия (диагностика)
echo ========================================
echo.
echo [TEST] Скрипт запущен
echo [TEST] Текущая директория: %CD%
echo [TEST] Директория скрипта: %~dp0
echo.

REM Проверка параметров
echo [TEST] Параметры командной строки:
echo [TEST]   Параметр 1 (Thin JAR): %~1
echo [TEST]   Параметр 2 (Java путь): %~2
echo.

REM Проверка Java
echo [TEST] Проверка Java...
where java >nul 2>&1
if errorlevel 1 (
    echo [TEST] Java не найдена в PATH
) else (
    echo [TEST] Java найдена в PATH
    java -version
)
echo.

REM Проверка файлов
echo [TEST] Проверка файлов в текущей директории:
dir /b *.jar 2>nul
if errorlevel 1 (
    echo [TEST] JAR файлы не найдены
) else (
    echo [TEST] JAR файлы найдены
)
echo.

REM Проверка папки lib
echo [TEST] Проверка папки lib:
if exist "lib" (
    echo [TEST] Папка lib существует
    dir /b lib\*.jar 2>nul | find /c /v ""
    echo [TEST] JAR файлов в lib:
) else (
    echo [TEST] Папка lib не найдена
)
echo.

echo [TEST] Тест завершён
echo.
echo Нажмите любую клавишу для выхода...
pause >nul
