USE [FishEye]
GO

-- =============================================================================
-- Файл:    05_ROLLBACK.sql
-- Пакет:   docs/development/notes/sql/26-0508/
-- Назначение: Откат всех объектов серии _2605 (удаление в обратном порядке).
--
-- Порядок применения: ТОЛЬКО если необходимо отменить изменения.
-- Выполнять ПОСЛЕ проверки, что клиенты (Access, FEMSQ) не используют _2605.
--
-- Создан:  2026-05-16
-- =============================================================================

-- 3. Процедура (зависит от функций)
DROP PROCEDURE IF EXISTS [ags].[spMstrg_2605];
GO
PRINT 'DROP: ags.spMstrg_2605'
GO

-- 2. Вторая функция (зависит от первой)
DROP FUNCTION IF EXISTS [ags].[fnIpgChRsltCstUtlPercentBrn_2605];
GO
PRINT 'DROP: ags.fnIpgChRsltCstUtlPercentBrn_2605'
GO

-- 1. Первая функция
DROP FUNCTION IF EXISTS [ags].[fnIpgChRsltCstUtl2_2605];
GO
PRINT 'DROP: ags.fnIpgChRsltCstUtl2_2605'
GO

PRINT 'Откат _2605 завершён'
GO
