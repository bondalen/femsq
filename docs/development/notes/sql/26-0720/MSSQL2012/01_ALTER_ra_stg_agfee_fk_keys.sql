-- =============================================================================
-- Файл:    MSSQL2012/01_ALTER_ra_stg_agfee_fk_keys.sql
-- Пакет:   docs/development/notes/sql/26-0720/
-- Назначение: ключи агента/стройки в staging type=6 (Stage 2a)
-- Совместимость: SQL Server 2012 SP4 (продуктив)
-- =============================================================================

PRINT '=== 01_ALTER: oafptOafSenderKey / oafptPnCstAgPnKey ===';

IF COL_LENGTH(N'ags.ra_stg_agfee', N'oafptOafSenderKey') IS NULL
BEGIN
    ALTER TABLE ags.ra_stg_agfee
        ADD oafptOafSenderKey INT NULL;
    PRINT 'Added ags.ra_stg_agfee.oafptOafSenderKey';
END
ELSE
    PRINT 'Skip: ags.ra_stg_agfee.oafptOafSenderKey already exists';

IF COL_LENGTH(N'ags.ra_stg_agfee', N'oafptPnCstAgPnKey') IS NULL
BEGIN
    ALTER TABLE ags.ra_stg_agfee
        ADD oafptPnCstAgPnKey INT NULL;
    PRINT 'Added ags.ra_stg_agfee.oafptPnCstAgPnKey';
END
ELSE
    PRINT 'Skip: ags.ra_stg_agfee.oafptPnCstAgPnKey already exists';

PRINT '=== 01_ALTER: готово ===';
