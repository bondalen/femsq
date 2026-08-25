-- Profile funnel SQL steps for unloadKey=910 (dev SQL Server 2022).
-- Mirrors JdbcSudzDao: fill #sudzEia → AccSmpl from #eia → ensure ctx from #eia.
-- Run in SSMS / sqlcmd; compare ms with UI «шаг: N мс» after redeploy.
SET NOCOUNT ON;
DECLARE @unload int = 910;
DECLARE @t0 datetime2;
DECLARE @ms int;
DECLARE @n int;

PRINT '=== A. fill #sudzEia (existInvAll materialize) ===';
IF OBJECT_ID('tempdb..#sudzEia') IS NOT NULL DROP TABLE #sudzEia;
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
)
SELECT cidutCntrPrtNum, cidutCntrPrtName, cidutCnName, cidutCnNameNull,
       cidutCnDate, cidutCnDateNull, cidutCnInv, cidutCnInvNull,
       cn_key, cn_s_org_key, iKey, ciKey
INTO #sudzEia
FROM existInvAll
OPTION (RECOMPILE);
SET @ms = DATEDIFF(millisecond, @t0, SYSUTCDATETIME());
SELECT @n = COUNT(*) FROM #sudzEia;
PRINT CONCAT('fill #sudzEia rows=', @n, ' ms=', @ms);

PRINT '=== B. AccSmplNot COUNT from #sudzEia ===';
SET @t0 = SYSUTCDATETIME();
;WITH accY AS (
  SELECT t.cidutCntrPrtNum,
         CASE WHEN t.cidutCnDate IS NULL THEN CAST('19000101' AS date) ELSE CAST(t.cidutCnDate AS date) END AS cidutCnDateNull,
         CASE WHEN t.cidutCnName IS NULL OR LTRIM(RTRIM(t.cidutCnName)) = N'' THEN N'NullИлиПусто' ELSE LTRIM(RTRIM(t.cidutCnName)) END AS cidutCnNameNull,
         CASE WHEN t.cidutCnInv IS NULL OR LTRIM(RTRIM(t.cidutCnInv)) = N'' THEN N'NullИлиПусто' ELSE LTRIM(RTRIM(t.cidutCnInv)) END AS cidutCnInvNull,
         acc.account_num, acc.account_key
  FROM sudz.CnInvDbtUplTbl AS t
  INNER JOIN ags.accnt AS acc ON t.cidutAccount = acc.account_key
  WHERE t.cidutUnloadKey = @unload
),
accSmplAll AS (
  SELECT z.ciKey, y.account_key, matched.ciasKey
  FROM #sudzEia AS z
  LEFT JOIN accY AS y
    ON z.cidutCnInvNull = y.cidutCnInvNull
   AND z.cidutCnDateNull = y.cidutCnDateNull
   AND z.cidutCnNameNull = y.cidutCnNameNull
   AND z.cidutCntrPrtNum = y.cidutCntrPrtNum
  OUTER APPLY (
    SELECT TOP 1 s.ciasKey
    FROM ags.cnInvAccntSmpl AS s
    INNER JOIN ags.cn_s_org_smpl AS o ON s.ciasCn_s_org_smpl = o.csosKey
    INNER JOIN ags.org_id AS i ON o.csosOrgId = i.org_id_key
    WHERE s.ciasCnInv = z.ciKey
      AND s.ciasAccnt = y.account_key
      AND i.org_id_value_l = z.cidutCntrPrtNum
  ) AS matched
  WHERE z.ciKey IS NOT NULL
)
SELECT @n = COUNT(*) FROM accSmplAll WHERE ciasKey IS NULL AND account_key IS NOT NULL
OPTION (RECOMPILE);
SET @ms = DATEDIFF(millisecond, @t0, SYSUTCDATETIME());
PRINT CONCAT('AccSmplNot missing=', @n, ' ms=', @ms);

PRINT '=== C. ensure missing+ambiguous COUNT from #sudzEia ===';
SET @t0 = SYSUTCDATETIME();
;WITH accY AS (
  SELECT t.cidutCntrPrtNum,
         CASE WHEN t.cidutCnDate IS NULL THEN CAST('19000101' AS date) ELSE CAST(t.cidutCnDate AS date) END AS cidutCnDateNull,
         CASE WHEN t.cidutCnName IS NULL OR LTRIM(RTRIM(t.cidutCnName)) = N'' THEN N'NullИлиПусто' ELSE LTRIM(RTRIM(t.cidutCnName)) END AS cidutCnNameNull,
         CASE WHEN t.cidutCnInv IS NULL OR LTRIM(RTRIM(t.cidutCnInv)) = N'' THEN N'NullИлиПусто' ELSE LTRIM(RTRIM(t.cidutCnInv)) END AS cidutCnInvNull,
         acc.account_num, acc.account_key
  FROM sudz.CnInvDbtUplTbl AS t
  INNER JOIN ags.accnt AS acc ON t.cidutAccount = acc.account_key
  WHERE t.cidutUnloadKey = @unload
),
cnnUnique AS (
  SELECT n.cnnCn, MIN(n.cnnKey) AS cnnKey FROM ags.cnNum AS n
  WHERE n.cnnType = 1 GROUP BY n.cnnCn HAVING COUNT(*) = 1
),
inUnique AS (
  SELECT n.inInv, n.inNumNull, MIN(n.inKey) AS inKey FROM ags.invNum AS n
  GROUP BY n.inInv, n.inNumNull HAVING COUNT(*) = 1
),
ctxBase AS (
  SELECT DISTINCT z.cidutCntrPrtNum, z.cidutCntrPrtName, z.cidutCnName,
         z.cidutCnDate, z.cidutCnInv, z.cidutCnInvNull, z.iKey,
         z.cn_s_org_key, y.account_key, y.account_num,
         cnn.cnnKey, invn.inKey AS invNumKey
  FROM #sudzEia AS z
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
  SUM(CASE WHEN cnnKey IS NOT NULL AND invNumKey IS NOT NULL AND idvvKey IS NULL THEN 1 ELSE 0 END) AS missing_unique,
  COUNT(DISTINCT CASE
    WHEN cnnKey IS NULL OR invNumKey IS NULL
    THEN CONCAT(cidutCnName, N'|', cidutCnInv, N'|', CAST(iKey AS nvarchar(20)))
  END) AS ambiguous_keys
FROM ctx
OPTION (RECOMPILE);
SET @ms = DATEDIFF(millisecond, @t0, SYSUTCDATETIME());
PRINT CONCAT('ensure snapshot ms=', @ms);

IF OBJECT_ID('tempdb..#sudzEia') IS NOT NULL DROP TABLE #sudzEia;
PRINT '=== done ===';
