USE [FishEye];
GO
-- =============================================================================
-- 07u_div_by_zero_smoke.sql
-- Smoke: деление на 0 при ag_lim=0 / ag_Pl=0 — PercentBrn + spMstrg RS4.
-- Этап: hotfix div-by-zero (оба стека).
-- =============================================================================
SET NOCOUNT ON;
GO

DECLARE @ipgCh int = 5;
DECLARE @dt date = '2022-12-31';
DECLARE @fail int = 0;
DECLARE @msg nvarchar(500);

RAISERROR(N'=== 07u div-by-zero smoke ===', 0, 1) WITH NOWAIT;

-- A. PercentBrn _2606: строки с ag_lim=0 не должны ронять batch
BEGIN TRY
    SELECT TOP 5
        cstapKey, ipgKey, dateRslt, ag_lim, ag_LimPercent, ag_PlPercent
    FROM ags.fnIpgChRsltCstUtlPercentBrn_2606(@ipgCh, NULL, NULL)
    WHERE dateRslt = @dt
      AND (ISNULL(ag_lim, 0) = 0 OR ISNULL(ag_Pl, 0) = 0)
    ORDER BY cstapKey, ipgKey;
    RAISERROR(N'  OK PercentBrn_2606: zero-lim rows queried', 0, 1) WITH NOWAIT;
END TRY
BEGIN CATCH
    SET @fail = @fail + 1;
    SET @msg = N'  FAIL PercentBrn_2606: ' + ERROR_MESSAGE();
    RAISERROR(@msg, 0, 1) WITH NOWAIT;
END CATCH

-- B. PercentBrn _2605
BEGIN TRY
    SELECT TOP 5
        cstapKey, ipgKey, dateRslt, ag_lim, ag_LimPercent, ag_PlPercent
    FROM ags.fnIpgChRsltCstUtlPercentBrn_2605(@ipgCh, NULL)
    WHERE dateRslt = @dt
      AND (ISNULL(ag_lim, 0) = 0 OR ISNULL(ag_Pl, 0) = 0)
    ORDER BY cstapKey, ipgKey;
    RAISERROR(N'  OK PercentBrn_2605: zero-lim rows queried', 0, 1) WITH NOWAIT;
END TRY
BEGIN CATCH
    SET @fail = @fail + 1;
    SET @msg = N'  FAIL PercentBrn_2605: ' + ERROR_MESSAGE();
    RAISERROR(@msg, 0, 1) WITH NOWAIT;
END CATCH

-- C. spMstrg_2605 saveToTables=1 (без дампа RS в stdout)
BEGIN TRY
    EXEC ags.spMstrg_2605
        @ipgCh = @ipgCh,
        @MounthEndDate = @dt,
        @ipgSt = NULL,
        @saveToTables = 1;
    RAISERROR(N'  OK spMstrg_2605 saveToTables=1', 0, 1) WITH NOWAIT;
END TRY
BEGIN CATCH
    SET @fail = @fail + 1;
    SET @msg = N'  FAIL spMstrg_2605: ' + ERROR_MESSAGE();
    RAISERROR(@msg, 0, 1) WITH NOWAIT;
END CATCH

-- D. spMstrg_2606 saveToTables=1
BEGIN TRY
    EXEC ags.spMstrg_2606
        @ipgCh = @ipgCh,
        @MounthEndDate = @dt,
        @ipgStKey = NULL,
        @stCostKey = NULL,
        @saveToTables = 1;
    RAISERROR(N'  OK spMstrg_2606 saveToTables=1', 0, 1) WITH NOWAIT;
END TRY
BEGIN CATCH
    SET @fail = @fail + 1;
    SET @msg = N'  FAIL spMstrg_2606: ' + ERROR_MESSAGE();
    RAISERROR(@msg, 0, 1) WITH NOWAIT;
END CATCH

IF @fail = 0
    RAISERROR(N'=== 07u div-by-zero smoke: PASS ===', 0, 1) WITH NOWAIT;
ELSE
    RAISERROR(N'=== 07u div-by-zero smoke: FAIL ===', 0, 1) WITH NOWAIT;
GO
