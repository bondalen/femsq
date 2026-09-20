/*
 * H6 rebuild @902 after A/B/C (pm keys 47–51 + raw_cia ∪ raw_doc).
 * lastUpdated: 2026-09-20
 */
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRAN;

DELETE FROM sudz.DbtUplCstAg WHERE ducaUpl = 902;

;WITH raw_cia AS (
  SELECT idd.iddDbt AS dbtKey, dv.dvUpl AS femsqUpl, p.cnipCstAgPn AS cstapKey
  FROM sudz.DbtValue dv
  JOIN sudz.invDbtDbt idd ON idd.iddInvDbt = dv.dvInvDbt
  JOIN sudz.invDbtCia c ON c.idcInvDbt = dv.dvInvDbt
  JOIN ags.cn_inv_pm p ON p.ciaCnInvAccntSmpl = c.idcCia AND p.cnipCstAgPn IS NOT NULL
  JOIN sudz.cn_inv_dbt_upl_g_p g ON g.cn_inv_pm_upl = p.cn_inv_pm_upl AND g.cn_inv_dbt_upl = dv.dvUpl
  WHERE dv.dvUpl = 902 AND idd.iddDbt IS NOT NULL
  GROUP BY idd.iddDbt, dv.dvUpl, p.cnipCstAgPn
),
raw_doc AS (
  SELECT idd.iddDbt AS dbtKey, dv.dvUpl AS femsqUpl, p.cnipCstAgPn AS cstapKey
  FROM sudz.DbtValue dv
  JOIN sudz.invDbtDbt idd ON idd.iddInvDbt = dv.dvInvDbt
  JOIN sudz.cn_inv_dbt_upl_g_p g ON g.cn_inv_dbt_upl = dv.dvUpl
  JOIN ags.cn_inv_pm p ON p.cn_inv_pm_upl = g.cn_inv_pm_upl AND p.cnipCstAgPn IS NOT NULL
  JOIN ags.cnInvAccntSmpl s ON s.ciasKey = p.ciaCnInvAccntSmpl
  JOIN ags.cnInv ci ON ci.ciKey = s.ciasCnInv
  JOIN ags.invNum n ON n.inInv = ci.ciInv AND n.inNumNull = LTRIM(RTRIM(dv.dvDocBase))
  WHERE dv.dvUpl = 902 AND idd.iddDbt IS NOT NULL
    AND dv.dvDocBase IS NOT NULL AND LTRIM(RTRIM(dv.dvDocBase)) <> N''
  GROUP BY idd.iddDbt, dv.dvUpl, p.cnipCstAgPn
),
raw AS (
  SELECT dbtKey, femsqUpl, cstapKey FROM raw_cia
  UNION
  SELECT dbtKey, femsqUpl, cstapKey FROM raw_doc
),
agg AS (
  SELECT dbtKey, femsqUpl, COUNT(DISTINCT cstapKey) AS nCst, MIN(cstapKey) AS cstapKey
  FROM raw GROUP BY dbtKey, femsqUpl
)
INSERT INTO sudz.DbtUplCstAg (ducaDbt, ducaUpl, ducaCstAgPn)
SELECT dbtKey, femsqUpl, cstapKey FROM agg WHERE nCst = 1;

COMMIT TRAN;

SELECT COUNT(*) AS inserted_902 FROM sudz.DbtUplCstAg WHERE ducaUpl = 902;

-- spot-check 0620CR000043 / dbt 94
SELECT a.ducaDbt, pn.cstapIpgPnN
FROM sudz.DbtUplCstAg a
JOIN ags.cstAgPn pn ON pn.cstapKey = a.ducaCstAgPn
WHERE a.ducaUpl = 902 AND a.ducaDbt = 94;
