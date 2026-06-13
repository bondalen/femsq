USE [FishEye];
GO
-- Диагностика расхождений PercentBrn_2605 ↔ _2606 (цепь 5).
-- Материализация ~11 мин; сравнение по дедуплицированным ключам (dateRslt, ipgKey, cstapKey).
SET NOCOUNT ON;

DECLARE @ipgCh int = 5;

IF OBJECT_ID('tempdb..#a') IS NOT NULL DROP TABLE #a;
IF OBJECT_ID('tempdb..#b') IS NOT NULL DROP TABLE #b;

SELECT dateRslt, ipgKey, cstapKey, cstAgPnCode, ag_lim, ag_presented, ag_percentDev
INTO #a FROM ags.fnIpgChRsltCstUtlPercentBrn_2605(@ipgCh, NULL);
SELECT dateRslt, ipgKey, cstapKey, cstAgPnCode, ag_lim, ag_presented, ag_percentDev
INTO #b FROM ags.fnIpgChRsltCstUtlPercentBrn_2606(@ipgCh, NULL, NULL);

;WITH da AS (
    SELECT dateRslt, ipgKey, cstapKey,
           MAX(cstAgPnCode) AS code, MAX(ag_lim) AS lim, MAX(ag_presented) AS pres, MAX(ag_percentDev) AS pct
    FROM #a GROUP BY dateRslt, ipgKey, cstapKey
), db AS (
    SELECT dateRslt, ipgKey, cstapKey,
           MAX(cstAgPnCode) AS code, MAX(ag_lim) AS lim, MAX(ag_presented) AS pres, MAX(ag_percentDev) AS pct
    FROM #b GROUP BY dateRslt, ipgKey, cstapKey
)
SELECT
    (SELECT COUNT(*) FROM #a) AS raw_rows_05,
    (SELECT COUNT(*) FROM #b) AS raw_rows_06,
    (SELECT COUNT(*) FROM da) AS keys_05,
    (SELECT COUNT(*) FROM db) AS keys_06,
    (SELECT COUNT(*) FROM db b WHERE NOT EXISTS (
        SELECT 1 FROM da a WHERE a.dateRslt = b.dateRslt
          AND ISNULL(a.ipgKey, -1) = ISNULL(b.ipgKey, -1)
          AND ISNULL(a.cstapKey, -1) = ISNULL(b.cstapKey, -1))) AS only_06,
    (SELECT COUNT(*) FROM da a WHERE NOT EXISTS (
        SELECT 1 FROM db b WHERE a.dateRslt = b.dateRslt
          AND ISNULL(a.ipgKey, -1) = ISNULL(b.ipgKey, -1)
          AND ISNULL(a.cstapKey, -1) = ISNULL(b.cstapKey, -1))) AS only_05,
    (SELECT COUNT(*) FROM da a INNER JOIN db b
        ON a.dateRslt = b.dateRslt
       AND ISNULL(a.ipgKey, -1) = ISNULL(b.ipgKey, -1)
       AND ISNULL(a.cstapKey, -1) = ISNULL(b.cstapKey, -1)
     WHERE ABS(ISNULL(a.pres, 0) - ISNULL(b.pres, 0)) > 0.01
        OR ABS(ISNULL(a.lim, 0) - ISNULL(b.lim, 0)) > 0.01
        OR ABS(ISNULL(a.pct, 0) - ISNULL(b.pct, 0)) > 0.0001) AS field_diff_keys;

PRINT N'TOP only_06 (ключи только в _2606):';
;WITH da AS (
    SELECT dateRslt, ipgKey, cstapKey, MAX(cstAgPnCode) AS code, MAX(ag_presented) AS pres
    FROM #a GROUP BY dateRslt, ipgKey, cstapKey
), db AS (
    SELECT dateRslt, ipgKey, cstapKey, MAX(cstAgPnCode) AS code, MAX(ag_presented) AS pres
    FROM #b GROUP BY dateRslt, ipgKey, cstapKey
)
SELECT TOP 15 b.cstapKey, b.code, b.dateRslt, b.ipgKey, b.pres
FROM db b
WHERE NOT EXISTS (
    SELECT 1 FROM da a WHERE a.dateRslt = b.dateRslt
      AND ISNULL(a.ipgKey, -1) = ISNULL(b.ipgKey, -1)
      AND ISNULL(a.cstapKey, -1) = ISNULL(b.cstapKey, -1))
ORDER BY b.cstapKey, b.dateRslt;

GO
