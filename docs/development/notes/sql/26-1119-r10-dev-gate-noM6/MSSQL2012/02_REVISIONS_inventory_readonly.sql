/*
 * R1.0 DEV-гейт: контур ревизий (0054 + домен type 3/5/6). Только чтение.
 * Прод SSMS / FishEye. lastUpdated: 2026-11-19
 */
SET NOCOUNT ON;

SELECT
    N'rev-table' AS section,
    t.name AS table_name,
    CASE WHEN OBJECT_ID(N'ags.' + t.name, N'U') IS NOT NULL
         THEN N'OK' ELSE N'MISSING' END AS status
FROM (VALUES
    (N'ra_a'),(N'ra_at'),(N'ra_dir'),(N'ra_f'),(N'ra_ft'),(N'ra_ft_s'),(N'ra_ft_sn'),
    (N'ra_stg_ra'),(N'ra_stg_ralp'),(N'ra_stg_ralp_sm'),(N'ra_stg_agfee'),(N'ra_execution'),
    (N'ralpRa'),(N'ralpRaAu'),(N'ra_summ'),
    (N'ogAgFee'),(N'ogAgFeeP')
) AS t(name)
ORDER BY table_name;

SELECT
    N'ra_a_log_level' AS section,
    CASE
        WHEN OBJECT_ID(N'ags.ra_a', N'U') IS NULL THEN N'TABLE_MISSING'
        WHEN COL_LENGTH(N'ags.ra_a', N'adt_staging_log_level') IS NULL THEN N'COLUMN_MISSING'
        ELSE N'TABLE_AND_COLUMN_EXIST'
    END AS ra_a_verification;

SELECT
    N'stg-row-cols' AS section,
    N'ralprtRow' AS col,
    CASE WHEN COL_LENGTH(N'ags.ra_stg_ralp', N'ralprtRow') IS NULL
         THEN N'MISSING' ELSE N'OK' END AS status
UNION ALL
SELECT N'stg-row-cols', N'oafptRow',
    CASE WHEN COL_LENGTH(N'ags.ra_stg_agfee', N'oafptRow') IS NULL
         THEN N'MISSING' ELSE N'OK' END;

SELECT
    N'rev-rowcounts' AS section,
    (SELECT COUNT(*) FROM ags.ralpRa) AS ralpRa_n,
    (SELECT COUNT(*) FROM ags.ralpRaAu) AS ralpRaAu_n,
    (SELECT COUNT(*) FROM ags.ogAgFee) AS ogAgFee_n,
    (SELECT COUNT(*) FROM ags.ogAgFeeP) AS ogAgFeeP_n,
    (SELECT COUNT(*) FROM ags.ra_a) AS ra_a_n;
