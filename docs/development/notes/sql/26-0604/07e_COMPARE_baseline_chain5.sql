USE [FishEye];
GO

-- =============================================================================
-- Файл:    07e_COMPARE_baseline_chain5.sql
-- Пакет:   docs/development/notes/sql/26-0604/
-- Назначение: Сравнение baseline _2606 ↔ _2605 на цепи 5 (NULL, NULL).
--   Уровень A — fn2: presented по (mNum, cstAgPnKey, iShKey); lim per ipgKey.
--   Уровень B — PercentBrn: переходные dateRslt (21/22/30.09.2022), модель _2605.
--   Уровень C — вспомогательный: COUNT PercentBrn при dateRslt = @MounthEndDate
--     (производные RS4–RS7; главный эталон — полный RS1, см. docs/06-sp-recordsets-and-acceptance.md).
-- Предусловия: 04, fnIpgChRsltCstUtlPercentBrn_2605.
-- Автор:   Александр
-- Дата:    2026-06-09
-- =============================================================================

SET NOCOUNT ON;
GO

PRINT N'=== 07e: COMPARE baseline chain 5 (5, NULL, NULL) vs _2605(5, NULL) ===';
PRINT N'@MounthEndDate эталон: 2022-09-30';
PRINT N'';

DECLARE @fail int = 0;
DECLARE @ipgCh int = 5;
DECLARE @monthEnd date = '2022-09-30';

-- =============================================================================
-- Уровень A — fn2 (месячная матрица)
-- Правило: presented/accepted — MAX по ipgKey в _2605 (репликация месячного факта).
--          lim — per (mNum, cstAgPnKey, ipgKey, iShKey).
-- =============================================================================
PRINT N'--- Level A: fn2 baseline (months 3, 9; typeGr 1. ОА и Изм., iShKey=2) ---';
PRINT N'  materialize fn2_2605...';

IF OBJECT_ID('tempdb..#ref05') IS NOT NULL DROP TABLE #ref05;
IF OBJECT_ID('tempdb..#new06') IS NOT NULL DROP TABLE #new06;

SELECT
    f.mNum,
    f.cstAgPnKey,
    f.iShKey,
    f.ipgKey,
    ISNULL(f.presented, 0) AS presented,
    ISNULL(f.accepted, 0) AS accepted,
    ISNULL(f.lim, 0) AS lim
INTO #ref05
FROM ags.fnIpgChRsltCstUtl2_2605(@ipgCh, NULL) f
WHERE f.typeGr = N'1. ОА и Изм.'
  AND f.iShKey = 2
  AND f.mNum IN (3, 9)
  AND f.ipgKey IS NOT NULL;

PRINT N'  #ref05 rows: ' + CAST(@@ROWCOUNT AS nvarchar(10));
PRINT N'  materialize fn2_2606...';

SELECT
    n.mNum,
    n.cstAgPnKey,
    n.iShKey,
    n.ipgKey,
    ISNULL(n.presented, 0) AS presented,
    ISNULL(n.accepted, 0) AS accepted,
    ISNULL(n.lim, 0) AS lim
INTO #new06
FROM ags.fnIpgChRsltCstUtl2_2606(@ipgCh, NULL, NULL) n
WHERE n.typeGr = N'1. ОА и Изм.'
  AND n.iShKey = 2
  AND n.mNum IN (3, 9)
  AND n.ipgKey IS NOT NULL;

PRINT N'  #new06 rows: ' + CAST(@@ROWCOUNT AS nvarchar(10));

DECLARE @presDiffCnt int = (
    SELECT COUNT(*)
    FROM (
        SELECT mNum, cstAgPnKey, iShKey, MAX(presented) AS presented_ref
        FROM #ref05
        GROUP BY mNum, cstAgPnKey, iShKey
    ) r
    LEFT JOIN (
        SELECT mNum, cstAgPnKey, iShKey, MAX(presented) AS presented
        FROM #new06
        GROUP BY mNum, cstAgPnKey, iShKey
    ) ns
        ON r.mNum = ns.mNum AND r.cstAgPnKey = ns.cstAgPnKey AND r.iShKey = ns.iShKey
    WHERE ABS(r.presented_ref - ISNULL(ns.presented, 0)) > 0.01
);

DECLARE @limDiffCnt int = (
    SELECT COUNT(*)
    FROM #ref05 r
    INNER JOIN #new06 ns
        ON r.mNum = ns.mNum AND r.cstAgPnKey = ns.cstAgPnKey
       AND r.iShKey = ns.iShKey AND r.ipgKey = ns.ipgKey
    WHERE ABS(r.lim - ISNULL(ns.lim, 0)) > 0.01
);

PRINT N'A.1 presented mismatches (m3,m9): ' + CAST(@presDiffCnt AS nvarchar(10));
IF @presDiffCnt > 0
BEGIN
    SET @fail = @fail + 1;
    PRINT N'  TOP 5 presented diffs:';
    SELECT TOP 5 *
    FROM (
        SELECT r.mNum, r.cstAgPnKey, r.presented_ref, ISNULL(ns.presented, 0) AS presented_2606,
            ABS(r.presented_ref - ISNULL(ns.presented, 0)) AS d
        FROM (
            SELECT mNum, cstAgPnKey, iShKey, MAX(presented) AS presented_ref
            FROM #ref05 GROUP BY mNum, cstAgPnKey, iShKey
        ) r
        LEFT JOIN (
            SELECT mNum, cstAgPnKey, iShKey, MAX(presented) AS presented
            FROM #new06 GROUP BY mNum, cstAgPnKey, iShKey
        ) ns ON r.mNum = ns.mNum AND r.cstAgPnKey = ns.cstAgPnKey AND r.iShKey = ns.iShKey
        WHERE ABS(r.presented_ref - ISNULL(ns.presented, 0)) > 0.01
    ) x ORDER BY d DESC;
END
ELSE
    PRINT N'  OK';

PRINT N'A.2 lim mismatches per ipgKey (m3,m9): ' + CAST(@limDiffCnt AS nvarchar(10));
IF @limDiffCnt > 0
BEGIN
    SET @fail = @fail + 1;
    PRINT N'  TOP 5 lim diffs:';
    SELECT TOP 5 r.mNum, r.cstAgPnKey, r.ipgKey, r.lim AS lim_ref, ns.lim AS lim_2606,
        ABS(r.lim - ISNULL(ns.lim, 0)) AS d
    FROM #ref05 r
    INNER JOIN #new06 ns
        ON r.mNum = ns.mNum AND r.cstAgPnKey = ns.cstAgPnKey
       AND r.iShKey = ns.iShKey AND r.ipgKey = ns.ipgKey
    WHERE ABS(r.lim - ISNULL(ns.lim, 0)) > 0.01
    ORDER BY d DESC;
END
ELSE
    PRINT N'  OK';

-- Spot: cstAgPnKey=453 m3
DECLARE @p453_2605 money = (
    SELECT MAX(ISNULL(presented, 0))
    FROM ags.fnIpgChRsltCstUtl2_2605(@ipgCh, NULL)
    WHERE cstAgPnKey = 453 AND mNum = 3 AND iShKey = 2
);
DECLARE @p453_2606 money = (
    SELECT ISNULL(presented, 0)
    FROM ags.fnIpgChRsltCstUtl2_2606(@ipgCh, NULL, NULL)
    WHERE cstAgPnKey = 453 AND mNum = 3 AND iShKey = 2 AND ipgKey IS NOT NULL
);

PRINT N'A.3 spot cstAgPnKey=453 mNum=3 presented: _2605=' + CAST(@p453_2605 AS nvarchar(30))
    + N' _2606=' + CAST(@p453_2606 AS nvarchar(30));
IF ABS(ISNULL(@p453_2605, 0) - ISNULL(@p453_2606, 0)) > 0.01
BEGIN
    SET @fail = @fail + 1;
    PRINT N'  FAIL';
END
ELSE
    PRINT N'  OK';

-- =============================================================================
-- Уровень B/C — PercentBrn (_2605): один материализованный вызов
-- =============================================================================
PRINT N'';
PRINT N'--- Level B/C: materialize PercentBrn_2605 (chain 5) ---';
PRINT N'  (may take several minutes...)';

IF OBJECT_ID('tempdb..#pb05') IS NOT NULL DROP TABLE #pb05;

SELECT
    dateRslt,
    ipgKey,
    cstAgPnCode,
    ag_lim,
    ag_Pl,
    ag_presented,
    ag_percentDev
INTO #pb05
FROM ags.fnIpgChRsltCstUtlPercentBrn_2605(@ipgCh, NULL)
WHERE dateRslt IN ('2022-09-21', '2022-09-22', '2022-09-30');

PRINT N'  #pb05 rows: ' + CAST(@@ROWCOUNT AS nvarchar(10));

-- Уровень B — модель перехода 8→11
PRINT N'--- Level B: transition model Sept 2022 ---';

DECLARE @sampleCode nvarchar(20) = N'051-2002202';

SELECT dateRslt, ipgKey, cstAgPnCode, ag_lim, ag_Pl, ag_presented, ag_percentDev
FROM #pb05
WHERE cstAgPnCode = @sampleCode
ORDER BY dateRslt;

DECLARE @pres21 money = (SELECT ag_presented FROM #pb05 WHERE dateRslt = '2022-09-21' AND cstAgPnCode = @sampleCode AND ipgKey = 8);
DECLARE @pres22 money = (SELECT ag_presented FROM #pb05 WHERE dateRslt = '2022-09-22' AND cstAgPnCode = @sampleCode AND ipgKey = 11);
DECLARE @lim21 money = (SELECT ag_lim FROM #pb05 WHERE dateRslt = '2022-09-21' AND cstAgPnCode = @sampleCode AND ipgKey = 8);
DECLARE @lim22 money = (SELECT ag_lim FROM #pb05 WHERE dateRslt = '2022-09-22' AND cstAgPnCode = @sampleCode AND ipgKey = 11);

PRINT N'B.1 sample ' + @sampleCode + N': pres 21.09=' + CAST(@pres21 AS nvarchar(30))
    + N' pres 22.09=' + CAST(@pres22 AS nvarchar(30));
PRINT N'B.2 sample ' + @sampleCode + N': lim 21.09/ipg8=' + CAST(@lim21 AS nvarchar(30))
    + N' lim 22.09/ipg11=' + CAST(@lim22 AS nvarchar(30));

IF ISNULL(@pres21, -1) = ISNULL(@pres22, -1) AND ISNULL(@lim21, -1) <> ISNULL(@lim22, -1)
    PRINT N'  OK (same presented, different lim — _2605 model confirmed)';
ELSE
BEGIN
    SET @fail = @fail + 1;
    PRINT N'  FAIL (expected same presented, different lim)';
END

DECLARE @samePresCnt int = (
    SELECT COUNT(*)
    FROM #pb05 a
    INNER JOIN #pb05 b
        ON a.cstAgPnCode = b.cstAgPnCode
       AND a.dateRslt = '2022-09-21' AND a.ipgKey = 8
       AND b.dateRslt = '2022-09-22' AND b.ipgKey = 11
    WHERE ISNULL(a.ag_presented, 0) = ISNULL(b.ag_presented, 0)
      AND a.ag_presented IS NOT NULL
);

DECLARE @pairCnt int = (
    SELECT COUNT(*) FROM #pb05
    WHERE dateRslt = '2022-09-21' AND ipgKey = 8 AND ag_presented IS NOT NULL
);

PRINT N'B.3 pairs ipg8@21.09 / ipg11@22.09 with equal presented: '
    + CAST(@samePresCnt AS nvarchar(10)) + N' / ' + CAST(@pairCnt AS nvarchar(10));

IF @pairCnt > 0 AND @samePresCnt = @pairCnt
    PRINT N'  OK (all transition pairs share monthly presented)';
ELSE IF @pairCnt = 0
    PRINT N'  SKIP (no pairs with presented)';
ELSE
BEGIN
    SET @fail = @fail + 1;
    PRINT N'  WARN (not all pairs equal — check edge cases)';
END

PRINT N'B.4 PercentBrn_2606: см. 07f_COMPARE_PercentBrn_full_chain5.sql';

-- Уровень C — sp-proxy
PRINT N'';
PRINT N'--- Level C: sp-proxy @MounthEndDate=' + CONVERT(nvarchar(10), @monthEnd, 23) + N' ---';

DECLARE @cntPb2605 int = (SELECT COUNT(*) FROM #pb05 WHERE dateRslt = @monthEnd);
DECLARE @cntPb2605Ipg11 int = (SELECT COUNT(*) FROM #pb05 WHERE dateRslt = @monthEnd AND ipgKey = 11);
DECLARE @cntPb2605Null int = (SELECT COUNT(*) FROM #pb05 WHERE dateRslt = @monthEnd AND ipgKey IS NULL);

PRINT N'C.1 PercentBrn_2605 rows dateRslt=monthEnd: total=' + CAST(@cntPb2605 AS nvarchar(10))
    + N' ipg11=' + CAST(@cntPb2605Ipg11 AS nvarchar(10))
    + N' ipgNULL=' + CAST(@cntPb2605Null AS nvarchar(10));

IF @cntPb2605 > 0 AND @cntPb2605Ipg11 > 0
    PRINT N'  OK (_2605 baseline recorded for future spMstrg_2606 compare)';
ELSE
BEGIN
    SET @fail = @fail + 1;
    PRINT N'  FAIL (empty PercentBrn at monthEnd)';
END

PRINT N'C.2 полный RS1 / PercentBrn (приоритет 1): см. 07f_COMPARE_PercentBrn_full_chain5.sql (TODO)';
PRINT N'C.3 spMstrg_2606 RS4-RS7: SKIP (sp not implemented)';

-- =============================================================================
PRINT N'';
IF @fail = 0
    PRINT N'=== 07e: PASS (with B.4/C.2 deferred) ===';
ELSE
    PRINT N'=== 07e: FAIL (' + CAST(@fail AS nvarchar(10)) + N' check(s)) — see Level A/B/C above ===';
GO
