USE [FishEye];
GO

-- =============================================================================
-- FIXTURE_10_00_single_ip_chains.sql
-- Dev-only: тестовые цепи 501 (только ИП 6) и 502 (только ИП 8) для К-12b@yearend.
-- Требует FIXTURE_06 (группы UtPl 18/19, золотой UtPl cst 2102).
-- Не входит в MSSQL2012/.
-- Автор:   Александр | Дата: 2026-07-06
-- =============================================================================

SET NOCOUNT ON;
GO

DECLARE @batchId uniqueidentifier = NEWID();
DECLARE @chain6 int = 501;
DECLARE @chain8 int = 502;

RAISERROR(N'=== FIXTURE_10_00: single-IP chains 501/502 ===', 0, 1) WITH NOWAIT;

IF NOT EXISTS (SELECT 1 FROM ags.ipgUtPlGr WHERE iuplgKey IN (18, 19))
BEGIN
    RAISERROR(N'ipgUtPlGr 18–19 missing. Run FIXTURE_06 first.', 16, 1);
    RETURN;
END;

IF OBJECT_ID(N'ags._fixture_single_ip_log', N'U') IS NULL
BEGIN
    CREATE TABLE ags._fixture_single_ip_log
    (
        logKey    int              IDENTITY(1, 1) NOT NULL PRIMARY KEY,
        batchId   uniqueidentifier NOT NULL,
        action    nvarchar(30)     NOT NULL,
        ipgcKey   int              NULL,
        ipgcrvKey int              NULL,
        note      nvarchar(200)    NULL,
        createdAt datetime2(0)     NOT NULL CONSTRAINT DF_fixture_single_ip_created DEFAULT (SYSDATETIME())
    );
    RAISERROR(N'  created ags._fixture_single_ip_log', 0, 1) WITH NOWAIT;
END;

IF EXISTS (SELECT 1 FROM ags.ipgChRl_2606 WHERE ipgcrvChain IN (@chain6, @chain8))
BEGIN
    RAISERROR(N'Chains 501/502 already exist. Run FIXTURE_10_99_rollback.sql first.', 16, 1);
    RETURN;
END;

BEGIN TRAN;

-- ipgCh (FK для ipgChRl_2606)
IF NOT EXISTS (SELECT 1 FROM ags.ipgCh WHERE ipgcKey = @chain6)
BEGIN
    SET IDENTITY_INSERT ags.ipgCh ON;
    INSERT INTO ags.ipgCh (ipgcKey, ipgcName)
    VALUES (@chain6, N'TEST_SINGLE_IP6_Y2022');
    SET IDENTITY_INSERT ags.ipgCh OFF;

    INSERT INTO ags._fixture_single_ip_log (batchId, action, ipgcKey, note)
    VALUES (@batchId, N'INSERT_IPGCH', @chain6, N'single IP 6');
END;

IF NOT EXISTS (SELECT 1 FROM ags.ipgCh WHERE ipgcKey = @chain8)
BEGIN
    SET IDENTITY_INSERT ags.ipgCh ON;
    INSERT INTO ags.ipgCh (ipgcKey, ipgcName)
    VALUES (@chain8, N'TEST_SINGLE_IP8_Y2022');
    SET IDENTITY_INSERT ags.ipgCh OFF;

    INSERT INTO ags._fixture_single_ip_log (batchId, action, ipgcKey, note)
    VALUES (@batchId, N'INSERT_IPGCH', @chain8, N'single IP 8');
END;

-- ipgChRl_2606: одна ИП на цепь, активна весь 2022 (ipgcrvEnd = NULL)
INSERT INTO ags.ipgChRl_2606 (ipgcrvChain, ipgcrvIpg, ipgcrvStr, ipgcrvUtPlGr)
OUTPUT @batchId, N'INSERT_RL', NULL, inserted.ipgcrvKey,
       N'chain=' + CAST(inserted.ipgcrvChain AS nvarchar) + N' ipg=' + CAST(inserted.ipgcrvIpg AS nvarchar)
INTO ags._fixture_single_ip_log (batchId, action, ipgcKey, ipgcrvKey, note)
VALUES
    (@chain6, 6,  '2022-01-01', 18),
    (@chain8, 8,  '2022-01-01', 19);

COMMIT;

SELECT ipgcrvChain, ipgcrvIpg, ipgcrvStr, ipgcrvEnd, ipgcrvUtPlGr
FROM ags.ipgChRl_2606
WHERE ipgcrvChain IN (@chain6, @chain8)
ORDER BY ipgcrvChain;

RAISERROR(N'=== FIXTURE_10_00: DONE ===', 0, 1) WITH NOWAIT;
GO
