USE [FishEye];
GO
-- =============================================================================
-- FIXTURE_04_verify_data.sql
-- Dev-only: инварианты UtPlMn после fixture (цепь 5).
--   A) sum(месяцы@stCost) ≈ ipgplLim / ipgpSm* по каждому stCost
--   B) помесячно: month@212 ≈ month@195+@172+@187
--   C) sparse: нет строк с iuplpmLim <= 0 (Решение 15)
-- =============================================================================
SET NOCOUNT ON;
GO

DECLARE @ipgCh   int = 5;
DECLARE @epsilon decimal(23, 8) = 0.01;

PRINT '=== FIXTURE_04: verify UtPlMn chain=' + CAST(@ipgCh AS varchar(10)) + ' ===';

DECLARE @zero_mn int;
SELECT @zero_mn = COUNT(*)
FROM ags.ipgUtPlPnLmMn m
INNER JOIN ags.ipgUtPlP up ON up.iuplpKey = m.iuplpmPlPn
INNER JOIN ags.ipgPn p ON p.ipgpKey = up.iuplpIpgPn
INNER JOIN ags.ipgChRlV v ON v.ipgcrvIpg = p.ipgpIpg AND v.ipgcrvChain = @ipgCh
WHERE m.iuplpmLim <= 0;

IF @zero_mn > 0
BEGIN
    RAISERROR(N'SPARSE: %d rows iuplpmLim<=0 on chain %d (expect 0).', 16, 1, @zero_mn, @ipgCh);
    RETURN;
END;

;WITH ch AS (
    SELECT DISTINCT p.ipgpKey, p.ipgpSmTtl, p.ipgpSmWrk, p.ipgpSmEqu, p.ipgpSmOth
    FROM ags.ipgPn p
    INNER JOIN ags.ipgChRlV v ON v.ipgcrvIpg = p.ipgpIpg AND v.ipgcrvChain = @ipgCh
),
pn_ut AS (
    SELECT DISTINCT up.iuplpIpgPn AS ipgpKey
    FROM ags.ipgUtPlPnLmMn m
    INNER JOIN ags.ipgUtPlP up ON up.iuplpKey = m.iuplpmPlPn
    INNER JOIN ch ON ch.ipgpKey = up.iuplpIpgPn
    WHERE m.iuplpmStCost = 212
),
lim_ref AS (
    SELECT
        u.ipgpKey,
        COALESCE(l212.ipgplLim, c.ipgpSmTtl) AS ref212,
        COALESCE(l195.ipgplLim, c.ipgpSmWrk, 0) AS ref195,
        COALESCE(l172.ipgplLim, c.ipgpSmEqu, 0) AS ref172,
        COALESCE(l187.ipgplLim, c.ipgpSmOth, 0) AS ref187
    FROM pn_ut u
    INNER JOIN ch c ON c.ipgpKey = u.ipgpKey
    LEFT JOIN ags.ipgPnLim l212 ON l212.ipgplPn = u.ipgpKey AND l212.ipgplStCost = 212
    LEFT JOIN ags.ipgPnLim l195 ON l195.ipgplPn = u.ipgpKey AND l195.ipgplStCost = 195
    LEFT JOIN ags.ipgPnLim l172 ON l172.ipgplPn = u.ipgpKey AND l172.ipgplStCost = 172
    LEFT JOIN ags.ipgPnLim l187 ON l187.ipgplPn = u.ipgpKey AND l187.ipgplStCost = 187
),
sums AS (
    SELECT
        up.iuplpIpgPn AS ipgpKey,
        m.iuplpmStCost,
        SUM(m.iuplpmLim) AS sum_mn
    FROM ags.ipgUtPlPnLmMn m
    INNER JOIN ags.ipgUtPlP up ON up.iuplpKey = m.iuplpmPlPn
    INNER JOIN pn_ut u ON u.ipgpKey = up.iuplpIpgPn
    WHERE m.iuplpmStCost IN (212, 195, 172, 187)
    GROUP BY up.iuplpIpgPn, m.iuplpmStCost
),
pvt AS (
    SELECT
        ipgpKey,
        MAX(CASE WHEN iuplpmStCost = 212 THEN sum_mn END) AS sum212,
        MAX(CASE WHEN iuplpmStCost = 195 THEN sum_mn END) AS sum195,
        MAX(CASE WHEN iuplpmStCost = 172 THEN sum_mn END) AS sum172,
        MAX(CASE WHEN iuplpmStCost = 187 THEN sum_mn END) AS sum187
    FROM sums
    GROUP BY ipgpKey
),
chk_lim AS (
    SELECT
        p.ipgpKey,
        ABS(ISNULL(p.sum212, 0) - r.ref212) AS d212,
        ABS(ISNULL(p.sum195, 0) - r.ref195) AS d195,
        ABS(ISNULL(p.sum172, 0) - r.ref172) AS d172,
        ABS(ISNULL(p.sum187, 0) - r.ref187) AS d187
    FROM pvt p
    INNER JOIN lim_ref r ON r.ipgpKey = p.ipgpKey
)
SELECT
    COUNT(*) AS pn_with_utplmn,
    SUM(CASE WHEN d212 <= @epsilon THEN 1 ELSE 0 END) AS ok212,
    SUM(CASE WHEN d195 <= @epsilon THEN 1 ELSE 0 END) AS ok195,
    SUM(CASE WHEN d172 <= @epsilon THEN 1 ELSE 0 END) AS ok172,
    SUM(CASE WHEN d187 <= @epsilon THEN 1 ELSE 0 END) AS ok187,
    SUM(CASE WHEN d212 > @epsilon OR d195 > @epsilon OR d172 > @epsilon OR d187 > @epsilon THEN 1 ELSE 0 END) AS fail_any
FROM chk_lim;

-- помесячная аддитивность
;WITH ch AS (
    SELECT DISTINCT p.ipgpKey
    FROM ags.ipgPn p
    INNER JOIN ags.ipgChRlV v ON v.ipgcrvIpg = p.ipgpIpg AND v.ipgcrvChain = @ipgCh
),
mn AS (
    SELECT
        m.iuplpmPlPn,
        m.iuplpmMn,
        MAX(CASE WHEN m.iuplpmStCost = 212 THEN m.iuplpmLim END) AS m212,
        ISNULL(MAX(CASE WHEN m.iuplpmStCost = 195 THEN m.iuplpmLim END), 0)
            + ISNULL(MAX(CASE WHEN m.iuplpmStCost = 172 THEN m.iuplpmLim END), 0)
            + ISNULL(MAX(CASE WHEN m.iuplpmStCost = 187 THEN m.iuplpmLim END), 0) AS m3
    FROM ags.ipgUtPlPnLmMn m
    INNER JOIN ags.ipgUtPlP up ON up.iuplpKey = m.iuplpmPlPn
    INNER JOIN ch ON ch.ipgpKey = up.iuplpIpgPn
    WHERE m.iuplpmStCost IN (212, 195, 172, 187)
    GROUP BY m.iuplpmPlPn, m.iuplpmMn
)
SELECT
    COUNT(*) AS month_slices,
    SUM(CASE WHEN m212 IS NOT NULL AND ABS(m212 - m3) <= @epsilon THEN 1 ELSE 0 END) AS month_ok,
    SUM(CASE WHEN m212 IS NOT NULL AND ABS(m212 - m3) > @epsilon THEN 1 ELSE 0 END) AS month_fail
FROM mn;

DECLARE @fail_lim int, @fail_mn int;

SELECT @fail_lim = SUM(CASE WHEN d212 > @epsilon OR d195 > @epsilon OR d172 > @epsilon OR d187 > @epsilon THEN 1 ELSE 0 END)
FROM (
    SELECT
        ABS(ISNULL(p.sum212, 0) - r.ref212) AS d212,
        ABS(ISNULL(p.sum195, 0) - r.ref195) AS d195,
        ABS(ISNULL(p.sum172, 0) - r.ref172) AS d172,
        ABS(ISNULL(p.sum187, 0) - r.ref187) AS d187
    FROM (
        SELECT ipgpKey,
            MAX(CASE WHEN iuplpmStCost = 212 THEN sum_mn END) AS sum212,
            MAX(CASE WHEN iuplpmStCost = 195 THEN sum_mn END) AS sum195,
            MAX(CASE WHEN iuplpmStCost = 172 THEN sum_mn END) AS sum172,
            MAX(CASE WHEN iuplpmStCost = 187 THEN sum_mn END) AS sum187
        FROM (
            SELECT up.iuplpIpgPn AS ipgpKey, m.iuplpmStCost, SUM(m.iuplpmLim) AS sum_mn
            FROM ags.ipgUtPlPnLmMn m
            INNER JOIN ags.ipgUtPlP up ON up.iuplpKey = m.iuplpmPlPn
            INNER JOIN ags.ipgPn p ON p.ipgpKey = up.iuplpIpgPn
            INNER JOIN ags.ipgChRlV v ON v.ipgcrvIpg = p.ipgpIpg AND v.ipgcrvChain = @ipgCh
            WHERE m.iuplpmStCost IN (212, 195, 172, 187)
            GROUP BY up.iuplpIpgPn, m.iuplpmStCost
        ) s GROUP BY ipgpKey
    ) p
    INNER JOIN (
        SELECT u.ipgpKey,
            COALESCE(l212.ipgplLim, c.ipgpSmTtl) AS ref212,
            COALESCE(l195.ipgplLim, c.ipgpSmWrk, 0) AS ref195,
            COALESCE(l172.ipgplLim, c.ipgpSmEqu, 0) AS ref172,
            COALESCE(l187.ipgplLim, c.ipgpSmOth, 0) AS ref187
        FROM (
            SELECT DISTINCT up.iuplpIpgPn AS ipgpKey
            FROM ags.ipgUtPlPnLmMn m
            INNER JOIN ags.ipgUtPlP up ON up.iuplpKey = m.iuplpmPlPn
            INNER JOIN ags.ipgPn p ON p.ipgpKey = up.iuplpIpgPn
            INNER JOIN ags.ipgChRlV v ON v.ipgcrvIpg = p.ipgpIpg AND v.ipgcrvChain = @ipgCh
            WHERE m.iuplpmStCost = 212
        ) u
        INNER JOIN ags.ipgPn c ON c.ipgpKey = u.ipgpKey
        LEFT JOIN ags.ipgPnLim l212 ON l212.ipgplPn = u.ipgpKey AND l212.ipgplStCost = 212
        LEFT JOIN ags.ipgPnLim l195 ON l195.ipgplPn = u.ipgpKey AND l195.ipgplStCost = 195
        LEFT JOIN ags.ipgPnLim l172 ON l172.ipgplPn = u.ipgpKey AND l172.ipgplStCost = 172
        LEFT JOIN ags.ipgPnLim l187 ON l187.ipgplPn = u.ipgpKey AND l187.ipgplStCost = 187
    ) r ON r.ipgpKey = p.ipgpKey
) x;

SELECT @fail_mn = COUNT(*)
FROM (
    SELECT
        m.iuplpmPlPn, m.iuplpmMn,
        MAX(CASE WHEN m.iuplpmStCost = 212 THEN m.iuplpmLim END) AS m212,
        ISNULL(MAX(CASE WHEN m.iuplpmStCost = 195 THEN m.iuplpmLim END), 0)
            + ISNULL(MAX(CASE WHEN m.iuplpmStCost = 172 THEN m.iuplpmLim END), 0)
            + ISNULL(MAX(CASE WHEN m.iuplpmStCost = 187 THEN m.iuplpmLim END), 0) AS m3
    FROM ags.ipgUtPlPnLmMn m
    INNER JOIN ags.ipgUtPlP up ON up.iuplpKey = m.iuplpmPlPn
    INNER JOIN ags.ipgPn p ON p.ipgpKey = up.iuplpIpgPn
    INNER JOIN ags.ipgChRlV v ON v.ipgcrvIpg = p.ipgpIpg AND v.ipgcrvChain = @ipgCh
    WHERE m.iuplpmStCost IN (212, 195, 172, 187)
    GROUP BY m.iuplpmPlPn, m.iuplpmMn
) z
WHERE z.m212 IS NOT NULL AND ABS(z.m212 - z.m3) > @epsilon;

PRINT '  lim_fail_pn: ' + CAST(ISNULL(@fail_lim, 0) AS varchar(10))
    + '  month_fail: ' + CAST(ISNULL(@fail_mn, 0) AS varchar(10))
    + CASE WHEN ISNULL(@fail_lim, 0) = 0 AND ISNULL(@fail_mn, 0) = 0 THEN N'  PASS' ELSE N'  *** FAIL ***' END;
GO
