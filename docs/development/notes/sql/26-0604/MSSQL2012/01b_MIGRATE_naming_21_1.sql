USE [FishEye];
GO

-- =============================================================================
-- Файл:    MSSQL2012/01b_MIGRATE_naming_21_1.sql
-- Пакет:   docs/development/notes/sql/26-0604/
-- Назначение: Переименование объектов этапа 21.1 (SQL Server 2012 SP4).
--   Зеркало ../01b_MIGRATE_naming_21_1.sql
-- Автор:   Александр
-- Дата:    2026-06-30
-- =============================================================================

PRINT N'=== 01b MSSQL2012: MIGRATE naming 21.1 ===';
GO

IF OBJECT_ID(N'ags.ipgChRl_2606', N'U') IS NOT NULL
    PRINT N'ags.ipgChRl_2606 уже существует — шаг 1 пропущен.';
ELSE IF OBJECT_ID(N'ags.ipgChRlV', N'U') IS NOT NULL
BEGIN
    IF COL_LENGTH(N'ags.ipgChRlV', N'ipgcrvEnd') IS NOT NULL
        ALTER TABLE ags.ipgChRlV DROP COLUMN ipgcrvEnd;

    IF OBJECT_ID(N'ags.fnIpgChRlVEnd', N'FN') IS NOT NULL
        EXEC sp_rename N'ags.fnIpgChRlVEnd', N'fnIpgChRlEnd_2606', N'OBJECT';

    EXEC sp_rename N'ags.ipgChRlV', N'ipgChRl_2606', N'OBJECT';

    ALTER TABLE ags.ipgChRl_2606
        ADD ipgcrvEnd AS (ags.fnIpgChRlEnd_2606(ipgcrvChain, ipgcrvStr));
END
GO

IF OBJECT_ID(N'ags.fnIpgChDats_2606', N'IF') IS NULL
   AND OBJECT_ID(N'ags.fnIpgChDatsV', N'IF') IS NOT NULL
    EXEC sp_rename N'ags.fnIpgChDatsV', N'fnIpgChDats_2606', N'OBJECT';
GO

IF OBJECT_ID(N'ags.stIpgOutLimPn_2606', N'U') IS NULL
   AND OBJECT_ID(N'ags.stIpgOutLimPn', N'U') IS NOT NULL
    EXEC sp_rename N'ags.stIpgOutLimPn', N'stIpgOutLimPn_2606', N'OBJECT';
GO

PRINT N'=== 01b MSSQL2012: завершено ===';
GO
