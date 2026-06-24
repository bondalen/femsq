USE [FishEye];
GO
-- =============================================================================
-- 07_VERIFY_spFn2_schema.sql
-- Паритет схемы результата fn2_2606 ↔ spIpgChRsltCstUtl2_2606 (INSERT EXEC).
-- Gate перед prod-путём 05b/06b (INSERT EXEC spFn2).
-- Автор: Александр | Дата: 2026-06-15
-- =============================================================================
SET NOCOUNT ON;
GO

DECLARE @fail int = 0;
DECLARE @fnCols int;
DECLARE @spCols int;
DECLARE @insRows int;
DECLARE @fnRows int;
DECLARE @msg nvarchar(400);

RAISERROR(N'=== 07_VERIFY_spFn2_schema: fn2 vs spFn2 ===', 0, 1) WITH NOWAIT;

-- A. Метаданные столбцов (dm_exec_describe_first_result_set)
SELECT @fnCols = COUNT(*)
FROM sys.dm_exec_describe_first_result_set(
    N'SELECT * FROM ags.fnIpgChRsltCstUtl2_2606(5, NULL, NULL)', NULL, 0)
WHERE is_hidden = 0;

SELECT @spCols = COUNT(*)
FROM sys.dm_exec_describe_first_result_set(
    N'EXEC ags.spIpgChRsltCstUtl2_2606 @ipgChKey=5, @ipgStKey=NULL, @stCostKey=NULL', NULL, 0)
WHERE is_hidden = 0;

SET @msg = N'  A. column count (dm_exec): fn=' + CAST(@fnCols AS nvarchar(10)) + N' sp=' + CAST(@spCols AS nvarchar(10));
RAISERROR(@msg, 0, 1) WITH NOWAIT;
IF @fnCols = 0
BEGIN
    SET @fail = @fail + 1;
    RAISERROR(N'    FAIL (fn metadata)', 0, 1) WITH NOWAIT;
END
ELSE IF @spCols = 0
    RAISERROR(N'    SKIP (dm_exec не возвращает метаданные SP — проверка B/C)', 0, 1) WITH NOWAIT;
ELSE IF @fnCols <> @spCols
BEGIN
    SET @fail = @fail + 1;
    RAISERROR(N'    FAIL', 0, 1) WITH NOWAIT;
END
ELSE
    RAISERROR(N'    OK', 0, 1) WITH NOWAIT;

-- B. INSERT EXEC (схема через TOP 0 FROM fn)
BEGIN TRY
    IF OBJECT_ID(N'tempdb..#fn2sp') IS NOT NULL DROP TABLE #fn2sp;
    SELECT TOP 0 * INTO #fn2sp FROM ags.fnIpgChRsltCstUtl2_2606(5, NULL, NULL);
    INSERT INTO #fn2sp EXEC ags.spIpgChRsltCstUtl2_2606 5, NULL, NULL;
    SELECT @insRows = COUNT(*) FROM #fn2sp WHERE ipgKey IS NOT NULL;
    RAISERROR(N'  B. INSERT EXEC: OK', 0, 1) WITH NOWAIT;
END TRY
BEGIN CATCH
    SET @fail = @fail + 1;
    SET @msg = N'  B. INSERT EXEC: FAIL — ' + ERROR_MESSAGE();
    RAISERROR(@msg, 0, 1) WITH NOWAIT;
    SET @insRows = NULL;
END CATCH

-- C. Сравнение COUNT (только если B прошёл)
IF @insRows IS NOT NULL
BEGIN
    SELECT @fnRows = COUNT(*) FROM ags.fnIpgChRsltCstUtl2_2606(5, NULL, NULL) f WHERE f.ipgKey IS NOT NULL;
    SET @msg = N'  C. rows ipgKey NOT NULL: fn=' + CAST(@fnRows AS nvarchar(12))
             + N' sp=' + CAST(@insRows AS nvarchar(12));
    RAISERROR(@msg, 0, 1) WITH NOWAIT;
    IF @fnRows <> @insRows
    BEGIN
        SET @fail = @fail + 1;
        RAISERROR(N'    FAIL (row count)', 0, 1) WITH NOWAIT;
    END
    ELSE
        RAISERROR(N'    OK', 0, 1) WITH NOWAIT;
END

IF @fail = 0
    RAISERROR(N'=== 07_VERIFY_spFn2_schema: PASS ===', 0, 1) WITH NOWAIT;
ELSE
    RAISERROR(N'=== 07_VERIFY_spFn2_schema: FAIL ===', 0, 1) WITH NOWAIT;
GO
