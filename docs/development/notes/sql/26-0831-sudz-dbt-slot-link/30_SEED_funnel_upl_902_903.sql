/*
 * S76-C — File + FileSh для upl 902 / 903 (воронка stage2, без B-seed).
 * Excel на шаре: …31.03.2026 / …30.06.2026 «Общий свод» -НОВЫЙ.xlsx (13 листов).
 * lastUpdated: 2026-09-01
 */
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRANSACTION;

/* --- upl 902: сброс буфера / Value (seed 82/85 перезапишется воронкой) --- */
DELETE FROM sudz.CnInvUplDbtP1 WHERE cip1UnloadKey = 902;

DELETE q
FROM sudz.CnInvUplInvDbtDouble AS q
INNER JOIN sudz.CnInvDbtUplTbl AS t ON t.cidutKey = q.ciudCidut
WHERE t.cidutUnloadKey = 902;

DELETE FROM sudz.DbtValue WHERE dvUpl = 902;
DELETE FROM sudz.CnInvDbtUplTbl WHERE cidutUnloadKey = 902;

DECLARE @file902 int;
SELECT @file902 = cidufKey FROM sudz.CnInvDbtUplFile WHERE cidufUpload = 902;

IF @file902 IS NULL
BEGIN
    INSERT INTO sudz.CnInvDbtUplFile
        (cidufUpload, cidufPath, cidufFlLoad, cidufLoadingProgress, cidufFlTbl)
    VALUES
        (902,
         N'D:\wire-guard-share-nb-win\femsq\excel\2026_03\debit\Дт Задолженность на 31.03.2026 (Общий свод) -НОВЫЙ.xlsx',
         0, N'', 1);
    SET @file902 = SCOPE_IDENTITY();
END
ELSE
BEGIN
    UPDATE sudz.CnInvDbtUplFile
    SET cidufPath = N'D:\wire-guard-share-nb-win\femsq\excel\2026_03\debit\Дт Задолженность на 31.03.2026 (Общий свод) -НОВЫЙ.xlsx',
        cidufFlLoad = 0,
        cidufFlTbl = 1
    WHERE cidufKey = @file902;
END

DELETE FROM sudz.CnInvDbtUplFileSh WHERE cidufsFile = @file902;

INSERT INTO sudz.CnInvDbtUplFileSh (cidufsFile, cidufsSheet, cidufsAccount, cidufsTest)
VALUES
    (@file902, N'601300', 16, 1),
    (@file902, N'601750', 17, 1),
    (@file902, N'601760', 18, 1),
    (@file902, N'606012', 19, 1),
    (@file902, N'606022', 21, 1),
    (@file902, N'682102', 22, 1),
    (@file902, N'761010', 23, 1),
    (@file902, N'762210', 24, 1),
    (@file902, N'767401', 25, 1),
    (@file902, N'767402 нет', 26, 1),
    (@file902, N'767403', 27, 1),
    (@file902, N'767501', 28, 1),
    (@file902, N'767502', 29, 1);

/* --- upl 903 --- */
DELETE FROM sudz.CnInvUplDbtP1 WHERE cip1UnloadKey = 903;

DELETE q
FROM sudz.CnInvUplInvDbtDouble AS q
INNER JOIN sudz.CnInvDbtUplTbl AS t ON t.cidutKey = q.ciudCidut
WHERE t.cidutUnloadKey = 903;

DELETE FROM sudz.DbtValue WHERE dvUpl = 903;
DELETE FROM sudz.CnInvDbtUplTbl WHERE cidutUnloadKey = 903;

DECLARE @file903 int;
SELECT @file903 = cidufKey FROM sudz.CnInvDbtUplFile WHERE cidufUpload = 903;

IF @file903 IS NULL
BEGIN
    INSERT INTO sudz.CnInvDbtUplFile
        (cidufUpload, cidufPath, cidufFlLoad, cidufLoadingProgress, cidufFlTbl)
    VALUES
        (903,
         N'D:\wire-guard-share-nb-win\femsq\excel\2026-06\debit\Дт Задолженность на 30.06.2026 (Общий свод) -НОВЫЙ.xlsx',
         0, N'', 1);
    SET @file903 = SCOPE_IDENTITY();
END
ELSE
BEGIN
    UPDATE sudz.CnInvDbtUplFile
    SET cidufPath = N'D:\wire-guard-share-nb-win\femsq\excel\2026-06\debit\Дт Задолженность на 30.06.2026 (Общий свод) -НОВЫЙ.xlsx',
        cidufFlLoad = 0,
        cidufFlTbl = 1
    WHERE cidufKey = @file903;
END

DELETE FROM sudz.CnInvDbtUplFileSh WHERE cidufsFile = @file903;

INSERT INTO sudz.CnInvDbtUplFileSh (cidufsFile, cidufsSheet, cidufsAccount, cidufsTest)
VALUES
    (@file903, N'601300', 16, 1),
    (@file903, N'601750', 17, 1),
    (@file903, N'601760', 18, 1),
    (@file903, N'606012', 19, 1),
    (@file903, N'606022', 21, 1),
    (@file903, N'682102', 22, 1),
    (@file903, N'761010', 23, 1),
    (@file903, N'762210', 24, 1),
    (@file903, N'767401 нет', 25, 1),
    (@file903, N'767402 нет', 26, 1),
    (@file903, N'767403', 27, 1),
    (@file903, N'767501', 28, 1),
    (@file903, N'767502', 29, 1);

COMMIT TRANSACTION;

SELECT u.upl_key, u.upl_name,
       f.cidufKey, f.cidufFlTbl, f.cidufFlLoad,
       (SELECT COUNT(*) FROM sudz.CnInvDbtUplFileSh s WHERE s.cidufsFile = f.cidufKey) AS sheets,
       (SELECT COUNT(*) FROM sudz.CnInvDbtUplTbl t WHERE t.cidutUnloadKey = u.upl_key) AS tbl,
       (SELECT COUNT(*) FROM sudz.DbtValue dv WHERE dv.dvUpl = u.upl_key) AS dv
FROM sudz.cn_inv_dbt_upl u
LEFT JOIN sudz.CnInvDbtUplFile f ON f.cidufUpload = u.upl_key
WHERE u.upl_key IN (902, 903)
ORDER BY u.upl_key;
GO
