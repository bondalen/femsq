/*
 * R1.0 DEV-гейт: маркеры M6 / объёмы. Только чтение.
 * Прод: SSMS, FishEye, Windows auth. Сетки → Cursor.
 * Синтаксис SQL Server 2012. lastUpdated: 2026-11-19
 * База: 26-1021-sudz-prod-survey/MSSQL2012/00_SURVEY_readonly.sql
 */
SET NOCOUNT ON;

SELECT
    N'identity' AS section,
    CAST(@@SERVERNAME AS nvarchar(128)) AS server_name,
    CAST(DB_NAME() AS nvarchar(128)) AS db_name,
    CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(32)) AS product_version,
    CAST(SERVERPROPERTY('ProductLevel') AS nvarchar(32)) AS product_level,
    CAST(SERVERPROPERTY('Edition') AS nvarchar(128)) AS edition;

SELECT
    N'compatibility' AS section,
    d.name AS db_name,
    d.compatibility_level,
    d.collation_name
FROM sys.databases AS d
WHERE d.name = DB_NAME();

SELECT
    N'object' AS section,
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc
FROM sys.objects AS o
INNER JOIN sys.schemas AS s ON s.schema_id = o.schema_id
WHERE s.name IN (N'ags', N'sudz')
  AND o.name IN (
        N'cn_inv_dbt', N'cnInvAccnt', N'cnInv', N'cn_inv_dbt_upl',
        N'invDbt', N'Dbt', N'DbtValue', N'invDbtDbt', N'invDbtTmpCiaRel',
        N'invDbtCia', N'cnInvCmm', N'yr', N'cn_inv_pm'
  )
ORDER BY s.name, o.name;

SELECT
    N'column' AS section,
    OBJECT_SCHEMA_NAME(c.object_id) AS schema_name,
    OBJECT_NAME(c.object_id) AS table_name,
    c.name AS column_name
FROM sys.columns AS c
WHERE OBJECT_NAME(c.object_id) = N'cnInvCmm'
  AND c.name IN (N'cnicInvAccnt', N'cnicDbt', N'cnicDv')
ORDER BY OBJECT_SCHEMA_NAME(c.object_id), c.name;

SELECT
    N'counts' AS section,
    (SELECT COUNT(*) FROM ags.cnInvAccnt) AS cia_rows,
    (SELECT COUNT(*) FROM ags.cn_inv_dbt) AS dbt_fact_rows,
    (SELECT COUNT(*) FROM ags.cn_inv_dbt_upl) AS upl_rows,
    (SELECT MAX(upl_key) FROM ags.cn_inv_dbt_upl) AS max_upl_key,
    (SELECT MAX(upl_date) FROM ags.cn_inv_dbt_upl) AS max_upl_date;

SELECT
    N'm6-absent-expect' AS section,
    CASE WHEN OBJECT_ID(N'sudz.Dbt', N'U') IS NULL
              AND OBJECT_ID(N'ags.Dbt', N'U') IS NULL
         THEN N'PASS' ELSE N'FAIL' END AS Dbt_absent,
    CASE WHEN OBJECT_ID(N'sudz.DbtValue', N'U') IS NULL
              AND OBJECT_ID(N'ags.DbtValue', N'U') IS NULL
         THEN N'PASS' ELSE N'FAIL' END AS DbtValue_absent,
    CASE WHEN OBJECT_ID(N'sudz.invDbtDbt', N'U') IS NULL
              AND OBJECT_ID(N'ags.invDbtDbt', N'U') IS NULL
         THEN N'PASS' ELSE N'FAIL' END AS invDbtDbt_absent,
    CASE WHEN COL_LENGTH(N'ags.cnInvCmm', N'cnicDbt') IS NULL
         THEN N'PASS' ELSE N'FAIL' END AS ags_cnicDbt_absent,
    CASE WHEN COL_LENGTH(N'ags.cnInvCmm', N'cnicDv') IS NULL
         THEN N'PASS' ELSE N'FAIL' END AS ags_cnicDv_absent,
    CASE WHEN OBJECT_ID(N'ags.invDbt', N'U') IS NOT NULL
         THEN N'PASS' ELSE N'FAIL' END AS ags_invDbt_present,
    CASE WHEN OBJECT_ID(N'ags.invDbtTmpCiaRel', N'U') IS NOT NULL
         THEN N'PASS' ELSE N'FAIL' END AS ags_invDbtTmpCiaRel_present;
