USE [FishEye];
GO
-- =============================================================================
-- FIXTURE_07_99_rollback.sql — откат FIXTURE_07 (INSERT_PLP_F07 / INSERT_MN_F07)
-- =============================================================================
SET NOCOUNT ON;
GO

PRINT N'=== FIXTURE_07_99: rollback ===';

IF NOT EXISTS (SELECT 1 FROM ags._fixture_utpl06_log WHERE action = N'INSERT_PLP_F07')
BEGIN
    PRINT N'  nothing to rollback';
    RETURN;
END;

BEGIN TRANSACTION;

DELETE m
FROM ags.ipgUtPlPnLmMn m
INNER JOIN ags._fixture_utpl06_log l ON l.iuplpmKey = m.iuplpmKey AND l.action = N'INSERT_MN_F07';

DECLARE @delMn int = @@ROWCOUNT;

DELETE up
FROM ags.ipgUtPlP up
INNER JOIN ags._fixture_utpl06_log l ON l.iuplpKey = up.iuplpKey AND l.action = N'INSERT_PLP_F07';

DECLARE @delPl int = @@ROWCOUNT;

DELETE FROM ags._fixture_utpl06_log WHERE action IN (N'INSERT_PLP_F07', N'INSERT_MN_F07');

COMMIT;

PRINT N'  deleted UtPlMn=' + CAST(@delMn AS nvarchar) + N'  ipgUtPlP=' + CAST(@delPl AS nvarchar);
GO
