USE [FishEye]
GO

-- =============================================================================
-- Файл:    02_CREATE_FUNCTION_fnIpgChRsltCstUtlPercentBrn_2605.sql
-- Пакет:   docs/development/notes/sql/26-0508/MSSQL2012/
-- Версия: SQL Server 2012 SP4+
-- Объект:  ags.fnIpgChRsltCstUtlPercentBrn_2605
--
-- Назначение: Multi-statement TVF — полный набор данных для отчётов по освоению
--             лимитов по стройкам. Параметр @ipgSt обеспечивает опциональную
--             фильтрацию по группе строек (NULL = все стройки).
--
-- Метод создания: трансформация OBJECT_DEFINITION(fnIpgChRsltCstUtlPercentBrn_2408)
--   с тремя заменами:
--   1. Имя функции: _2408 → _2605 (CREATE)
--   2. Параметры: добавлен @ipgSt nvarchar(255) = NULL
--   3. FROM-строка: fnIpgChRsltCstUtl2_2408(@ipgChKey) → fnIpgChRsltCstUtl2_2605(@ipgChKey, @ipgSt)
--
-- Зависимости:
--   - ags.fnIpgChRsltCstUtl2_2605  (должна существовать, создаётся скриптом 01_*)
--
-- Применимость: SQL Server 2012 SP4+
--   Перед CREATE: DROP существующей функции.
--   Откат: DROP FUNCTION [ags].[fnIpgChRsltCstUtlPercentBrn_2605]
--
-- Проверка перед запуском:
--   - Скрипт 01_CREATE_FUNCTION_fnIpgChRsltCstUtl2_2605.sql уже выполнен
--   - ags.fnIpgChRsltCstUtlPercentBrn_2408 существует (является источником)
--
-- Автор:   ANB / рефакторинг _2605
-- Создан:  2026-05-16
-- =============================================================================

SET NOCOUNT ON;
GO

-- Идемпотентность: удалить предыдущую версию (отдельный batch)
IF OBJECT_ID(N'ags.fnIpgChRsltCstUtlPercentBrn_2605', N'IF') IS NOT NULL
    DROP FUNCTION [ags].[fnIpgChRsltCstUtlPercentBrn_2605];
GO

-- Получить определение _2408, применить 3 замены, создать _2605
DECLARE @def nvarchar(max) = OBJECT_DEFINITION(OBJECT_ID('ags.fnIpgChRsltCstUtlPercentBrn_2408'));

IF @def IS NULL
BEGIN
    RAISERROR('ОШИБКА: ags.fnIpgChRsltCstUtlPercentBrn_2408 не найдена в базе данных.', 16, 1);
    RETURN;
END

-- 1. Сменить имя
SET @def = REPLACE(@def,
    'CREATE FUNCTION [ags].[fnIpgChRsltCstUtlPercentBrn_2408]',
    'CREATE FUNCTION [ags].[fnIpgChRsltCstUtlPercentBrn_2605]');

-- 2. Добавить параметр @ipgSt после @ipgChKey
SET @def = REPLACE(@def,
    N'@ipgChKey int -- цепочка инвестпрограмм',
    N'@ipgChKey int,         -- цепочка инвестпрограмм' + CHAR(13) + CHAR(10)
    + CHAR(9) + N'@ipgSt     nvarchar(255) = NULL  -- пункт структуры инвестпрограммы (NULL = без фильтра)');

-- 3. Заменить вызов базовой функции
SET @def = REPLACE(@def,
    N'from ags.fnIpgChRsltCstUtl2_2408 (@ipgChKey) t',
    N'from ags.fnIpgChRsltCstUtl2_2605(@ipgChKey, @ipgSt) t');

-- Контроль: убедиться что все замены применились
IF @def NOT LIKE N'%fnIpgChRsltCstUtlPercentBrn_2605%'
   OR @def NOT LIKE N'%@ipgSt%'
   OR @def NOT LIKE N'%fnIpgChRsltCstUtl2_2605%'
BEGIN
    RAISERROR('ОШИБКА: одна или несколько замен не применились. Проверьте исходный объект.', 16, 1);
    RETURN;
END

EXEC sp_executesql @def;
GO

PRINT 'OK: ags.fnIpgChRsltCstUtlPercentBrn_2605 создана/обновлена'
GO
