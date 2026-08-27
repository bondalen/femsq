/*
 * M2 — E1: вся история ags.cn_inv_dbt → invDbtVar + invDbtDbtVar + DbtValue
 * §1.4: cnNum/invNum по TimeOfEntry ≤ asOf (max), иначе earliest
 * Энтропия: СГК 606012 на split-iKey → sibling idNum 254/253
 * После 06a коллизий (slot,upl) быть не должно; rn=1 — только страховка.
 * lastUpdated: 2026-08-27
 */
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

IF EXISTS (SELECT 1 FROM sudz.DbtValue)
BEGIN
    RAISERROR(N'DbtValue not empty — CLEAR first', 16, 1);
    RETURN;
END
GO

IF OBJECT_ID(N'tempdb..#fact') IS NOT NULL DROP TABLE #fact;
IF OBJECT_ID(N'tempdb..#ctx') IS NOT NULL DROP TABLE #ctx;

/* ---- facts with resolved slot + context keys ---- */
SELECT
    cid.cn_inv_dbt_key AS cidKey,
    cid.cidCnInvAccntCtpt AS ciaKey,
    cid.cn_inv_dbt_upl AS uplKey,
    COALESCE(u.uplStatusOnDate, u.upl_date) AS asOf,
    cid.dbt_ttl AS ttl,
    cid.dbt_overd AS overd,
    cid.cn_inv_date_start AS dateStart,
    cid.cn_inv_date_maturity AS dateMaturity,
    cid.doc_base AS docBase,
    COALESCE(cid.cidTimeOfEntry, GETDATE()) AS timeOfEntry,
    slot.idKey AS invDbtKey,
    s.ciasAccnt AS accnt,
    a.ciaCn_s_org AS cn_s_org,
    ci.ciInv AS iKey,
    ci.ciCn AS cnKey
INTO #fact
FROM ags.cn_inv_dbt AS cid
INNER JOIN ags.cn_inv_dbt_upl AS u ON u.upl_key = cid.cn_inv_dbt_upl
INNER JOIN ags.cnInvAccnt AS a ON a.ciaKey = cid.cidCnInvAccntCtpt
INNER JOIN ags.cnInvAccntSmpl AS s ON s.ciasKey = a.ciaCnInvAccntSmpl
INNER JOIN ags.cnInv AS ci ON ci.ciKey = s.ciasCnInv
INNER JOIN sudz.invDbtCia AS br ON br.idcCia = a.ciaKey
INNER JOIN sudz.invDbt AS slot ON slot.idKey = br.idcInvDbt;

/* remap entropy: large SGK → sibling */
UPDATE f
SET f.invDbtKey = sib.idKey
FROM #fact AS f
INNER JOIN sudz.invDbt AS primarySlot ON primarySlot.idKey = f.invDbtKey
INNER JOIN sudz.invDbt AS sib
    ON sib.idInv = primarySlot.idInv
   AND sib.idNum IN (253, 254)
   AND sib.idNote IN (N'S73-split', N'S73-quarter')
WHERE f.accnt = 606012
  AND primarySlot.idInv IN (336,4786,6766,6770,6776,6798,6801,6812,6814,4480);

CREATE CLUSTERED INDEX IX_fact ON #fact (cidKey);

/* invNum / cnNum §1.4 */
ALTER TABLE #fact ADD invNumKey int NULL, cnNumKey int NULL;

;WITH cand AS (
    SELECT
        f.cidKey,
        n.inKey,
        ROW_NUMBER() OVER (
            PARTITION BY f.cidKey
            ORDER BY
                CASE WHEN n.inTimeOfEntry <= f.asOf THEN 0 ELSE 1 END,
                CASE WHEN n.inTimeOfEntry <= f.asOf THEN n.inTimeOfEntry END DESC,
                CASE WHEN n.inTimeOfEntry <= f.asOf THEN n.inKey END DESC,
                n.inTimeOfEntry ASC,
                n.inKey ASC
        ) AS rn
    FROM #fact AS f
    INNER JOIN ags.invNum AS n ON n.inInv = f.iKey
)
UPDATE f SET f.invNumKey = c.inKey
FROM #fact AS f
INNER JOIN cand AS c ON c.cidKey = f.cidKey AND c.rn = 1;

;WITH cand AS (
    SELECT
        f.cidKey,
        cnn.cnnKey,
        ROW_NUMBER() OVER (
            PARTITION BY f.cidKey
            ORDER BY
                CASE WHEN cnn.cnnTimeOfEntry <= f.asOf THEN 0 ELSE 1 END,
                CASE WHEN cnn.cnnTimeOfEntry <= f.asOf THEN cnn.cnnTimeOfEntry END DESC,
                CASE WHEN cnn.cnnTimeOfEntry <= f.asOf THEN cnn.cnnKey END DESC,
                cnn.cnnTimeOfEntry ASC,
                cnn.cnnKey ASC
        ) AS rn
    FROM #fact AS f
    INNER JOIN ags.cnNum AS cnn ON cnn.cnnCn = f.cnKey AND cnn.cnnType = 1
)
UPDATE f SET f.cnNumKey = c.cnnKey
FROM #fact AS f
INNER JOIN cand AS c ON c.cidKey = f.cidKey AND c.rn = 1;

IF EXISTS (SELECT 1 FROM #fact WHERE invNumKey IS NULL OR cnNumKey IS NULL)
BEGIN
    DECLARE @bad int = (SELECT COUNT(*) FROM #fact WHERE invNumKey IS NULL OR cnNumKey IS NULL);
    RAISERROR(N'E1: unresolved cnNum/invNum for %d facts', 16, 1, @bad);
    RETURN;
END

/* distinct contexts */
SELECT DISTINCT
    cnNumKey AS idvvCnNum,
    invNumKey AS idvvInvNum,
    accnt AS idvvAccnt,
    cn_s_org AS idvvCn_s_org
INTO #ctx
FROM #fact;

INSERT INTO sudz.invDbtVar (idvvCnNum, idvvInvNum, idvvAccnt, idvvCn_s_org, idvvTimeOfEntry)
SELECT c.idvvCnNum, c.idvvInvNum, c.idvvAccnt, c.idvvCn_s_org, GETDATE()
FROM #ctx AS c
WHERE NOT EXISTS (
    SELECT 1 FROM sudz.invDbtVar v
    WHERE v.idvvCnNum = c.idvvCnNum
      AND v.idvvInvNum = c.idvvInvNum
      AND v.idvvAccnt = c.idvvAccnt
      AND v.idvvCn_s_org = c.idvvCn_s_org
);

/* slot↔var bridges needed for trigger */
INSERT INTO sudz.invDbtDbtVar (iddvInvDbt, iddvInvDbtVar, iddvTimeOfEntry)
SELECT DISTINCT f.invDbtKey, v.idvvKey, GETDATE()
FROM #fact AS f
INNER JOIN sudz.invDbtVar AS v
    ON v.idvvCnNum = f.cnNumKey
   AND v.idvvInvNum = f.invNumKey
   AND v.idvvAccnt = f.accnt
   AND v.idvvCn_s_org = f.cn_s_org
WHERE NOT EXISTS (
    SELECT 1 FROM sudz.invDbtDbtVar bv
    WHERE bv.iddvInvDbt = f.invDbtKey AND bv.iddvInvDbtVar = v.idvvKey
);

/* Values — UNIQUE(invDbt, upl): if duplicate cid for same slot+upl, keep max key */
;WITH ranked AS (
    SELECT
        f.*,
        v.idvvKey AS varKey,
        ROW_NUMBER() OVER (
            PARTITION BY f.invDbtKey, f.uplKey
            ORDER BY f.cidKey DESC
        ) AS rn
    FROM #fact AS f
    INNER JOIN sudz.invDbtVar AS v
        ON v.idvvCnNum = f.cnNumKey
       AND v.idvvInvNum = f.invNumKey
       AND v.idvvAccnt = f.accnt
       AND v.idvvCn_s_org = f.cn_s_org
)
INSERT INTO sudz.DbtValue (
    dvInvDbtVar, dvUpl, dvTtl, dvOverd,
    dvDateStart, dvDateMaturity, dvDocBase, dvTimeOfEntry, dvInvDbt
)
SELECT
    r.varKey, r.uplKey, r.ttl, r.overd,
    r.dateStart, r.dateMaturity, LEFT(r.docBase, 255), r.timeOfEntry, r.invDbtKey
FROM ranked AS r
WHERE r.rn = 1;

DECLARE @cid int = (SELECT COUNT(*) FROM ags.cn_inv_dbt);
DECLARE @dv int = (SELECT COUNT(*) FROM sudz.DbtValue);
DECLARE @var int = (SELECT COUNT(*) FROM sudz.invDbtVar);
DECLARE @collapsed int = @cid - @dv;
PRINT CONCAT(N'DbtValue=', @dv, N' / cid=', @cid, N' / vars=', @var, N' / collapsed=', @collapsed);
IF @collapsed <> 0
    RAISERROR(N'E1: DbtValue count %d <> cn_inv_dbt %d (collapsed=%d) — check 06a split', 16, 1, @dv, @cid, @collapsed);
GO
