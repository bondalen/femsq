-- =============================================================================
-- 26-0928 ROLLBACK: снять UX/CK/колонку yr_upl_p_q
-- lastUpdated: 2026-09-28
-- =============================================================================

SET NOCOUNT ON;
GO

IF EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'sudz.yr_upl_p')
      AND name = N'UX_yr_upl_p_YrQ'
)
BEGIN
    ALTER TABLE sudz.yr_upl_p DROP CONSTRAINT UX_yr_upl_p_YrQ;
END
GO

IF EXISTS (
    SELECT 1 FROM sys.check_constraints
    WHERE parent_object_id = OBJECT_ID(N'sudz.yr_upl_p')
      AND name = N'CK_yr_upl_p_q'
)
BEGIN
    ALTER TABLE sudz.yr_upl_p DROP CONSTRAINT CK_yr_upl_p_q;
END
GO

IF COL_LENGTH(N'sudz.yr_upl_p', N'yr_upl_p_q') IS NOT NULL
BEGIN
    ALTER TABLE sudz.yr_upl_p DROP COLUMN yr_upl_p_q;
END
GO
