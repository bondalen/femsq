USE [FishEye];
GO

-- =============================================================================
-- Файл:    10b_CREATE_FUNCTION_fnCstAgPnTypeChar.sql
-- Пакет:   docs/development/notes/sql/26-0604/
-- Назначение: 5-я литера кода САК (cstapIpgPnN) — тип стройки для OUT_GROUP.
--   '1' ПИР, '2' стройка (КС), '3' бурение (Решение 16, этап 19.1).
-- Предусловия: нет.
-- Следующий: 10c (seed stIpgOutLimPn).
-- Автор:   Александр
-- Дата:    2026-06-29
-- =============================================================================

PRINT N'=== 10b: CREATE FUNCTION ags.fnCstAgPnTypeChar ===';
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER FUNCTION ags.fnCstAgPnTypeChar(@cstapIpgPnN nvarchar(255))
RETURNS char(1)
AS
BEGIN
    IF @cstapIpgPnN IS NULL OR LEN(@cstapIpgPnN) < 5
        RETURN NULL;

    RETURN SUBSTRING(@cstapIpgPnN, 5, 1);
END;
GO

PRINT N'Функция ags.fnCstAgPnTypeChar создана.';
GO
