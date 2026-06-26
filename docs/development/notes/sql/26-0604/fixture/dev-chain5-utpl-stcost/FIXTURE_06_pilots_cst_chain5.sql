USE [FishEye];
GO
-- =============================================================================
-- FIXTURE_06_pilots_cst_chain5.sql
-- Dev-only: golden UtPl для 5–10 пилотных строек с тремя пунктами ИП (этап 18.7.2c).
-- Предусловие: FIXTURE_06_00 + FIXTURE_06_01 (группы 18–20, swap ipgcrvUtPlGr).
-- cstAgPn=2102 пропускается (уже в FIXTURE_06_golden_cst_2102.sql).
-- =============================================================================
SET NOCOUNT ON;
GO

DECLARE @batchId uniqueidentifier = NEWID();
DECLARE @ipgCh int = 5;

PRINT N'=== FIXTURE_06_pilots: chain=' + CAST(@ipgCh AS nvarchar)
    + N' batch=' + CAST(@batchId AS nvarchar(36)) + N' ===';

IF OBJECT_ID(N'ags._fixture_utpl06_log', N'U') IS NULL
BEGIN
    RAISERROR(N'Run FIXTURE_06_00_setup_journal.sql first.', 16, 1);
    RETURN;
END;

IF NOT EXISTS (
    SELECT 1 FROM ags.ipgChRlV
    WHERE ipgcrvChain = @ipgCh AND ipgcrvIpg = 6 AND ipgcrvUtPlGr = 18
)
BEGIN
    RAISERROR(N'ipgcrvUtPlGr not swapped. Run FIXTURE_06_01_swap_utplgr.sql first.', 16, 1);
    RETURN;
END;

IF OBJECT_ID('tempdb..#pilots') IS NOT NULL DROP TABLE #pilots;
CREATE TABLE #pilots (cstAgPn int NOT NULL PRIMARY KEY);
INSERT INTO #pilots (cstAgPn) VALUES
    (121), (631), (1251), (1608), (1713), (2080), (2146), (2212);

IF OBJECT_ID('tempdb..#targets') IS NOT NULL DROP TABLE #targets;
SELECT
    pl.cstAgPn,
    p.ipgpKey,
    p.ipgpIpg,
    v.ipgcrvUtPlGr,
    CASE p.ipgpIpg WHEN 6 THEN 201 WHEN 8 THEN 202 WHEN 11 THEN 203 END AS iuplpPl,
    CASE p.ipgpIpg WHEN 6 THEN 'E' WHEN 8 THEN 'M' WHEN 11 THEN 'L' END AS prof,
    COALESCE(l212.ipgplLim, p.ipgpSmTtl, 0) AS lim212,
    COALESCE(l195.ipgplLim, p.ipgpSmWrk, 0) AS lim195,
    COALESCE(l172.ipgplLim, p.ipgpSmEqu, 0) AS lim172,
    COALESCE(l187.ipgplLim, p.ipgpSmOth, 0) AS lim187
INTO #targets
FROM #pilots pl
INNER JOIN ags.ipgPn p ON p.ipgpCstAgPn = pl.cstAgPn AND p.ipgpSh = 1
INNER JOIN ags.ipgChRlV v ON v.ipgcrvIpg = p.ipgpIpg AND v.ipgcrvChain = @ipgCh
LEFT JOIN ags.ipgPnLim l212 ON l212.ipgplPn = p.ipgpKey AND l212.ipgplStCost = 212
LEFT JOIN ags.ipgPnLim l195 ON l195.ipgplPn = p.ipgpKey AND l195.ipgplStCost = 195
LEFT JOIN ags.ipgPnLim l172 ON l172.ipgplPn = p.ipgpKey AND l172.ipgplStCost = 172
LEFT JOIN ags.ipgPnLim l187 ON l187.ipgplPn = p.ipgpKey AND l187.ipgplStCost = 187
WHERE NOT EXISTS (
    SELECT 1
    FROM ags.ipgUtPlP up
    INNER JOIN ags.ipgUtPlGrP gp ON gp.iuplgpPl = up.iuplpPl AND gp.iuplgpGr = v.ipgcrvUtPlGr
    INNER JOIN ags.ipgUtPlPnLmMn m ON m.iuplpmPlPn = up.iuplpKey AND m.iuplpmStCost = 212
    WHERE up.iuplpIpgPn = p.ipgpKey
);

DECLARE @tgt int = (SELECT COUNT(*) FROM #targets);
DECLARE @np int = (SELECT COUNT(*) FROM #pilots);
DECLARE @exp int = @np * 3;
RAISERROR(N'  pilot cst=%d  targets ipgp=%d (expect up to %d)', 0, 1, @np, @tgt, @exp) WITH NOWAIT;

IF @tgt = 0
BEGIN
    RAISERROR(N'All pilot targets already have golden UtPl.', 0, 1) WITH NOWAIT;
    RETURN;
END;

DECLARE @ipgpKey int, @iuplpPl int, @prof char(1), @cst int;
DECLARE @lim212 decimal(23, 8), @lim195 decimal(23, 8), @lim172 decimal(23, 8), @lim187 decimal(23, 8);
DECLARE @iuplpKey int;

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT cstAgPn, ipgpKey, iuplpPl, prof, lim212, lim195, lim172, lim187
    FROM #targets
    ORDER BY cstAgPn, ipgpIpg;
OPEN cur;
FETCH NEXT FROM cur INTO @cst, @ipgpKey, @iuplpPl, @prof, @lim212, @lim195, @lim172, @lim187;

WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRAN;

    INSERT INTO ags.ipgUtPlP (iuplpPl, iuplpLim, iuplpIpgPn)
    VALUES (@iuplpPl, @lim212, @ipgpKey);
    SET @iuplpKey = SCOPE_IDENTITY();

    INSERT INTO ags._fixture_utpl06_log (batchId, action, iuplpKey, ipgpKey, note)
    VALUES (@batchId, N'INSERT_PLP', @iuplpKey, @ipgpKey,
            N'cst=' + CAST(@cst AS nvarchar) + N' pl=' + CAST(@iuplpPl AS nvarchar) + N' prof=' + @prof);

    ;WITH mn AS (
        SELECT n AS iuplpmMn FROM (VALUES (1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12)) v(n)
    ),
    st AS (
        SELECT s AS iuplpmStCost, l AS lim_val
        FROM (VALUES (212, @lim212), (195, @lim195), (172, @lim172), (187, @lim187)) x(s, l)
    ),
    grid AS (
        SELECT mn.iuplpmMn, st.iuplpmStCost, st.lim_val FROM mn CROSS JOIN st
    ),
    calc AS (
        SELECT g.iuplpmMn, g.iuplpmStCost,
            CAST(
                CASE
                    WHEN @prof = 'E' THEN CASE
                        WHEN g.iuplpmMn < 12 THEN CAST(g.lim_val / 12.0 AS decimal(23, 8))
                        ELSE g.lim_val - 11 * CAST(g.lim_val / 12.0 AS decimal(23, 8))
                    END
                    WHEN @prof = 'M' THEN g.lim_val * CASE
                        WHEN g.iuplpmMn = 4 THEN 0.25
                        WHEN g.iuplpmMn = 7 THEN 0.35
                        WHEN g.iuplpmMn = 9 THEN 0.40
                        ELSE 0
                    END
                    WHEN @prof = 'L' THEN g.lim_val * CASE
                        WHEN g.iuplpmMn = 9 THEN 0.40
                        WHEN g.iuplpmMn = 11 THEN 0.60
                        ELSE 0
                    END
                    ELSE 0
                END AS decimal(23, 8)
            ) AS iuplpmLim
        FROM grid g
    )
    INSERT INTO ags.ipgUtPlPnLmMn (iuplpmPlPn, iuplpmStCost, iuplpmMn, iuplpmLim)
    OUTPUT @batchId, N'INSERT_MN', NULL, NULL, NULL, NULL, NULL, NULL, NULL,
           inserted.iuplpmPlPn, @ipgpKey, inserted.iuplpmKey,
           N'cst=' + CAST(@cst AS nvarchar)
    INTO ags._fixture_utpl06_log (
        batchId, action, iuplgKey, iuplKey, iuplgpKey,
        ipgcrvKey, ipgcrvIpg, utPlGr_before, utPlGr_after,
        iuplpKey, ipgpKey, iuplpmKey, note
    )
    SELECT @iuplpKey, c.iuplpmStCost, c.iuplpmMn, c.iuplpmLim FROM calc c
    WHERE c.iuplpmLim > 0;

    COMMIT;

    FETCH NEXT FROM cur INTO @cst, @ipgpKey, @iuplpPl, @prof, @lim212, @lim195, @lim172, @lim187;
END;

CLOSE cur; DEALLOCATE cur;

SELECT t.cstAgPn, COUNT(*) AS ipgp_done
FROM #targets t
GROUP BY t.cstAgPn
ORDER BY t.cstAgPn;

PRINT N'  batchId=' + CAST(@batchId AS nvarchar(36));
GO
