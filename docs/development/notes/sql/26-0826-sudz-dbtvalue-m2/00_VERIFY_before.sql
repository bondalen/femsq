/*
 * B1-prep P3 / B1 gate: VERIFY before ALTER DbtValue → M2
 *
 * Только SELECT. Не меняет данные.
 * Критерии GO:
 *   - у каждой DbtValue ровно 1 слот через invDbtDbtVar (по dvInvDbtVar)
 *   - 0 дублей (iddvInvDbt, dvUpl) — иначе UNIQUE(dvInvDbt, dvUpl) не взлетит
 *   - (информативно) слот согласован с invDbtDbt для текущего dvDbt
 *
 * Схемы: sudz + test_sudz
 * lastUpdated: 2026-08-26
 */

SET NOCOUNT ON;

PRINT N'=== sudz.DbtValue: slot cardinality via invDbtDbtVar ===';
SELECT
    (SELECT COUNT(*) FROM sudz.DbtValue) AS dv_total,
    SUM(CASE WHEN x.cnt = 0 THEN 1 ELSE 0 END) AS no_slot,
    SUM(CASE WHEN x.cnt = 1 THEN 1 ELSE 0 END) AS one_slot,
    SUM(CASE WHEN x.cnt > 1 THEN 1 ELSE 0 END) AS multi_slot
FROM (
    SELECT dv.dvKey, COUNT(DISTINCT b.iddvInvDbt) AS cnt
    FROM sudz.DbtValue AS dv
    LEFT JOIN sudz.invDbtDbtVar AS b ON b.iddvInvDbtVar = dv.dvInvDbtVar
    GROUP BY dv.dvKey
) AS x;

PRINT N'=== sudz: duplicate (iddvInvDbt, dvUpl) — must be 0 ===';
SELECT COUNT(*) AS dup_pairs
FROM (
    SELECT b.iddvInvDbt, dv.dvUpl
    FROM sudz.DbtValue AS dv
    INNER JOIN sudz.invDbtDbtVar AS b ON b.iddvInvDbtVar = dv.dvInvDbtVar
    GROUP BY b.iddvInvDbt, dv.dvUpl
    HAVING COUNT(*) > 1
) AS d;

PRINT N'=== sudz: backfill preview (dvInvDbt_mapped) ===';
SELECT
    dv.dvKey,
    dv.dvDbt,
    dv.dvInvDbtVar,
    dv.dvUpl,
    b.iddvInvDbt AS dvInvDbt_mapped,
    slot.idInv,
    slot.idNum,
    CASE
        WHEN idd.iddInvDbt IS NULL THEN N'no_idd_for_pair'
        WHEN idd.iddInvDbt = b.iddvInvDbt THEN N'match'
        ELSE N'mismatch'
    END AS vs_idd
FROM sudz.DbtValue AS dv
INNER JOIN sudz.invDbtDbtVar AS b ON b.iddvInvDbtVar = dv.dvInvDbtVar
INNER JOIN sudz.invDbt AS slot ON slot.idKey = b.iddvInvDbt
LEFT JOIN sudz.invDbtDbt AS idd
    ON idd.iddDbt = dv.dvDbt
   AND idd.iddInvDbt = b.iddvInvDbt
ORDER BY dv.dvKey;

PRINT N'=== test_sudz.DbtValue: slot cardinality ===';
SELECT
    (SELECT COUNT(*) FROM test_sudz.DbtValue) AS dv_total,
    SUM(CASE WHEN x.cnt = 0 THEN 1 ELSE 0 END) AS no_slot,
    SUM(CASE WHEN x.cnt = 1 THEN 1 ELSE 0 END) AS one_slot,
    SUM(CASE WHEN x.cnt > 1 THEN 1 ELSE 0 END) AS multi_slot
FROM (
    SELECT dv.dvKey, COUNT(DISTINCT b.iddvInvDbt) AS cnt
    FROM test_sudz.DbtValue AS dv
    LEFT JOIN test_sudz.invDbtDbtVar AS b ON b.iddvInvDbtVar = dv.dvInvDbtVar
    GROUP BY dv.dvKey
) AS x;

PRINT N'=== test_sudz: duplicate (iddvInvDbt, dvUpl) — must be 0 ===';
SELECT COUNT(*) AS dup_pairs
FROM (
    SELECT b.iddvInvDbt, dv.dvUpl
    FROM test_sudz.DbtValue AS dv
    INNER JOIN test_sudz.invDbtDbtVar AS b ON b.iddvInvDbtVar = dv.dvInvDbtVar
    GROUP BY b.iddvInvDbt, dv.dvUpl
    HAVING COUNT(*) > 1
) AS d;

PRINT N'=== GO criteria (expect all 1) ===';
SELECT
    CASE WHEN sudz_card.no_slot = 0 AND sudz_card.one_slot = sudz_card.dv_total AND sudz_card.multi_slot = 0
         THEN 1 ELSE 0 END AS sudz_cardinality_ok,
    CASE WHEN sudz_dup.dup_pairs = 0 THEN 1 ELSE 0 END AS sudz_unique_ok,
    CASE WHEN test_card.no_slot = 0 AND test_card.one_slot = test_card.dv_total AND test_card.multi_slot = 0
         THEN 1 ELSE 0 END AS test_cardinality_ok,
    CASE WHEN test_dup.dup_pairs = 0 THEN 1 ELSE 0 END AS test_unique_ok
FROM
(
    SELECT
        (SELECT COUNT(*) FROM sudz.DbtValue) AS dv_total,
        SUM(CASE WHEN x.cnt = 0 THEN 1 ELSE 0 END) AS no_slot,
        SUM(CASE WHEN x.cnt = 1 THEN 1 ELSE 0 END) AS one_slot,
        SUM(CASE WHEN x.cnt > 1 THEN 1 ELSE 0 END) AS multi_slot
    FROM (
        SELECT dv.dvKey, COUNT(DISTINCT b.iddvInvDbt) AS cnt
        FROM sudz.DbtValue AS dv
        LEFT JOIN sudz.invDbtDbtVar AS b ON b.iddvInvDbtVar = dv.dvInvDbtVar
        GROUP BY dv.dvKey
    ) AS x
) AS sudz_card
CROSS JOIN
(
    SELECT COUNT(*) AS dup_pairs
    FROM (
        SELECT b.iddvInvDbt, dv.dvUpl
        FROM sudz.DbtValue AS dv
        INNER JOIN sudz.invDbtDbtVar AS b ON b.iddvInvDbtVar = dv.dvInvDbtVar
        GROUP BY b.iddvInvDbt, dv.dvUpl
        HAVING COUNT(*) > 1
    ) AS d
) AS sudz_dup
CROSS JOIN
(
    SELECT
        (SELECT COUNT(*) FROM test_sudz.DbtValue) AS dv_total,
        SUM(CASE WHEN x.cnt = 0 THEN 1 ELSE 0 END) AS no_slot,
        SUM(CASE WHEN x.cnt = 1 THEN 1 ELSE 0 END) AS one_slot,
        SUM(CASE WHEN x.cnt > 1 THEN 1 ELSE 0 END) AS multi_slot
    FROM (
        SELECT dv.dvKey, COUNT(DISTINCT b.iddvInvDbt) AS cnt
        FROM test_sudz.DbtValue AS dv
        LEFT JOIN test_sudz.invDbtDbtVar AS b ON b.iddvInvDbtVar = dv.dvInvDbtVar
        GROUP BY dv.dvKey
    ) AS x
) AS test_card
CROSS JOIN
(
    SELECT COUNT(*) AS dup_pairs
    FROM (
        SELECT b.iddvInvDbt, dv.dvUpl
        FROM test_sudz.DbtValue AS dv
        INNER JOIN test_sudz.invDbtDbtVar AS b ON b.iddvInvDbtVar = dv.dvInvDbtVar
        GROUP BY b.iddvInvDbt, dv.dvUpl
        HAVING COUNT(*) > 1
    ) AS d
) AS test_dup;
GO
