-- S61h / 0069: тестовая выгрузка воронки на 31.12.2025 (не трогает Access upl 2…26 и seed 801–903/901)
-- Диапазон 910–919 зарезервирован под воронку excelToTbl / orgNotInBuirg / …
-- DEV only (схема sudz).

SET NOCOUNT ON;

-- 1) Шапка выгрузки
IF NOT EXISTS (SELECT 1 FROM sudz.cn_inv_dbt_upl WHERE upl_key = 910)
BEGIN
    INSERT INTO sudz.cn_inv_dbt_upl (upl_key, upl_date, uplStatusOnDate, upl_name)
    VALUES (
        910,
        '2026-01-20',           -- дата пакета (как «когда грузили»)
        '2025-12-31',           -- срез
        N'[funnel] Дт Задолженность на 31.12.2025 (Общий свод) — UAT воронки'
    );
END
ELSE
BEGIN
    UPDATE sudz.cn_inv_dbt_upl
    SET upl_date = '2026-01-20',
        uplStatusOnDate = '2025-12-31',
        upl_name = N'[funnel] Дт Задолженность на 31.12.2025 (Общий свод) — UAT воронки'
    WHERE upl_key = 910;
END

-- 2) File (пустой лог; путь — имя xlsx 2025; флаги выключены до upload)
DECLARE @fileKey int;
SELECT @fileKey = cidufKey FROM sudz.CnInvDbtUplFile WHERE cidufUpload = 910;

IF @fileKey IS NULL
BEGIN
    INSERT INTO sudz.CnInvDbtUplFile
        (cidufUpload, cidufPath, cidufFlLoad, cidufLoadingProgress, cidufFlTbl)
    VALUES
        (910, N'', 0, N'', 0);
    SET @fileKey = SCOPE_IDENTITY();
END
ELSE
BEGIN
    -- не затираем progress/path если уже работали; только гарантируем upload=910
    UPDATE sudz.CnInvDbtUplFile
    SET cidufUpload = 910
    WHERE cidufKey = @fileKey;
END

-- 3) FileSh: 6 рабочих листов как у Access File=20 (upl 26), если ещё нет
IF NOT EXISTS (SELECT 1 FROM sudz.CnInvDbtUplFileSh WHERE cidufsFile = @fileKey)
BEGIN
    INSERT INTO sudz.CnInvDbtUplFileSh (cidufsFile, cidufsSheet, cidufsAccount, cidufsTest)
    VALUES
        (@fileKey, N'606012', 19, 1),
        (@fileKey, N'606022', 21, 1),
        (@fileKey, N'761010', 23, 1),
        (@fileKey, N'767501', 28, 1),
        (@fileKey, N'762210', 24, 1),
        (@fileKey, N'767502', 29, 1);
END

-- 4) Tbl для 910 — пустой буфер (эфемерный)
DELETE FROM sudz.CnInvDbtUplTbl WHERE cidutUnloadKey = 910;

-- VERIFY
SELECT u.upl_key, u.upl_name,
       CONVERT(varchar(10), u.upl_date, 23) AS upl_date,
       CONVERT(varchar(10), u.uplStatusOnDate, 23) AS status_on,
       f.cidufKey, f.cidufFlTbl, f.cidufFlLoad,
       (SELECT COUNT(*) FROM sudz.CnInvDbtUplFileSh s WHERE s.cidufsFile = f.cidufKey) AS sheets,
       (SELECT COUNT(*) FROM sudz.CnInvDbtUplTbl t WHERE t.cidutUnloadKey = 910) AS tbl
FROM sudz.cn_inv_dbt_upl u
LEFT JOIN sudz.CnInvDbtUplFile f ON f.cidufUpload = u.upl_key
WHERE u.upl_key = 910;

SELECT cidufsKey, cidufsSheet, cidufsAccount, cidufsTest
FROM sudz.CnInvDbtUplFileSh
WHERE cidufsFile = @fileKey
ORDER BY cidufsKey;
