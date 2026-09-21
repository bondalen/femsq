-- 11_SMOKE_P1_903.sql — rebuild @903 + корзины A/B/C + сверка A с бывшим каноном-ключом
SET NOCOUNT ON;
GO

EXEC sudz.usp_RebuildDbtUplCstAg @dbtUpl = 903;
GO

SELECT
    SUM(CASE WHEN ducaCstAgPn IS NOT NULL THEN 1 ELSE 0 END) AS cntA,
    SUM(CASE WHEN ducaCstAgPn IS NULL AND ducaCode LIKE N'кодов -%' THEN 1 ELSE 0 END) AS cntB,
    SUM(CASE WHEN ducaCode = N'не обнаружена в платежах' THEN 1 ELSE 0 END) AS cntC,
    COUNT(*) AS nAll
FROM sudz.DbtUplCstAg
WHERE ducaUpl = 903;
GO

SELECT TOP 10 ducaDbt, ducaCstAgPn, ducaCode, LEFT(ducaName, 80) AS nm
FROM sudz.DbtUplCstAg
WHERE ducaUpl = 903 AND ducaCode LIKE N'кодов -%'
ORDER BY ducaDbt;
GO

SELECT TOP 5 ducaDbt, ducaCode, ducaName
FROM sudz.DbtUplCstAg
WHERE ducaUpl = 903 AND ducaCode = N'не обнаружена в платежах'
ORDER BY ducaDbt;
GO
