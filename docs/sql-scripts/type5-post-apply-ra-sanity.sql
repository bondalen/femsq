/*
 * DBHub: пост-проверка инкремента B (upsert RA) для type=5 после reconcile с addRa=true.
 * Дополняет инкремент A: docs/sql-scripts/type5-match-categories-check.sql
 *
 * Назначение:
 * - зафиксировать объём staging по exec_key;
 * - при известном baseline max(ra_key) до прогона — оценить прирост строк в ags.ra / ags.ra_summ.
 *
 * Инструкция:
 * 1) @exec_key — запуск из ags.ra_execution / rain_exec_key.
 * 2) @baseline_max_ra_key — NULL = только staging; задать число = сравнение с состоянием до apply.
 * 3) Выполнить скрипт целиком.
 *
 * lastUpdated: 2026-03-24
 */

DECLARE @exec_key BIGINT = 17;
DECLARE @baseline_max_ra_key BIGINT = NULL; /* например 51537 до контрольного apply */

-- A) Объём staging для запуска
SELECT COUNT(*) AS stg_rows
FROM ags.ra_stg_ra
WHERE rain_exec_key = @exec_key;

-- B) При заданном baseline: сколько новых RA и сумм после прогона
IF @baseline_max_ra_key IS NOT NULL
BEGIN
    SELECT COUNT(*) AS ra_rows_after_baseline
    FROM ags.ra
    WHERE ra_key > @baseline_max_ra_key;

    SELECT COUNT(*) AS ra_summ_rows_for_new_ra
    FROM ags.ra_summ s
    WHERE EXISTS (
        SELECT 1
        FROM ags.ra r
        WHERE r.ra_key = s.ras_ra
          AND r.ra_key > @baseline_max_ra_key
    );

    SELECT TOP 25
        r.ra_key,
        r.ra_num,
        r.ra_date,
        r.ra_period,
        r.ra_cac,
        r.ra_org_sender,
        r.ra_type,
        r.ra_created
    FROM ags.ra r
    WHERE r.ra_key > @baseline_max_ra_key
    ORDER BY r.ra_key DESC;
END
ELSE
BEGIN
    SELECT CAST(N'set @baseline_max_ra_key to compare ra/ra_summ growth' AS nvarchar(200)) AS hint;
END
