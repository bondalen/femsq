-- 0054 / RALP key match simulation — READ ONLY
-- !!! SET @exec_key to the last type=3 dry-run with ~1262 staging rows
-- (from 00_FIND_LAST_TYPE3_EXEC.sql)
USE FishEye;
GO

DECLARE @exec_key INT = 0;  -- <<< REPLACE with real exec_key
DECLARE @year INT = 2026;

IF @exec_key = 0
BEGIN
    RAISERROR(N'Set @exec_key to last type=3 staging exec_key (see 00_FIND...).', 16, 1);
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
        ISNULL(s.ralprtPresented, 0) AS presented,
        CASE WHEN s.ralprtCstAgPn IS NULL OR s.ralprtOgSender IS NULL OR s.ralprtDate IS NULL THEN 1 ELSE 0 END AS invalid_fk
    FROM ags.ra_stg_ralp s
    WHERE s.ralprt_exec_key = @exec_key
),
dom AS (
    SELECT
        ra.ralprKey,
        ra.ralprNum AS num,
        CAST(ra.ralprDate AS date) AS dt,
        ra.ralprCstAgPn AS cst,
        ra.ralprOgSender AS og
    FROM ags.ralpRa ra
    WHERE ra.ralprY = @year
),
matched AS (
    SELECT s.excel_row, s.norm_num, s.dt, s.cst, s.og, d.ralprKey
    FROM stg s
    INNER JOIN dom d
        ON d.num = s.norm_num AND d.dt = s.dt AND d.cst = s.cst AND d.og = s.og
    WHERE s.invalid_fk = 0
)
SELECT
    @exec_key AS exec_key,
    (SELECT COUNT(*) FROM stg) AS stg_total,
    (SELECT COUNT(*) FROM stg WHERE invalid_fk = 1) AS stg_invalid,
    (SELECT COUNT(*) FROM stg WHERE invalid_fk = 0) AS stg_valid,
    (SELECT COUNT(*) FROM dom) AS domain_ra,
    (SELECT COUNT(*) FROM matched) AS matched_full_key,
    (SELECT COUNT(*) FROM stg WHERE invalid_fk = 0) - (SELECT COUNT(*) FROM matched) AS would_insert,
    (SELECT COUNT(*) FROM dom) - (SELECT COUNT(DISTINCT ralprKey) FROM matched) AS would_orphan_delete;

-- Partial keys (diagnose WHICH field breaks)
;WITH stg AS (
    SELECT
        CASE
            WHEN ISNULL(s.ralprtPresented, 0) = 1 AND CHARINDEX('-', s.ralprtNum) > 0
                THEN STUFF(s.ralprtNum, CHARINDEX('-', s.ralprtNum), 1, '/')
            ELSE s.ralprtNum
        END AS norm_num,
        CAST(s.ralprtDate AS date) AS dt,
        s.ralprtCstAgPn AS cst,
        s.ralprtOgSender AS og,
        CASE WHEN s.ralprtCstAgPn IS NULL OR s.ralprtOgSender IS NULL OR s.ralprtDate IS NULL THEN 1 ELSE 0 END AS invalid_fk
    FROM ags.ra_stg_ralp s
    WHERE s.ralprt_exec_key = @exec_key
),
dom AS (
    SELECT ra.ralprNum AS num, CAST(ra.ralprDate AS date) AS dt, ra.ralprCstAgPn AS cst, ra.ralprOgSender AS og
    FROM ags.ralpRa ra
    WHERE ra.ralprY = @year
)
SELECT N'full_key' AS kind, COUNT(*) AS cnt FROM stg s
  INNER JOIN dom d ON d.num=s.norm_num AND d.dt=s.dt AND d.cst=s.cst AND d.og=s.og WHERE s.invalid_fk=0
UNION ALL
SELECT N'num_date_only', COUNT(*) FROM stg s
  INNER JOIN dom d ON d.num=s.norm_num AND d.dt=s.dt WHERE s.invalid_fk=0
UNION ALL
SELECT N'num_date_cst', COUNT(*) FROM stg s
  INNER JOIN dom d ON d.num=s.norm_num AND d.dt=s.dt AND d.cst=s.cst WHERE s.invalid_fk=0
UNION ALL
SELECT N'num_date_og', COUNT(*) FROM stg s
  INNER JOIN dom d ON d.num=s.norm_num AND d.dt=s.dt AND d.og=s.og WHERE s.invalid_fk=0
UNION ALL
SELECT N'domain_num_date_in_stg', COUNT(*) FROM dom d
  WHERE EXISTS (SELECT 1 FROM stg s WHERE s.invalid_fk=0 AND s.norm_num=d.num AND s.dt=d.dt);
GO
