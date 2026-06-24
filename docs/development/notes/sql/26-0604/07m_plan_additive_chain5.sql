USE [FishEye];
GO
-- =============================================================================
-- 07m_plan_additive_chain5.sql
-- К-13: plan@212 ≈ plan@172 + plan@187 + plan@195
--        на последнем dAll ≤ @MounthEndDate (COALESCE ag/in/dr SmmTtl), уровень ipgPn.
--
-- Параметры: @ipgCh, @stIpg (NULL = вся цепь), @MounthEndDate
-- PERF: ≤ 480 с @ stIpg=NULL
-- =============================================================================
SET NOCOUNT ON;
GO

DECLARE @ipgCh           int   = 5;
DECLARE @stIpg           int   = NULL;   -- <<< 61, 46, NULL
DECLARE @MounthEndDate   date  = '2022-12-31';
DECLARE @epsilon         money = 5.00;  -- накопление ×1e6 после split по весам ipgPnLim

DECLARE @stNet   int = (SELECT ipgcStNetIpg FROM ags.ipgCh WHERE ipgcKey = @ipgCh);
DECLARE @ipgRoot int = ISNULL(@stIpg, 1);
DECLARE @t0      datetime2 = SYSDATETIME();

DECLARE @msg nvarchar(500);
SET @msg = N'=== 07m К-13 plan additive  chain=' + CAST(@ipgCh AS nvarchar)
         + N'  stIpg=' + ISNULL(CAST(@stIpg AS nvarchar), N'NULL')
         + N'  dt=' + CONVERT(nvarchar(10), @MounthEndDate, 23) + N' ===';
RAISERROR(@msg, 0, 1) WITH NOWAIT;

IF OBJECT_ID('tempdb..#pn_ut') IS NOT NULL DROP TABLE #pn_ut;
IF OBJECT_ID('tempdb..#contracts') IS NOT NULL DROP TABLE #contracts;
IF OBJECT_ID('tempdb..#p212') IS NOT NULL DROP TABLE #p212;
IF OBJECT_ID('tempdb..#p172') IS NOT NULL DROP TABLE #p172;
IF OBJECT_ID('tempdb..#p187') IS NOT NULL DROP TABLE #p187;
IF OBJECT_ID('tempdb..#p195') IS NOT NULL DROP TABLE #p195;
IF OBJECT_ID('tempdb..#diff') IS NOT NULL DROP TABLE #diff;

;WITH ch AS (
    SELECT DISTINCT p.ipgpKey, p.ipgpCstAgPn
    FROM ags.ipgPn p
    INNER JOIN ags.ipgChRlV v ON v.ipgcrvIpg = p.ipgpIpg AND v.ipgcrvChain = @ipgCh
    WHERE @stIpg IS NULL
       OR EXISTS (SELECT 1 FROM ags.ipgStPn sp WHERE sp.ipgspSt = @stIpg AND sp.ipgspPn = p.ipgpKey)
)
SELECT DISTINCT c.ipgpKey, c.ipgpCstAgPn
INTO #pn_ut
FROM ch c
WHERE EXISTS (
    SELECT 1
    FROM ags.ipgUtPlPnLmMn m
    INNER JOIN ags.ipgUtPlP up ON up.iuplpKey = m.iuplpmPlPn
    WHERE up.iuplpIpgPn = c.ipgpKey AND m.iuplpmStCost = 212
);

SELECT DISTINCT c.ipgpCstAgPn AS cstAgPnKey
INTO #contracts
FROM ags.ipgPn c
INNER JOIN ags.ipgChRlV cr ON cr.ipgcrvIpg = c.ipgpIpg AND cr.ipgcrvChain = @ipgCh
WHERE c.ipgpCstAgPn IS NOT NULL
  AND EXISTS (
      SELECT 1
      FROM #pn_ut u
      WHERE u.ipgpCstAgPn = c.ipgpCstAgPn
  )
  AND (@stIpg IS NULL OR EXISTS (
      SELECT 1 FROM ags.ipgStPn sp WHERE sp.ipgspSt = @stIpg AND sp.ipgspPn = c.ipgpKey
  ));

DECLARE @npn int = (SELECT COUNT(*) FROM #pn_ut);
RAISERROR(N'  ipgPn with UtPlMn: %d', 0, 1, @npn) WITH NOWAIT;

;WITH raw AS (
    SELECT u.ipgpKey, m.dAll,
        SUM(COALESCE(m.agSmmTtl, m.inSmmTtl, m.drSmmTtl, 0)) AS plan_val
    FROM #pn_ut u
    INNER JOIN #contracts c ON c.cstAgPnKey = u.ipgpCstAgPn
    CROSS APPLY ags.fnMasteringCstAgPnSh_2606(@ipgCh, u.ipgpCstAgPn, 212, @stNet, @ipgRoot) m
    WHERE m.ipgpKey = u.ipgpKey AND m.dAll <= @MounthEndDate
    GROUP BY u.ipgpKey, m.dAll
),
ranked AS (
    SELECT ipgpKey, plan_val,
        ROW_NUMBER() OVER (PARTITION BY ipgpKey ORDER BY dAll DESC) AS rn
    FROM raw
    WHERE plan_val <> 0
)
SELECT ipgpKey, plan_val AS plan212
INTO #p212
FROM ranked
WHERE rn = 1;

;WITH raw AS (
    SELECT u.ipgpKey, m.dAll,
        SUM(COALESCE(m.agSmmTtl, m.inSmmTtl, m.drSmmTtl, 0)) AS plan_val
    FROM #pn_ut u
    INNER JOIN #contracts c ON c.cstAgPnKey = u.ipgpCstAgPn
    CROSS APPLY ags.fnMasteringCstAgPnSh_2606(@ipgCh, u.ipgpCstAgPn, 172, @stNet, @ipgRoot) m
    WHERE m.ipgpKey = u.ipgpKey AND m.dAll <= @MounthEndDate
    GROUP BY u.ipgpKey, m.dAll
),
ranked AS (
    SELECT ipgpKey, plan_val,
        ROW_NUMBER() OVER (PARTITION BY ipgpKey ORDER BY dAll DESC) AS rn
    FROM raw
    WHERE plan_val <> 0
)
SELECT ipgpKey, plan_val AS plan172
INTO #p172
FROM ranked
WHERE rn = 1;

;WITH raw AS (
    SELECT u.ipgpKey, m.dAll,
        SUM(COALESCE(m.agSmmTtl, m.inSmmTtl, m.drSmmTtl, 0)) AS plan_val
    FROM #pn_ut u
    INNER JOIN #contracts c ON c.cstAgPnKey = u.ipgpCstAgPn
    CROSS APPLY ags.fnMasteringCstAgPnSh_2606(@ipgCh, u.ipgpCstAgPn, 187, @stNet, @ipgRoot) m
    WHERE m.ipgpKey = u.ipgpKey AND m.dAll <= @MounthEndDate
    GROUP BY u.ipgpKey, m.dAll
),
ranked AS (
    SELECT ipgpKey, plan_val,
        ROW_NUMBER() OVER (PARTITION BY ipgpKey ORDER BY dAll DESC) AS rn
    FROM raw
    WHERE plan_val <> 0
)
SELECT ipgpKey, plan_val AS plan187
INTO #p187
FROM ranked
WHERE rn = 1;

;WITH raw AS (
    SELECT u.ipgpKey, m.dAll,
        SUM(COALESCE(m.agSmmTtl, m.inSmmTtl, m.drSmmTtl, 0)) AS plan_val
    FROM #pn_ut u
    INNER JOIN #contracts c ON c.cstAgPnKey = u.ipgpCstAgPn
    CROSS APPLY ags.fnMasteringCstAgPnSh_2606(@ipgCh, u.ipgpCstAgPn, 195, @stNet, @ipgRoot) m
    WHERE m.ipgpKey = u.ipgpKey AND m.dAll <= @MounthEndDate
    GROUP BY u.ipgpKey, m.dAll
),
ranked AS (
    SELECT ipgpKey, plan_val,
        ROW_NUMBER() OVER (PARTITION BY ipgpKey ORDER BY dAll DESC) AS rn
    FROM raw
    WHERE plan_val <> 0
)
SELECT ipgpKey, plan_val AS plan195
INTO #p195
FROM ranked
WHERE rn = 1;

SELECT
    u.ipgpKey,
    u.ipgpCstAgPn,
    ISNULL(a.plan212, 0) AS plan212,
    ISNULL(b.plan172, 0) AS plan172,
    ISNULL(c.plan187, 0) AS plan187,
    ISNULL(d.plan195, 0) AS plan195,
    ISNULL(b.plan172, 0) + ISNULL(c.plan187, 0) + ISNULL(d.plan195, 0) AS plan_sum3,
    ISNULL(a.plan212, 0)
        - (ISNULL(b.plan172, 0) + ISNULL(c.plan187, 0) + ISNULL(d.plan195, 0)) AS diff
INTO #diff
FROM #pn_ut u
LEFT JOIN #p212 a ON a.ipgpKey = u.ipgpKey
LEFT JOIN #p172 b ON b.ipgpKey = u.ipgpKey
LEFT JOIN #p187 c ON c.ipgpKey = u.ipgpKey
LEFT JOIN #p195 d ON d.ipgpKey = u.ipgpKey
WHERE ISNULL(a.plan212, 0) <> 0
   OR ISNULL(b.plan172, 0) <> 0
   OR ISNULL(c.plan187, 0) <> 0
   OR ISNULL(d.plan195, 0) <> 0;

DECLARE @rows int, @fail int, @skip int, @maxdiff money;
SELECT
    @rows = COUNT(*),
    @fail = SUM(CASE WHEN ABS(diff) > @epsilon THEN 1 ELSE 0 END),
    @skip = SUM(CASE WHEN plan212 = 0 AND plan172 = 0 AND plan187 = 0 AND plan195 = 0 THEN 1 ELSE 0 END),
    @maxdiff = MAX(ABS(diff))
FROM #diff;

DECLARE @ms int = DATEDIFF(ms, @t0, SYSDATETIME());
SET @msg = N'К-13 | chain=' + CAST(@ipgCh AS nvarchar)
         + N' | dt=' + CONVERT(nvarchar(10), @MounthEndDate, 23)
         + N' | ipgPn=' + CAST(ISNULL(@rows, 0) AS nvarchar)
         + N' | FAIL_plan_additive=' + CAST(ISNULL(@fail, 0) AS nvarchar)
         + N' | max|diff|=' + CAST(ISNULL(@maxdiff, 0) AS nvarchar(30))
         + N' | ms=' + CAST(@ms AS nvarchar)
         + CASE WHEN ISNULL(@fail, 0) = 0 THEN N' | PASS' ELSE N' | *** FAIL ***' END;
RAISERROR(@msg, 0, 1) WITH NOWAIT;

IF ISNULL(@fail, 0) > 0
BEGIN
    RAISERROR(N'  TOP failures (ipgPn):', 0, 1) WITH NOWAIT;
    SELECT TOP 20
        ipgpKey, ipgpCstAgPn, plan212, plan172, plan187, plan195, plan_sum3, diff
    FROM #diff
    WHERE ABS(diff) > @epsilon
    ORDER BY ABS(diff) DESC;

    RAISERROR(N'К-13 plan additive failed.', 16, 1);
END;

RAISERROR(N'=== 07m К-13 завершено ===', 0, 1) WITH NOWAIT;
GO
