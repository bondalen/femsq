USE [FishEye];
GO

-- =============================================================================
-- Файл:    07o_plan_align_spot_2102.sql
-- Пакет:   docs/development/notes/sql/26-0604/
-- Назначение: Gate plan-align (этап 21.4.4) — invest-golden cstAgPn=2102, stIpg=42.
--   План PercentBrn по календарю смены ИП (Решение 22): на ipgcrvEnd — iv_Pl + iv_PlAccum;
--   на yearend активной ИП — минимум iv_PlAccum (iv_Pl может быть 0 при m12=0 в fixture).
-- Предусловия: 05c (plan из LmMn@212), FIXTURE_06.
-- Автор:   Александр | Дата: 2026-07-06 (пересмотр 21.4.4)
-- =============================================================================

SET NOCOUNT ON;
GO

RAISERROR(N'=== 07o plan-align spot: cst 2102, stIpg=42, calendar IP 6/8/11 ===', 0, 1) WITH NOWAIT;

DECLARE @ipgCh   int  = 5;
DECLARE @stIpg   int  = 42;
DECLARE @cstAgPn int  = 2102;
DECLARE @dt      date = '2022-12-31';
DECLARE @fail    int  = 0;
DECLARE @msg     nvarchar(500);

-- Ожидаемые точки: ipgcrvEnd для завершённых ИП, yearend для активной
IF OBJECT_ID('tempdb..#expect') IS NOT NULL DROP TABLE #expect;

SELECT
    v.ipgcrvIpg AS ipgKey,
    v.ipgcrvStr,
    v.ipgcrvEnd,
    CASE
        WHEN v.ipgcrvEnd IS NULL OR v.ipgcrvEnd >= @dt THEN @dt
        ELSE CAST(v.ipgcrvEnd AS date)
    END AS check_dt,
    CASE
        WHEN v.ipgcrvEnd IS NULL OR v.ipgcrvEnd >= @dt THEN N'yearend'
        ELSE N'ipgcrvEnd'
    END AS chk_kind
INTO #expect
FROM ags.ipgChRl_2606 v
WHERE v.ipgcrvChain = @ipgCh
  AND v.ipgcrvIpg IN (6, 8, 11);

SELECT ipgKey, ipgcrvStr, ipgcrvEnd, check_dt, chk_kind FROM #expect ORDER BY ipgKey;

IF OBJECT_ID('tempdb..#plan') IS NOT NULL DROP TABLE #plan;

SELECT
    e.ipgKey,
    e.check_dt,
    e.chk_kind,
    p.iv_Pl,
    p.iv_PlAccum
INTO #plan
FROM #expect e
LEFT JOIN ags.fnIpgChRsltCstUtlPercentBrn_2606(@ipgCh, @stIpg, NULL) p
    ON p.cstapKey = @cstAgPn
   AND p.ipgKey = e.ipgKey
   AND p.dateRslt = e.check_dt;

SELECT ipgKey, check_dt, chk_kind, iv_Pl, iv_PlAccum FROM #plan ORDER BY ipgKey;

DECLARE @ipg int, @chk date, @kind nvarchar(20), @pl money, @plAcc money;

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT ipgKey, check_dt, chk_kind, iv_Pl, iv_PlAccum FROM #plan;
OPEN cur;
FETCH NEXT FROM cur INTO @ipg, @chk, @kind, @pl, @plAcc;
WHILE @@FETCH_STATUS = 0
BEGIN
    IF ISNULL(@plAcc, 0) = 0
    BEGIN
        SET @fail = @fail + 1;
        SET @msg = N'  FAIL: ipgKey=' + CAST(@ipg AS nvarchar(10))
            + N' @' + CONVERT(nvarchar(10), @chk, 120)
            + N' (' + @kind + N') — iv_PlAccum expected non-zero';
        RAISERROR(@msg, 0, 1) WITH NOWAIT;
    END
    ELSE IF @kind = N'ipgcrvEnd' AND ISNULL(@pl, 0) = 0
    BEGIN
        SET @fail = @fail + 1;
        SET @msg = N'  FAIL: ipgKey=' + CAST(@ipg AS nvarchar(10))
            + N' @' + CONVERT(nvarchar(10), @chk, 120)
            + N' (ipgcrvEnd) — iv_Pl expected non-zero';
        RAISERROR(@msg, 0, 1) WITH NOWAIT;
    END
    ELSE IF @kind = N'yearend' AND ISNULL(@pl, 0) = 0
    BEGIN
        SET @msg = N'  OK ipgKey=' + CAST(@ipg AS nvarchar(10))
            + N' @yearend — iv_Pl=0, iv_PlAccum non-zero (m12 fixture)';
        RAISERROR(@msg, 0, 1) WITH NOWAIT;
    END
    ELSE
    BEGIN
        SET @msg = N'  OK ipgKey=' + CAST(@ipg AS nvarchar(10))
            + N' @' + CONVERT(nvarchar(10), @chk, 120)
            + N' (' + @kind + N')';
        RAISERROR(@msg, 0, 1) WITH NOWAIT;
    END
    FETCH NEXT FROM cur INTO @ipg, @chk, @kind, @pl, @plAcc;
END
CLOSE cur;
DEALLOCATE cur;

IF (SELECT COUNT(*) FROM #expect) <> 3
BEGIN
    SET @fail = @fail + 1;
    RAISERROR(N'  FAIL: expected 3 IP checkpoints (6/8/11)', 0, 1) WITH NOWAIT;
END

IF @fail = 0
    RAISERROR(N'=== 07o plan-align spot: PASS ===', 0, 1) WITH NOWAIT;
ELSE
    RAISERROR(N'=== 07o plan-align spot: FAIL ===', 0, 1) WITH NOWAIT;
GO
