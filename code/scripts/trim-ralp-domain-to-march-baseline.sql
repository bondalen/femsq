-- Приведение домена RALP (2026) к мартовскому перечню документов.
--
-- Источник перечня: staging exec_key=1152 (файл 2026_03/(2026)_Аренда_рабочий.xlsx, прогон 2026-07-09).
-- Март: 424 строки staging, 420 valid (cst+og resolved), 4 invalid.
-- Июль (exec 1153): 1262 staging, 1248 valid — на 828 документов больше марта.
--
-- До скрипта: ralpRa_2026=1248. После: ralpRa_2026=420, ralpRaAu_2026=420 (ожидаемо).
--
-- Часть 2: для 15 общих документов с разным состоянием — синхронизация ralpRaAu с мартовским staging.

SET NOCOUNT ON;

DECLARE @march_exec_key BIGINT = 1152;
DECLARE @year INT = 2026;

IF NOT EXISTS (SELECT 1 FROM ags.ra_stg_ralp WHERE ralprt_exec_key = @march_exec_key)
BEGIN
    RAISERROR('Нет staging exec_key=%d. Сначала dry-run ревизии на снимке 2026_03.', 16, 1, @march_exec_key);
    RETURN;
END;

BEGIN TRANSACTION;

-- Ключи мартовского перечня (нормализация num как в Java)
IF OBJECT_ID('tempdb..#march_keep') IS NOT NULL DROP TABLE #march_keep;
SELECT
    s.ralprt_key,
    CASE
        WHEN ISNULL(s.ralprtPresented, 0) = 1 AND CHARINDEX(N'-', s.ralprtNum) > 0
            THEN STUFF(s.ralprtNum, CHARINDEX(N'-', s.ralprtNum), 1, N'/')
        ELSE s.ralprtNum
    END AS ralprNum,
    s.ralprtDate,
    s.ralprtCstAgPn,
    s.ralprtOgSender,
    s.ralprtArrived,
    s.ralprtSent,
    s.ralprtReturned,
    s.ralprtNote,
    s.ralprtCostAndVat,
    s.ralprtStatus,
    s.ralprtTestStartDate
INTO #march_keep
FROM ags.ra_stg_ralp s
WHERE s.ralprt_exec_key = @march_exec_key
  AND s.ralprtCstAgPn IS NOT NULL
  AND s.ralprtOgSender IS NOT NULL
  AND s.ralprtNum IS NOT NULL
  AND s.ralprtDate IS NOT NULL;

-- 1. Удалить ralpRaAu для записей вне мартовского перечня
DELETE au
FROM ags.ralpRaAu au
JOIN ags.ralpRa r ON r.ralprKey = au.ralpraRa
WHERE r.ralprY = @year
  AND NOT EXISTS (
      SELECT 1 FROM #march_keep k
      WHERE k.ralprNum = r.ralprNum
        AND k.ralprtDate = r.ralprDate
        AND k.ralprtCstAgPn = r.ralprCstAgPn
        AND k.ralprtOgSender = r.ralprOgSender
  );

-- 2. Удалить ralpRa вне мартовского перечня
DELETE r
FROM ags.ralpRa r
WHERE r.ralprY = @year
  AND NOT EXISTS (
      SELECT 1 FROM #march_keep k
      WHERE k.ralprNum = r.ralprNum
        AND k.ralprtDate = r.ralprDate
        AND k.ralprtCstAgPn = r.ralprCstAgPn
        AND k.ralprtOgSender = r.ralprOgSender
  );

-- 3. Синхронизировать состояние ralpRaAu с мартовским staging (15 расхождений с июлем)
UPDATE au
SET
    au.ralpraCostAndVat = k.ralprtCostAndVat,
    au.ralpraSent = k.ralprtSent,
    au.ralpraSentDate = TRY_CONVERT(DATE, LTRIM(RTRIM(k.ralprtSent)), 104),
    au.ralpraReturned = k.ralprtReturned,
    au.ralpraReturnedDate = TRY_CONVERT(DATE, LTRIM(RTRIM(k.ralprtReturned)), 104),
    au.ralpraNote = k.ralprtNote,
    au.ralpraStatus = ISNULL(k.ralprtStatus, 0),
    au.ralpraTestStartDate = k.ralprtTestStartDate
FROM ags.ralpRaAu au
JOIN ags.ralpRa r ON r.ralprKey = au.ralpraRa
JOIN #march_keep k
  ON k.ralprNum = r.ralprNum
 AND k.ralprtDate = r.ralprDate
 AND k.ralprtCstAgPn = r.ralprCstAgPn
 AND k.ralprtOgSender = r.ralprOgSender
WHERE r.ralprY = @year
  AND LTRIM(RTRIM(ISNULL(au.ralpraArrived, N''))) = LTRIM(RTRIM(ISNULL(k.ralprtArrived, N'')));

SELECT
    (SELECT COUNT(*) FROM #march_keep) AS march_valid_keys,
    (SELECT COUNT(*) FROM ags.ralpRa WHERE ralprY = @year) AS ralpRa_2026,
    (SELECT COUNT(*) FROM ags.ralpRaAu au JOIN ags.ralpRa r ON r.ralprKey = au.ralpraRa WHERE r.ralprY = @year) AS ralpRaAu_2026,
    (SELECT COUNT(*) FROM ags.ralpRa r WHERE r.ralprY = @year AND NOT EXISTS (
        SELECT 1 FROM #march_keep k WHERE k.ralprNum=r.ralprNum AND k.ralprtDate=r.ralprDate
          AND k.ralprtCstAgPn=r.ralprCstAgPn AND k.ralprtOgSender=r.ralprOgSender)) AS orphan_ra;

COMMIT TRANSACTION;
