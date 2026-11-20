@echo off
REM C2 / D1.1 — выгрузка эталона структуры ИПГ с прода (только чтение).
REM ЗАПАСНОЙ способ: нужен bcp.exe в PATH. Предпочтительно 01c_EXPORT_sqlcmd_mode.sql в SSMS.
REM Запуск: из cmd.exe (не двойной клик из проводника — окно закроется).
REM lastUpdated: 2026-11-20

cd /d "%~dp0"
setlocal
set SERVER=SPB-05-NV-SQL1
set DATABASE=FishEye
set OUT=C:\Temp\femsq_ipg_st_etalon_20261120

where bcp >nul 2>&1
if errorlevel 1 (
  echo FAIL: bcp.exe не найден в PATH.
  echo Используйте 01c_EXPORT_sqlcmd_mode.sql в SSMS ^(SQLCMD Mode^).
  pause
  exit /b 1
)

if not exist "%OUT%" mkdir "%OUT%"

echo === BCP etalon to %OUT% ===
echo Server=%SERVER% DB=%DATABASE%
echo.

call :export stType || goto :fail
call :export st || goto :fail
call :export stIpg || goto :fail
call :export stIpgNm || goto :fail
call :export stCost || goto :fail
call :export stCostNm || goto :fail
call :export stRel || goto :fail
call :export stNet || goto :fail
call :export stNetPn || goto :fail
call :export ipg || goto :fail
call :export ipgCh || goto :fail
call :export ipgPn || goto :fail
call :export ipgStPn || goto :fail
call :export ipgSh || goto :fail

bcp "SELECT * FROM ags.[stIpgOutLimPn_2606]" queryout "%OUT%\stIpgOutLimPn_2606.tsv" -c -T -S %SERVER% -d %DATABASE%
if errorlevel 1 (
  echo WARN: stIpgOutLimPn_2606 not exported ^(bcp error / rights / path^) > "%OUT%\stIpgOutLimPn_2606.WARN.txt"
)

echo.
echo === DONE ===
echo Pack folder %OUT% into AES zip and send to отПрод session 26-1120_14-45
dir /b "%OUT%"
pause
endlocal
goto :eof

:fail
echo.
echo FAIL — останов. Смотрите сообщение bcp выше.
echo Предпочтительно: 01c_EXPORT_sqlcmd_mode.sql в SSMS.
pause
exit /b 1

:export
echo --- %~1 ---
bcp "SELECT * FROM ags.[%~1]" queryout "%OUT%\%~1.tsv" -c -T -S %SERVER% -d %DATABASE%
if errorlevel 1 (
  echo FAIL %~1
  exit /b 1
)
exit /b 0
