-- Smoke: counts for invDbtVarEnsure logic on upl 910 (read-only).
-- Mirrors JdbcSudzDao.sqlDbtUplInvDbtVarEnsureCte.

WITH tbl AS (
  SELECT a.cidutCntrPrtNum, a.cidutCntrPrtName, a.cidutCntrPrtITN,
         a.cidutCnName, a.cidutCnDate, a.cidutCnInv, a.cidutAccount,
         CASE WHEN a.cidutCnDate IS NULL THEN CAST('19000101' AS date)
              ELSE CAST(a.cidutCnDate AS date) END AS cidutCnDateNull,
         CASE WHEN a.cidutCnName IS NULL OR LTRIM(RTRIM(a.cidutCnName)) = N''
              THEN N'NullИлиПусто' ELSE LTRIM(RTRIM(a.cidutCnName)) END AS cidutCnNameNull,
         CASE WHEN a.cidutCnInv IS NULL OR LTRIM(RTRIM(a.cidutCnInv)) = N''
              THEN N'NullИлиПусто' ELSE LTRIM(RTRIM(a.cidutCnInv)) END AS cidutCnInvNull
  FROM sudz.CnInvDbtUplTbl AS a
  WHERE a.cidutUnloadKey = 910
),
ctptNot AS (
  SELECT z.cidutCntrPrtNum
  FROM (SELECT cidutCntrPrtNum, cidutCntrPrtName, cidutCntrPrtITN FROM tbl
        GROUP BY cidutCntrPrtNum, cidutCntrPrtName, cidutCntrPrtITN) AS z
  LEFT JOIN ags.org_id AS x ON z.cidutCntrPrtNum = x.org_id_value_l AND x.org_id_type = 1
  WHERE x.org_id_key IS NULL
),
tblCtptExist AS (
  SELECT DISTINCT n.cidutCntrPrtNum, og.ogNm AS cidutCntrPrtName,
         n.cidutCnName, n.cidutCnDate, n.cidutCnDateNull, n.cidutCnNameNull,
         n.cidutCnInv, n.cidutCnInvNull, n.cidutAccount
  FROM tbl AS n
  LEFT JOIN ctptNot AS b ON n.cidutCntrPrtNum = b.cidutCntrPrtNum
  INNER JOIN ags.org_id AS oi ON n.cidutCntrPrtNum = oi.org_id_value_l AND oi.org_id_type = 1
  LEFT JOIN ags.og AS og ON oi.org = og.ogKey
  WHERE b.cidutCntrPrtNum IS NULL
),
cnCtptList AS (
  SELECT c.cn_key, num.cnnNumNull AS cn_number, o.cn_s_org_key, i.org_id_value_l,
         CASE WHEN o.csoCnDate IS NULL THEN CAST('19000101' AS date)
              ELSE CAST(o.csoCnDate AS date) END AS csoCnDateNull
  FROM ags.cn AS c
  INNER JOIN ags.cn_s AS s ON c.cn_key = s.cn_key AND s.cn_s_type = 2
  INNER JOIN ags.cn_s_org_smpl AS m ON s.cn_s_key = m.csosCn_s
  INNER JOIN ags.cn_s_org AS o ON m.csosKey = o.csoCn_s_org_smpl
  INNER JOIN ags.org_id AS i ON m.csosOrgId = i.org_id_key
  INNER JOIN ags.cnNum AS num ON c.cn_key = num.cnnCn
),
existList AS (
  SELECT k.cidutCntrPrtNum, k.cidutCntrPrtName, k.cidutCnName,
         k.cidutCnNameNull, k.cidutCnDate, k.cidutCnDateNull,
         l.cn_key, l.cn_s_org_key
  FROM tblCtptExist AS k
  INNER JOIN cnCtptList AS l
    ON k.cidutCnNameNull = l.cn_number
   AND k.cidutCnDateNull = l.csoCnDateNull
   AND k.cidutCntrPrtNum = l.org_id_value_l
  GROUP BY k.cidutCntrPrtNum, k.cidutCntrPrtName, k.cidutCnName,
           k.cidutCnNameNull, k.cidutCnDate, k.cidutCnDateNull,
           l.cn_key, l.cn_s_org_key
),
existInvGrouped AS (
  SELECT h.cidutCntrPrtNum, h.cidutCntrPrtName, h.cidutCnName,
         h.cidutCnNameNull, h.cidutCnDate, h.cidutCnDateNull,
         t.cidutCnInv, t.cidutCnInvNull, h.cn_key, h.cn_s_org_key
  FROM existList AS h
  LEFT JOIN tbl AS t
    ON h.cidutCntrPrtNum = t.cidutCntrPrtNum
   AND h.cidutCnNameNull = t.cidutCnNameNull
   AND h.cidutCnDateNull = t.cidutCnDateNull
  GROUP BY h.cidutCntrPrtNum, h.cidutCntrPrtName, h.cidutCnName,
           h.cidutCnNameNull, h.cidutCnDate, h.cidutCnDateNull,
           t.cidutCnInv, t.cidutCnInvNull, h.cn_key, h.cn_s_org_key
),
variants AS (
  SELECT ci.ciKey, inv.iKey, ci.ciCn AS cn_key, n.inNumNull,
         CASE WHEN o.csoCnDate IS NULL THEN CAST('19000101' AS date)
              ELSE CAST(o.csoCnDate AS date) END AS csoCnDateNull
  FROM ags.cnInv AS ci
  INNER JOIN ags.inv AS inv ON inv.iKey = ci.ciInv
  INNER JOIN ags.invNum AS n ON n.inInv = inv.iKey
  INNER JOIN ags.cn_s AS s ON s.cn_key = ci.ciCn AND s.cn_s_type = 2
  INNER JOIN ags.cn_s_org_smpl AS m ON m.csosCn_s = s.cn_s_key
  INNER JOIN ags.cn_s_org AS o ON o.csoCn_s_org_smpl = m.csosKey
),
existInvAll AS (
  SELECT f.cidutCntrPrtNum, f.cidutCntrPrtName, f.cidutCnName,
         f.cidutCnNameNull, f.cidutCnDate, f.cidutCnDateNull,
         f.cidutCnInv, f.cidutCnInvNull, f.cn_key, f.cn_s_org_key,
         g.iKey, g.ciKey
  FROM existInvGrouped AS f
  LEFT JOIN variants AS g
    ON f.cn_key = g.cn_key
   AND f.cidutCnInvNull = g.inNumNull
   AND f.cidutCnDateNull = g.csoCnDateNull
  GROUP BY f.cidutCntrPrtNum, f.cidutCntrPrtName, f.cidutCnName,
           f.cidutCnNameNull, f.cidutCnDate, f.cidutCnDateNull,
           f.cidutCnInv, f.cidutCnInvNull, f.cn_key, f.cn_s_org_key,
           g.iKey, g.ciKey
),
accY AS (
  SELECT t.cidutCntrPrtNum, t.cidutCnNameNull, t.cidutCnDateNull,
         t.cidutCnInvNull, acc.account_num, acc.account_key
  FROM tbl AS t
  INNER JOIN ags.accnt AS acc ON t.cidutAccount = acc.account_key
),
cnnUnique AS (
  SELECT cnnCn, MIN(cnnKey) AS cnnKey FROM ags.cnNum WHERE cnnType = 1
  GROUP BY cnnCn HAVING COUNT(*) = 1
),
inUnique AS (
  SELECT inInv, inNumNull, MIN(inKey) AS inKey FROM ags.invNum
  GROUP BY inInv, inNumNull HAVING COUNT(*) = 1
),
ctxBase AS (
  SELECT DISTINCT z.cidutCntrPrtNum, z.cidutCnName, z.cidutCnInv, z.iKey,
         z.cn_s_org_key, y.account_key, cnn.cnnKey, invn.inKey AS invNumKey
  FROM existInvAll AS z
  INNER JOIN accY AS y
    ON z.cidutCnInvNull = y.cidutCnInvNull
   AND z.cidutCnDateNull = y.cidutCnDateNull
   AND z.cidutCnNameNull = y.cidutCnNameNull
   AND z.cidutCntrPrtNum = y.cidutCntrPrtNum
  LEFT JOIN cnnUnique AS cnn ON cnn.cnnCn = z.cn_key
  LEFT JOIN inUnique AS invn ON invn.inInv = z.iKey AND invn.inNumNull = z.cidutCnInvNull
  WHERE z.iKey IS NOT NULL AND z.cn_s_org_key IS NOT NULL AND y.account_key IS NOT NULL
),
ctx AS (
  SELECT b.*, v.idvvKey
  FROM ctxBase AS b
  LEFT JOIN sudz.invDbtVar AS v
    ON v.idvvCnNum = b.cnnKey AND v.idvvInvNum = b.invNumKey
   AND v.idvvAccnt = b.account_key AND v.idvvCn_s_org = b.cn_s_org_key
)
SELECT
  (SELECT COUNT(*) FROM ctx WHERE cnnKey IS NOT NULL AND invNumKey IS NOT NULL AND idvvKey IS NULL) AS missing,
  (SELECT COUNT(*) FROM ctx WHERE cnnKey IS NULL OR invNumKey IS NULL) AS ambiguous,
  (SELECT COUNT(*) FROM ctx WHERE cnnKey IS NOT NULL AND invNumKey IS NOT NULL AND idvvKey IS NOT NULL) AS already,
  (SELECT COUNT(*) FROM ctx) AS ctxRows;
