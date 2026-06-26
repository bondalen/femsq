USE [FishEye];
GO
-- =============================================================================
-- 07o_plan_17dates_chain5.sql
-- Строгая приёмка плана UtPl (18.7.4): матрица 17 дат, полная цепь 5 (~1889 ipgp).
--
-- Предусловие: FIXTURE_06 + FIXTURE_07 (UtPl в группах 18/19/20).
--
-- Критерии:
--   К-12b/c/t — как 07n; К-12t на датах ipgcrvEnd (ужесточение _2605, Решение 14)
--   К-13b     — аддитивность RS на каждой dd
--   К-14      — P2 (fnStCostRsIpgPn): на @dt план только у активной ИП (неактивные = 0)
--   К-15      — P1 (mastering) на 31.12: cum = лимит по stCost у активной ipgPn
--   К-16      — P2 на 31.12: cum = лимит активного пункта
--   К-17      — на ipgcrvEnd: cum(UtPl) = smmTtl (смена ИП в цепи)
-- =============================================================================
SET NOCOUNT ON;
GO

DECLARE @ipgCh           int   = 5;
DECLARE @yearend         date  = '2022-12-31';
DECLARE @epsilon         money = 0.01;
DECLARE @epsilonAdd      money = 5.00;

DECLARE @stNet   int = (SELECT ipgcStNetIpg FROM ags.ipgCh WHERE ipgcKey = @ipgCh);
DECLARE @ipgRoot int = 1;
DECLARE @t0      datetime2 = SYSDATETIME();

DECLARE @msg nvarchar(800);
SET @msg = N'=== 07o strict plan × 17 dates  chain=' + CAST(@ipgCh AS nvarchar)
         + N'  FULL ===';
RAISERROR(@msg, 0, 1) WITH NOWAIT;

-- =========================================================================
-- Ревизии / ipgPn с UtPl в тестовых группах
-- =========================================================================
IF OBJECT_ID('tempdb..#rev') IS NOT NULL DROP TABLE #rev;
SELECT
    p.ipgpKey,
    p.ipgpSh,
    p.ipgpCstAgPn,
    v.ipgcrvStr,
    v.ipgcrvEnd,
    v.ipgcrvUtPlGr,
    CAST(p.ipgpSmTtl * 1000000 AS money) AS ref212,
    CAST(ISNULL(p.ipgpSmWrk, 0) * 1000000 AS money) AS ref195,
    CAST(ISNULL(p.ipgpSmEqu, 0) * 1000000 AS money) AS ref172,
    CAST(ISNULL(p.ipgpSmOth, 0) * 1000000 AS money) AS ref187
INTO #rev
FROM ags.ipgPn p
INNER JOIN ags.ipgChRlV v ON v.ipgcrvIpg = p.ipgpIpg AND v.ipgcrvChain = @ipgCh;

DECLARE @rev_cnt int = (SELECT COUNT(*) FROM #rev);
RAISERROR(N'  ipgPn on chain: %d', 0, 1, @rev_cnt) WITH NOWAIT;

IF OBJECT_ID('tempdb..#pn') IS NOT NULL DROP TABLE #pn;
SELECT DISTINCT
    r.ipgpKey, r.ipgpSh, r.ipgpCstAgPn, r.ipgcrvUtPlGr, r.ipgcrvStr, r.ipgcrvEnd,
    r.ref212, r.ref195, r.ref172, r.ref187
INTO #pn
FROM #rev r
WHERE EXISTS (
    SELECT 1
    FROM ags.ipgUtPlPnLmMn m
    INNER JOIN ags.ipgUtPlP up ON up.iuplpKey = m.iuplpmPlPn
    INNER JOIN ags.ipgUtPlGrP gp ON gp.iuplgpPl = up.iuplpPl AND gp.iuplgpGr = r.ipgcrvUtPlGr
    WHERE up.iuplpIpgPn = r.ipgpKey AND m.iuplpmStCost = 212 AND m.iuplpmLim > 0
);

DECLARE @pn_cnt int = (SELECT COUNT(*) FROM #pn);
RAISERROR(N'  ipgPn with test-gr UtPl: %d', 0, 1, @pn_cnt) WITH NOWAIT;

IF @pn_cnt < 100
BEGIN
    RAISERROR(N'Too few ipgPn with UtPl (%d) — apply FIXTURE_07.', 16, 1, @pn_cnt);
    RETURN;
END;

IF OBJECT_ID('tempdb..#dates') IS NOT NULL DROP TABLE #dates;
SELECT d.dAll AS dt
INTO #dates
FROM ags.fnIpgChDatsV(@ipgCh) d
ORDER BY d.dAll;

DECLARE @nd int = (SELECT COUNT(*) FROM #dates);
RAISERROR(N'  control dates: %d', 0, 1, @nd) WITH NOWAIT;

-- =========================================================================
-- DATA + cum UtPl
-- =========================================================================
IF OBJECT_ID('tempdb..#utpl_cum') IS NOT NULL DROP TABLE #utpl_cum;
;WITH base AS (
    SELECT up.iuplpIpgPn AS ipgpKey, m.iuplpmStCost, m.iuplpmMn, m.iuplpmLim
    FROM ags.ipgUtPlPnLmMn m
    INNER JOIN ags.ipgUtPlP up ON up.iuplpKey = m.iuplpmPlPn
    INNER JOIN #pn p ON p.ipgpKey = up.iuplpIpgPn
    INNER JOIN ags.ipgUtPlGrP gp ON gp.iuplgpPl = up.iuplpPl AND gp.iuplgpGr = p.ipgcrvUtPlGr
    WHERE m.iuplpmStCost IN (212, 195, 172, 187)
),
cum AS (
    SELECT ipgpKey, iuplpmStCost, iuplpmMn, iuplpmLim,
        SUM(iuplpmLim) OVER (
            PARTITION BY ipgpKey, iuplpmStCost ORDER BY iuplpmMn
            ROWS UNBOUNDED PRECEDING
        ) AS cum_lim
    FROM base
)
SELECT ipgpKey, iuplpmStCost, iuplpmMn,
    CAST(cum_lim * 1000000 AS money) AS cum_money
INTO #utpl_cum
FROM cum;

-- =========================================================================
-- RS timeline (P2)
-- =========================================================================
IF OBJECT_ID('tempdb..#rs') IS NOT NULL DROP TABLE #rs;
CREATE TABLE #rs (
    ipgpKey      int   NOT NULL,
    iuplpmStCost int   NOT NULL,
    dd           date  NOT NULL,
    mKey         int   NULL,
    smmTtl       money NULL,
    PRIMARY KEY (ipgpKey, iuplpmStCost, dd)
);

DECLARE @k int, @sh int, @gr int;
DECLARE cur CURSOR LOCAL FAST_FORWARD FOR SELECT ipgpKey, ipgpSh, ipgcrvUtPlGr FROM #pn;
OPEN cur;
FETCH NEXT FROM cur INTO @k, @sh, @gr;
WHILE @@FETCH_STATUS = 0
BEGIN
    INSERT INTO #rs (ipgpKey, iuplpmStCost, dd, mKey, smmTtl)
    SELECT @k, stc, r.dd, r.mKey, r.smmTtl
    FROM (VALUES (212),(195),(172),(187)) v(stc)
    CROSS APPLY (
        SELECT dd, mKey, smmTtl
        FROM ags.fnStCostRsIpgPn_2606(@ipgCh, @k, @gr, v.stc, @stNet, @sh)
        WHERE dd IS NOT NULL
    ) r;
    FETCH NEXT FROM cur INTO @k, @sh, @gr;
END;
CLOSE cur; DEALLOCATE cur;

-- =========================================================================
-- Счётчики FAIL
-- =========================================================================
DECLARE @fail_data int = 0, @fail_k12c int = 0, @fail_k12t int = 0, @fail_k13b int = 0;
DECLARE @fail_k14 int = 0, @fail_k15 int = 0, @fail_k16 int = 0, @fail_k17 int = 0;

SELECT @fail_data = COUNT(*)
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
) x WHERE d212 > @epsilon OR d195 > @epsilon OR d172 > @epsilon OR d187 > @epsilon;

-- К-12c: timeline на всех dd (sparse: cum на mKey = last month ≤ mKey)
SELECT @fail_k12c = COUNT(*)
FROM #rs r
WHERE ABS(ISNULL((
    SELECT TOP 1 c.cum_money FROM #utpl_cum c
    WHERE c.ipgpKey = r.ipgpKey AND c.iuplpmStCost = r.iuplpmStCost AND c.iuplpmMn <= r.mKey
    ORDER BY c.iuplpmMn DESC
), 0) - ISNULL(r.smmTtl, 0)) > @epsilon;

-- К-13b: additive на всех dd
;WITH pvt AS (
    SELECT ipgpKey, dd,
        MAX(CASE WHEN iuplpmStCost = 212 THEN smmTtl END) AS p212,
        MAX(CASE WHEN iuplpmStCost = 195 THEN smmTtl END) AS p195,
        MAX(CASE WHEN iuplpmStCost = 172 THEN smmTtl END) AS p172,
        MAX(CASE WHEN iuplpmStCost = 187 THEN smmTtl END) AS p187
    FROM #rs GROUP BY ipgpKey, dd
)
SELECT @fail_k13b = COUNT(*) FROM pvt
WHERE ABS(ISNULL(p212, 0) - (ISNULL(p172, 0) + ISNULL(p187, 0) + ISNULL(p195, 0))) > @epsilonAdd;

-- К-12t / К-17: на ipgcrvEnd
SELECT @fail_k12t = COUNT(*)
FROM #pn p
INNER JOIN #rs r ON r.ipgpKey = p.ipgpKey AND r.iuplpmStCost = 212 AND r.dd = p.ipgcrvEnd
WHERE p.ipgcrvEnd IS NOT NULL
  AND ABS(ISNULL((
      SELECT TOP 1 c.cum_money FROM #utpl_cum c
      WHERE c.ipgpKey = r.ipgpKey AND c.iuplpmStCost = r.iuplpmStCost AND c.iuplpmMn <= r.mKey
      ORDER BY c.iuplpmMn DESC
  ), 0) - ISNULL(r.smmTtl, 0)) > @epsilon;

SET @fail_k17 = @fail_k12t;

-- К-14: на каждой из 17 дат — неактивные ipgPn имеют нулевой план @212
SELECT @fail_k14 = COUNT(*)
FROM #dates d
CROSS JOIN #pn p
INNER JOIN #rs r ON r.ipgpKey = p.ipgpKey AND r.iuplpmStCost = 212 AND r.dd = d.dt
WHERE NOT (p.ipgcrvStr <= d.dt AND (p.ipgcrvEnd IS NULL OR p.ipgcrvEnd >= d.dt))
  AND ABS(ISNULL(r.smmTtl, 0)) > @epsilon;

-- К-16: P2 на 31.12 у активной ipgPn
SELECT @fail_k16 = COUNT(*)
FROM #pn p
WHERE p.ipgcrvStr <= @yearend AND (p.ipgcrvEnd IS NULL OR p.ipgcrvEnd >= @yearend)
  AND (
      EXISTS (SELECT 1 FROM #rs x WHERE x.ipgpKey = p.ipgpKey AND x.iuplpmStCost = 212 AND x.dd = @yearend
              AND ABS(ISNULL(x.smmTtl, 0) - p.ref212) > @epsilon)
      OR EXISTS (SELECT 1 FROM #rs x WHERE x.ipgpKey = p.ipgpKey AND x.iuplpmStCost = 195 AND x.dd = @yearend
              AND ABS(ISNULL(x.smmTtl, 0) - p.ref195) > @epsilon)
      OR EXISTS (SELECT 1 FROM #rs x WHERE x.ipgpKey = p.ipgpKey AND x.iuplpmStCost = 172 AND x.dd = @yearend
              AND ABS(ISNULL(x.smmTtl, 0) - p.ref172) > @epsilon)
      OR EXISTS (SELECT 1 FROM #rs x WHERE x.ipgpKey = p.ipgpKey AND x.iuplpmStCost = 187 AND x.dd = @yearend
              AND ABS(ISNULL(x.smmTtl, 0) - p.ref187) > @epsilon)
  );

-- К-15: P1 mastering на 31.12 у активной ipgPn
SELECT @fail_k15 = COUNT(*)
FROM #pn p
WHERE p.ipgcrvStr <= @yearend AND (p.ipgcrvEnd IS NULL OR p.ipgcrvEnd >= @yearend)
  AND EXISTS (
      SELECT 1 FROM (VALUES (212, p.ref212),(195, p.ref195),(172, p.ref172),(187, p.ref187)) t(stc, ref)
      WHERE ABS(ISNULL((
          SELECT SUM(COALESCE(m.agSmmTtl, m.inSmmTtl, m.drSmmTtl, 0))
          FROM ags.fnMasteringCstAgPnSh_2606(@ipgCh, p.ipgpCstAgPn, t.stc, @stNet, @ipgRoot) m
          WHERE m.ipgpKey = p.ipgpKey AND m.dAll = @yearend
      ), 0) - t.ref) > @epsilon
  );

-- =========================================================================
-- Отчёт по датам (краткий)
-- =========================================================================
RAISERROR(N'--- per-date K-14 (inactive plan@212 must be 0) ---', 0, 1) WITH NOWAIT;

SELECT d.dt,
    SUM(CASE WHEN p.ipgcrvStr <= d.dt AND (p.ipgcrvEnd IS NULL OR p.ipgcrvEnd >= d.dt) THEN 1 ELSE 0 END) AS active_pn,
    SUM(CASE WHEN NOT (p.ipgcrvStr <= d.dt AND (p.ipgcrvEnd IS NULL OR p.ipgcrvEnd >= d.dt))
              AND ABS(ISNULL(r.smmTtl, 0)) > @epsilon THEN 1 ELSE 0 END) AS k14_fail
FROM #dates d
CROSS JOIN #pn p
LEFT JOIN #rs r ON r.ipgpKey = p.ipgpKey AND r.iuplpmStCost = 212 AND r.dd = d.dt
GROUP BY d.dt
ORDER BY d.dt;

-- =========================================================================
-- Итог
-- =========================================================================
DECLARE @fail_total int = ISNULL(@fail_data, 0) + ISNULL(@fail_k12c, 0) + ISNULL(@fail_k12t, 0)
                        + ISNULL(@fail_k13b, 0) + ISNULL(@fail_k14, 0)
                        + ISNULL(@fail_k15, 0) + ISNULL(@fail_k16, 0) + ISNULL(@fail_k17, 0);
DECLARE @ms int = DATEDIFF(ms, @t0, SYSDATETIME());

SET @msg = N'07o | chain=' + CAST(@ipgCh AS nvarchar) + N' | pn=' + CAST(@pn_cnt AS nvarchar)
         + N' | dates=' + CAST(@nd AS nvarchar)
         + N' | fail data/k12c/k12t/k13b/k14/k15/k16/k17='
         + CAST(ISNULL(@fail_data, 0) AS nvarchar) + N'/'
         + CAST(ISNULL(@fail_k12c, 0) AS nvarchar) + N'/'
         + CAST(ISNULL(@fail_k12t, 0) AS nvarchar) + N'/'
         + CAST(ISNULL(@fail_k13b, 0) AS nvarchar) + N'/'
         + CAST(ISNULL(@fail_k14, 0) AS nvarchar) + N'/'
         + CAST(ISNULL(@fail_k15, 0) AS nvarchar) + N'/'
         + CAST(ISNULL(@fail_k16, 0) AS nvarchar) + N'/'
         + CAST(ISNULL(@fail_k17, 0) AS nvarchar)
         + N' | ms=' + CAST(@ms AS nvarchar)
         + CASE WHEN @fail_total = 0 THEN N' | PASS' ELSE N' | *** FAIL ***' END;
RAISERROR(@msg, 0, 1) WITH NOWAIT;

IF @fail_total > 0
    RAISERROR(N'07o strict plan 17-date check failed.', 16, 1);

RAISERROR(N'=== 07o завершено ===', 0, 1) WITH NOWAIT;
GO
