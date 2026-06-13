USE [FishEye];
GO
-- =============================================================================
-- 07h4_fn2_profile_stIpg46.sql
-- Профиль fn2_2606 для stIpg=46: разбивка времени (RRc, StIpgStCost, полный fn2).
-- Точечные стройки: cac=1574 (max Sh), 371 (бывш. slow), 338 (fast).
-- =============================================================================
SET NOCOUNT ON;
GO

DECLARE @ipgCh   int = 5;
DECLARE @stIpg   int = 46;
DECLARE @stCost  int = 212;
DECLARE @stNet   int = (SELECT c.ipgcStNetIpg FROM ags.ipgCh c WHERE c.ipgcKey = @ipgCh);
DECLARE @yKey    int;
DECLARE @t0      datetime2;
DECLARE @ms      int;
DECLARE @n       int;
DECLARE @msg     nvarchar(500);

SELECT @yKey = MIN(y.yKey)
FROM (
    SELECT MAX(y2.yyyy) AS mxY
    FROM ags.ipgChRlV v
    INNER JOIN ags.ipg i ON i.ipgKey = v.ipgcrvIpg
    INNER JOIN ags.yyyy y2 ON y2.yKey = i.ipgYy
    WHERE v.ipgcrvChain = @ipgCh
) x
INNER JOIN ags.yyyy y ON y.yyyy = x.mxY;

SET @msg = N'=== 07h4: fn2 profile stIpg=46 yKey=' + CAST(@yKey AS nvarchar) + N' ===';
RAISERROR(@msg, 0, 1) WITH NOWAIT;

-- -------------------------------------------------------------------------
-- A. Объёмы RRc / mastering по трём стройкам
-- -------------------------------------------------------------------------
RAISERROR(N'--- A. Data volumes (1574 / 371 / 338) ---', 0, 1) WITH NOWAIT;

SELECT v.cac, cap.cstapIpgPnN AS code,
    (SELECT COUNT(*) FROM ags.ra_summ s JOIN ags.ra r ON s.ras_ra = r.ra_key
     JOIN ags.factDocCost fc ON fc.fdcoFd = s.ras_fdKey WHERE r.ra_cac = v.cac) AS factDocCost_ras_cnt,
    (SELECT COUNT(*) FROM ags.RRcTimeList r WHERE r.ra_cac = v.cac) AS RRcTimeList_cnt,
    (SELECT COUNT(*) FROM ags.ra r WHERE r.ra_cac = v.cac) AS ra_cnt,
    (SELECT COUNT(*) FROM ags.ogAgFeeP p INNER JOIN ags.ogAgFee a ON a.oafKey = p.oafpOaf WHERE p.oafpCstAgPn = v.cac) AS ogAgFeeP_cnt
FROM (VALUES (1574),(371),(338)) v(cac)
INNER JOIN ags.cstAgPn cap ON cap.cstapKey = v.cac
ORDER BY v.cac;

-- -------------------------------------------------------------------------
-- B. CstAgPnSh по одной стройке
-- -------------------------------------------------------------------------
RAISERROR(N'--- B. fnMasteringCstAgPnSh_2606 per contract ---', 0, 1) WITH NOWAIT;

DECLARE @cac int;
DECLARE cur CURSOR LOCAL FAST_FORWARD FOR SELECT cac FROM (VALUES (1574),(371),(338)) x(cac);
OPEN cur;
FETCH NEXT FROM cur INTO @cac;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @t0 = SYSDATETIME();
    SELECT @n = COUNT(*) FROM ags.fnMasteringCstAgPnSh_2606(@ipgCh, @cac, @stCost, @stNet, @stIpg);
    SET @ms = DATEDIFF(ms, @t0, SYSDATETIME());
    SET @msg = N'  cac=' + CAST(@cac AS nvarchar) + N' CstAgPnSh rows=' + CAST(@n AS nvarchar) + N' ms=' + CAST(@ms AS nvarchar);
    RAISERROR(@msg, 0, 1) WITH NOWAIT; -- cac timing
    FETCH NEXT FROM cur INTO @cac;
END
CLOSE cur; DEALLOCATE cur;

-- -------------------------------------------------------------------------
-- C. RRcTimeList → raFact2408 (как в fn2, весь год)
-- -------------------------------------------------------------------------
RAISERROR(N'--- C. raFact2408 aggregate (RRcTimeList full year) ---', 0, 1) WITH NOWAIT;

IF OBJECT_ID('tempdb..#raFact') IS NOT NULL DROP TABLE #raFact;
SET @t0 = SYSDATETIME();
SELECT p.y AS yKey, p.m AS mNum, r.ra_cac AS cstAgPnKey, r.typeGr,
    SUM(r.ras_total) AS presentedAll,
    SUM(CASE WHEN r.complianceY = N'соответствует'
            OR (r.complianceY = N'не соответствует' AND r.ras_total > 0) THEN r.ras_total END) AS presented
INTO #raFact
FROM ags.RRcTimeList r
INNER JOIN ags.ra_period p ON r.ra_period = p.[key]
WHERE p.y = @yKey
GROUP BY p.y, r.ra_cac, p.m, r.typeGr;
SELECT @n = COUNT(*) FROM #raFact;
SET @ms = DATEDIFF(ms, @t0, SYSDATETIME());
SET @msg = N'  raFact2408 rows=' + CAST(@n AS nvarchar) + N' ms=' + CAST(@ms AS nvarchar);
RAISERROR(@msg, 0, 1) WITH NOWAIT;

-- C2. RRc только по stIpg=46 (164 контракта)
RAISERROR(N'--- C2. RRcTimeList filtered stIpg=46 contracts ---', 0, 1) WITH NOWAIT;
IF OBJECT_ID('tempdb..#tc') IS NOT NULL DROP TABLE #tc;
SELECT DISTINCT pp.ipgpCstAgPn AS cac INTO #tc
FROM ags.ipgPn pp
JOIN ags.ipg ip ON ip.ipgKey = pp.ipgpIpg
JOIN ags.ipgChRl cr ON cr.ipgcrIpg = ip.ipgKey AND cr.ipgcrChain = @ipgCh
WHERE EXISTS (SELECT 1 FROM ags.ipgStPn sp WHERE sp.ipgspSt = @stIpg AND sp.ipgspPn = pp.ipgpKey);

SET @t0 = SYSDATETIME();
SELECT @n = COUNT(*)
FROM ags.RRcTimeList r
INNER JOIN ags.ra_period p ON r.ra_period = p.[key]
WHERE p.y = @yKey AND r.ra_cac IN (SELECT cac FROM #tc);
SET @ms = DATEDIFF(ms, @t0, SYSDATETIME());
SET @msg = N'  RRc rows (46 contracts) cnt=' + CAST(@n AS nvarchar) + N' ms=' + CAST(@ms AS nvarchar);
RAISERROR(@msg, 0, 1) WITH NOWAIT;

-- C3. RRc cac=1574 only
SET @t0 = SYSDATETIME();
SELECT @n = COUNT(*) FROM ags.RRcTimeList r INNER JOIN ags.ra_period p ON r.ra_period = p.[key]
WHERE p.y = @yKey AND r.ra_cac = 1574;
SET @ms = DATEDIFF(ms, @t0, SYSDATETIME());
SET @msg = N'  RRc cac=1574 cnt=' + CAST(@n AS nvarchar) + N' ms=' + CAST(@ms AS nvarchar);
RAISERROR(@msg, 0, 1) WITH NOWAIT;

-- -------------------------------------------------------------------------
-- D. fnMasteringStIpgStCost_2606 (164× CstAgPnSh внутри)
-- -------------------------------------------------------------------------
RAISERROR(N'--- D. fnMasteringStIpgStCost_2606 stIpg=46 ---', 0, 1) WITH NOWAIT;
SET @t0 = SYSDATETIME();
SELECT @n = COUNT(*) FROM ags.fnMasteringStIpgStCost_2606(@stIpg, @ipgCh, @stCost, NULL);
SET @ms = DATEDIFF(ms, @t0, SYSDATETIME());
SET @msg = N'  StIpgStCost rows=' + CAST(@n AS nvarchar) + N' ms=' + CAST(@ms AS nvarchar);
RAISERROR(@msg, 0, 1) WITH NOWAIT;

-- -------------------------------------------------------------------------
-- E. fn2_2606 stIpg=46 (полный)
-- -------------------------------------------------------------------------
RAISERROR(N'--- E. fn2_2606 stIpg=46 full ---', 0, 1) WITH NOWAIT;
SET @t0 = SYSDATETIME();
SELECT @n = COUNT(*) FROM ags.fnIpgChRsltCstUtl2_2606(@ipgCh, @stIpg, NULL) f WHERE f.ipgKey IS NOT NULL;
SET @ms = DATEDIFF(ms, @t0, SYSDATETIME());
SET @msg = N'  fn2 rows=' + CAST(@n AS nvarchar) + N' ms=' + CAST(@ms AS nvarchar);
RAISERROR(@msg, 0, 1) WITH NOWAIT;

-- -------------------------------------------------------------------------
-- F. P5 status
-- -------------------------------------------------------------------------
RAISERROR(N'--- F. P5 / indexes ---', 0, 1) WITH NOWAIT;
SELECT
    CASE WHEN OBJECT_ID('ags.RRcTimeListBase', 'U') IS NOT NULL THEN 1 ELSE 0 END AS P5_RRcMat,
    CASE WHEN EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_ipgStPn_St_Pn') THEN 1 ELSE 0 END AS P4_idx_ipgStPn;

RAISERROR(N'=== 07h4 DONE ===', 0, 1) WITH NOWAIT;
GO
