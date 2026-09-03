-- Isolate: NOT EXISTS in invMatchRank CASE vs set-based #hasExtPit (unload 902).
SET NOCOUNT ON;
DECLARE @u int = 902;
DECLARE @t0 datetime2;
DECLARE @ms int;
DECLARE @n bigint;
DECLARE @rank0 bigint;

IF OBJECT_ID('tempdb..#eig') IS NOT NULL DROP TABLE #eig;
;WITH tbl AS (
  SELECT a.cidutCntrPrtNum, a.cidutCntrPrtName, a.cidutCntrPrtITN,
         a.cidutCnName, a.cidutCnDate, a.cidutCnInv, a.cidutAccount,
         CASE WHEN a.cidutCnDate IS NULL THEN CAST('19000101' AS date) ELSE CAST(a.cidutCnDate AS date) END AS cidutCnDateNull,
         CASE WHEN a.cidutCnName IS NULL OR LTRIM(RTRIM(a.cidutCnName)) = N'' THEN N'NullИлиПусто' ELSE LTRIM(RTRIM(a.cidutCnName)) END AS cidutCnNameNull,
         CASE WHEN a.cidutCnInv IS NULL OR LTRIM(RTRIM(a.cidutCnInv)) = N'' THEN N'NullИлиПусто' ELSE LTRIM(RTRIM(a.cidutCnInv)) END AS cidutCnInvNull
  FROM sudz.CnInvDbtUplTbl AS a WHERE a.cidutUnloadKey = @u
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
)
SELECT * INTO #eig FROM existInvGrouped OPTION (RECOMPILE);

PRINT 'B1: invCand base + pitApply (no CASE NOT EXISTS)';
SET @t0 = SYSUTCDATETIME();
SELECT @n = COUNT_BIG(*)
FROM #eig AS f
INNER JOIN ags.cnInv AS ci ON ci.ciCn = f.cn_key
INNER JOIN ags.inv AS inv ON inv.iKey = ci.ciInv
INNER JOIN ags.invNum AS n ON n.inInv = inv.iKey
OUTER APPLY (
  SELECT COUNT(DISTINCT dv.dvUpl) AS pitHistCnt
  FROM sudz.invDbt AS id
  INNER JOIN sudz.DbtValue AS dv ON dv.dvInvDbt = id.idKey
  WHERE id.idInv = inv.iKey AND dv.dvUpl IN (801, 802, 803)
) AS pit
WHERE (n.inNumNull = f.cidutCnInvNull
   OR (f.cidutCnInvNull <> N'NullИлиПусто' AND n.inNum LIKE f.cidutCnInvNull + N' %'))
OPTION (RECOMPILE);
SET @ms = DATEDIFF(millisecond, @t0, SYSUTCDATETIME());
PRINT CONCAT('n=', @n, ' ms=', @ms);

PRINT 'B2: same + CASE with correlated NOT EXISTS';
IF OBJECT_ID('tempdb..#b2') IS NOT NULL DROP TABLE #b2;
SET @t0 = SYSUTCDATETIME();
SELECT
  CASE
    WHEN LTRIM(RTRIM(ISNULL(f.cidutCnInv, N''))) = LTRIM(RTRIM(ISNULL(n.inNum, N'')))
     AND LTRIM(RTRIM(ISNULL(f.cidutCnInv, N''))) <> N''
     AND NOT EXISTS (
       SELECT 1 FROM ags.cnInv AS ciX
       INNER JOIN ags.invNum AS nx ON nx.inInv = ciX.ciInv
       OUTER APPLY (
         SELECT COUNT(DISTINCT dv.dvUpl) AS pitHistCnt
         FROM sudz.invDbt AS id
         INNER JOIN sudz.DbtValue AS dv ON dv.dvInvDbt = id.idKey
         WHERE id.idInv = ciX.ciInv AND dv.dvUpl IN (801, 802, 803)
       ) AS pitX
       WHERE ciX.ciCn = f.cn_key
         AND nx.inNum LIKE f.cidutCnInvNull + N' %'
         AND pitX.pitHistCnt > 0
     ) THEN 0
    WHEN n.inNum LIKE f.cidutCnInvNull + N' %' AND pit.pitHistCnt > 0 THEN 1
    WHEN n.inNumNull = f.cidutCnInvNull AND pit.pitHistCnt > 0 THEN 2
    WHEN LTRIM(RTRIM(ISNULL(f.cidutCnInv, N''))) = LTRIM(RTRIM(ISNULL(n.inNum, N'')))
     AND LTRIM(RTRIM(ISNULL(f.cidutCnInv, N''))) <> N'' THEN 3
    WHEN n.inNumNull = f.cidutCnInvNull THEN 4
    WHEN n.inNum LIKE f.cidutCnInvNull + N' %' THEN 5
    ELSE 99 END AS rankExpr
INTO #b2
FROM #eig AS f
INNER JOIN ags.cnInv AS ci ON ci.ciCn = f.cn_key
INNER JOIN ags.inv AS inv ON inv.iKey = ci.ciInv
INNER JOIN ags.invNum AS n ON n.inInv = inv.iKey
OUTER APPLY (
  SELECT COUNT(DISTINCT dv.dvUpl) AS pitHistCnt
  FROM sudz.invDbt AS id
  INNER JOIN sudz.DbtValue AS dv ON dv.dvInvDbt = id.idKey
  WHERE id.idInv = inv.iKey AND dv.dvUpl IN (801, 802, 803)
) AS pit
WHERE (n.inNumNull = f.cidutCnInvNull
   OR (f.cidutCnInvNull <> N'NullИлиПусто' AND n.inNum LIKE f.cidutCnInvNull + N' %'))
OPTION (RECOMPILE);
SET @ms = DATEDIFF(millisecond, @t0, SYSUTCDATETIME());
SELECT @n = COUNT_BIG(*), @rank0 = SUM(CASE WHEN rankExpr = 0 THEN 1 ELSE 0 END) FROM #b2;
PRINT CONCAT('n=', @n, ' rank0=', @rank0, ' ms=', @ms);

PRINT 'B3: set-based #hasExtPit (cn, invNull with extended PIT competitor)';
IF OBJECT_ID('tempdb..#hasExtPit') IS NOT NULL DROP TABLE #hasExtPit;
SET @t0 = SYSUTCDATETIME();
SELECT DISTINCT f.cn_key, f.cidutCnInvNull
INTO #hasExtPit
FROM #eig AS f
WHERE EXISTS (
  SELECT 1
  FROM ags.cnInv AS ciX
  INNER JOIN ags.invNum AS nx ON nx.inInv = ciX.ciInv
  INNER JOIN sudz.invDbt AS id ON id.idInv = ciX.ciInv
  INNER JOIN sudz.DbtValue AS dv ON dv.dvInvDbt = id.idKey AND dv.dvUpl IN (801,802,803)
  WHERE ciX.ciCn = f.cn_key
    AND nx.inNum LIKE f.cidutCnInvNull + N' %'
)
OPTION (RECOMPILE);
SET @ms = DATEDIFF(millisecond, @t0, SYSUTCDATETIME());
SELECT @n = COUNT_BIG(*) FROM #hasExtPit;
PRINT CONCAT('hasExtPit n=', @n, ' ms=', @ms);

PRINT 'B4: invCand rank via LEFT JOIN #hasExtPit (no correlated NOT EXISTS)';
IF OBJECT_ID('tempdb..#b4') IS NOT NULL DROP TABLE #b4;
SET @t0 = SYSUTCDATETIME();
SELECT
  CASE
    WHEN LTRIM(RTRIM(ISNULL(f.cidutCnInv, N''))) = LTRIM(RTRIM(ISNULL(n.inNum, N'')))
     AND LTRIM(RTRIM(ISNULL(f.cidutCnInv, N''))) <> N''
     AND hep.cn_key IS NULL THEN 0
    WHEN n.inNum LIKE f.cidutCnInvNull + N' %' AND pit.pitHistCnt > 0 THEN 1
    WHEN n.inNumNull = f.cidutCnInvNull AND pit.pitHistCnt > 0 THEN 2
    WHEN LTRIM(RTRIM(ISNULL(f.cidutCnInv, N''))) = LTRIM(RTRIM(ISNULL(n.inNum, N'')))
     AND LTRIM(RTRIM(ISNULL(f.cidutCnInv, N''))) <> N'' THEN 3
    WHEN n.inNumNull = f.cidutCnInvNull THEN 4
    WHEN n.inNum LIKE f.cidutCnInvNull + N' %' THEN 5
    ELSE 99 END AS rankExpr
INTO #b4
FROM #eig AS f
INNER JOIN ags.cnInv AS ci ON ci.ciCn = f.cn_key
INNER JOIN ags.inv AS inv ON inv.iKey = ci.ciInv
INNER JOIN ags.invNum AS n ON n.inInv = inv.iKey
OUTER APPLY (
  SELECT COUNT(DISTINCT dv.dvUpl) AS pitHistCnt
  FROM sudz.invDbt AS id
  INNER JOIN sudz.DbtValue AS dv ON dv.dvInvDbt = id.idKey
  WHERE id.idInv = inv.iKey AND dv.dvUpl IN (801, 802, 803)
) AS pit
LEFT JOIN #hasExtPit AS hep ON hep.cn_key = f.cn_key AND hep.cidutCnInvNull = f.cidutCnInvNull
WHERE (n.inNumNull = f.cidutCnInvNull
   OR (f.cidutCnInvNull <> N'NullИлиПусто' AND n.inNum LIKE f.cidutCnInvNull + N' %'))
OPTION (RECOMPILE);
SET @ms = DATEDIFF(millisecond, @t0, SYSUTCDATETIME());
SELECT @n = COUNT_BIG(*), @rank0 = SUM(CASE WHEN rankExpr = 0 THEN 1 ELSE 0 END) FROM #b4;
PRINT CONCAT('n=', @n, ' rank0=', @rank0, ' ms=', @ms);

-- sanity: rank histograms
PRINT 'B2 vs B4 rank histogram diff check (counts by rank)';
SELECT 'B2' AS src, rankExpr, COUNT(*) AS cnt FROM #b2 GROUP BY rankExpr
UNION ALL
SELECT 'B4', rankExpr, COUNT(*) FROM #b4 GROUP BY rankExpr
ORDER BY 1, 2;

IF OBJECT_ID('tempdb..#eig') IS NOT NULL DROP TABLE #eig;
IF OBJECT_ID('tempdb..#b2') IS NOT NULL DROP TABLE #b2;
IF OBJECT_ID('tempdb..#b4') IS NOT NULL DROP TABLE #b4;
IF OBJECT_ID('tempdb..#hasExtPit') IS NOT NULL DROP TABLE #hasExtPit;
PRINT '=== done ===';
