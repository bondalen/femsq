-- =============================================================================
-- 07_VERIFY_after.sql — 0054 bootstrap (MSSQL2012)
-- =============================================================================

PRINT '=== 07_VERIFY_after: 26-0730-0054-ra-bootstrap ===';
PRINT 'Дата: ' + CONVERT(nvarchar(30), GETDATE(), 121);
PRINT 'БД: ' + DB_NAME();

SELECT t.name AS table_name,
       CASE WHEN OBJECT_ID(N'ags.' + t.name, N'U') IS NOT NULL THEN N'OK' ELSE N'MISSING' END AS status
FROM (VALUES
    (N'ra_a'),(N'ra_at'),(N'ra_dir'),(N'ra_f'),(N'ra_ft'),(N'ra_ft_s'),(N'ra_ft_sn'),(N'ra_ft_st'),
    (N'ra_stg_ra'),(N'ra_stg_ralp'),(N'ra_stg_ralp_sm'),(N'ra_stg_agfee'),(N'ra_execution'),
    (N'ra_sheet_conf'),(N'ra_col_map')
) t(name)
ORDER BY table_name;

SELECT CASE
    WHEN OBJECT_ID(N'ags.ra_a', N'U') IS NULL THEN N'TABLE_MISSING'
    WHEN COL_LENGTH(N'ags.ra_a', N'adt_staging_log_level') IS NULL THEN N'COLUMN_MISSING'
    ELSE N'TABLE_AND_COLUMN_EXIST'
END AS ra_a_verification;

SELECT N'ralprtRow' AS col,
       CASE WHEN COL_LENGTH(N'ags.ra_stg_ralp', N'ralprtRow') IS NULL THEN N'MISSING' ELSE N'OK' END AS status
UNION ALL SELECT N'ralprsRow',
       CASE WHEN COL_LENGTH(N'ags.ra_stg_ralp_sm', N'ralprsRow') IS NULL THEN N'MISSING' ELSE N'OK' END
UNION ALL SELECT N'oafptRow',
       CASE WHEN COL_LENGTH(N'ags.ra_stg_agfee', N'oafptRow') IS NULL THEN N'MISSING' ELSE N'OK' END
UNION ALL SELECT N'oafptOafSenderKey',
       CASE WHEN COL_LENGTH(N'ags.ra_stg_agfee', N'oafptOafSenderKey') IS NULL THEN N'MISSING' ELSE N'OK' END
UNION ALL SELECT N'oafptPnCstAgPnKey',
       CASE WHEN COL_LENGTH(N'ags.ra_stg_agfee', N'oafptPnCstAgPnKey') IS NULL THEN N'MISSING' ELSE N'OK' END;

SELECT N'ra_ft' AS tbl, COUNT(*) AS cnt FROM ags.ra_ft
UNION ALL SELECT N'ra_at', COUNT(*) FROM ags.ra_at
UNION ALL SELECT N'ra_sheet_conf', COUNT(*) FROM ags.ra_sheet_conf
UNION ALL SELECT N'ra_col_map', COUNT(*) FROM ags.ra_col_map;

PRINT '=== 07_VERIFY_after: готово ===';
GO
