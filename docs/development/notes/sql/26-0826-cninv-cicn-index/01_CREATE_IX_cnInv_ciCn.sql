-- DEV: индекс для page cnInv по договору (ciCn)
SET NOCOUNT ON;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'ags.cnInv')
      AND name = N'IX_cnInv_ciCn'
)
BEGIN
    CREATE NONCLUSTERED INDEX IX_cnInv_ciCn
        ON ags.cnInv (ciCn)
        INCLUDE (ciInv, ciTimeOfEntry);
END
GO
