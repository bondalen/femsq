-- =============================================================================
-- Файл:    00_VERIFY_before.sql
-- Пакет:   docs/development/notes/sql/26-0714/
-- Назначение: Проверка ПЕРЕД добавлением ralprtRow / ralprsRow (задача 0051).
-- =============================================================================

PRINT '=== 00_VERIFY_before: 26-0714 excel-row staging ===';
PRINT 'Дата: ' + CONVERT(nvarchar(30), GETDATE(), 121);
PRINT 'БД: ' + DB_NAME();
PRINT '@@VERSION: ' + CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(50));
PRINT '';

PRINT '--- 1. Таблицы staging RALP (должны существовать) ---';
SELECT
    t.obj_name,
    CASE WHEN OBJECT_ID(N'ags.' + t.obj_name, N'U') IS NOT NULL THEN N'OK' ELSE N'MISSING!' END AS status
FROM (VALUES
    (N'ra_stg_ralp'),
    (N'ra_stg_ralp_sm'),
    (N'ra_stg_ra')
) t(obj_name);

PRINT '--- 2. Колонки до ALTER (ожидание: ralprtRow/ralprsRow отсутствуют; rainRow есть) ---';
SELECT
    N'ralprtRow' AS col_name,
    N'ra_stg_ralp' AS tbl,
    COL_LENGTH(N'ags.ra_stg_ralp', N'ralprtRow') AS col_length,
    CASE WHEN COL_LENGTH(N'ags.ra_stg_ralp', N'ralprtRow') IS NULL THEN N'OK (absent, will ADD)' ELSE N'ALREADY EXISTS' END AS status
UNION ALL
SELECT
    N'ralprsRow',
    N'ra_stg_ralp_sm',
    COL_LENGTH(N'ags.ra_stg_ralp_sm', N'ralprsRow'),
    CASE WHEN COL_LENGTH(N'ags.ra_stg_ralp_sm', N'ralprsRow') IS NULL THEN N'OK (absent, will ADD)' ELSE N'ALREADY EXISTS' END
UNION ALL
SELECT
    N'rainRow',
    N'ra_stg_ra',
    COL_LENGTH(N'ags.ra_stg_ra', N'rainRow'),
    CASE WHEN COL_LENGTH(N'ags.ra_stg_ra', N'rainRow') IS NOT NULL THEN N'OK (exists)' ELSE N'MISSING rainRow!' END;

PRINT '=== 00_VERIFY_before: готово ===';
