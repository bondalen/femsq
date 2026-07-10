-- Откат apply type=5 по max-key (dev FishEye, март test_26 / adt_key=14).
-- Прецедент: type5-acceptance-smoke-check-report-2026-04-15, type5-row-eligibility.md §4.
--
-- Перед запуском задать границы из лога reconcile exec_key=N:
--   @ra_key_max_before  — MAX(ra_key) до apply (для exec 1148: 106627)
--   @rac_key_from/@rac_key_to — 16 новых ra_change (для exec 1148: 5038..5053)
--
-- Порядок удаления: ra_change_summ → ra_change → ra_summ → ra

SET NOCOUNT ON;
DECLARE @ra_key_max_before BIGINT = 108205;
DECLARE @rac_key_from INT = 5054;
DECLARE @rac_key_to INT = 5069;

BEGIN TRANSACTION;

DELETE FROM ags.ra_change_summ WHERE [raсs_raс] BETWEEN @rac_key_from AND @rac_key_to;
DELETE FROM ags.ra_change WHERE rac_key BETWEEN @rac_key_from AND @rac_key_to;
DELETE FROM ags.ra_summ WHERE ras_ra > @ra_key_max_before;
DELETE FROM ags.ra WHERE ra_key > @ra_key_max_before;

SELECT
    MAX(ra_key) AS ra_max,
    (SELECT COUNT(*) FROM ags.ra WHERE ra_key > @ra_key_max_before) AS ra_tail,
    MAX(rac_key) AS rac_max,
    (SELECT COUNT(*) FROM ags.ra_change WHERE rac_key BETWEEN @rac_key_from AND @rac_key_to) AS rac_tail,
    (SELECT COUNT(*) FROM ags.ra_summ WHERE ras_ra > @ra_key_max_before) AS ras_tail
FROM ags.ra;

COMMIT TRANSACTION;
