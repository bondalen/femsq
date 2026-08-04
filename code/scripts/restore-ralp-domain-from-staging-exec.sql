-- Восстановление домена RALP 2026 из staging указанного exec_key (полный REPLACE года).
-- Использование: sqlcmd ... -v exec_key=XXXX -i restore-ralp-domain-from-staging-exec.sql
-- После exec с onfKey (старые прогоны) — обязательно heal onfKey→onfOg.

SET NOCOUNT ON;

DECLARE @exec_key BIGINT = $(exec_key);
DECLARE @year INT = 2026;

IF (SELECT COUNT(*) FROM ags.ra_stg_ralp WHERE ralprt_exec_key = @exec_key) < 1
BEGIN
    RAISERROR('Staging exec_key=%d пуст.', 16, 1, @exec_key);
    RETURN;
END;

BEGIN TRANSACTION;

DELETE au
  FROM ags.ralpRaAu au
  JOIN ags.ralpRa r ON r.ralprKey = au.ralpraRa
 WHERE r.ralprY = @year;

DELETE FROM ags.ralpRa WHERE ralprY = @year;

INSERT INTO ags.ralpRa (ralprNum, ralprDate, ralprCstAgPn, ralprOgSender)
SELECT
    CASE
        WHEN ISNULL(s.ralprtPresented, 0) = 1 AND CHARINDEX(N'-', s.ralprtNum) > 0
            THEN STUFF(s.ralprtNum, CHARINDEX(N'-', s.ralprtNum), 1, N'/')
        WHEN s.ralprtNum LIKE N'%,00' AND s.ralprtNum NOT LIKE N'%/%'
            THEN LEFT(s.ralprtNum, LEN(s.ralprtNum) - 3)
        WHEN s.ralprtNum LIKE N'%.00' AND s.ralprtNum NOT LIKE N'%/%'
            THEN LEFT(s.ralprtNum, LEN(s.ralprtNum) - 3)
        ELSE s.ralprtNum
    END,
    s.ralprtDate,
    s.ralprtCstAgPn,
    s.ralprtOgSender
FROM ags.ra_stg_ralp s
WHERE s.ralprt_exec_key = @exec_key
  AND s.ralprtNum IS NOT NULL AND LTRIM(RTRIM(s.ralprtNum)) <> N''
  AND s.ralprtDate IS NOT NULL
  AND s.ralprtCstAgPn IS NOT NULL
  AND s.ralprtOgSender IS NOT NULL;

INSERT INTO ags.ralpRaAu (
    ralpraRa, ralpraArrived, ralpraArrivedDate,
    ralpraCostAndVat, ralpraSent, ralpraSentDate,
    ralpraReturned, ralpraReturnedDate,
    ralpraNote, ralpraStatus, ralpraTestStartDate
)
SELECT
    r.ralprKey,
    LTRIM(RTRIM(s.ralprtArrived)),
    TRY_CONVERT(DATE, LTRIM(RTRIM(s.ralprtArrived)), 104),
    s.ralprtCostAndVat,
    s.ralprtSent,
    TRY_CONVERT(DATE, LTRIM(RTRIM(s.ralprtSent)), 104),
    s.ralprtReturned,
    TRY_CONVERT(DATE, LTRIM(RTRIM(s.ralprtReturned)), 104),
    s.ralprtNote,
    ISNULL(s.ralprtStatus, 0),
    s.ralprtTestStartDate
FROM ags.ra_stg_ralp s
JOIN ags.ralpRa r
  ON r.ralprY = @year
 AND r.ralprDate = s.ralprtDate
 AND r.ralprCstAgPn = s.ralprtCstAgPn
 AND r.ralprOgSender = s.ralprtOgSender
 AND r.ralprNum = CASE
        WHEN ISNULL(s.ralprtPresented, 0) = 1 AND CHARINDEX(N'-', s.ralprtNum) > 0
            THEN STUFF(s.ralprtNum, CHARINDEX(N'-', s.ralprtNum), 1, N'/')
        WHEN s.ralprtNum LIKE N'%,00' AND s.ralprtNum NOT LIKE N'%/%'
            THEN LEFT(s.ralprtNum, LEN(s.ralprtNum) - 3)
        WHEN s.ralprtNum LIKE N'%.00' AND s.ralprtNum NOT LIKE N'%/%'
            THEN LEFT(s.ralprtNum, LEN(s.ralprtNum) - 3)
        ELSE s.ralprtNum
    END
WHERE s.ralprt_exec_key = @exec_key
  AND s.ralprtArrived IS NOT NULL AND LTRIM(RTRIM(s.ralprtArrived)) <> N''
  AND s.ralprtCstAgPn IS NOT NULL AND s.ralprtOgSender IS NOT NULL;

SELECT
    @exec_key AS from_exec,
    (SELECT COUNT(*) FROM ags.ralpRa WHERE ralprY = @year) AS ralpRa_2026,
    (SELECT COUNT(*) FROM ags.ralpRaAu au JOIN ags.ralpRa r ON r.ralprKey = au.ralpraRa WHERE r.ralprY = @year) AS ralpRaAu_2026;

COMMIT TRANSACTION;
