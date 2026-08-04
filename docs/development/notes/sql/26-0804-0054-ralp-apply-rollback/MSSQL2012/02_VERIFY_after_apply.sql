-- =============================================================================
-- 02_VERIFY_after_apply.sql  (FishEye / MSSQL 2012 SP4)
-- Сверка после UI apply type=3. Не меняет данные.
-- =============================================================================
USE FishEye;
GO

SET NOCOUNT ON;

PRINT '=== AFTER counts vs bak ===';
SELECT
    (SELECT COUNT(*) FROM ags.ralpRa WHERE ralprY = 2026) AS ra_now,
    (SELECT COUNT(*) FROM ags.ralpRa_bak_20260804) AS ra_bak,
    (SELECT COUNT(*) FROM ags.ralpRa WHERE ralprY = 2026)
      - (SELECT COUNT(*) FROM ags.ralpRa_bak_20260804) AS ra_delta;

SELECT
    (SELECT COUNT(*) FROM ags.ralpRaAu au
     INNER JOIN ags.ralpRa r ON r.ralprKey = au.ralpraRa
     WHERE r.ralprY = 2026) AS au_now,
    (SELECT COUNT(*) FROM ags.ralpRaAu_bak_20260804) AS au_bak;

PRINT '=== Keys newer than bak max (ожидаемо ~325 RA) ===';
DECLARE @max_bak_ra INT;
SELECT @max_bak_ra = MAX(ralprKey) FROM ags.ralpRa_bak_20260804;

SELECT COUNT(*) AS new_ra_keys
FROM ags.ralpRa
WHERE ralprY = 2026 AND ralprKey > @max_bak_ra;

SELECT TOP 10 ralprKey, ralprNum, ralprDate, ralprCstAgPn, ralprOgSender
FROM ags.ralpRa
WHERE ralprY = 2026 AND ralprKey > @max_bak_ra
ORDER BY ralprKey;

PRINT '=== Sample: report 480 must still exist (not deleted) ===';
SELECT ralprKey, ralprNum, ralprDate, ralprCstAgPn, ralprOgSender
FROM ags.ralpRa
WHERE ralprY = 2026 AND ralprNum = N'480';

PRINT '=== DONE verify. If OK: uncheck AddRA in UI. If bad: run 03_ROLLBACK. ===';
GO
