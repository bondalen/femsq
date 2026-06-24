USE [FishEye];
GO
-- =============================================================================
-- 07l_RS_derivative_spot_chain5.sql
-- Spot-check RS4–RS7: общие столбцы _2606 ↔ _2605 (таблицы *_2408_*), без rowNum/limSort.
-- Дополняет 07k (RS1 keyDiff + COUNT RS2–7). @MounthEndDate='2022-12-31'.
-- Автор: Александр | Дата: 2026-06-15
-- =============================================================================
SET NOCOUNT ON;
GO

DECLARE @fail int = 0;
DECLARE @n int = 4;
DECLARE @sql nvarchar(max);
DECLARE @cols nvarchar(max);
DECLARE @diff int;
DECLARE @cnt05 int;
DECLARE @cnt06 int;
DECLARE @msg nvarchar(400);

RAISERROR(N'=== 07l: RS4–RS7 spot compare (common columns) ===', 0, 1) WITH NOWAIT;

WHILE @n <= 7
BEGIN
    SET @sql = N'SELECT @c = COUNT(*) FROM ags.spMstrg_2408_ResultSet' + CAST(@n AS nvarchar(1));
    EXEC sp_executesql @sql, N'@c int OUTPUT', @c = @cnt05 OUTPUT;
    SET @sql = N'SELECT @c = COUNT(*) FROM ags.spMstrg_2606_ResultSet' + CAST(@n AS nvarchar(1));
    EXEC sp_executesql @sql, N'@c int OUTPUT', @c = @cnt06 OUTPUT;

    SELECT @cols = STRING_AGG(QUOTENAME(c1.COLUMN_NAME), ', ') WITHIN GROUP (ORDER BY c1.ORDINAL_POSITION)
    FROM INFORMATION_SCHEMA.COLUMNS c1
    JOIN INFORMATION_SCHEMA.COLUMNS c2
      ON c1.COLUMN_NAME = c2.COLUMN_NAME AND c1.TABLE_SCHEMA = c2.TABLE_SCHEMA
    WHERE c1.TABLE_SCHEMA = N'ags'
      AND c1.TABLE_NAME = N'spMstrg_2408_ResultSet' + CAST(@n AS nvarchar(1))
      AND c2.TABLE_NAME = N'spMstrg_2606_ResultSet' + CAST(@n AS nvarchar(1))
      AND c1.COLUMN_NAME NOT IN (N'rowNum', N'limSort');

    IF @cols IS NULL OR LEN(@cols) = 0
    BEGIN
        SET @msg = N'  RS' + CAST(@n AS nvarchar(1)) + N' SKIP: no common columns';
        RAISERROR(@msg, 0, 1) WITH NOWAIT;
        SET @n = @n + 1;
        CONTINUE;
    END

    SET @sql = N'
        SELECT @d = COUNT(*) FROM (
            SELECT ' + @cols + N' FROM ags.spMstrg_2606_ResultSet' + CAST(@n AS nvarchar(1)) + N'
            EXCEPT
            SELECT ' + @cols + N' FROM ags.spMstrg_2408_ResultSet' + CAST(@n AS nvarchar(1)) + N'
        ) x';
    EXEC sp_executesql @sql, N'@d int OUTPUT', @d = @diff OUTPUT;

    SET @msg = N'  RS' + CAST(@n AS nvarchar(1))
             + N' cnt05=' + CAST(@cnt05 AS nvarchar(12))
             + N' cnt06=' + CAST(@cnt06 AS nvarchar(12))
             + N' except06=' + CAST(@diff AS nvarchar(12))
             + N' (COUNT=критерий; EXCEPT=инфо)';
    RAISERROR(@msg, 0, 1) WITH NOWAIT;

    IF @cnt05 <> @cnt06
    BEGIN
        SET @fail = @fail + 1;
        RAISERROR(N'    FAIL (COUNT)', 0, 1) WITH NOWAIT;
    END
    ELSE IF @diff <> 0
        RAISERROR(N'    OK COUNT; WARN except (производный RS, см. RS1/07k)', 0, 1) WITH NOWAIT;
    ELSE
        RAISERROR(N'    OK', 0, 1) WITH NOWAIT;

    SET @n = @n + 1;
END

IF @fail = 0
    RAISERROR(N'=== 07l: PASS ===', 0, 1) WITH NOWAIT;
ELSE
    RAISERROR(N'=== 07l: FAIL ===', 0, 1) WITH NOWAIT;
GO
