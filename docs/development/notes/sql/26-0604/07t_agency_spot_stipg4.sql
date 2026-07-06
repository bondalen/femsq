USE [FishEye];
GO

-- =============================================================================
-- Файл:    07t_agency_spot_stipg4.sql
-- Пакет:   docs/development/notes/sql/26-0604/
-- Назначение: Gate agency-golden (этап 21.3) — stIpg=4, cst 849 / 1862.
--   A. К-12 phase-0: SUM(UtPlMn@212) в ipgcrvUtPlGr ≈ лимит ipgPn на ИП 6/8/11.
--   B. PercentBrn: ag_lim и ag_accepted ненулевые на каждом ИП 6/8/11 (календарь ревизий).
--   C. Plan-align: ag_Pl + ag_PlAccum на ipgcrvEnd / yearend (Решение 22, этап 21.4.4).
-- Предусловия: FIXTURE_06_01 (swap UtPlGr 18–20); 05c (plan LmMn@212).
-- Автор:   Александр | Дата: 2026-07-06 (plan gate 21.4.4)
-- =============================================================================

SET NOCOUNT ON;
GO

RAISERROR(N'=== 07t agency-spot: stIpg=4, cst 849/1862, yearend 2022-12-31 ===', 0, 1) WITH NOWAIT;

DECLARE @ipgCh   int  = 5;
DECLARE @stIpg   int  = 4;
DECLARE @dt      date = '2022-12-31';
DECLARE @epsilon money = 0.01;
DECLARE @fail    int  = 0;
DECLARE @msg     nvarchar(500);

-- ---------------------------------------------------------------------------
-- A. К-12 phase-0: UtPl в тестовых группах ipgcrvUtPlGr
-- ---------------------------------------------------------------------------
RAISERROR(N'--- A. К-12 phase-0 (UtPl sum vs lim, ipgcrvUtPlGr) ---', 0, 1) WITH NOWAIT;

IF OBJECT_ID('tempdb..#k12') IS NOT NULL DROP TABLE #k12;

SELECT
    p.ipgpCstAgPn,
    p.ipgpIpg,
    COALESCE(l212.ipgplLim, p.ipgpSmTtl) AS ref212,
    SUM(CASE WHEN m.iuplpmStCost = 212 THEN m.iuplpmLim ELSE 0 END) AS sum212
INTO #k12
FROM ags.ipgPn p
INNER JOIN ags.ipgChRl_2606 v ON v.ipgcrvIpg = p.ipgpIpg AND v.ipgcrvChain = @ipgCh
INNER JOIN ags.ipgStPn sp ON sp.ipgspPn = p.ipgpKey AND sp.ipgspSt = @stIpg
LEFT JOIN ags.ipgPnLim l212 ON l212.ipgplPn = p.ipgpKey AND l212.ipgplStCost = 212
INNER JOIN ags.ipgUtPlP up ON up.iuplpIpgPn = p.ipgpKey
INNER JOIN ags.ipgUtPlGrP gp ON gp.iuplgpPl = up.iuplpPl AND gp.iuplgpGr = v.ipgcrvUtPlGr
LEFT JOIN ags.ipgUtPlPnLmMn m ON m.iuplpmPlPn = up.iuplpKey
WHERE p.ipgpCstAgPn IN (849, 1862)
  AND p.ipgpIpg IN (6, 8, 11)
GROUP BY p.ipgpCstAgPn, p.ipgpIpg, p.ipgpSmTtl, l212.ipgplLim;

SELECT ipgpCstAgPn, ipgpIpg, ref212, sum212,
       ABS(ref212 - sum212) AS diff212
FROM #k12
ORDER BY ipgpCstAgPn, ipgpIpg;

DECLARE @cst int, @ipg int, @ref money, @sum money;
DECLARE c12 CURSOR LOCAL FAST_FORWARD FOR
    SELECT ipgpCstAgPn, ipgpIpg, ref212, sum212 FROM #k12;
OPEN c12;
FETCH NEXT FROM c12 INTO @cst, @ipg, @ref, @sum;
WHILE @@FETCH_STATUS = 0
BEGIN
    IF ABS(ISNULL(@ref, 0) - ISNULL(@sum, 0)) > @epsilon
    BEGIN
        SET @fail = @fail + 1;
        SET @msg = N'  FAIL К-12: cst=' + CAST(@cst AS nvarchar(10))
            + N' ipg=' + CAST(@ipg AS nvarchar(10))
            + N' ref212=' + CAST(@ref AS nvarchar(30))
            + N' sum212=' + CAST(@sum AS nvarchar(30));
        RAISERROR(@msg, 0, 1) WITH NOWAIT;
    END
    ELSE
    BEGIN
        SET @msg = N'  OK К-12: cst=' + CAST(@cst AS nvarchar(10))
            + N' ipg=' + CAST(@ipg AS nvarchar(10));
        RAISERROR(@msg, 0, 1) WITH NOWAIT;
    END
    FETCH NEXT FROM c12 INTO @cst, @ipg, @ref, @sum;
END
CLOSE c12;
DEALLOCATE c12;

IF (SELECT COUNT(*) FROM #k12) <> 6
BEGIN
    SET @fail = @fail + 1;
    RAISERROR(N'  FAIL К-12: expected 6 rows (2 cst × 3 IP), got different count', 0, 1) WITH NOWAIT;
END

-- ---------------------------------------------------------------------------
-- B. PercentBrn: ag_lim + ag_accepted per IP (revision calendar)
-- ---------------------------------------------------------------------------
RAISERROR(N'--- B. PercentBrn agency fact+lim @ stIpg=4 ---', 0, 1) WITH NOWAIT;

IF OBJECT_ID('tempdb..#pb') IS NOT NULL DROP TABLE #pb;

SELECT
    p.cstapKey,
    p.ipgKey,
    MAX(CASE WHEN ISNULL(p.ag_lim, 0) <> 0 THEN 1 ELSE 0 END)       AS has_lim,
    MAX(CASE WHEN ISNULL(p.ag_accepted, 0) <> 0 THEN 1 ELSE 0 END) AS has_acc,
    MAX(CASE WHEN ISNULL(p.ag_Pl, 0) <> 0 THEN 1 ELSE 0 END)       AS has_pl,
    MAX(CASE WHEN p.dateRslt = @dt AND ISNULL(p.ag_Pl, 0) <> 0 THEN 1 ELSE 0 END) AS has_pl_ye
INTO #pb
FROM ags.fnIpgChRsltCstUtlPercentBrn_2606(@ipgCh, @stIpg, NULL) p
WHERE p.cstapKey IN (849, 1862)
  AND p.ipgKey IN (6, 8, 11)
GROUP BY p.cstapKey, p.ipgKey;

SELECT * FROM #pb ORDER BY cstapKey, ipgKey;

DECLARE @cst2 int, @ipg2 int, @hl int, @ha int, @hp int;
DECLARE cpb CURSOR LOCAL FAST_FORWARD FOR
    SELECT cstapKey, ipgKey, has_lim, has_acc, has_pl FROM #pb;
OPEN cpb;
FETCH NEXT FROM cpb INTO @cst2, @ipg2, @hl, @ha, @hp;
WHILE @@FETCH_STATUS = 0
BEGIN
    IF @hl = 0 OR @ha = 0
    BEGIN
        SET @fail = @fail + 1;
        SET @msg = N'  FAIL agency: cst=' + CAST(@cst2 AS nvarchar(10))
            + N' ipg=' + CAST(@ipg2 AS nvarchar(10))
            + N' has_lim=' + CAST(@hl AS nvarchar(2))
            + N' has_acc=' + CAST(@ha AS nvarchar(2));
        RAISERROR(@msg, 0, 1) WITH NOWAIT;
    END
    ELSE
    BEGIN
        SET @msg = N'  OK agency: cst=' + CAST(@cst2 AS nvarchar(10))
            + N' ipg=' + CAST(@ipg2 AS nvarchar(10))
            + N' lim+accepted';
        RAISERROR(@msg, 0, 1) WITH NOWAIT;
    END
    FETCH NEXT FROM cpb INTO @cst2, @ipg2, @hl, @ha, @hp;
END
CLOSE cpb;
DEALLOCATE cpb;

IF (SELECT COUNT(*) FROM #pb) <> 6
BEGIN
    SET @fail = @fail + 1;
    RAISERROR(N'  FAIL agency: expected 6 PercentBrn groups (2 cst × 3 IP)', 0, 1) WITH NOWAIT;
END

-- ---------------------------------------------------------------------------
-- C. Plan-align @ calendar: ag_Pl + ag_PlAccum (ipgcrvEnd / yearend)
-- ---------------------------------------------------------------------------
RAISERROR(N'--- C. PercentBrn ag_Pl @ calendar (ipgcrvEnd / yearend) ---', 0, 1) WITH NOWAIT;

IF OBJECT_ID('tempdb..#expect') IS NOT NULL DROP TABLE #expect;

SELECT
    c.cstAgPn,
    v.ipgcrvIpg AS ipgKey,
    CASE
        WHEN v.ipgcrvEnd IS NULL OR v.ipgcrvEnd >= @dt THEN @dt
        ELSE CAST(v.ipgcrvEnd AS date)
    END AS check_dt
INTO #expect
FROM (VALUES (849), (1862)) c(cstAgPn)
CROSS JOIN ags.ipgChRl_2606 v
WHERE v.ipgcrvChain = @ipgCh
  AND v.ipgcrvIpg IN (6, 8, 11);

IF OBJECT_ID('tempdb..#plan') IS NOT NULL DROP TABLE #plan;

SELECT
    e.cstAgPn,
    e.ipgKey,
    e.check_dt,
    p.ag_Pl,
    p.ag_PlAccum
INTO #plan
FROM #expect e
LEFT JOIN ags.fnIpgChRsltCstUtlPercentBrn_2606(@ipgCh, @stIpg, NULL) p
    ON p.cstapKey = e.cstAgPn
   AND p.ipgKey = e.ipgKey
   AND p.dateRslt = e.check_dt;

SELECT cstAgPn, ipgKey, check_dt, ag_Pl, ag_PlAccum FROM #plan ORDER BY cstAgPn, ipgKey;

DECLARE @cst3 int, @ipg3 int, @chk date, @apl money, @aplAcc money;
DECLARE cpl CURSOR LOCAL FAST_FORWARD FOR
    SELECT cstAgPn, ipgKey, check_dt, ag_Pl, ag_PlAccum FROM #plan;
OPEN cpl;
FETCH NEXT FROM cpl INTO @cst3, @ipg3, @chk, @apl, @aplAcc;
WHILE @@FETCH_STATUS = 0
BEGIN
    IF ISNULL(@apl, 0) = 0 OR ISNULL(@aplAcc, 0) = 0
    BEGIN
        SET @fail = @fail + 1;
        SET @msg = N'  FAIL plan: cst=' + CAST(@cst3 AS nvarchar(10))
            + N' ipg=' + CAST(@ipg3 AS nvarchar(10))
            + N' @' + CONVERT(nvarchar(10), @chk, 120)
            + N' — ag_Pl/ag_PlAccum expected non-zero';
        RAISERROR(@msg, 0, 1) WITH NOWAIT;
    END
    ELSE
    BEGIN
        SET @msg = N'  OK plan: cst=' + CAST(@cst3 AS nvarchar(10))
            + N' ipg=' + CAST(@ipg3 AS nvarchar(10))
            + N' @' + CONVERT(nvarchar(10), @chk, 120);
        RAISERROR(@msg, 0, 1) WITH NOWAIT;
    END
    FETCH NEXT FROM cpl INTO @cst3, @ipg3, @chk, @apl, @aplAcc;
END
CLOSE cpl;
DEALLOCATE cpl;

IF (SELECT COUNT(*) FROM #expect) <> 6
BEGIN
    SET @fail = @fail + 1;
    RAISERROR(N'  FAIL plan: expected 6 calendar checkpoints', 0, 1) WITH NOWAIT;
END

-- ---------------------------------------------------------------------------
-- Итог
-- ---------------------------------------------------------------------------
IF @fail = 0
BEGIN
    SET @msg = N'=== 07t agency-spot: PASS ===';
    RAISERROR(@msg, 0, 1) WITH NOWAIT;
END
ELSE
BEGIN
    SET @msg = N'=== 07t agency-spot: FAIL (fail=' + CAST(@fail AS nvarchar(10)) + N') ===';
    RAISERROR(@msg, 0, 1) WITH NOWAIT;
END
GO
