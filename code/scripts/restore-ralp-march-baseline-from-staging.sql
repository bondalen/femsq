-- Восстановление мартовской базы RALP (420 valid) из staging exec_key=1152.
-- Полный мартовский перечень: 424 staging, 420 valid (файл 2026_03).
-- НЕ использовать exec_key=1135 (1262 строк — фактически июльский объём).

SET NOCOUNT ON;

DECLARE @march_exec_key BIGINT = 1152;
DECLARE @year INT = 2026;

IF (SELECT COUNT(*) FROM ags.ra_stg_ralp WHERE ralprt_exec_key = @march_exec_key) < 400
BEGIN
    RAISERROR('Staging exec_key=%d не найден или неполный. Запустите dry-run на снимке 2026_03.', 16, 1, @march_exec_key);
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
        ELSE s.ralprtNum
    END,
    s.ralprtDate,
    s.ralprtCstAgPn,
    s.ralprtOgSender
FROM ags.ra_stg_ralp s
WHERE s.ralprt_exec_key = @march_exec_key
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
        ELSE s.ralprtNum
    END
WHERE s.ralprt_exec_key = @march_exec_key
  AND s.ralprtArrived IS NOT NULL AND LTRIM(RTRIM(s.ralprtArrived)) <> N''
  AND s.ralprtCstAgPn IS NOT NULL AND s.ralprtOgSender IS NOT NULL;

SELECT
    (SELECT COUNT(*) FROM ags.ralpRa WHERE ralprY = @year) AS ralpRa_2026,
    (SELECT COUNT(*) FROM ags.ralpRaAu au JOIN ags.ralpRa r ON r.ralprKey = au.ralpraRa WHERE r.ralprY = @year) AS ralpRaAu_2026;

COMMIT TRANSACTION;
