USE [FishEye];
GO

-- =============================================================================
-- Файл:    MSSQL2012/10b_CREATE_FUNCTION_fnCstAgPnTypeChar.sql
-- Пакет:   docs/development/notes/sql/26-0604/
-- Назначение: 5-я литера кода САК — тип стройки для OUT_GROUP (Решение 16).
--   Совместимость: SQL Server 2012 SP4 (11.0.7507.2).
-- Автор:   Александр
-- Дата:    2026-06-29
-- =============================================================================

PRINT N'=== 10b MSSQL2012: CREATE FUNCTION ags.fnCstAgPnTypeChar ===';
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'ags.fnCstAgPnTypeChar', N'FN') IS NOT NULL
    DROP FUNCTION ags.fnCstAgPnTypeChar;
GO

CREATE FUNCTION ags.fnCstAgPnTypeChar(@cstapIpgPnN nvarchar(255))
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
