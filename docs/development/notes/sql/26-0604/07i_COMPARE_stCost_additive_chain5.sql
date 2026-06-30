USE [FishEye];
GO
-- =============================================================================
-- 07i_COMPARE_stCost_additive_chain5.sql
-- Самосверка _2606 по структуре затрат (лимиты):
--   lim@212  ≈  lim@172 + lim@187 + lim@195
--   (@stCostKey NULL ≡ 212)
--
-- Фаза 0: аудит ipgPnLim / ipgUtPlPnLmMn (данные)
-- Фаза 1: fnMasteringCstAgPnSh_2606 — agLim по контрактам stIpg
--
-- Параметры:
--   @ipgCh  — цепь (5)
--   @stIpg  — узел stIpg (61 = 1 контракт; NULL = вся цепь, долго)
-- =============================================================================
SET NOCOUNT ON;
GO

DECLARE @ipgCh   int   = 5;
DECLARE @stIpg   int   = 61;   -- <<< МЕНЯЙ: 61, 46, NULL
DECLARE @epsilon money = 0.01;

DECLARE @stNet int = (SELECT ipgcStNetIpg FROM ags.ipgCh WHERE ipgcKey = @ipgCh);
DECLARE @ipgRoot int = ISNULL(@stIpg, 1);

DECLARE @msg nvarchar(400);
SET @msg = N'=== 07i stCost additive  chain=' + CAST(@ipgCh AS nvarchar)
         + N'  stIpg=' + ISNULL(CAST(@stIpg AS nvarchar), N'NULL')
         + N'  stNet=' + CAST(@stNet AS nvarchar) + N' ===';
RAISERROR(@msg, 0, 1) WITH NOWAIT;

-- =========================================================================
-- Фаза 0: аудит данных ipgPnLim (цепь 5)
-- =========================================================================
RAISERROR(N'--- [0/2] DATA AUDIT ipgPnLim / ipgUtPlPnLmMn ---', 0, 1) WITH NOWAIT;

;WITH pn AS (
    SELECT DISTINCT p.ipgpKey
    FROM ags.ipgChRl_2606 v
    INNER JOIN ags.ipgPn p ON v.ipgcrvIpg = p.ipgpIpg
    WHERE v.ipgcrvChain = @ipgCh
),
pvt AS (
    SELECT
        l.ipgplPn,
        MAX(CASE WHEN l.ipgplStCost = 212 THEN l.ipgplLim END) AS lim212,
        ISNULL(MAX(CASE WHEN l.ipgplStCost = 172 THEN l.ipgplLim END), 0)
            + ISNULL(MAX(CASE WHEN l.ipgplStCost = 187 THEN l.ipgplLim END), 0)
            + ISNULL(MAX(CASE WHEN l.ipgplStCost = 195 THEN l.ipgplLim END), 0) AS lim3
    FROM ags.ipgPnLim l
    INNER JOIN pn ON pn.ipgpKey = l.ipgplPn
    WHERE l.ipgplStCost IN (212, 172, 187, 195)
    GROUP BY l.ipgplPn
)
SELECT
    COUNT(*) AS ipgPn_with_lim212,
    SUM(CASE WHEN lim212 IS NOT NULL AND ABS(lim212 - lim3) <= @epsilon THEN 1 ELSE 0 END) AS data_match_172_187_195,
    SUM(CASE WHEN lim212 IS NOT NULL AND ABS(lim212 - lim3) > @epsilon THEN 1 ELSE 0 END) AS data_mismatch
FROM pvt;

SELECT
    (SELECT COUNT(*) FROM ags.ipgPnLim WHERE ipgplStCost = 182) AS ipgPnLim_rows_stCost182,
    (SELECT COUNT(*) FROM ags.ipgPnLim WHERE ipgplStCost = 195) AS ipgPnLim_rows_stCost195;

;WITH pn AS (
    SELECT DISTINCT p.ipgpKey
    FROM ags.ipgChRl_2606 v
    INNER JOIN ags.ipgPn p ON v.ipgcrvIpg = p.ipgpIpg
    WHERE v.ipgcrvChain = @ipgCh
)
SELECT
    m.iuplpmStCost,
    COUNT(*) AS utpl_mn_rows
FROM ags.ipgUtPlPnLmMn m
INNER JOIN ags.ipgUtPlP up ON up.iuplpKey = m.iuplpmPlPn
INNER JOIN pn ON pn.ipgpKey = up.iuplpIpgPn
GROUP BY m.iuplpmStCost
ORDER BY m.iuplpmStCost;

-- =========================================================================
-- Фаза 1: mastering agLim — additive по контрактам stIpg
-- =========================================================================
RAISERROR(N'--- [1/2] fnMasteringCstAgPnSh agLim additive ---', 0, 1) WITH NOWAIT;

IF OBJECT_ID('tempdb..#contracts') IS NOT NULL DROP TABLE #contracts;
IF OBJECT_ID('tempdb..#lim212') IS NOT NULL DROP TABLE #lim212;
IF OBJECT_ID('tempdb..#lim172') IS NOT NULL DROP TABLE #lim172;
IF OBJECT_ID('tempdb..#lim187') IS NOT NULL DROP TABLE #lim187;
IF OBJECT_ID('tempdb..#lim195') IS NOT NULL DROP TABLE #lim195;
IF OBJECT_ID('tempdb..#diff') IS NOT NULL DROP TABLE #diff;

SELECT DISTINCT pp.ipgpCstAgPn AS cstAgPnKey
INTO #contracts
FROM ags.ipgPn pp
INNER JOIN ags.ipgChRl_2606 cr ON cr.ipgcrvIpg = pp.ipgpIpg AND cr.ipgcrvChain = @ipgCh
WHERE @stIpg IS NULL
   OR EXISTS (
       SELECT 1 FROM ags.ipgStPn sp
       WHERE sp.ipgspSt = @stIpg AND sp.ipgspPn = pp.ipgpKey
   );

DECLARE @nc int;
SELECT @nc = COUNT(*) FROM #contracts;
SET @msg = N'  contracts to test: ' + CAST(@nc AS nvarchar);
RAISERROR(@msg, 0, 1) WITH NOWAIT;

-- Агрегат agLim по (cstAgPn, dAll) для каждого stCostKey
SELECT
    c.cstAgPnKey,
    m.dAll,
    SUM(ISNULL(m.agLim, 0)) AS agLim
INTO #lim212
FROM #contracts c
CROSS APPLY ags.fnMasteringCstAgPnSh_2606(@ipgCh, c.cstAgPnKey, 212, @stNet, @ipgRoot) m
GROUP BY c.cstAgPnKey, m.dAll;

SELECT
    c.cstAgPnKey,
    m.dAll,
    SUM(ISNULL(m.agLim, 0)) AS agLim
INTO #lim172
FROM #contracts c
CROSS APPLY ags.fnMasteringCstAgPnSh_2606(@ipgCh, c.cstAgPnKey, 172, @stNet, @ipgRoot) m
GROUP BY c.cstAgPnKey, m.dAll;

SELECT
    c.cstAgPnKey,
    m.dAll,
    SUM(ISNULL(m.agLim, 0)) AS agLim
INTO #lim187
FROM #contracts c
CROSS APPLY ags.fnMasteringCstAgPnSh_2606(@ipgCh, c.cstAgPnKey, 187, @stNet, @ipgRoot) m
GROUP BY c.cstAgPnKey, m.dAll;

SELECT
    c.cstAgPnKey,
    m.dAll,
    SUM(ISNULL(m.agLim, 0)) AS agLim
INTO #lim195
FROM #contracts c
CROSS APPLY ags.fnMasteringCstAgPnSh_2606(@ipgCh, c.cstAgPnKey, 195, @stNet, @ipgRoot) m
GROUP BY c.cstAgPnKey, m.dAll;

SELECT
    COALESCE(a.cstAgPnKey, b.cstAgPnKey, c.cstAgPnKey, d.cstAgPnKey) AS cstAgPnKey,
    COALESCE(a.dAll, b.dAll, c.dAll, d.dAll) AS dAll,
    ISNULL(a.agLim, 0) AS lim212,
    ISNULL(b.agLim, 0) AS lim172,
    ISNULL(c.agLim, 0) AS lim187,
    ISNULL(d.agLim, 0) AS lim195,
    ISNULL(b.agLim, 0) + ISNULL(c.agLim, 0) + ISNULL(d.agLim, 0) AS lim_sum3,
    ISNULL(a.agLim, 0) - (ISNULL(b.agLim, 0) + ISNULL(c.agLim, 0) + ISNULL(d.agLim, 0)) AS diff
INTO #diff
FROM #lim212 a
FULL JOIN #lim172 b ON a.cstAgPnKey = b.cstAgPnKey AND (a.dAll = b.dAll OR (a.dAll IS NULL AND b.dAll IS NULL))
FULL JOIN #lim187 c ON COALESCE(a.cstAgPnKey, b.cstAgPnKey) = c.cstAgPnKey
    AND (COALESCE(a.dAll, b.dAll) = c.dAll OR (COALESCE(a.dAll, b.dAll) IS NULL AND c.dAll IS NULL))
FULL JOIN #lim195 d ON COALESCE(a.cstAgPnKey, b.cstAgPnKey, c.cstAgPnKey) = d.cstAgPnKey
    AND (COALESCE(a.dAll, b.dAll, c.dAll) = d.dAll OR (COALESCE(a.dAll, b.dAll, c.dAll) IS NULL AND d.dAll IS NULL))
WHERE ISNULL(a.agLim, 0) <> 0
   OR ISNULL(b.agLim, 0) <> 0
   OR ISNULL(c.agLim, 0) <> 0
   OR ISNULL(d.agLim, 0) <> 0;

DECLARE @rows int, @fail int, @maxdiff money;
SELECT
    @rows = COUNT(*),
    @fail = SUM(CASE WHEN ABS(diff) > @epsilon THEN 1 ELSE 0 END),
    @maxdiff = MAX(ABS(diff))
FROM #diff;

SET @msg = N'  slices (cstAgPn,dAll) with lim<>0: ' + CAST(@rows AS nvarchar)
         + N'  FAIL_lim: ' + CAST(@fail AS nvarchar)
         + N'  max|diff|: ' + CAST(ISNULL(@maxdiff, 0) AS nvarchar(30))
         + CASE WHEN @fail = 0 THEN N'  PASS' ELSE N'  *** FAIL ***' END;
RAISERROR(@msg, 0, 1) WITH NOWAIT;

IF @fail > 0
BEGIN
    RAISERROR(N'  TOP failures:', 0, 1) WITH NOWAIT;
    SELECT TOP 20
        cstAgPnKey, dAll, lim212, lim172, lim187, lim195, lim_sum3, diff
    FROM #diff
    WHERE ABS(diff) > @epsilon
    ORDER BY ABS(diff) DESC;
END;

RAISERROR(N'=== 07i завершено ===', 0, 1) WITH NOWAIT;
GO
