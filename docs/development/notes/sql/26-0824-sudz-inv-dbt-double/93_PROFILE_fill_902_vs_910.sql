-- Profile fill #sudzEia: 902 vs 910 — stages + current Java existInvAll (invCand+pitHist).
-- Target: FishEye / SQL Server 2022 (dev Docker).
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @results TABLE (
  upl int NOT NULL,
  stage nvarchar(48) NOT NULL,
  n bigint NULL,
  ms int NULL
);

DECLARE @u int;
DECLARE @t0 datetime2;
DECLARE @ms int;
DECLARE @n bigint;

DECLARE upl_cur CURSOR LOCAL FAST_FORWARD FOR
  SELECT v FROM (VALUES (902), (910)) AS x(v);
OPEN upl_cur;
FETCH NEXT FROM upl_cur INTO @u;
WHILE @@FETCH_STATUS = 0
BEGIN
  PRINT CONCAT('=== unload ', @u, ' ===');

  -- A0: domain sizes (once per loop is fine)
  SET @t0 = SYSUTCDATETIME();
  SELECT @n = COUNT_BIG(*) FROM sudz.CnInvDbtUplTbl WHERE cidutUnloadKey = @u;
  SET @ms = DATEDIFF(millisecond, @t0, SYSUTCDATETIME());
  INSERT INTO @results VALUES (@u, N'tbl', @n, @ms);

  -- A1: materialize prefix to #eig (through existInvGrouped) — no invCand
  IF OBJECT_ID('tempdb..#eig') IS NOT NULL DROP TABLE #eig;
  SET @t0 = SYSUTCDATETIME();
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
  SET @ms = DATEDIFF(millisecond, @t0, SYSUTCDATETIME());
  SELECT @n = COUNT_BIG(*) FROM #eig;
  INSERT INTO @results VALUES (@u, N'existInvGrouped', @n, @ms);

  SELECT @n = COUNT_BIG(DISTINCT cn_key) FROM #eig;
  INSERT INTO @results VALUES (@u, N'eigg_distinct_cn', @n, NULL);

  SELECT @n = COUNT_BIG(*)
  FROM (SELECT DISTINCT cn_key FROM #eig) e
  INNER JOIN ags.cnInv ci ON ci.ciCn = e.cn_key;
  INSERT INTO @results VALUES (@u, N'cnInv_on_matched_cn', @n, NULL);

  -- A2: invCandRaw COUNT without pitHist / rank CASE
  SET @t0 = SYSUTCDATETIME();
  SELECT @n = COUNT_BIG(*)
  FROM #eig AS f
  INNER JOIN ags.cnInv AS ci ON ci.ciCn = f.cn_key
  INNER JOIN ags.inv AS inv ON inv.iKey = ci.ciInv
  INNER JOIN ags.invNum AS n ON n.inInv = inv.iKey
  WHERE (n.inNumNull = f.cidutCnInvNull
     OR (f.cidutCnInvNull <> N'NullИлиПусто' AND n.inNum LIKE f.cidutCnInvNull + N' %'))
  OPTION (RECOMPILE);
  SET @ms = DATEDIFF(millisecond, @t0, SYSUTCDATETIME());
  INSERT INTO @results VALUES (@u, N'invCandRaw_match', @n, @ms);

  -- A3: same + OUTER APPLY pitHist only (no NOT EXISTS in CASE)
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
  INSERT INTO @results VALUES (@u, N'invCand_plus_pitApply', @n, @ms);

  -- A4: full Java fill INTO #sudzEia (ranking + NOT EXISTS in CASE)
  IF OBJECT_ID('tempdb..#sudzEia') IS NOT NULL DROP TABLE #sudzEia;
  SET @t0 = SYSUTCDATETIME();
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
  ),
  invCand AS (
    SELECT f.cidutCntrPrtNum, f.cidutCntrPrtName, f.cidutCnName,
           f.cidutCnNameNull, f.cidutCnDate, f.cidutCnDateNull,
           f.cidutCnInv, f.cidutCnInvNull, f.cn_key, f.cn_s_org_key,
           ci.ciKey, inv.iKey, n.inKey AS invNumKey,
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
             ELSE 99 END AS invMatchRank,
           ISNULL(pit.pitHistCnt, 0) AS pitHistCnt
    FROM existInvGrouped AS f
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
  ),
  invCiRanked AS (
    SELECT c.*, ROW_NUMBER() OVER (
      PARTITION BY c.cidutCntrPrtNum, c.cidutCnNameNull, c.cidutCnDateNull, c.cidutCnInvNull, c.cn_key
      ORDER BY c.invMatchRank, c.pitHistCnt DESC, c.invNumKey ASC
    ) AS rn
    FROM invCand AS c
    WHERE c.invMatchRank < 99
  ),
  existInvAll AS (
    SELECT f.cidutCntrPrtNum, f.cidutCntrPrtName, f.cidutCnName,
           f.cidutCnNameNull, f.cidutCnDate, f.cidutCnDateNull,
           f.cidutCnInv, f.cidutCnInvNull, f.cn_key, f.cn_s_org_key,
           r.iKey, r.ciKey
    FROM existInvGrouped AS f
    LEFT JOIN invCiRanked AS r
      ON r.cidutCntrPrtNum = f.cidutCntrPrtNum
     AND r.cidutCnNameNull = f.cidutCnNameNull
     AND r.cidutCnDateNull = f.cidutCnDateNull
     AND r.cidutCnInvNull = f.cidutCnInvNull
     AND r.cn_key = f.cn_key
     AND r.rn = 1
  )
  SELECT cidutCntrPrtNum, cidutCntrPrtName, cidutCnName, cidutCnNameNull,
         cidutCnDate, cidutCnDateNull, cidutCnInv, cidutCnInvNull,
         cn_key, cn_s_org_key, iKey, ciKey
  INTO #sudzEia
  FROM existInvAll
  OPTION (RECOMPILE);
  SET @ms = DATEDIFF(millisecond, @t0, SYSUTCDATETIME());
  SELECT @n = COUNT_BIG(*) FROM #sudzEia;
  INSERT INTO @results VALUES (@u, N'fill_java_full', @n, @ms);

  -- A5: old simple fill (92_PROFILE style) for apples-to-apples with Aug baseline
  IF OBJECT_ID('tempdb..#sudzEiaSimple') IS NOT NULL DROP TABLE #sudzEiaSimple;
  SET @t0 = SYSUTCDATETIME();
  ;WITH needInv AS (SELECT DISTINCT cn_key, cidutCnInvNull FROM #eig),
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
    FROM #eig AS f
    LEFT JOIN invCi AS ic ON ic.inNumNull = f.cidutCnInvNull AND ic.ciCn = f.cn_key
  )
  SELECT * INTO #sudzEiaSimple FROM existInvAll OPTION (RECOMPILE);
  SET @ms = DATEDIFF(millisecond, @t0, SYSUTCDATETIME());
  SELECT @n = COUNT_BIG(*) FROM #sudzEiaSimple;
  INSERT INTO @results VALUES (@u, N'fill_simple_92', @n, @ms);

  IF OBJECT_ID('tempdb..#eig') IS NOT NULL DROP TABLE #eig;
  IF OBJECT_ID('tempdb..#sudzEia') IS NOT NULL DROP TABLE #sudzEia;
  IF OBJECT_ID('tempdb..#sudzEiaSimple') IS NOT NULL DROP TABLE #sudzEiaSimple;

  FETCH NEXT FROM upl_cur INTO @u;
END
CLOSE upl_cur;
DEALLOCATE upl_cur;

-- Domain sizes
INSERT INTO @results (upl, stage, n, ms)
SELECT 0, N'domain_invDbt', COUNT_BIG(*), NULL FROM sudz.invDbt;
INSERT INTO @results (upl, stage, n, ms)
SELECT 0, N'domain_DbtValue', COUNT_BIG(*), NULL FROM sudz.DbtValue;
INSERT INTO @results (upl, stage, n, ms)
SELECT 0, N'domain_DbtValue_PIT', COUNT_BIG(*), NULL FROM sudz.DbtValue WHERE dvUpl IN (801,802,803);
INSERT INTO @results (upl, stage, n, ms)
SELECT 0, N'domain_cnInv', COUNT_BIG(*), NULL FROM ags.cnInv;
INSERT INTO @results (upl, stage, n, ms)
SELECT 0, N'domain_invNum', COUNT_BIG(*), NULL FROM ags.invNum;

SELECT upl, stage, n, ms FROM @results
ORDER BY CASE WHEN upl = 0 THEN 0 ELSE 1 END, upl,
  CASE stage
    WHEN N'tbl' THEN 1
    WHEN N'existInvGrouped' THEN 2
    WHEN N'eigg_distinct_cn' THEN 3
    WHEN N'cnInv_on_matched_cn' THEN 4
    WHEN N'invCandRaw_match' THEN 5
    WHEN N'invCand_plus_pitApply' THEN 6
    WHEN N'fill_java_full' THEN 7
    WHEN N'fill_simple_92' THEN 8
    ELSE 50
  END;

PRINT '=== done ===';
