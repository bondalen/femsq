-- VERIFY before: индекс IX_cnInv_ciCn
SET NOCOUNT ON;

SELECT @@VERSION AS sql_version;

SELECT name, compatibility_level
FROM sys.databases
WHERE name = DB_NAME();

SELECT i.name AS index_name, i.type_desc
FROM sys.indexes i
WHERE i.object_id = OBJECT_ID(N'ags.cnInv')
ORDER BY i.name;
GO
