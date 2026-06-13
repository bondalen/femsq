USE [FishEye];
GO
-- =============================================================================
-- 05b_CREATE_TABLE_spMstrg_2606_ResultSets.sql
-- DDL: ags.spMstrg_2606_ResultSet1..7 — та же схема столбцов, что spMstrg_2408_ResultSet*.
-- Решение 8 (03-design-decisions.md §8): изоляция от *_2408_ResultSet*.
-- Автор: Александр | Дата: 2026-06-11
-- =============================================================================
SET NOCOUNT ON;
GO

PRINT N'=== 05b: CREATE TABLE spMstrg_2606_ResultSet1..7 ===';
GO

DECLARE @n int = 1;
DECLARE @sql nvarchar(500);

WHILE @n <= 7
BEGIN
    SET @sql = N'
IF OBJECT_ID(N''ags.spMstrg_2606_ResultSet' + CAST(@n AS nvarchar(1)) + N''', N''U'') IS NOT NULL
    DROP TABLE ags.spMstrg_2606_ResultSet' + CAST(@n AS nvarchar(1)) + N';

SELECT *
INTO ags.spMstrg_2606_ResultSet' + CAST(@n AS nvarchar(1)) + N'
FROM ags.spMstrg_2408_ResultSet' + CAST(@n AS nvarchar(1)) + N'
WHERE 1 = 0;';

    EXEC sp_executesql @sql;
    PRINT N'  spMstrg_2606_ResultSet' + CAST(@n AS nvarchar(1)) + N' OK';

    SET @n = @n + 1;
END

PRINT N'=== 05b: DONE ===';
GO
