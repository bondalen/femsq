/*
 * DBHub-check SQL для Phase 1.1.6 (Type 5 match categories + partial apply).
 *
 * Назначение:
 * - категории матчинга NEW/CHANGED/UNCHANGED/AMBIGUOUS/INVALID (RA-ветка, как в reconcile);
 * - признак applyEligibility: ELIGIBLE_NEW / ELIGIBLE_CHANGED / REJECTED_* / FILTERED_TO_RC / SKIP_UNCHANGED;
 * - контроль VBA-semantics: кондиционные строки могут применяться при наличии некондиционных
 *   (нет глобального shouldBlockApply по data-quality).
 *
 * См. также: type5-post-apply-ra-sanity.sql (инкремент B после addRa=true).
 *
 * Инструкция:
 * 1) Установите @exec_key под нужный запуск из ags.ra_execution.
 * 2) Выполните скрипт целиком в DBHub.
 *
 * lastUpdated: 2026-03-24
 */

DECLARE @exec_key BIGINT = 17;

IF OBJECT_ID('tempdb..#classified') IS NOT NULL
    DROP TABLE #classified;

;WITH stg AS (
    SELECT
        s.rain_key,
        LTRIM(RTRIM(s.rainRaNum)) AS rainRaNum,
        s.rainRaDate,
        LTRIM(RTRIM(s.rainCstAgPnStr)) AS rainCstAgPnStr,
        LTRIM(RTRIM(s.rainSender)) AS rainSender,
        LTRIM(RTRIM(s.rainSign)) AS rainSign,
        s.rainTtl,
        s.rainWork,
        s.rainEquip,
        s.rainOthers,
        LTRIM(RTRIM(s.rainArrivedNum)) AS rainArrivedNum,
        s.rainArrivedDate,
        s.rainArrivedDateFact,
        LTRIM(RTRIM(s.rainReturnedNum)) AS rainReturnedNum,
        s.rainReturnedDate,
        LTRIM(RTRIM(s.rainReturnedReason)) AS rainReturnedReason,
        LTRIM(RTRIM(s.rainSendNum)) AS rainSendNum,
        s.rainSendDate
    FROM ags.ra_stg_ra s
    WHERE s.rain_exec_key = @exec_key
),
lookup_resolved AS (
    SELECT
        stg.*,
        rp.[key] AS periodKey,
        c.cstapKey AS cstapKey,
        og.ogKey AS ogKey
    FROM stg
    LEFT JOIN ags.ra_period rp
        ON rp.rap_datePeriod = CASE
            WHEN stg.rainRaDate IS NULL THEN NULL
            WHEN DAY(stg.rainRaDate) < 16 THEN DATEFROMPARTS(YEAR(stg.rainRaDate), MONTH(stg.rainRaDate), 15)
            ELSE EOMONTH(stg.rainRaDate)
        END
    LEFT JOIN ags.cstAgPn c
        ON stg.rainCstAgPnStr = c.cstapIpgPnN
    LEFT JOIN ags.ogNmF_allVariantsNoRepeat og
        ON stg.rainSender = og.ogNm255
        AND UPPER(ISNULL(stg.rainSender, '')) <> N'ИТОГ'
),
domain_join AS (
    SELECT
        l.*,
        r.ra_key,
        r.ra_type,
        r.ra_date,
        r.ra_arrived,
        r.ra_arrived_date,
        r.ra_arrived_dateFact,
        r.ra_returned,
        r.ra_returned_date,
        r.ra_returnedReason,
        r.ra_sent,
        r.ra_sent_date,
        sm.ras_total,
        sm.ras_work,
        sm.ras_equip,
        sm.ras_others,
        COUNT(r.ra_key) OVER (
            PARTITION BY l.rain_key
        ) AS candidateCount
    FROM lookup_resolved l
    LEFT JOIN ags.ra r
        ON l.ogKey = r.ra_org_sender
        AND l.cstapKey = r.ra_cac
        AND l.periodKey = r.ra_period
        AND l.rainRaNum = r.ra_num
    LEFT JOIN ags.raSmLt sm
        ON sm.ras_ra = r.ra_key
),
classified AS (
    SELECT
        d.rain_key,
        d.rainSign,
        d.periodKey,
        d.cstapKey,
        d.ogKey,
        d.rainRaNum,
        d.candidateCount,
        CASE
            WHEN d.rainSign = N'ОА изм' THEN 'FILTERED_SIGN'
            WHEN d.rainRaNum IS NULL OR d.periodKey IS NULL OR d.cstapKey IS NULL OR d.ogKey IS NULL THEN 'INVALID'
            WHEN d.rainSign IS NULL OR d.rainSign NOT IN (N'ОА', N'ОА прочие') THEN 'INVALID'
            WHEN d.candidateCount > 1 THEN 'AMBIGUOUS'
            WHEN d.candidateCount = 0 THEN 'NEW'
            WHEN
                ISNULL(d.ra_type, '') = ISNULL(d.rainSign, '')
                AND ISNULL(d.ra_date, CONVERT(date, '19000101')) = ISNULL(d.rainRaDate, CONVERT(date, '19000101'))
                AND ISNULL(d.ra_arrived, '') = ISNULL(d.rainArrivedNum, '')
                AND ISNULL(d.ra_arrived_date, CONVERT(date, '19000101')) = ISNULL(d.rainArrivedDate, CONVERT(date, '19000101'))
                AND ISNULL(d.ra_arrived_dateFact, CONVERT(date, '19000101')) = ISNULL(d.rainArrivedDateFact, CONVERT(date, '19000101'))
                AND ISNULL(d.ra_returned, '') = ISNULL(d.rainReturnedNum, '')
                AND ISNULL(d.ra_returned_date, CONVERT(date, '19000101')) = ISNULL(d.rainReturnedDate, CONVERT(date, '19000101'))
                AND ISNULL(d.ra_returnedReason, '') = ISNULL(d.rainReturnedReason, '')
                AND ISNULL(d.ra_sent, '') = ISNULL(d.rainSendNum, '')
                AND ISNULL(d.ra_sent_date, CONVERT(date, '19000101')) = ISNULL(d.rainSendDate, CONVERT(date, '19000101'))
                AND ISNULL(d.ras_total, 0) = ISNULL(d.rainTtl, 0)
                AND ISNULL(d.ras_work, 0) = ISNULL(d.rainWork, 0)
                AND ISNULL(d.ras_equip, 0) = ISNULL(d.rainEquip, 0)
                AND ISNULL(d.ras_others, 0) = ISNULL(d.rainOthers, 0)
            THEN 'UNCHANGED'
            ELSE 'CHANGED'
        END AS matchCategory,
        CASE
            WHEN d.rainSign = N'ОА изм' THEN 'FILTERED_TO_RC'
            WHEN d.rainRaNum IS NULL OR d.periodKey IS NULL OR d.cstapKey IS NULL OR d.ogKey IS NULL THEN 'REJECTED_INVALID'
            WHEN d.rainSign IS NULL OR d.rainSign NOT IN (N'ОА', N'ОА прочие') THEN 'REJECTED_INVALID'
            WHEN d.candidateCount > 1 THEN 'REJECTED_AMBIGUOUS'
            WHEN d.candidateCount = 0 THEN 'ELIGIBLE_NEW'
            WHEN
                ISNULL(d.ra_type, '') = ISNULL(d.rainSign, '')
                AND ISNULL(d.ra_date, CONVERT(date, '19000101')) = ISNULL(d.rainRaDate, CONVERT(date, '19000101'))
                AND ISNULL(d.ra_arrived, '') = ISNULL(d.rainArrivedNum, '')
                AND ISNULL(d.ra_arrived_date, CONVERT(date, '19000101')) = ISNULL(d.rainArrivedDate, CONVERT(date, '19000101'))
                AND ISNULL(d.ra_arrived_dateFact, CONVERT(date, '19000101')) = ISNULL(d.rainArrivedDateFact, CONVERT(date, '19000101'))
                AND ISNULL(d.ra_returned, '') = ISNULL(d.rainReturnedNum, '')
                AND ISNULL(d.ra_returned_date, CONVERT(date, '19000101')) = ISNULL(d.rainReturnedDate, CONVERT(date, '19000101'))
                AND ISNULL(d.ra_returnedReason, '') = ISNULL(d.rainReturnedReason, '')
                AND ISNULL(d.ra_sent, '') = ISNULL(d.rainSendNum, '')
                AND ISNULL(d.ra_sent_date, CONVERT(date, '19000101')) = ISNULL(d.rainSendDate, CONVERT(date, '19000101'))
                AND ISNULL(d.ras_total, 0) = ISNULL(d.rainTtl, 0)
                AND ISNULL(d.ras_work, 0) = ISNULL(d.rainWork, 0)
                AND ISNULL(d.ras_equip, 0) = ISNULL(d.rainEquip, 0)
                AND ISNULL(d.ras_others, 0) = ISNULL(d.rainOthers, 0)
            THEN 'SKIP_UNCHANGED'
            ELSE 'ELIGIBLE_CHANGED'
        END AS applyEligibility
    FROM domain_join d
)
SELECT *
INTO #classified
FROM classified;

-- 1) Распределение по категориям матчинга
SELECT
    matchCategory,
    COUNT(*) AS rowsCount
FROM #classified
GROUP BY matchCategory
ORDER BY
    CASE matchCategory
        WHEN 'INVALID' THEN 1
        WHEN 'AMBIGUOUS' THEN 2
        WHEN 'NEW' THEN 3
        WHEN 'CHANGED' THEN 4
        WHEN 'UNCHANGED' THEN 5
        WHEN 'FILTERED_SIGN' THEN 6
        ELSE 99
    END;

-- 2) Распределение по applyEligibility (partial apply)
SELECT
    applyEligibility,
    COUNT(*) AS rowsCount
FROM #classified
GROUP BY applyEligibility
ORDER BY
    CASE applyEligibility
        WHEN 'REJECTED_INVALID' THEN 1
        WHEN 'REJECTED_AMBIGUOUS' THEN 2
        WHEN 'FILTERED_TO_RC' THEN 3
        WHEN 'ELIGIBLE_NEW' THEN 4
        WHEN 'ELIGIBLE_CHANGED' THEN 5
        WHEN 'SKIP_UNCHANGED' THEN 6
        ELSE 99
    END;

-- 3) Детализация проблемных категорий матчинга (топ-50)
SELECT TOP 50
    rain_key,
    matchCategory,
    applyEligibility,
    rainSign,
    rainRaNum,
    periodKey,
    cstapKey,
    ogKey,
    candidateCount
FROM #classified
WHERE matchCategory IN ('INVALID', 'AMBIGUOUS')
ORDER BY rain_key;

-- 4) Partial apply (VBA): одновременно есть строки к apply и отклонённые по данным — нормально
SELECT
    SUM(CASE WHEN applyEligibility = 'ELIGIBLE_NEW' THEN 1 ELSE 0 END) AS eligibleNewCount,
    SUM(CASE WHEN applyEligibility = 'ELIGIBLE_CHANGED' THEN 1 ELSE 0 END) AS eligibleChangedCount,
    SUM(CASE WHEN applyEligibility = 'REJECTED_INVALID' THEN 1 ELSE 0 END) AS rejectedInvalidCount,
    SUM(CASE WHEN applyEligibility = 'REJECTED_AMBIGUOUS' THEN 1 ELSE 0 END) AS rejectedAmbiguousCount,
    SUM(CASE WHEN applyEligibility = 'FILTERED_TO_RC' THEN 1 ELSE 0 END) AS filteredToRcCount,
    SUM(CASE WHEN applyEligibility = 'SKIP_UNCHANGED' THEN 1 ELSE 0 END) AS skipUnchangedCount,
    CAST(
        CASE
            WHEN SUM(CASE WHEN applyEligibility IN ('ELIGIBLE_NEW', 'ELIGIBLE_CHANGED') THEN 1 ELSE 0 END) > 0
                AND SUM(CASE WHEN applyEligibility IN ('REJECTED_INVALID', 'REJECTED_AMBIGUOUS') THEN 1 ELSE 0 END) > 0
            THEN 1
            ELSE 0
        END AS bit
    ) AS partialApplyCoexistsRejected
FROM #classified;
