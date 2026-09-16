/*
 * C.10.6 / QII — сброс upl 903 для чистого UI-прогона (как 12_RESET_upl902).
 * Не трогает DbtValue@901/@902 и очереди 901/902.
 * Path Excel = «НОВЫЙ» QII на шаре.
 * lastUpdated: 2026-09-15
 */
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRANSACTION;

DELETE FROM sudz.CnInvUplDbtP1 WHERE cip1UnloadKey = 903;

DELETE FROM sudz.CnInvUplSfDouble WHERE ciusUnloadKey = 903;

DELETE q
FROM sudz.CnInvUplInvDbtDouble AS q
WHERE q.ciudUnloadKey = 903
   OR EXISTS (
        SELECT 1 FROM sudz.CnInvDbtUplTbl AS t
        WHERE t.cidutKey = q.ciudCidut AND t.cidutUnloadKey = 903
      );

DELETE FROM sudz.DbtValue WHERE dvUpl = 903;

DELETE FROM sudz.CnInvDbtUplTbl WHERE cidutUnloadKey = 903;

UPDATE sudz.CnInvDbtUplFile
SET cidufFlTbl = 1,
    cidufFlLoad = 1,
    cidufPath = N'D:\wire-guard-share-nb-win\femsq\excel\2026-06\debit\Дт Задолженность на 30.06.2026 (Общий свод) -НОВЫЙ.xlsx'
WHERE cidufUpload = 903;

COMMIT TRANSACTION;

SELECT COUNT(*) AS dv903 FROM sudz.DbtValue WHERE dvUpl = 903;
SELECT COUNT(*) AS tbl903 FROM sudz.CnInvDbtUplTbl WHERE cidutUnloadKey = 903;
SELECT COUNT(*) AS g4open903
FROM sudz.CnInvUplInvDbtDouble
WHERE ciudUnloadKey = 903 AND ciudStatus = N'open';
SELECT cidufFlTbl, cidufFlLoad, cidufPath
FROM sudz.CnInvDbtUplFile
WHERE cidufUpload = 903;
GO
