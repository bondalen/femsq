-- 04_VERIFY_after.sql
SET NOCOUNT ON;

SELECT
  CASE WHEN OBJECT_ID(N'sudz.DbtUplCstAgExp', N'U') IS NULL THEN N'missing' ELSE N'exists' END AS DbtUplCstAgExp,
  CASE WHEN OBJECT_ID(N'sudz.usp_RebuildDbtUplCstAgExp', N'P') IS NULL THEN N'missing' ELSE N'exists' END AS usp_RebuildDbtUplCstAgExp;

SELECT duexRule, COUNT(*) AS n
FROM sudz.DbtUplCstAgExp
GROUP BY duexRule
ORDER BY duexRule;
