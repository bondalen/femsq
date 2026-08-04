-- =============================================================================
-- 03_ROLLBACK_from_bak.sql  (FishEye / MSSQL 2012 SP4)
-- Полный откат года 2026 к ags.ralpRa_bak_20260804 / ralpRaAu_bak_20260804.
-- ВНИМАНИЕ: удаляет текущие ralpRa/Au 2026, затем восстанавливает из bak.
-- Перед COMMIT сверьте counts. При сомнении — ROLLBACK TRANSACTION.
-- =============================================================================
USE FishEye;
GO

SET NOCOUNT ON;

IF OBJECT_ID(N'ags.ralpRa_bak_20260804', N'U') IS NULL
BEGIN
    RAISERROR('Нет ags.ralpRa_bak_20260804 — откат невозможен.', 16, 1);
    RETURN;
END;

IF OBJECT_ID(N'ags.ralpRaAu_bak_20260804', N'U') IS NULL
BEGIN
    RAISERROR('Нет ags.ralpRaAu_bak_20260804 — откат невозможен.', 16, 1);
    RETURN;
END;

PRINT '=== BAK sizes ===';
SELECT COUNT(*) AS ra_bak FROM ags.ralpRa_bak_20260804;
SELECT COUNT(*) AS au_bak FROM ags.ralpRaAu_bak_20260804;

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
FROM ags.ralpRa_bak_20260804;

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
FROM ags.ralpRaAu_bak_20260804;

SET IDENTITY_INSERT ags.ralpRaAu OFF;

PRINT '=== COMPARE now vs bak (must match) ===';
SELECT
    (SELECT COUNT(*) FROM ags.ralpRa WHERE ralprY = 2026) AS ra_now,
    (SELECT COUNT(*) FROM ags.ralpRa_bak_20260804) AS ra_bak;

SELECT
    (SELECT COUNT(*) FROM ags.ralpRaAu au
     INNER JOIN ags.ralpRa r ON r.ralprKey = au.ralpraRa
     WHERE r.ralprY = 2026) AS au_now,
    (SELECT COUNT(*) FROM ags.ralpRaAu_bak_20260804) AS au_bak;

-- Раскомментируйте ОДНУ строку:
-- COMMIT TRANSACTION;
-- ROLLBACK TRANSACTION;

PRINT '=== ВАЖНО: выполните COMMIT TRANSACTION; или ROLLBACK TRANSACTION; вручную ===';
GO
