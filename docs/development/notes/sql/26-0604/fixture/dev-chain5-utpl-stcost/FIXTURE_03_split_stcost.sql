USE [FishEye];
GO
-- =============================================================================
-- FIXTURE_03_split_stcost.sql
-- Dev-only: для каждой строки ipgUtPlPnLmMn@212 (цепь 5) вставляет строки
-- @195, @172, @187 пропорционально ipgPnLim; строку @212 сохраняет.
-- Остаток округления помесячно — в @187.
-- =============================================================================
SET NOCOUNT ON;
GO

DECLARE @ipgCh   int = 5;
DECLARE @batchId uniqueidentifier = NEWID();
DECLARE @epsilon decimal(23, 8) = 0.00000001;

PRINT '=== FIXTURE_03: split UtPlMn@212 -> 195/172/187 chain='
    + CAST(@ipgCh AS varchar(10)) + ' batch=' + CAST(@batchId AS varchar(36)) + ' ===';

IF OBJECT_ID(N'ags._fixture_utpl_stcost_log', N'U') IS NULL
BEGIN
    RAISERROR(N'Run FIXTURE_00_setup_journal.sql first.', 16, 1);
    RETURN;
END;

DECLARE @existing int;
SELECT @existing = COUNT(*)
FROM ags.ipgUtPlPnLmMn m
INNER JOIN ags.ipgUtPlP up ON up.iuplpKey = m.iuplpmPlPn
INNER JOIN ags.ipgPn p ON p.ipgpKey = up.iuplpIpgPn
INNER JOIN ags.ipgChRlV v ON v.ipgcrvIpg = p.ipgpIpg AND v.ipgcrvChain = @ipgCh
WHERE m.iuplpmStCost IN (195, 172, 187);

IF @existing > 0
BEGIN
    RAISERROR(N'Chain 5 already has %d UtPlMn rows @195/172/187. Run FIXTURE_99_rollback.sql first.', 16, 1, @existing);
    RETURN;
END;

IF OBJECT_ID('tempdb..#src') IS NOT NULL DROP TABLE #src;
IF OBJECT_ID('tempdb..#parts') IS NOT NULL DROP TABLE #parts;

;WITH ch AS (
    SELECT DISTINCT p.ipgpKey, p.ipgpSmTtl, p.ipgpSmWrk, p.ipgpSmEqu, p.ipgpSmOth
    FROM ags.ipgPn p
    INNER JOIN ags.ipgChRlV v ON v.ipgcrvIpg = p.ipgpIpg AND v.ipgcrvChain = @ipgCh
),
lim AS (
    SELECT
        c.ipgpKey,
        c.ipgpSmTtl,
        COALESCE(l212.ipgplLim, c.ipgpSmTtl, 0) AS lim212,
        COALESCE(l195.ipgplLim, c.ipgpSmWrk, 0) AS lim195,
        COALESCE(l172.ipgplLim, c.ipgpSmEqu, 0) AS lim172,
        COALESCE(l187.ipgplLim, c.ipgpSmOth, 0) AS lim187
    FROM ch c
    LEFT JOIN ags.ipgPnLim l212 ON l212.ipgplPn = c.ipgpKey AND l212.ipgplStCost = 212
    LEFT JOIN ags.ipgPnLim l195 ON l195.ipgplPn = c.ipgpKey AND l195.ipgplStCost = 195
    LEFT JOIN ags.ipgPnLim l172 ON l172.ipgplPn = c.ipgpKey AND l172.ipgplStCost = 172
    LEFT JOIN ags.ipgPnLim l187 ON l187.ipgplPn = c.ipgpKey AND l187.ipgplStCost = 187
)
SELECT
    m.iuplpmKey,
    m.iuplpmPlPn,
    m.iuplpmMn,
    m.iuplpmLim AS lim212,
    l.ipgpKey,
    l.lim212 AS base212,
    l.lim195,
    l.lim172,
    l.lim187
INTO #src
FROM ags.ipgUtPlPnLmMn m
INNER JOIN ags.ipgUtPlP up ON up.iuplpKey = m.iuplpmPlPn
INNER JOIN lim l ON l.ipgpKey = up.iuplpIpgPn
WHERE m.iuplpmStCost = 212;

DECLARE @src_cnt int = (SELECT COUNT(*) FROM #src);
PRINT '  source rows @212: ' + CAST(@src_cnt AS varchar(10));

SELECT
    s.iuplpmPlPn,
    s.iuplpmMn,
    st.iuplpmStCost,
    CAST(
        CASE st.iuplpmStCost
            WHEN 195 THEN
                CASE WHEN ABS(s.base212) < @epsilon THEN 0
                     ELSE ROUND(s.lim212 * s.lim195 / s.base212, 8) END
            WHEN 172 THEN
                CASE WHEN ABS(s.base212) < @epsilon THEN 0
                     ELSE ROUND(s.lim212 * s.lim172 / s.base212, 8) END
            WHEN 187 THEN
                CASE WHEN ABS(s.base212) < @epsilon THEN s.lim212
                     ELSE
                        s.lim212
                        - ROUND(s.lim212 * s.lim195 / s.base212, 8)
                        - ROUND(s.lim212 * s.lim172 / s.base212, 8)
                END
        END AS decimal(23, 8)
    ) AS iuplpmLim
INTO #parts
FROM #src s
CROSS JOIN (VALUES (195), (172), (187)) AS st(iuplpmStCost);

-- убрать нулевые части (не вставляем)
DELETE FROM #parts WHERE iuplpmLim IS NULL OR ABS(iuplpmLim) < @epsilon;

DECLARE @ins195 int = 0, @ins172 int = 0, @ins187 int = 0;

BEGIN TRAN;

DECLARE @out TABLE (
    iuplpmKey int,
    iuplpmPlPn int,
    iuplpmStCost int,
    iuplpmMn int,
    iuplpmLim decimal(23, 8)
);

INSERT INTO ags.ipgUtPlPnLmMn (iuplpmPlPn, iuplpmStCost, iuplpmMn, iuplpmLim)
OUTPUT
    inserted.iuplpmKey, inserted.iuplpmPlPn, inserted.iuplpmStCost,
    inserted.iuplpmMn, inserted.iuplpmLim
INTO @out
SELECT p.iuplpmPlPn, p.iuplpmStCost, p.iuplpmMn, p.iuplpmLim
FROM #parts p;

INSERT INTO ags._fixture_utpl_stcost_log
(
    batchId, action, iuplpmKey, iuplpmPlPn, iuplpmStCost, iuplpmMn,
    iuplpmLim_before, iuplpmLim_after
)
SELECT
    @batchId, N'INSERT', o.iuplpmKey, o.iuplpmPlPn, o.iuplpmStCost, o.iuplpmMn,
    NULL, o.iuplpmLim
FROM @out o;

SELECT @ins195 = COUNT(*) FROM @out WHERE iuplpmStCost = 195;
SELECT @ins172 = COUNT(*) FROM @out WHERE iuplpmStCost = 172;
SELECT @ins187 = COUNT(*) FROM @out WHERE iuplpmStCost = 187;

COMMIT;

DECLARE @ins_total int = (SELECT COUNT(*) FROM @out);

PRINT '  inserted @195: ' + CAST(@ins195 AS varchar(10));
PRINT '  inserted @172: ' + CAST(@ins172 AS varchar(10));
PRINT '  inserted @187: ' + CAST(@ins187 AS varchar(10));
PRINT '  total inserted: ' + CAST(@ins_total AS varchar(10));
GO
