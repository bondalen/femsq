USE [FishEye]
GO

-- =============================================================================
-- Файл:    06_DROP_obsolete_2408.sql
-- Пакет:   docs/development/notes/sql/26-0508/
-- Назначение: Удаление устаревших объектов после полного перехода на _2605.
--
-- ВНИМАНИЕ: Выполнять ТОЛЬКО ПОСЛЕ:
--   1. Все тесты этапов 3–5 пройдены ✅
--   2. На продуктиве _2605-объекты применены и подтверждены
--   3. Access-форма Form_ipgChMin переключена на spMstrg_2605 и проверена
--   4. execute_spMstrg_2605.sh запущен и ResultSet-таблицы заполнены корректно
--
-- СЕКЦИЯ A — можно выполнять немедленно (промежуточные _ipgSt-варианты):
--   На dev FishEye этих объектов нет → IF EXISTS даёт no-op (безопасно).
--   На продуктиве (если были созданы) — будут удалены.
--
-- СЕКЦИЯ B — выполнять ТОЛЬКО после полного отказа от _2408 у всех клиентов:
--   spMstrg_2408 и spMstrg_2408_SaveToTables закомментированы.
--   Раскомментировать, когда Access и FEMSQ перешли на _2605 на продуктиве.
--
-- Создан:  2026-05-16
-- =============================================================================

PRINT '=== 06_DROP_obsolete_2408: удаление устаревших объектов ===';
PRINT 'Дата запуска: ' + CONVERT(nvarchar(30), GETDATE(), 121);
PRINT '';

-- =============================================================================
-- СЕКЦИЯ A: промежуточные _ipgSt-варианты (если существуют)
-- =============================================================================
PRINT '--- СЕКЦИЯ A: промежуточные _ipgSt-объекты ---';

-- A1. Процедуры _ipgSt
DROP PROCEDURE IF EXISTS [ags].[spMstrg_2408_SaveToTables_ipgSt];
GO
PRINT 'DROP (IF EXISTS): ags.spMstrg_2408_SaveToTables_ipgSt';
GO

DROP PROCEDURE IF EXISTS [ags].[spMstrg_2408_ipgSt];
GO
PRINT 'DROP (IF EXISTS): ags.spMstrg_2408_ipgSt';
GO

-- A2. Функции _ipgSt (в порядке зависимостей: сначала зависимая, потом базовая)
DROP FUNCTION IF EXISTS [ags].[fnIpgChRsltCstUtlPercentBrn_2408_ipgSt];
GO
PRINT 'DROP (IF EXISTS): ags.fnIpgChRsltCstUtlPercentBrn_2408_ipgSt';
GO

DROP FUNCTION IF EXISTS [ags].[fnIpgChRsltCstUtl2_2408_ipgSt];
GO
PRINT 'DROP (IF EXISTS): ags.fnIpgChRsltCstUtl2_2408_ipgSt';
GO

PRINT '';
PRINT '--- СЕКЦИЯ A завершена ---';
PRINT '';

-- =============================================================================
-- СЕКЦИЯ B: базовые _2408-объекты
-- Раскомментировать ТОЛЬКО после полного перехода на _2605 на продуктиве.
-- =============================================================================
PRINT '--- СЕКЦИЯ B: базовые _2408-объекты (ЗАКОММЕНТИРОВАНЫ) ---';
PRINT 'Для удаления раскомментировать после подтверждения на продуктиве.';
PRINT '';

/*
-- B1. Процедуры (зависят от функций — удаляем первыми)
DROP PROCEDURE IF EXISTS [ags].[spMstrg_2408_SaveToTables];
GO
PRINT 'DROP: ags.spMstrg_2408_SaveToTables';
GO

DROP PROCEDURE IF EXISTS [ags].[spMstrg_2408];
GO
PRINT 'DROP: ags.spMstrg_2408';
GO

-- B2. Функции (в порядке зависимостей)
DROP FUNCTION IF EXISTS [ags].[fnIpgChRsltCstUtlPercentBrn_2408];
GO
PRINT 'DROP: ags.fnIpgChRsltCstUtlPercentBrn_2408';
GO

DROP FUNCTION IF EXISTS [ags].[fnIpgChRsltCstUtl2_2408];
GO
PRINT 'DROP: ags.fnIpgChRsltCstUtl2_2408';
GO
*/

-- =============================================================================
-- Итоговая проверка: _2605-объекты должны существовать
-- =============================================================================
PRINT '--- Проверка: _2605-объекты живы ---';

SELECT
    name,
    type_desc,
    CONVERT(varchar(10), modify_date, 23) AS modified
FROM sys.objects
WHERE schema_id = SCHEMA_ID('ags')
  AND name IN (
    'fnIpgChRsltCstUtl2_2605',
    'fnIpgChRsltCstUtlPercentBrn_2605',
    'spMstrg_2605'
  )
ORDER BY name;
GO

PRINT '';
PRINT '=== 06_DROP_obsolete_2408: завершено ===';
GO
