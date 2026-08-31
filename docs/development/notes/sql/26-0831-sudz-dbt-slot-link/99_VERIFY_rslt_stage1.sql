/*
 * VERIFY Stage 1 Rslt 2025 (801–803, L001–L010, asOfUpl=803).
 * lastUpdated: 2026-08-31
 */
SET NOCOUNT ON;

SELECT N'DbtValue_by_upl' AS chk, dvUpl, COUNT(*) AS n
FROM sudz.DbtValue
WHERE dvUpl IN (801, 802, 803, 804, 901)
GROUP BY dvUpl
ORDER BY dvUpl;

SELECT N'fact_by_upl' AS chk, upl_key, COUNT(DISTINCT dbtKey) AS debts, COUNT(*) AS rows
FROM sudz.vw_Yr_DbtFact
WHERE yr_key = 900 AND upl_key IN (801, 802, 803)
GROUP BY upl_key
ORDER BY upl_key;

SELECT N'L_bridge_ok' AS chk, COUNT(*) AS mismatch
FROM sudz.DbtSlotLinkGroup AS g
INNER JOIN sudz.DbtSlotLinkMember AS m ON m.lid = g.lid
INNER JOIN sudz.invDbt AS s ON s.idInv = m.iKey AND s.idNum = m.idNum
INNER JOIN sudz.invDbtDbt AS b ON b.iddInvDbt = s.idKey
WHERE g.dslgStatus = N'active'
  AND b.iddDbt <> g.canonicalDbtKey;

/* L001 — str.134 */
SELECT N'L001' AS lid, g.canonicalDbtKey, f.upl_key, f.invNumEnum, f.dvTtl, f.dvOverd
FROM sudz.DbtSlotLinkGroup AS g
INNER JOIN sudz.vw_Yr_DbtFact AS f ON f.dbtKey = g.canonicalDbtKey AND f.yr_key = 900
WHERE g.lid = N'L001'
ORDER BY f.upl_key;

/* Эталон 7947 — str.129 */
SELECT TOP 5 N'stable7947' AS tag, f.upl_key, f.dbtKey, f.invNumEnum, f.dvTtl, f.dvOverd, f.CstAgPnCode
FROM sudz.vw_Yr_DbtFact AS f
WHERE f.yr_key = 900
  AND f.upl_key IN (801, 802, 803)
  AND f.invNumEnum = N'7947'
  AND ABS(CAST(f.dvTtl AS decimal(19, 4)) - 70525000.01) < 0.02
ORDER BY f.upl_key;

/* L002–L010 sums @803 (one row per canonical dbt) */
SELECT g.lid, g.canonicalDbtKey, g.matchSum,
       MAX(CASE WHEN f.upl_key = 801 THEN f.invNumEnum END) AS inv_801,
       MAX(CASE WHEN f.upl_key = 802 THEN f.invNumEnum END) AS inv_802,
       MAX(CASE WHEN f.upl_key = 803 THEN f.invNumEnum END) AS inv_803,
       MAX(CASE WHEN f.upl_key = 802 THEN CAST(f.dvTtl AS decimal(19, 4)) END) AS ttl_802
FROM sudz.DbtSlotLinkGroup AS g
LEFT JOIN sudz.vw_Yr_DbtFact AS f
    ON f.dbtKey = g.canonicalDbtKey AND f.yr_key = 900 AND f.upl_key IN (801, 802, 803)
WHERE g.lid LIKE N'L%' AND g.dslgStatus = N'active'
GROUP BY g.lid, g.canonicalDbtKey, g.matchSum
ORDER BY g.lid;
GO
