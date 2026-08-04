-- 0054 / sample rows where num+date match but full key does NOT — READ ONLY
-- Shows whether cst or og differs (typical Access vs FEMSQ Stage2 drift).
USE FishEye;
GO

DECLARE @exec_key INT = 0;  -- <<< REPLACE
DECLARE @year INT = 2026;

IF @exec_key = 0
BEGIN
    RAISERROR(N'Set @exec_key (same as in 01_MATCH_SIMULATION.sql).', 16, 1);
    RETURN;
END

;WITH stg AS (
    SELECT
        s.ralprtRow AS excel_row,
        s.ralprtNum AS raw_num,
        CASE
            WHEN ISNULL(s.ralprtPresented, 0) = 1 AND CHARINDEX('-', s.ralprtNum) > 0
                THEN STUFF(s.ralprtNum, CHARINDEX('-', s.ralprtNum), 1, '/')
            ELSE s.ralprtNum
        END AS norm_num,
        CAST(s.ralprtDate AS date) AS dt,
        s.ralprtCstAgPn AS cst,
        s.ralprtOgSender AS og,
        ISNULL(s.ralprtPresented, 0) AS presented
    FROM ags.ra_stg_ralp s
    WHERE s.ralprt_exec_key = @exec_key
      AND s.ralprtCstAgPn IS NOT NULL
      AND s.ralprtOgSender IS NOT NULL
      AND s.ralprtDate IS NOT NULL
),
dom AS (
    SELECT ra.ralprKey, ra.ralprNum AS num, CAST(ra.ralprDate AS date) AS dt,
           ra.ralprCstAgPn AS cst, ra.ralprOgSender AS og
    FROM ags.ralpRa ra
    WHERE ra.ralprY = @year
)
-- Same num+date, different cst and/or og
SELECT TOP 40
    s.excel_row,
    s.norm_num,
    s.dt,
    s.presented,
    s.cst AS stg_cst,
    d.cst AS dom_cst,
    s.og AS stg_og,
    d.og AS dom_og,
    CASE WHEN s.cst <> d.cst THEN N'cst' ELSE N'' END
      + CASE WHEN s.cst <> d.cst AND s.og <> d.og THEN N'+' ELSE N'' END
      + CASE WHEN s.og <> d.og THEN N'og' ELSE N'' END AS differs
FROM stg s
INNER JOIN dom d ON d.num = s.norm_num AND d.dt = s.dt
WHERE NOT (s.cst = d.cst AND s.og = d.og)
ORDER BY s.excel_row;

-- Domain rows with num+date NOT present in staging at all (true orphans if keys were OK)
;WITH stg AS (
    SELECT
        CASE
            WHEN ISNULL(s.ralprtPresented, 0) = 1 AND CHARINDEX('-', s.ralprtNum) > 0
                THEN STUFF(s.ralprtNum, CHARINDEX('-', s.ralprtNum), 1, '/')
            ELSE s.ralprtNum
        END AS norm_num,
        CAST(s.ralprtDate AS date) AS dt
    FROM ags.ra_stg_ralp s
    WHERE s.ralprt_exec_key = @exec_key
      AND s.ralprtCstAgPn IS NOT NULL AND s.ralprtOgSender IS NOT NULL AND s.ralprtDate IS NOT NULL
),
dom AS (
    SELECT ra.ralprKey, ra.ralprNum AS num, CAST(ra.ralprDate AS date) AS dt,
           ra.ralprCstAgPn AS cst, ra.ralprOgSender AS og
    FROM ags.ralpRa ra
    WHERE ra.ralprY = @year
)
SELECT TOP 40
    d.ralprKey, d.num, d.dt, d.cst, d.og
FROM dom d
WHERE NOT EXISTS (SELECT 1 FROM stg s WHERE s.norm_num = d.num AND s.dt = d.dt)
ORDER BY d.num, d.dt;

-- Staging valid rows with no domain hit even on num+date
;WITH stg AS (
    SELECT
        s.ralprtRow AS excel_row,
        CASE
            WHEN ISNULL(s.ralprtPresented, 0) = 1 AND CHARINDEX('-', s.ralprtNum) > 0
                THEN STUFF(s.ralprtNum, CHARINDEX('-', s.ralprtNum), 1, '/')
            ELSE s.ralprtNum
        END AS norm_num,
        CAST(s.ralprtDate AS date) AS dt,
        s.ralprtCstAgPn AS cst,
        s.ralprtOgSender AS og
    FROM ags.ra_stg_ralp s
    WHERE s.ralprt_exec_key = @exec_key
      AND s.ralprtCstAgPn IS NOT NULL AND s.ralprtOgSender IS NOT NULL AND s.ralprtDate IS NOT NULL
),
dom AS (
    SELECT ra.ralprNum AS num, CAST(ra.ralprDate AS date) AS dt
    FROM ags.ralpRa ra
    WHERE ra.ralprY = @year
)
SELECT TOP 40
    s.excel_row, s.norm_num, s.dt, s.cst, s.og
FROM stg s
WHERE NOT EXISTS (SELECT 1 FROM dom d WHERE d.num = s.norm_num AND d.dt = s.dt)
ORDER BY s.excel_row;
GO
