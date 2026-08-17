-- =============================================================================
-- S61e / 0069: в `sudz.cn_inv_dbt_upl` — выгрузки, на которые ссылается
-- seed CnInvDbtUplFile (cidufUpload из Access / ags). Без этого экран C
-- показывает только sandbox 801–903, а File+листы «невидимы».
-- DEV only. Идемпотентно (NOT EXISTS).
-- =============================================================================

SET NOCOUNT ON;
GO

INSERT INTO sudz.cn_inv_dbt_upl (upl_key, upl_date, uplStatusOnDate, upl_name)
SELECT a.upl_key, a.upl_date, a.uplStatusOnDate, a.upl_name
FROM ags.cn_inv_dbt_upl AS a
WHERE a.upl_key IN (SELECT f.cidufUpload FROM sudz.CnInvDbtUplFile AS f)
  AND NOT EXISTS (
        SELECT 1 FROM sudz.cn_inv_dbt_upl AS s WHERE s.upl_key = a.upl_key
  );
GO

SELECT COUNT(*) AS sudz_upl_cnt FROM sudz.cn_inv_dbt_upl;
SELECT f.cidufUpload, u.upl_name, COUNT(sh.cidufsKey) AS sheets
FROM sudz.CnInvDbtUplFile AS f
JOIN sudz.cn_inv_dbt_upl AS u ON u.upl_key = f.cidufUpload
LEFT JOIN sudz.CnInvDbtUplFileSh AS sh ON sh.cidufsFile = f.cidufKey
WHERE f.cidufUpload = 26
GROUP BY f.cidufUpload, u.upl_name;
GO
