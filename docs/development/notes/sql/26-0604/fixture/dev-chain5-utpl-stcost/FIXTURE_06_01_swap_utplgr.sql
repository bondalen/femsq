USE [FishEye];
GO
-- =============================================================================
-- FIXTURE_06_01_swap_utplgr.sql
-- Dev-only: подмена ipgChRl_2606.ipgcrvUtPlGr для ИП 6/8/11 цепи 5 → группы 18/19/20.
-- Исходные значения (3/4/6) сохраняются в ags._fixture_utpl06_log.
-- =============================================================================
SET NOCOUNT ON;
GO

DECLARE @ipgCh   int = 5;
DECLARE @batchId uniqueidentifier = NEWID();

PRINT N'=== FIXTURE_06_01: swap ipgcrvUtPlGr chain=' + CAST(@ipgCh AS nvarchar)
    + N' batch=' + CAST(@batchId AS nvarchar(36)) + N' ===';

IF OBJECT_ID(N'ags._fixture_utpl06_log', N'U') IS NULL
BEGIN
    RAISERROR(N'Run FIXTURE_06_00_setup_journal.sql first.', 16, 1);
    RETURN;
END;

IF NOT EXISTS (SELECT 1 FROM ags.ipgUtPlGr WHERE iuplgKey IN (18, 19, 20))
BEGIN
    RAISERROR(N'ipgUtPlGr 18–20 missing. Run FIXTURE_06_00 first.', 16, 1);
    RETURN;
END;

IF EXISTS (
    SELECT 1 FROM ags._fixture_utpl06_log
    WHERE action = N'SWAP_UTPLGR' AND utPlGr_after IN (18, 19, 20)
)
BEGIN
    RAISERROR(N'ipgcrvUtPlGr already swapped (FIXTURE_06). Run FIXTURE_06_99_rollback.sql first.', 16, 1);
    RETURN;
END;

DECLARE @map TABLE (ipg int NOT NULL PRIMARY KEY, new_gr int NOT NULL);
INSERT INTO @map VALUES (6, 18), (8, 19), (11, 20);

BEGIN TRAN;

UPDATE v
SET ipgcrvUtPlGr = m.new_gr
OUTPUT
    @batchId, N'SWAP_UTPLGR', NULL, NULL, NULL,
    inserted.ipgcrvKey, inserted.ipgcrvIpg,
    deleted.ipgcrvUtPlGr, inserted.ipgcrvUtPlGr,
    NULL, NULL, NULL,
    N'chain=' + CAST(@ipgCh AS nvarchar)
INTO ags._fixture_utpl06_log (
    batchId, action, iuplgKey, iuplKey, iuplgpKey,
    ipgcrvKey, ipgcrvIpg, utPlGr_before, utPlGr_after,
    iuplpKey, ipgpKey, iuplpmKey, note
)
FROM ags.ipgChRl_2606 v
INNER JOIN @map m ON m.ipg = v.ipgcrvIpg
WHERE v.ipgcrvChain = @ipgCh;

COMMIT;

DECLARE @n int = (
    SELECT COUNT(*) FROM ags._fixture_utpl06_log
    WHERE action = N'SWAP_UTPLGR' AND batchId = @batchId
);

SELECT ipgcrvIpg, ipgcrvStr, ipgcrvEnd, ipgcrvUtPlGr
FROM ags.ipgChRl_2606
WHERE ipgcrvChain = @ipgCh
ORDER BY ipgcrvStr;

PRINT N'  swapped rows: ' + CAST(@n AS nvarchar);
GO
