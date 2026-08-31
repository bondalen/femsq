/*
 * Stage 1 sum-parity: DbtValue 801/802/803 = point-in-time ags.cn_inv_dbt
 *   801 ← ags upl 26 (asOf 2024-12-31)
 *   802 ← ags upl 27 (asOf 2025-03-31)
 *   803 ← ags upl 28 (asOf 2025-06-30)
 * Не last-asOf-any (06/07). upl 804/901 не трогаем.
 * lastUpdated: 2026-08-31
 */
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

IF OBJECT_ID(N'tempdb..#map') IS NOT NULL DROP TABLE #map;
CREATE TABLE #map (
    sudzUpl int NOT NULL PRIMARY KEY,
    agsUpl  int NOT NULL,
    asOf    date NOT NULL
);

INSERT INTO #map (sudzUpl, agsUpl, asOf)
SELECT s.upl_key, m.agsUpl, COALESCE(s.uplStatusOnDate, CAST(s.upl_date AS date))
FROM (VALUES
    (801, 26),
    (802, 27),
    (803, 28)
) AS m (sudzUpl, agsUpl)
INNER JOIN sudz.cn_inv_dbt_upl AS s ON s.upl_key = m.sudzUpl;

IF (SELECT COUNT(*) FROM #map) <> 3
BEGIN
    RAISERROR(N'09_PIT: expected sudz.cn_inv_dbt_upl 801,802,803', 16, 1);
    RETURN;
END

/* ags source must exist with expected counts */
IF NOT EXISTS (SELECT 1 FROM ags.cn_inv_dbt WHERE cn_inv_dbt_upl = 26)
   OR NOT EXISTS (SELECT 1 FROM ags.cn_inv_dbt WHERE cn_inv_dbt_upl = 27)
   OR NOT EXISTS (SELECT 1 FROM ags.cn_inv_dbt WHERE cn_inv_dbt_upl = 28)
BEGIN
    RAISERROR(N'09_PIT: missing ags.cn_inv_dbt upl 26/27/28', 16, 1);
    RETURN;
END

DECLARE @sudzUpl int;
DECLARE @agsUpl int;
DECLARE @asOf date;

DECLARE map_cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT sudzUpl, agsUpl, asOf FROM #map ORDER BY sudzUpl;

OPEN map_cur;
FETCH NEXT FROM map_cur INTO @sudzUpl, @agsUpl, @asOf;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF OBJECT_ID(N'tempdb..#fact') IS NOT NULL DROP TABLE #fact;

    /* Exactly one ags upl — not asOf<= */
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
        @asOf AS factAsOf
    INTO #fact
    FROM ags.cn_inv_dbt AS cid
    INNER JOIN ags.cnInvAccnt AS a ON a.ciaKey = cid.cidCnInvAccntCtpt
    INNER JOIN ags.cnInvAccntSmpl AS s ON s.ciasKey = a.ciaCnInvAccntSmpl
    INNER JOIN ags.cnInv AS ci ON ci.ciKey = s.ciasCnInv
    INNER JOIN sudz.invDbtCia AS br ON br.idcCia = a.ciaKey
    INNER JOIN sudz.invDbt AS slot ON slot.idKey = br.idcInvDbt
    WHERE cid.cn_inv_dbt_upl = @agsUpl;

    /* remap entropy: large SGK → sibling (как E1 / 06) */
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

    ALTER TABLE #fact ADD invNumKey int NULL, cnNumKey int NULL;

    ;WITH cand AS (
        SELECT
            f.cidKey,
            n.inKey,
            ROW_NUMBER() OVER (
                PARTITION BY f.cidKey
                ORDER BY
                    CASE WHEN n.inTimeOfEntry <= f.factAsOf THEN 0 ELSE 1 END,
                    CASE WHEN n.inTimeOfEntry <= f.factAsOf THEN n.inTimeOfEntry END DESC,
                    CASE WHEN n.inTimeOfEntry <= f.factAsOf THEN n.inKey END DESC,
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
                    CASE WHEN cnn.cnnTimeOfEntry <= f.factAsOf THEN 0 ELSE 1 END,
                    CASE WHEN cnn.cnnTimeOfEntry <= f.factAsOf THEN cnn.cnnTimeOfEntry END DESC,
                    CASE WHEN cnn.cnnTimeOfEntry <= f.factAsOf THEN cnn.cnnKey END DESC,
                    cnn.cnnTimeOfEntry ASC,
                    cnn.cnnKey ASC
            ) AS rn
        FROM #fact AS f
        INNER JOIN ags.cnNum AS cnn ON cnn.cnnCn = f.cnKey AND cnn.cnnType = 1
    )
    UPDATE f SET f.cnNumKey = c.cnnKey
    FROM #fact AS f
    INNER JOIN cand AS c ON c.cidKey = f.cidKey AND c.rn = 1;

    BEGIN TRANSACTION;

    DELETE FROM sudz.DbtValue WHERE dvUpl = @sudzUpl;

    INSERT INTO sudz.invDbtVar (idvvCnNum, idvvInvNum, idvvAccnt, idvvCn_s_org, idvvTimeOfEntry)
    SELECT DISTINCT f.cnNumKey, f.invNumKey, f.accnt, f.cn_s_org, GETDATE()
    FROM #fact AS f
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
    FROM #fact AS f
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
        @sudzUpl,
        f.ttl,
        f.overd,
        f.dateStart,
        f.dateMaturity,
        LEFT(f.docBase, 255),
        f.timeOfEntry,
        f.invDbtKey
    FROM #fact AS f
    INNER JOIN sudz.invDbtVar AS v
        ON v.idvvCnNum = f.cnNumKey
       AND v.idvvInvNum = f.invNumKey
       AND v.idvvAccnt = f.accnt
       AND v.idvvCn_s_org = f.cn_s_org
    WHERE f.invNumKey IS NOT NULL AND f.cnNumKey IS NOT NULL;

    COMMIT TRANSACTION;

    SELECT N'pit_backfill' AS chk, @sudzUpl AS sudzUpl, @agsUpl AS agsUpl,
           COUNT(*) AS n_fact, @asOf AS asOf
    FROM #fact;

    SELECT N'DbtValue' AS chk, @sudzUpl AS sudzUpl, COUNT(*) AS n,
           SUM(CAST(dvTtl AS decimal(28, 2))) AS sum_ttl,
           SUM(CAST(dvOverd AS decimal(28, 2))) AS sum_overd
    FROM sudz.DbtValue WHERE dvUpl = @sudzUpl;

    SELECT N'unresolved' AS chk, @sudzUpl AS sudzUpl, COUNT(*) AS n
    FROM #fact WHERE invNumKey IS NULL OR cnNumKey IS NULL;

    DROP TABLE #fact;

    FETCH NEXT FROM map_cur INTO @sudzUpl, @agsUpl, @asOf;
END

CLOSE map_cur;
DEALLOCATE map_cur;
GO

SELECT N'keep_901' AS chk, COUNT(*) AS n FROM sudz.DbtValue WHERE dvUpl = 901;

SELECT dvUpl, COUNT(*) AS n,
       SUM(CAST(dvTtl AS decimal(28, 2))) AS sum_ttl,
       SUM(CAST(dvOverd AS decimal(28, 2))) AS sum_overd
FROM sudz.DbtValue
WHERE dvUpl IN (801, 802, 803, 901)
GROUP BY dvUpl
ORDER BY dvUpl;
GO
