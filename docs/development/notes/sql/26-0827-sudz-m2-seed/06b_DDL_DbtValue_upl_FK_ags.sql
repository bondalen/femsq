/*
 * M2 — DbtValue.dvUpl → ags.cn_inv_dbt_upl (E1 из ags.cn_inv_dbt)
 * Было: FK_DbtValue_upl_test → sudz.cn_inv_dbt_upl (песочница).
 * lastUpdated: 2026-08-27
 */
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

IF EXISTS (
    SELECT 1 FROM sys.foreign_keys
    WHERE name = N'FK_DbtValue_upl_test'
      AND parent_object_id = OBJECT_ID(N'sudz.DbtValue')
)
    ALTER TABLE sudz.DbtValue DROP CONSTRAINT FK_DbtValue_upl_test;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys
    WHERE name = N'FK_DbtValue_upl'
      AND parent_object_id = OBJECT_ID(N'sudz.DbtValue')
)
BEGIN
    ALTER TABLE sudz.DbtValue
        ADD CONSTRAINT FK_DbtValue_upl FOREIGN KEY (dvUpl)
            REFERENCES ags.cn_inv_dbt_upl (upl_key);
    PRINT N'FK_DbtValue_upl → ags.cn_inv_dbt_upl';
END
ELSE
    PRINT N'FK_DbtValue_upl already present';
GO
