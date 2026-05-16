USE [FishEye]
GO

-- =============================================================================
-- Файл:    00_VERIFY_before.sql
-- Пакет:   docs/development/notes/sql/26-0508/
-- Назначение: Проверка состояния БД ПЕРЕД применением пакета _2605.
--             Убедиться, что все зависимые объекты существуют.
-- Выполнять: до скриптов 01–03, после резервной копии.
-- =============================================================================

PRINT '=== 00_VERIFY_before: состояние до применения пакета _2605 ===';
PRINT 'Дата: ' + CONVERT(nvarchar(30), GETDATE(), 121);
PRINT '';

-- -----------------------------------------------------------------------------
-- 1. Базовые _2408-объекты (должны существовать)
-- -----------------------------------------------------------------------------
PRINT '--- 1. Базовые объекты _2408 ---';
SELECT
    name,
    type_desc,
    CONVERT(varchar(10), modify_date, 23) AS modified,
    CASE WHEN OBJECT_ID('ags.' + name) IS NOT NULL THEN 'OK' ELSE 'MISSING!' END AS status
FROM (VALUES
    ('fnIpgChRsltCstUtl2_2408'),
    ('fnIpgChRsltCstUtlPercentBrn_2408'),
    ('spMstrg_2408'),
    ('spMstrg_2408_SaveToTables')
) t(obj_name)
JOIN sys.objects o ON o.name = t.obj_name AND o.schema_id = SCHEMA_ID('ags');
GO

-- -----------------------------------------------------------------------------
-- 2. Таблица importIpgSt_26-0320 (должна существовать и содержать данные)
-- -----------------------------------------------------------------------------
PRINT '--- 2. importIpgSt_26-0320 ---';
SELECT
    OBJECT_ID('ags.[importIpgSt_26-0320]') AS object_id,
    (SELECT COUNT(*) FROM ags.[importIpgSt_26-0320]) AS row_count,
    (SELECT COUNT(DISTINCT cst_type) FROM ags.[importIpgSt_26-0320]) AS distinct_cst_type;
GO

-- -----------------------------------------------------------------------------
-- 3. ResultSet-таблицы (должны существовать, 7 штук)
-- -----------------------------------------------------------------------------
PRINT '--- 3. ResultSet-таблицы ---';
SELECT COUNT(*) AS resultset_tables_count
FROM sys.tables
WHERE schema_id = SCHEMA_ID('ags')
  AND name LIKE 'spMstrg_2408_ResultSet%';
GO

-- -----------------------------------------------------------------------------
-- 4. _2605-объекты (НЕ должны существовать перед применением)
-- -----------------------------------------------------------------------------
PRINT '--- 4. _2605-объекты (должны отсутствовать) ---';
SELECT
    obj_name AS name,
    CASE WHEN OBJECT_ID('ags.' + obj_name) IS NOT NULL THEN 'ALREADY EXISTS!' ELSE 'OK (absent)' END AS status
FROM (VALUES
    ('fnIpgChRsltCstUtl2_2605'),
    ('fnIpgChRsltCstUtlPercentBrn_2605'),
    ('spMstrg_2605')
) t(obj_name);
GO

-- -----------------------------------------------------------------------------
-- 5. Версия SQL Server (должна поддерживать CREATE OR ALTER)
-- -----------------------------------------------------------------------------
PRINT '--- 5. SQL Server version ---';
SELECT @@VERSION AS sql_version, SERVERPROPERTY('ProductMajorVersion') AS major_version;
GO

PRINT '';
PRINT '=== 00_VERIFY_before: завершено ===';
GO
