/*
 * Type5 acceptance post-run smoke check
 * ------------------------------------
 * Назначение:
 *   Обязательный smoke-check после КАЖДОГО apply IT:
 *   1) rollback действительно вернул домен к baseline;
 *   2) технические артефакты (execution/marker) ожидаемы.
 *
 * Важно:
 *   - Скрипт read-only (ничего не удаляет/не меняет).
 *   - Рекомендовано запускать в той же SQL-сессии, где снимали baseline.
 */

SET NOCOUNT ON;

/* ---------- 1) Снять baseline (выполнить ПЕРЕД apply) ---------- */
SELECT
    'baseline_capture' AS section,
    CAST(ISNULL(MAX(ra_key), 0) AS bigint) AS ra_max,
    CAST((SELECT ISNULL(MAX(ras_key), 0) FROM ags.ra_summ) AS bigint) AS ras_max,
    CAST((SELECT ISNULL(MAX(rac_key), 0) FROM ags.ra_change) AS bigint) AS rac_max,
    CAST((SELECT ISNULL(MAX([raсs_key]), 0) FROM ags.ra_change_summ) AS bigint) AS racs_max
FROM ags.ra;

/*
 * ---------- 2) Вставить baseline и выполнить post-run check (ПОСЛЕ apply+rollback) ----------
 * Скопируйте сюда значения из baseline_capture:
 */
DECLARE @baseline_ra_max BIGINT = NULL;     -- example: 51537
DECLARE @baseline_ras_max BIGINT = NULL;    -- example: 37711
DECLARE @baseline_rac_max BIGINT = NULL;    -- example: 3429
DECLARE @baseline_racs_max BIGINT = NULL;   -- example: 2409

WITH baseline AS (
    SELECT
        @baseline_ra_max AS ra_max,
        @baseline_ras_max AS ras_max,
        @baseline_rac_max AS rac_max,
        @baseline_racs_max AS racs_max
),
current_state AS (
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
        WHEN b.ra_max IS NULL OR b.ras_max IS NULL OR b.rac_max IS NULL OR b.racs_max IS NULL
        THEN 'BASELINE_NOT_SET'
        ELSE 'CHECK_REQUIRED'
    END AS rollback_status
FROM current_state c
CROSS JOIN baseline b;

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
 * Интерпретация (обязательный критерий после каждого apply IT):
 *   - OK_ROLLBACK      -> PASS
 *   - CHECK_REQUIRED   -> FAIL (проверить rollback/границы baseline)
 *   - BASELINE_NOT_SET -> FAIL (baseline не заполнен)
 *
 *   Наличие новых строк в ra_execution / ra_reconcile_marker — ожидаемо.
 */
