-- =============================================================================
-- Файл:    04_VERIFY_after.sql
-- Пакет:   docs/development/notes/sql/26-0714/
-- Назначение: Проверка ПОСЛЕ добавления ralprtRow / ralprsRow.
-- =============================================================================

PRINT '=== 04_VERIFY_after: 26-0714 excel-row staging ===';
PRINT 'Дата: ' + CONVERT(nvarchar(30), GETDATE(), 121);
PRINT '';

PRINT '--- 1. Колонки (ожидание: все col_length NOT NULL) ---';
SELECT
    col_name,
    tbl,
    col_length,
    CASE WHEN col_length IS NOT NULL THEN N'OK' ELSE N'MISSING!' END AS status
FROM (
    SELECT N'ralprtRow' AS col_name, N'ra_stg_ralp' AS tbl, COL_LENGTH(N'ags.ra_stg_ralp', N'ralprtRow') AS col_length
    UNION ALL
    SELECT N'ralprsRow', N'ra_stg_ralp_sm', COL_LENGTH(N'ags.ra_stg_ralp_sm', N'ralprsRow')
    UNION ALL
    SELECT N'rainRow', N'ra_stg_ra', COL_LENGTH(N'ags.ra_stg_ra', N'rainRow')
) q;

PRINT '--- 2. Метаданные sys.columns ---';
SELECT
    OBJECT_NAME(c.object_id) AS table_name,
    c.name AS column_name,
    t.name AS type_name,
    c.is_nullable
FROM sys.columns c
INNER JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE c.object_id IN (OBJECT_ID(N'ags.ra_stg_ralp'), OBJECT_ID(N'ags.ra_stg_ralp_sm'))
  AND c.name IN (N'ralprtRow', N'ralprsRow')
ORDER BY table_name, column_name;

PRINT '=== 04_VERIFY_after: готово ===';
