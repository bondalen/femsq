USE [FishEye];
GO

-- =============================================================================
-- Файл:    01b_RECREATE_fnIpgChRlEnd_2606.sql
-- Пакет:   docs/development/notes/sql/26-0604/
-- Назначение: После sp_rename (01b) пересоздать тело fnIpgChRlEnd_2606 и computed ipgcrvEnd.
-- Автор:   Александр | Дата: 2026-06-30
-- =============================================================================

PRINT N'=== 01b_RECREATE: fnIpgChRlEnd_2606 ===';
GO

IF COL_LENGTH(N'ags.ipgChRl_2606', N'ipgcrvEnd') IS NOT NULL
BEGIN
    PRINT N'DROP computed ipgcrvEnd';
    ALTER TABLE ags.ipgChRl_2606 DROP COLUMN ipgcrvEnd;
END;
GO

IF OBJECT_ID(N'ags.fnIpgChRlEnd_2606', N'FN') IS NOT NULL
    DROP FUNCTION ags.fnIpgChRlEnd_2606;
GO

CREATE FUNCTION ags.fnIpgChRlEnd_2606(@chain int, @str date)
RETURNS date
AS
BEGIN
    RETURN DATEADD(day, -1, (
        SELECT MIN(t.ipgcrvStr)
        FROM ags.ipgChRl_2606 t
        WHERE t.ipgcrvChain = @chain
          AND t.ipgcrvStr > @str
    ))
END;
GO

ALTER TABLE ags.ipgChRl_2606
    ADD ipgcrvEnd AS (ags.fnIpgChRlEnd_2606(ipgcrvChain, ipgcrvStr));
GO

PRINT N'=== 01b_RECREATE: завершено ===';
GO
