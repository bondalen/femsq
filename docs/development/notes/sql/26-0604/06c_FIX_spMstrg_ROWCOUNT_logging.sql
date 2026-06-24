USE [FishEye];
GO
-- =============================================================================
-- 06c_FIX_spMstrg_ROWCOUNT_logging.sql
-- Исправление лога «Записей сохранено: 0» — @@ROWCOUNT сбрасывается PRINT(DATEDIFF).
-- Патчит ags.spMstrg_2605; затем 06_CREATE_PROCEDURE_spMstrg_2606.sql.
-- Автор: Александр | Дата: 2026-06-15
-- =============================================================================
SET NOCOUNT ON;
GO

DECLARE @sql    nvarchar(max);
DECLARE @proc   sysname = N'ags.spMstrg_2605';
DECLARE @find   nvarchar(120) = N'PRINT ''Записей сохранено: '' + CAST(@@ROWCOUNT AS nvarchar(20));';
DECLARE @pos    int;
DECLARE @repl   nvarchar(160);
DECLARE @n      int = 1;

SET @sql = OBJECT_DEFINITION(OBJECT_ID(@proc));
IF @sql IS NULL
BEGIN
    RAISERROR(N'06c: %s не найдена', 16, 1, @proc);
    RETURN;
END

IF CHARINDEX(N'@SavedRs1', @sql) = 0
    SET @sql = REPLACE(@sql,
        N'DECLARE @StepName nvarchar(100);',
        N'DECLARE @StepName nvarchar(100);' + CHAR(10)
        + N'    DECLARE @SavedRs1 int, @SavedRs2 int, @SavedRs3 int, @SavedRs4 int, @SavedRs5 int, @SavedRs6 int, @SavedRs7 int;');

IF CHARINDEX(N'SET @SavedRs1 = @@ROWCOUNT', @sql) = 0
    SET @sql = REPLACE(@sql,
        N'INSERT INTO ags.spMstrg_2408_ResultSet1' + CHAR(10)
        + N'    SELECT * FROM @TableFnIpgChRsltCstUtlPercentBrn_2408;' + CHAR(10) + N'    END',
        N'INSERT INTO ags.spMstrg_2408_ResultSet1' + CHAR(10)
        + N'    SELECT * FROM @TableFnIpgChRsltCstUtlPercentBrn_2408;' + CHAR(10)
        + N'    SET @SavedRs1 = @@ROWCOUNT;' + CHAR(10) + N'    END');

IF CHARINDEX(N'SET @SavedRs4 = @@ROWCOUNT', @sql) = 0
    SET @sql = REPLACE(@sql,
        N'INSERT INTO ags.spMstrg_2408_ResultSet4' + CHAR(10)
        + N'    SELECT * FROM @TableFnIpgChRsltCstUtlPercentBrnRep01_2408;' + CHAR(10) + N'    END',
        N'INSERT INTO ags.spMstrg_2408_ResultSet4' + CHAR(10)
        + N'    SELECT * FROM @TableFnIpgChRsltCstUtlPercentBrnRep01_2408;' + CHAR(10)
        + N'    SET @SavedRs4 = @@ROWCOUNT;' + CHAR(10) + N'    END');

IF CHARINDEX(N'SET @SavedRs6 = @@ROWCOUNT', @sql) = 0
    SET @sql = REPLACE(@sql,
        N'FROM @TableFnIpgChRsltCstUtlPercentBrnRepSrc01_2408;' + CHAR(10) + N'    END',
        N'FROM @TableFnIpgChRsltCstUtlPercentBrnRepSrc01_2408;' + CHAR(10)
        + N'    SET @SavedRs6 = @@ROWCOUNT;' + CHAR(10) + N'    END');

DECLARE @rs int = 2;
WHILE @rs <= 7
BEGIN
    IF @rs IN (2, 3, 5, 7) AND CHARINDEX(N'SET @SavedRs' + CAST(@rs AS nvarchar(1)) + N' = @@ROWCOUNT', @sql) = 0
    BEGIN
        DECLARE @p int = CHARINDEX(N'INSERT INTO ags.spMstrg_2408_ResultSet' + CAST(@rs AS nvarchar(1)), @sql);
        DECLARE @e int = CHARINDEX(N'    END' + CHAR(10) + N'    ELSE BEGIN', @sql, @p);
        IF @p > 0 AND @e > @p
            SET @sql = STUFF(@sql, @e, 0, CHAR(10) + N'    SET @SavedRs' + CAST(@rs AS nvarchar(1)) + N' = @@ROWCOUNT;');
    END
    SET @rs = @rs + 1;
END

WHILE @n <= 7
BEGIN
    SET @pos = CHARINDEX(@find, @sql);
    IF @pos = 0 BREAK;
    SET @repl = N'PRINT ''Записей сохранено: '' + CAST(@SavedRs' + CAST(@n AS nvarchar(1)) + N' AS nvarchar(20));';
    SET @sql = STUFF(@sql, @pos, LEN(@find), @repl);
    SET @n = @n + 1;
END

SET @sql = REPLACE(@sql, N'CREATE PROCEDURE ags.spMstrg_2605', N'CREATE OR ALTER PROCEDURE ags.spMstrg_2605');
SET @sql = REPLACE(@sql, N'CREATE   PROCEDURE ags.spMstrg_2605', N'CREATE OR ALTER PROCEDURE ags.spMstrg_2605');

PRINT N'=== 06c: патч ROWCOUNT → spMstrg_2605 ===';
EXEC sp_executesql @sql;

IF CHARINDEX(N'@@ROWCOUNT', OBJECT_DEFINITION(OBJECT_ID(N'ags.spMstrg_2605'))) > 0
    RAISERROR(N'06c: WARN — в spMstrg_2605 остался @@ROWCOUNT', 0, 1) WITH NOWAIT;
ELSE
    PRINT N'=== 06c: spMstrg_2605 OK ===';
GO
