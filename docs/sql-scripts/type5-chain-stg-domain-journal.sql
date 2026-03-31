/*
 * DBHub-check SQL: 1.6.2 — сверка цепочки ra_stg_ra → ags.ra → ags.ra_change → journal выполнения.
 *
 * Journal выполнения:
 * - ags.ra_execution: статус, exec_error, времена
 * - ags.ra_a.adt_results: HTML-лог (AuditLogEntry) со строками STAGING_LOAD_STATS / RECONCILE_*
 *
 * Инструкция:
 * 1) Установите @exec_key под нужный запуск.
 * 2) Выполните скрипт целиком в DBHub.
 *
 * lastUpdated: 2026-03-25
 */

DECLARE @exec_key BIGINT = 17;

/* ------------------------------
 * A) Execution row (status/journal pointers)
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

/* ------------------------------
 * B) Audit journal (adt_results HTML)
 * ------------------------------ */
SELECT
    a.adt_key,
    a.adt_AddRA,
    a.adt_name,
    a.adt_lastUpdated,
    CAST(a.adt_results AS NVARCHAR(MAX)) AS adt_results_html
FROM ags.ra_a a
WHERE a.adt_key = (
    SELECT TOP 1 exec_adt_key FROM ags.ra_execution WHERE exec_key = @exec_key
);

/* ------------------------------
 * C) Staging scope for exec_key
 * ------------------------------ */
SELECT
    COUNT(*) AS stg_rows,
    SUM(CASE WHEN LTRIM(RTRIM(rainSign)) IN (N'ОА', N'ОА прочие') THEN 1 ELSE 0 END) AS stg_ra_rows,
    SUM(CASE WHEN LTRIM(RTRIM(rainSign)) = N'ОА изм' THEN 1 ELSE 0 END) AS stg_rc_rows
FROM ags.ra_stg_ra
WHERE rain_exec_key = @exec_key;

SELECT TOP 25
    s.rain_key,
    LTRIM(RTRIM(s.rainSign)) AS rainSign,
    s.rainRaDate,
    LTRIM(RTRIM(s.rainRaNum)) AS rainRaNum,
    LTRIM(RTRIM(s.rainCstAgPnStr)) AS rainCstAgPnStr,
    LTRIM(RTRIM(s.rainSender)) AS rainSender,
    s.rainTtl, s.rainWork, s.rainEquip, s.rainOthers
FROM ags.ra_stg_ra s
WHERE s.rain_exec_key = @exec_key
ORDER BY s.rain_key;

/* ------------------------------
 * D) RA chain: staging (eligible signs) → lookup → domain ags.ra
 * (join logic mirrors type5-match-categories-check.sql)
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
domain_candidates AS (
    SELECT
        l.*,
        r.ra_key,
        COUNT(r.ra_key) OVER (PARTITION BY l.rain_key) AS candidateCount
    FROM lookup_resolved l
    LEFT JOIN ags.ra r
        ON l.ogKey = r.ra_org_sender
        AND l.cstapKey = r.ra_cac
        AND l.periodKey = r.ra_period
        AND l.rainRaNum = r.ra_num
)
SELECT
    COUNT(*) AS ra_stg_rows_considered,
    SUM(CASE WHEN periodKey IS NULL OR cstapKey IS NULL OR ogKey IS NULL OR rainRaNum IS NULL THEN 1 ELSE 0 END) AS ra_lookup_missing,
    SUM(CASE WHEN candidateCount = 0 THEN 1 ELSE 0 END) AS ra_domain_missing,
    SUM(CASE WHEN candidateCount = 1 THEN 1 ELSE 0 END) AS ra_domain_single,
    SUM(CASE WHEN candidateCount > 1 THEN 1 ELSE 0 END) AS ra_domain_ambiguous
FROM domain_candidates;

SELECT TOP 50
    d.rain_key,
    d.rainSign,
    d.periodKey,
    d.cstapKey,
    d.ogKey,
    d.rainRaNum,
    d.candidateCount,
    d.ra_key
FROM (
    SELECT
        dc.*,
        ROW_NUMBER() OVER (PARTITION BY dc.rain_key ORDER BY dc.ra_key DESC) AS rn
    FROM domain_candidates dc
) d
WHERE d.rn = 1
  AND (d.periodKey IS NULL OR d.cstapKey IS NULL OR d.ogKey IS NULL OR d.rainRaNum IS NULL OR d.candidateCount <> 1)
ORDER BY d.rain_key;

/* ------------------------------
 * E) RC chain: domain ags.ra_change sanity + duplicates
 * (RC staging parse itself is in Java; its counters are visible in adt_results_html)
 * ------------------------------ */
SELECT
    COUNT(*) AS rc_domain_rows_total
FROM ags.ra_change;

SELECT TOP 50
    c.ra_period,
    c.[raс_ra] AS rac_ra_fk,
    c.[raс_num] AS rac_num,
    COUNT(*) AS cnt
FROM ags.ra_change c
GROUP BY c.ra_period, c.[raс_ra], c.[raс_num]
HAVING COUNT(*) > 1
ORDER BY cnt DESC, c.ra_period DESC;

SELECT TOP 25
    c.rac_key,
    c.ra_period,
    c.[raс_ra] AS rac_ra_fk,
    c.[raс_num] AS rac_num,
    c.[raс_date] AS rac_date,
    c.ra_org_sender,
    c.ra_created
FROM ags.ra_change c
ORDER BY c.rac_key DESC;

/* ------------------------------
 * F) Marker rows (if present) as link from exec_key to apply steps
 * ------------------------------ */
IF OBJECT_ID(N'ags.ra_reconcile_marker', N'U') IS NOT NULL
BEGIN
    SELECT
        rm.exec_key,
        rm.file_type,
        rm.step_code,
        rm.created_at,
        rm.details
    FROM ags.ra_reconcile_marker rm
    WHERE rm.exec_key = @exec_key
    ORDER BY rm.created_at;
END

