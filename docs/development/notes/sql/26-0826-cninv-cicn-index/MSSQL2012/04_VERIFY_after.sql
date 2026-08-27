-- VERIFY after: IX_cnInv_ciCn
SET NOCOUNT ON;

SELECT i.name AS index_name,
       COL_NAME(ic.object_id, ic.column_id) AS col,
       ic.key_ordinal,
       ic.is_included_column
FROM sys.indexes i
JOIN sys.index_columns ic
  ON i.object_id = ic.object_id AND i.index_id = ic.index_id
WHERE i.object_id = OBJECT_ID(N'ags.cnInv')
  AND i.name = N'IX_cnInv_ciCn'
ORDER BY ic.key_ordinal, ic.is_included_column, col;
GO
