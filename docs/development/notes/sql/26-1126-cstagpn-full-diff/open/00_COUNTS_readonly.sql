/*
 * C2 §3.5.1 — counts cstAgPn (+ родители) на ТЕКУЩЕЙ БД (прод или noM6).
 * Только чтение. SQL Server 2012.
 * lastUpdated: 2026-11-26
 */
SET NOCOUNT ON;

SELECT
    DB_NAME() AS db_name,
    @@SERVERNAME AS server_name;

SELECT
    (SELECT COUNT(*) FROM ags.cstAgPn) AS cstAgPn_cnt,
    (SELECT COUNT(*) FROM ags.cstAg) AS cstAg_cnt,
    (SELECT COUNT(*) FROM ags.cst) AS cst_cnt,
    (SELECT COUNT(*) FROM ags.ogAg) AS ogAg_cnt;

SELECT TOP 5 cstapKey, cstapIpgPnN
FROM ags.cstAgPn
ORDER BY cstapKey DESC;
GO
