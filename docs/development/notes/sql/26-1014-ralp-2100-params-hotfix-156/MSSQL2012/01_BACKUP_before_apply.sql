-- =============================================================================
-- 01_BACKUP_before_apply.sql  (FishEye / MSSQL 2012 SP4)
-- Снимок ags.ralpRa / ags.ralpRaAu за 2026 ПЕРЕД деплоем thin 156 и apply type=3.
-- Не трогает августовские ags.*_bak_20260804.
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

IF OBJECT_ID(N'ags.ralpRa_bak_20261015', N'U') IS NOT NULL
BEGIN
    PRINT 'DROP existing ags.ralpRa_bak_20261015';
    DROP TABLE ags.ralpRa_bak_20261015;
END;

IF OBJECT_ID(N'ags.ralpRaAu_bak_20261015', N'U') IS NOT NULL
BEGIN
    PRINT 'DROP existing ags.ralpRaAu_bak_20261015';
    DROP TABLE ags.ralpRaAu_bak_20261015;
END;

PRINT '=== SELECT INTO bak ===';
SELECT *
INTO ags.ralpRa_bak_20261015
FROM ags.ralpRa
WHERE ralprY = 2026;

SELECT au.*
INTO ags.ralpRaAu_bak_20261015
FROM ags.ralpRaAu au
INNER JOIN ags.ralpRa r ON r.ralprKey = au.ralpraRa
WHERE r.ralprY = 2026;

PRINT '=== BAK counts (must equal BEFORE) ===';
SELECT COUNT(*) AS ra_bak FROM ags.ralpRa_bak_20261015;
SELECT COUNT(*) AS au_bak FROM ags.ralpRaAu_bak_20261015;

PRINT '=== DONE backup. Приложение пока не останавливать, файлы не менять. ===';
GO
