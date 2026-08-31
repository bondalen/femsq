/*
 * Variant B (legacy wide): last fact per slot with asOf <= uplStatusOnDate(801).
 * Для Stage1 sum-parity с Access Rslt используйте 09_BACKFILL_DbtValue_pit_ags26_28.sql.
 * lastUpdated: 2026-08-31
 */
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

DECLARE @upl801 int = 801;
DECLARE @asOf801 date = (
    SELECT COALESCE(u.uplStatusOnDate, CAST(u.upl_date AS date))
    FROM sudz.cn_inv_dbt_upl AS u
    WHERE u.upl_key = @upl801
);

IF @asOf801 IS NULL
BEGIN
    RAISERROR(N'06_BACKFILL: sudz.cn_inv_dbt_upl 801 not found', 16, 1);
    RETURN;
END

IF OBJECT_ID(N'tempdb..#fact801') IS NOT NULL DROP TABLE #fact801;

;WITH raw AS (
    SELECT
        cid.cn_inv_dbt_key AS cidKey,
        cid.cidCnInvAccntCtpt AS ciaKey,
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
        ci.ciCn AS cnKey,
        COALESCE(u.uplStatusOnDate, CAST(u.upl_date AS date)) AS asOf,
        ROW_NUMBER() OVER (
            PARTITION BY slot.idKey
            ORDER BY
                COALESCE(u.uplStatusOnDate, CAST(u.upl_date AS date)) DESC,
                cid.cn_inv_dbt_key DESC
        ) AS rn
    FROM ags.cn_inv_dbt AS cid
    INNER JOIN ags.cn_inv_dbt_upl AS u ON u.upl_key = cid.cn_inv_dbt_upl
    INNER JOIN ags.cnInvAccnt AS a ON a.ciaKey = cid.cidCnInvAccntCtpt
    INNER JOIN ags.cnInvAccntSmpl AS s ON s.ciasKey = a.ciaCnInvAccntSmpl
    INNER JOIN ags.cnInv AS ci ON ci.ciKey = s.ciasCnInv
    INNER JOIN sudz.invDbtCia AS br ON br.idcCia = a.ciaKey
    INNER JOIN sudz.invDbt AS slot ON slot.idKey = br.idcInvDbt
    WHERE COALESCE(u.uplStatusOnDate, CAST(u.upl_date AS date)) <= @asOf801
)
SELECT
    r.cidKey, r.ciaKey, r.ttl, r.overd, r.dateStart, r.dateMaturity,
    r.docBase, r.timeOfEntry, r.invDbtKey, r.accnt, r.cn_s_org, r.iKey, r.cnKey, r.asOf
INTO #fact801
FROM raw AS r
WHERE r.rn = 1;

/* remap entropy: large SGK → sibling (как E1) */
UPDATE f
SET f.invDbtKey = sib.idKey
FROM #fact801 AS f
INNER JOIN sudz.invDbt AS primarySlot ON primarySlot.idKey = f.invDbtKey
INNER JOIN sudz.invDbt AS sib
    ON sib.idInv = primarySlot.idInv
   AND sib.idNum IN (253, 254)
   AND sib.idNote IN (N'S73-split', N'S73-quarter')
WHERE f.accnt = 606012
  AND primarySlot.idInv IN (336,4786,6766,6770,6776,6798,6801,6812,6814,4480);

ALTER TABLE #fact801 ADD invNumKey int NULL, cnNumKey int NULL;

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
    FROM #fact801 AS f
    INNER JOIN ags.invNum AS n ON n.inInv = f.iKey
)
UPDATE f SET f.invNumKey = c.inKey
FROM #fact801 AS f
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
    FROM #fact801 AS f
    INNER JOIN ags.cnNum AS cnn ON cnn.cnnCn = f.cnKey AND cnn.cnnType = 1
)
UPDATE f SET f.cnNumKey = c.cnnKey
FROM #fact801 AS f
INNER JOIN cand AS c ON c.cidKey = f.cidKey AND c.rn = 1;

BEGIN TRANSACTION;

DELETE FROM sudz.DbtValue WHERE dvUpl = @upl801;

INSERT INTO sudz.invDbtVar (idvvCnNum, idvvInvNum, idvvAccnt, idvvCn_s_org, idvvTimeOfEntry)
SELECT DISTINCT f.cnNumKey, f.invNumKey, f.accnt, f.cn_s_org, GETDATE()
FROM #fact801 AS f
WHERE f.invNumKey IS NOT NULL AND f.cnNumKey IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM sudz.invDbtVar v
    WHERE v.idvvCnNum = f.cnNumKey
      AND v.idvvInvNum = f.invNumKey
      AND v.idvvAccnt = f.accnt
      AND v.idvvCn_s_org = f.cn_s_org
);

INSERT INTO sudz.invDbtDbtVar (iddvInvDbt, iddvInvDbtVar, iddvTimeOfEntry)
SELECT DISTINCT f.invDbtKey, v.idvvKey, GETDATE()
FROM #fact801 AS f
INNER JOIN sudz.invDbtVar AS v
    ON v.idvvCnNum = f.cnNumKey
   AND v.idvvInvNum = f.invNumKey
   AND v.idvvAccnt = f.accnt
   AND v.idvvCn_s_org = f.cn_s_org
WHERE f.invNumKey IS NOT NULL AND f.cnNumKey IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM sudz.invDbtDbtVar bv
    WHERE bv.iddvInvDbt = f.invDbtKey AND bv.iddvInvDbtVar = v.idvvKey
);

INSERT INTO sudz.DbtValue (
    dvInvDbtVar, dvUpl, dvTtl, dvOverd,
    dvDateStart, dvDateMaturity, dvDocBase, dvTimeOfEntry, dvInvDbt
)
SELECT
    v.idvvKey,
    @upl801,
    f.ttl,
    f.overd,
    f.dateStart,
    f.dateMaturity,
    LEFT(f.docBase, 255),
    f.timeOfEntry,
    f.invDbtKey
FROM #fact801 AS f
INNER JOIN sudz.invDbtVar AS v
    ON v.idvvCnNum = f.cnNumKey
   AND v.idvvInvNum = f.invNumKey
   AND v.idvvAccnt = f.accnt
   AND v.idvvCn_s_org = f.cn_s_org
WHERE f.invNumKey IS NOT NULL AND f.cnNumKey IS NOT NULL;

COMMIT TRANSACTION;

SELECT N'DbtValue_upl801' AS chk, COUNT(*) AS n
FROM sudz.DbtValue WHERE dvUpl = @upl801;

SELECT N'unresolved_ctx' AS chk, COUNT(*) AS n
FROM #fact801 WHERE invNumKey IS NULL OR cnNumKey IS NULL;
GO
