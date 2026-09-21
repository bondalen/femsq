-- 05_ROLLBACK.sql — DEV only: снять эксперимент (канон не трогать)
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF OBJECT_ID(N'sudz.vw_Yr_DbtFactExp', N'V') IS NOT NULL
    DROP VIEW sudz.vw_Yr_DbtFactExp;
GO

IF OBJECT_ID(N'sudz.usp_RebuildDbtUplCstAgExp', N'P') IS NOT NULL
    DROP PROCEDURE sudz.usp_RebuildDbtUplCstAgExp;
GO

IF OBJECT_ID(N'sudz.DbtUplCstAgExp', N'U') IS NOT NULL
    DROP TABLE sudz.DbtUplCstAgExp;
GO

SELECT
  CASE WHEN OBJECT_ID(N'sudz.vw_Yr_DbtFactExp', N'V') IS NULL THEN N'dropped' ELSE N'still exists' END AS vw_Yr_DbtFactExp,
  CASE WHEN OBJECT_ID(N'sudz.DbtUplCstAgExp', N'U') IS NULL THEN N'dropped' ELSE N'still exists' END AS DbtUplCstAgExp,
  CASE WHEN OBJECT_ID(N'sudz.usp_RebuildDbtUplCstAgExp', N'P') IS NULL THEN N'dropped' ELSE N'still exists' END AS usp,
  CASE WHEN OBJECT_ID(N'sudz.DbtUplCstAg', N'U') IS NULL THEN N'missing' ELSE N'exists' END AS canon_DbtUplCstAg;
