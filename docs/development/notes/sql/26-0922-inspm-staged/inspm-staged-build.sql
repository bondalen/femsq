/*
  InsPmNotLoad — staged materialize (без INSERT в ags.cn_inv_pm).
  Параметр: @uk = ciputUnloadKey / cn_inv_pm_upl.
  Совместимость: SQL Server 2012+ (SELECT INTO #tmp).
  Создано: 2026-09-22. Замеры: docs …/26-0922-inspm-staged/README.md
*/
SET NOCOUNT ON;
DECLARE @uk int = 60; /* сменить: 57,58,59,60,55,… */
DECLARE @t0 datetime2, @wall datetime2 = SYSDATETIME();

IF OBJECT_ID('tempdb..#stg') IS NOT NULL DROP TABLE #stg;
IF OBJECT_ID('tempdb..#ctpt') IS NOT NULL DROP TABLE #ctpt;
IF OBJECT_ID('tempdb..#oneCn') IS NOT NULL DROP TABLE #oneCn;
IF OBJECT_ID('tempdb..#oneInv') IS NOT NULL DROP TABLE #oneInv;
IF OBJECT_ID('tempdb..#cand') IS NOT NULL DROP TABLE #cand;
IF OBJECT_ID('tempdb..#missing') IS NOT NULL DROP TABLE #missing;
IF OBJECT_ID('tempdb..#ready') IS NOT NULL DROP TABLE #ready;
IF OBJECT_ID('tempdb..#docmap') IS NOT NULL DROP TABLE #docmap;
IF OBJECT_ID('tempdb..#prof') IS NOT NULL DROP TABLE #prof;
CREATE TABLE #prof (stage varchar(32) NOT NULL, n int NOT NULL, ms int NOT NULL);

SET @t0 = SYSDATETIME();
SELECT
  a.ciputCntrPrtNum AS CntrPrtNum,
  CASE WHEN a.ciputCnName IS NULL OR LTRIM(RTRIM(a.ciputCnName)) = N''
       THEN N'NullИлиПусто' ELSE LTRIM(RTRIM(a.ciputCnName)) END AS CnName,
  CASE WHEN a.ciputCnInv IS NULL OR LTRIM(RTRIM(a.ciputCnInv)) = N''
       THEN N'NullИлиПусто' ELSE LTRIM(RTRIM(a.ciputCnInv)) END AS ciputCnInv,
  a.ciputAccount,
  LTRIM(RTRIM(a.ciputCnInvDocCode)) AS ciputCnInvDocCode,
  TRY_CAST(LTRIM(RTRIM(a.ciputCnInvDocCode)) AS decimal(18, 0)) AS docKod,
  a.ciputSheetNum, a.ciputUnloadKey,
  ISNULL(a.ciputAgentNum, 9999999) AS ciputAgentNum,
  CASE
    WHEN a.ciputCAC IS NULL OR a.ciputCAC = N'' THEN
      CASE WHEN SUBSTRING(a.ciputLink, 4, 1) = N'-' AND LEN(a.ciputLink) > 10
           THEN LEFT(a.ciputLink, 11) ELSE NULL END
    ELSE
      CASE WHEN SUBSTRING(a.ciputCAC, 4, 1) = N'-' AND LEN(a.ciputCAC) > 10
           THEN LEFT(a.ciputCAC, 11) ELSE NULL END
  END AS cacOrNull,
  a.ciputLink, a.ciputEntryDate, a.ciputDocDate, a.ciputDueDate,
  a.ciputDbtBlns, a.ciputDbtBlnsOverd, a.ciputDbtBlnsOverdNot,
  a.ciputCdtBlns, a.ciputCdtBlnsOverd, a.ciputCdtBlnsOverdNot, a.ciputBlns,
  a.ciputAlligmentDate, a.ciputBaseDate, a.ciputCnInvDocSum,
  a.ciputStornoReason, a.ciputStornoDocCode
INTO #stg
FROM sudz.CnInvPmtUplTbl AS a
WHERE a.ciputUnloadKey = @uk;
INSERT INTO #prof VALUES ('01_stg', @@ROWCOUNT, DATEDIFF(ms, @t0, SYSDATETIME()));

SET @t0 = SYSDATETIME();
SELECT CntrPrtNum, CnName, ciputCnInv, ciputAccount
INTO #ctpt
FROM #stg
WHERE CntrPrtNum IS NOT NULL AND ciputAccount IS NOT NULL
  AND ciputCnInvDocCode IS NOT NULL AND ciputCnInvDocCode <> N''
GROUP BY CntrPrtNum, CnName, ciputCnInv, ciputAccount;
INSERT INTO #prof VALUES ('02_ctpt', @@ROWCOUNT, DATEDIFF(ms, @t0, SYSDATETIME()));

SET @t0 = SYSDATETIME();
SELECT
  z.CntrPrtNum, z.CnName, z.ciputCnInv, z.ciputAccount,
  MIN(c.cn_key) AS cn_key, MIN(os.csosKey) AS csosKey
INTO #oneCn
FROM #ctpt AS z
INNER JOIN ags.org_id AS i
  ON z.CntrPrtNum = i.org_id_value_l AND i.org_id_type = 1
INNER JOIN ags.cn_s_org_smpl AS os ON os.csosOrgId = i.org_id_key
INNER JOIN ags.cn_s AS s ON s.cn_s_key = os.csosCn_s AND s.cn_s_type = 2
INNER JOIN ags.cn AS c ON c.cn_key = s.cn_key
INNER JOIN ags.cnNum AS num
  ON num.cnnCn = c.cn_key AND num.cnnNumNull = z.CnName
GROUP BY z.CntrPrtNum, z.CnName, z.ciputCnInv, z.ciputAccount
HAVING COUNT(DISTINCT c.cn_key) = 1;
INSERT INTO #prof VALUES ('03_oneCn', @@ROWCOUNT, DATEDIFF(ms, @t0, SYSDATETIME()));

SET @t0 = SYSDATETIME();
SELECT
  o.CntrPrtNum, o.CnName, o.ciputCnInv, o.ciputAccount,
  o.cn_key, o.csosKey, MIN(ci.ciKey) AS ciKey
INTO #oneInv
FROM #oneCn AS o
INNER JOIN ags.cnInv AS ci ON ci.ciCn = o.cn_key
INNER JOIN ags.invNum AS n
  ON n.inInv = ci.ciInv AND n.inNumNull = o.ciputCnInv
GROUP BY o.CntrPrtNum, o.CnName, o.ciputCnInv, o.ciputAccount, o.cn_key, o.csosKey
HAVING COUNT(DISTINCT ci.ciKey) = 1;
INSERT INTO #prof VALUES ('04_oneInv', @@ROWCOUNT, DATEDIFF(ms, @t0, SYSDATETIME()));

SET @t0 = SYSDATETIME();
SELECT d.cn_inv_doc_kod AS docKod, MIN(d.cn_inv_doc_key) AS cn_inv_doc_key
INTO #docmap
FROM (SELECT DISTINCT docKod FROM #stg WHERE docKod IS NOT NULL) AS x
INNER JOIN ags.cn_inv_doc AS d ON d.cn_inv_doc_kod = x.docKod
GROUP BY d.cn_inv_doc_kod;
INSERT INTO #prof VALUES ('04b_docmap', @@ROWCOUNT, DATEDIFF(ms, @t0, SYSDATETIME()));

SET @t0 = SYSDATETIME();
SELECT
  f.ciasKey, dm.cn_inv_doc_key, o.cn_key, o.ciKey, o.csosKey, a.account_key,
  s.CntrPrtNum, s.CnName, s.ciputCnInv, s.ciputAccount, s.ciputCnInvDocCode,
  s.ciputSheetNum, s.ciputUnloadKey, s.ciputAgentNum,
  s.cacOrNull, s.ciputLink,
  s.ciputEntryDate, s.ciputDocDate, s.ciputDueDate,
  s.ciputDbtBlns, s.ciputDbtBlnsOverd, s.ciputDbtBlnsOverdNot,
  s.ciputCdtBlns, s.ciputCdtBlnsOverd, s.ciputCdtBlnsOverdNot, s.ciputBlns,
  s.ciputAlligmentDate, s.ciputBaseDate, s.ciputCnInvDocSum,
  s.ciputStornoReason, s.ciputStornoDocCode,
  p.cstapKey
INTO #cand
FROM #oneInv AS o
INNER JOIN ags.accnt AS a ON a.account_num = o.ciputAccount
INNER JOIN ags.cnInvAccntSmpl AS f
  ON f.ciasCnInv = o.ciKey
 AND f.ciasCn_s_org_smpl = o.csosKey
 AND f.ciasAccnt = a.account_key
INNER JOIN #stg AS s
  ON s.CntrPrtNum = o.CntrPrtNum AND s.CnName = o.CnName
 AND s.ciputCnInv = o.ciputCnInv AND s.ciputAccount = o.ciputAccount
INNER JOIN #docmap AS dm ON dm.docKod = s.docKod
LEFT JOIN ags.cstAgPn AS p ON s.cacOrNull = p.cstapIpgPnN;
INSERT INTO #prof VALUES ('05_cand', @@ROWCOUNT, DATEDIFF(ms, @t0, SYSDATETIME()));

SET @t0 = SYSDATETIME();
SELECT ciasKey, cn_inv_doc_key, ciputSheetNum
INTO #missing
FROM (
  SELECT ciasKey, cn_inv_doc_key, ciputSheetNum
  FROM #cand
  GROUP BY ciasKey, cn_inv_doc_key, ciputSheetNum
  EXCEPT
  SELECT ciaCnInvAccntSmpl, cn_inv_doc, [number]
  FROM ags.cn_inv_pm
  WHERE cn_inv_pm_upl = @uk
) AS x;
INSERT INTO #prof VALUES ('06_missing', @@ROWCOUNT, DATEDIFF(ms, @t0, SYSDATETIME()));

SET @t0 = SYSDATETIME();
;WITH agOne AS (
  SELECT s.cn_key, i.org_id_value_l, MIN(os.csosKey) AS AgCsosKey
  FROM (SELECT DISTINCT cn_key FROM #cand) AS k
  INNER JOIN ags.cn_s AS s ON s.cn_key = k.cn_key AND s.cn_s_type = 1
  INNER JOIN ags.cn_s_org_smpl AS os ON os.csosCn_s = s.cn_s_key
  INNER JOIN ags.org_id AS i
    ON i.org_id_key = os.csosOrgId AND i.org_id_type = 1
  GROUP BY s.cn_key, i.org_id_value_l
  HAVING COUNT(DISTINCT os.csosKey) = 1
), ranked AS (
  SELECT
    c.*,
    ag.AgCsosKey,
    ROW_NUMBER() OVER (
      PARTITION BY c.ciasKey, c.cn_inv_doc_key, c.ciputSheetNum
      ORDER BY c.ciputUnloadKey
    ) AS rn
  FROM #cand AS c
  INNER JOIN #missing AS m
    ON c.ciasKey = m.ciasKey
   AND c.cn_inv_doc_key = m.cn_inv_doc_key
   AND c.ciputSheetNum = m.ciputSheetNum
  LEFT JOIN agOne AS ag
    ON c.cn_key = ag.cn_key AND c.ciputAgentNum = ag.org_id_value_l
)
SELECT *
INTO #ready
FROM ranked
WHERE rn = 1;
INSERT INTO #prof VALUES ('07_ready', @@ROWCOUNT, DATEDIFF(ms, @t0, SYSDATETIME()));

SELECT stage, n, ms FROM #prof ORDER BY stage;
SELECT
  @uk AS uk,
  DATEDIFF(ms, @wall, SYSDATETIME()) AS wall_ms,
  (SELECT n FROM #prof WHERE stage = '07_ready') AS ready_n;
/* INSERT в ags.cn_inv_pm — отдельным скриптом после UAT COUNT. */
