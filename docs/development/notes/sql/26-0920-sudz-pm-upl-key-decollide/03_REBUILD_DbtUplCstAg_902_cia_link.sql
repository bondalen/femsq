/*
 * H6 rebuild @902 after C':
 *   B' — raw_cia: idcCia → cnInvAccnt → smpl (не idcCia как ciasKey)
 *   A  — raw_doc: invNum OR cn_inv_doc_link = dvDocBase
 * lastUpdated: 2026-09-20
 *
 * Примечание: data-fix invDbtCia для 9469 не нужен — idcCia=16284 уже
 * указывает на smpl 68548 (49786/767502); ломал прямой join к pm.
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
  JOIN ags.cnInvAccnt cia ON cia.ciaKey = c.idcCia
  JOIN ags.cn_inv_pm p ON p.ciaCnInvAccntSmpl = cia.ciaCnInvAccntSmpl
    AND p.cnipCstAgPn IS NOT NULL
  JOIN sudz.cn_inv_dbt_upl_g_p g ON g.cn_inv_pm_upl = p.cn_inv_pm_upl
    AND g.cn_inv_dbt_upl = dv.dvUpl
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
  JOIN ags.invNum n ON n.inInv = ci.ciInv
  WHERE dv.dvUpl = 902 AND idd.iddDbt IS NOT NULL
    AND dv.dvDocBase IS NOT NULL AND LTRIM(RTRIM(dv.dvDocBase)) <> N''
    AND (
      n.inNumNull = LTRIM(RTRIM(dv.dvDocBase))
      OR (
        LEN(LTRIM(RTRIM(dv.dvDocBase))) >= 8
        AND LTRIM(RTRIM(ISNULL(p.cn_inv_doc_link, N''))) = LTRIM(RTRIM(dv.dvDocBase))
      )
    )
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

-- spot-check residual FAIL + earlier bothDiff samples
SELECT a.ducaDbt, pn.cstapIpgPnN
FROM sudz.DbtUplCstAg a
JOIN ags.cstAgPn pn ON pn.cstapKey = a.ducaCstAgPn
WHERE a.ducaUpl = 902 AND a.ducaDbt IN (94, 4249, 4734, 9469)
ORDER BY a.ducaDbt;
