-- 0054 / RALP key diagnostics (FishEye / MSSQL2012) — READ ONLY
-- Find last type=3 executions and staging sizes.
-- Password/transfer: au#LL891
USE FishEye;
GO

-- Recent executions (status + dry-run flag)
SELECT TOP 30
    e.exec_key,
    e.exec_adt_key,
    e.exec_status,
    e.exec_add_ra,
    e.exec_started,
    e.exec_finished
FROM ags.ra_execution e
ORDER BY e.exec_key DESC;

-- Staging counts by exec (type=3 = ra_stg_ralp)
SELECT TOP 20
    s.ralprt_exec_key AS exec_key,
    COUNT(*) AS stg_cnt,
    SUM(CASE WHEN s.ralprtCstAgPn IS NULL OR s.ralprtOgSender IS NULL OR s.ralprtDate IS NULL THEN 1 ELSE 0 END) AS invalid_fk
FROM ags.ra_stg_ralp s
GROUP BY s.ralprt_exec_key
ORDER BY s.ralprt_exec_key DESC;

-- Domain year 2026
SELECT COUNT(*) AS ralpRa_2026 FROM ags.ralpRa WHERE ralprY = 2026;
SELECT COUNT(*) AS ralpRaAu_2026
FROM ags.ralpRaAu au
INNER JOIN ags.ralpRa ra ON au.ralpraRa = ra.ralprKey
WHERE ra.ralprY = 2026;
GO
