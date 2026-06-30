USE [FishEye];
GO

-- =============================================================================
-- Файл:    MSSQL2012/10b_CREATE_FUNCTION_fnCstAgPnTypeChar.sql
-- Пакет:   docs/development/notes/sql/26-0604/
-- Зеркало dev. Синхронизировано скриптом _sync_to_mssql2012.py
-- =============================================================================

PRINT N'=== 10b: CREATE FUNCTION ags.fnCstAgPnTypeChar ===';
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO


IF OBJECT_ID(N'ags.fnCstAgPnTypeChar', N'IF') IS NOT NULL
    DROP FUNCTION ags.fnCstAgPnTypeChar;
IF OBJECT_ID(N'ags.fnCstAgPnTypeChar', N'TF') IS NOT NULL
    DROP FUNCTION ags.fnCstAgPnTypeChar;
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
