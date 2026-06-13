USE [FishEye];
GO
-- =============================================================================
-- MSSQL2012/05b_CREATE_TABLE_spMstrg_2606_ResultSets.sql
-- Зеркало ../05b_CREATE_TABLE_spMstrg_2606_ResultSets.sql (SQL Server 2012 SP4).
-- =============================================================================
SET NOCOUNT ON;
GO

PRINT N'=== 05b MSSQL2012: CREATE TABLE spMstrg_2606_ResultSet1..7 ===';
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

PRINT N'=== 05b MSSQL2012: DONE ===';
GO
