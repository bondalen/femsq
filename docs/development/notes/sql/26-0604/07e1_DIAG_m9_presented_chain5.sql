USE [FishEye];
GO

-- =============================================================================
-- Файл:    07e1_DIAG_m9_presented_chain5.sql
-- Пакет:   docs/development/notes/sql/26-0604/
-- Назначение: Диагностика Level A FAIL (presented m9): разрыв источников факта.
--   _2605 / _2408 — RRcTimeList.ras_total
--   fn2_2606 / mastering — fnMasteringPresRaMn → fnStCostRa (legacy)
-- Предусловия: fn2_2605, fn2_2606, ipgChRlV.
-- Автор:   Александр
-- Дата:    2026-06-09
-- =============================================================================

SET NOCOUNT ON;
GO

PRINT N'=== 07e1: DIAG presented m9 — chain 5 ===';
PRINT N'';

DECLARE @ipgCh int = 5;
DECLARE @stNet int = (SELECT ipgcStNetIpg FROM ags.ipgCh WHERE ipgcKey = @ipgCh);
DECLARE @dSep date = '2022-09-30';
DECLARE @dMar date = '2022-03-31';

-- -----------------------------------------------------------------------------
-- 1. Сводка: m9 keys с pres05>0 и PresRaMn=0
-- -----------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#m9') IS NOT NULL DROP TABLE #m9;

SELECT cstAgPnKey, MAX(presented) AS pres05
INTO #m9
FROM ags.fnIpgChRsltCstUtl2_2605(@ipgCh, NULL)
WHERE typeGr = N'1. ОА и Изм.'
  AND iShKey = 2
  AND mNum = 9
  AND ipgKey IS NOT NULL
GROUP BY cstAgPnKey;

DECLARE @cntPres05 int = (SELECT COUNT(*) FROM #m9 WHERE pres05 > 0.01);
DECLARE @cntPresMn0 int = (
    SELECT COUNT(*)
    FROM #m9 s
    WHERE s.pres05 > 0.01
      AND ISNULL(ags.fnMasteringPresRaMn(@dSep, s.cstAgPnKey, 212, @stNet, 0), 0) < 0.01
);

PRINT N'1. m9: cstAgPn с pres05>0: ' + CAST(@cntPres05 AS nvarchar(10));
PRINT N'   из них PresRaMn@' + CONVERT(nvarchar(10), @dSep, 23) + N' = 0: '
    + CAST(@cntPresMn0 AS nvarchar(10));

IF @cntPres05 > 0 AND @cntPresMn0 = @cntPres05
    PRINT N'   OK pattern: ALL m9 presented in _2605 come from path != fnMasteringPresRaMn';
ELSE IF @cntPresMn0 = 0
    PRINT N'   UNEXPECTED: no zero PresRaMn cases';
ELSE
    PRINT N'   MIXED: ' + CAST(@cntPres05 - @cntPresMn0 AS nvarchar(10))
        + N' keys have non-zero PresRaMn — partial mismatch';

-- -----------------------------------------------------------------------------
-- 2. Spot TOP-5: pres05 vs PresRaMn vs RRc vs fnStCostRa_2606 (cst 849…)
-- -----------------------------------------------------------------------------
PRINT N'';
PRINT N'2. Spot TOP-5 m9 (pres05 DESC):';

SELECT TOP 5
    s.cstAgPnKey,
    cap.cstapIpgPnN AS code,
    s.pres05,
    ags.fnMasteringPresRaMn(@dSep, s.cstAgPnKey, 212, @stNet, 0) AS presMn_legacy,
    (
        SELECT SUM(CASE
            WHEN (r.complianceY = N'соответствует'
                OR (r.complianceY = N'не соответствует' AND r.ras_total > 0))
            THEN r.ras_total END)
        FROM ags.RRcTimeList r
        INNER JOIN ags.ra_period p ON r.ra_period = p.[key]
        INNER JOIN ags.yyyy y ON p.y = y.yKey
        WHERE r.ra_cac = s.cstAgPnKey
          AND y.yyyy = 2022
          AND p.m = 9
          AND r.typeGr = N'1. ОА и Изм.'
    ) AS pres_rrc_m9,
    (
        SELECT SUM(ags.fnStCostRa_2606(r.ra_key, 212, @stNet))
        FROM ags.ra r
        WHERE r.ra_cac = s.cstAgPnKey
          AND YEAR(r.ra_datePeriod) = 2022
          AND MONTH(r.ra_datePeriod) = 9
    ) AS pres_stcost2606_m9
FROM #m9 s
INNER JOIN ags.cstAgPn cap ON cap.cstapKey = s.cstAgPnKey
WHERE s.pres05 > 0.01
ORDER BY s.pres05 DESC;

-- -----------------------------------------------------------------------------
-- 3. Эталон cstAgPnKey=849: pres2408 vs PresRaMn по месяцам (month-end)
-- -----------------------------------------------------------------------------
PRINT N'';
PRINT N'3. cstAgPnKey=849: _2408 presented vs PresRaMn (month-end 2022):';

DECLARE @cst849 int = 849;

SELECT m.mNum,
    MAX(f.presented) AS pres_2408,
    ags.fnMasteringPresRaMn(
        DATEFROMPARTS(2022, m.mNum, DAY(EOMONTH(DATEFROMPARTS(2022, m.mNum, 1)))),
        @cst849, 212, @stNet, 0
    ) AS presMn_eom
FROM ags.mmmm m
LEFT JOIN ags.fnIpgChRsltCstUtl_2408(@ipgCh) f
    ON f.cstAgPnKey = @cst849
   AND f.mNum = m.mNum
   AND f.iShKey = 2
   AND f.typeGr = N'1. ОА и Изм.'
   AND f.ipgKey = 11
WHERE m.mNum BETWEEN 1 AND 12
GROUP BY m.mNum
ORDER BY m.mNum;

-- -----------------------------------------------------------------------------
-- 4. m3 edge: PresRaMn=0 при pres05>0 (6 keys)
-- -----------------------------------------------------------------------------
PRINT N'';
PRINT N'4. m3 edge cases (PresRaMn@31.03=0, pres05>0):';

SELECT s.cstAgPnKey, cap.cstapIpgPnN AS code, s.pres05,
    ags.fnMasteringPresRaMn(@dMar, s.cstAgPnKey, 212, @stNet, 0) AS presMn_m3
FROM (
    SELECT cstAgPnKey, MAX(presented) AS pres05
    FROM ags.fnIpgChRsltCstUtl2_2605(@ipgCh, NULL)
    WHERE typeGr = N'1. ОА и Изм.' AND iShKey = 2 AND mNum = 3 AND ipgKey IS NOT NULL
    GROUP BY cstAgPnKey
) s
INNER JOIN ags.cstAgPn cap ON cap.cstapKey = s.cstAgPnKey
WHERE s.pres05 > 0.01
  AND ISNULL(ags.fnMasteringPresRaMn(@dMar, s.cstAgPnKey, 212, @stNet, 0), 0) < 0.01;

PRINT N'';
PRINT N'=== 07e1: conclusion ===';
PRINT N'  _2605 presented (m4–m12) = RRcTimeList.ras_total (_2408 path).';
PRINT N'  fn2_2606 presented = fnMasteringPresRaMn → fnStCostRa (legacy) → 0 when нет ra_summCt.';
PRINT N'  RRc matches pres05 exactly; fnStCostRa_2606 — близко, но не эталон _2605.';
PRINT N'  Fix: fact в fn2_2606 из RRcTimeList-логики _2408 (CTE raFact2408); лимиты — mastering.';
PRINT N'  Точечная проверка: 07e2_COMPARE_fn2_single_cstAgPn.sql (@cstAgPnKey).';
GO
