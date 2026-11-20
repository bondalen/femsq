-- =============================================================================
-- 02_MIGRATE_one_au_per_change.sql — 1 Au на каждый rac_key без Au
-- Источник: поля рассмотрения на ra_change + latest ra_change_summ (ra_chSmLt)
-- =============================================================================
SET NOCOUNT ON;
PRINT '=== 02_MIGRATE one Au per ra_change ===';

IF OBJECT_ID(N'ags.ra_change_au', N'U') IS NULL
BEGIN
    RAISERROR(N'ags.ra_change_au отсутствует — сначала 01_CREATE', 16, 1);
    RETURN;
END

INSERT INTO ags.ra_change_au (
    racAu_rac,
    racAu_arrived,
    racAu_arrived_date,
    racAu_arrived_dateFact,
    racAu_returned,
    racAu_returned_date,
    racAu_returnedReason,
    racAu_sent,
    racAu_sent_date,
    racAu_total,
    racAu_work,
    racAu_equip,
    racAu_others
)
SELECT
    c.rac_key,
    ISNULL(c.ra_arrived, N''),
    c.ra_arrived_date,
    c.ra_arrived_dateFact,
    c.ra_returned,
    c.ra_returned_date,
    c.ra_returnedReason,
    c.ra_sent,
    c.ra_sent_date,
    s.[raсs_total],
    s.[raсs_work],
    s.[raсs_equip],
    s.[raсs_others]
FROM ags.ra_change c
LEFT JOIN ags.ra_chSmLt s ON s.[raсs_raс] = c.rac_key
WHERE NOT EXISTS (
    SELECT 1 FROM ags.ra_change_au a WHERE a.racAu_rac = c.rac_key
);

PRINT 'Migrated rows: ' + CAST(@@ROWCOUNT AS varchar(20));
GO
