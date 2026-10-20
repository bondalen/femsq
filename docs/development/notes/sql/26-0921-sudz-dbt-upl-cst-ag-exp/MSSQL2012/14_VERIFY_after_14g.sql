-- MSSQL2012: после 12 (usp 14g) + 13 (backfill docBase) + rebuild Duca
-- Ожидание DEV-эталона 1019: conflict QIV/QI к 26-0505 = 0 (жёсткие классы).
SET NOCOUNT ON;

SELECT
    SERVERPROPERTY(N'ProductVersion') AS productVersion,
    @@VERSION AS fullVersion;

-- процедура на месте
SELECT OBJECT_ID(N'sudz.usp_RebuildDbtUplCstAg', N'P') AS uspId;

-- A/B/C по кварталам (типично после 14g+1.8)
SELECT
    ducaUpl,
    SUM(CASE WHEN ducaCstAgPn IS NOT NULL THEN 1 ELSE 0 END) AS cntA,
    SUM(CASE WHEN ducaCstAgPn IS NULL AND ducaCode LIKE N'кодов -%' THEN 1 ELSE 0 END) AS cntB,
    SUM(CASE WHEN ducaCode = N'не обнаружена в платежах' THEN 1 ELSE 0 END) AS cntC,
    COUNT(*) AS n
FROM sudz.DbtUplCstAg
WHERE ducaUpl IN (901, 902, 903)
GROUP BY ducaUpl
ORDER BY ducaUpl;

-- контроль трёх кейсов QI (после backfill docBase)
SELECT idd.iddDbt, dv.dvUpl, dv.dvDocBase, duca.ducaCode
FROM sudz.invDbtDbt AS idd
JOIN sudz.DbtValue AS dv ON dv.dvInvDbt = idd.iddInvDbt AND dv.dvUpl IN (901, 902)
LEFT JOIN sudz.DbtUplCstAg AS duca ON duca.ducaDbt = idd.iddDbt AND duca.ducaUpl = dv.dvUpl
WHERE idd.iddDbt IN (11925, 11932, 12407, 3672, 4086, 8655)
ORDER BY idd.iddDbt, dv.dvUpl;

-- доля Value, где docBase = CnInv при непустом CnInv в Tbl (выборка)
SELECT TOP 20
    dv.dvUpl, dv.dvDocBase, t.cidutCnInv, t.cidutDoc
FROM sudz.DbtValue AS dv
JOIN sudz.invDbt AS id ON id.idKey = dv.dvInvDbt
JOIN ags.invNum AS n ON n.inInv = id.idInv
JOIN sudz.CnInvDbtUplTbl AS t
  ON t.cidutUnloadKey = dv.dvUpl
 AND LTRIM(RTRIM(ISNULL(t.cidutCnInv, N''))) = n.inNumNull
 AND CAST(COALESCE(t.cidutDebt, 0) AS decimal(19, 4)) = CAST(COALESCE(dv.dvTtl, 0) AS decimal(19, 4))
WHERE dv.dvUpl = 902
  AND NULLIF(LTRIM(RTRIM(t.cidutDoc)), N'') IS NOT NULL
  AND LTRIM(RTRIM(t.cidutDoc)) <> LTRIM(RTRIM(t.cidutCnInv))
ORDER BY dv.dvKey;
GO
