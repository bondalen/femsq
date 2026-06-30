USE [FishEye];
GO
-- =============================================================================
-- FIXTURE_01_normalize_utplmn.sql
-- Dev-only: для цепи 5 масштабирует iuplpmLim@212 так, чтобы
--   sum(месяцы) = ipgpSmTtl по каждому пункту UtPl.
-- =============================================================================
SET NOCOUNT ON;
GO

DECLARE @ipgCh   int = 5;
DECLARE @batchId uniqueidentifier = NEWID();
DECLARE @epsilon decimal(23, 8) = 0.00000001;

PRINT '=== FIXTURE_01: normalize UtPlMn@212 chain=' + CAST(@ipgCh AS varchar(10))
    + ' batch=' + CAST(@batchId AS varchar(36)) + ' ===';

IF OBJECT_ID(N'ags._fixture_utpl_stcost_log', N'U') IS NULL
BEGIN
    RAISERROR(N'Run FIXTURE_00_setup_journal.sql first.', 16, 1);
    RETURN;
END;

IF OBJECT_ID('tempdb..#tgt') IS NOT NULL DROP TABLE #tgt;
IF OBJECT_ID('tempdb..#scaled') IS NOT NULL DROP TABLE #scaled;

;WITH ch AS (
    SELECT DISTINCT p.ipgpKey, p.ipgpSmTtl
    FROM ags.ipgPn p
    INNER JOIN ags.ipgChRl_2606 v ON v.ipgcrvIpg = p.ipgpIpg AND v.ipgcrvChain = @ipgCh
),
ut AS (
    SELECT
        up.iuplpKey,
        up.iuplpIpgPn AS ipgpKey,
        ch.ipgpSmTtl,
        SUM(m.iuplpmLim) AS sum_mn
    FROM ags.ipgUtPlPnLmMn m
    INNER JOIN ags.ipgUtPlP up ON up.iuplpKey = m.iuplpmPlPn
    INNER JOIN ch ON ch.ipgpKey = up.iuplpIpgPn
    WHERE m.iuplpmStCost = 212
    GROUP BY up.iuplpKey, up.iuplpIpgPn, ch.ipgpSmTtl
)
SELECT
    u.iuplpKey,
    u.ipgpKey,
    u.ipgpSmTtl,
    u.sum_mn,
    CASE
        WHEN u.sum_mn IS NULL OR ABS(u.sum_mn) < @epsilon THEN CAST(1 AS decimal(28, 12))
        ELSE CAST(u.ipgpSmTtl / u.sum_mn AS decimal(28, 12))
    END AS scale_factor
INTO #tgt
FROM ut u
WHERE u.ipgpSmTtl IS NOT NULL
  AND ABS(ISNULL(u.sum_mn, 0) - u.ipgpSmTtl) > 0.01;

DECLARE @need int = (SELECT COUNT(*) FROM #tgt);
PRINT '  utpl items to normalize: ' + CAST(@need AS varchar(10));

IF @need = 0
BEGIN
    PRINT '  nothing to do — PASS';
    RETURN;
END;

SELECT
    m.iuplpmKey,
    m.iuplpmPlPn,
    m.iuplpmStCost,
    m.iuplpmMn,
    m.iuplpmLim AS lim_before,
    CAST(ROUND(m.iuplpmLim * t.scale_factor, 8) AS decimal(23, 8)) AS lim_scaled,
    t.ipgpSmTtl,
    t.iuplpKey,
    ROW_NUMBER() OVER (
        PARTITION BY m.iuplpmPlPn
        ORDER BY m.iuplpmMn DESC, m.iuplpmKey DESC
    ) AS rn_last
INTO #scaled
FROM ags.ipgUtPlPnLmMn m
INNER JOIN #tgt t ON t.iuplpKey = m.iuplpmPlPn
WHERE m.iuplpmStCost = 212;

-- остаток округления — в последний месяц
;WITH adj AS (
    SELECT
        s.iuplpKey,
        s.ipgpSmTtl,
        SUM(CASE WHEN s.rn_last = 1 THEN 0 ELSE s.lim_scaled END) AS sum_other
    FROM #scaled s
    GROUP BY s.iuplpKey, s.ipgpSmTtl
)
UPDATE s
SET lim_scaled = CAST(ROUND(a.ipgpSmTtl - a.sum_other, 8) AS decimal(23, 8))
FROM #scaled s
INNER JOIN adj a ON a.iuplpKey = s.iuplpKey
WHERE s.rn_last = 1;

BEGIN TRAN;

UPDATE m
SET iuplpmLim = s.lim_scaled
FROM ags.ipgUtPlPnLmMn m
INNER JOIN #scaled s ON s.iuplpmKey = m.iuplpmKey;

INSERT INTO ags._fixture_utpl_stcost_log
(
    batchId, action, iuplpmKey, iuplpmPlPn, iuplpmStCost, iuplpmMn,
    iuplpmLim_before, iuplpmLim_after
)
SELECT
    @batchId, N'NORMALIZE', s.iuplpmKey, s.iuplpmPlPn, s.iuplpmStCost, s.iuplpmMn,
    s.lim_before, s.lim_scaled
FROM #scaled s;

COMMIT;

DECLARE @left int;
SELECT @left = COUNT(*)
FROM (
    SELECT up.iuplpKey, SUM(m.iuplpmLim) AS sum_mn, p.ipgpSmTtl
    FROM ags.ipgUtPlPnLmMn m
    INNER JOIN ags.ipgUtPlP up ON up.iuplpKey = m.iuplpmPlPn
    INNER JOIN ags.ipgPn p ON p.ipgpKey = up.iuplpIpgPn
    INNER JOIN ags.ipgChRl_2606 v ON v.ipgcrvIpg = p.ipgpIpg AND v.ipgcrvChain = @ipgCh
    WHERE m.iuplpmStCost = 212
    GROUP BY up.iuplpKey, p.ipgpSmTtl
) x
WHERE ABS(x.sum_mn - x.ipgpSmTtl) > 0.01;

DECLARE @upd int = (SELECT COUNT(*) FROM #scaled);
PRINT '  rows updated: ' + CAST(@upd AS varchar(10));
PRINT '  remaining mismatches: ' + CAST(@left AS varchar(10))
    + CASE WHEN @left = 0 THEN N'  PASS' ELSE N'  *** FAIL ***' END;
GO
