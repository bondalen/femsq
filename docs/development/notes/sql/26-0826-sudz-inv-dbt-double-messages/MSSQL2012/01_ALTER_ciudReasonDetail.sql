-- =============================================================================
-- A2-messages: ciudReasonDetail (MSSQL 2012 SP4) — зеркало DEV-скрипта
-- =============================================================================

SET NOCOUNT ON;
GO

IF COL_LENGTH(N'sudz.CnInvUplInvDbtDouble', N'ciudReasonDetail') IS NULL
BEGIN
    ALTER TABLE sudz.CnInvUplInvDbtDouble
        ADD ciudReasonDetail nvarchar(max) NULL;
END
GO

SELECT c.name AS column_name, ty.name AS type_name, c.max_length, c.is_nullable
FROM sys.columns c
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE c.object_id = OBJECT_ID(N'sudz.CnInvUplInvDbtDouble')
  AND c.name IN (N'ciudReason', N'ciudReasonDetail')
ORDER BY c.column_id;
GO
