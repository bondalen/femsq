-- =============================================================================
-- cidufOpsProgress (MSSQL 2012 SP4) — зеркало DEV
-- lastUpdated: 2026-09-19
-- =============================================================================

SET NOCOUNT ON;
GO

IF COL_LENGTH(N'sudz.CnInvDbtUplFile', N'cidufOpsProgress') IS NULL
BEGIN
    ALTER TABLE sudz.CnInvDbtUplFile
        ADD cidufOpsProgress nvarchar(max) NULL;
END
GO

SELECT c.name AS column_name, ty.name AS type_name, c.max_length, c.is_nullable
FROM sys.columns c
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE c.object_id = OBJECT_ID(N'sudz.CnInvDbtUplFile')
  AND c.name IN (N'cidufLoadingProgress', N'cidufOpsProgress')
ORDER BY c.column_id;
GO
