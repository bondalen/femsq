USE [FishEye];
GO
-- =============================================================================
-- 07h6_fn2_profile_stIpgNULL.sql
-- Профиль fn2_2606 для полной цепи (stIpg=NULL) — К-7 / G4.
-- Разбивка: @raFact*, mastering, CTE-объёмы, полный fn2.
-- Паритет 07h4 (stIpg=46) + 07h5 (CTE), но @ipgStKey=NULL.
-- =============================================================================
SET NOCOUNT ON;
GO

DECLARE @ipgChKey  int = 5;
DECLARE @ipgStKey  int = NULL;
DECLARE @stCostKey int = 212;
DECLARE @yKey      int;
DECLARE @yyyy      int;
DECLARE @t0        datetime2;
DECLARE @ms        int;
DECLARE @n         int;
DECLARE @msg       nvarchar(500);

SELECT @yKey = MIN(y.yKey), @yyyy = MIN(y.yyyy)
FROM (
    SELECT MAX(y2.yyyy) AS mxY
    FROM ags.ipgChRlV v
    INNER JOIN ags.ipg i ON i.ipgKey = v.ipgcrvIpg
    INNER JOIN ags.yyyy y2 ON y2.yKey = i.ipgYy
    WHERE v.ipgcrvChain = @ipgChKey
) x
INNER JOIN ags.yyyy y ON y.yyyy = x.mxY;

SET @msg = N'=== 07h6: fn2 profile stIpg=NULL yKey=' + CAST(@yKey AS nvarchar) + N' ===';
RAISERROR(@msg, 0, 1) WITH NOWAIT;

-- Контракты цепи
DECLARE @ntc int;
SELECT @ntc = COUNT(DISTINCT pp.ipgpCstAgPn)
FROM ags.ipgPn pp
JOIN ags.ipg ip ON ip.ipgKey = pp.ipgpIpg
JOIN ags.ipgChRl cr ON cr.ipgcrIpg = ip.ipgKey AND cr.ipgcrChain = @ipgChKey;
SET @msg = N'  chain contracts (ipgPn): ' + CAST(@ntc AS nvarchar);
RAISERROR(@msg, 0, 1) WITH NOWAIT;

-- -------------------------------------------------------------------------
-- A. @raFact* tables (как fn2)
-- -------------------------------------------------------------------------
RAISERROR(N'--- A. @raFact* build ---', 0, 1) WITH NOWAIT;
IF OBJECT_ID('tempdb..#raFact2408') IS NOT NULL DROP TABLE #raFact2408;
IF OBJECT_ID('tempdb..#raFactStorage') IS NOT NULL DROP TABLE #raFactStorage;
IF OBJECT_ID('tempdb..#raFactCct') IS NOT NULL DROP TABLE #raFactCct;

SET @t0 = SYSDATETIME();
SELECT p.y AS yKey, p.m AS mNum, r.ra_cac AS cstAgPnKey, r.typeGr,
    SUM(r.ras_total) AS presentedAll
INTO #raFact2408
FROM ags.RRcTimeList r
INNER JOIN ags.ra_period p ON r.ra_period = p.[key]
WHERE p.y = @yKey
GROUP BY p.y, r.ra_cac, p.m, r.typeGr;

SELECT mh.mNum, p.pdpCstAgPn AS cstAgPnKey, SUM(p.costVAT) AS storageSum
INTO #raFactStorage
FROM ags.cn_PrDocP p
INNER JOIN ags.cn_PrDoc d ON p.pdpPrDoc = d.cnpdKey
INNER JOIN ags.yyyy yh ON YEAR(p.positingDate) = yh.yyyy
INNER JOIN ags.mmmm mh ON MONTH(p.positingDate) = mh.mNum
WHERE yh.yKey = @yKey AND d.cnpdTpOrd IN (1,2,4) AND p.satstusOfOUKVtext = N'проведено'
GROUP BY mh.mNum, p.pdpCstAgPn;

SELECT mh.mNum, p.pdpCstAgPn AS cstAgPnKey, SUM(p.costVAT) AS cctSum
INTO #raFactCct
FROM ags.cn_PrDocP p
INNER JOIN ags.cn_PrDoc d ON p.pdpPrDoc = d.cnpdKey
INNER JOIN ags.cn_PrDocT t ON d.cnpdTpOrd = t.pdtoKey
INNER JOIN ags.yyyy yh ON YEAR(p.positingDate) = yh.yyyy
INNER JOIN ags.mmmm mh ON MONTH(p.positingDate) = mh.mNum
WHERE yh.yKey = @yKey AND t.pdtoCode = N'ZUGH' AND p.satstusOfOUKVtext = N'проведено'
GROUP BY mh.mNum, p.pdpCstAgPn;

SET @ms = DATEDIFF(ms, @t0, SYSDATETIME());
SET @msg = N'  raFact2408=' + CAST((SELECT COUNT(*) FROM #raFact2408) AS nvarchar)
         + N' storage=' + CAST((SELECT COUNT(*) FROM #raFactStorage) AS nvarchar)
         + N' cct=' + CAST((SELECT COUNT(*) FROM #raFactCct) AS nvarchar)
         + N' ms=' + CAST(@ms AS nvarchar);
RAISERROR(@msg, 0, 1) WITH NOWAIT;

-- -------------------------------------------------------------------------
-- B. fnMasteringStIpgStCost_2606 NULL (680 строек)
-- -------------------------------------------------------------------------
RAISERROR(N'--- B. fnMasteringStIpgStCost_2606 stIpg=NULL ---', 0, 1) WITH NOWAIT;
SET @t0 = SYSDATETIME();
SELECT @n = COUNT(*) FROM ags.fnMasteringStIpgStCost_2606(@ipgStKey, @ipgChKey, @stCostKey, NULL);
SET @ms = DATEDIFF(ms, @t0, SYSDATETIME());
SET @msg = N'  StIpgStCost rows=' + CAST(@n AS nvarchar) + N' ms=' + CAST(@ms AS nvarchar);
RAISERROR(@msg, 0, 1) WITH NOWAIT;

-- -------------------------------------------------------------------------
-- C. CTE volumes (schemeRows + ipgChContracts lite)
-- -------------------------------------------------------------------------
RAISERROR(N'--- C. CTE volumes ---', 0, 1) WITH NOWAIT;

IF OBJECT_ID('tempdb..#mastMonthEnd') IS NOT NULL DROP TABLE #mastMonthEnd;
SELECT v.ipgcrvIpg AS ipgKey, MAX(d.dAll) AS dAll
INTO #mastMonthEnd
FROM ags.fnIpgChDatsV(@ipgChKey) d
INNER JOIN ags.ipgChRlV v ON v.ipgcrvChain = @ipgChKey
    AND d.dAll >= v.ipgcrvStr AND (v.ipgcrvEnd IS NULL OR d.dAll <= v.ipgcrvEnd)
GROUP BY v.ipgcrvIpg, YEAR(d.dAll), MONTH(d.dAll);

IF OBJECT_ID('tempdb..#schemeRows') IS NOT NULL DROP TABLE #schemeRows;
SET @t0 = SYSDATETIME();
;WITH mastering AS (
    SELECT m.*, me.ipgKey, MONTH(me.dAll) AS mNum, v.ipgcrvStr AS ipgActStr, v.ipgcrvEnd AS ipgActEnd
    FROM ags.fnMasteringStIpgStCost_2606(@ipgStKey, @ipgChKey, @stCostKey, NULL) m
    INNER JOIN #mastMonthEnd me ON me.dAll = m.dAll
    INNER JOIN ags.ipgChRlV v ON v.ipgcrvChain = @ipgChKey AND v.ipgcrvIpg = me.ipgKey
)
SELECT mst.ipgpCstAgPn, mst.mNum, mst.ipgKey, mst.ipgActStr, mst.ipgActEnd,
    sch.iShKey, N'1. ОА и Изм.' AS typeGr,
    sch.lim, sch.presented, sch.accepted
INTO #schemeRows
FROM mastering mst
CROSS APPLY (VALUES
    (2, mst.agLim, mst.agMstrngPrsRaMn, mst.agMstrngAcpRaMn),
    (1, mst.inLim, mst.inMstrngPrsRaMn, mst.inMstrngAcpRaMn),
    (3, mst.drLim, mst.drMstrngPrsRaMn, mst.drMstrngAcpRaMn)
) AS sch(iShKey, lim, presented, accepted)
WHERE NOT (sch.lim IS NULL AND sch.presented IS NULL AND sch.accepted IS NULL);

SELECT @n = COUNT(*) FROM #schemeRows;
SET @ms = DATEDIFF(ms, @t0, SYSDATETIME());
SET @msg = N'  schemeRows rows=' + CAST(@n AS nvarchar) + N' ms=' + CAST(@ms AS nvarchar);
RAISERROR(@msg, 0, 1) WITH NOWAIT;

-- ipgChContracts row count
SET @t0 = SYSDATETIME();
SELECT @n = COUNT(*)
FROM (
    SELECT DISTINCT src.cstAgPnKey, mm.mKey, tg.typeGr
    FROM (
        SELECT p.oafpCstAgPn AS cstAgPnKey FROM ags.ogAgFee a
            INNER JOIN (SELECT @yKey AS yKey) ly ON a.oafY = ly.yKey
            INNER JOIN ags.ogAgFeeP p ON a.oafKey = p.oafpOaf WHERE p.oafpCstAgPn IS NOT NULL
        UNION SELECT DISTINCT cstAgPnKey FROM #raFact2408
        UNION SELECT DISTINCT cstAgPnKey FROM #raFactStorage
        UNION SELECT DISTINCT cstAgPnKey FROM #raFactCct
        UNION SELECT ip.ipgpCstAgPn FROM ags.ipgPn ip
            INNER JOIN ags.ipgChRlV v ON v.ipgcrvChain = @ipgChKey AND v.ipgcrvIpg = ip.ipgpIpg
            WHERE ip.ipgpCstAgPn IS NOT NULL
    ) src
    CROSS JOIN ags.mmmm mm
    CROSS JOIN ags.ra_typeGr tg
) x;
SET @ms = DATEDIFF(ms, @t0, SYSDATETIME());
SET @msg = N'  ipgChContracts rows=' + CAST(@n AS nvarchar) + N' ms=' + CAST(@ms AS nvarchar);
RAISERROR(@msg, 0, 1) WITH NOWAIT;

-- allMonthsForIpg volume estimate
;WITH ipgPnSchemePts AS (
    SELECT p.ipgpIpg AS ipgKey, p.ipgpCstAgPn, p.ipgpSh AS iShKey
    FROM ags.ipgPn p INNER JOIN ags.ipgChRlV v ON v.ipgcrvChain = @ipgChKey AND v.ipgcrvIpg = p.ipgpIpg
    UNION SELECT p.ipgpIpg, p.ipgpCstAgPn, 2 FROM ags.ipgPn p
        INNER JOIN ags.ipgChRlV v ON v.ipgcrvChain = @ipgChKey AND v.ipgcrvIpg = p.ipgpIpg WHERE p.ipgpSh = 1
),
ipgMasteringCombos AS (
    SELECT DISTINCT v.ipgcrvIpg AS ipgKey, v.ipgcrvStr AS ipgActStr, v.ipgcrvEnd AS ipgActEnd,
        p.ipgpCstAgPn, N'1. ОА и Изм.' AS typeGr
    FROM ags.ipgPn p
    INNER JOIN ags.ipgChRlV v ON v.ipgcrvChain = @ipgChKey AND v.ipgcrvIpg = p.ipgpIpg
    WHERE EXISTS (SELECT 1 FROM #schemeRows sr WHERE sr.ipgpCstAgPn = p.ipgpCstAgPn)
),
ipgSchemeCombo AS (
    SELECT DISTINCT mc.ipgKey, mc.ipgActStr, mc.ipgActEnd, mc.ipgpCstAgPn, pt.iShKey, mc.typeGr
    FROM ipgMasteringCombos mc
    INNER JOIN ipgPnSchemePts pt ON pt.ipgKey = mc.ipgKey AND pt.ipgpCstAgPn = mc.ipgpCstAgPn
)
SELECT @n = COUNT(*) FROM ipgSchemeCombo c CROSS JOIN ags.mmmm mm;
SET @msg = N'  allMonthsForIpg (12×combo) rows=' + CAST(@n AS nvarchar);
RAISERROR(@msg, 0, 1) WITH NOWAIT;

-- -------------------------------------------------------------------------
-- D. fn2_2606 stIpg=NULL (полный) — К-7
-- -------------------------------------------------------------------------
RAISERROR(N'--- D. fn2_2606 stIpg=NULL full (К-7) ---', 0, 1) WITH NOWAIT;
SET @t0 = SYSDATETIME();
SELECT @n = COUNT(*) FROM ags.fnIpgChRsltCstUtl2_2606(@ipgChKey, @ipgStKey, NULL) f WHERE f.ipgKey IS NOT NULL;
SET @ms = DATEDIFF(ms, @t0, SYSDATETIME());
SET @msg = N'  fn2 rows=' + CAST(@n AS nvarchar) + N' ms=' + CAST(@ms AS nvarchar)
         + CASE WHEN @ms < 120000 THEN N'  К-7 PASS' ELSE N'  К-7 FAIL (цель <120000 ms)' END;
RAISERROR(@msg, 0, 1) WITH NOWAIT;

RAISERROR(N'=== 07h6 DONE ===', 0, 1) WITH NOWAIT;
GO
