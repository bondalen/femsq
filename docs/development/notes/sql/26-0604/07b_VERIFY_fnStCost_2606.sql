USE [FishEye];
GO

-- =============================================================================
-- Файл:    07b_VERIFY_fnStCost_2606.sql
-- Пакет:   docs/development/notes/sql/26-0604/
-- Назначение: Тест F (политика B+F): fnStCost* = fnStCost*_2606.
--   Сравниваются пары (носитель, stcKey), где на ПОСЛЕДНЕЙ сумме есть строка Ct
--   с этим stcKey (не все ключи подряд для носителя с «чужим» Ct).
--   Критерий: |legacy - _2606| < 0.01
--   Наивный SUM(factDocCost) — НЕ критерий.
--   RA без Ct целиком, но с flat — вне выборки Ct (legacy=0, _2606>0 — ожидаемо до 01d1).
--   После 01d1: gate G-stCost195 — flat work → fnStCostRa_2606(195) ≈ ras_work.
--   Пары Ct@182 без legacy — исключены (ложная регрессия flat→182 до 01d1).
-- Предусловия: 03b0 применён; для G-stCost195 — 01c+01d1.
-- Автор:   Александр
-- Дата:    2026-06-09 | Обновлён: 2026-06-13 (этап 13, G-stCost195)
-- =============================================================================

PRINT '=== 07b: VERIFY fnStCost*_2606 (тест F) ===';
GO

SET NOCOUNT ON;

DECLARE @stNet int;
DECLARE @raPairs int;
DECLARE @raMismatch int;
DECLARE @raChPairs int;
DECLARE @raChMismatch int;
DECLARE @agFeeMismatch int;
DECLARE @ralpMismatch int;
DECLARE @prDocMismatch int;
DECLARE @mnrlMismatch int;
DECLARE @flat195Mismatch int;
DECLARE @flat195Pairs int;
DECLARE @fail bit;

SELECT @stNet = c.ipgcStNetIpg FROM ags.ipgCh c WHERE c.ipgcKey = 5;

IF @stNet IS NULL
BEGIN
    RAISERROR(N'ipgCh 5 не найдена — невозможно определить @stNet', 16, 1);
    RETURN;
END

PRINT N'@stNet (ipgcStNetIpg цепи 5) = ' + CAST(@stNet AS nvarchar(10));

-- Пары (носитель, stcKey) с Ct на последней сумме RA
IF OBJECT_ID(N'tempdb..#RaCtPairs', N'U') IS NOT NULL DROP TABLE #RaCtPairs;

SELECT DISTINCT
    rs.ras_ra AS carrierKey,
    ct.rscStCost AS stcKey
INTO #RaCtPairs
FROM ags.ra_summ rs
INNER JOIN ags.ra_summCt ct ON ct.rscRaSumm = rs.ras_key
WHERE rs.ras_key =
(
    SELECT MAX(m.ras_key)
    FROM
    (
        SELECT MAX(s.ras_date) AS dm
        FROM ags.ra_summ s
        WHERE s.ras_ra = rs.ras_ra
    ) AS z
    INNER JOIN ags.ra_summ m ON z.dm = m.ras_date AND m.ras_ra = rs.ras_ra
);

-- Исключить Ct@182 без legacy (ошибочный flat→182 до 01d1; не критерий теста F)
DELETE p
FROM #RaCtPairs p
WHERE p.stcKey = 182
  AND ISNULL(ags.fnStCostRa(p.carrierKey, 182, @stNet), 0) = 0;

SELECT @raPairs = COUNT(*) FROM #RaCtPairs;
PRINT N'Пар RA (носитель × stcKey из Ct последней суммы): ' + CAST(@raPairs AS nvarchar(20));

IF OBJECT_ID(N'tempdb..#RaMismatch', N'U') IS NOT NULL DROP TABLE #RaMismatch;

SELECT
    p.carrierKey,
    p.stcKey,
    CAST(ags.fnStCostRa(p.carrierKey, p.stcKey, @stNet) AS decimal(19, 4)) AS legacyVal,
    CAST(ags.fnStCostRa_2606(p.carrierKey, p.stcKey, @stNet) AS decimal(19, 4)) AS newVal,
    ABS(
        CAST(ags.fnStCostRa(p.carrierKey, p.stcKey, @stNet) AS decimal(19, 4))
      - CAST(ags.fnStCostRa_2606(p.carrierKey, p.stcKey, @stNet) AS decimal(19, 4))
    ) AS deltaAbs
INTO #RaMismatch
FROM #RaCtPairs p
WHERE ABS(
        ISNULL(ags.fnStCostRa(p.carrierKey, p.stcKey, @stNet), 0)
      - ISNULL(ags.fnStCostRa_2606(p.carrierKey, p.stcKey, @stNet), 0)
  ) >= 0.01;

SELECT @raMismatch = COUNT(*) FROM #RaMismatch;

PRINT N'--- fnStCostRa vs fnStCostRa_2606 ---';
PRINT N'Расхождений (|delta| >= 0.01): ' + CAST(@raMismatch AS nvarchar(20));

IF @raMismatch > 0
BEGIN
    PRINT N'Первые 20 расхождений RA:';
    SELECT TOP 20 * FROM #RaMismatch ORDER BY deltaAbs DESC, carrierKey, stcKey;
END

-- Пары RaCh с Ct на последней сумме
IF OBJECT_ID(N'tempdb..#RaChCtPairs', N'U') IS NOT NULL DROP TABLE #RaChCtPairs;

SELECT DISTINCT
    rcs.raсs_raс AS carrierKey,
    ct.rcscStCost AS stcKey
INTO #RaChCtPairs
FROM ags.ra_change_summ rcs
INNER JOIN ags.ra_change_summCt ct ON ct.rcscRaChSumm = rcs.raсs_key
WHERE rcs.raсs_key =
(
    SELECT MAX(m.raсs_key)
    FROM
    (
        SELECT MAX(s.raсs_date) AS dm
        FROM ags.ra_change_summ s
        WHERE s.raсs_raс = rcs.raсs_raс
    ) AS z
    INNER JOIN ags.ra_change_summ m ON z.dm = m.raсs_date AND m.raсs_raс = rcs.raсs_raс
);

SELECT @raChPairs = COUNT(*) FROM #RaChCtPairs;
PRINT N'Пар RaCh (носитель × stcKey из Ct последней суммы): ' + CAST(@raChPairs AS nvarchar(20));

IF OBJECT_ID(N'tempdb..#RaChMismatch', N'U') IS NOT NULL DROP TABLE #RaChMismatch;

SELECT
    p.carrierKey,
    p.stcKey,
    CAST(ags.fnStCostRaCh(p.carrierKey, p.stcKey, @stNet) AS decimal(19, 4)) AS legacyVal,
    CAST(ags.fnStCostRaCh_2606(p.carrierKey, p.stcKey, @stNet) AS decimal(19, 4)) AS newVal,
    ABS(
        CAST(ags.fnStCostRaCh(p.carrierKey, p.stcKey, @stNet) AS decimal(19, 4))
      - CAST(ags.fnStCostRaCh_2606(p.carrierKey, p.stcKey, @stNet) AS decimal(19, 4))
    ) AS deltaAbs
INTO #RaChMismatch
FROM #RaChCtPairs p
WHERE ABS(
        ISNULL(ags.fnStCostRaCh(p.carrierKey, p.stcKey, @stNet), 0)
      - ISNULL(ags.fnStCostRaCh_2606(p.carrierKey, p.stcKey, @stNet), 0)
  ) >= 0.01;

SELECT @raChMismatch = COUNT(*) FROM #RaChMismatch;

PRINT N'--- fnStCostRaCh vs fnStCostRaCh_2606 ---';
PRINT N'Расхождений (|delta| >= 0.01): ' + CAST(@raChMismatch AS nvarchar(20));

IF @raChMismatch > 0
BEGIN
    PRINT N'Первые 20 расхождений RaCh:';
    SELECT TOP 20 * FROM #RaChMismatch ORDER BY deltaAbs DESC, carrierKey, stcKey;
END

-- Доп. регрессия flat→factDocCost (информативно)
SELECT @agFeeMismatch = COUNT(*)
FROM ags.ogAgFeeP p
WHERE p.oafp_fdKey IS NOT NULL
  AND ABS(
        ISNULL(ags.fnStCostAgFee(p.oafpKey, 148, @stNet), 0)
      - ISNULL(ags.fnStCostAgFee_2606(p.oafpKey, 148, @stNet), 0)
  ) >= 0.01;

SELECT @ralpMismatch = COUNT(*)
FROM ags.ralpRaAu p
WHERE p.ralpra_fdKey IS NOT NULL
  AND ABS(
        ISNULL(ags.fnStCostRalp(p.ralpraKey, 150, @stNet), 0)
      - ISNULL(ags.fnStCostRalp_2606(p.ralpraKey, 150, @stNet), 0)
  ) >= 0.01;

SELECT @prDocMismatch = COUNT(*)
FROM ags.cn_PrDocP p
CROSS JOIN (VALUES (205), (197)) AS k(stcKey)
WHERE p.pdp_fdKey IS NOT NULL
  AND ABS(
        ISNULL(ags.fnStCostPrDoc(p.pdpKey, k.stcKey, @stNet), 0)
      - ISNULL(ags.fnStCostPrDoc_2606(p.pdpKey, k.stcKey, @stNet), 0)
  ) >= 0.01;

SELECT @mnrlMismatch = COUNT(*)
FROM ags.cstAgPnMnrl m
WHERE m.am_fdKey IS NOT NULL
  AND ABS(
        ISNULL(ags.fnStCostMnrl(m.amKey, 169, @stNet), 0)
      - ISNULL(ags.fnStCostMnrl_2606(m.amKey, 169, @stNet), 0)
  ) >= 0.01;

PRINT N'--- доп. регрессия flat→factDocCost ---';
PRINT N'AgFee расхождений: ' + CAST(@agFeeMismatch AS nvarchar(20));
PRINT N'Ralp расхождений:  ' + CAST(@ralpMismatch AS nvarchar(20));
PRINT N'PrDoc расхождений: ' + CAST(@prDocMismatch AS nvarchar(20));
PRINT N'Mnrl расхождений:  ' + CAST(@mnrlMismatch AS nvarchar(20));

-- Gate G-stCost195: flat work → fnStCostRa_2606(195) ≈ ras_work (последняя сумма)
IF OBJECT_ID(N'tempdb..#FlatWork195', N'U') IS NOT NULL DROP TABLE #FlatWork195;

SELECT
    rs.ras_ra AS carrierKey,
    rs.ras_work AS flatWork,
    CAST(ags.fnStCostRa_2606(rs.ras_ra, 195, @stNet) AS decimal(19, 4)) AS fn2606_195,
    ABS(
        CAST(rs.ras_work AS decimal(19, 4))
      - CAST(ags.fnStCostRa_2606(rs.ras_ra, 195, @stNet) AS decimal(19, 4))
    ) AS deltaAbs
INTO #FlatWork195
FROM ags.ra_summ rs
WHERE rs.ras_work IS NOT NULL AND rs.ras_work <> 0
  AND rs.ras_key =
(
    SELECT MAX(m.ras_key)
    FROM
    (
        SELECT MAX(s.ras_date) AS dm
        FROM ags.ra_summ s
        WHERE s.ras_ra = rs.ras_ra
    ) AS z
    INNER JOIN ags.ra_summ m ON z.dm = m.ras_date AND m.ras_ra = rs.ras_ra
);

SELECT @flat195Pairs = COUNT(*) FROM #FlatWork195;
SELECT @flat195Mismatch = COUNT(*) FROM #FlatWork195 WHERE deltaAbs >= 0.01;

PRINT N'--- gate G-stCost195 (flat work → fnStCostRa_2606@195) ---';
PRINT N'RA с ras_work>0 (последняя сумма): ' + CAST(@flat195Pairs AS nvarchar(20));
PRINT N'Расхождений G-stCost195 (|delta| >= 0.01): ' + CAST(@flat195Mismatch AS nvarchar(20));

IF @flat195Mismatch > 0
BEGIN
    PRINT N'Первые 20 расхождений G-stCost195:';
    SELECT TOP 20 * FROM #FlatWork195 WHERE deltaAbs >= 0.01 ORDER BY deltaAbs DESC, carrierKey;
END

SET @fail = 0;
IF @raMismatch > 0 OR @raChMismatch > 0 OR @flat195Mismatch > 0
    SET @fail = 1;

IF @fail = 1
BEGIN
    PRINT N'=== 07b: ТЕСТ F — FAIL (есть расхождения RA/RaCh с Ct или G-stCost195) ===';
    RAISERROR(N'07b VERIFY: тест F не пройден — см. расхождения выше', 16, 1);
END
ELSE
    PRINT N'=== 07b: ТЕСТ F — PASS (0 расхождений RA/RaCh на выборке с Ct; G-stCost195 OK) ===';
GO
