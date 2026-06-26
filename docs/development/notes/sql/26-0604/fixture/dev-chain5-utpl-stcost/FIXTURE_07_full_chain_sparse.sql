USE [FishEye];
GO
-- =============================================================================
-- FIXTURE_07_full_chain_sparse.sql
-- Dev-only (18.7.4): UtPl в тестовых группах 18–20 для всей цепи 5 (~1889 ipgp).
--   1) COPY: из legacy-групп 3/4/6 → 18/19/20 (только lim>0)
--   2) GEN:  sparse профиль E (равномерно) для ipgp с lim212>0 без источника
-- Предусловие: FIXTURE_06_00 + FIXTURE_06_01 (swap ipgcrvUtPlGr).
-- Журнал: ags._fixture_utpl06_log (action INSERT_PLP_F07 / INSERT_MN_F07).
-- =============================================================================
SET NOCOUNT ON;
GO

DECLARE @batchId uniqueidentifier = NEWID();
DECLARE @ipgCh int = 5;

PRINT N'=== FIXTURE_07: full chain sparse UtPl batch=' + CAST(@batchId AS nvarchar(36)) + N' ===';

IF OBJECT_ID(N'ags._fixture_utpl06_log', N'U') IS NULL
BEGIN
    RAISERROR(N'Run FIXTURE_06_00_setup_journal.sql first.', 16, 1);
    RETURN;
END;

IF NOT EXISTS (SELECT 1 FROM ags.ipgChRlV WHERE ipgcrvChain = 5 AND ipgcrvIpg = 6 AND ipgcrvUtPlGr = 18)
BEGIN
    RAISERROR(N'ipgcrvUtPlGr not swapped. Run FIXTURE_06_01 first.', 16, 1);
    RETURN;
END;

IF EXISTS (SELECT 1 FROM ags._fixture_utpl06_log WHERE action = N'INSERT_PLP_F07')
BEGIN
    RAISERROR(N'FIXTURE_07 already applied. Run FIXTURE_07_99_rollback.sql first.', 16, 1);
    RETURN;
END;

IF OBJECT_ID('tempdb..#tgt') IS NOT NULL DROP TABLE #tgt;
SELECT
    p.ipgpKey,
    v.ipgcrvUtPlGr AS tgt_gr,
    CASE v.ipgcrvUtPlGr WHEN 18 THEN 3 WHEN 19 THEN 4 WHEN 20 THEN 6 END AS src_gr,
    CASE v.ipgcrvUtPlGr WHEN 18 THEN 201 WHEN 19 THEN 202 WHEN 20 THEN 203 END AS iuplpPl,
    COALESCE(l212.ipgplLim, p.ipgpSmTtl, 0) AS lim212,
    COALESCE(l195.ipgplLim, p.ipgpSmWrk, 0) AS lim195,
    COALESCE(l172.ipgplLim, p.ipgpSmEqu, 0) AS lim172,
    COALESCE(l187.ipgplLim, p.ipgpSmOth, 0) AS lim187,
    src.iuplpKey AS src_iuplpKey
INTO #tgt
FROM ags.ipgPn p
INNER JOIN ags.ipgChRlV v ON v.ipgcrvIpg = p.ipgpIpg AND v.ipgcrvChain = @ipgCh
LEFT JOIN ags.ipgPnLim l212 ON l212.ipgplPn = p.ipgpKey AND l212.ipgplStCost = 212
LEFT JOIN ags.ipgPnLim l195 ON l195.ipgplPn = p.ipgpKey AND l195.ipgplStCost = 195
LEFT JOIN ags.ipgPnLim l172 ON l172.ipgplPn = p.ipgpKey AND l172.ipgplStCost = 172
LEFT JOIN ags.ipgPnLim l187 ON l187.ipgplPn = p.ipgpKey AND l187.ipgplStCost = 187
OUTER APPLY (
    SELECT TOP 1 up.iuplpKey
    FROM ags.ipgUtPlP up
    INNER JOIN ags.ipgUtPlGrP gp ON gp.iuplgpPl = up.iuplpPl
        AND gp.iuplgpGr = CASE v.ipgcrvUtPlGr WHEN 18 THEN 3 WHEN 19 THEN 4 WHEN 20 THEN 6 END
    INNER JOIN ags.ipgUtPlPnLmMn m ON m.iuplpmPlPn = up.iuplpKey AND m.iuplpmLim > 0
    WHERE up.iuplpIpgPn = p.ipgpKey
) src
WHERE NOT EXISTS (
    SELECT 1 FROM ags.ipgUtPlP up2
    INNER JOIN ags.ipgUtPlGrP gp2 ON gp2.iuplgpPl = up2.iuplpPl AND gp2.iuplgpGr = v.ipgcrvUtPlGr
    INNER JOIN ags.ipgUtPlPnLmMn m2 ON m2.iuplpmPlPn = up2.iuplpKey AND m2.iuplpmLim > 0
    WHERE up2.iuplpIpgPn = p.ipgpKey
);

DECLARE @tgt_cnt int = (SELECT COUNT(*) FROM #tgt);
PRINT N'  targets (no test-gr UtPl): ' + CAST(@tgt_cnt AS nvarchar(10));

BEGIN TRANSACTION;

IF OBJECT_ID('tempdb..#newplp') IS NOT NULL DROP TABLE #newplp;
CREATE TABLE #newplp (iuplpKey int NOT NULL, ipgpKey int NOT NULL, src_iuplpKey int NULL);

INSERT INTO ags.ipgUtPlP (iuplpPl, iuplpLim, iuplpIpgPn)
OUTPUT inserted.iuplpKey, inserted.iuplpIpgPn, NULL INTO #newplp (iuplpKey, ipgpKey, src_iuplpKey)
SELECT t.iuplpPl, t.lim212, t.ipgpKey
FROM #tgt t;

UPDATE n SET n.src_iuplpKey = t.src_iuplpKey
FROM #newplp n
INNER JOIN #tgt t ON t.ipgpKey = n.ipgpKey;

INSERT INTO ags._fixture_utpl06_log (batchId, action, iuplpKey, ipgpKey, iuplgKey, note)
SELECT @batchId, N'INSERT_PLP_F07', n.iuplpKey, n.ipgpKey, t.tgt_gr,
    CASE WHEN t.src_iuplpKey IS NOT NULL THEN N'copy' ELSE N'gen' END
FROM #newplp n
INNER JOIN #tgt t ON t.ipgpKey = n.ipgpKey;

-- COPY months from legacy
INSERT INTO ags.ipgUtPlPnLmMn (iuplpmPlPn, iuplpmStCost, iuplpmMn, iuplpmLim)
OUTPUT @batchId, N'INSERT_MN_F07', NULL, NULL, NULL, NULL, NULL, NULL, NULL,
       inserted.iuplpmPlPn, NULL, inserted.iuplpmKey, N'copy'
INTO ags._fixture_utpl06_log (
    batchId, action, iuplgKey, iuplKey, iuplgpKey, ipgcrvKey, ipgcrvIpg,
    utPlGr_before, utPlGr_after, iuplpKey, ipgpKey, iuplpmKey, note
)
SELECT n.iuplpKey, m.iuplpmStCost, m.iuplpmMn, m.iuplpmLim
FROM #newplp n
INNER JOIN ags.ipgUtPlPnLmMn m ON m.iuplpmPlPn = n.src_iuplpKey
WHERE n.src_iuplpKey IS NOT NULL AND m.iuplpmLim > 0;

DECLARE @copy_mn int = @@ROWCOUNT;

-- GEN sparse profile E for rows without legacy source and lim212 > 0
;WITH gen_tgt AS (
    SELECT n.iuplpKey, t.lim212, t.lim195, t.lim172, t.lim187
    FROM #newplp n
    INNER JOIN #tgt t ON t.ipgpKey = n.ipgpKey
    WHERE n.src_iuplpKey IS NULL AND t.lim212 > 0
),
mn AS (SELECT n AS iuplpmMn FROM (VALUES (1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12)) v(n)),
st AS (
    SELECT g.iuplpKey, x.iuplpmStCost,
        CASE x.iuplpmStCost
            WHEN 212 THEN g.lim212 WHEN 195 THEN g.lim195
            WHEN 172 THEN g.lim172 WHEN 187 THEN g.lim187
        END AS lim_val
    FROM gen_tgt g
    CROSS JOIN (VALUES (212),(195),(172),(187)) x(iuplpmStCost)
),
calc AS (
    SELECT st.iuplpKey, mn.iuplpmMn, st.iuplpmStCost,
        CAST(CASE
            WHEN mn.iuplpmMn < 12 THEN st.lim_val / 12.0
            ELSE st.lim_val - 11 * CAST(st.lim_val / 12.0 AS decimal(23, 8))
        END AS decimal(23, 8)) AS iuplpmLim
    FROM st
    CROSS JOIN mn
)
INSERT INTO ags.ipgUtPlPnLmMn (iuplpmPlPn, iuplpmStCost, iuplpmMn, iuplpmLim)
OUTPUT @batchId, N'INSERT_MN_F07', NULL, NULL, NULL, NULL, NULL, NULL, NULL,
       inserted.iuplpmPlPn, NULL, inserted.iuplpmKey, N'gen'
INTO ags._fixture_utpl06_log (
    batchId, action, iuplgKey, iuplKey, iuplgpKey, ipgcrvKey, ipgcrvIpg,
    utPlGr_before, utPlGr_after, iuplpKey, ipgpKey, iuplpmKey, note
)
SELECT c.iuplpKey, c.iuplpmStCost, c.iuplpmMn, c.iuplpmLim
FROM calc c
WHERE c.iuplpmLim > 0;

DECLARE @gen_mn int = @@ROWCOUNT;
DECLARE @plp_cnt int = (SELECT COUNT(*) FROM #newplp);

COMMIT TRANSACTION;

PRINT N'  ipgUtPlP inserted: ' + CAST(@plp_cnt AS nvarchar(10));
PRINT N'  UtPlMn copied: ' + CAST(@copy_mn AS nvarchar(10)) + N'  generated: ' + CAST(@gen_mn AS nvarchar(10));
PRINT N'  batchId=' + CAST(@batchId AS nvarchar(36));
GO
