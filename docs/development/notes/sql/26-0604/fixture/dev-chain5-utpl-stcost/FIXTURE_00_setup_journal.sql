USE [FishEye];
GO
-- =============================================================================
-- FIXTURE_00_setup_journal.sql
-- Dev-only: журнал изменений fixture UtPlMn по stCost (цепь 5).
-- Не входит в MSSQL2012/ и не применяется на prod.
-- =============================================================================
SET NOCOUNT ON;
GO

PRINT '=== FIXTURE_00: setup journal ===';

IF OBJECT_ID(N'ags._fixture_utpl_stcost_log', N'U') IS NULL
BEGIN
    CREATE TABLE ags._fixture_utpl_stcost_log
    (
        logKey           int           IDENTITY(1, 1) NOT NULL PRIMARY KEY,
        batchId          uniqueidentifier NOT NULL,
        action           nvarchar(20)  NOT NULL, -- NORMALIZE | INSERT
        iuplpmKey        int           NULL,
        iuplpmPlPn       int           NOT NULL,
        iuplpmStCost     int           NOT NULL,
        iuplpmMn         int           NOT NULL,
        iuplpmLim_before decimal(23, 8) NULL,
        iuplpmLim_after  decimal(23, 8) NULL,
        createdAt        datetime2(0)  NOT NULL CONSTRAINT DF_fixture_utpl_created DEFAULT (SYSDATETIME())
    );

    CREATE INDEX IX_fixture_utpl_batch ON ags._fixture_utpl_stcost_log (batchId, action);
    PRINT '  created ags._fixture_utpl_stcost_log';
END
ELSE
    PRINT '  ags._fixture_utpl_stcost_log already exists';
GO
