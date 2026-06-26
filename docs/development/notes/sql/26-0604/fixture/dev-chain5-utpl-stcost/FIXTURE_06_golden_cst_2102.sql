USE [FishEye];
GO
-- =============================================================================
-- FIXTURE_06_golden_cst_2102.sql
-- Dev-only: sparse UtPl (212/195/172/187) для ipgPn 2037, 3290, 5271
-- (cstAgPn=2102) в тестовых группах 18/19/20. Существующие UtPl в группах 3/4/6 не трогаем.
--
-- Профили (только месяцы с lim>0):
--   2037 (ИП 6, gr 18): равномерно 1/12 → 12×4 = 48 строк
--   3290 (ИП 8, gr 19): mn 4/7/9 → 3×4 = 12 строк
--   5271 (ИП 11, gr 20): mn 9/11 → 2×4 = 8 строк (как FIXTURE_05)
-- =============================================================================
SET NOCOUNT ON;
GO

DECLARE @cstAgPn int = 2102;
DECLARE @batchId uniqueidentifier = NEWID();

PRINT N'=== FIXTURE_06_golden: cstAgPn=' + CAST(@cstAgPn AS nvarchar)
    + N' batch=' + CAST(@batchId AS nvarchar(36)) + N' ===';

IF OBJECT_ID(N'ags._fixture_utpl06_log', N'U') IS NULL
BEGIN
    RAISERROR(N'Run FIXTURE_06_00_setup_journal.sql first.', 16, 1);
    RETURN;
END;

IF NOT EXISTS (
    SELECT 1 FROM ags.ipgChRlV
    WHERE ipgcrvChain = 5 AND ipgcrvIpg = 6 AND ipgcrvUtPlGr = 18
)
BEGIN
    RAISERROR(N'ipgcrvUtPlGr not swapped. Run FIXTURE_06_01_swap_utplgr.sql first.', 16, 1);
    RETURN;
END;

IF OBJECT_ID('tempdb..#golden') IS NOT NULL DROP TABLE #golden;
CREATE TABLE #golden (
    ipgpKey   int NOT NULL PRIMARY KEY,
    iuplpPl   int NOT NULL,
    prof      char(1) NOT NULL  -- E=equal, M=mid, L=late (40/60)
);

INSERT INTO #golden (ipgpKey, iuplpPl, prof) VALUES
    (2037, 201, 'E'),
    (3290, 202, 'M'),
    (5271, 203, 'L');

IF EXISTS (
    SELECT 1 FROM #golden g
    INNER JOIN ags._fixture_utpl06_log l ON l.ipgpKey = g.ipgpKey AND l.action = N'INSERT_MN'
)
BEGIN
    RAISERROR(N'Golden UtPl already applied. Run FIXTURE_06_99_rollback.sql first.', 16, 1);
    RETURN;
END;

-- Удалить пилот FIXTURE_05 на 5271 (план без привязки к группе мешает изоляции)
IF EXISTS (
    SELECT 1 FROM ags.ipgUtPlP up
  INNER JOIN ags._fixture_utpl_stcost_log l ON l.action = N'INSERT_PLP' AND l.iuplpmPlPn = up.iuplpKey
    WHERE up.iuplpIpgPn = 5271
)
BEGIN
    PRINT N'  removing FIXTURE_05 pilot on ipgpPn=5271...';
    DELETE m
    FROM ags.ipgUtPlPnLmMn m
    INNER JOIN ags.ipgUtPlP up ON up.iuplpKey = m.iuplpmPlPn
    INNER JOIN ags._fixture_utpl_stcost_log l ON l.iuplpmKey = m.iuplpmKey AND l.action = N'INSERT'
    WHERE up.iuplpIpgPn = 5271;

    DELETE up
    FROM ags.ipgUtPlP up
    INNER JOIN ags._fixture_utpl_stcost_log l ON l.action = N'INSERT_PLP' AND l.iuplpmPlPn = up.iuplpKey
    WHERE up.iuplpIpgPn = 5271;

    DELETE FROM ags._fixture_utpl_stcost_log
    WHERE action IN (N'INSERT', N'INSERT_PLP')
      AND iuplpmPlPn IN (SELECT iuplpKey FROM ags.ipgUtPlP WHERE iuplpIpgPn = 5271);
END;

IF OBJECT_ID('tempdb..#lim') IS NOT NULL DROP TABLE #lim;
SELECT
    g.ipgpKey,
    g.iuplpPl,
    g.prof,
    COALESCE(l212.ipgplLim, p.ipgpSmTtl, 0) AS lim212,
    COALESCE(l195.ipgplLim, p.ipgpSmWrk, 0) AS lim195,
    COALESCE(l172.ipgplLim, p.ipgpSmEqu, 0) AS lim172,
    COALESCE(l187.ipgplLim, p.ipgpSmOth, 0) AS lim187
INTO #lim
FROM #golden g
INNER JOIN ags.ipgPn p ON p.ipgpKey = g.ipgpKey
LEFT JOIN ags.ipgPnLim l212 ON l212.ipgplPn = p.ipgpKey AND l212.ipgplStCost = 212
LEFT JOIN ags.ipgPnLim l195 ON l195.ipgplPn = p.ipgpKey AND l195.ipgplStCost = 195
LEFT JOIN ags.ipgPnLim l172 ON l172.ipgplPn = p.ipgpKey AND l172.ipgplStCost = 172
LEFT JOIN ags.ipgPnLim l187 ON l187.ipgplPn = p.ipgpKey AND l187.ipgplStCost = 187
WHERE p.ipgpCstAgPn = @cstAgPn;

IF (SELECT COUNT(*) FROM #lim) <> 3
BEGIN
    RAISERROR(N'Expected 3 golden ipgPn on cstAgPn %d.', 16, 1, @cstAgPn);
    RETURN;
END;

DECLARE @ipgpKey int, @iuplpPl int, @prof char(1);
DECLARE @lim212 decimal(23, 8), @lim195 decimal(23, 8), @lim172 decimal(23, 8), @lim187 decimal(23, 8);
DECLARE @iuplpKey int;

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
    SELECT ipgpKey, iuplpPl, prof, lim212, lim195, lim172, lim187 FROM #lim;
OPEN cur;
FETCH NEXT FROM cur INTO @ipgpKey, @iuplpPl, @prof, @lim212, @lim195, @lim172, @lim187;

WHILE @@FETCH_STATUS = 0
BEGIN
  IF EXISTS (
      SELECT 1 FROM ags.ipgUtPlP up
      INNER JOIN ags.ipgUtPlGrP gp ON gp.iuplgpPl = up.iuplpPl
      INNER JOIN ags.ipgUtPlGr gr ON gr.iuplgKey = gp.iuplgpGr
      WHERE up.iuplpIpgPn = @ipgpKey AND gr.iuplgKey IN (18, 19, 20)
  )
  BEGIN
      RAISERROR(N'ipgpPn %d already has golden UtPl in test group.', 16, 1, @ipgpKey);
      CLOSE cur; DEALLOCATE cur;
      RETURN;
  END;

    BEGIN TRAN;

    INSERT INTO ags.ipgUtPlP (iuplpPl, iuplpLim, iuplpIpgPn)
    VALUES (@iuplpPl, @lim212, @ipgpKey);
    SET @iuplpKey = SCOPE_IDENTITY();

    INSERT INTO ags._fixture_utpl06_log (batchId, action, iuplpKey, ipgpKey, note)
    VALUES (@batchId, N'INSERT_PLP', @iuplpKey, @ipgpKey,
            N'pl=' + CAST(@iuplpPl AS nvarchar) + N' prof=' + @prof);

    ;WITH mn AS (
        SELECT n AS iuplpmMn FROM (VALUES (1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12)) v(n)
    ),
    st AS (
        SELECT s AS iuplpmStCost, l AS lim_val
        FROM (VALUES (212, @lim212), (195, @lim195), (172, @lim172), (187, @lim187)) x(s, l)
    ),
    grid AS (
        SELECT mn.iuplpmMn, st.iuplpmStCost, st.lim_val
        FROM mn CROSS JOIN st
    ),
    calc AS (
        SELECT
            g.iuplpmMn,
            g.iuplpmStCost,
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
    OUTPUT
        @batchId, N'INSERT_MN', NULL, NULL, NULL, NULL, NULL, NULL, NULL,
        inserted.iuplpmPlPn, @ipgpKey, inserted.iuplpmKey,
        N'stc=' + CAST(inserted.iuplpmStCost AS nvarchar) + N' mn=' + CAST(inserted.iuplpmMn AS nvarchar)
    INTO ags._fixture_utpl06_log (
        batchId, action, iuplgKey, iuplKey, iuplgpKey,
        ipgcrvKey, ipgcrvIpg, utPlGr_before, utPlGr_after,
        iuplpKey, ipgpKey, iuplpmKey, note
    )
    SELECT @iuplpKey, c.iuplpmStCost, c.iuplpmMn, c.iuplpmLim
    FROM calc c
    WHERE c.iuplpmLim > 0;

    COMMIT;

    DECLARE @mnCnt int = (SELECT COUNT(*) FROM ags.ipgUtPlPnLmMn WHERE iuplpmPlPn = @iuplpKey);
    PRINT N'  ipgpPn=' + CAST(@ipgpKey AS nvarchar) + N' ipgUtPlP=' + CAST(@iuplpKey AS nvarchar)
        + N' UtPlMn=' + CAST(@mnCnt AS nvarchar);

    FETCH NEXT FROM cur INTO @ipgpKey, @iuplpPl, @prof, @lim212, @lim195, @lim172, @lim187;
END;

CLOSE cur;
DEALLOCATE cur;

PRINT N'  batchId=' + CAST(@batchId AS nvarchar(36));
GO
