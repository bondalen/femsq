/*
 * ROLLBACK: staging-ключи CnInvPmtUplTbl (1.13.1).
 * lastUpdated: 2026-10-03
 */
SET NOCOUNT ON;
GO

IF COL_LENGTH(N'sudz.CnInvPmtUplTbl', N'ciputDueGrp') IS NOT NULL
    ALTER TABLE sudz.CnInvPmtUplTbl DROP COLUMN ciputDueGrp;
GO

IF COL_LENGTH(N'sudz.CnInvPmtUplTbl', N'ciputDueKey') IS NOT NULL
    ALTER TABLE sudz.CnInvPmtUplTbl DROP COLUMN ciputDueKey;
GO

IF COL_LENGTH(N'sudz.CnInvPmtUplTbl', N'ciputCacSpanKey') IS NOT NULL
    ALTER TABLE sudz.CnInvPmtUplTbl DROP COLUMN ciputCacSpanKey;
GO

IF COL_LENGTH(N'sudz.CnInvPmtUplTbl', N'ciputSfKey') IS NOT NULL
    ALTER TABLE sudz.CnInvPmtUplTbl DROP COLUMN ciputSfKey;
GO
