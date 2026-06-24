USE [FishEye];
GO
-- =============================================================================
-- FIXTURE_05_rollback.sql
-- Dev-only: откат FIXTURE_05_pilot_cst_2102.sql (ipgPn=5271).
-- =============================================================================
SET NOCOUNT ON;
GO

DECLARE @ipgpKey int = 5271;

PRINT N'=== FIXTURE_05 rollback ipgpPn=' + CAST(@ipgpKey AS nvarchar) + N' ===';

IF OBJECT_ID(N'ags._fixture_utpl_stcost_log', N'U') IS NULL
BEGIN
    PRINT N'  journal missing';
    RETURN;
END;

BEGIN TRAN;

DELETE m
FROM ags.ipgUtPlPnLmMn m
INNER JOIN ags.ipgUtPlP up ON up.iuplpKey = m.iuplpmPlPn
WHERE up.iuplpIpgPn = @ipgpKey
  AND EXISTS (
      SELECT 1 FROM ags._fixture_utpl_stcost_log l
      WHERE l.action = N'INSERT' AND l.iuplpmKey = m.iuplpmKey
  );

DECLARE @delMn int = @@ROWCOUNT;

DELETE up
FROM ags.ipgUtPlP up
WHERE up.iuplpIpgPn = @ipgpKey
  AND EXISTS (
      SELECT 1 FROM ags._fixture_utpl_stcost_log l
      WHERE l.action = N'INSERT_PLP' AND l.iuplpmPlPn = up.iuplpKey
  );

DECLARE @delPl int = @@ROWCOUNT;

DELETE FROM ags._fixture_utpl_stcost_log
WHERE action IN (N'INSERT', N'INSERT_PLP')
  AND (iuplpmPlPn IN (SELECT iuplpKey FROM ags.ipgUtPlP WHERE iuplpIpgPn = @ipgpKey)
       OR iuplpmKey IN (SELECT m.iuplpmKey FROM ags.ipgUtPlPnLmMn m
                        INNER JOIN ags.ipgUtPlP up ON up.iuplpKey = m.iuplpmPlPn
                        WHERE up.iuplpIpgPn = @ipgpKey));

COMMIT;

PRINT N'  deleted UtPlMn=' + CAST(@delMn AS nvarchar) + N'  ipgUtPlP=' + CAST(@delPl AS nvarchar);
GO
