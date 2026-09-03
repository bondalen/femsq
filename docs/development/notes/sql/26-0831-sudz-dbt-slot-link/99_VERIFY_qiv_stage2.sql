/*
 * Stage2 QIV gate — A1 sibling duplicate Values (P1 / S76-A.1).
 *
 * Использование:
 *   DECLARE @upl int = 901;
 *   -- затем выполнить запросы ниже, подставив @upl
 *
 * Ожидание:
 *   same_ttl_sibling_dup = 0
 *   multi_slot_legit     — информационно (разные ttl на одном iKey)
 *
 * lastUpdated: 2026-09-01
 */
SET NOCOUNT ON;

DECLARE @upl int = 901;

PRINT N'=== A1: same-ttl sibling duplicates (expect 0) ===';
SELECT @upl AS upl,
       d.idInv AS iKey,
       inv.inNum,
       COUNT(DISTINCT dv.dvInvDbt) AS slot_cnt,
       COUNT(DISTINCT CAST(dv.dvTtl AS decimal(19, 2))) AS ttl_variants,
       SUM(CAST(dv.dvTtl AS decimal(19, 2))) AS sum_ttl
FROM sudz.DbtValue AS dv
INNER JOIN sudz.invDbt AS d ON d.idKey = dv.dvInvDbt
LEFT JOIN ags.invNum AS inv ON inv.inKey = d.idInv
WHERE dv.dvUpl = @upl
GROUP BY d.idInv, inv.inNum, dv.dvUpl
HAVING COUNT(DISTINCT dv.dvInvDbt) > 1
   AND COUNT(DISTINCT CAST(dv.dvTtl AS decimal(19, 2))) = 1;

PRINT N'=== A1b: UX_DbtValue_InvDbtUpl (expect 0 dup slots) ===';
SELECT dv.dvInvDbt, dv.dvUpl, COUNT(*) AS cnt
FROM sudz.DbtValue AS dv
WHERE dv.dvUpl = @upl
GROUP BY dv.dvInvDbt, dv.dvUpl
HAVING COUNT(*) > 1;

PRINT N'=== A1c: one Value per Dbt@upl via invDbtDbt (expect 0) ===';
SELECT idd.iddDbt AS dbtKey, dv.dvUpl, COUNT(*) AS cnt
FROM sudz.DbtValue AS dv
INNER JOIN sudz.invDbtDbt AS idd ON idd.iddInvDbt = dv.dvInvDbt
WHERE dv.dvUpl = @upl
GROUP BY idd.iddDbt, dv.dvUpl
HAVING COUNT(*) > 1;

PRINT N'=== INFO: multi-slot same iKey, different ttl (legit) ===';
SELECT d.idInv AS iKey,
       inv.inNum,
       COUNT(DISTINCT dv.dvInvDbt) AS slot_cnt,
       COUNT(DISTINCT CAST(dv.dvTtl AS decimal(19, 2))) AS ttl_variants
FROM sudz.DbtValue AS dv
INNER JOIN sudz.invDbt AS d ON d.idKey = dv.dvInvDbt
LEFT JOIN ags.invNum AS inv ON inv.inKey = d.idInv
WHERE dv.dvUpl = @upl
GROUP BY d.idInv, inv.inNum
HAVING COUNT(DISTINCT dv.dvInvDbt) > 1
   AND COUNT(DISTINCT CAST(dv.dvTtl AS decimal(19, 2))) > 1
ORDER BY slot_cnt DESC;

PRINT N'=== A2: Value on short inv when extended hist inv on same cn (expect 0) ===';
SELECT @upl AS upl,
       shortInv.inNum AS short_inv,
       extInv.inNum AS hist_inv,
       ci.ciCn AS cn_key,
       CAST(dv.dvTtl AS decimal(19, 2)) AS dv_ttl
FROM sudz.DbtValue AS dv
INNER JOIN sudz.invDbt AS d ON d.idKey = dv.dvInvDbt
INNER JOIN ags.invNum AS shortInv ON shortInv.inInv = d.idInv
INNER JOIN ags.cnInv AS ci ON ci.ciInv = shortInv.inInv
INNER JOIN ags.cnInv AS ci2 ON ci2.ciCn = ci.ciCn
INNER JOIN ags.invNum AS extInv ON extInv.inInv = ci2.ciInv
WHERE dv.dvUpl = @upl
  AND extInv.inNum LIKE shortInv.inNum + N' %'
  AND extInv.inInv <> shortInv.inInv
  AND EXISTS (
      SELECT 1
      FROM sudz.invDbt AS hid
      INNER JOIN sudz.DbtValue AS hdv ON hdv.dvInvDbt = hid.idKey
      WHERE hid.idInv = extInv.inInv
        AND hdv.dvUpl IN (801, 802, 803)
  );

PRINT N'=== A2.1e: Value without matching Tbl.cidutCnInv@upl (expect 0) ===';
SELECT @upl AS upl,
       id.idKey AS slot,
       id.idInv AS iKey,
       n.inNum AS var_inv,
       CAST(dv.dvTtl AS decimal(19, 2)) AS ttl
FROM sudz.DbtValue AS dv
INNER JOIN sudz.invDbt AS id ON id.idKey = dv.dvInvDbt
INNER JOIN sudz.invDbtVar AS v ON v.idvvKey = dv.dvInvDbtVar
INNER JOIN ags.invNum AS n ON n.inKey = v.idvvInvNum
WHERE dv.dvUpl = @upl
  AND NOT EXISTS (
      SELECT 1
      FROM sudz.CnInvDbtUplTbl AS t
      INNER JOIN ags.cnNum AS num
          ON num.cnnNumNull = CASE
               WHEN t.cidutCnName IS NULL OR LTRIM(RTRIM(t.cidutCnName)) = N''
               THEN N'NullИлиПусто' ELSE LTRIM(RTRIM(t.cidutCnName)) END
      INNER JOIN ags.cn AS c ON c.cn_key = num.cnnCn
      INNER JOIN ags.cnInv AS ci ON ci.ciCn = c.cn_key AND ci.ciInv = id.idInv
      INNER JOIN ags.cn_s AS s ON s.cn_key = c.cn_key AND s.cn_s_type = 2
      INNER JOIN ags.cn_s_org_smpl AS m ON m.csosCn_s = s.cn_s_key
      INNER JOIN ags.cn_s_org AS o ON o.csoCn_s_org_smpl = m.csosKey
      INNER JOIN ags.org_id AS i ON i.org_id_key = m.csosOrgId
          AND i.org_id_value_l = t.cidutCntrPrtNum
      WHERE t.cidutUnloadKey = @upl
        AND CASE WHEN t.cidutCnDate IS NULL THEN CAST('19000101' AS date)
                 ELSE CAST(t.cidutCnDate AS date) END
          = CASE WHEN o.csoCnDate IS NULL THEN CAST('19000101' AS date)
                 ELSE CAST(o.csoCnDate AS date) END
        AND ABS(CAST(dv.dvTtl AS decimal(19, 2)) - CAST(t.cidutDebt AS decimal(19, 2))) <= 0.01
        AND LTRIM(RTRIM(ISNULL(t.cidutCnInv, N''))) <> N''
        AND LTRIM(RTRIM(t.cidutCnInv)) = LTRIM(RTRIM(n.inNum))
  );

PRINT N'=== A3: Tbl rows without Value@upl (expect 0 or queue only) ===';
SELECT @upl AS upl,
       t.cidutKey,
       t.cidutCnInv,
       CAST(t.cidutDebt AS decimal(19, 2)) AS debt,
       t.cidutCntrPrtNum
FROM sudz.CnInvDbtUplTbl AS t
WHERE t.cidutUnloadKey = @upl
  AND NOT EXISTS (
      SELECT 1
      FROM sudz.DbtValue AS dv
      INNER JOIN sudz.invDbt AS id ON id.idKey = dv.dvInvDbt
      INNER JOIN ags.cnNum AS num
          ON num.cnnNumNull = CASE
               WHEN t.cidutCnName IS NULL OR LTRIM(RTRIM(t.cidutCnName)) = N''
               THEN N'NullИлиПусто' ELSE LTRIM(RTRIM(t.cidutCnName)) END
      INNER JOIN ags.cn AS c ON c.cn_key = num.cnnCn
      INNER JOIN ags.cnInv AS ci ON ci.ciCn = c.cn_key AND ci.ciInv = id.idInv
      INNER JOIN ags.cn_s AS s ON s.cn_key = c.cn_key AND s.cn_s_type = 2
      INNER JOIN ags.cn_s_org_smpl AS m ON m.csosCn_s = s.cn_s_key
      INNER JOIN ags.cn_s_org AS o ON o.csoCn_s_org_smpl = m.csosKey
      INNER JOIN ags.org_id AS i ON i.org_id_key = m.csosOrgId
          AND i.org_id_value_l = t.cidutCntrPrtNum
      WHERE dv.dvUpl = @upl
        AND CASE WHEN t.cidutCnDate IS NULL THEN CAST('19000101' AS date)
                 ELSE CAST(t.cidutCnDate AS date) END
          = CASE WHEN o.csoCnDate IS NULL THEN CAST('19000101' AS date)
                 ELSE CAST(o.csoCnDate AS date) END
        AND ABS(CAST(dv.dvTtl AS decimal(19, 2)) - CAST(t.cidutDebt AS decimal(19, 2))) <= 0.01
  )
  AND NOT EXISTS (
      SELECT 1 FROM sudz.CnInvUplInvDbtDouble AS q
      WHERE q.ciudCidut = t.cidutKey AND q.ciudUnloadKey = @upl
  );

GO
