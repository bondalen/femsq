/*
 * Type 5 reconcile marker cleanup policy (TEST stand only)
 * --------------------------------------------------------
 * Назначение:
 *   Безопасная очистка технических маркеров идемпотентности в ags.ra_reconcile_marker
 *   на тестовом стенде, чтобы таблица не росла бесконечно.
 *
 * Политика (Вариант B):
 *   1) TTL: удаляем только "старые" маркеры (по created_at).
 *   2) Retention: дополнительно сохраняем N последних exec на каждую ревизию (exec_adt_key).
 *   3) Safety: никогда не трогаем RUNNING.
 *
 * Важно:
 *   - Для PROD использовать только после отдельного согласования.
 *   - По умолчанию скрипт работает в режиме dry-run (только просмотр кандидатов).
 */

SET NOCOUNT ON;

DECLARE @ttlDays INT = 14;                -- хранить минимум 14 дней
DECLARE @keepLatestPerAudit INT = 20;     -- плюс держать минимум 20 последних exec на каждую ревизию
DECLARE @applyDelete BIT = 0;             -- 0 = dry-run, 1 = выполнить DELETE

;WITH marker_base AS (
    SELECT
        rm.rm_key,
        rm.exec_key,
        rm.file_type,
        rm.step_code,
        rm.created_at,
        ex.exec_adt_key,
        ex.exec_status,
        ROW_NUMBER() OVER (
            PARTITION BY ex.exec_adt_key
            ORDER BY rm.exec_key DESC, rm.rm_key DESC
        ) AS rn_per_audit
    FROM ags.ra_reconcile_marker rm
    LEFT JOIN ags.ra_execution ex
        ON ex.exec_key = rm.exec_key
    WHERE rm.file_type = 5
      AND rm.step_code IN ('TYPE5_APPLY_RA', 'TYPE5_APPLY_RC', 'TYPE5_DELETE_RA', 'TYPE5_DELETE_RC')
),
candidates AS (
    SELECT *
    FROM marker_base
    WHERE created_at < DATEADD(DAY, -@ttlDays, SYSUTCDATETIME())
      AND rn_per_audit > @keepLatestPerAudit
      AND ISNULL(exec_status, 'UNKNOWN') <> 'RUNNING'
)
SELECT
    'dry_run_summary' AS section,
    COUNT(*) AS rows_to_delete
FROM candidates;

SELECT
    'dry_run_details' AS section,
    rm_key,
    exec_key,
    exec_adt_key,
    exec_status,
    step_code,
    created_at,
    rn_per_audit
FROM candidates
ORDER BY created_at, rm_key;

IF @applyDelete = 1
BEGIN
    BEGIN TRANSACTION;

    DELETE rm
    FROM ags.ra_reconcile_marker rm
    INNER JOIN candidates c
        ON c.rm_key = rm.rm_key;

    SELECT
        'delete_result' AS section,
        @@ROWCOUNT AS rows_deleted;

    COMMIT TRANSACTION;
END;

/*
 * Быстрый запуск:
 *
 * 1) Dry-run:
 *    оставить @applyDelete = 0 и посмотреть dry_run_summary/dry_run_details
 *
 * 2) Реальная очистка:
 *    установить @applyDelete = 1
 *
 * Рекомендуемый регламент для TEST:
 *   - запуск 1 раз в неделю;
 *   - @ttlDays = 14..30;
 *   - @keepLatestPerAudit >= 20.
 */
