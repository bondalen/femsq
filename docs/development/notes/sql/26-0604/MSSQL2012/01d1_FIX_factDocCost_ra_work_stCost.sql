USE [FishEye];
GO
-- =============================================================================
-- 01d1_FIX_factDocCost_ra_work_stCost.sql
-- Миграция: ras_work / raсs_work → factDocCost @195 (не @182)
-- План: docs/11-ra-work-stCost195-fix-plan.md §4.3
-- Идемпотентен. Предусловие: 01c с work→195.
-- Автор:   Александр
-- Дата:    2026-06-13
-- =============================================================================
SET NOCOUNT ON;
GO

DECLARE @epsilon money = 0.01;
DECLARE @msg nvarchar(400);

RAISERROR(N'=== 01d1: FIX factDocCost ra_work → stCost 195 ===', 0, 1) WITH NOWAIT;

-- -------------------------------------------------------------------------
-- Отчёт «до»
-- -------------------------------------------------------------------------
RAISERROR(N'--- [0] BEFORE ---', 0, 1) WITH NOWAIT;

SELECT
    (SELECT COUNT(*)
     FROM ags.factDocCost c
     INNER JOIN ags.factDoc fd ON fd.fdKey = c.fdcoFd
     WHERE fd.fdDocType = N'RaSumm' AND c.fdcoStCost = 182) AS RaSumm_fdco_182,
    (SELECT COUNT(*)
     FROM ags.factDocCost c
     INNER JOIN ags.factDoc fd ON fd.fdKey = c.fdcoFd
     WHERE fd.fdDocType = N'RaSumm' AND c.fdcoStCost = 195) AS RaSumm_fdco_195,
    (SELECT COUNT(*)
     FROM ags.factDocCost c
     INNER JOIN ags.factDoc fd ON fd.fdKey = c.fdcoFd
     WHERE fd.fdDocType = N'RaChangeSumm' AND c.fdcoStCost = 182) AS RaChangeSumm_fdco_182,
    (SELECT COUNT(*)
     FROM ags.factDocCost c
     INNER JOIN ags.factDoc fd ON fd.fdKey = c.fdcoFd
     WHERE fd.fdDocType = N'RaChangeSumm' AND c.fdcoStCost = 195) AS RaChangeSumm_fdco_195;

SELECT
    (SELECT COUNT(*)
     FROM ags.factDocCost c182
     INNER JOIN ags.factDoc fd ON fd.fdKey = c182.fdcoFd AND fd.fdDocType = N'RaSumm'
     INNER JOIN ags.factDocCost c195 ON c195.fdcoFd = c182.fdcoFd AND c195.fdcoStCost = 195
     WHERE c182.fdcoStCost = 182
       AND ABS(c182.fdcoSumm - c195.fdcoSumm) < @epsilon) AS merge_equal_182_195_RaSumm,
    (SELECT COUNT(*)
     FROM ags.factDocCost c182
     INNER JOIN ags.factDoc fd ON fd.fdKey = c182.fdcoFd AND fd.fdDocType = N'RaSumm'
     INNER JOIN ags.factDocCost c195 ON c195.fdcoFd = c182.fdcoFd AND c195.fdcoStCost = 195
     WHERE c182.fdcoStCost = 182
       AND ABS(c182.fdcoSumm - c195.fdcoSumm) >= @epsilon) AS conflict_182_195_RaSumm;

-- -------------------------------------------------------------------------
-- Бэкап (один раз)
-- -------------------------------------------------------------------------
IF OBJECT_ID(N'ags._backup_fdco_182_2606', N'U') IS NULL
BEGIN
    RAISERROR(N'--- [1] backup → ags._backup_fdco_182_2606 ---', 0, 1) WITH NOWAIT;
    SELECT c.fdcoKey, c.fdcoFd, c.fdcoStCost, c.fdcoSumm, fd.fdDocType
    INTO ags._backup_fdco_182_2606
    FROM ags.factDocCost c
    INNER JOIN ags.factDoc fd ON fd.fdKey = c.fdcoFd
    WHERE fd.fdDocType IN (N'RaSumm', N'RaChangeSumm')
      AND c.fdcoStCost = 182;
    SET @msg = N'  backup rows: ' + CAST(@@ROWCOUNT AS nvarchar);
    RAISERROR(@msg, 0, 1) WITH NOWAIT;
END
ELSE
    RAISERROR(N'--- [1] backup exists, skip ---', 0, 1) WITH NOWAIT;

-- -------------------------------------------------------------------------
-- Случай C: конфликты (182+195, разные суммы) — только отчёт
-- -------------------------------------------------------------------------
IF OBJECT_ID(N'tempdb..#conflicts', N'U') IS NOT NULL DROP TABLE #conflicts;

SELECT
    fd.fdDocType,
    c182.fdcoFd,
    c182.fdcoSumm AS summ182,
    c195.fdcoSumm AS summ195,
    ABS(c182.fdcoSumm - c195.fdcoSumm) AS diff
INTO #conflicts
FROM ags.factDocCost c182
INNER JOIN ags.factDoc fd ON fd.fdKey = c182.fdcoFd
INNER JOIN ags.factDocCost c195 ON c195.fdcoFd = c182.fdcoFd AND c195.fdcoStCost = 195
WHERE c182.fdcoStCost = 182
  AND fd.fdDocType IN (N'RaSumm', N'RaChangeSumm')
  AND ABS(c182.fdcoSumm - c195.fdcoSumm) >= @epsilon;

DECLARE @conflicts int;
SELECT @conflicts = COUNT(*) FROM #conflicts;
SET @msg = N'--- [2] conflicts (not auto-fixed): ' + CAST(@conflicts AS nvarchar) + N' ---';
RAISERROR(@msg, 0, 1) WITH NOWAIT;

IF @conflicts > 0
    SELECT TOP 20 * FROM #conflicts ORDER BY diff DESC;

-- -------------------------------------------------------------------------
-- Случай A: DELETE @182 при равной @195
-- -------------------------------------------------------------------------
RAISERROR(N'--- [3] DELETE @182 when @195 equal ---', 0, 1) WITH NOWAIT;

DELETE c182
FROM ags.factDocCost c182
INNER JOIN ags.factDoc fd ON fd.fdKey = c182.fdcoFd
INNER JOIN ags.factDocCost c195 ON c195.fdcoFd = c182.fdcoFd AND c195.fdcoStCost = 195
WHERE c182.fdcoStCost = 182
  AND fd.fdDocType IN (N'RaSumm', N'RaChangeSumm')
  AND ABS(c182.fdcoSumm - c195.fdcoSumm) < @epsilon;

SET @msg = N'  deleted: ' + CAST(@@ROWCOUNT AS nvarchar);
RAISERROR(@msg, 0, 1) WITH NOWAIT;

-- -------------------------------------------------------------------------
-- Случай B: UPDATE @182 → @195 (нет @195)
-- -------------------------------------------------------------------------
RAISERROR(N'--- [4] UPDATE @182 → @195 (no @195) ---', 0, 1) WITH NOWAIT;

UPDATE c
SET c.fdcoStCost = 195
FROM ags.factDocCost c
INNER JOIN ags.factDoc fd ON fd.fdKey = c.fdcoFd
WHERE c.fdcoStCost = 182
  AND fd.fdDocType IN (N'RaSumm', N'RaChangeSumm')
  AND NOT EXISTS (
      SELECT 1 FROM ags.factDocCost x
      WHERE x.fdcoFd = c.fdcoFd AND x.fdcoStCost = 195
  );

SET @msg = N'  updated: ' + CAST(@@ROWCOUNT AS nvarchar);
RAISERROR(@msg, 0, 1) WITH NOWAIT;

-- -------------------------------------------------------------------------
-- Отчёт «после» + gates К-11a
-- -------------------------------------------------------------------------
RAISERROR(N'--- [5] AFTER + gates ---', 0, 1) WITH NOWAIT;

SELECT
    (SELECT COUNT(*)
     FROM ags.factDocCost c
     INNER JOIN ags.factDoc fd ON fd.fdKey = c.fdcoFd
     WHERE fd.fdDocType = N'RaSumm' AND c.fdcoStCost = 182) AS RaSumm_fdco_182_after,
    (SELECT COUNT(*)
     FROM ags.factDocCost c
     INNER JOIN ags.factDoc fd ON fd.fdKey = c.fdcoFd
     WHERE fd.fdDocType = N'RaChangeSumm' AND c.fdcoStCost = 182) AS RaChangeSumm_fdco_182_after;

DECLARE @flat_work_182 int;

SELECT @flat_work_182 = COUNT(*)
FROM ags.factDocCost c
INNER JOIN ags.ra_summ rs ON rs.ras_fdKey = c.fdcoFd
WHERE c.fdcoStCost = 182
  AND rs.ras_work IS NOT NULL AND rs.ras_work <> 0
  AND ABS(c.fdcoSumm - rs.ras_work) < @epsilon;

SELECT @flat_work_182 = @flat_work_182 + (
    SELECT COUNT(*)
    FROM ags.factDocCost c
    INNER JOIN ags.ra_change_summ rcs ON rcs.racs_fdKey = c.fdcoFd
    WHERE c.fdcoStCost = 182
      AND rcs.raсs_work IS NOT NULL AND rcs.raсs_work <> 0
      AND ABS(c.fdcoSumm - rcs.raсs_work) < @epsilon
);

SET @msg = N'  gate flat_work_at_182: ' + CAST(@flat_work_182 AS nvarchar)
         + CASE WHEN @flat_work_182 = 0 THEN N'  PASS' ELSE N'  *** FAIL ***' END;
RAISERROR(@msg, 0, 1) WITH NOWAIT;

DECLARE @remaining_conflicts int;
SELECT @remaining_conflicts = COUNT(*) FROM #conflicts c
WHERE EXISTS (
    SELECT 1 FROM ags.factDocCost x
    WHERE x.fdcoFd = c.fdcoFd AND x.fdcoStCost = 182
);

SET @msg = N'  remaining conflicts @182: ' + CAST(@remaining_conflicts AS nvarchar);
RAISERROR(@msg, 0, 1) WITH NOWAIT;

RAISERROR(N'=== 01d1 завершено ===', 0, 1) WITH NOWAIT;
GO
