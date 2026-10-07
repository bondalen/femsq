/*
 * DEV (SQL Server 2016+): staging-ключи Excel→Tbl на sudz.CnInvPmtUplTbl (1.13.1).
 * lastUpdated: 2026-10-03
 */
SET NOCOUNT ON;
GO

IF COL_LENGTH(N'sudz.CnInvPmtUplTbl', N'ciputSfKey') IS NULL
BEGIN
    ALTER TABLE sudz.CnInvPmtUplTbl ADD ciputSfKey int NULL;
END
GO

IF COL_LENGTH(N'sudz.CnInvPmtUplTbl', N'ciputCacSpanKey') IS NULL
BEGIN
    ALTER TABLE sudz.CnInvPmtUplTbl ADD ciputCacSpanKey int NULL;
END
GO

IF COL_LENGTH(N'sudz.CnInvPmtUplTbl', N'ciputDueKey') IS NULL
BEGIN
    ALTER TABLE sudz.CnInvPmtUplTbl ADD ciputDueKey int NULL;
END
GO

IF COL_LENGTH(N'sudz.CnInvPmtUplTbl', N'ciputDueGrp') IS NULL
BEGIN
    ALTER TABLE sudz.CnInvPmtUplTbl ADD ciputDueGrp smallint NULL;
END
GO

SELECT c.name AS column_name, ty.name AS type_name, c.max_length, c.is_nullable
FROM sys.columns c
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE c.object_id = OBJECT_ID(N'sudz.CnInvPmtUplTbl')
  AND c.name IN (N'ciputSfKey', N'ciputCacSpanKey', N'ciputDueKey', N'ciputDueGrp')
ORDER BY c.column_id;
GO
