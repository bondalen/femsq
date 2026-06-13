USE [FishEye];
GO

-- =============================================================================
-- Файл:    05_CREATE_FUNCTION_fnIpgChRsltCstUtlPercentBrn_2606.sql
-- Пакет:   docs/development/notes/sql/26-0604/
-- Назначение: PercentBrn / будущий RS1 — на базе fn2_2606.
--   Трансформация OBJECT_DEFINITION(_2605): fn2_2605 → fn2_2606, @ipgSt → @ipgStKey/@stCostKey.
-- Предусловия: 04 (fnIpgChRsltCstUtl2_2606), fnIpgChRsltCstUtlPercentBrn_2605.
-- Автор:   Александр
-- Дата:    2026-06-09
-- =============================================================================

PRINT N'=== 05: CREATE FUNCTION ags.fnIpgChRsltCstUtlPercentBrn_2606 ===';
GO

SET NOCOUNT ON;
GO

IF OBJECT_ID(N'ags.fnIpgChRsltCstUtlPercentBrn_2606', N'IF') IS NOT NULL
    DROP FUNCTION ags.fnIpgChRsltCstUtlPercentBrn_2606;
GO

DECLARE @def nvarchar(max) = OBJECT_DEFINITION(OBJECT_ID(N'ags.fnIpgChRsltCstUtlPercentBrn_2605'));

IF @def IS NULL
BEGIN
    RAISERROR(N'ОШИБКА: ags.fnIpgChRsltCstUtlPercentBrn_2605 не найдена.', 16, 1);
    RETURN;
END

-- 1. Имя функции
SET @def = REPLACE(@def, N'fnIpgChRsltCstUtlPercentBrn_2605', N'fnIpgChRsltCstUtlPercentBrn_2606');

-- 2. Параметры: @ipgSt → @ipgStKey + @stCostKey
SET @def = REPLACE(@def,
    N'@ipgSt     nvarchar(255) = NULL  -- пункт структуры инвестпрограммы (NULL = без фильтра)',
    N'@ipgStKey   int = NULL,  -- узел stIpg (NULL = все разделы)' + CHAR(13) + CHAR(10)
    + CHAR(9) + N'@stCostKey int = NULL   -- пункт stCost (NULL = все статьи)');

-- 3. Вызов fn2
SET @def = REPLACE(@def,
    N'from ags.fnIpgChRsltCstUtl2_2605(@ipgChKey, @ipgSt) t',
    N'from ags.fnIpgChRsltCstUtl2_2606(@ipgChKey, @ipgStKey, @stCostKey) t');

IF @def NOT LIKE N'%fnIpgChRsltCstUtlPercentBrn_2606%'
   OR @def NOT LIKE N'%@ipgStKey%'
   OR @def NOT LIKE N'%fnIpgChRsltCstUtl2_2606%'
BEGIN
    RAISERROR(N'ОШИБКА: замены в PercentBrn_2606 не применились.', 16, 1);
    RETURN;
END

EXEC sp_executesql @def;
GO

PRINT N'=== 05: fnIpgChRsltCstUtlPercentBrn_2606 создана ===';
GO
