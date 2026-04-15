/*
 * Type5 acceptance post-run smoke check
 * ------------------------------------
 * Назначение:
 *   Быстро проверить, что после ручного/CI acceptance-прогона не осталось
 *   доменных "хвостов", и при этом технические артефакты ожидаемы.
 *
 * Использование:
 *   1) Записать baseline max-ключи до apply-прогона (временная таблица ниже).
 *   2) После прогона/rollback выполнить блок "post-run checks".
 *
 * Важно:
 *   - Скрипт read-only, ничего не удаляет.
 *   - Для dry-run acceptance допускается отсутствие роста доменных ключей.
 */

SET NOCOUNT ON;

/* ---------- 1) Snapshot baseline (выполнить ПЕРЕД apply-прогоном) ---------- */
IF OBJECT_ID('tempdb..#type5_baseline') IS NOT NULL
    DROP TABLE #type5_baseline;

SELECT
    CAST(ISNULL(MAX(ra_key), 0) AS bigint) AS ra_max,
    CAST((SELECT ISNULL(MAX(ras_key), 0) FROM ags.ra_summ) AS bigint) AS ras_max,
    CAST((SELECT ISNULL(MAX(rac_key), 0) FROM ags.ra_change) AS bigint) AS rac_max,
    CAST((SELECT ISNULL(MAX([raсs_key]), 0) FROM ags.ra_change_summ) AS bigint) AS racs_max
INTO #type5_baseline
FROM ags.ra;

SELECT 'baseline_snapshot' AS section, * FROM #type5_baseline;

/* ---------- 2) Post-run checks (выполнить ПОСЛЕ прогона и rollback) ---------- */
WITH current_state AS (
    SELECT
        CAST(ISNULL(MAX(ra_key), 0) AS bigint) AS ra_max,
        CAST((SELECT ISNULL(MAX(ras_key), 0) FROM ags.ra_summ) AS bigint) AS ras_max,
        CAST((SELECT ISNULL(MAX(rac_key), 0) FROM ags.ra_change) AS bigint) AS rac_max,
        CAST((SELECT ISNULL(MAX([raсs_key]), 0) FROM ags.ra_change_summ) AS bigint) AS racs_max
    FROM ags.ra
)
SELECT
    'postrun_domain_delta_vs_baseline' AS section,
    c.ra_max - b.ra_max AS ra_delta,
    c.ras_max - b.ras_max AS ras_delta,
    c.rac_max - b.rac_max AS rac_delta,
    c.racs_max - b.racs_max AS racs_delta,
    CASE
        WHEN c.ra_max = b.ra_max
         AND c.ras_max = b.ras_max
         AND c.rac_max = b.rac_max
         AND c.racs_max = b.racs_max
        THEN 'OK_ROLLBACK'
        ELSE 'CHECK_REQUIRED'
    END AS rollback_status
FROM current_state c
CROSS JOIN #type5_baseline b;

/* ---------- 3) Технические артефакты (ожидаемые) ---------- */
SELECT TOP 10
    'recent_exec_for_audit_13_14' AS section,
    exec_key,
    exec_adt_key,
    exec_status,
    exec_started_at
FROM ags.ra_execution
WHERE exec_adt_key IN (13, 14)
ORDER BY exec_key DESC;

SELECT TOP 20
    'recent_type5_markers' AS section,
    rm_key,
    exec_key,
    file_type,
    step_code,
    created_at
FROM ags.ra_reconcile_marker
WHERE file_type = 5
ORDER BY rm_key DESC;

/*
 * Интерпретация:
 *   - rollback_status = OK_ROLLBACK: доменные таблицы чистые.
 *   - Наличие новых строк в ra_execution / ra_reconcile_marker — ожидаемо.
 *   - Если rollback_status = CHECK_REQUIRED: сверить rollback-скрипт и baseline.
 */
