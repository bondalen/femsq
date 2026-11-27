-- =============================================================================
-- §4.3 G-ip (фаза 0): SUM(LmMn) ≈ ipgPnLim по stCost для пунктов с UtPl на цепи 507.
-- ε = 1e-8 млн (ADR 012). Diagnostic — без silent fix.
-- =============================================================================
SET NOCOUNT ON;

DECLARE @ipgCh int = 507;
DECLARE @epsilon decimal(23, 8) = 0.00000001;

IF OBJECT_ID('tempdb..#pn_ut') IS NOT NULL DROP TABLE #pn_ut;
IF OBJECT_ID('tempdb..#lim_ref') IS NOT NULL DROP TABLE #lim_ref;
IF OBJECT_ID('tempdb..#sums') IS NOT NULL DROP TABLE #sums;
IF OBJECT_ID('tempdb..#chk') IS NOT NULL DROP TABLE #chk;

SELECT DISTINCT p.ipgpKey, p.ipgpCstAgPn
INTO #pn_ut
FROM ags.ipgPn p
INNER JOIN ags.ipgChRl_2606 v ON v.ipgcrvIpg = p.ipgpIpg AND v.ipgcrvChain = @ipgCh
WHERE EXISTS (
    SELECT 1
    FROM ags.ipgUtPlPnLmMn m
    INNER JOIN ags.ipgUtPlP up ON up.iuplpKey = m.iuplpmPlPn
    INNER JOIN ags.ipgUtPlGrP gp ON gp.iuplgpPl = up.iuplpPl AND gp.iuplgpGr = v.ipgcrvUtPlGr
    WHERE up.iuplpIpgPn = p.ipgpKey AND m.iuplpmStCost = 212
);

SELECT
    u.ipgpKey,
    u.ipgpCstAgPn,
    COALESCE(l212.ipgplLim, c.ipgpSmTtl, 0) AS ref212,
    COALESCE(l195.ipgplLim, c.ipgpSmWrk, 0) AS ref195,
    COALESCE(l172.ipgplLim, c.ipgpSmEqu, 0) AS ref172,
    COALESCE(l187.ipgplLim, c.ipgpSmOth, 0) AS ref187
INTO #lim_ref
FROM #pn_ut u
INNER JOIN ags.ipgPn c ON c.ipgpKey = u.ipgpKey
LEFT JOIN ags.ipgPnLim l212 ON l212.ipgplPn = u.ipgpKey AND l212.ipgplStCost = 212
LEFT JOIN ags.ipgPnLim l195 ON l195.ipgplPn = u.ipgpKey AND l195.ipgplStCost = 195
LEFT JOIN ags.ipgPnLim l172 ON l172.ipgplPn = u.ipgpKey AND l172.ipgplStCost = 172
LEFT JOIN ags.ipgPnLim l187 ON l187.ipgplPn = u.ipgpKey AND l187.ipgplStCost = 187;

SELECT
    up.iuplpIpgPn AS ipgpKey,
    m.iuplpmStCost,
    SUM(m.iuplpmLim) AS sum_mn
INTO #sums
FROM ags.ipgUtPlPnLmMn m
INNER JOIN ags.ipgUtPlP up ON up.iuplpKey = m.iuplpmPlPn
INNER JOIN #pn_ut u ON u.ipgpKey = up.iuplpIpgPn
WHERE m.iuplpmStCost IN (212, 195, 172, 187)
GROUP BY up.iuplpIpgPn, m.iuplpmStCost;

SELECT
    r.ipgpKey,
    r.ipgpCstAgPn,
    r.ref212, ISNULL(s212.sum_mn, 0) AS sum212, ABS(r.ref212 - ISNULL(s212.sum_mn, 0)) AS d212,
    r.ref195, ISNULL(s195.sum_mn, 0) AS sum195, ABS(r.ref195 - ISNULL(s195.sum_mn, 0)) AS d195,
    r.ref172, ISNULL(s172.sum_mn, 0) AS sum172, ABS(r.ref172 - ISNULL(s172.sum_mn, 0)) AS d172,
    r.ref187, ISNULL(s187.sum_mn, 0) AS sum187, ABS(r.ref187 - ISNULL(s187.sum_mn, 0)) AS d187,
    CASE WHEN ABS(r.ref212 - ISNULL(s212.sum_mn, 0)) <= @epsilon
          AND ABS(r.ref195 - ISNULL(s195.sum_mn, 0)) <= @epsilon
          AND ABS(r.ref172 - ISNULL(s172.sum_mn, 0)) <= @epsilon
          AND ABS(r.ref187 - ISNULL(s187.sum_mn, 0)) <= @epsilon
         THEN 1 ELSE 0 END AS ok
INTO #chk
FROM #lim_ref r
LEFT JOIN #sums s212 ON s212.ipgpKey = r.ipgpKey AND s212.iuplpmStCost = 212
LEFT JOIN #sums s195 ON s195.ipgpKey = r.ipgpKey AND s195.iuplpmStCost = 195
LEFT JOIN #sums s172 ON s172.ipgpKey = r.ipgpKey AND s172.iuplpmStCost = 172
LEFT JOIN #sums s187 ON s187.ipgpKey = r.ipgpKey AND s187.iuplpmStCost = 187;

SELECT
    (SELECT COUNT(*) FROM #pn_ut) AS pn_with_utpl,
    (SELECT COUNT(*) FROM #chk WHERE ok = 1) AS gip_ok,
    (SELECT COUNT(*) FROM #chk WHERE ok = 0) AS gip_fail;

SELECT ipgpKey, ipgpCstAgPn, d212, d195, d172, d187, ok
FROM #chk
ORDER BY ok, d212 DESC;
GO
