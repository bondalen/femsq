USE [FishEye];
GO

-- =============================================================================
-- Файл:    00_VERIFY_before.sql
-- Пакет:   docs/development/notes/sql/26-0604/
-- Назначение: Состояние БД ПЕРЕД применением пакета spMstrg_2606.
-- Выполнять: до скриптов 01+, после резервной копии (на продуктиве).
-- =============================================================================

PRINT '=== 00_VERIFY_before: пакет spMstrg_2606 ===';
PRINT 'Дата: ' + CONVERT(nvarchar(30), GETDATE(), 121);
PRINT '';

-- -----------------------------------------------------------------------------
-- 0. Совместимость пакета (опционально для MSSQL2012/)
-- -----------------------------------------------------------------------------
PRINT '--- 0. Версия SQL Server ---';
SELECT @@VERSION AS sql_version;
GO

-- -----------------------------------------------------------------------------
-- 1. Объекты _2605 / _2408 (не должны исчезнуть после деплоя _2606)
-- -----------------------------------------------------------------------------
PRINT '--- 1. Базовые объекты _2408 / _2605 ---';
SELECT
    t.obj_name,
    CASE WHEN o.object_id IS NOT NULL THEN 'OK' ELSE 'MISSING!' END AS status
FROM (VALUES
    ('fnIpgChRsltCstUtl2_2408'),
    ('fnIpgChRsltCstUtlPercentBrn_2408'),
    ('fnIpgChRsltCstUtl2_2605'),
    ('fnIpgChRsltCstUtlPercentBrn_2605'),
    ('spMstrg_2605')
) AS t(obj_name)
LEFT JOIN sys.objects o
    ON o.name = t.obj_name
   AND o.schema_id = SCHEMA_ID('ags');
GO

-- -----------------------------------------------------------------------------
-- 2. Таблица ipgChRlV (до применения 01 — должна отсутствовать)
-- -----------------------------------------------------------------------------
PRINT '--- 2. ipgChRlV (ожидается отсутствие до 01) ---';
SELECT
    OBJECT_ID(N'ags.ipgChRlV', N'U') AS object_id,
    CASE
        WHEN OBJECT_ID(N'ags.ipgChRlV', N'U') IS NULL THEN 'OK (not exists yet)'
        ELSE 'EXISTS — повторное применение 01'
    END AS status;
GO

-- -----------------------------------------------------------------------------
-- 3. Источник миграции: ipgChRl для цепей 5 и 15
-- -----------------------------------------------------------------------------
PRINT '--- 3. ipgChRl: цепи 5 и 15 ---';
SELECT
    r.ipgcrChain,
    r.ipgcrIpg,
    i.ipgNm,
    i.ipgStr,
    r.ipgcrUtPlGr
FROM ags.ipgChRl r
JOIN ags.ipg i ON i.ipgKey = r.ipgcrIpg
WHERE r.ipgcrChain IN (5, 15)
ORDER BY r.ipgcrChain, i.ipgStr;
GO

-- -----------------------------------------------------------------------------
-- 4. ResultSet _2408 (не трогаем в пакете _2606)
-- -----------------------------------------------------------------------------
PRINT '--- 4. spMstrg_2408_ResultSet1..7 ---';
SELECT name, create_date
FROM sys.tables
WHERE schema_id = SCHEMA_ID('ags')
  AND name LIKE 'spMstrg_2408_ResultSet%'
ORDER BY name;
GO

PRINT '=== 00_VERIFY_before: завершено ===';
GO
