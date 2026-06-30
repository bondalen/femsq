USE [FishEye];
GO

-- =============================================================================
-- Файл:    07r_stipg_spot_rs1_chain5.sql
-- Пакет:   docs/development/notes/sql/26-0604/
-- Назначение: Приёмка этапа 19.5 — spot-check spMstrg_2606 / RS1 при @ipgStKey.
--   Цепь 5, stIpg=42, golden cstAgPn=2102: сужение RS1 (не ~14k), сверка с
--   PercentBrn (07f) и fn2 (07h).
-- Предусловия: 10a–10d, патч 04, 05–06 (spMstrg_2606).
-- Эталон dev @ 10.7.0.3: fn2=14 строк; PercentBrn/RS1 raw=64, keys=16 dateRslt.
-- Автор:   Александр
-- Дата:    2026-06-29
-- =============================================================================

SET NOCOUNT ON;
GO

RAISERROR(N'=== 07r: stIpg spot RS1 chain 5 (этап 19.5) ===', 0, 1) WITH NOWAIT;

DECLARE @ipgCh      int  = 5;
DECLARE @stIpg      int  = 42;
DECLARE @cstAgPn    int  = 2102;
DECLARE @dt         date = '2022-12-31';
DECLARE @fail       int  = 0;
DECLARE @msg        nvarchar(500);
DECLARE @t0         datetime2;
DECLARE @ms         int;
DECLARE @fn2Rows int, @fn2Cst int, @fn2Other int, @fn205 int;
DECLARE @pbRaw int, @pbKeys int, @pbDt int, @pbOther int;
DECLARE @rs1Raw int, @rs1Cst int, @rs1Dt int, @rs1Other int;
DECLARE @keyDiff int;

-- ---------------------------------------------------------------------------
-- A. fn2 (07h): одна стройка, не вся цепь
-- ---------------------------------------------------------------------------
RAISERROR(N'--- A. fn2_2606 stIpg=42 ---', 0, 1) WITH NOWAIT;

SELECT @fn2Rows = COUNT(*),
       @fn2Cst  = COUNT(DISTINCT cstAgPnKey),
       @fn2Other = SUM(CASE WHEN cstAgPnKey <> @cstAgPn THEN 1 ELSE 0 END)
FROM ags.fnIpgChRsltCstUtl2_2606(@ipgCh, @stIpg, NULL);

SET @msg = N'  fn2 rows=' + CAST(@fn2Rows AS nvarchar(10))
    + N' distinct cst=' + CAST(@fn2Cst AS nvarchar(10))
    + N' other cst rows=' + CAST(ISNULL(@fn2Other, 0) AS nvarchar(10))
    + N' (expected rows=14, cst=1, other=0)';
RAISERROR(@msg, 0, 1) WITH NOWAIT;

IF @fn2Rows <> 14 OR @fn2Cst <> 1 OR ISNULL(@fn2Other, 0) <> 0
BEGIN
    SET @fail = @fail + 1;
    RAISERROR(N'  FAIL: fn2 universe', 0, 1) WITH NOWAIT;
END

SELECT @fn205 = COUNT(*)
FROM ags.fnIpgChRsltCstUtl2_2605(@ipgCh, NULL) f
WHERE f.cstAgPnKey = @cstAgPn AND f.ipgKey IS NOT NULL;

SET @msg = N'  fn2_2605 full chain cst2102 rows=' + CAST(@fn205 AS nvarchar(10))
    + N' (expect = fn2_2606)';
RAISERROR(@msg, 0, 1) WITH NOWAIT;

IF @fn205 <> @fn2Rows
BEGIN
    SET @fail = @fail + 1;
    RAISERROR(N'  FAIL: fn2_2606 vs _2605 for cst2102', 0, 1) WITH NOWAIT;
END

-- ---------------------------------------------------------------------------
-- B. PercentBrn (07f spot): stIpg=42, cst 2102
-- ---------------------------------------------------------------------------
RAISERROR(N'--- B. PercentBrn_2606 stIpg=42 ---', 0, 1) WITH NOWAIT;

IF OBJECT_ID('tempdb..#pb42') IS NOT NULL DROP TABLE #pb42;

SET @t0 = SYSDATETIME();
SELECT dateRslt, ipgKey, cstapKey,
       MAX(ag_lim) AS ag_lim, MAX(ag_Pl) AS ag_Pl,
       MAX(ag_presented) AS ag_presented, MAX(ag_percentDev) AS ag_percentDev
INTO #pb42
FROM ags.fnIpgChRsltCstUtlPercentBrn_2606(@ipgCh, @stIpg, NULL)
WHERE cstapKey = @cstAgPn
GROUP BY dateRslt, ipgKey, cstapKey;

SELECT @pbRaw = COUNT(*),
       @pbKeys = (SELECT COUNT(*) FROM #pb42),
       @pbDt = COUNT(DISTINCT dateRslt),
       @pbOther = SUM(CASE WHEN cstapKey <> @cstAgPn THEN 1 ELSE 0 END)
FROM ags.fnIpgChRsltCstUtlPercentBrn_2606(@ipgCh, @stIpg, NULL);

SET @ms = DATEDIFF(ms, @t0, SYSDATETIME());
SET @msg = N'  PercentBrn raw=' + CAST(@pbRaw AS nvarchar(10))
    + N' dedup keys=' + CAST(@pbKeys AS nvarchar(10))
    + N' distinct dateRslt=' + CAST(@pbDt AS nvarchar(10))
    + N' ms=' + CAST(@ms AS nvarchar(10))
    + N' (expected raw=64, keys=16, dt=16)';
RAISERROR(@msg, 0, 1) WITH NOWAIT;

IF @pbRaw > 500 OR @pbRaw = 0 OR @pbKeys <> 16 OR @pbDt <> 16 OR ISNULL(@pbOther, 0) <> 0
BEGIN
    SET @fail = @fail + 1;
    RAISERROR(N'  FAIL: PercentBrn st42', 0, 1) WITH NOWAIT;
END

-- ---------------------------------------------------------------------------
-- C. spMstrg_2606 → RS1
-- ---------------------------------------------------------------------------
RAISERROR(N'--- C. spMstrg_2606 @ipgStKey=42 → RS1 ---', 0, 1) WITH NOWAIT;

SET @t0 = SYSDATETIME();
EXEC ags.spMstrg_2606
    @ipgCh         = @ipgCh,
    @MounthEndDate = @dt,
    @ipgStKey      = @stIpg,
    @stCostKey     = NULL,
    @saveToTables  = 1;
SET @ms = DATEDIFF(ms, @t0, SYSDATETIME());

SELECT @rs1Raw = COUNT(*),
       @rs1Cst = COUNT(DISTINCT cstapKey),
       @rs1Dt  = COUNT(DISTINCT dateRslt),
       @rs1Other = SUM(CASE WHEN cstapKey <> @cstAgPn THEN 1 ELSE 0 END)
FROM ags.spMstrg_2606_ResultSet1;

SET @msg = N'  RS1 raw=' + CAST(@rs1Raw AS nvarchar(10))
    + N' distinct cst=' + CAST(@rs1Cst AS nvarchar(10))
    + N' distinct dateRslt=' + CAST(@rs1Dt AS nvarchar(10))
    + N' exec ms=' + CAST(@ms AS nvarchar(10))
    + N' (expected raw=64, cst=1, dt=16; NOT ~14447)';
RAISERROR(@msg, 0, 1) WITH NOWAIT;

IF @rs1Raw >= 5000 OR @rs1Raw = 0 OR @rs1Cst <> 1 OR @rs1Dt <> 16 OR ISNULL(@rs1Other, 0) <> 0
BEGIN
    SET @fail = @fail + 1;
    RAISERROR(N'  FAIL: RS1 count/universe', 0, 1) WITH NOWAIT;
END

IF @rs1Raw <> @pbRaw
BEGIN
    SET @fail = @fail + 1;
    SET @msg = N'  FAIL: RS1 raw <> PercentBrn raw (' + CAST(@rs1Raw AS nvarchar(10))
        + N' vs ' + CAST(@pbRaw AS nvarchar(10)) + N')';
    RAISERROR(@msg, 0, 1) WITH NOWAIT;
END

-- ---------------------------------------------------------------------------
-- D. RS1 ↔ PercentBrn (07f F.3 dedup keys)
-- ---------------------------------------------------------------------------
RAISERROR(N'--- D. RS1 ↔ PercentBrn key compare ---', 0, 1) WITH NOWAIT;

IF OBJECT_ID('tempdb..#rs1k') IS NOT NULL DROP TABLE #rs1k;

SELECT dateRslt, ipgKey, cstapKey,
       MAX(ag_lim) AS ag_lim, MAX(ag_Pl) AS ag_Pl,
       MAX(ag_presented) AS ag_presented, MAX(ag_percentDev) AS ag_percentDev
INTO #rs1k
FROM ags.spMstrg_2606_ResultSet1
WHERE cstapKey = @cstAgPn
GROUP BY dateRslt, ipgKey, cstapKey;

SELECT @keyDiff = COUNT(*)
FROM #pb42 a
FULL OUTER JOIN #rs1k b
    ON a.dateRslt = b.dateRslt
   AND ISNULL(a.ipgKey, -1)   = ISNULL(b.ipgKey, -1)
   AND ISNULL(a.cstapKey, -1) = ISNULL(b.cstapKey, -1)
WHERE a.dateRslt IS NULL OR b.dateRslt IS NULL
   OR ABS(ISNULL(a.ag_presented, 0) - ISNULL(b.ag_presented, 0)) > 0.01
   OR ABS(ISNULL(a.ag_lim, 0) - ISNULL(b.ag_lim, 0)) > 0.01
   OR ABS(ISNULL(a.ag_Pl, 0) - ISNULL(b.ag_Pl, 0)) > 0.01
   OR ABS(ISNULL(a.ag_percentDev, 0) - ISNULL(b.ag_percentDev, 0)) > 0.0001;

SET @msg = N'  dedup keys pb=' + CAST((SELECT COUNT(*) FROM #pb42) AS nvarchar(10))
    + N' rs1=' + CAST((SELECT COUNT(*) FROM #rs1k) AS nvarchar(10))
    + N' keyDiff=' + CAST(@keyDiff AS nvarchar(10)) + N' (expected 0)';
RAISERROR(@msg, 0, 1) WITH NOWAIT;

IF @keyDiff <> 0
BEGIN
    SET @fail = @fail + 1;
    RAISERROR(N'  FAIL: RS1 vs PercentBrn fields', 0, 1) WITH NOWAIT;
END

DROP TABLE #pb42;
DROP TABLE #rs1k;

IF @fail = 0
    RAISERROR(N'=== 07r: PASS ===', 0, 1) WITH NOWAIT;
ELSE
BEGIN
    SET @msg = N'=== 07r: FAIL (' + CAST(@fail AS nvarchar(10)) + N' check(s)) ===';
    RAISERROR(@msg, 0, 1) WITH NOWAIT;
END
GO
