/*
 * DBHub-check SQL: 1.7.3 — Type 5 RC (ags.ra_change) match + apply sanity.
 *
 * Назначение:
 * - построить RC read-model в SQL по staging "ОА изм" (best-effort парсинг rainRaNum);
 * - привязать к base RA по (reportPeriod, reportNum) → ra_key;
 * - сопоставить с domain RC по (rcPeriod, ra_key, changeNum);
 * - дать категории NEW/CHANGED/UNCHANGED/AMBIGUOUS/PARSE_INVALID/MISSING_BASE_RA;
 * - после apply — оценить дельты по baseline (сколько вставлено/версионировано).
 *
 * Ограничения:
 * - парсинг в SQL является best-effort и зависит от формата строки; эталонная логика — Java `RcStagingLineParser`.
 *
 * Инструкция:
 * 1) Установите @exec_key.
 * 2) (Опционально) установите baseline max rac_key/raсs_key ДО apply для проверки дельт.
 * 3) Выполните скрипт целиком.
 *
 * lastUpdated: 2026-03-25
 */

DECLARE @exec_key BIGINT = 17;
DECLARE @baseline_max_rac_key  BIGINT = NULL;
DECLARE @baseline_max_racs_key BIGINT = NULL;

IF OBJECT_ID('tempdb..#rc') IS NOT NULL
    DROP TABLE #rc;

;WITH stg AS (
    SELECT
        s.rain_key,
        LTRIM(RTRIM(s.rainRaNum)) AS rainRaNum,
        s.rainRaDate,
        LTRIM(RTRIM(s.rainCstAgPnStr)) AS rainCstAgPnStr,
        LTRIM(RTRIM(s.rainSender)) AS rainSender,
        LTRIM(RTRIM(s.rainSign)) AS rainSign,
        s.rainArrivedNum,
        s.rainArrivedDate,
        s.rainArrivedDateFact,
        s.rainReturnedNum,
        s.rainReturnedDate,
        s.rainReturnedReason,
        s.rainSendNum,
        s.rainSendDate,
        s.rainTtl, s.rainWork, s.rainEquip, s.rainOthers
    FROM ags.ra_stg_ra s
    WHERE s.rain_exec_key = @exec_key
      AND LTRIM(RTRIM(s.rainSign)) = N'ОА изм'
),
parsed AS (
    SELECT
        stg.*,
        LOWER(stg.rainRaNum) AS raNumLower,
        -- change number: first digits after token 'изм'
        TRY_CONVERT(INT, NULLIF(
            SUBSTRING(
                stg.rainRaNum,
                NULLIF(PATINDEX(N'%[0-9]%', SUBSTRING(stg.rainRaNum, NULLIF(CHARINDEX(N'изм', LOWER(stg.rainRaNum)), 0) + 3, 200)), 0)
                    + (NULLIF(CHARINDEX(N'изм', LOWER(stg.rainRaNum)), 0) + 3) - 1,
                10
            ),
            N''
        )) AS changeNum,
        -- report number: between ' в ' and ' от ' (common format)
        NULLIF(LTRIM(RTRIM(
            CASE
                WHEN CHARINDEX(N' в ', stg.rainRaNum) > 0 AND CHARINDEX(N' от ', stg.rainRaNum) > CHARINDEX(N' в ', stg.rainRaNum)
                    THEN SUBSTRING(
                        stg.rainRaNum,
                        CHARINDEX(N' в ', stg.rainRaNum) + 3,
                        CHARINDEX(N' от ', stg.rainRaNum) - (CHARINDEX(N' в ', stg.rainRaNum) + 3)
                    )
                ELSE NULL
            END
        )), N'') AS reportNum,
        -- report date: after ' от ' (supports dd.MM.yyyy and dd.MM.yy)
        CASE
            WHEN CHARINDEX(N' от ', stg.rainRaNum) > 0 THEN
                TRY_CONVERT(date, LTRIM(RTRIM(SUBSTRING(stg.rainRaNum, CHARINDEX(N' от ', stg.rainRaNum) + 4, 10))), 104)
            ELSE NULL
        END AS reportDate
    FROM stg
),
lookup AS (
    SELECT
        p.*,
        rp.[key] AS rcPeriodKey,
        rpp.[key] AS reportPeriodKey,
        og.ogKey AS ogKey
    FROM parsed p
    LEFT JOIN ags.ra_period rp
        ON rp.rap_datePeriod = CASE
            WHEN p.rainRaDate IS NULL THEN NULL
            WHEN DAY(p.rainRaDate) < 16 THEN DATEFROMPARTS(YEAR(p.rainRaDate), MONTH(p.rainRaDate), 15)
            ELSE EOMONTH(p.rainRaDate)
        END
    LEFT JOIN ags.ra_period rpp
        ON rpp.rap_datePeriod = CASE
            WHEN p.reportDate IS NULL THEN NULL
            WHEN DAY(p.reportDate) < 16 THEN DATEFROMPARTS(YEAR(p.reportDate), MONTH(p.reportDate), 15)
            ELSE EOMONTH(p.reportDate)
        END
    LEFT JOIN ags.ogNmF_allVariantsNoRepeat og
        ON p.rainSender = og.ogNm255
        AND UPPER(ISNULL(p.rainSender, '')) <> N'ИТОГ'
),
base_ra AS (
    SELECT
        l.*,
        r.ra_key AS baseRaKey,
        COUNT(r.ra_key) OVER (PARTITION BY l.rain_key) AS baseRaCandidateCount
    FROM lookup l
    LEFT JOIN ags.ra r
        ON l.reportPeriodKey = r.ra_period
        AND l.reportNum = r.ra_num
),
domain_rc AS (
    SELECT
        b.*,
        c.rac_key,
        COUNT(c.rac_key) OVER (PARTITION BY b.rain_key) AS racCandidateCount,
        c.[raс_date] AS rcDateDb,
        c.ra_org_sender AS ogDb,
        c.ra_arrived AS arrivedDb,
        c.ra_arrived_date AS arrivedDateDb,
        c.ra_arrived_dateFact AS arrivedDateFactDb,
        c.ra_returned AS returnedDb,
        c.ra_returned_date AS returnedDateDb,
        c.ra_returnedReason AS returnedReasonDb,
        c.ra_sent AS sentDb,
        c.ra_sent_date AS sentDateDb,
        sm.[raсs_total] AS totalDb,
        sm.[raсs_work] AS workDb,
        sm.[raсs_equip] AS equipDb,
        sm.[raсs_others] AS othersDb
    FROM base_ra b
    LEFT JOIN ags.ra_change c
        ON b.rcPeriodKey = c.ra_period
        AND b.baseRaKey = c.[raс_ra]
        AND CAST(b.changeNum AS NVARCHAR(32)) = LTRIM(RTRIM(c.[raс_num]))
    LEFT JOIN ags.ra_chSmLt sm
        ON sm.[raсs_raс] = c.rac_key
),
classified AS (
    SELECT
        d.*,
        CASE
            WHEN d.rainRaNum IS NULL THEN 'PARSE_INVALID'
            WHEN d.changeNum IS NULL OR d.reportNum IS NULL OR d.reportDate IS NULL THEN 'PARSE_INVALID'
            WHEN d.rcPeriodKey IS NULL OR d.reportPeriodKey IS NULL THEN 'PARSE_INVALID'
            WHEN d.baseRaCandidateCount = 0 THEN 'MISSING_BASE_RA'
            WHEN d.baseRaCandidateCount > 1 THEN 'AMBIGUOUS_BASE_RA'
            WHEN d.racCandidateCount = 0 THEN 'NEW'
            WHEN d.racCandidateCount > 1 THEN 'AMBIGUOUS'
            WHEN
                ISNULL(d.rcDateDb, CONVERT(date,'19000101')) = ISNULL(d.rainRaDate, CONVERT(date,'19000101'))
                AND ISNULL(d.ogDb, -1) = ISNULL(d.ogKey, -1)
                AND ISNULL(d.arrivedDb, '') = ISNULL(LTRIM(RTRIM(d.rainArrivedNum)), '')
                AND ISNULL(d.arrivedDateDb, CONVERT(date,'19000101')) = ISNULL(d.rainArrivedDate, CONVERT(date,'19000101'))
                AND ISNULL(d.arrivedDateFactDb, CONVERT(date,'19000101')) = ISNULL(d.rainArrivedDateFact, CONVERT(date,'19000101'))
                AND ISNULL(d.returnedDb, '') = ISNULL(LTRIM(RTRIM(d.rainReturnedNum)), '')
                AND ISNULL(d.returnedDateDb, CONVERT(date,'19000101')) = ISNULL(d.rainReturnedDate, CONVERT(date,'19000101'))
                AND ISNULL(d.returnedReasonDb, '') = ISNULL(LTRIM(RTRIM(d.rainReturnedReason)), '')
                AND ISNULL(d.sentDb, '') = ISNULL(LTRIM(RTRIM(d.rainSendNum)), '')
                AND ISNULL(d.sentDateDb, CONVERT(date,'19000101')) = ISNULL(d.rainSendDate, CONVERT(date,'19000101'))
                AND ISNULL(d.totalDb, 0) = ISNULL(d.rainTtl, 0)
                AND ISNULL(d.workDb, 0) = ISNULL(d.rainWork, 0)
                AND ISNULL(d.equipDb, 0) = ISNULL(d.rainEquip, 0)
                AND ISNULL(d.othersDb, 0) = ISNULL(d.rainOthers, 0)
            THEN 'UNCHANGED'
            ELSE 'CHANGED'
        END AS rcCategory
    FROM domain_rc d
)
SELECT *
INTO #rc
FROM classified;

/* 1) Распределение категорий RC */
SELECT
    rcCategory,
    COUNT(*) AS rowsCount
FROM #rc
GROUP BY rcCategory
ORDER BY
    CASE rcCategory
        WHEN 'PARSE_INVALID' THEN 1
        WHEN 'MISSING_BASE_RA' THEN 2
        WHEN 'AMBIGUOUS_BASE_RA' THEN 3
        WHEN 'AMBIGUOUS' THEN 4
        WHEN 'NEW' THEN 5
        WHEN 'CHANGED' THEN 6
        WHEN 'UNCHANGED' THEN 7
        ELSE 99
    END;

/* 2) Топ проблемных строк */
SELECT TOP 50
    rain_key,
    rcCategory,
    rainRaNum,
    rainRaDate,
    changeNum,
    reportNum,
    reportDate,
    rcPeriodKey,
    reportPeriodKey,
    baseRaCandidateCount,
    baseRaKey,
    racCandidateCount,
    rac_key
FROM #rc
WHERE rcCategory IN ('PARSE_INVALID', 'MISSING_BASE_RA', 'AMBIGUOUS_BASE_RA', 'AMBIGUOUS')
ORDER BY rain_key;

/* 3) NEW/CHANGED детали (сопоставление) */
SELECT TOP 50
    rain_key,
    rcCategory,
    baseRaKey,
    changeNum,
    rac_key,
    rainRaNum,
    rainRaDate
FROM #rc
WHERE rcCategory IN ('NEW', 'CHANGED')
ORDER BY rain_key;

/* 4) Apply deltas (baseline) */
IF @baseline_max_rac_key IS NULL OR @baseline_max_racs_key IS NULL
BEGIN
    SELECT CAST(N'set @baseline_max_rac_key/@baseline_max_racs_key to check apply deltas' AS NVARCHAR(200)) AS hint;
END
ELSE
BEGIN
    SELECT COUNT(*) AS rc_rows_inserted_after_baseline
    FROM ags.ra_change
    WHERE rac_key > @baseline_max_rac_key;

    SELECT COUNT(*) AS rc_summ_rows_inserted_after_baseline
    FROM ags.ra_change_summ
    WHERE [raсs_key] > @baseline_max_racs_key;

    SELECT TOP 25
        c.rac_key,
        c.ra_period,
        c.[raс_ra] AS rac_ra_fk,
        c.[raс_num] AS rac_num,
        c.[raс_date] AS rac_date,
        c.ra_created
    FROM ags.ra_change c
    WHERE c.rac_key > @baseline_max_rac_key
    ORDER BY c.rac_key DESC;
END

