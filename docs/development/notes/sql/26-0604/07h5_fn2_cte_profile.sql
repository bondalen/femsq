USE [FishEye];
GO
-- =============================================================================
-- 07h5_fn2_cte_profile.sql
-- Поэтапный профиль CTE fn2_2606 для stIpg=46 (после mastering / schemeRows).
-- Цель: локализовать ~79 с накладных fn2 (withAccum, ipgChContracts, extraBase…).
-- =============================================================================
SET NOCOUNT ON;
GO

DECLARE @ipgChKey  int = 5;
DECLARE @ipgStKey  int = 46;
DECLARE @stCostKey int = 212;
DECLARE @yKey      int;
DECLARE @yyyy      int;
DECLARE @t0        datetime2;
DECLARE @ms        int;
DECLARE @n         int;
DECLARE @msg       nvarchar(400);

SELECT @yKey = MIN(y.yKey), @yyyy = MIN(y.yyyy)
FROM (
    SELECT MAX(y2.yyyy) AS mxY
    FROM ags.ipgChRl_2606 v
    INNER JOIN ags.ipg i ON i.ipgKey = v.ipgcrvIpg
    INNER JOIN ags.yyyy y2 ON y2.yKey = i.ipgYy
    WHERE v.ipgcrvChain = @ipgChKey
) x
INNER JOIN ags.yyyy y ON y.yyyy = x.mxY;

SET @msg = N'=== 07h5: fn2 CTE profile stIpg=' + CAST(@ipgStKey AS nvarchar) + N' yKey=' + CAST(@yKey AS nvarchar) + N' ===';
RAISERROR(@msg, 0, 1) WITH NOWAIT;

-- stIpg contracts
IF OBJECT_ID('tempdb..#stTc') IS NOT NULL DROP TABLE #stTc;
SELECT DISTINCT pp.ipgpCstAgPn AS cac INTO #stTc
FROM ags.ipgPn pp
JOIN ags.ipg ip ON ip.ipgKey = pp.ipgpIpg
JOIN ags.ipgChRl cr ON cr.ipgcrIpg = ip.ipgKey AND cr.ipgcrChain = @ipgChKey
WHERE EXISTS (SELECT 1 FROM ags.ipgStPn sp WHERE sp.ipgspSt = @ipgStKey AND sp.ipgspPn = pp.ipgpKey);

-- -------------------------------------------------------------------------
-- 0. Fact tables (как fn2)
-- -------------------------------------------------------------------------
RAISERROR(N'--- 0. @raFact* tables ---', 0, 1) WITH NOWAIT;
IF OBJECT_ID('tempdb..#raFact2408') IS NOT NULL DROP TABLE #raFact2408;
IF OBJECT_ID('tempdb..#raFactRalp') IS NOT NULL DROP TABLE #raFactRalp;
IF OBJECT_ID('tempdb..#raFactMnrl') IS NOT NULL DROP TABLE #raFactMnrl;
IF OBJECT_ID('tempdb..#raFactStorage') IS NOT NULL DROP TABLE #raFactStorage;

SET @t0 = SYSDATETIME();
SELECT p.y AS yKey, p.m AS mNum, r.ra_cac AS cstAgPnKey, r.typeGr,
    SUM(r.ras_total) AS presentedAll, SUM(ABS(r.ras_total)) AS presentedAllModul,
    SUM(CASE WHEN r.complianceY = N'соответствует' OR (r.complianceY = N'не соответствует' AND r.ras_total > 0) THEN r.ras_total END) AS presented,
    SUM(CASE WHEN r.rsltOfConsider = N'sended' AND (r.complianceY = N'соответствует' OR (r.complianceY = N'не соответствует' AND r.ras_total > 0)) THEN r.ras_total END) AS accepted,
    SUM(CASE WHEN r.rsltOfConsider = N'returned' AND (r.complianceY = N'соответствует' OR (r.complianceY = N'не соответствует' AND r.ras_total > 0)) THEN r.ras_total END) AS returned,
    SUM(CASE WHEN r.rsltOfConsider = N'in process' AND (r.complianceY = N'соответствует' OR (r.complianceY = N'не соответствует' AND r.ras_total > 0)) THEN r.ras_total END) AS inProcess,
    SUM(CASE WHEN r.rsltOfConsider = N'not arrived' AND (r.complianceY = N'соответствует' OR (r.complianceY = N'не соответствует' AND r.ras_total > 0)) THEN r.ras_total END) AS notArrived,
    SUM(CASE WHEN NOT (r.complianceY = N'соответствует' OR (r.complianceY = N'не соответствует' AND r.ras_total > 0)) THEN r.ras_total END) AS presentedPrevYears,
    SUM(CASE WHEN r.rsltOfConsider = N'sended' AND NOT (r.complianceY = N'соответствует' OR (r.complianceY = N'не соответствует' AND r.ras_total > 0)) THEN r.ras_total END) AS acceptedPrevYears,
    SUM(CASE WHEN r.rsltOfConsider = N'returned' AND NOT (r.complianceY = N'соответствует' OR (r.complianceY = N'не соответствует' AND r.ras_total > 0)) THEN r.ras_total END) AS returnedPrevYears,
    SUM(CASE WHEN r.rsltOfConsider = N'in process' AND NOT (r.complianceY = N'соответствует' OR (r.complianceY = N'не соответствует' AND r.ras_total > 0)) THEN r.ras_total END) AS inProcessPrevYears,
    SUM(CASE WHEN r.rsltOfConsider = N'not arrived' AND NOT (r.complianceY = N'соответствует' OR (r.complianceY = N'не соответствует' AND r.ras_total > 0)) THEN r.ras_total END) AS notArrivedPrevYears
INTO #raFact2408
FROM ags.RRcTimeList r
INNER JOIN ags.ra_period p ON r.ra_period = p.[key]
WHERE p.y = @yKey
GROUP BY p.y, r.ra_cac, p.m, r.typeGr;

SELECT y.yKey, mm.mNum, p.ralpCstAgPn AS cstAgPnKey, N'1. ОА и Изм.' AS typeGr,
    SUM(p.ralpCostAndVat) AS presentedRalp,
    SUM(CASE WHEN IIF(p.ralpReturned IS NULL, IIF(p.ralpSent IS NULL, IIF(p.ralpArrived IS NULL, N'not arrived', N'in process'), N'sended'), IIF(p.ralpSentDate >= p.ralpReturnedDate, N'sended', N'returned')) = N'sended' THEN p.ralpCostAndVat END) AS acceptedRalp,
    SUM(CASE WHEN IIF(p.ralpReturned IS NULL, IIF(p.ralpSent IS NULL, IIF(p.ralpArrived IS NULL, N'not arrived', N'in process'), N'sended'), IIF(p.ralpSentDate >= p.ralpReturnedDate, N'sended', N'returned')) = N'returned' THEN p.ralpCostAndVat END) AS returnedRalp,
    SUM(CASE WHEN IIF(p.ralpReturned IS NULL, IIF(p.ralpSent IS NULL, IIF(p.ralpArrived IS NULL, N'not arrived', N'in process'), N'sended'), IIF(p.ralpSentDate >= p.ralpReturnedDate, N'sended', N'returned')) = N'in process' THEN p.ralpCostAndVat END) AS inProcessRalp,
    SUM(CASE WHEN IIF(p.ralpReturned IS NULL, IIF(p.ralpSent IS NULL, IIF(p.ralpArrived IS NULL, N'not arrived', N'in process'), N'sended'), IIF(p.ralpSentDate >= p.ralpReturnedDate, N'sended', N'returned')) = N'not arrived' THEN p.ralpCostAndVat END) AS notArrivedRalp
INTO #raFactRalp
FROM ags.ralp p INNER JOIN ags.yyyy y ON p.ralpY = y.yyyy INNER JOIN ags.mmmm mm ON p.ralpM = mm.mNum
WHERE y.yKey = @yKey GROUP BY y.yKey, mm.mNum, p.ralpCstAgPn;

SELECT ym.yKey, mmr.mNum, mr.amCstAgPn AS cstAgPnKey, SUM(mr.amSum) AS MnrlSum
INTO #raFactMnrl
FROM ags.cstAgPnMnrl mr INNER JOIN ags.yyyy ym ON YEAR(mr.amPositing) = ym.yyyy INNER JOIN ags.mmmm mmr ON MONTH(mr.amPositing) = mmr.mNum
WHERE ym.yKey = @yKey GROUP BY ym.yKey, mmr.mNum, mr.amCstAgPn;

SELECT mh.mNum, p.pdpCstAgPn AS cstAgPnKey, SUM(p.costVAT) AS storageSum
INTO #raFactStorage
FROM ags.cn_PrDocP p INNER JOIN ags.cn_PrDoc d ON p.pdpPrDoc = d.cnpdKey
INNER JOIN ags.yyyy yh ON YEAR(p.positingDate) = yh.yyyy INNER JOIN ags.mmmm mh ON MONTH(p.positingDate) = mh.mNum
WHERE yh.yKey = @yKey AND d.cnpdTpOrd IN (1,2,4) AND p.satstusOfOUKVtext = N'проведено'
GROUP BY mh.mNum, p.pdpCstAgPn;

SET @ms = DATEDIFF(ms, @t0, SYSDATETIME());
SET @msg = N'  raFact* ms=' + CAST(@ms AS nvarchar);
RAISERROR(@msg, 0, 1) WITH NOWAIT;

IF OBJECT_ID('tempdb..#branchCache') IS NOT NULL DROP TABLE #branchCache;
SELECT b.cstapbCstAgPn, MAX(b.cstapbBranch) AS branch
INTO #branchCache
FROM ags.cstAgPnBranch b
WHERE (b.cstapbEnd IS NULL OR b.cstapbEnd >= CAST(GETDATE() AS date))
  AND (b.cstapbStart IS NULL OR b.cstapbStart <= CAST(GETDATE() AS date))
GROUP BY b.cstapbCstAgPn;

-- -------------------------------------------------------------------------
-- 1. schemeRows (mastering) — основной вклад ~36 с
-- -------------------------------------------------------------------------
RAISERROR(N'--- 1. #schemeRows (mastering) ---', 0, 1) WITH NOWAIT;
IF OBJECT_ID('tempdb..#mastMonthEnd') IS NOT NULL DROP TABLE #mastMonthEnd;
SELECT v.ipgcrvIpg AS ipgKey, MAX(d.dAll) AS dAll
INTO #mastMonthEnd
FROM ags.fnIpgChDats_2606(@ipgChKey) d
INNER JOIN ags.ipgChRl_2606 v ON v.ipgcrvChain = @ipgChKey AND d.dAll >= v.ipgcrvStr AND (v.ipgcrvEnd IS NULL OR d.dAll <= v.ipgcrvEnd)
GROUP BY v.ipgcrvIpg, YEAR(d.dAll), MONTH(d.dAll);

IF OBJECT_ID('tempdb..#schemeRows') IS NOT NULL DROP TABLE #schemeRows;
SET @t0 = SYSDATETIME();
;WITH mastering AS (
    SELECT m.*, me.ipgKey, MONTH(me.dAll) AS mNum, v.ipgcrvStr AS ipgActStr, v.ipgcrvEnd AS ipgActEnd
    FROM ags.fnMasteringStIpgStCost_2606(@ipgStKey, @ipgChKey, @stCostKey, NULL) m
    INNER JOIN #mastMonthEnd me ON me.dAll = m.dAll
    INNER JOIN ags.ipgChRl_2606 v ON v.ipgcrvChain = @ipgChKey AND v.ipgcrvIpg = me.ipgKey
)
SELECT ipgpCstAgPn, dAll, mNum, ipgKey, ipgActStr, ipgActEnd, 2 AS iShKey, N'Агентская' AS iShNm, N'1. ОА и Изм.' AS typeGr,
    agLim AS lim, agMstrngPrsRaMn AS presented, agMstrngAcpRaMn AS accepted,
    agMstrngPrsAgFeeMn AS agFeePresented, agMstrngAcpAgFeeMn AS agFeeAccepted,
    agMstrngPrsRalpMn AS presentedRalp, agMstrngAcpRalpMn AS acceptedRalp,
    agMstrngAcpStorMn AS storageSum, agMstrngAcpControlMn AS cctSum, agMstrngAcpMnrlMn AS MnrlSum
INTO #schemeRows
FROM mastering
WHERE NOT (agLim IS NULL AND agMstrngPrsRaMn IS NULL AND agMstrngAcpRaMn IS NULL AND agMstrngPrsAgFeeMn IS NULL AND agMstrngAcpAgFeeMn IS NULL AND agMstrngPrsRalpMn IS NULL AND agMstrngAcpRalpMn IS NULL AND agMstrngAcpStorMn IS NULL AND agMstrngAcpControlMn IS NULL AND agMstrngAcpMnrlMn IS NULL)
UNION ALL
SELECT ipgpCstAgPn, dAll, mNum, ipgKey, ipgActStr, ipgActEnd, 1, N'Инвестиционная', N'1. ОА и Изм.', inLim, inMstrngPrsRaMn, inMstrngAcpRaMn, inMstrngPrsAgFeeMn, inMstrngAcpAgFeeMn, inMstrngPrsRalpMn, inMstrngAcpRalpMn, inMstrngAcpStorMn, inMstrngAcpControlMn, inMstrngAcpMnrlMn
FROM mastering WHERE NOT (inLim IS NULL AND inMstrngPrsRaMn IS NULL AND inMstrngAcpRaMn IS NULL AND inMstrngPrsAgFeeMn IS NULL AND inMstrngAcpAgFeeMn IS NULL AND inMstrngPrsRalpMn IS NULL AND inMstrngAcpRalpMn IS NULL AND inMstrngAcpStorMn IS NULL AND inMstrngAcpControlMn IS NULL AND inMstrngAcpMnrlMn IS NULL)
UNION ALL
SELECT ipgpCstAgPn, dAll, mNum, ipgKey, ipgActStr, ipgActEnd, 3, N'Иная схема', N'1. ОА и Изм.', drLim, drMstrngPrsRaMn, drMstrngAcpRaMn, drMstrngPrsAgFeeMn, drMstrngAcpAgFeeMn, drMstrngPrsRalpMn, drMstrngAcpRalpMn, drMstrngAcpStorMn, drMstrngAcpControlMn, drMstrngAcpMnrlMn
FROM mastering WHERE NOT (drLim IS NULL AND drMstrngPrsRaMn IS NULL AND drMstrngAcpRaMn IS NULL AND drMstrngPrsAgFeeMn IS NULL AND drMstrngAcpAgFeeMn IS NULL AND drMstrngPrsRalpMn IS NULL AND drMstrngAcpRalpMn IS NULL AND drMstrngAcpStorMn IS NULL AND drMstrngAcpControlMn IS NULL AND drMstrngAcpMnrlMn IS NULL);

SELECT @n = COUNT(*) FROM #schemeRows;
SET @ms = DATEDIFF(ms, @t0, SYSDATETIME());
SET @msg = N'  schemeRows rows=' + CAST(@n AS nvarchar) + N' ms=' + CAST(@ms AS nvarchar);
RAISERROR(@msg, 0, 1) WITH NOWAIT;

-- -------------------------------------------------------------------------
-- 2. ipgSchemeCombo + allMonthsForIpg
-- -------------------------------------------------------------------------
RAISERROR(N'--- 2. allMonthsForIpg ---', 0, 1) WITH NOWAIT;
IF OBJECT_ID('tempdb..#allMonths') IS NOT NULL DROP TABLE #allMonths;
SET @t0 = SYSDATETIME();
;WITH ipgPnSchemePts AS (
    SELECT p.ipgpIpg AS ipgKey, p.ipgpCstAgPn, p.ipgpSh AS iShKey
    FROM ags.ipgPn p INNER JOIN ags.ipgChRl_2606 v ON v.ipgcrvChain = @ipgChKey AND v.ipgcrvIpg = p.ipgpIpg
    UNION SELECT p.ipgpIpg, p.ipgpCstAgPn, 2 FROM ags.ipgPn p INNER JOIN ags.ipgChRl_2606 v ON v.ipgcrvChain = @ipgChKey AND v.ipgcrvIpg = p.ipgpIpg WHERE p.ipgpSh = 1
),
ipgMasteringCombos AS (SELECT DISTINCT sr.ipgKey, sr.ipgActStr, sr.ipgActEnd, sr.ipgpCstAgPn, sr.typeGr FROM #schemeRows sr),
ipgSchemeCombo AS (
    SELECT DISTINCT mc.ipgKey, mc.ipgActStr, mc.ipgActEnd, mc.ipgpCstAgPn, pt.iShKey,
        CASE pt.iShKey WHEN 2 THEN N'Агентская' WHEN 1 THEN N'Инвестиционная' WHEN 3 THEN N'Иная схема' END AS iShNm,
        mc.typeGr, CAST(1 AS bit) AS shShow
    FROM ipgMasteringCombos mc INNER JOIN ipgPnSchemePts pt ON pt.ipgKey = mc.ipgKey AND pt.ipgpCstAgPn = mc.ipgpCstAgPn
),
ipgSchemeLim AS (SELECT ipgKey, ipgpCstAgPn, iShKey, MAX(lim) AS lim FROM #schemeRows GROUP BY ipgKey, ipgpCstAgPn, iShKey)
SELECT mm.mKey, mm.mNum, mm.mCs, mm.mNm, mm.mQ, mm.mHy, c.ipgKey, c.ipgActStr, c.ipgActEnd,
    c.ipgpCstAgPn, c.iShKey, c.iShNm, c.typeGr, c.shShow, il.lim,
    sr.presented AS mstrPresented, sr.accepted AS mstrAccepted, sr.agFeePresented, sr.agFeeAccepted,
    sr.presentedRalp, sr.acceptedRalp, sr.storageSum, sr.cctSum, sr.MnrlSum
INTO #allMonths
FROM ipgSchemeCombo c
CROSS JOIN ags.mmmm mm
LEFT JOIN ipgSchemeLim il ON il.ipgKey = c.ipgKey AND il.ipgpCstAgPn = c.ipgpCstAgPn AND il.iShKey = c.iShKey
LEFT JOIN #schemeRows sr ON sr.ipgKey = c.ipgKey AND sr.ipgpCstAgPn = c.ipgpCstAgPn AND sr.iShKey = c.iShKey AND sr.mNum = mm.mNum;

SELECT @n = COUNT(*) FROM #allMonths;
SET @ms = DATEDIFF(ms, @t0, SYSDATETIME());
SET @msg = N'  allMonths rows=' + CAST(@n AS nvarchar) + N' ms=' + CAST(@ms AS nvarchar);
RAISERROR(@msg, 0, 1) WITH NOWAIT;

-- -------------------------------------------------------------------------
-- 3. ipgChContracts (full chain vs stIpg filter)
-- -------------------------------------------------------------------------
RAISERROR(N'--- 3. ipgChContracts ---', 0, 1) WITH NOWAIT;
IF OBJECT_ID('tempdb..#ipgChContracts') IS NOT NULL DROP TABLE #ipgChContracts;
SET @t0 = SYSDATETIME();
SELECT DISTINCT src.cstAgPnKey, mm.mKey, tg.typeGr
INTO #ipgChContracts
FROM (
    SELECT p.oafpCstAgPn AS cstAgPnKey FROM ags.ogAgFee a
        INNER JOIN (SELECT @yKey AS yKey, @yyyy AS yyyy) ly ON a.oafY = ly.yKey
        INNER JOIN ags.ogAgFeeP p ON a.oafKey = p.oafpOaf WHERE p.oafpCstAgPn IS NOT NULL
    UNION SELECT DISTINCT cstAgPnKey FROM #raFact2408
    UNION SELECT DISTINCT cstAgPnKey FROM #raFactRalp
    UNION SELECT p.pdpCstAgPn FROM ags.cn_PrDocP p INNER JOIN ags.cn_PrDoc d ON p.pdpPrDoc = d.cnpdKey
        INNER JOIN ags.cn_PrDocT t ON d.cnpdTpOrd = t.pdtoKey INNER JOIN ags.yyyy yy ON YEAR(p.positingDate) = yy.yyyy
        INNER JOIN (SELECT @yKey AS yKey) ly ON yy.yKey = ly.yKey
        WHERE t.pdtoCode IN (N'ZKTG',N'ZPTG',N'ZUGH',N'ZKTA') AND p.pdpCstAgPn IS NOT NULL
    UNION SELECT ip.ipgpCstAgPn FROM ags.ipgPn ip INNER JOIN ags.ipgChRl_2606 v ON v.ipgcrvChain = @ipgChKey AND v.ipgcrvIpg = ip.ipgpIpg WHERE ip.ipgpCstAgPn IS NOT NULL
    UNION SELECT DISTINCT cstAgPnKey FROM #raFactMnrl
) src CROSS JOIN ags.mmmm mm CROSS JOIN ags.ra_typeGr tg;

SELECT @n = COUNT(*) FROM #ipgChContracts;
SET @ms = DATEDIFF(ms, @t0, SYSDATETIME());
SET @msg = N'  ipgChContracts FULL rows=' + CAST(@n AS nvarchar) + N' ms=' + CAST(@ms AS nvarchar);
RAISERROR(@msg, 0, 1) WITH NOWAIT;

SELECT @n = COUNT(*) FROM #ipgChContracts c WHERE c.cstAgPnKey IN (SELECT cac FROM #stTc);
SET @msg = N'  ipgChContracts stIpg=46 subset rows=' + CAST(@n AS nvarchar);
RAISERROR(@msg, 0, 1) WITH NOWAIT;

-- -------------------------------------------------------------------------
-- 4. ipgBase
-- -------------------------------------------------------------------------
RAISERROR(N'--- 4. #ipgBase ---', 0, 1) WITH NOWAIT;
IF OBJECT_ID('tempdb..#ipgBase') IS NOT NULL DROP TABLE #ipgBase;
SET @t0 = SYSDATETIME();
SELECT ly.yKey, ly.yyyy, u.mKey, u.mNum, u.mCs, u.mNm, u.mQ, u.mHy,
    u.ipgKey, ipg.ipgNm, u.ipgActStr AS ipgStr, u.ipgActEnd AS ipgEnd,
    ca.cstaInvestor, oa.ogaKey, o.ogNm, bc.branch, u.typeGr, u.lim, u.iShKey, u.iShNm,
    CAST(NULL AS nvarchar(255)) AS limPlan, cap.cstapIpgPnN AS cstAgPnCode, u.ipgpCstAgPn AS cstAgPnKey,
    IIF(u.iShKey = 2 AND u.shShow = 1, rf.presentedAll, NULL) AS presentedAll,
    IIF(u.iShKey = 2 AND u.shShow = 1, rf.presented, u.mstrPresented) AS presented,
    IIF(u.iShKey = 2 AND u.shShow = 1, rf.accepted, u.mstrAccepted) AS accepted,
    u.agFeePresented, u.agFeeAccepted, u.presentedRalp, u.acceptedRalp, u.storageSum, u.cctSum, u.MnrlSum
INTO #ipgBase
FROM #allMonths u
CROSS JOIN (SELECT @yKey AS yKey, @yyyy AS yyyy) ly
INNER JOIN ags.ipg ipg ON ipg.ipgKey = u.ipgKey
INNER JOIN ags.cstAgPn cap ON cap.cstapKey = u.ipgpCstAgPn
LEFT JOIN #branchCache bc ON bc.cstapbCstAgPn = cap.cstapKey
INNER JOIN ags.cstAg ca ON ca.cstaKey = cap.cstapCsta
INNER JOIN ags.ogAg oa ON oa.ogaKey = ca.cstaAg
INNER JOIN ags.og o ON o.ogKey = oa.ogaOg
LEFT JOIN #raFact2408 rf ON u.iShKey = 2 AND rf.cstAgPnKey = u.ipgpCstAgPn AND rf.mNum = u.mNum AND rf.typeGr = u.typeGr
LEFT JOIN #raFactRalp rr ON rr.cstAgPnKey = u.ipgpCstAgPn AND rr.yKey = ly.yKey AND rr.mNum = u.mNum AND rr.typeGr = u.typeGr
LEFT JOIN #raFactMnrl rm ON rm.cstAgPnKey = u.ipgpCstAgPn AND rm.yKey = ly.yKey AND rm.mNum = u.mNum;

SELECT @n = COUNT(*) FROM #ipgBase;
SET @ms = DATEDIFF(ms, @t0, SYSDATETIME());
SET @msg = N'  ipgBase rows=' + CAST(@n AS nvarchar) + N' ms=' + CAST(@ms AS nvarchar);
RAISERROR(@msg, 0, 1) WITH NOWAIT;

-- -------------------------------------------------------------------------
-- 5. extraBase + masExtraBase + nullIpgBase (по отдельности)
-- -------------------------------------------------------------------------
RAISERROR(N'--- 5a. #nullIpgBase ---', 0, 1) WITH NOWAIT;
SET @t0 = SYSDATETIME();
IF OBJECT_ID('tempdb..#nullIpgBase') IS NOT NULL DROP TABLE #nullIpgBase;
SELECT cs.cstAgPnKey, mm.mNum INTO #nullIpgBase
FROM #ipgChContracts cs
INNER JOIN ags.mmmm mm ON mm.mKey = cs.mKey
WHERE cs.typeGr = N'2. ОА, прочие и Изм';
SELECT @n = @@ROWCOUNT;
SET @ms = DATEDIFF(ms, @t0, SYSDATETIME());
SET @msg = N'  nullIpgBase (lite) rows=' + CAST(@n AS nvarchar) + N' ms=' + CAST(@ms AS nvarchar);
RAISERROR(@msg, 0, 1) WITH NOWAIT;

RAISERROR(N'--- 5b. #extraBase NOT EXISTS schemeRows ---', 0, 1) WITH NOWAIT;
SET @t0 = SYSDATETIME();
SELECT @n = COUNT(*)
FROM #ipgChContracts cs
INNER JOIN ags.mmmm mm ON mm.mKey = cs.mKey
INNER JOIN ags.cstAgPn cap ON cap.cstapKey = cs.cstAgPnKey
INNER JOIN ags.cstAg ca ON ca.cstaKey = cap.cstapCsta
INNER JOIN ags.ipg ip ON ip.ipgYy = @yKey AND ip.ipgOg = ca.cstaInvestor
INNER JOIN ags.ipgChRl cr ON cr.ipgcrIpg = ip.ipgKey AND cr.ipgcrChain = @ipgChKey
WHERE cs.typeGr = N'1. ОА и Изм.'
  AND NOT EXISTS (SELECT 1 FROM #schemeRows sr WHERE sr.ipgpCstAgPn = cs.cstAgPnKey);
SET @ms = DATEDIFF(ms, @t0, SYSDATETIME());
SET @msg = N'  extraBase candidate rows=' + CAST(@n AS nvarchar) + N' ms=' + CAST(@ms AS nvarchar);
RAISERROR(@msg, 0, 1) WITH NOWAIT;

RAISERROR(N'--- 5c. #masExtraBase EXISTS+NOT EXISTS ---', 0, 1) WITH NOWAIT;
SET @t0 = SYSDATETIME();
SELECT @n = COUNT(*)
FROM #ipgChContracts cs
INNER JOIN ags.mmmm mm ON mm.mKey = cs.mKey
INNER JOIN ags.cstAgPn cap ON cap.cstapKey = cs.cstAgPnKey
INNER JOIN ags.cstAg ca ON ca.cstaKey = cap.cstapCsta
INNER JOIN ags.ipg ip ON ip.ipgYy = @yKey AND ip.ipgOg = ca.cstaInvestor
INNER JOIN ags.ipgChRl cr ON cr.ipgcrIpg = ip.ipgKey AND cr.ipgcrChain = @ipgChKey
WHERE cs.typeGr = N'1. ОА и Изм.'
  AND EXISTS (SELECT 1 FROM #schemeRows sr WHERE sr.ipgpCstAgPn = cs.cstAgPnKey)
  AND NOT EXISTS (SELECT 1 FROM #schemeRows sr2 WHERE sr2.ipgpCstAgPn = cs.cstAgPnKey AND sr2.ipgKey = ip.ipgKey);
SET @ms = DATEDIFF(ms, @t0, SYSDATETIME());
SET @msg = N'  masExtraBase candidate rows=' + CAST(@n AS nvarchar) + N' ms=' + CAST(@ms AS nvarchar);
RAISERROR(@msg, 0, 1) WITH NOWAIT;

-- -------------------------------------------------------------------------
-- 6. withAccum (24 window SUM) на #ipgBase
-- -------------------------------------------------------------------------
RAISERROR(N'--- 6. withAccum on #ipgBase ---', 0, 1) WITH NOWAIT;
SET @t0 = SYSDATETIME();
IF OBJECT_ID('tempdb..#withAccum') IS NOT NULL DROP TABLE #withAccum;
SELECT b.*,
    SUM(b.presented) OVER (PARTITION BY b.yKey, b.cstAgPnKey, b.typeGr, b.ipgKey, b.iShKey ORDER BY b.mKey ROWS UNBOUNDED PRECEDING) AS presentedAccum,
    SUM(b.accepted) OVER (PARTITION BY b.yKey, b.cstAgPnKey, b.typeGr, b.ipgKey, b.iShKey ORDER BY b.mKey ROWS UNBOUNDED PRECEDING) AS acceptedAccum,
    SUM(b.agFeePresented) OVER (PARTITION BY b.yKey, b.cstAgPnKey, b.typeGr, b.ipgKey, b.iShKey ORDER BY b.mKey ROWS UNBOUNDED PRECEDING) AS agFeePresentedAccum,
    SUM(b.presentedRalp) OVER (PARTITION BY b.yKey, b.cstAgPnKey, b.typeGr, b.ipgKey, b.iShKey ORDER BY b.mKey ROWS UNBOUNDED PRECEDING) AS presentedRalpAccum
INTO #withAccum
FROM #ipgBase b;
SELECT @n = COUNT(*) FROM #withAccum;
SET @ms = DATEDIFF(ms, @t0, SYSDATETIME());
SET @msg = N'  withAccum (4 windows) rows=' + CAST(@n AS nvarchar) + N' ms=' + CAST(@ms AS nvarchar);
RAISERROR(@msg, 0, 1) WITH NOWAIT;

-- full 24 windows
RAISERROR(N'--- 6b. withAccum FULL 24 windows ---', 0, 1) WITH NOWAIT;
SET @t0 = SYSDATETIME();
IF OBJECT_ID('tempdb..#withAccumFull') IS NOT NULL DROP TABLE #withAccumFull;
SELECT b.*,
    SUM(b.presentedAll) OVER (PARTITION BY b.yKey,b.cstAgPnKey,b.typeGr,b.ipgKey,b.iShKey ORDER BY b.mKey ROWS UNBOUNDED PRECEDING) AS presentedAllAccum,
    SUM(b.presented) OVER (PARTITION BY b.yKey,b.cstAgPnKey,b.typeGr,b.ipgKey,b.iShKey ORDER BY b.mKey ROWS UNBOUNDED PRECEDING) AS presentedAccum,
    SUM(b.accepted) OVER (PARTITION BY b.yKey,b.cstAgPnKey,b.typeGr,b.ipgKey,b.iShKey ORDER BY b.mKey ROWS UNBOUNDED PRECEDING) AS acceptedAccum,
    SUM(b.agFeePresented) OVER (PARTITION BY b.yKey,b.cstAgPnKey,b.typeGr,b.ipgKey,b.iShKey ORDER BY b.mKey ROWS UNBOUNDED PRECEDING) AS agFeePresentedAccum,
    SUM(b.agFeeAccepted) OVER (PARTITION BY b.yKey,b.cstAgPnKey,b.typeGr,b.ipgKey,b.iShKey ORDER BY b.mKey ROWS UNBOUNDED PRECEDING) AS agFeeAcceptedAccum,
    SUM(b.presentedRalp) OVER (PARTITION BY b.yKey,b.cstAgPnKey,b.typeGr,b.ipgKey,b.iShKey ORDER BY b.mKey ROWS UNBOUNDED PRECEDING) AS presentedRalpAccum,
    SUM(b.acceptedRalp) OVER (PARTITION BY b.yKey,b.cstAgPnKey,b.typeGr,b.ipgKey,b.iShKey ORDER BY b.mKey ROWS UNBOUNDED PRECEDING) AS acceptedRalpAccum,
    SUM(b.storageSum) OVER (PARTITION BY b.yKey,b.cstAgPnKey,b.typeGr,b.ipgKey,b.iShKey ORDER BY b.mKey ROWS UNBOUNDED PRECEDING) AS storageSumAccum,
    SUM(b.cctSum) OVER (PARTITION BY b.yKey,b.cstAgPnKey,b.typeGr,b.ipgKey,b.iShKey ORDER BY b.mKey ROWS UNBOUNDED PRECEDING) AS cctSumAccum,
    SUM(b.MnrlSum) OVER (PARTITION BY b.yKey,b.cstAgPnKey,b.typeGr,b.ipgKey,b.iShKey ORDER BY b.mKey ROWS UNBOUNDED PRECEDING) AS MnrlSumAccum
INTO #withAccumFull
FROM #ipgBase b;
SET @ms = DATEDIFF(ms, @t0, SYSDATETIME());
SET @msg = N'  withAccum FULL (10 windows) ms=' + CAST(@ms AS nvarchar);
RAISERROR(@msg, 0, 1) WITH NOWAIT;

RAISERROR(N'=== 07h5 DONE (сравните с fn2 115s: schemeRows + остальное) ===', 0, 1) WITH NOWAIT;
GO
