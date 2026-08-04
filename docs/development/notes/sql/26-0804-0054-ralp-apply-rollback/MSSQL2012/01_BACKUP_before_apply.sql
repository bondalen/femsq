-- =============================================================================
-- 01_BACKUP_before_apply.sql  (FishEye / MSSQL 2012 SP4)
-- Снимок ags.ralpRa / ags.ralpRaAu за 2026 ПЕРЕД apply type=3.
-- Имя bak привязано к дате пакета; при повторном прогоне — DROP старых bak.
-- =============================================================================
USE FishEye;
GO

SET NOCOUNT ON;

PRINT '=== BEFORE counts ===';
SELECT COUNT(*) AS ra_2026 FROM ags.ralpRa WHERE ralprY = 2026;
SELECT COUNT(*) AS au_2026
FROM ags.ralpRaAu au
INNER JOIN ags.ralpRa r ON r.ralprKey = au.ralpraRa
WHERE r.ralprY = 2026;
SELECT MAX(ralprKey) AS max_ralprKey FROM ags.ralpRa WHERE ralprY = 2026;
SELECT MAX(au.ralpraKey) AS max_ralpraKey
FROM ags.ralpRaAu au
INNER JOIN ags.ralpRa r ON r.ralprKey = au.ralpraRa
WHERE r.ralprY = 2026;

IF OBJECT_ID(N'ags.ralpRa_bak_20260804', N'U') IS NOT NULL
BEGIN
    PRINT 'DROP existing ags.ralpRa_bak_20260804';
    DROP TABLE ags.ralpRa_bak_20260804;
END;

IF OBJECT_ID(N'ags.ralpRaAu_bak_20260804', N'U') IS NOT NULL
BEGIN
    PRINT 'DROP existing ags.ralpRaAu_bak_20260804';
    DROP TABLE ags.ralpRaAu_bak_20260804;
END;

PRINT '=== SELECT INTO bak ===';
SELECT *
INTO ags.ralpRa_bak_20260804
FROM ags.ralpRa
WHERE ralprY = 2026;

SELECT au.*
INTO ags.ralpRaAu_bak_20260804
FROM ags.ralpRaAu au
INNER JOIN ags.ralpRa r ON r.ralprKey = au.ralpraRa
WHERE r.ralprY = 2026;

PRINT '=== BAK counts (must equal BEFORE) ===';
SELECT COUNT(*) AS ra_bak FROM ags.ralpRa_bak_20260804;
SELECT COUNT(*) AS au_bak FROM ags.ralpRaAu_bak_20260804;

PRINT '=== DONE backup. Proceed to UI apply (AddRA=1). ===';
GO
