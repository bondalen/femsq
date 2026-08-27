-- =============================================================================
-- A2-messages: ciudReasonDetail — универсальный текстовый канал по строке очереди
-- Первый наполнитель: [queue.build] при rebuild CnInvUplInvDbtDouble
-- DEV (SQL Server 2022 Docker). ags.* не изменяет.
-- =============================================================================

SET NOCOUNT ON;
GO

IF COL_LENGTH(N'sudz.CnInvUplInvDbtDouble', N'ciudReasonDetail') IS NULL
BEGIN
    ALTER TABLE sudz.CnInvUplInvDbtDouble
        ADD ciudReasonDetail nvarchar(max) NULL;
END
GO

-- VERIFY
SELECT c.name AS column_name, ty.name AS type_name, c.max_length, c.is_nullable
FROM sys.columns c
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE c.object_id = OBJECT_ID(N'sudz.CnInvUplInvDbtDouble')
  AND c.name IN (N'ciudReason', N'ciudReasonDetail')
ORDER BY c.column_id;
GO
