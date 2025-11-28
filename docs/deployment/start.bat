@echo off
REM ============================================================================
REM FEMSQ: Запуск Thin JAR с внешними библиотеками (Windows)
REM ============================================================================
REM Использование:
REM   start.bat [thin-jar-name]
REM
REM Примеры:
REM   start.bat
REM   start.bat femsq-web-0.1.0.1-SNAPSHOT-thin.jar
REM ============================================================================

setlocal enabledelayedexpansion

echo ========================================
echo FEMSQ: Запуск с внешними библиотеками
echo ========================================
echo.

REM Определяем директорию скрипта
set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%"

REM Параметры
set "THIN_JAR=%~1"
if "%THIN_JAR%"=="" set "THIN_JAR=femsq-web-0.1.0.1-SNAPSHOT-thin.jar"

set "LIB_DIR=%SCRIPT_DIR%lib"
set "NATIVE_LIBS_DIR=%SCRIPT_DIR%native-libs"

REM ============================================================================
REM Проверка наличия Thin JAR
REM ============================================================================
if not exist "%THIN_JAR%" (
    echo [ERROR] Thin JAR не найден: %THIN_JAR%
    echo.
    echo Убедитесь, что файл существует в текущей директории.
    echo.
    pause
    exit /b 1
)

echo [OK] Thin JAR: %THIN_JAR%

REM ============================================================================
REM Проверка наличия библиотек
REM ============================================================================
if not exist "%LIB_DIR%" (
    echo [ERROR] Директория lib не найдена: %LIB_DIR%
    echo.
    echo ИНСТРУКЦИЯ ПО ИЗВЛЕЧЕНИЮ БИБЛИОТЕК:
    echo 1. Откройте старый Fat JAR в архиваторе (WinRAR, 7-Zip)
    echo 2. Найдите папку BOOT-INF\lib
    echo 3. Извлеките её в текущую директорию
    echo 4. Переименуйте BOOT-INF\lib в lib
    echo.
    echo Или используйте команду:
    echo   jar xf femsq-web-0.1.0.1-SNAPSHOT.jar BOOT-INF\lib
    echo   move BOOT-INF\lib lib
    echo   rmdir /s /q BOOT-INF
    echo.
    pause
    exit /b 1
)

REM Подсчитываем библиотеки
set "LIB_COUNT=0"
for %%F in ("%LIB_DIR%\*.jar") do set /a LIB_COUNT+=1

if %LIB_COUNT% EQU 0 (
    echo [ERROR] В %LIB_DIR% нет JAR файлов
    echo.
    pause
    exit /b 1
)

echo [OK] Библиотеки: %LIB_DIR% ^(%LIB_COUNT% файлов^)

REM ============================================================================
REM Проверка и настройка native-libs (для Windows Authentication)
REM ============================================================================
REM native-libs должна быть рядом с тонким JAR (не в lib/)
REM Приложение автоматически создаст эту папку при запуске, если её нет

if exist "%NATIVE_LIBS_DIR%" (
    echo [OK] Native libs: %NATIVE_LIBS_DIR%
    
    REM Добавляем native-libs в PATH для загрузки DLL
    set "PATH=%NATIVE_LIBS_DIR%;%PATH%"
    echo [OK] Добавлено в PATH для Windows Authentication
) else (
    echo [INFO] Директория native-libs не найдена
    echo        Приложение создаст её автоматически при запуске
    echo        Windows Authentication будет работать после первого запуска
)

echo.
echo ========================================
echo Запуск приложения...
echo ========================================
echo.

REM ============================================================================
REM Запуск приложения с внешними библиотеками
REM ============================================================================
REM Формируем classpath: сначала все библиотеки, затем тонкий JAR
REM Используем явный classpath для Spring Boot Loader 3.x

set "CLASSPATH=%THIN_JAR%"
for %%F in ("%LIB_DIR%\*.jar") do (
    set "CLASSPATH=!CLASSPATH!;%%F"
)

REM Запуск через Spring Boot Loader с явным classpath
java -cp "%CLASSPATH%" org.springframework.boot.loader.launch.JarLauncher

REM Проверяем код выхода
if errorlevel 1 (
    echo.
    echo [ERROR] Приложение завершилось с ошибкой
    pause
    exit /b 1
)

endlocal