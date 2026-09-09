/*
 * S77.7 / C.10.4 — сброс upl 902 для чистого UI-прогона gate'ов (после premature C.9).
 * Не трогает DbtValue@901 и очереди 901.
 * Path Excel = «НОВЫЙ» QI на шаре (как в CnInvDbtUplFile после S76).
 * lastUpdated: 2026-09-09
 */
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRANSACTION;

DELETE FROM sudz.CnInvUplDbtP1 WHERE cip1UnloadKey = 902;

DELETE FROM sudz.CnInvUplSfDouble WHERE ciusUnloadKey = 902;

DELETE q
FROM sudz.CnInvUplInvDbtDouble AS q
WHERE q.ciudUnloadKey = 902
   OR EXISTS (
        SELECT 1 FROM sudz.CnInvDbtUplTbl AS t
        WHERE t.cidutKey = q.ciudCidut AND t.cidutUnloadKey = 902
      );

DELETE FROM sudz.DbtValue WHERE dvUpl = 902;

DELETE FROM sudz.CnInvDbtUplTbl WHERE cidutUnloadKey = 902;

UPDATE sudz.CnInvDbtUplFile
SET cidufFlTbl = 1,
    cidufFlLoad = 1,
    cidufPath = N'D:\wire-guard-share-nb-win\femsq\excel\2026_03\debit\Дт Задолженность на 31.03.2026 (Общий свод) -НОВЫЙ.xlsx'
WHERE cidufUpload = 902;

COMMIT TRANSACTION;

SELECT COUNT(*) AS dv902 FROM sudz.DbtValue WHERE dvUpl = 902;
SELECT COUNT(*) AS tbl902 FROM sudz.CnInvDbtUplTbl WHERE cidutUnloadKey = 902;
SELECT COUNT(*) AS g4open902
FROM sudz.CnInvUplInvDbtDouble
WHERE ciudUnloadKey = 902 AND ciudStatus = N'open';
SELECT cidufFlTbl, cidufFlLoad, cidufPath
FROM sudz.CnInvDbtUplFile
WHERE cidufUpload = 902;
GO
