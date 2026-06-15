/*
=============================================================================
Файл:    06b_CREATE_PROCEDURE_spMstrg_2606_spPath.sql
Объект:  ags.spMstrg_2606 (путь Ступень 3 — SP PercentBrn + #temp)
Дата:    2026-06-15
Этап:    14.3 — только продуктив SQL 2012 (см. MSSQL2012/06b). На dev SQL 2022 медленнее fn.
=============================================================================
ПРЕДУСЛОВИЯ: 04b, 05b (prod: INSERT EXEC spFn2), 05 (fn PercentBrn — схема TOP 0)
=============================================================================*/
USE [FishEye];
GO
IF OBJECT_ID(N'ags.spMstrg_2606', N'P') IS NOT NULL DROP PROCEDURE ags.spMstrg_2606;
GO

SET NOCOUNT ON;
PRINT N'=== 06b: spMstrg_2606 (SP-path, Ступень 3) ===';

DECLARE @sql  nvarchar(max);
DECLARE @chk  int;
DECLARE @declStart int;
DECLARE @insertPos int;

SET @sql = OBJECT_DEFINITION(OBJECT_ID(N'ags.spMstrg_2605'));
IF @sql IS NULL
BEGIN
    RAISERROR(N'OBJECT_DEFINITION вернул NULL для ags.spMstrg_2605', 16, 1);
    RETURN;
END

SET @sql = REPLACE(@sql, N'CREATE   PROCEDURE ags.spMstrg_2605', N'CREATE PROCEDURE ags.spMstrg_2606');
SET @sql = REPLACE(@sql, N'CREATE PROCEDURE ags.spMstrg_2605', N'CREATE PROCEDURE ags.spMstrg_2606');
SET @sql = REPLACE(@sql,
    N'@ipgSt         nvarchar(255) = NULL',
    N'@ipgStKey      int           = NULL,' + CHAR(10)
    + N'    @stCostKey     int           = NULL');
SET @sql = REPLACE(@sql,
    N'ags.fnIpgChRsltCstUtlPercentBrn_2605(@ipgCh, @ipgSt)',
    N'ags.fnIpgChRsltCstUtlPercentBrn_2606(@ipgCh, @ipgStKey, @stCostKey)');
SET @sql = REPLACE(@sql,
    N'select * from ags.fnIpgChRsltCstUtlPercentBrn_2606(@ipgCh, @ipgStKey, @stCostKey)',
    N'exec ags.spIpgChRsltCstUtlPercentBrn_2606 @ipgCh, @ipgStKey, @stCostKey');
SET @sql = REPLACE(@sql, N'spMstrg_2408_ResultSet', N'spMstrg_2606_ResultSet');

SET @declStart = CHARINDEX(N'declare @TableFnIpgChRsltCstUtlPercentBrn_2408 table', LOWER(@sql));
SET @insertPos = CHARINDEX(N'insert into @TableFnIpgChRsltCstUtlPercentBrn_2408', LOWER(@sql));
IF @declStart = 0 OR @insertPos = 0
BEGIN
    RAISERROR(N'Блок declare/insert @TableFn не найден', 16, 1);
    RETURN;
END
SET @sql = STUFF(@sql, @declStart, @insertPos - @declStart,
    N'IF OBJECT_ID(N''tempdb..#TableFnIpgChRsltCstUtlPercentBrn_2606'') IS NOT NULL DROP TABLE #TableFnIpgChRsltCstUtlPercentBrn_2606;' + CHAR(10)
    + N'    SELECT TOP 0 * INTO #TableFnIpgChRsltCstUtlPercentBrn_2606 FROM ags.fnIpgChRsltCstUtlPercentBrn_2606(@ipgCh, @ipgStKey, @stCostKey);' + CHAR(10)
    + CHAR(10));
SET @sql = REPLACE(@sql, N'@TableFnIpgChRsltCstUtlPercentBrn_2408', N'#TableFnIpgChRsltCstUtlPercentBrn_2606');
SET @sql = REPLACE(@sql,
    N'insert into #TableFnIpgChRsltCstUtlPercentBrn_2606' + CHAR(10) + N'    exec ags.spIpgChRsltCstUtlPercentBrn_2606 @ipgCh, @ipgStKey, @stCostKey',
    N'exec ags.spIpgChRsltCstUtlPercentBrn_2606 @ipgCh, @ipgStKey, @stCostKey');

SET @chk = CHARINDEX(N'exec ags.spIpgChRsltCstUtlPercentBrn_2606', LOWER(@sql));
IF @chk = 0 BEGIN RAISERROR(N'EXEC spPercentBrn не найден', 16, 1); RETURN; END

EXEC sp_executesql @sql;
PRINT N'=== 06b: spMstrg_2606 (SP-path) применён ===';
GO
