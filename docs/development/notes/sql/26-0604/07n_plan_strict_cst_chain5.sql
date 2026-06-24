USE [FishEye];
GO
-- =============================================================================
-- 07n_plan_strict_cst_chain5.sql
-- Строгая приёмка плана UtPl (этап 18.7): одна стройка → цепь → агрегация.
--
-- Критерии (в пределах одной ipgPn / периода актуальности в цепи):
--   К-12b: на @MounthEndDate накопленный план = лимит по каждому stCost (212/195/172/187)
--   К-12c: на каждой дате dd стека smmTtl = cum(UtPlMn через mKey) × 1e6
--   К-13b: на каждой dd plan@212 ≈ @172+@187+@195
--   К-12r: на ipgcrvEnd ревизии — план = cum(UtPl) на эту дату (смена ИП в цепи)
--
-- Параметры: @ipgCh, @cstAgPn (или @stIpg), @MounthEndDate
-- =============================================================================
SET NOCOUNT ON;
GO

DECLARE @ipgCh           int   = 5;
DECLARE @cstAgPn         int   = 2102;   -- <<< пилот; stIpg=61
DECLARE @stIpg           int   = NULL;   -- <<< если задан — переопределяет @cstAgPn
DECLARE @MounthEndDate   date  = '2022-12-31';
DECLARE @epsilon         money = 0.01;
DECLARE @epsilonAdd      money = 5.00;

DECLARE @stNet   int = (SELECT ipgcStNetIpg FROM ags.ipgCh WHERE ipgcKey = @ipgCh);
DECLARE @ipgRoot int = ISNULL(@stIpg, 1);
DECLARE @t0      datetime2 = SYSDATETIME();

IF @stIpg IS NOT NULL
BEGIN
    SELECT TOP (1) @cstAgPn = p.ipgpCstAgPn
    FROM ags.ipgStPn sp
    INNER JOIN ags.ipgPn p ON p.ipgpKey = sp.ipgspPn
    INNER JOIN ags.ipgChRlV v ON v.ipgcrvIpg = p.ipgpIpg AND v.ipgcrvChain = @ipgCh
    WHERE sp.ipgspSt = @stIpg AND p.ipgpCstAgPn IS NOT NULL;
END;

DECLARE @msg nvarchar(600);
SET @msg = N'=== 07n strict plan  chain=' + CAST(@ipgCh AS nvarchar)
         + N'  cstAgPn=' + CAST(@cstAgPn AS nvarchar)
         + N'  stIpg=' + ISNULL(CAST(@stIpg AS nvarchar), N'NULL')
         + N'  dt=' + CONVERT(nvarchar(10), @MounthEndDate, 23) + N' ===';
RAISERROR(@msg, 0, 1) WITH NOWAIT;

-- =========================================================================
-- Ревизии ipgPn на цепи (периоды актуальности)
-- =========================================================================
RAISERROR(N'--- [0] IPG revisions on chain ---', 0, 1) WITH NOWAIT;

IF OBJECT_ID('tempdb..#rev') IS NOT NULL DROP TABLE #rev;
SELECT
    p.ipgpKey,
    p.ipgpSh,
    v.ipgcrvStr,
    v.ipgcrvEnd,
    v.ipgcrvUtPlGr,
    CAST(p.ipgpSmTtl * 1000000 AS money) AS ref212,
    CAST(ISNULL(p.ipgpSmWrk, 0) * 1000000 AS money) AS ref195,
    CAST(ISNULL(p.ipgpSmEqu, 0) * 1000000 AS money) AS ref172,
    CAST(ISNULL(p.ipgpSmOth, 0) * 1000000 AS money) AS ref187,
    CASE WHEN v.ipgcrvStr <= @MounthEndDate
              AND (v.ipgcrvEnd IS NULL OR v.ipgcrvEnd >= @MounthEndDate)
         THEN 1 ELSE 0 END AS active_on_dt
INTO #rev
FROM ags.ipgPn p
INNER JOIN ags.ipgChRlV v ON v.ipgcrvIpg = p.ipgpIpg AND v.ipgcrvChain = @ipgCh
WHERE p.ipgpCstAgPn = @cstAgPn
ORDER BY v.ipgcrvStr;

SELECT ipgpKey, ipgpSh, ipgcrvStr, ipgcrvEnd, ipgcrvUtPlGr, active_on_dt FROM #rev;

-- =========================================================================
-- ipgPn с UtPlMn на этой стройке
-- =========================================================================
IF OBJECT_ID('tempdb..#pn') IS NOT NULL DROP TABLE #pn;
SELECT DISTINCT
    r.ipgpKey,
    r.ipgpSh,
    r.ipgcrvUtPlGr,
    r.ipgcrvStr,
    r.ipgcrvEnd,
    r.active_on_dt,
    r.ref212, r.ref195, r.ref172, r.ref187
INTO #pn
FROM #rev r
WHERE EXISTS (
    SELECT 1
    FROM ags.ipgUtPlPnLmMn m
    INNER JOIN ags.ipgUtPlP up ON up.iuplpKey = m.iuplpmPlPn
    INNER JOIN ags.ipgUtPlGrP gp ON gp.iuplgpPl = up.iuplpPl AND gp.iuplgpGr = r.ipgcrvUtPlGr
    WHERE up.iuplpIpgPn = r.ipgpKey AND m.iuplpmStCost = 212
);

DECLARE @npn int = (SELECT COUNT(*) FROM #pn);
RAISERROR(N'  ipgPn with UtPlMn: %d', 0, 1, @npn) WITH NOWAIT;

IF @npn = 0
BEGIN
    RAISERROR(N'No UtPlMn on cstAgPn — apply FIXTURE_05 or pick another cst.', 16, 1);
    RETURN;
END;

-- =========================================================================
-- Фаза 1: DATA sum(UtPlMn) = лимит
-- =========================================================================
RAISERROR(N'--- [1/5] DATA: sum(UtPlMn) vs limit ---', 0, 1) WITH NOWAIT;

IF OBJECT_ID('tempdb..#utpl_cum') IS NOT NULL DROP TABLE #utpl_cum;
;WITH base AS (
    SELECT
        up.iuplpIpgPn AS ipgpKey,
        m.iuplpmStCost,
        m.iuplpmMn,
        m.iuplpmLim
    FROM ags.ipgUtPlPnLmMn m
    INNER JOIN ags.ipgUtPlP up ON up.iuplpKey = m.iuplpmPlPn
    INNER JOIN #pn p ON p.ipgpKey = up.iuplpIpgPn
    INNER JOIN ags.ipgUtPlGrP gp ON gp.iuplgpPl = up.iuplpPl AND gp.iuplgpGr = p.ipgcrvUtPlGr
    WHERE m.iuplpmStCost IN (212, 195, 172, 187)
),
cum AS (
    SELECT
        ipgpKey,
        iuplpmStCost,
        iuplpmMn,
        iuplpmLim,
        SUM(iuplpmLim) OVER (
            PARTITION BY ipgpKey, iuplpmStCost
            ORDER BY iuplpmMn
            ROWS UNBOUNDED PRECEDING
        ) AS cum_lim
    FROM base
)
SELECT
    ipgpKey,
    iuplpmStCost,
    iuplpmMn,
    CAST(cum_lim * 1000000 AS money) AS cum_money,
    CAST(iuplpmLim * 1000000 AS money) AS mn_money
INTO #utpl_cum
FROM cum;

DECLARE @data_fail int = 0;
SELECT @data_fail = COUNT(*)
FROM (
    SELECT p.ipgpKey,
        ABS(ISNULL(SUM(CASE WHEN m.iuplpmStCost = 212 THEN m.iuplpmLim END), 0) - p.ref212 / 1000000.0) AS d212,
        ABS(ISNULL(SUM(CASE WHEN m.iuplpmStCost = 195 THEN m.iuplpmLim END), 0) - p.ref195 / 1000000.0) AS d195,
        ABS(ISNULL(SUM(CASE WHEN m.iuplpmStCost = 172 THEN m.iuplpmLim END), 0) - p.ref172 / 1000000.0) AS d172,
        ABS(ISNULL(SUM(CASE WHEN m.iuplpmStCost = 187 THEN m.iuplpmLim END), 0) - p.ref187 / 1000000.0) AS d187
    FROM #pn p
    INNER JOIN ags.ipgUtPlP up ON up.iuplpIpgPn = p.ipgpKey
    INNER JOIN ags.ipgUtPlGrP gp ON gp.iuplgpPl = up.iuplpPl AND gp.iuplgpGr = p.ipgcrvUtPlGr
    INNER JOIN ags.ipgUtPlPnLmMn m ON m.iuplpmPlPn = up.iuplpKey AND m.iuplpmStCost IN (212, 195, 172, 187)
    GROUP BY p.ipgpKey, p.ref212, p.ref195, p.ref172, p.ref187
) x
WHERE d212 > @epsilon OR d195 > @epsilon OR d172 > @epsilon OR d187 > @epsilon;

SET @msg = N'  DATA fail ipgPn=' + CAST(ISNULL(@data_fail, 0) AS nvarchar)
         + CASE WHEN ISNULL(@data_fail, 0) = 0 THEN N'  PASS' ELSE N'  *** FAIL ***' END;
RAISERROR(@msg, 0, 1) WITH NOWAIT;

IF ISNULL(@data_fail, 0) > 0 RETURN;

-- =========================================================================
-- Фаза 2: fnStCostRsIpgPn — timeline (К-12c) + yearend (К-12b) + revision end (К-12r)
-- =========================================================================
RAISERROR(N'--- [2/5] RS: timeline + yearend + revision-end ---', 0, 1) WITH NOWAIT;

IF OBJECT_ID('tempdb..#rs') IS NOT NULL DROP TABLE #rs;
CREATE TABLE #rs (
    ipgpKey     int   NOT NULL,
    iuplpmStCost int  NOT NULL,
    dd          date  NOT NULL,
    mKey        int   NULL,
    smmTtl      money NULL,
    lim_val     money NULL,
    PRIMARY KEY (ipgpKey, iuplpmStCost, dd)
);

DECLARE @k int, @sh int, @gr int;
DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT ipgpKey, ipgpSh, ipgcrvUtPlGr FROM #pn;
OPEN cur;
FETCH NEXT FROM cur INTO @k, @sh, @gr;
WHILE @@FETCH_STATUS = 0
BEGIN
    INSERT INTO #rs (ipgpKey, iuplpmStCost, dd, mKey, smmTtl, lim_val)
    SELECT @k, stc, r.dd, r.mKey, r.smmTtl, r.lim
    FROM (VALUES (212),(195),(172),(187)) v(stc)
    CROSS APPLY (
        SELECT dd, mKey, smmTtl, lim
        FROM ags.fnStCostRsIpgPn_2606(@ipgCh, @k, @gr, v.stc, @stNet, @sh)
        WHERE dd IS NOT NULL
    ) r;
    FETCH NEXT FROM cur INTO @k, @sh, @gr;
END;
CLOSE cur;
DEALLOCATE cur;

DECLARE @fail_timeline int = 0, @fail_yearend int = 0, @fail_revn int = 0;

SELECT @fail_timeline = COUNT(*)
FROM #rs r
WHERE NOT EXISTS (
    SELECT 1 FROM #utpl_cum c
    WHERE c.ipgpKey = r.ipgpKey AND c.iuplpmStCost = r.iuplpmStCost AND c.iuplpmMn = r.mKey
      AND ABS(c.cum_money - ISNULL(r.smmTtl, 0)) <= @epsilon
);

SELECT @fail_yearend = COUNT(*)
FROM #pn p
INNER JOIN #rs r ON r.ipgpKey = p.ipgpKey AND r.iuplpmStCost = 212 AND r.dd = @MounthEndDate
WHERE p.active_on_dt = 1
  AND (ABS(ISNULL(r.smmTtl, 0) - p.ref212) > @epsilon
    OR EXISTS (SELECT 1 FROM #rs x WHERE x.ipgpKey = p.ipgpKey AND x.iuplpmStCost = 195 AND x.dd = @MounthEndDate AND ABS(ISNULL(x.smmTtl,0)-p.ref195)>@epsilon)
    OR EXISTS (SELECT 1 FROM #rs x WHERE x.ipgpKey = p.ipgpKey AND x.iuplpmStCost = 172 AND x.dd = @MounthEndDate AND ABS(ISNULL(x.smmTtl,0)-p.ref172)>@epsilon)
    OR EXISTS (SELECT 1 FROM #rs x WHERE x.ipgpKey = p.ipgpKey AND x.iuplpmStCost = 187 AND x.dd = @MounthEndDate AND ABS(ISNULL(x.smmTtl,0)-p.ref187)>@epsilon));

SELECT @fail_revn = COUNT(*)
FROM #pn p
INNER JOIN #rs r ON r.ipgpKey = p.ipgpKey AND r.iuplpmStCost = 212 AND r.dd = p.ipgcrvEnd
WHERE p.ipgcrvEnd IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM #utpl_cum c
      WHERE c.ipgpKey = r.ipgpKey AND c.iuplpmStCost = r.iuplpmStCost AND c.iuplpmMn = r.mKey
        AND ABS(c.cum_money - ISNULL(r.smmTtl, 0)) <= @epsilon
  );

SET @msg = N'  RS timeline fail=' + CAST(ISNULL(@fail_timeline, 0) AS nvarchar)
         + N'  yearend fail=' + CAST(ISNULL(@fail_yearend, 0) AS nvarchar)
         + N'  revision-end fail=' + CAST(ISNULL(@fail_revn, 0) AS nvarchar);
RAISERROR(@msg, 0, 1) WITH NOWAIT;

IF ISNULL(@fail_timeline, 0) > 0
BEGIN
    RAISERROR(N'  TOP RS timeline mismatches:', 0, 1) WITH NOWAIT;
    SELECT TOP 10 r.ipgpKey, r.iuplpmStCost, r.dd, r.mKey, r.smmTtl,
        (SELECT TOP 1 c.cum_money FROM #utpl_cum c
         WHERE c.ipgpKey = r.ipgpKey AND c.iuplpmStCost = r.iuplpmStCost AND c.iuplpmMn = r.mKey) AS utpl_cum
    FROM #rs r
    WHERE NOT EXISTS (
        SELECT 1 FROM #utpl_cum c
        WHERE c.ipgpKey = r.ipgpKey AND c.iuplpmStCost = r.iuplpmStCost AND c.iuplpmMn = r.mKey
          AND ABS(c.cum_money - ISNULL(r.smmTtl, 0)) <= @epsilon
    );
END;

-- =========================================================================
-- Фаза 3: MASTERING fnMasteringCstAgPnSh @MounthEndDate (К-12b stack)
-- =========================================================================
RAISERROR(N'--- [3/5] MASTERING @dt vs limit (active ipgPn) ---', 0, 1) WITH NOWAIT;

DECLARE @fail_mst int = 0;
SELECT @fail_mst = COUNT(*)
FROM #pn p
WHERE p.active_on_dt = 1
  AND EXISTS (
      SELECT 1 FROM (VALUES (212, p.ref212),(195, p.ref195),(172, p.ref172),(187, p.ref187)) t(stc, ref)
      WHERE ABS(ISNULL((
          SELECT SUM(COALESCE(m.agSmmTtl, m.inSmmTtl, m.drSmmTtl, 0))
          FROM ags.fnMasteringCstAgPnSh_2606(@ipgCh, @cstAgPn, t.stc, @stNet, @ipgRoot) m
          WHERE m.ipgpKey = p.ipgpKey AND m.dAll = @MounthEndDate
      ), 0) - t.ref) > @epsilon
  );

SET @msg = N'  MASTERING @dt fail ipgPn=' + CAST(ISNULL(@fail_mst, 0) AS nvarchar);
RAISERROR(@msg, 0, 1) WITH NOWAIT;

-- =========================================================================
-- Фаза 4: ADDITIVE по датам RS (К-13b)
-- =========================================================================
RAISERROR(N'--- [4/5] RS additive @212 = @172+@187+@195 ---', 0, 1) WITH NOWAIT;

DECLARE @fail_add int = 0;
;WITH pvt AS (
    SELECT ipgpKey, dd,
        MAX(CASE WHEN iuplpmStCost = 212 THEN smmTtl END) AS p212,
        MAX(CASE WHEN iuplpmStCost = 195 THEN smmTtl END) AS p195,
        MAX(CASE WHEN iuplpmStCost = 172 THEN smmTtl END) AS p172,
        MAX(CASE WHEN iuplpmStCost = 187 THEN smmTtl END) AS p187
    FROM #rs
    GROUP BY ipgpKey, dd
)
SELECT @fail_add = COUNT(*)
FROM pvt
WHERE ABS(ISNULL(p212, 0) - (ISNULL(p172, 0) + ISNULL(p187, 0) + ISNULL(p195, 0))) > @epsilonAdd;

SET @msg = N'  RS additive fail dates=' + CAST(ISNULL(@fail_add, 0) AS nvarchar);
RAISERROR(@msg, 0, 1) WITH NOWAIT;

-- =========================================================================
-- Итог
-- =========================================================================
DECLARE @fail_total int = ISNULL(@fail_timeline, 0) + ISNULL(@fail_yearend, 0)
                        + ISNULL(@fail_revn, 0) + ISNULL(@fail_mst, 0) + ISNULL(@fail_add, 0);
DECLARE @ms int = DATEDIFF(ms, @t0, SYSDATETIME());

SET @msg = N'07n | cstAgPn=' + CAST(@cstAgPn AS nvarchar)
         + N' | fail timeline/yearend/revn/mst/add='
         + CAST(ISNULL(@fail_timeline, 0) AS nvarchar) + N'/'
         + CAST(ISNULL(@fail_yearend, 0) AS nvarchar) + N'/'
         + CAST(ISNULL(@fail_revn, 0) AS nvarchar) + N'/'
         + CAST(ISNULL(@fail_mst, 0) AS nvarchar) + N'/'
         + CAST(ISNULL(@fail_add, 0) AS nvarchar)
         + N' | ms=' + CAST(@ms AS nvarchar)
         + CASE WHEN @fail_total = 0 THEN N' | PASS' ELSE N' | *** FAIL ***' END;
RAISERROR(@msg, 0, 1) WITH NOWAIT;

IF @fail_total > 0
    RAISERROR(N'07n strict plan check failed.', 16, 1);

RAISERROR(N'=== 07n завершено ===', 0, 1) WITH NOWAIT;
GO
