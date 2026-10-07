-- =============================================================================
-- ROLLBACK cn_inv_pm_due_grp (MSSQL 2012 SP4)
-- lastUpdated: 2026-10-03
-- =============================================================================

SET NOCOUNT ON;
GO

IF COL_LENGTH(N'ags.cn_inv_pm', N'cn_inv_pm_due_grp') IS NOT NULL
    ALTER TABLE ags.cn_inv_pm DROP COLUMN cn_inv_pm_due_grp;
GO
