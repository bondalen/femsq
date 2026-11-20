-- =============================================================================
-- 03_VERIFY_after.sql
-- =============================================================================
SET NOCOUNT ON;
PRINT '=== 03_VERIFY_after ra_change_au ===';

IF OBJECT_ID(N'ags.ra_change_au', N'U') IS NULL
BEGIN
    RAISERROR(N'FAIL: ags.ra_change_au missing', 16, 1);
    RETURN;
END
PRINT 'PASS: table exists';

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'ags.ra_change_au')
      AND name = N'UX_ra_change_au_rac_arrived'
)
BEGIN
    RAISERROR(N'FAIL: UX_ra_change_au_rac_arrived missing', 16, 1);
    RETURN;
END
PRINT 'PASS: unique index';

DECLARE @rc INT, @au INT, @orphan INT;
SELECT @rc = COUNT(*) FROM ags.ra_change;
SELECT @au = COUNT(*) FROM ags.ra_change_au;
SELECT @orphan = COUNT(*)
FROM ags.ra_change c
WHERE NOT EXISTS (SELECT 1 FROM ags.ra_change_au a WHERE a.racAu_rac = c.rac_key);

PRINT 'ra_change=' + CAST(@rc AS varchar(20))
    + ' ra_change_au=' + CAST(@au AS varchar(20))
    + ' changes_without_au=' + CAST(@orphan AS varchar(20));

IF @orphan > 0
    PRINT 'WARN: есть ra_change без Au — повторите 02_MIGRATE';
ELSE
    PRINT 'PASS: каждый ra_change имеет ≥1 Au';
GO
