-- =============================================================================
-- 99_ROLLBACK.sql — только DEV / до выкладки Au-писателя на прод
-- =============================================================================
SET NOCOUNT ON;
PRINT '=== 99_ROLLBACK ra_change_au ===';

IF OBJECT_ID(N'ags.FK_ra_change_au_factDoc', N'F') IS NOT NULL
    ALTER TABLE ags.ra_change_au DROP CONSTRAINT FK_ra_change_au_factDoc;

IF OBJECT_ID(N'ags.FK_ra_change_au_ra_change', N'F') IS NOT NULL
    ALTER TABLE ags.ra_change_au DROP CONSTRAINT FK_ra_change_au_ra_change;

IF OBJECT_ID(N'ags.ra_change_au', N'U') IS NOT NULL
BEGIN
    DROP TABLE ags.ra_change_au;
    PRINT 'Dropped ags.ra_change_au';
END
ELSE
    PRINT 'Skip: table absent';
GO
