-- =============================================================================
-- cn_inv_pm_due_grp (MSSQL 2012 SP4) — зеркало DEV / 1.13.2
-- lastUpdated: 2026-10-03
-- =============================================================================

SET NOCOUNT ON;
GO

IF COL_LENGTH(N'ags.cn_inv_pm', N'cn_inv_pm_due_grp') IS NULL
BEGIN
    ALTER TABLE ags.cn_inv_pm ADD cn_inv_pm_due_grp smallint NULL;
END
GO

SELECT c.name AS column_name, ty.name AS type_name, c.is_nullable
FROM sys.columns c
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE c.object_id = OBJECT_ID(N'ags.cn_inv_pm')
  AND c.name = N'cn_inv_pm_due_grp';
GO
