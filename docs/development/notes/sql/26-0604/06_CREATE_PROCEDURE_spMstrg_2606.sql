/*
=============================================================================
Файл:    06_CREATE_PROCEDURE_spMstrg_2606.sql
Объект:  ags.spMstrg_2606
Дата:    2026-06-11
Этап:    11 (chat-plan-26-0604-spMstrg-2606-v2)
=============================================================================
НАЗНАЧЕНИЕ:
  Процедура отчёта освоения _2606. Шаблон — spMstrg_2605 (SaveToTables + SELECT).
  @ipgStKey / @stCostKey int — DAG-фильтры (NULL = без фильтра).
  @saveToTables bit — 0=SELECT×7 (Access), 1=TRUNCATE+INSERT в *_2606_ResultSet*.
ЗАВИСИМОСТИ:
  fnIpgChRsltCstUtlPercentBrn_2606, spMstrg_2606_ResultSet1..7 (05b)
ROLLBACK: 08_ROLLBACK.sql
=============================================================================*/
USE [FishEye];
GO
SET NOCOUNT ON;
PRINT N'=== 06: Создание ags.spMstrg_2606 ===';

DECLARE @sql  nvarchar(max);
DECLARE @chk  int;

SET @sql = OBJECT_DEFINITION(OBJECT_ID(N'ags.spMstrg_2605'));
IF @sql IS NULL
BEGIN
    RAISERROR(N'OBJECT_DEFINITION вернул NULL для ags.spMstrg_2605', 16, 1);
    RETURN;
END
PRINT N'Длина исходного текста spMstrg_2605: ' + CAST(LEN(@sql) AS nvarchar(20));

-- B1: имя процедуры
SET @sql = REPLACE(@sql, N'CREATE   PROCEDURE ags.spMstrg_2605', N'CREATE OR ALTER PROCEDURE ags.spMstrg_2606');
SET @sql = REPLACE(@sql, N'CREATE PROCEDURE ags.spMstrg_2605', N'CREATE OR ALTER PROCEDURE ags.spMstrg_2606');

-- B2: параметры (@ipgSt nvarchar → @ipgStKey + @stCostKey int)
SET @sql = REPLACE(@sql,
    N'@ipgSt         nvarchar(255) = NULL',
    N'@ipgStKey      int           = NULL,' + CHAR(10)
    + N'    @stCostKey     int           = NULL');

-- B3: вызов PercentBrn
SET @sql = REPLACE(@sql,
    N'ags.fnIpgChRsltCstUtlPercentBrn_2605(@ipgCh, @ipgSt)',
    N'ags.fnIpgChRsltCstUtlPercentBrn_2606(@ipgCh, @ipgStKey, @stCostKey)');

-- B4: целевые таблицы ResultSet (_2606, не _2408)
SET @sql = REPLACE(@sql, N'spMstrg_2408_ResultSet', N'spMstrg_2606_ResultSet');

-- B5: имя временной табличной переменной (косметика)
SET @sql = REPLACE(@sql,
    N'@TableFnIpgChRsltCstUtlPercentBrn_2408',
    N'@TableFnIpgChRsltCstUtlPercentBrn_2606');

-- Проверки замен
SET @chk = CHARINDEX(N'spMstrg_2606', @sql);
IF @chk = 0 BEGIN RAISERROR(N'Замена spMstrg_2606 не применилась', 16, 1); RETURN; END
SET @chk = CHARINDEX(N'fnIpgChRsltCstUtlPercentBrn_2606', @sql);
IF @chk = 0 BEGIN RAISERROR(N'Замена PercentBrn_2606 не применилась', 16, 1); RETURN; END
SET @chk = CHARINDEX(N'@ipgStKey', @sql);
IF @chk = 0 BEGIN RAISERROR(N'Замена @ipgStKey не применилась', 16, 1); RETURN; END
SET @chk = CHARINDEX(N'spMstrg_2408_ResultSet', @sql);
IF @chk > 0 BEGIN RAISERROR(N'Остались ссылки на spMstrg_2408_ResultSet', 16, 1); RETURN; END
SET @chk = CHARINDEX(N'fnIpgChRsltCstUtlPercentBrn_2605', @sql);
IF @chk > 0 BEGIN RAISERROR(N'Остались ссылки на PercentBrn_2605', 16, 1); RETURN; END

PRINT N'Итоговая длина SQL: ' + CAST(LEN(@sql) AS nvarchar(20));
PRINT N'Применяем CREATE OR ALTER PROCEDURE ags.spMstrg_2606...';
EXEC sp_executesql @sql;
PRINT N'ags.spMstrg_2606 создана успешно!';
GO
