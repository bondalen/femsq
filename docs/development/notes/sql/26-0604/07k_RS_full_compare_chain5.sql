USE [FishEye];
GO
-- =============================================================================
-- 07k_RS_full_compare_chain5.sql
-- Сходимость RS1..RS7: spMstrg_2606_ResultSet* ↔ spMstrg_2408_ResultSet*
--   (_2605 пишет в таблицы *_2408_*)
-- RS1: бизнес-ключи (dateRslt, ipgKey, cstapKey) — как 07f F.3.
-- RS2–RS7: производные от RS1 — COUNT + spot (см. docs/06-sp-recordsets).
-- Предусловие: spMstrg_2605 и spMstrg_2606 с @saveToTables=1, один @MounthEndDate.
-- Эталон dev: @ipgCh=5, @MounthEndDate='2022-12-31'
-- Автор: Александр | Дата: 2026-06-15
-- =============================================================================
SET NOCOUNT ON;
GO

DECLARE @fail   int = 0;
DECLARE @n      int = 1;
DECLARE @cnt05  int;
DECLARE @cnt06  int;
DECLARE @keyDiff int;
DECLARE @sql    nvarchar(max);
DECLARE @msg    nvarchar(400);

RAISERROR(N'=== 07k: RS compare chain 5 (_2606 vs _2605 tables) ===', 0, 1) WITH NOWAIT;

WHILE @n <= 7
BEGIN
    IF OBJECT_ID(N'ags.spMstrg_2606_ResultSet' + CAST(@n AS nvarchar(1)), N'U') IS NULL
       OR OBJECT_ID(N'ags.spMstrg_2408_ResultSet' + CAST(@n AS nvarchar(1)), N'U') IS NULL
    BEGIN
        SET @msg = N'  RS' + CAST(@n AS nvarchar(1)) + N' SKIP: table missing';
        RAISERROR(@msg, 0, 1) WITH NOWAIT;
        SET @fail = @fail + 1;
        SET @n = @n + 1;
        CONTINUE;
    END

    SET @sql = N'SELECT @c = COUNT(*) FROM ags.spMstrg_2606_ResultSet' + CAST(@n AS nvarchar(1));
    EXEC sp_executesql @sql, N'@c int OUTPUT', @c = @cnt06 OUTPUT;

    SET @sql = N'SELECT @c = COUNT(*) FROM ags.spMstrg_2408_ResultSet' + CAST(@n AS nvarchar(1));
    EXEC sp_executesql @sql, N'@c int OUTPUT', @c = @cnt05 OUTPUT;

    IF @n = 1
    BEGIN
        -- RS1: полная проверка по бизнес-ключам (GROUPING SETS → дедуп)
        SET @sql = N'
            SELECT @d = COUNT(*)
            FROM (
                SELECT dateRslt, ipgKey, cstapKey,
                       MAX(ag_lim) AS ag_lim, MAX(ag_presented) AS ag_presented,
                       MAX(ag_Pl) AS ag_Pl, MAX(ag_percentDev) AS ag_percentDev
                FROM ags.spMstrg_2408_ResultSet1
                GROUP BY dateRslt, ipgKey, cstapKey
            ) a
            FULL OUTER JOIN (
                SELECT dateRslt, ipgKey, cstapKey,
                       MAX(ag_lim) AS ag_lim, MAX(ag_presented) AS ag_presented,
                       MAX(ag_Pl) AS ag_Pl, MAX(ag_percentDev) AS ag_percentDev
                FROM ags.spMstrg_2606_ResultSet1
                GROUP BY dateRslt, ipgKey, cstapKey
            ) b
                ON a.dateRslt = b.dateRslt
               AND ISNULL(a.ipgKey, -1)   = ISNULL(b.ipgKey, -1)
               AND ISNULL(a.cstapKey, -1) = ISNULL(b.cstapKey, -1)
            WHERE a.dateRslt IS NULL OR b.dateRslt IS NULL
               OR ABS(ISNULL(a.ag_presented, 0) - ISNULL(b.ag_presented, 0)) > 0.01
               OR ABS(ISNULL(a.ag_lim, 0) - ISNULL(b.ag_lim, 0)) > 0.01
               OR ABS(ISNULL(a.ag_Pl, 0) - ISNULL(b.ag_Pl, 0)) > 0.01
               OR ABS(ISNULL(a.ag_percentDev, 0) - ISNULL(b.ag_percentDev, 0)) > 0.0001';
        EXEC sp_executesql @sql, N'@d int OUTPUT', @d = @keyDiff OUTPUT;

        SET @msg = N'  RS1 cnt05=' + CAST(@cnt05 AS nvarchar(12))
                 + N' cnt06=' + CAST(@cnt06 AS nvarchar(12))
                 + N' keyDiff=' + CAST(@keyDiff AS nvarchar(12));
        RAISERROR(@msg, 0, 1) WITH NOWAIT;

        IF @cnt05 <> @cnt06 OR @keyDiff <> 0
        BEGIN
            SET @fail = @fail + 1;
            RAISERROR(N'    FAIL', 0, 1) WITH NOWAIT;
        END
        ELSE
            RAISERROR(N'    OK (RS1 business keys)', 0, 1) WITH NOWAIT;
    END
    ELSE
    BEGIN
        -- RS2–RS7: производные — достаточно совпадения COUNT (см. 06-sp-recordsets §Приоритет 3)
        SET @msg = N'  RS' + CAST(@n AS nvarchar(1))
                 + N' cnt05=' + CAST(@cnt05 AS nvarchar(12))
                 + N' cnt06=' + CAST(@cnt06 AS nvarchar(12))
                 + N' (COUNT-only derivative)';
        RAISERROR(@msg, 0, 1) WITH NOWAIT;

        IF @cnt05 <> @cnt06
        BEGIN
            SET @fail = @fail + 1;
            RAISERROR(N'    FAIL', 0, 1) WITH NOWAIT;
        END
        ELSE
            RAISERROR(N'    OK', 0, 1) WITH NOWAIT;
    END

    SET @n = @n + 1;
END

IF @fail = 0
    RAISERROR(N'=== 07k: PASS ===', 0, 1) WITH NOWAIT;
ELSE
    RAISERROR(N'=== 07k: FAIL ===', 0, 1) WITH NOWAIT;
GO
