-- 00_VERIFY_before.sql — словарь FIO для краткого отчёта (БП 1.1.1.0)
-- Target: FishEye; prod package_compat = SQL Server 2012 SP4
SET NOCOUNT ON;

SELECT
  @@VERSION AS sql_version,
  CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(128)) AS product_version,
  CAST(DATABASEPROPERTYEX(DB_NAME(), 'CompatibilityLevel') AS int) AS compat_level;

SELECT
  CASE WHEN OBJECT_ID(N'ags.fioDict', N'U') IS NULL THEN N'missing' ELSE N'exists' END AS fioDict_table,
  CASE WHEN OBJECT_ID(N'ags.v_fioDictWord', N'V') IS NULL THEN N'missing' ELSE N'exists' END AS fioDict_word_view;
