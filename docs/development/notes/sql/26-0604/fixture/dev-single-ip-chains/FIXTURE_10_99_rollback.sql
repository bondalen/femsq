USE [FishEye];
GO

-- =============================================================================
-- FIXTURE_10_99_rollback.sql — откат цепей 501/502 (dev-only)
-- =============================================================================

SET NOCOUNT ON;
GO

DECLARE @chain6 int = 501;
DECLARE @chain8 int = 502;
DECLARE @batchId uniqueidentifier = NEWID();

RAISERROR(N'=== FIXTURE_10_99: rollback chains 501/502 ===', 0, 1) WITH NOWAIT;

BEGIN TRAN;

DELETE FROM ags.ipgChRl_2606 WHERE ipgcrvChain IN (@chain6, @chain8);
DELETE FROM ags.ipgCh WHERE ipgcKey IN (@chain6, @chain8);

IF OBJECT_ID(N'ags._fixture_single_ip_log', N'U') IS NOT NULL
    INSERT INTO ags._fixture_single_ip_log (batchId, action, note)
    VALUES (@batchId, N'ROLLBACK', N'deleted chains 501/502');

COMMIT;

RAISERROR(N'=== FIXTURE_10_99: DONE ===', 0, 1) WITH NOWAIT;
GO
