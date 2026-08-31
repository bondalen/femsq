/*
 * Gate E1′ / Stage1: DbtValue PIT sums ≡ ags.cn_inv_dbt (26/27/28 → 801/802/803).
 * lastUpdated: 2026-08-31
 */
SET NOCOUNT ON;

SELECT N'pit_map' AS chk, m.sudzUpl, m.agsUpl,
       s.n AS sudz_n, s.sum_ttl AS sudz_ttl, s.sum_overd AS sudz_overd,
       a.n AS ags_n, a.sum_ttl AS ags_ttl, a.sum_overd AS ags_overd,
       CASE WHEN s.n = a.n AND s.sum_ttl = a.sum_ttl AND s.sum_overd = a.sum_overd
            THEN N'OK' ELSE N'DIFF' END AS match_flag
FROM (VALUES
    (801, 26), (802, 27), (803, 28)
) AS m (sudzUpl, agsUpl)
OUTER APPLY (
    SELECT COUNT(*) AS n,
           SUM(CAST(dvTtl AS decimal(28, 2))) AS sum_ttl,
           SUM(CAST(dvOverd AS decimal(28, 2))) AS sum_overd
    FROM sudz.DbtValue WHERE dvUpl = m.sudzUpl
) AS s
OUTER APPLY (
    SELECT COUNT(*) AS n,
           SUM(CAST(dbt_ttl AS decimal(28, 2))) AS sum_ttl,
           SUM(CAST(dbt_overd AS decimal(28, 2))) AS sum_overd
    FROM ags.cn_inv_dbt WHERE cn_inv_dbt_upl = m.agsUpl
) AS a
ORDER BY m.sudzUpl;

SELECT N'keep_901' AS chk, COUNT(*) AS n FROM sudz.DbtValue WHERE dvUpl = 901;

SELECT N'L_bridge_ok' AS chk, COUNT(*) AS mismatch
FROM sudz.DbtSlotLinkGroup AS g
INNER JOIN sudz.DbtSlotLinkMember AS m ON m.lid = g.lid
INNER JOIN sudz.invDbt AS s ON s.idInv = m.iKey AND s.idNum = m.idNum
INNER JOIN sudz.invDbtDbt AS b ON b.iddInvDbt = s.idKey
WHERE g.dslgStatus = N'active'
  AND b.iddDbt <> g.canonicalDbtKey;
GO
