/*
 * DBHub-check SQL: чек-лист верификации Type 5 (RA + RC) по exec_key.
 *
 * Назначение:
 * - быстро подтвердить цепочку staging → match → apply → domain;
 * - сверить reconcile-счётчики (adt_results) с фактами в БД;
 * - проверить отсутствие дублей по каноническим ключам;
 * - проверить marker-таблицу идемпотентности.
 *
 * Примечания:
 * - для матчинга RA категорий используйте также: docs/sql-scripts/type5-match-categories-check.sql
 * - для пост-проверки apply RA (baseline max(ra_key)) используйте также: docs/sql-scripts/type5-post-apply-ra-sanity.sql
 *
 * Инструкция:
 * 1) Установите @exec_key (из ags.ra_execution).
 * 2) Выполните скрипт целиком в DBHub.
 *
 * lastUpdated: 2026-03-25
 */

DECLARE @exec_key BIGINT = 17;

/* ------------------------------
 * A) Execution metadata
 * ------------------------------ */
SELECT TOP 1
    e.exec_key,
    e.exec_adt_key,
    e.exec_status,
    e.exec_started,
    e.exec_finished,
    DATEDIFF(SECOND, e.exec_started, e.exec_finished) AS exec_duration_sec
FROM ags.ra_execution e
WHERE e.exec_key = @exec_key;

/* ------------------------------
 * B) Audit (adt_results)
 * ------------------------------ */
SELECT
    a.adt_key,
    a.adt_AddRA,
    CAST(a.adt_results AS NVARCHAR(MAX)) AS adt_results
FROM ags.ra_a a
WHERE a.adt_key = (
    SELECT TOP 1 exec_adt_key FROM ags.ra_execution WHERE exec_key = @exec_key
);

/* ------------------------------
 * C) Staging volume
 * ------------------------------ */
SELECT
    COUNT(*) AS stg_rows_total,
    SUM(CASE WHEN LTRIM(RTRIM(rainSign)) IN (N'ОА', N'ОА прочие') THEN 1 ELSE 0 END) AS stg_rows_ra_sign,
    SUM(CASE WHEN LTRIM(RTRIM(rainSign)) = N'ОА изм' THEN 1 ELSE 0 END) AS stg_rows_rc_sign,
    SUM(CASE WHEN UPPER(LTRIM(RTRIM(rainSender))) = N'ИТОГ' THEN 1 ELSE 0 END) AS stg_rows_itog_sender
FROM ags.ra_stg_ra
WHERE rain_exec_key = @exec_key;

/* ------------------------------
 * D) Marker table status (idempotency)
 * ------------------------------ */
IF OBJECT_ID(N'ags.ra_reconcile_marker', N'U') IS NULL
BEGIN
    SELECT CAST(N'ags.ra_reconcile_marker: NOT FOUND' AS NVARCHAR(200)) AS marker_status;
END
ELSE
BEGIN
    SELECT
        exec_key,
        file_type,
        step_code,
        created_at
    FROM ags.ra_reconcile_marker
    WHERE exec_key = @exec_key
    ORDER BY created_at;
END

/* ------------------------------
 * E) Domain duplicate checks (core idempotency)
 * ------------------------------ */

-- E1) RA duplicates by read-model key (ra_period, ra_num).
SELECT TOP 50
    r.ra_period,
    r.ra_num,
    COUNT(*) AS cnt
FROM ags.ra r
GROUP BY r.ra_period, r.ra_num
HAVING COUNT(*) > 1
ORDER BY cnt DESC, r.ra_period DESC, r.ra_num;

-- E2) RC duplicates by key used in apply guard (ra_period, raс_ra, raс_num).
SELECT TOP 50
    c.ra_period,
    c.[raс_ra] AS rac_ra_fk,
    c.[raс_num] AS rac_num,
    COUNT(*) AS cnt
FROM ags.ra_change c
GROUP BY c.ra_period, c.[raс_ra], c.[raс_num]
HAVING COUNT(*) > 1
ORDER BY cnt DESC, c.ra_period DESC;

/* ------------------------------
 * F) RC parse health for this exec_key (staging)
 * ------------------------------ */
SELECT TOP 50
    s.rain_key,
    s.rainRaNum,
    s.rainRaDate,
    s.rainSign
FROM ags.ra_stg_ra s
WHERE s.rain_exec_key = @exec_key
  AND LTRIM(RTRIM(s.rainSign)) = N'ОА изм'
  AND (
      s.rainRaNum IS NULL
      OR s.rainRaNum NOT LIKE N'%изм%'
      AND s.rainRaNum NOT LIKE N'%Изм%'
      AND s.rainRaNum NOT LIKE N'%ИЗМ%'
  )
ORDER BY s.rain_key;

/* ------------------------------
 * G) Quick sanity: joined RC base RA lookup (how many RC rows can find base RA)
 * ------------------------------ */
;WITH rc_stg AS (
    SELECT
        s.rain_key,
        LTRIM(RTRIM(s.rainRaNum)) AS rainRaNum,
        s.rainRaDate
    FROM ags.ra_stg_ra s
    WHERE s.rain_exec_key = @exec_key
      AND LTRIM(RTRIM(s.rainSign)) = N'ОА изм'
)
SELECT
    COUNT(*) AS rc_rows,
    SUM(CASE WHEN rp.[key] IS NULL THEN 1 ELSE 0 END) AS rc_missing_period,
    SUM(CASE WHEN rp.[key] IS NOT NULL THEN 1 ELSE 0 END) AS rc_has_period
FROM rc_stg rcs
LEFT JOIN ags.ra_period rp
    ON rp.rap_datePeriod = CASE
        WHEN rcs.rainRaDate IS NULL THEN NULL
        WHEN DAY(rcs.rainRaDate) < 16 THEN DATEFROMPARTS(YEAR(rcs.rainRaDate), MONTH(rcs.rainRaDate), 15)
        ELSE EOMONTH(rcs.rainRaDate)
    END;

/* ------------------------------
 * H) Notes
 * ------------------------------ */
SELECT CAST(N'Checklist complete. For deeper match-category analysis run type5-match-categories-check.sql' AS NVARCHAR(200)) AS hint;

