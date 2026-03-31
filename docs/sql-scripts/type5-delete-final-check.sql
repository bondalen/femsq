/*
 * DBHub-check SQL: 1.7.5 — delete-ветки Type 5 + финальная сверка счётчиков/journal.
 *
 * Назначение:
 * - вычислить план удалений RA (1.4.1) и RC (1.4.2) по текущему exec_key (best-effort SQL-аналог);
 * - показать, были ли применены удаления (по marker шагам TYPE5_DELETE_RA/TYPE5_DELETE_RC для exec_key);
 * - вывести journal выполнения (ra_execution + adt_results) и ключевые sanity проверки.
 *
 * Важно:
 * - реальное применение delete защищено runtime-флагом `-Dfemsq.reconcile.type5.enableDeletes=true`.
 * - этот скрипт НИЧЕГО не удаляет — только считает план и показывает факты.
 *
 * lastUpdated: 2026-03-25
 */

DECLARE @exec_key BIGINT = 17;

DECLARE @adt_key INT =
    (SELECT TOP 1 exec_adt_key FROM ags.ra_execution WHERE exec_key = @exec_key);

/* ------------------------------
 * A) Journal (execution + adt_results)
 * ------------------------------ */
SELECT TOP 1
    e.exec_key,
    e.exec_adt_key,
    e.exec_status,
    e.exec_started,
    e.exec_finished,
    DATEDIFF(SECOND, e.exec_started, e.exec_finished) AS exec_duration_sec,
    CAST(e.exec_error AS NVARCHAR(MAX)) AS exec_error
FROM ags.ra_execution e
WHERE e.exec_key = @exec_key;

SELECT
    a.adt_key,
    a.adt_AddRA,
    a.adt_name,
    a.adt_lastUpdated,
    CAST(a.adt_results AS NVARCHAR(MAX)) AS adt_results_html
FROM ags.ra_a a
WHERE a.adt_key = @adt_key;

/* ------------------------------
 * B) Marker: whether delete steps were applied
 * ------------------------------ */
IF OBJECT_ID(N'ags.ra_reconcile_marker', N'U') IS NULL
BEGIN
    SELECT CAST(N'ags.ra_reconcile_marker: NOT FOUND' AS NVARCHAR(200)) AS marker_status;
END
ELSE
BEGIN
    SELECT
        rm.exec_key,
        rm.file_type,
        rm.step_code,
        rm.created_at
    FROM ags.ra_reconcile_marker rm
    WHERE rm.exec_key = @exec_key
      AND rm.step_code IN (N'TYPE5_DELETE_RA', N'TYPE5_DELETE_RC', N'TYPE5_APPLY_RA', N'TYPE5_APPLY_RC')
    ORDER BY rm.created_at;
END

/* ------------------------------
 * C) RA delete plan (SQL-аналог planRaDeletes)
 * Canonical key: (ra_period, ra_cac, ra_org_sender, ra_num)
 * Scope: только периоды, присутствующие в source (staging) RA allowed signs.
 * ------------------------------ */
;WITH stg AS (
    SELECT
        s.rain_key,
        LTRIM(RTRIM(s.rainRaNum)) AS rainRaNum,
        s.rainRaDate,
        LTRIM(RTRIM(s.rainCstAgPnStr)) AS rainCstAgPnStr,
        LTRIM(RTRIM(s.rainSender)) AS rainSender,
        LTRIM(RTRIM(s.rainSign)) AS rainSign
    FROM ags.ra_stg_ra s
    WHERE s.rain_exec_key = @exec_key
      AND LTRIM(RTRIM(s.rainSign)) IN (N'ОА', N'ОА прочие')
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
source_keys AS (
    SELECT DISTINCT
        l.periodKey AS ra_period,
        l.cstapKey AS ra_cac,
        l.ogKey AS ra_org_sender,
        l.rainRaNum AS ra_num
    FROM lookup_resolved l
    WHERE l.periodKey IS NOT NULL
      AND l.cstapKey IS NOT NULL
      AND l.ogKey IS NOT NULL
      AND l.rainRaNum IS NOT NULL
),
source_periods AS (
    SELECT DISTINCT ra_period FROM source_keys
),
domain_grouped AS (
    SELECT
        r.ra_period,
        r.ra_cac,
        r.ra_org_sender,
        r.ra_num,
        COUNT(*) AS cnt,
        MIN(r.ra_key) AS any_ra_key
    FROM ags.ra r
    GROUP BY r.ra_period, r.ra_cac, r.ra_org_sender, r.ra_num
),
planned AS (
    SELECT
        d.*,
        CASE WHEN d.cnt = 1 THEN 1 ELSE 0 END AS deletableSingle,
        CASE WHEN d.cnt <> 1 THEN 1 ELSE 0 END AS skippedAmbiguous
    FROM domain_grouped d
    WHERE d.ra_period IN (SELECT ra_period FROM source_periods)
      AND NOT EXISTS (
          SELECT 1 FROM source_keys s
          WHERE s.ra_period = d.ra_period
            AND s.ra_cac = d.ra_cac
            AND s.ra_org_sender = d.ra_org_sender
            AND s.ra_num = d.ra_num
      )
)
SELECT
    COUNT(*) AS raDeletePlannedTotal,
    SUM(deletableSingle) AS raDeletePlannedSingle,
    SUM(skippedAmbiguous) AS raDeleteSkippedAmbiguous
FROM planned;

SELECT TOP 50
    p.ra_period,
    p.ra_num,
    p.ra_cac,
    p.ra_org_sender,
    p.cnt AS domainDuplicatesForKey,
    p.any_ra_key
FROM planned p
ORDER BY p.cnt DESC, p.ra_period DESC;

/* ------------------------------
 * D) RC delete plan (SQL best-effort analog planRcDeletes)
 * Key: (rcPeriod, baseRaKey, changeNum)
 * Scope: только rcPeriod, присутствующие в source RC.
 * ------------------------------ */
;WITH stg AS (
    SELECT
        s.rain_key,
        LTRIM(RTRIM(s.rainRaNum)) AS rainRaNum,
        s.rainRaDate
    FROM ags.ra_stg_ra s
    WHERE s.rain_exec_key = @exec_key
      AND LTRIM(RTRIM(s.rainSign)) = N'ОА изм'
),
parsed AS (
    SELECT
        stg.*,
        TRY_CONVERT(INT, NULLIF(
            SUBSTRING(
                stg.rainRaNum,
                NULLIF(PATINDEX(N'%[0-9]%', SUBSTRING(stg.rainRaNum, NULLIF(CHARINDEX(N'изм', LOWER(stg.rainRaNum)), 0) + 3, 200)), 0)
                    + (NULLIF(CHARINDEX(N'изм', LOWER(stg.rainRaNum)), 0) + 3) - 1,
                10
            ),
            N''
        )) AS changeNum,
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
        CASE
            WHEN CHARINDEX(N' от ', stg.rainRaNum) > 0 THEN
                TRY_CONVERT(date, LTRIM(RTRIM(SUBSTRING(stg.rainRaNum, CHARINDEX(N' от ', stg.rainRaNum) + 4, 10))), 104)
            ELSE NULL
        END AS reportDate
    FROM stg
),
periods AS (
    SELECT
        p.*,
        rp.[key] AS rcPeriodKey,
        rpp.[key] AS reportPeriodKey
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
),
base_ra AS (
    SELECT
        pr.*,
        r.ra_key AS baseRaKey,
        COUNT(r.ra_key) OVER (PARTITION BY pr.rain_key) AS baseRaCandidateCount
    FROM periods pr
    LEFT JOIN ags.ra r
        ON pr.reportPeriodKey = r.ra_period
        AND pr.reportNum = r.ra_num
),
source_rc_keys AS (
    SELECT DISTINCT
        b.rcPeriodKey AS rcPeriod,
        b.baseRaKey AS raKey,
        CAST(b.changeNum AS NVARCHAR(32)) AS changeNumKey
    FROM base_ra b
    WHERE b.rcPeriodKey IS NOT NULL
      AND b.baseRaCandidateCount = 1
      AND b.baseRaKey IS NOT NULL
      AND b.changeNum IS NOT NULL
),
rc_periods AS (
    SELECT DISTINCT rcPeriod FROM source_rc_keys
),
domain_grouped AS (
    SELECT
        c.ra_period AS rcPeriod,
        c.[raс_ra] AS raKey,
        LTRIM(RTRIM(c.[raс_num])) AS changeNumKey,
        COUNT(*) AS cnt,
        MIN(c.rac_key) AS any_rac_key
    FROM ags.ra_change c
    GROUP BY c.ra_period, c.[raс_ra], LTRIM(RTRIM(c.[raс_num]))
),
planned AS (
    SELECT
        d.*,
        CASE WHEN d.cnt = 1 THEN 1 ELSE 0 END AS deletableSingle,
        CASE WHEN d.cnt <> 1 THEN 1 ELSE 0 END AS skippedAmbiguous
    FROM domain_grouped d
    WHERE d.rcPeriod IN (SELECT rcPeriod FROM rc_periods)
      AND NOT EXISTS (
          SELECT 1 FROM source_rc_keys s
          WHERE s.rcPeriod = d.rcPeriod
            AND s.raKey = d.raKey
            AND s.changeNumKey = d.changeNumKey
      )
)
SELECT
    COUNT(*) AS rcDeletePlannedTotal,
    SUM(deletableSingle) AS rcDeletePlannedSingle,
    SUM(skippedAmbiguous) AS rcDeleteSkippedAmbiguous
FROM planned;

SELECT TOP 50
    p.rcPeriod,
    p.raKey,
    p.changeNumKey,
    p.cnt AS domainDuplicatesForKey,
    p.any_rac_key
FROM planned p
ORDER BY p.cnt DESC, p.rcPeriod DESC;

