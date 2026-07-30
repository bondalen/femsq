-- =============================================================================
-- 00_VERIFY_before.sql — 0054 bootstrap (MSSQL2012)
-- Target: SPB-05-NV-SQL1 / FishEye / SQL Server 2012
-- =============================================================================

PRINT '=== 00_VERIFY_before: 26-0730-0054-ra-bootstrap ===';
PRINT 'Дата: ' + CONVERT(nvarchar(30), GETDATE(), 121);
PRINT 'БД: ' + DB_NAME();
PRINT 'Server: ' + @@SERVERNAME;
PRINT 'ProductVersion: ' + CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(50));
PRINT '';

SELECT
    CASE
        WHEN CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(50)) LIKE N'11.%' THEN N'OK for MSSQL2012 package'
        ELSE N'WARNING: ProductVersion not 11.x (expected SQL Server 2012)'
    END AS package_compat;

IF SCHEMA_ID(N'ags') IS NULL
    PRINT 'ERROR: schema ags MISSING';
ELSE
    PRINT 'schema ags: OK';

PRINT '--- Ожидание до CREATE: таблицы MISSING (или Skip если уже созданы) ---';
SELECT t.name AS table_name,
       CASE WHEN OBJECT_ID(N'ags.' + t.name, N'U') IS NOT NULL THEN N'EXISTS' ELSE N'MISSING' END AS status
FROM (VALUES
    (N'ra_a'),(N'ra_at'),(N'ra_dir'),(N'ra_f'),(N'ra_ft'),(N'ra_ft_s'),(N'ra_ft_sn'),(N'ra_ft_st'),
    (N'ra_stg_ra'),(N'ra_stg_ralp'),(N'ra_stg_ralp_sm'),(N'ra_stg_agfee'),(N'ra_execution'),
    (N'ra_sheet_conf'),(N'ra_col_map')
) t(name)
ORDER BY table_name;

PRINT '=== 00_VERIFY_before: готово ===';
GO
