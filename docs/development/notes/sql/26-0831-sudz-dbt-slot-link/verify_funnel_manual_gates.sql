-- verify_funnel_manual_gates.sql
-- Gate-проверки ручных стоп-точек воронки 0069 (без UI).
-- Параметр: @uplKey (cidutUnloadKey / ciudUnloadKey / ciusUnloadKey / dvUpl)
-- Целевая платформа: DEV (SQL Server 2022). На prod — только SELECT.

DECLARE @uplKey INT = 902;  -- заменить на нужный upl

-- G2: CnExistCtptNotLoad (0 строк = PASS)
-- Логика = JdbcSudzDao.findDbtUplCnExistCtptNotLoad / ciduCnExistCtptNot
WITH norm AS (
  SELECT a.cidutCntrPrtNum, a.cidutCntrPrtName, a.cidutCntrPrtITN,
         a.cidutCnName, a.cidutCnDate,
         CASE WHEN a.cidutCnDate IS NULL THEN CAST('19000101' AS date)
              ELSE CAST(a.cidutCnDate AS date) END AS cidutCnDateNull,
         CASE WHEN a.cidutCnName IS NULL OR LTRIM(RTRIM(a.cidutCnName)) = N''
              THEN N'NullИлиПусто' ELSE LTRIM(RTRIM(a.cidutCnName)) END AS cidutCnNameNull
  FROM sudz.CnInvDbtUplTbl AS a
  WHERE a.cidutUnloadKey = @uplKey
),
ctptNot AS (
  SELECT z.cidutCntrPrtNum
  FROM (
    SELECT cidutCntrPrtNum, cidutCntrPrtName, cidutCntrPrtITN
    FROM sudz.CnInvDbtUplTbl
    WHERE cidutUnloadKey = @uplKey
    GROUP BY cidutCntrPrtNum, cidutCntrPrtName, cidutCntrPrtITN
  ) AS z
  LEFT JOIN ags.org_id AS x ON z.cidutCntrPrtNum = x.org_id_value_l AND x.org_id_type = 1
  WHERE x.org_id_key IS NULL
),
tblCtptExist AS (
  SELECT DISTINCT n.cidutCntrPrtNum, og.ogNm AS cidutCntrPrtName, n.cidutCntrPrtITN,
         n.cidutCnName, n.cidutCnDate, n.cidutCnDateNull, n.cidutCnNameNull
  FROM norm AS n
  LEFT JOIN ctptNot AS b ON n.cidutCntrPrtNum = b.cidutCntrPrtNum
  INNER JOIN ags.org_id AS oi ON n.cidutCntrPrtNum = oi.org_id_value_l AND oi.org_id_type = 1
  LEFT JOIN ags.og AS og ON oi.org = og.ogKey
  WHERE b.cidutCntrPrtNum IS NULL
),
cnCtptList AS (
  SELECT c.cn_key, num.cnnNumNull AS cn_number, i.org_id_value_l,
         CASE WHEN o.csoCnDate IS NULL THEN CAST('19000101' AS date)
              ELSE CAST(o.csoCnDate AS date) END AS csoCnDateNull
  FROM ags.cn AS c
  INNER JOIN ags.cn_s AS s ON c.cn_key = s.cn_key AND s.cn_s_type = 2
  INNER JOIN ags.cn_s_org_smpl AS m ON s.cn_s_key = m.csosCn_s
  INNER JOIN ags.cn_s_org AS o ON m.csosKey = o.csoCn_s_org_smpl
  INNER JOIN ags.org_id AS i ON m.csosOrgId = i.org_id_key
  INNER JOIN ags.cnNum AS num ON c.cn_key = num.cnnCn
),
cnCtptExistNot AS (
  SELECT DISTINCT k.cidutCntrPrtNum, k.cidutCntrPrtName, k.cidutCntrPrtITN,
         k.cidutCnNameNull, k.cidutCnDateNull
  FROM tblCtptExist AS k
  LEFT JOIN cnCtptList AS l
    ON k.cidutCnNameNull = l.cn_number
   AND k.cidutCntrPrtNum = l.org_id_value_l
   AND k.cidutCnDateNull = l.csoCnDateNull
  WHERE l.cn_key IS NULL
)
SELECT N'G2_CnExistCtptNotLoad' AS gate,
       COUNT(*) AS blocker_count,
       CASE WHEN COUNT(*) = 0 THEN N'PASS' ELSE N'FAIL' END AS status
FROM (
  SELECT z.cidutCntrPrtNum, z.cidutCnNameNull, z.cidutCnDateNull
  FROM cnCtptExistNot AS z
  LEFT JOIN (
    SELECT n.cnnNumNull AS cn_number, o.cn_key
    FROM ags.cn AS o
    INNER JOIN ags.cnNum AS n ON o.cn_key = n.cnnCn
  ) AS y ON z.cidutCnNameNull = y.cn_number
  GROUP BY z.cidutCntrPrtNum, z.cidutCntrPrtName, z.cidutCntrPrtITN,
           z.cidutCnNameNull, z.cidutCnDateNull
  HAVING COUNT(y.cn_key) > 0
) AS g2;

-- G3: КСДСФ open
SELECT N'G3_KSDSF_open' AS gate,
       COUNT(*) AS blocker_count,
       CASE WHEN COUNT(*) = 0 THEN N'PASS' ELSE N'FAIL' END AS status
FROM sudz.CnInvUplSfDouble
WHERE ciusUnloadKey = @uplKey AND ciusStatus = N'open';

-- G4: КСДД open
SELECT N'G4_KSDD_open' AS gate,
       COUNT(*) AS blocker_count,
       CASE WHEN COUNT(*) = 0 THEN N'PASS' ELSE N'FAIL' END AS status
FROM sudz.CnInvUplInvDbtDouble
WHERE ciudUnloadKey = @uplKey AND ciudStatus = N'open';

-- Сводка загрузки
SELECT N'summary' AS gate,
       (SELECT COUNT(*) FROM sudz.CnInvDbtUplTbl WHERE cidutUnloadKey = @uplKey) AS tbl_rows,
       (SELECT COUNT(*) FROM sudz.DbtValue WHERE dvUpl = @uplKey) AS dbt_value_rows;
