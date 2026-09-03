/*
 * S76 — сброс upl 901 для чистого apply воронки (без ручных SQL-fix).
 * Не трогает DbtValue@801–803 (stage1 PIT).
 * lastUpdated: 2026-09-01
 */
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRANSACTION;

DELETE FROM sudz.CnInvUplDbtP1 WHERE cip1UnloadKey = 901;

DELETE q
FROM sudz.CnInvUplInvDbtDouble AS q
INNER JOIN sudz.CnInvDbtUplTbl AS t ON t.cidutKey = q.ciudCidut
WHERE t.cidutUnloadKey = 901;

DELETE FROM sudz.DbtValue WHERE dvUpl = 901;

DELETE FROM sudz.CnInvDbtUplTbl WHERE cidutUnloadKey = 901;

/* B-seed (10_SEED): синтетические inv/Dbt вне Excel */
IF OBJECT_ID('tempdb..#seedIKey') IS NOT NULL DROP TABLE #seedIKey;
SELECT iKey INTO #seedIKey FROM ags.inv WHERE iNote = N'B-seed-access-q4-missing';

IF OBJECT_ID('tempdb..#seedInKey') IS NOT NULL DROP TABLE #seedInKey;
SELECT inKey INTO #seedInKey FROM ags.invNum WHERE inInv IN (SELECT iKey FROM #seedIKey);

DELETE bv
FROM sudz.invDbtDbtVar AS bv
INNER JOIN sudz.invDbt AS id ON id.idKey = bv.iddvInvDbt
WHERE id.idInv IN (SELECT iKey FROM #seedIKey);

DELETE bd
FROM sudz.invDbtDbt AS bd
INNER JOIN sudz.invDbt AS id ON id.idKey = bd.iddInvDbt
WHERE id.idInv IN (SELECT iKey FROM #seedIKey);

DELETE FROM sudz.invDbt WHERE idInv IN (SELECT iKey FROM #seedIKey);

DELETE FROM sudz.invDbtVar WHERE idvvInvNum IN (SELECT inKey FROM #seedInKey);

DELETE FROM sudz.Dbt WHERE dbtNote = N'B-seed-access-q4-missing';

DELETE FROM ags.cnInv WHERE ciInv IN (SELECT iKey FROM #seedIKey);
DELETE FROM ags.invNum WHERE inInv IN (SELECT iKey FROM #seedIKey);
DELETE FROM ags.inv WHERE iKey IN (SELECT iKey FROM #seedIKey);

UPDATE sudz.CnInvDbtUplFile
SET cidufFlTbl = 1, cidufFlLoad = 1
WHERE cidufUpload = 901;

COMMIT TRANSACTION;

SELECT COUNT(*) AS dv901 FROM sudz.DbtValue WHERE dvUpl = 901;
SELECT COUNT(*) AS tbl901 FROM sudz.CnInvDbtUplTbl WHERE cidutUnloadKey = 901;
SELECT cidufFlTbl, cidufFlLoad FROM sudz.CnInvDbtUplFile WHERE cidufUpload = 901;
GO
