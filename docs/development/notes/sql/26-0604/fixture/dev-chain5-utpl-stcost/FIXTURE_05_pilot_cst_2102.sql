USE [FishEye];
GO
-- =============================================================================
-- FIXTURE_05_pilot_cst_2102.sql
-- Dev-only: пилот cstAgPn=2102, ipgPn=5271 (актуальна на 2022-12-31 в цепи 5).
-- UtPl: 40% лимита в mn=9, 60% в mn=11; split по stCost (sparse: только lim>0).
-- =============================================================================
SET NOCOUNT ON;
GO

DECLARE @cstAgPn   int = 2102;
DECLARE @ipgpKey   int = 5271;
DECLARE @iuplpPl   int = 85;
DECLARE @batchId   uniqueidentifier = NEWID();
DECLARE @pctEarly  decimal(23, 8) = 0.40;
DECLARE @pctLate   decimal(23, 8) = 0.60;

PRINT N'=== FIXTURE_05: pilot UtPl cstAgPn=' + CAST(@cstAgPn AS nvarchar)
    + N' ipgpPn=' + CAST(@ipgpKey AS nvarchar) + N' batch=' + CAST(@batchId AS nvarchar(36)) + N' ===';

IF OBJECT_ID(N'ags._fixture_utpl_stcost_log', N'U') IS NULL
BEGIN
    RAISERROR(N'Run FIXTURE_00_setup_journal.sql first.', 16, 1);
    RETURN;
END;

IF NOT EXISTS (SELECT 1 FROM ags.ipgPn WHERE ipgpKey = @ipgpKey AND ipgpCstAgPn = @cstAgPn)
BEGIN
    RAISERROR(N'ipgpPn %d not on cstAgPn %d.', 16, 1, @ipgpKey, @cstAgPn);
    RETURN;
END;

IF EXISTS (
    SELECT 1 FROM ags.ipgUtPlPnLmMn m
    INNER JOIN ags.ipgUtPlP up ON up.iuplpKey = m.iuplpmPlPn
    WHERE up.iuplpIpgPn = @ipgpKey
)
BEGIN
    RAISERROR(N'ipgpPn %d already has UtPlMn — run FIXTURE_05_rollback.sql first.', 16, 1, @ipgpKey);
    RETURN;
END;

DECLARE @lim212 decimal(23, 8), @lim195 decimal(23, 8), @lim172 decimal(23, 8), @lim187 decimal(23, 8);
SELECT
    @lim212 = COALESCE(l212.ipgplLim, p.ipgpSmTtl, 0),
    @lim195 = COALESCE(l195.ipgplLim, p.ipgpSmWrk, 0),
    @lim172 = COALESCE(l172.ipgplLim, p.ipgpSmEqu, 0),
    @lim187 = COALESCE(l187.ipgplLim, p.ipgpSmOth, 0)
FROM ags.ipgPn p
LEFT JOIN ags.ipgPnLim l212 ON l212.ipgplPn = p.ipgpKey AND l212.ipgplStCost = 212
LEFT JOIN ags.ipgPnLim l195 ON l195.ipgplPn = p.ipgpKey AND l195.ipgplStCost = 195
LEFT JOIN ags.ipgPnLim l172 ON l172.ipgplPn = p.ipgpKey AND l172.ipgplStCost = 172
LEFT JOIN ags.ipgPnLim l187 ON l187.ipgplPn = p.ipgpKey AND l187.ipgplStCost = 187
WHERE p.ipgpKey = @ipgpKey;

DECLARE @iuplpKey int;

BEGIN TRAN;

INSERT INTO ags.ipgUtPlP (iuplpPl, iuplpLim, iuplpIpgPn)
VALUES (@iuplpPl, @lim212, @ipgpKey);

SET @iuplpKey = SCOPE_IDENTITY();

INSERT INTO ags._fixture_utpl_stcost_log (batchId, action, iuplpmKey, iuplpmPlPn, iuplpmStCost, iuplpmMn, iuplpmLim_before, iuplpmLim_after)
VALUES (@batchId, N'INSERT_PLP', NULL, @iuplpKey, 0, 0, NULL, @lim212);

;WITH mn AS (
    SELECT n AS iuplpmMn FROM (VALUES (1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12)) v(n)
),
st AS (
    SELECT s AS iuplpmStCost, l AS lim_val
    FROM (VALUES (212, @lim212), (195, @lim195), (172, @lim172), (187, @lim187)) x(s, l)
),
grid AS (
    SELECT mn.iuplpmMn, st.iuplpmStCost, st.lim_val
    FROM mn CROSS JOIN st
),
calc AS (
    SELECT
        g.iuplpmMn,
        g.iuplpmStCost,
        CAST(
            g.lim_val * CASE
                WHEN g.iuplpmMn = 9 THEN @pctEarly
                WHEN g.iuplpmMn = 11 THEN @pctLate
                ELSE 0
            END AS decimal(23, 8)
        ) AS iuplpmLim
    FROM grid g
)
INSERT INTO ags.ipgUtPlPnLmMn (iuplpmPlPn, iuplpmStCost, iuplpmMn, iuplpmLim)
OUTPUT
    @batchId, N'INSERT', inserted.iuplpmKey, inserted.iuplpmPlPn,
    inserted.iuplpmStCost, inserted.iuplpmMn, CAST(NULL AS decimal(23, 8)), inserted.iuplpmLim
INTO ags._fixture_utpl_stcost_log (batchId, action, iuplpmKey, iuplpmPlPn, iuplpmStCost, iuplpmMn, iuplpmLim_before, iuplpmLim_after)
SELECT @iuplpKey, c.iuplpmStCost, c.iuplpmMn, c.iuplpmLim
FROM calc c
WHERE c.iuplpmLim > 0;

COMMIT;

DECLARE @rows int = (
    SELECT COUNT(*) FROM ags.ipgUtPlPnLmMn m
    INNER JOIN ags.ipgUtPlP up ON up.iuplpKey = m.iuplpmPlPn
    WHERE up.iuplpIpgPn = @ipgpKey
);

PRINT N'  ipgUtPlP=' + CAST(@iuplpKey AS nvarchar) + N'  UtPlMn rows=' + CAST(@rows AS nvarchar);
PRINT N'  batchId=' + CAST(@batchId AS nvarchar(36));
GO
