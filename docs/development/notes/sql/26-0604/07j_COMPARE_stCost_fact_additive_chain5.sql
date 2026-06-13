USE [FishEye];
GO
-- =============================================================================
-- 07j_COMPARE_stCost_fact_additive_chain5.sql
-- Самосверка _2606 по структуре затрат (факт RA):
--   pres@212  ≈  pres@172 + pres@187 + pres@195
--   accp@212  ≈  accp@172 + accp@187 + accp@195
-- Gate regression_182: flat work не должен давать _2606(182) при legacy(182)=0
--
-- Параметры:
--   @ipgCh  — цепь (5)
--   @stIpg  — узел stIpg (61, 46, NULL)
-- =============================================================================
SET NOCOUNT ON;
GO

DECLARE @ipgCh   int   = 5;
DECLARE @stIpg   int   = 61;   -- <<< МЕНЯЙ: 61, 46, NULL
DECLARE @epsilon money = 0.01;

DECLARE @stNet int = (SELECT ipgcStNetIpg FROM ags.ipgCh WHERE ipgcKey = @ipgCh);
DECLARE @ipgRoot int = ISNULL(@stIpg, 1);

DECLARE @msg nvarchar(400);
SET @msg = N'=== 07j stCost FACT additive  chain=' + CAST(@ipgCh AS nvarchar)
         + N'  stIpg=' + ISNULL(CAST(@stIpg AS nvarchar), N'NULL')
         + N'  stNet=' + CAST(@stNet AS nvarchar) + N' ===';
RAISERROR(@msg, 0, 1) WITH NOWAIT;

-- =========================================================================
-- Gate regression_182 (данные factDocCost, быстрый прокси К-11b)
-- =========================================================================
RAISERROR(N'--- [0/2] GATE regression_182 (flat work @182) ---', 0, 1) WITH NOWAIT;

DECLARE @flat_work_182 int;
DECLARE @regression_fn int = NULL;

SELECT @flat_work_182 = COUNT(*)
FROM ags.factDocCost c
INNER JOIN ags.ra_summ rs ON rs.ras_fdKey = c.fdcoFd
WHERE c.fdcoStCost = 182
  AND rs.ras_work IS NOT NULL AND rs.ras_work <> 0
  AND ABS(c.fdcoSumm - rs.ras_work) < @epsilon;

SELECT @flat_work_182 = @flat_work_182 + (
    SELECT COUNT(*)
    FROM ags.factDocCost c
    INNER JOIN ags.ra_change_summ rcs ON rcs.racs_fdKey = c.fdcoFd
    WHERE c.fdcoStCost = 182
      AND rcs.raсs_work IS NOT NULL AND rcs.raсs_work <> 0
      AND ABS(c.fdcoSumm - rcs.raсs_work) < @epsilon
);

SET @msg = N'  flat_work_at_182: ' + CAST(@flat_work_182 AS nvarchar)
         + CASE WHEN @flat_work_182 = 0 THEN N'  PASS' ELSE N'  *** FAIL ***' END;
RAISERROR(@msg, 0, 1) WITH NOWAIT;

-- Выборочная fn-проверка (TOP 100 RA с ras_work>0 на цепи 5)
IF OBJECT_ID('tempdb..#ra_sample') IS NOT NULL DROP TABLE #ra_sample;

SELECT TOP 100 r.ra_key AS carrierKey
INTO #ra_sample
FROM ags.ra_summ rs
INNER JOIN ags.ra r ON r.ra_key = rs.ras_ra
WHERE rs.ras_work IS NOT NULL AND rs.ras_work <> 0
  AND EXISTS (
      SELECT 1
      FROM ags.ipgPn pp
      INNER JOIN ags.ipgChRlV cr ON cr.ipgcrvIpg = pp.ipgpIpg AND cr.ipgcrvChain = @ipgCh
      WHERE pp.ipgpCstAgPn = r.ra_cac
  )
ORDER BY rs.ras_key DESC;

SELECT @regression_fn = COUNT(*)
FROM #ra_sample s
WHERE ISNULL(ags.fnStCostRa_2606(s.carrierKey, 182, 3), 0) > @epsilon
  AND ISNULL(ags.fnStCostRa(s.carrierKey, 182, 3), 0) <= @epsilon;

SET @msg = N'  fn regression_182 sample(100): ' + CAST(ISNULL(@regression_fn, 0) AS nvarchar)
         + CASE WHEN ISNULL(@regression_fn, 0) = 0 THEN N'  PASS' ELSE N'  *** FAIL ***' END;
RAISERROR(@msg, 0, 1) WITH NOWAIT;

-- =========================================================================
-- Фаза 1: mastering agMasteringPres / agMasteringAccp — additive
-- =========================================================================
RAISERROR(N'--- [1/2] fnMasteringCstAgPnSh FACT additive ---', 0, 1) WITH NOWAIT;

IF OBJECT_ID('tempdb..#contracts') IS NOT NULL DROP TABLE #contracts;
IF OBJECT_ID('tempdb..#pres212') IS NOT NULL DROP TABLE #pres212;
IF OBJECT_ID('tempdb..#pres172') IS NOT NULL DROP TABLE #pres172;
IF OBJECT_ID('tempdb..#pres187') IS NOT NULL DROP TABLE #pres187;
IF OBJECT_ID('tempdb..#pres195') IS NOT NULL DROP TABLE #pres195;
IF OBJECT_ID('tempdb..#diff_pres') IS NOT NULL DROP TABLE #diff_pres;
IF OBJECT_ID('tempdb..#diff_accp') IS NOT NULL DROP TABLE #diff_accp;

SELECT DISTINCT pp.ipgpCstAgPn AS cstAgPnKey
INTO #contracts
FROM ags.ipgPn pp
INNER JOIN ags.ipgChRlV cr ON cr.ipgcrvIpg = pp.ipgpIpg AND cr.ipgcrvChain = @ipgCh
WHERE @stIpg IS NULL
   OR EXISTS (
       SELECT 1 FROM ags.ipgStPn sp
       WHERE sp.ipgspSt = @stIpg AND sp.ipgspPn = pp.ipgpKey
   );

DECLARE @nc int;
SELECT @nc = COUNT(*) FROM #contracts;
SET @msg = N'  contracts to test: ' + CAST(@nc AS nvarchar);
RAISERROR(@msg, 0, 1) WITH NOWAIT;

SELECT c.cstAgPnKey, m.dAll, SUM(ISNULL(m.agMasteringPres, 0)) AS val
INTO #pres212
FROM #contracts c
CROSS APPLY ags.fnMasteringCstAgPnSh_2606(@ipgCh, c.cstAgPnKey, 212, @stNet, @ipgRoot) m
GROUP BY c.cstAgPnKey, m.dAll;

SELECT c.cstAgPnKey, m.dAll, SUM(ISNULL(m.agMasteringPres, 0)) AS val
INTO #pres172
FROM #contracts c
CROSS APPLY ags.fnMasteringCstAgPnSh_2606(@ipgCh, c.cstAgPnKey, 172, @stNet, @ipgRoot) m
GROUP BY c.cstAgPnKey, m.dAll;

SELECT c.cstAgPnKey, m.dAll, SUM(ISNULL(m.agMasteringPres, 0)) AS val
INTO #pres187
FROM #contracts c
CROSS APPLY ags.fnMasteringCstAgPnSh_2606(@ipgCh, c.cstAgPnKey, 187, @stNet, @ipgRoot) m
GROUP BY c.cstAgPnKey, m.dAll;

SELECT c.cstAgPnKey, m.dAll, SUM(ISNULL(m.agMasteringPres, 0)) AS val
INTO #pres195
FROM #contracts c
CROSS APPLY ags.fnMasteringCstAgPnSh_2606(@ipgCh, c.cstAgPnKey, 195, @stNet, @ipgRoot) m
GROUP BY c.cstAgPnKey, m.dAll;

SELECT
    COALESCE(a.cstAgPnKey, b.cstAgPnKey, c.cstAgPnKey, d.cstAgPnKey) AS cstAgPnKey,
    COALESCE(a.dAll, b.dAll, c.dAll, d.dAll) AS dAll,
    ISNULL(a.val, 0) AS pres212,
    ISNULL(b.val, 0) AS pres172,
    ISNULL(c.val, 0) AS pres187,
    ISNULL(d.val, 0) AS pres195,
    ISNULL(b.val, 0) + ISNULL(c.val, 0) + ISNULL(d.val, 0) AS pres_sum3,
    ISNULL(a.val, 0) - (ISNULL(b.val, 0) + ISNULL(c.val, 0) + ISNULL(d.val, 0)) AS diff
INTO #diff_pres
FROM #pres212 a
FULL JOIN #pres172 b ON a.cstAgPnKey = b.cstAgPnKey AND (a.dAll = b.dAll OR (a.dAll IS NULL AND b.dAll IS NULL))
FULL JOIN #pres187 c ON COALESCE(a.cstAgPnKey, b.cstAgPnKey) = c.cstAgPnKey
    AND (COALESCE(a.dAll, b.dAll) = c.dAll OR (COALESCE(a.dAll, b.dAll) IS NULL AND c.dAll IS NULL))
FULL JOIN #pres195 d ON COALESCE(a.cstAgPnKey, b.cstAgPnKey, c.cstAgPnKey) = d.cstAgPnKey
    AND (COALESCE(a.dAll, b.dAll, c.dAll) = d.dAll OR (COALESCE(a.dAll, b.dAll, c.dAll) IS NULL AND d.dAll IS NULL))
WHERE ISNULL(a.val, 0) <> 0
   OR ISNULL(b.val, 0) <> 0
   OR ISNULL(c.val, 0) <> 0
   OR ISNULL(d.val, 0) <> 0;

DECLARE @rows_pres int, @fail_pres int, @maxdiff_pres money;
SELECT
    @rows_pres = COUNT(*),
    @fail_pres = ISNULL(SUM(CASE WHEN ABS(diff) > @epsilon THEN 1 ELSE 0 END), 0),
    @maxdiff_pres = ISNULL(MAX(ABS(diff)), 0)
FROM #diff_pres;

SET @msg = N'  pres slices: ' + CAST(@rows_pres AS nvarchar)
         + N'  FAIL_fact_pres: ' + CAST(@fail_pres AS nvarchar)
         + N'  max|diff|: ' + CAST(@maxdiff_pres AS nvarchar(30))
         + CASE WHEN @fail_pres = 0 THEN N'  PASS' ELSE N'  *** FAIL ***' END;
RAISERROR(@msg, 0, 1) WITH NOWAIT;

IF @fail_pres > 0
BEGIN
    RAISERROR(N'  TOP pres failures:', 0, 1) WITH NOWAIT;
    SELECT TOP 20 cstAgPnKey, dAll, pres212, pres172, pres187, pres195, pres_sum3, diff
    FROM #diff_pres
    WHERE ABS(diff) > @epsilon
    ORDER BY ABS(diff) DESC;
END;

-- accp (переиспользуем #contracts)
IF OBJECT_ID('tempdb..#accp212') IS NOT NULL DROP TABLE #accp212;
IF OBJECT_ID('tempdb..#accp172') IS NOT NULL DROP TABLE #accp172;
IF OBJECT_ID('tempdb..#accp187') IS NOT NULL DROP TABLE #accp187;
IF OBJECT_ID('tempdb..#accp195') IS NOT NULL DROP TABLE #accp195;

SELECT c.cstAgPnKey, m.dAll, SUM(ISNULL(m.agMasteringAccp, 0)) AS val
INTO #accp212
FROM #contracts c
CROSS APPLY ags.fnMasteringCstAgPnSh_2606(@ipgCh, c.cstAgPnKey, 212, @stNet, @ipgRoot) m
GROUP BY c.cstAgPnKey, m.dAll;

SELECT c.cstAgPnKey, m.dAll, SUM(ISNULL(m.agMasteringAccp, 0)) AS val
INTO #accp172
FROM #contracts c
CROSS APPLY ags.fnMasteringCstAgPnSh_2606(@ipgCh, c.cstAgPnKey, 172, @stNet, @ipgRoot) m
GROUP BY c.cstAgPnKey, m.dAll;

SELECT c.cstAgPnKey, m.dAll, SUM(ISNULL(m.agMasteringAccp, 0)) AS val
INTO #accp187
FROM #contracts c
CROSS APPLY ags.fnMasteringCstAgPnSh_2606(@ipgCh, c.cstAgPnKey, 187, @stNet, @ipgRoot) m
GROUP BY c.cstAgPnKey, m.dAll;

SELECT c.cstAgPnKey, m.dAll, SUM(ISNULL(m.agMasteringAccp, 0)) AS val
INTO #accp195
FROM #contracts c
CROSS APPLY ags.fnMasteringCstAgPnSh_2606(@ipgCh, c.cstAgPnKey, 195, @stNet, @ipgRoot) m
GROUP BY c.cstAgPnKey, m.dAll;

SELECT
    COALESCE(a.cstAgPnKey, b.cstAgPnKey, c.cstAgPnKey, d.cstAgPnKey) AS cstAgPnKey,
    COALESCE(a.dAll, b.dAll, c.dAll, d.dAll) AS dAll,
    ISNULL(a.val, 0) AS accp212,
    ISNULL(b.val, 0) AS accp172,
    ISNULL(c.val, 0) AS accp187,
    ISNULL(d.val, 0) AS accp195,
    ISNULL(b.val, 0) + ISNULL(c.val, 0) + ISNULL(d.val, 0) AS accp_sum3,
    ISNULL(a.val, 0) - (ISNULL(b.val, 0) + ISNULL(c.val, 0) + ISNULL(d.val, 0)) AS diff
INTO #diff_accp
FROM #accp212 a
FULL JOIN #accp172 b ON a.cstAgPnKey = b.cstAgPnKey AND (a.dAll = b.dAll OR (a.dAll IS NULL AND b.dAll IS NULL))
FULL JOIN #accp187 c ON COALESCE(a.cstAgPnKey, b.cstAgPnKey) = c.cstAgPnKey
    AND (COALESCE(a.dAll, b.dAll) = c.dAll OR (COALESCE(a.dAll, b.dAll) IS NULL AND c.dAll IS NULL))
FULL JOIN #accp195 d ON COALESCE(a.cstAgPnKey, b.cstAgPnKey, c.cstAgPnKey) = d.cstAgPnKey
    AND (COALESCE(a.dAll, b.dAll, c.dAll) = d.dAll OR (COALESCE(a.dAll, b.dAll, c.dAll) IS NULL AND d.dAll IS NULL))
WHERE ISNULL(a.val, 0) <> 0
   OR ISNULL(b.val, 0) <> 0
   OR ISNULL(c.val, 0) <> 0
   OR ISNULL(d.val, 0) <> 0;

DECLARE @rows_accp int, @fail_accp int, @maxdiff_accp money;
SELECT
    @rows_accp = COUNT(*),
    @fail_accp = ISNULL(SUM(CASE WHEN ABS(diff) > @epsilon THEN 1 ELSE 0 END), 0),
    @maxdiff_accp = ISNULL(MAX(ABS(diff)), 0)
FROM #diff_accp;

SET @msg = N'  accp slices: ' + CAST(@rows_accp AS nvarchar)
         + N'  FAIL_fact_accp: ' + CAST(@fail_accp AS nvarchar)
         + N'  max|diff|: ' + CAST(@maxdiff_accp AS nvarchar(30))
         + CASE WHEN @fail_accp = 0 THEN N'  PASS' ELSE N'  *** FAIL ***' END;
RAISERROR(@msg, 0, 1) WITH NOWAIT;

IF @fail_accp > 0
BEGIN
    RAISERROR(N'  TOP accp failures:', 0, 1) WITH NOWAIT;
    SELECT TOP 20 cstAgPnKey, dAll, accp212, accp172, accp187, accp195, accp_sum3, diff
    FROM #diff_accp
    WHERE ABS(diff) > @epsilon
    ORDER BY ABS(diff) DESC;
END;

DECLARE @fail_total int = ISNULL(@fail_pres, 0) + ISNULL(@fail_accp, 0) + @flat_work_182 + ISNULL(@regression_fn, 0);
SET @msg = N'=== 07j итог: FAIL_total=' + CAST(@fail_total AS nvarchar)
         + CASE WHEN @fail_total = 0 THEN N'  PASS (К-11)' ELSE N'  *** FAIL (К-11) ***' END
         + N' ===';
RAISERROR(@msg, 0, 1) WITH NOWAIT;
GO
