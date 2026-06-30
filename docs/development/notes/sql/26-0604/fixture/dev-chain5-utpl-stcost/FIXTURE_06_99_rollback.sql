USE [FishEye];
GO
-- =============================================================================
-- FIXTURE_06_99_rollback.sql
-- Dev-only: откат FIXTURE_06 (golden UtPl, подмена ipgcrvUtPlGr, тестовые группы).
-- Параметр @batchId — частичный откат; NULL = полный откат всех batch FIXTURE_06.
-- =============================================================================
SET NOCOUNT ON;
GO

DECLARE @batchId uniqueidentifier = NULL;

PRINT N'=== FIXTURE_06_99: rollback ===';

IF OBJECT_ID(N'ags._fixture_utpl06_log', N'U') IS NULL
BEGIN
    PRINT N'  journal missing — nothing to rollback';
    RETURN;
END;

IF OBJECT_ID('tempdb..#batches') IS NOT NULL DROP TABLE #batches;
SELECT DISTINCT batchId
INTO #batches
FROM ags._fixture_utpl06_log
WHERE @batchId IS NULL OR batchId = @batchId;

IF NOT EXISTS (SELECT 1 FROM #batches)
BEGIN
    PRINT N'  no batches in journal';
    RETURN;
END;

BEGIN TRAN;

-- 1) UtPlMn из golden
DELETE m
FROM ags.ipgUtPlPnLmMn m
INNER JOIN ags._fixture_utpl06_log l ON l.iuplpmKey = m.iuplpmKey AND l.action = N'INSERT_MN'
INNER JOIN #batches b ON b.batchId = l.batchId;

DECLARE @delMn int = @@ROWCOUNT;

-- 2) ipgUtPlP из golden
DELETE up
FROM ags.ipgUtPlP up
INNER JOIN ags._fixture_utpl06_log l ON l.iuplpKey = up.iuplpKey AND l.action = N'INSERT_PLP'
INNER JOIN #batches b ON b.batchId = l.batchId;

DECLARE @delPl int = @@ROWCOUNT;

-- 3) восстановить ipgcrvUtPlGr
UPDATE v
SET ipgcrvUtPlGr = l.utPlGr_before
FROM ags.ipgChRl_2606 v
INNER JOIN ags._fixture_utpl06_log l ON l.ipgcrvKey = v.ipgcrvKey AND l.action = N'SWAP_UTPLGR'
INNER JOIN #batches b ON b.batchId = l.batchId;

DECLARE @restSw int = @@ROWCOUNT;

-- 4) ipgUtPlGrP (только тестовые связи 18–20)
DELETE g
FROM ags.ipgUtPlGrP g
INNER JOIN ags._fixture_utpl06_log l ON l.action = N'INSERT_GRP' AND l.iuplgKey = g.iuplgpGr AND l.iuplKey = g.iuplgpPl
INNER JOIN #batches b ON b.batchId = l.batchId;

DECLARE @delGrp int = @@ROWCOUNT;

-- 5) ipgUtPlGr 18–20
DELETE gr
FROM ags.ipgUtPlGr gr
INNER JOIN ags._fixture_utpl06_log l ON l.action = N'INSERT_GR' AND l.iuplgKey = gr.iuplgKey
INNER JOIN #batches b ON b.batchId = l.batchId
WHERE NOT EXISTS (SELECT 1 FROM ags.ipgUtPlGrP p WHERE p.iuplgpGr = gr.iuplgKey);

DECLARE @delGr int = @@ROWCOUNT;

-- 6) ipgUtPl 201–203
DELETE u
FROM ags.ipgUtPl u
INNER JOIN ags._fixture_utpl06_log l ON l.action = N'INSERT_UTPL' AND l.iuplKey = u.iuplKey
INNER JOIN #batches b ON b.batchId = l.batchId
WHERE NOT EXISTS (SELECT 1 FROM ags.ipgUtPlP p WHERE p.iuplpPl = u.iuplKey)
  AND NOT EXISTS (SELECT 1 FROM ags.ipgUtPlGrP g WHERE g.iuplgpPl = u.iuplKey);

DECLARE @delUt int = @@ROWCOUNT;

DELETE l
FROM ags._fixture_utpl06_log l
INNER JOIN #batches b ON b.batchId = l.batchId;

COMMIT;

PRINT N'  deleted UtPlMn=' + CAST(@delMn AS nvarchar)
    + N'  ipgUtPlP=' + CAST(@delPl AS nvarchar)
    + N'  restored swap=' + CAST(@restSw AS nvarchar)
    + N'  ipgUtPlGrP=' + CAST(@delGrp AS nvarchar)
    + N'  ipgUtPlGr=' + CAST(@delGr AS nvarchar)
    + N'  ipgUtPl=' + CAST(@delUt AS nvarchar);
GO
