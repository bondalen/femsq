-- S68 VERIFY before: окружение и зависимости staging
SET NOCOUNT ON;

SELECT @@VERSION AS sql_version;

SELECT name, compatibility_level
FROM sys.databases
WHERE name = DB_NAME();

SELECT s.name AS schema_name, t.name AS table_name
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE s.name = N'sudz'
  AND t.name IN (
      N'CnInvDbtUplTbl', N'CnInvPmtUplTbl',
      N'CnInvDbtUplFile', N'CnInvPmtUplFile',
      N'CnInvUplSfDouble', N'CnInvDbtUplFileInvDouble'
  )
ORDER BY t.name;
GO
