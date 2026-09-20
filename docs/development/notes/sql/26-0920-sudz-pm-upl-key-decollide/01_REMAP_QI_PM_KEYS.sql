/*
 * 26-0920 — DEV: развести ключи sudz/ags cn_inv_pm_upl (коллизия 3–8).
 * A: пакеты QI export_*_26-0422 → ключи 47–51; перенос apply-строк; g_p@902.
 * Не трогает исторические ags pm в ключах 3–8.
 *
 * lastUpdated: 2026-09-20
 */
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRAN;

-- 1) Календари ags + sudz: 47..51
SET IDENTITY_INSERT ags.cn_inv_pm_upl ON;
IF NOT EXISTS (SELECT 1 FROM ags.cn_inv_pm_upl WHERE cn_inv_pm_key = 47)
  INSERT INTO ags.cn_inv_pm_upl (cn_inv_pm_key, cn_inv_pm_name, cn_inv_pm_date)
  VALUES
    (47, N'export_606012_26-0422', '2026-04-22'),
    (48, N'export_606022_26-0422', '2026-04-22'),
    (49, N'export_761010_26-0422', '2026-04-22'),
    (50, N'export_767501_26-0422', '2026-04-22'),
    (51, N'export_767502_26-0422', '2026-04-22');
SET IDENTITY_INSERT ags.cn_inv_pm_upl OFF;

SET IDENTITY_INSERT sudz.cn_inv_pm_upl ON;
IF NOT EXISTS (SELECT 1 FROM sudz.cn_inv_pm_upl WHERE cn_inv_pm_key = 47)
  INSERT INTO sudz.cn_inv_pm_upl (cn_inv_pm_key, cn_inv_pm_name, cn_inv_pm_date)
  VALUES
    (47, N'export_606012_26-0422', '2026-04-22'),
    (48, N'export_606022_26-0422', '2026-04-22'),
    (49, N'export_761010_26-0422', '2026-04-22'),
    (50, N'export_767501_26-0422', '2026-04-22'),
    (51, N'export_767502_26-0422', '2026-04-22');
SET IDENTITY_INSERT sudz.cn_inv_pm_upl OFF;

-- 2) Перенос только FEMSQ apply (Sep 2026+) из коллизионных ключей
UPDATE ags.cn_inv_pm SET cn_inv_pm_upl = 47
WHERE cn_inv_pm_upl = 3 AND cipTimeOfEntry >= '2026-09-01';
UPDATE ags.cn_inv_pm SET cn_inv_pm_upl = 48
WHERE cn_inv_pm_upl = 4 AND cipTimeOfEntry >= '2026-09-01';
UPDATE ags.cn_inv_pm SET cn_inv_pm_upl = 49
WHERE cn_inv_pm_upl = 5 AND cipTimeOfEntry >= '2026-09-01';
UPDATE ags.cn_inv_pm SET cn_inv_pm_upl = 50
WHERE cn_inv_pm_upl = 6 AND cipTimeOfEntry >= '2026-09-01';
UPDATE ags.cn_inv_pm SET cn_inv_pm_upl = 51
WHERE cn_inv_pm_upl = 8 AND cipTimeOfEntry >= '2026-09-01';

-- 3) g_p @902 → новые ключи
UPDATE sudz.cn_inv_dbt_upl_g_p SET cn_inv_pm_upl = 47
WHERE cn_inv_dbt_upl = 902 AND cn_inv_pm_upl = 3;
UPDATE sudz.cn_inv_dbt_upl_g_p SET cn_inv_pm_upl = 48
WHERE cn_inv_dbt_upl = 902 AND cn_inv_pm_upl = 4;
UPDATE sudz.cn_inv_dbt_upl_g_p SET cn_inv_pm_upl = 49
WHERE cn_inv_dbt_upl = 902 AND cn_inv_pm_upl = 5;
UPDATE sudz.cn_inv_dbt_upl_g_p SET cn_inv_pm_upl = 50
WHERE cn_inv_dbt_upl = 902 AND cn_inv_pm_upl = 6;
UPDATE sudz.cn_inv_dbt_upl_g_p SET cn_inv_pm_upl = 51
WHERE cn_inv_dbt_upl = 902 AND cn_inv_pm_upl = 8;

-- 4) File + Tbl на новые ключи (чтобы повторный apply не писал в 3–8)
UPDATE sudz.CnInvPmtUplFile SET cipufUpload = 47 WHERE cipufUpload = 3;
UPDATE sudz.CnInvPmtUplFile SET cipufUpload = 48 WHERE cipufUpload = 4;
UPDATE sudz.CnInvPmtUplFile SET cipufUpload = 49 WHERE cipufUpload = 5;
UPDATE sudz.CnInvPmtUplFile SET cipufUpload = 50 WHERE cipufUpload = 6;
UPDATE sudz.CnInvPmtUplFile SET cipufUpload = 51 WHERE cipufUpload = 8;

UPDATE sudz.CnInvPmtUplTbl SET ciputUnloadKey = 47 WHERE ciputUnloadKey = 3;
UPDATE sudz.CnInvPmtUplTbl SET ciputUnloadKey = 48 WHERE ciputUnloadKey = 4;
UPDATE sudz.CnInvPmtUplTbl SET ciputUnloadKey = 49 WHERE ciputUnloadKey = 5;
UPDATE sudz.CnInvPmtUplTbl SET ciputUnloadKey = 50 WHERE ciputUnloadKey = 6;
UPDATE sudz.CnInvPmtUplTbl SET ciputUnloadKey = 51 WHERE ciputUnloadKey = 8;

-- 5) Пометить старые sudz-пакеты (остаются для истории UI, без g_p)
UPDATE sudz.cn_inv_pm_upl
SET cn_inv_pm_name = N'[deprecated collision] ' + cn_inv_pm_name
WHERE cn_inv_pm_key IN (3, 4, 5, 6, 8)
  AND cn_inv_pm_name NOT LIKE N'[deprecated collision]%';

-- 6) IDENTITY sudz выше ags+новых, чтобы createPmUpl не стол в 9…46
DECLARE @reseed int = (SELECT MAX(cn_inv_pm_key) FROM sudz.cn_inv_pm_upl);
DBCC CHECKIDENT ('sudz.cn_inv_pm_upl', RESEED, @reseed);

COMMIT TRAN;

-- verify
SELECT 'g_p_902' AS tag, cn_inv_pm_upl FROM sudz.cn_inv_dbt_upl_g_p WHERE cn_inv_dbt_upl = 902 ORDER BY 2;
SELECT 'pm_new' AS tag, cn_inv_pm_upl, COUNT(*) AS n
FROM ags.cn_inv_pm WHERE cn_inv_pm_upl BETWEEN 47 AND 51 GROUP BY cn_inv_pm_upl ORDER BY 1;
SELECT 'pm_old_left' AS tag, cn_inv_pm_upl, COUNT(*) AS n
FROM ags.cn_inv_pm WHERE cn_inv_pm_upl IN (3,4,5,6,8) GROUP BY cn_inv_pm_upl ORDER BY 1;
