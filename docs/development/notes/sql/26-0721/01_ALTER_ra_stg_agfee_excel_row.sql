-- =============================================================================
-- 26-0721 / 0056: номер Excel-строки в staging type=6 (AgFee)
-- Целевая платформа: abs (SQL Server 2022) и syntax-совместимо с 2012+
-- =============================================================================
PRINT '=== 01_ALTER: oafptRow ===';

IF COL_LENGTH(N'ags.ra_stg_agfee', N'oafptRow') IS NULL
BEGIN
    ALTER TABLE ags.ra_stg_agfee
        ADD oafptRow INT NULL;
    PRINT 'Added ags.ra_stg_agfee.oafptRow';
END
ELSE
    PRINT 'Skip: ags.ra_stg_agfee.oafptRow already exists';
GO
