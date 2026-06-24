USE [FishEye];
GO
-- =============================================================================
-- FIXTURE_99_rollback.sql
-- Dev-only: откат последнего batch INSERT и всех NORMALIZE из журнала.
-- Параметр: @batchId — если NULL, откатывает все batch'и журнала (полный откат fixture).
-- =============================================================================
SET NOCOUNT ON;
GO

DECLARE @batchId uniqueidentifier = NULL; -- <<< указать batch для частичного отката

PRINT '=== FIXTURE_99: rollback ===';

IF OBJECT_ID(N'ags._fixture_utpl_stcost_log', N'U') IS NULL
BEGIN
    PRINT '  journal table missing — nothing to rollback';
    RETURN;
END;

IF OBJECT_ID('tempdb..#batches') IS NOT NULL DROP TABLE #batches;

SELECT DISTINCT batchId
INTO #batches
FROM ags._fixture_utpl_stcost_log
WHERE @batchId IS NULL OR batchId = @batchId;

IF NOT EXISTS (SELECT 1 FROM #batches)
BEGIN
    PRINT '  no batches in journal';
    RETURN;
END;

BEGIN TRAN;

-- 1) удалить вставленные строки split
DELETE m
FROM ags.ipgUtPlPnLmMn m
INNER JOIN ags._fixture_utpl_stcost_log l
    ON l.iuplpmKey = m.iuplpmKey AND l.action = N'INSERT'
INNER JOIN #batches b ON b.batchId = l.batchId;

DECLARE @del int = @@ROWCOUNT;

-- 2) восстановить NORMALIZE
UPDATE m
SET iuplpmLim = l.iuplpmLim_before
FROM ags.ipgUtPlPnLmMn m
INNER JOIN ags._fixture_utpl_stcost_log l
    ON l.iuplpmKey = m.iuplpmKey AND l.action = N'NORMALIZE'
INNER JOIN #batches b ON b.batchId = l.batchId
WHERE l.iuplpmLim_before IS NOT NULL;

DECLARE @rest int = @@ROWCOUNT;

DELETE l
FROM ags._fixture_utpl_stcost_log l
INNER JOIN #batches b ON b.batchId = l.batchId;

COMMIT;

PRINT '  deleted INSERT rows: ' + CAST(@del AS varchar(10));
PRINT '  restored NORMALIZE rows: ' + CAST(@rest AS varchar(10));
PRINT '  journal batches removed: ' + CAST((SELECT COUNT(*) FROM #batches) AS varchar(10));
GO
