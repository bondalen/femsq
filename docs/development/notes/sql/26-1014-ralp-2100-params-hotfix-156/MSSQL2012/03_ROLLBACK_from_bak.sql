-- =============================================================================
-- 03_ROLLBACK_from_bak.sql  (FishEye / MSSQL 2012 SP4)
-- Откат года 2026 к ags.ralpRa_bak_20261015 / ralpRaAu_bak_20261015.
-- Не использует августовские *_bak_20260804.
-- Удаляет текущие ralpRa/Au 2026, затем восстанавливает из bak.
-- COMMIT в скрипте нет: после сверки counts выполните вручную
--   COMMIT TRANSACTION;   или   ROLLBACK TRANSACTION;
-- Колонки — как на проде 2026-08-04 (ralpRa 7, ralpRaAu 12, без ralpra_fdKey).
-- =============================================================================
USE FishEye;
GO

SET NOCOUNT ON;

IF OBJECT_ID(N'ags.ralpRa_bak_20261015', N'U') IS NULL
BEGIN
    RAISERROR('Нет ags.ralpRa_bak_20261015 — откат невозможен.', 16, 1);
    RETURN;
END;

IF OBJECT_ID(N'ags.ralpRaAu_bak_20261015', N'U') IS NULL
BEGIN
    RAISERROR('Нет ags.ralpRaAu_bak_20261015 — откат невозможен.', 16, 1);
    RETURN;
END;

PRINT '=== BAK sizes ===';
SELECT COUNT(*) AS ra_bak FROM ags.ralpRa_bak_20261015;
SELECT COUNT(*) AS au_bak FROM ags.ralpRaAu_bak_20261015;

BEGIN TRANSACTION;

PRINT '=== DELETE current 2026 ===';
DELETE au
FROM ags.ralpRaAu au
INNER JOIN ags.ralpRa r ON r.ralprKey = au.ralpraRa
WHERE r.ralprY = 2026;

DELETE FROM ags.ralpRa WHERE ralprY = 2026;

PRINT '=== RESTORE ralpRa FROM bak (IDENTITY_INSERT) ===';
SET IDENTITY_INSERT ags.ralpRa ON;

INSERT INTO ags.ralpRa (
    ralprKey, ralprNum, ralprDate, ralprCstAgPn, ralprOgSender, ralprY, ralprM
)
SELECT
    ralprKey, ralprNum, ralprDate, ralprCstAgPn, ralprOgSender, ralprY, ralprM
FROM ags.ralpRa_bak_20261015;

SET IDENTITY_INSERT ags.ralpRa OFF;

PRINT '=== RESTORE ralpRaAu FROM bak (IDENTITY_INSERT) ===';
SET IDENTITY_INSERT ags.ralpRaAu ON;

INSERT INTO ags.ralpRaAu (
    ralpraKey,
    ralpraRa,
    ralpraCostAndVat,
    ralpraArrived,
    ralpraArrivedDate,
    ralpraReturned,
    ralpraReturnedDate,
    ralpraSent,
    ralpraSentDate,
    ralpraNote,
    ralpraStatus,
    ralpraTestStartDate
)
SELECT
    ralpraKey,
    ralpraRa,
    ralpraCostAndVat,
    ralpraArrived,
    ralpraArrivedDate,
    ralpraReturned,
    ralpraReturnedDate,
    ralpraSent,
    ralpraSentDate,
    ralpraNote,
    ralpraStatus,
    ralpraTestStartDate
FROM ags.ralpRaAu_bak_20261015;

SET IDENTITY_INSERT ags.ralpRaAu OFF;

PRINT '=== COMPARE now vs bak (must match) ===';
SELECT
    (SELECT COUNT(*) FROM ags.ralpRa WHERE ralprY = 2026) AS ra_now,
    (SELECT COUNT(*) FROM ags.ralpRa_bak_20261015) AS ra_bak;

SELECT
    (SELECT COUNT(*) FROM ags.ralpRaAu au
     INNER JOIN ags.ralpRa r ON r.ralprKey = au.ralpraRa
     WHERE r.ralprY = 2026) AS au_now,
    (SELECT COUNT(*) FROM ags.ralpRaAu_bak_20261015) AS au_bak;

PRINT '=== ВАЖНО: COMMIT TRANSACTION; или ROLLBACK TRANSACTION; вручную ===';
GO
