-- =============================================================================
-- 26-0721 / MSSQL2012 / 0056: номер Excel-строки в staging type=6 (AgFee)
-- Продуктив: SQL Server 2012 SP4 — без CREATE OR ALTER / DROP IF EXISTS
-- =============================================================================
PRINT '=== 01_ALTER: oafptRow (MSSQL2012) ===';

IF COL_LENGTH(N'ags.ra_stg_agfee', N'oafptRow') IS NULL
BEGIN
    ALTER TABLE ags.ra_stg_agfee
        ADD oafptRow INT NULL;
    PRINT 'Added ags.ra_stg_agfee.oafptRow';
END
ELSE
    PRINT 'Skip: ags.ra_stg_agfee.oafptRow already exists';
GO
