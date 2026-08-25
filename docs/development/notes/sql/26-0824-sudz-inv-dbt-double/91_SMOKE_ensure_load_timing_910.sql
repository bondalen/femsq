-- Smoke timings for optimized AccSmpl / invDbtVarEnsure / invDbtLoad classify (upl 910).
-- Mirrors JdbcSudzDao sqlDbtUplExistInvAllCte + ensure/load tails (dev SQL Server 2022).
SET NOCOUNT ON;
DECLARE @unload int = 910;
DECLARE @t0 datetime2;
DECLARE @ms int;

PRINT '=== 1. AccSmpl (accSmplNot COUNT) ===';
SET @t0 = SYSUTCDATETIME();
;WITH tbl AS (
  SELECT a.cidutCntrPrtNum, a.cidutCntrPrtName, a.cidutCntrPrtITN,
         a.cidutCnName, a.cidutCnDate, a.cidutCnInv, a.cidutAccount,
         CASE WHEN a.cidutCnDate IS NULL THEN CAST('19000101' AS date) ELSE CAST(a.cidutCnDate AS date) END AS cidutCnDateNull,
         CASE WHEN a.cidutCnName IS NULL OR LTRIM(RTRIM(a.cidutCnName)) = N'' THEN N'NullИлиПусто' ELSE LTRIM(RTRIM(a.cidutCnName)) END AS cidutCnNameNull,
         CASE WHEN a.cidutCnInv IS NULL OR LTRIM(RTRIM(a.cidutCnInv)) = N'' THEN N'NullИлиПусто' ELSE LTRIM(RTRIM(a.cidutCnInv)) END AS cidutCnInvNull
  FROM sudz.CnInvDbtUplTbl AS a WHERE a.cidutUnloadKey = @unload
),
ctptNot AS (
  SELECT z.cidutCntrPrtNum
  FROM (SELECT cidutCntrPrtNum, cidutCntrPrtName, cidutCntrPrtITN FROM tbl GROUP BY cidutCntrPrtNum, cidutCntrPrtName, cidutCntrPrtITN) AS z
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
cnNeed AS (SELECT DISTINCT cidutCnNameNull, cidutCntrPrtNum, cidutCnDateNull FROM tblCtptExist),
cnCtptList AS (
  SELECT c.cn_key, num.cnnNumNull AS cn_number, o.cn_s_org_key, i.org_id_value_l,
         CASE WHEN o.csoCnDate IS NULL THEN CAST('19000101' AS date) ELSE CAST(o.csoCnDate AS date) END AS csoCnDateNull
  FROM cnNeed AS need
  INNER JOIN ags.cnNum AS num ON need.cidutCnNameNull = num.cnnNumNull
  INNER JOIN ags.cn AS c ON c.cn_key = num.cnnCn
  INNER JOIN ags.cn_s AS s ON c.cn_key = s.cn_key AND s.cn_s_type = 2
  INNER JOIN ags.cn_s_org_smpl AS m ON s.cn_s_key = m.csosCn_s
  INNER JOIN ags.cn_s_org AS o ON m.csosKey = o.csoCn_s_org_smpl
  INNER JOIN ags.org_id AS i ON m.csosOrgId = i.org_id_key
  WHERE need.cidutCntrPrtNum = i.org_id_value_l
    AND need.cidutCnDateNull = CASE WHEN o.csoCnDate IS NULL THEN CAST('19000101' AS date) ELSE CAST(o.csoCnDate AS date) END
),
existList AS (
  SELECT k.cidutCntrPrtNum, k.cidutCntrPrtName, k.cidutCnName, k.cidutCnNameNull, k.cidutCnDate, k.cidutCnDateNull, l.cn_key, l.cn_s_org_key
  FROM tblCtptExist AS k
  INNER JOIN cnCtptList AS l ON k.cidutCnNameNull = l.cn_number AND k.cidutCnDateNull = l.csoCnDateNull AND k.cidutCntrPrtNum = l.org_id_value_l
  GROUP BY k.cidutCntrPrtNum, k.cidutCntrPrtName, k.cidutCnName, k.cidutCnNameNull, k.cidutCnDate, k.cidutCnDateNull, l.cn_key, l.cn_s_org_key
),
existInvGrouped AS (
  SELECT h.cidutCntrPrtNum, h.cidutCntrPrtName, h.cidutCnName, h.cidutCnNameNull, h.cidutCnDate, h.cidutCnDateNull,
         t.cidutCnInv, t.cidutCnInvNull, h.cn_key, h.cn_s_org_key
  FROM existList AS h
  LEFT JOIN tbl AS t ON h.cidutCntrPrtNum = t.cidutCntrPrtNum AND h.cidutCnNameNull = t.cidutCnNameNull AND h.cidutCnDateNull = t.cidutCnDateNull
  GROUP BY h.cidutCntrPrtNum, h.cidutCntrPrtName, h.cidutCnName, h.cidutCnNameNull, h.cidutCnDate, h.cidutCnDateNull,
           t.cidutCnInv, t.cidutCnInvNull, h.cn_key, h.cn_s_org_key
),
needInv AS (SELECT DISTINCT cn_key, cidutCnInvNull FROM existInvGrouped),
invNumNeed AS (
  SELECT n.inInv, n.inNumNull FROM ags.invNum AS n
  WHERE EXISTS (SELECT 1 FROM needInv AS need WHERE need.cidutCnInvNull = n.inNumNull)
),
invCi AS (
  SELECT n.inNumNull, ci.ciKey, ci.ciCn, inv.iKey
  FROM invNumNeed AS n
  INNER JOIN ags.inv AS inv ON inv.iKey = n.inInv
  INNER JOIN ags.cnInv AS ci ON ci.ciInv = n.inInv
),
existInvAll AS (
  SELECT f.cidutCntrPrtNum, f.cidutCntrPrtName, f.cidutCnName, f.cidutCnNameNull, f.cidutCnDate, f.cidutCnDateNull,
         f.cidutCnInv, f.cidutCnInvNull, f.cn_key, f.cn_s_org_key, ic.iKey, ic.ciKey
  FROM existInvGrouped AS f
  LEFT JOIN invCi AS ic ON ic.inNumNull = f.cidutCnInvNull AND ic.ciCn = f.cn_key
),
accY AS (
  SELECT t.cidutCntrPrtNum, t.cidutCnNameNull, t.cidutCnDateNull, t.cidutCnInvNull, acc.account_num, acc.account_key
  FROM tbl AS t INNER JOIN ags.accnt AS acc ON t.cidutAccount = acc.account_key
),
smplS AS (
  SELECT s.ciasKey, s.ciasCnInv, s.ciasAccnt, i.org_id_value_l
  FROM (SELECT DISTINCT ciKey FROM existInvAll WHERE ciKey IS NOT NULL) AS need
  INNER JOIN ags.cnInvAccntSmpl AS s ON s.ciasCnInv = need.ciKey
  INNER JOIN ags.cn_s_org_smpl AS o ON s.ciasCn_s_org_smpl = o.csosKey
  INNER JOIN ags.org_id AS i ON o.csosOrgId = i.org_id_key
),
accSmplAll AS (
  SELECT x.cidutCntrPrtNum, x.cidutCntrPrtName, x.cidutCnName, x.cidutCnNameNull, x.cidutCnDate, x.cidutCnInv,
         x.cn_key, x.iKey, x.ciKey, x.account_num, x.account_key, s.ciasKey
  FROM (
    SELECT z.cidutCntrPrtNum, z.cidutCntrPrtName, z.cidutCnName, z.cidutCnNameNull, z.cidutCnDate, z.cidutCnInv,
           z.cn_key, z.iKey, z.ciKey, y.account_num, y.account_key
    FROM existInvAll AS z
    LEFT JOIN accY AS y ON z.cidutCnInvNull = y.cidutCnInvNull AND z.cidutCnDateNull = y.cidutCnDateNull
      AND z.cidutCnNameNull = y.cidutCnNameNull AND z.cidutCntrPrtNum = y.cidutCntrPrtNum
    WHERE z.ciKey IS NOT NULL
  ) AS x
  LEFT JOIN smplS AS s ON x.account_key = s.ciasAccnt AND x.ciKey = s.ciasCnInv AND x.cidutCntrPrtNum = s.org_id_value_l
),
accSmplNot AS (
  SELECT cidutCntrPrtNum, cidutCntrPrtName, cidutCnName, cidutCnNameNull, cidutCnDate, cidutCnInv, cn_key, iKey, ciKey, account_num, account_key
  FROM accSmplAll WHERE ciasKey IS NULL AND account_key IS NOT NULL
)
SELECT COUNT(*) AS accSmplNot_cnt, DATEDIFF(ms, @t0, SYSUTCDATETIME()) AS ms FROM accSmplNot;

PRINT '=== 2. ensure snapshot (missing + ambiguous COUNT) ===';
SET @t0 = SYSUTCDATETIME();
;WITH tbl AS (
  SELECT a.cidutCntrPrtNum, a.cidutCntrPrtName, a.cidutCntrPrtITN,
         a.cidutCnName, a.cidutCnDate, a.cidutCnInv, a.cidutAccount,
         CASE WHEN a.cidutCnDate IS NULL THEN CAST('19000101' AS date) ELSE CAST(a.cidutCnDate AS date) END AS cidutCnDateNull,
         CASE WHEN a.cidutCnName IS NULL OR LTRIM(RTRIM(a.cidutCnName)) = N'' THEN N'NullИлиПусто' ELSE LTRIM(RTRIM(a.cidutCnName)) END AS cidutCnNameNull,
         CASE WHEN a.cidutCnInv IS NULL OR LTRIM(RTRIM(a.cidutCnInv)) = N'' THEN N'NullИлиПусто' ELSE LTRIM(RTRIM(a.cidutCnInv)) END AS cidutCnInvNull
  FROM sudz.CnInvDbtUplTbl AS a WHERE a.cidutUnloadKey = @unload
),
ctptNot AS (
  SELECT z.cidutCntrPrtNum
  FROM (SELECT cidutCntrPrtNum, cidutCntrPrtName, cidutCntrPrtITN FROM tbl GROUP BY cidutCntrPrtNum, cidutCntrPrtName, cidutCntrPrtITN) AS z
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
cnNeed AS (SELECT DISTINCT cidutCnNameNull, cidutCntrPrtNum, cidutCnDateNull FROM tblCtptExist),
cnCtptList AS (
  SELECT c.cn_key, num.cnnNumNull AS cn_number, o.cn_s_org_key, i.org_id_value_l,
         CASE WHEN o.csoCnDate IS NULL THEN CAST('19000101' AS date) ELSE CAST(o.csoCnDate AS date) END AS csoCnDateNull
  FROM cnNeed AS need
  INNER JOIN ags.cnNum AS num ON need.cidutCnNameNull = num.cnnNumNull
  INNER JOIN ags.cn AS c ON c.cn_key = num.cnnCn
  INNER JOIN ags.cn_s AS s ON c.cn_key = s.cn_key AND s.cn_s_type = 2
  INNER JOIN ags.cn_s_org_smpl AS m ON s.cn_s_key = m.csosCn_s
  INNER JOIN ags.cn_s_org AS o ON m.csosKey = o.csoCn_s_org_smpl
  INNER JOIN ags.org_id AS i ON m.csosOrgId = i.org_id_key
  WHERE need.cidutCntrPrtNum = i.org_id_value_l
    AND need.cidutCnDateNull = CASE WHEN o.csoCnDate IS NULL THEN CAST('19000101' AS date) ELSE CAST(o.csoCnDate AS date) END
),
existList AS (
  SELECT k.cidutCntrPrtNum, k.cidutCntrPrtName, k.cidutCnName, k.cidutCnNameNull, k.cidutCnDate, k.cidutCnDateNull, l.cn_key, l.cn_s_org_key
  FROM tblCtptExist AS k
  INNER JOIN cnCtptList AS l ON k.cidutCnNameNull = l.cn_number AND k.cidutCnDateNull = l.csoCnDateNull AND k.cidutCntrPrtNum = l.org_id_value_l
  GROUP BY k.cidutCntrPrtNum, k.cidutCntrPrtName, k.cidutCnName, k.cidutCnNameNull, k.cidutCnDate, k.cidutCnDateNull, l.cn_key, l.cn_s_org_key
),
existInvGrouped AS (
  SELECT h.cidutCntrPrtNum, h.cidutCntrPrtName, h.cidutCnName, h.cidutCnNameNull, h.cidutCnDate, h.cidutCnDateNull,
         t.cidutCnInv, t.cidutCnInvNull, h.cn_key, h.cn_s_org_key
  FROM existList AS h
  LEFT JOIN tbl AS t ON h.cidutCntrPrtNum = t.cidutCntrPrtNum AND h.cidutCnNameNull = t.cidutCnNameNull AND h.cidutCnDateNull = t.cidutCnDateNull
  GROUP BY h.cidutCntrPrtNum, h.cidutCntrPrtName, h.cidutCnName, h.cidutCnNameNull, h.cidutCnDate, h.cidutCnDateNull,
           t.cidutCnInv, t.cidutCnInvNull, h.cn_key, h.cn_s_org_key
),
needInv AS (SELECT DISTINCT cn_key, cidutCnInvNull FROM existInvGrouped),
invNumNeed AS (
  SELECT n.inInv, n.inNumNull FROM ags.invNum AS n
  WHERE EXISTS (SELECT 1 FROM needInv AS need WHERE need.cidutCnInvNull = n.inNumNull)
),
invCi AS (
  SELECT n.inNumNull, ci.ciKey, ci.ciCn, inv.iKey
  FROM invNumNeed AS n
  INNER JOIN ags.inv AS inv ON inv.iKey = n.inInv
  INNER JOIN ags.cnInv AS ci ON ci.ciInv = n.inInv
),
existInvAll AS (
  SELECT f.cidutCntrPrtNum, f.cidutCntrPrtName, f.cidutCnName, f.cidutCnNameNull, f.cidutCnDate, f.cidutCnDateNull,
         f.cidutCnInv, f.cidutCnInvNull, f.cn_key, f.cn_s_org_key, ic.iKey, ic.ciKey
  FROM existInvGrouped AS f
  LEFT JOIN invCi AS ic ON ic.inNumNull = f.cidutCnInvNull AND ic.ciCn = f.cn_key
),
accY AS (
  SELECT t.cidutCntrPrtNum, t.cidutCnNameNull, t.cidutCnDateNull, t.cidutCnInvNull, acc.account_num, acc.account_key
  FROM tbl AS t INNER JOIN ags.accnt AS acc ON t.cidutAccount = acc.account_key
),
cnnUnique AS (
  SELECT n.cnnCn, MIN(n.cnnKey) AS cnnKey
  FROM ags.cnNum AS n
  INNER JOIN (SELECT DISTINCT cn_key FROM existInvGrouped WHERE cn_key IS NOT NULL) AS need ON need.cn_key = n.cnnCn
  WHERE n.cnnType = 1 GROUP BY n.cnnCn HAVING COUNT(*) = 1
),
inUnique AS (
  SELECT n.inInv, n.inNumNull, MIN(n.inKey) AS inKey
  FROM invNumNeed AS need
  INNER JOIN ags.invNum AS n ON n.inInv = need.inInv AND n.inNumNull = need.inNumNull
  GROUP BY n.inInv, n.inNumNull HAVING COUNT(*) = 1
),
ctxBase AS (
  SELECT DISTINCT z.cidutCntrPrtNum, z.cidutCntrPrtName, z.cidutCnName, z.cidutCnDate, z.cidutCnInv, z.cidutCnInvNull,
         z.iKey, z.cn_s_org_key, y.account_key, y.account_num, cnn.cnnKey, invn.inKey AS invNumKey
  FROM existInvAll AS z
  INNER JOIN accY AS y ON z.cidutCnInvNull = y.cidutCnInvNull AND z.cidutCnDateNull = y.cidutCnDateNull
    AND z.cidutCnNameNull = y.cidutCnNameNull AND z.cidutCntrPrtNum = y.cidutCntrPrtNum
  LEFT JOIN cnnUnique AS cnn ON cnn.cnnCn = z.cn_key
  LEFT JOIN inUnique AS invn ON invn.inInv = z.iKey AND invn.inNumNull = z.cidutCnInvNull
  WHERE z.iKey IS NOT NULL AND z.cn_s_org_key IS NOT NULL AND y.account_key IS NOT NULL
),
ctx AS (
  SELECT b.*, v.idvvKey
  FROM ctxBase AS b
  LEFT JOIN sudz.invDbtVar AS v
    ON v.idvvCnNum = b.cnnKey AND v.idvvInvNum = b.invNumKey AND v.idvvAccnt = b.account_key AND v.idvvCn_s_org = b.cn_s_org_key
)
SELECT
  SUM(CASE WHEN cnnKey IS NOT NULL AND invNumKey IS NOT NULL AND idvvKey IS NULL THEN 1 ELSE 0 END) AS missing_cnt,
  SUM(CASE WHEN cnnKey IS NULL OR invNumKey IS NULL THEN 1 ELSE 0 END) AS ambiguous_cnt,
  DATEDIFF(ms, @t0, SYSUTCDATETIME()) AS ms
FROM ctx
WHERE (cnnKey IS NULL OR invNumKey IS NULL)
   OR (cnnKey IS NOT NULL AND invNumKey IS NOT NULL AND idvvKey IS NULL);

PRINT '=== 3. invDbtLoad classify (needQueueBest COUNT, read-only) ===';
SET @t0 = SYSUTCDATETIME();
;WITH tbl AS (
  SELECT a.cidutCntrPrtNum, a.cidutCntrPrtName, a.cidutCntrPrtITN,
         a.cidutCnName, a.cidutCnDate, a.cidutCnInv, a.cidutAccount,
         CASE WHEN a.cidutCnDate IS NULL THEN CAST('19000101' AS date) ELSE CAST(a.cidutCnDate AS date) END AS cidutCnDateNull,
         CASE WHEN a.cidutCnName IS NULL OR LTRIM(RTRIM(a.cidutCnName)) = N'' THEN N'NullИлиПусто' ELSE LTRIM(RTRIM(a.cidutCnName)) END AS cidutCnNameNull,
         CASE WHEN a.cidutCnInv IS NULL OR LTRIM(RTRIM(a.cidutCnInv)) = N'' THEN N'NullИлиПусто' ELSE LTRIM(RTRIM(a.cidutCnInv)) END AS cidutCnInvNull
  FROM sudz.CnInvDbtUplTbl AS a WHERE a.cidutUnloadKey = @unload
),
ctptNot AS (
  SELECT z.cidutCntrPrtNum
  FROM (SELECT cidutCntrPrtNum, cidutCntrPrtName, cidutCntrPrtITN FROM tbl GROUP BY cidutCntrPrtNum, cidutCntrPrtName, cidutCntrPrtITN) AS z
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
cnNeed AS (SELECT DISTINCT cidutCnNameNull, cidutCntrPrtNum, cidutCnDateNull FROM tblCtptExist),
cnCtptList AS (
  SELECT c.cn_key, num.cnnNumNull AS cn_number, o.cn_s_org_key, i.org_id_value_l,
         CASE WHEN o.csoCnDate IS NULL THEN CAST('19000101' AS date) ELSE CAST(o.csoCnDate AS date) END AS csoCnDateNull
  FROM cnNeed AS need
  INNER JOIN ags.cnNum AS num ON need.cidutCnNameNull = num.cnnNumNull
  INNER JOIN ags.cn AS c ON c.cn_key = num.cnnCn
  INNER JOIN ags.cn_s AS s ON c.cn_key = s.cn_key AND s.cn_s_type = 2
  INNER JOIN ags.cn_s_org_smpl AS m ON s.cn_s_key = m.csosCn_s
  INNER JOIN ags.cn_s_org AS o ON m.csosKey = o.csoCn_s_org_smpl
  INNER JOIN ags.org_id AS i ON m.csosOrgId = i.org_id_key
  WHERE need.cidutCntrPrtNum = i.org_id_value_l
    AND need.cidutCnDateNull = CASE WHEN o.csoCnDate IS NULL THEN CAST('19000101' AS date) ELSE CAST(o.csoCnDate AS date) END
),
existList AS (
  SELECT k.cidutCntrPrtNum, k.cidutCntrPrtName, k.cidutCnName, k.cidutCnNameNull, k.cidutCnDate, k.cidutCnDateNull, l.cn_key, l.cn_s_org_key
  FROM tblCtptExist AS k
  INNER JOIN cnCtptList AS l ON k.cidutCnNameNull = l.cn_number AND k.cidutCnDateNull = l.csoCnDateNull AND k.cidutCntrPrtNum = l.org_id_value_l
  GROUP BY k.cidutCntrPrtNum, k.cidutCntrPrtName, k.cidutCnName, k.cidutCnNameNull, k.cidutCnDate, k.cidutCnDateNull, l.cn_key, l.cn_s_org_key
),
existInvGrouped AS (
  SELECT h.cidutCntrPrtNum, h.cidutCntrPrtName, h.cidutCnName, h.cidutCnNameNull, h.cidutCnDate, h.cidutCnDateNull,
         t.cidutCnInv, t.cidutCnInvNull, h.cn_key, h.cn_s_org_key
  FROM existList AS h
  LEFT JOIN tbl AS t ON h.cidutCntrPrtNum = t.cidutCntrPrtNum AND h.cidutCnNameNull = t.cidutCnNameNull AND h.cidutCnDateNull = t.cidutCnDateNull
  GROUP BY h.cidutCntrPrtNum, h.cidutCntrPrtName, h.cidutCnName, h.cidutCnNameNull, h.cidutCnDate, h.cidutCnDateNull,
           t.cidutCnInv, t.cidutCnInvNull, h.cn_key, h.cn_s_org_key
),
needInv AS (SELECT DISTINCT cn_key, cidutCnInvNull FROM existInvGrouped),
invNumNeed AS (
  SELECT n.inInv, n.inNumNull FROM ags.invNum AS n
  WHERE EXISTS (SELECT 1 FROM needInv AS need WHERE need.cidutCnInvNull = n.inNumNull)
),
invCi AS (
  SELECT n.inNumNull, ci.ciKey, ci.ciCn, inv.iKey
  FROM invNumNeed AS n
  INNER JOIN ags.inv AS inv ON inv.iKey = n.inInv
  INNER JOIN ags.cnInv AS ci ON ci.ciInv = n.inInv
),
existInvAll AS (
  SELECT f.cidutCntrPrtNum, f.cidutCntrPrtName, f.cidutCnName, f.cidutCnNameNull, f.cidutCnDate, f.cidutCnDateNull,
         f.cidutCnInv, f.cidutCnInvNull, f.cn_key, f.cn_s_org_key, ic.iKey, ic.ciKey
  FROM existInvGrouped AS f
  LEFT JOIN invCi AS ic ON ic.inNumNull = f.cidutCnInvNull AND ic.ciCn = f.cn_key
),
accY AS (
  SELECT t.cidutCntrPrtNum, t.cidutCnNameNull, t.cidutCnDateNull, t.cidutCnInvNull, acc.account_num, acc.account_key
  FROM tbl AS t INNER JOIN ags.accnt AS acc ON t.cidutAccount = acc.account_key
),
cnnUnique AS (
  SELECT n.cnnCn, MIN(n.cnnKey) AS cnnKey
  FROM ags.cnNum AS n
  INNER JOIN (SELECT DISTINCT cn_key FROM existInvGrouped WHERE cn_key IS NOT NULL) AS need ON need.cn_key = n.cnnCn
  WHERE n.cnnType = 1 GROUP BY n.cnnCn HAVING COUNT(*) = 1
),
inUnique AS (
  SELECT n.inInv, n.inNumNull, MIN(n.inKey) AS inKey
  FROM invNumNeed AS need
  INNER JOIN ags.invNum AS n ON n.inInv = need.inInv AND n.inNumNull = need.inNumNull
  GROUP BY n.inInv, n.inNumNull HAVING COUNT(*) = 1
),
ctxBase AS (
  SELECT DISTINCT z.cidutCntrPrtNum, z.cidutCntrPrtName, z.cidutCnName, z.cidutCnDate, z.cidutCnInv, z.cidutCnInvNull,
         z.iKey, z.cn_s_org_key, y.account_key, y.account_num, cnn.cnnKey, invn.inKey AS invNumKey
  FROM existInvAll AS z
  INNER JOIN accY AS y ON z.cidutCnInvNull = y.cidutCnInvNull AND z.cidutCnDateNull = y.cidutCnDateNull
    AND z.cidutCnNameNull = y.cidutCnNameNull AND z.cidutCntrPrtNum = y.cidutCntrPrtNum
  LEFT JOIN cnnUnique AS cnn ON cnn.cnnCn = z.cn_key
  LEFT JOIN inUnique AS invn ON invn.inInv = z.iKey AND invn.inNumNull = z.cidutCnInvNull
  WHERE z.iKey IS NOT NULL AND z.cn_s_org_key IS NOT NULL AND y.account_key IS NOT NULL
),
ctx AS (
  SELECT b.*, v.idvvKey
  FROM ctxBase AS b
  LEFT JOIN sudz.invDbtVar AS v
    ON v.idvvCnNum = b.cnnKey AND v.idvvInvNum = b.invNumKey AND v.idvvAccnt = b.account_key AND v.idvvCn_s_org = b.cn_s_org_key
),
resolvedUnique AS (SELECT * FROM ctx WHERE cnnKey IS NOT NULL AND invNumKey IS NOT NULL),
ambiguousIKeys AS (SELECT DISTINCT iKey FROM ctx WHERE cnnKey IS NULL OR invNumKey IS NULL),
multiCtxIKeys AS (
  SELECT iKey FROM resolvedUnique
  GROUP BY iKey
  HAVING COUNT(DISTINCT CONCAT(CAST(cnnKey AS varchar(20)), N'|', CAST(invNumKey AS varchar(20)), N'|',
    CAST(account_key AS varchar(20)), N'|', CAST(cn_s_org_key AS varchar(20)))) > 1
),
histInvDbtMulti AS (SELECT idInv AS iKey FROM sudz.invDbt GROUP BY idInv HAVING COUNT(*) > 1),
histNamedAccMulti AS (
  SELECT ci.ciInv AS iKey
  FROM ags.cnInvAccnt AS a
  INNER JOIN ags.cnInvAccntSmpl AS s ON a.ciaCnInvAccntSmpl = s.ciasKey
  INNER JOIN ags.cnInv AS ci ON s.ciasCnInv = ci.ciKey
  WHERE a.ciaName IS NOT NULL
  GROUP BY ci.ciInv HAVING COUNT(*) > 1
),
tblRows AS (
  SELECT a.cidutKey, a.cidutUnloadKey, a.cidutCnName, a.cidutCnInv, a.cidutDebt, a.cidutCntrPrtNum,
         CASE WHEN a.cidutCnDate IS NULL THEN CAST('19000101' AS date) ELSE CAST(a.cidutCnDate AS date) END AS cidutCnDateNull,
         CASE WHEN a.cidutCnName IS NULL OR LTRIM(RTRIM(a.cidutCnName)) = N'' THEN N'NullИлиПусто' ELSE LTRIM(RTRIM(a.cidutCnName)) END AS cidutCnNameNull,
         CASE WHEN a.cidutCnInv IS NULL OR LTRIM(RTRIM(a.cidutCnInv)) = N'' THEN N'NullИлиПусто' ELSE LTRIM(RTRIM(a.cidutCnInv)) END AS cidutCnInvNull
  FROM sudz.CnInvDbtUplTbl AS a WHERE a.cidutUnloadKey = @unload
),
currentMulti AS (
  SELECT e.iKey FROM tblRows AS t
  INNER JOIN existInvAll AS e ON e.cidutCntrPrtNum = t.cidutCntrPrtNum AND e.cidutCnNameNull = t.cidutCnNameNull
    AND e.cidutCnDateNull = t.cidutCnDateNull AND e.cidutCnInvNull = t.cidutCnInvNull
  WHERE e.iKey IS NOT NULL
  GROUP BY e.iKey HAVING COUNT(DISTINCT t.cidutKey) > 1
),
needQueue AS (
  SELECT iKey, N'ambiguous' AS reason FROM ambiguousIKeys
  UNION SELECT iKey, N'multi' FROM multiCtxIKeys
  UNION SELECT iKey, N'multi' FROM histInvDbtMulti
  UNION SELECT iKey, N'multi' FROM histNamedAccMulti
  UNION SELECT iKey, N'multi' FROM currentMulti
),
needQueueBest AS (SELECT iKey, MIN(reason) AS reason FROM needQueue GROUP BY iKey)
SELECT COUNT(*) AS needQueue_cnt, DATEDIFF(ms, @t0, SYSUTCDATETIME()) AS ms FROM needQueueBest;

PRINT '=== DONE ===';
