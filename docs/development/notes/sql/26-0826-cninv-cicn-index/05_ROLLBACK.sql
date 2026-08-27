-- ROLLBACK: IX_cnInv_ciCn
SET NOCOUNT ON;

IF EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'ags.cnInv')
      AND name = N'IX_cnInv_ciCn'
)
BEGIN
    DROP INDEX IX_cnInv_ciCn ON ags.cnInv;
END
GO
