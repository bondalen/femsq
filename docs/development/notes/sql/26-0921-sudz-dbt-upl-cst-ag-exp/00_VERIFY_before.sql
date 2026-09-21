-- 00_VERIFY_before.sql — эксперимент DbtUplCstAgExp (S83 / 0921)
-- Target: FishEye; package_compat = SQL Server 2012 SP4
SET NOCOUNT ON;

SELECT
  @@VERSION AS sql_version,
  CAST(SERVERPROPERTY(N'ProductVersion') AS nvarchar(128)) AS product_version,
  CAST(DATABASEPROPERTYEX(DB_NAME(), N'CompatibilityLevel') AS int) AS compat_level;

SELECT
  CASE WHEN OBJECT_ID(N'sudz.DbtUplCstAg', N'U') IS NULL THEN N'missing' ELSE N'exists' END AS DbtUplCstAg,
  CASE WHEN OBJECT_ID(N'sudz.DbtUplCstAgExp', N'U') IS NULL THEN N'missing' ELSE N'exists' END AS DbtUplCstAgExp,
  CASE WHEN OBJECT_ID(N'sudz.usp_RebuildDbtUplCstAgExp', N'P') IS NULL THEN N'missing' ELSE N'exists' END AS usp_RebuildDbtUplCstAgExp,
  CASE WHEN OBJECT_ID(N'sudz.cn_inv_dbt_upl_g_p', N'U') IS NULL THEN N'missing' ELSE N'exists' END AS g_p;
