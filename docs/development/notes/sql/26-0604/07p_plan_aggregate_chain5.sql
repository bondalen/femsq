USE [FishEye];
GO
-- =============================================================================
-- 07p_plan_aggregate_chain5.sql
-- Этап 18.7.3: согласованность накопленного плана при агрегации
--   ipgPn → cstAgPn → stIpg → филиал → агент (og)
-- на 17 датах fnIpgChDats_2606, пилотные cst с golden UtPl (FIXTURE_06).
--
-- Критерии:
--   К-18a: SUM(ipgp plan) = fnMasteringStIpgStCost(NULL) на (cstAgPn, dt)
--   К-18b: на выборочных stIpg (61, 46) сумма plan_cst = StIpgStCost(@stIpg)
--   К-18c: разбиение по филиалу сохраняет grand total на каждой dt
--   К-18d: разбиение по агенту (cstaInvestor) сохраняет grand total на каждой dt
-- =============================================================================
SET NOCOUNT ON;
GO

DECLARE @ipgCh       int   = 5;
DECLARE @stCost      int   = 212;
DECLARE @epsilon     money = 0.01;
DECLARE @t0          datetime2 = SYSDATETIME();
DECLARE @stNet int = (SELECT ipgcStNetIpg FROM ags.ipgCh WHERE ipgcKey = @ipgCh);
DECLARE @msg nvarchar(600);

RAISERROR(N'=== 07p plan aggregate  chain=5 ===', 0, 1) WITH NOWAIT;

IF OBJECT_ID('tempdb..#pilots') IS NOT NULL DROP TABLE #pilots;
CREATE TABLE #pilots (cstAgPn int NOT NULL PRIMARY KEY);
INSERT INTO #pilots (cstAgPn) VALUES
    (2102), (121), (631), (1251), (1608), (1713), (2080), (2146), (2212);

IF OBJECT_ID('tempdb..#dates') IS NOT NULL DROP TABLE #dates;
SELECT d.dAll AS dt INTO #dates FROM ags.fnIpgChDats_2606(@ipgCh) d;

IF OBJECT_ID('tempdb..#ipgp') IS NOT NULL DROP TABLE #ipgp;
SELECT DISTINCT p.ipgpKey, p.ipgpCstAgPn AS cstAgPn
INTO #ipgp
FROM ags.ipgPn p
INNER JOIN ags.ipgChRl_2606 v ON v.ipgcrvIpg = p.ipgpIpg AND v.ipgcrvChain = @ipgCh
INNER JOIN #pilots pl ON pl.cstAgPn = p.ipgpCstAgPn
WHERE p.ipgpSh = 1
  AND EXISTS (
      SELECT 1 FROM ags.ipgUtPlPnLmMn m
      INNER JOIN ags.ipgUtPlP up ON up.iuplpKey = m.iuplpmPlPn
      INNER JOIN ags.ipgUtPlGrP gp ON gp.iuplgpPl = up.iuplpPl AND gp.iuplgpGr = v.ipgcrvUtPlGr
      WHERE up.iuplpIpgPn = p.ipgpKey AND m.iuplpmStCost = @stCost
  );

DECLARE @nip int = (SELECT COUNT(*) FROM #ipgp);
RAISERROR(N'  golden ipgpPn: %d', 0, 1, @nip) WITH NOWAIT;

IF OBJECT_ID('tempdb..#plan_ipgp') IS NOT NULL DROP TABLE #plan_ipgp;
CREATE TABLE #plan_ipgp (
    cstAgPn int NOT NULL, ipgpKey int NOT NULL, dt date NOT NULL,
    plan_val money NOT NULL, PRIMARY KEY (cstAgPn, ipgpKey, dt)
);

DECLARE @cst int;
DECLARE cst_cur CURSOR LOCAL FAST_FORWARD FOR SELECT cstAgPn FROM #pilots;
OPEN cst_cur;
FETCH NEXT FROM cst_cur INTO @cst;
WHILE @@FETCH_STATUS = 0
BEGIN
    INSERT INTO #plan_ipgp (cstAgPn, ipgpKey, dt, plan_val)
    SELECT @cst, i.ipgpKey, d.dt, COALESCE(m.agSmmTtl, m.inSmmTtl, m.drSmmTtl, 0)
    FROM #ipgp i CROSS JOIN #dates d
    CROSS APPLY ags.fnMasteringCstAgPnSh_2606(@ipgCh, @cst, @stCost, @stNet, 1) m
    WHERE i.cstAgPn = @cst AND m.ipgpKey = i.ipgpKey AND m.dAll = d.dt;
    FETCH NEXT FROM cst_cur INTO @cst;
END;
CLOSE cst_cur; DEALLOCATE cst_cur;

IF OBJECT_ID('tempdb..#plan_cst') IS NOT NULL DROP TABLE #plan_cst;
SELECT cstAgPn, dt, SUM(plan_val) AS plan_val
INTO #plan_cst FROM #plan_ipgp GROUP BY cstAgPn, dt;

IF OBJECT_ID('tempdb..#plan_stipg') IS NOT NULL DROP TABLE #plan_stipg;
SELECT m.ipgpCstAgPn AS cstAgPn, m.dAll AS dt,
    COALESCE(m.agSmmTtl, m.inSmmTtl, m.drSmmTtl, 0) AS plan_val
INTO #plan_stipg
FROM ags.fnMasteringStIpgStCost_2606(NULL, @ipgCh, @stCost, NULL) m
INNER JOIN #pilots p ON p.cstAgPn = m.ipgpCstAgPn
INNER JOIN #dates d ON d.dt = m.dAll;

IF OBJECT_ID('tempdb..#meta') IS NOT NULL DROP TABLE #meta;
SELECT DISTINCT
    pl.cstAgPn,
    COALESCE(b.cstapbBranch, -1) AS branch,
    COALESCE(ca.cstaInvestor, -1) AS ogKey
INTO #meta
FROM #pilots pl
INNER JOIN ags.cstAgPn cap ON cap.cstapKey = pl.cstAgPn
INNER JOIN ags.cstAg ca ON ca.cstaKey = cap.cstapCsta
LEFT JOIN ags.cstAgPnBranch b ON b.cstapbCstAgPn = pl.cstAgPn
    AND (b.cstapbStart IS NULL OR b.cstapbStart <= '2022-12-31')
    AND (b.cstapbEnd IS NULL OR b.cstapbEnd >= '2022-01-01');

-- К-18a
DECLARE @fail_a int = 0;
SELECT @fail_a = COUNT(*)
FROM #plan_cst c
FULL JOIN #plan_stipg s ON s.cstAgPn = c.cstAgPn AND s.dt = c.dt
WHERE ABS(ISNULL(c.plan_val, 0) - ISNULL(s.plan_val, 0)) > @epsilon;

-- К-18b: stIpg 61 (cst 2102) и stIpg 46 (4 пилота)
DECLARE @fail_b int = 0;

;WITH rollup61 AS (
    SELECT c.dt, SUM(c.plan_val) AS plan_sum
    FROM #plan_cst c
    WHERE c.cstAgPn = 2102
    GROUP BY c.dt
),
st61 AS (
    SELECT m.dAll AS dt, SUM(COALESCE(m.agSmmTtl, m.inSmmTtl, m.drSmmTtl, 0)) AS plan_sum
    FROM ags.fnMasteringStIpgStCost_2606(61, @ipgCh, @stCost, NULL) m
    WHERE m.ipgpCstAgPn = 2102
    GROUP BY m.dAll
)
SELECT @fail_b = COUNT(*)
FROM rollup61 r
FULL JOIN st61 s ON s.dt = r.dt
WHERE ABS(ISNULL(r.plan_sum, 0) - ISNULL(s.plan_sum, 0)) > @epsilon;

;WITH rollup46 AS (
    SELECT c.dt, SUM(c.plan_val) AS plan_sum
    FROM #plan_cst c
    WHERE c.cstAgPn IN (631, 1251, 1713, 2080)
    GROUP BY c.dt
),
st46 AS (
    SELECT m.dAll AS dt, SUM(COALESCE(m.agSmmTtl, m.inSmmTtl, m.drSmmTtl, 0)) AS plan_sum
    FROM ags.fnMasteringStIpgStCost_2606(46, @ipgCh, @stCost, NULL) m
    WHERE m.ipgpCstAgPn IN (631, 1251, 1713, 2080)
    GROUP BY m.dAll
)
SELECT @fail_b = @fail_b + COUNT(*)
FROM rollup46 r
FULL JOIN st46 s ON s.dt = r.dt
WHERE ABS(ISNULL(r.plan_sum, 0) - ISNULL(s.plan_sum, 0)) > @epsilon;

-- К-18c / К-18d
DECLARE @fail_c int = 0, @fail_d int = 0;
;WITH grand AS (
    SELECT dt, SUM(plan_val) AS total FROM #plan_cst GROUP BY dt
),
by_branch AS (
    SELECT c.dt, SUM(c.plan_val) AS total
    FROM #plan_cst c
    INNER JOIN (SELECT DISTINCT cstAgPn, branch FROM #meta) m ON m.cstAgPn = c.cstAgPn
    GROUP BY c.dt
),
by_og AS (
    SELECT c.dt, SUM(c.plan_val) AS total
    FROM #plan_cst c
    INNER JOIN (SELECT DISTINCT cstAgPn, ogKey FROM #meta) m ON m.cstAgPn = c.cstAgPn
    GROUP BY c.dt
)
SELECT
    @fail_c = SUM(CASE WHEN ABS(g.total - b.total) > @epsilon THEN 1 ELSE 0 END),
    @fail_d = SUM(CASE WHEN ABS(g.total - o.total) > @epsilon THEN 1 ELSE 0 END)
FROM grand g
INNER JOIN by_branch b ON b.dt = g.dt
INNER JOIN by_og o ON o.dt = g.dt;

DECLARE @nd int = (SELECT COUNT(*) FROM #dates);
DECLARE @fail_total int = ISNULL(@fail_a, 0) + ISNULL(@fail_b, 0) + ISNULL(@fail_c, 0) + ISNULL(@fail_d, 0);
DECLARE @ms int = DATEDIFF(ms, @t0, SYSDATETIME());

SET @msg = N'07p | pilots=9 | dates=' + CAST(@nd AS nvarchar)
         + N' | fail a/b/c/d=' + CAST(ISNULL(@fail_a, 0) AS nvarchar) + N'/'
         + CAST(ISNULL(@fail_b, 0) AS nvarchar) + N'/'
         + CAST(ISNULL(@fail_c, 0) AS nvarchar) + N'/'
         + CAST(ISNULL(@fail_d, 0) AS nvarchar)
         + N' | ms=' + CAST(@ms AS nvarchar)
         + CASE WHEN @fail_total = 0 THEN N' | PASS' ELSE N' | *** FAIL ***' END;
RAISERROR(@msg, 0, 1) WITH NOWAIT;

IF @fail_total > 0
    RAISERROR(N'07p plan aggregate check failed.', 16, 1);

RAISERROR(N'=== 07p завершено ===', 0, 1) WITH NOWAIT;
GO
