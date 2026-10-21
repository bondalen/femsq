/*
 * Фаза A/B cutover: обследование FishEye на SPB-05-NV-SQL1. Только чтение.
 * SSMS, база FishEye, Windows auth. Результаты всех сеток принести в Cursor.
 * Синтаксис SQL Server 2012. lastUpdated: 2026-10-21
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
        N'cnInvCmm', N'yr', N'cn_inv_pm'
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
ORDER BY c.name;

SELECT
    N'counts' AS section,
    (SELECT COUNT(*) FROM ags.cnInvAccnt) AS cia_rows,
    (SELECT COUNT(*) FROM ags.cn_inv_dbt) AS dbt_fact_rows,
    (SELECT COUNT(*) FROM ags.cn_inv_dbt_upl) AS upl_rows,
    (SELECT MAX(upl_key) FROM ags.cn_inv_dbt_upl) AS max_upl_key,
    (SELECT MAX(upl_date) FROM ags.cn_inv_dbt_upl) AS max_upl_date;

;WITH raw AS (
    SELECT
        ci.ciInv AS iKey,
        CASE
            WHEN a.ciaName IS NULL OR LTRIM(RTRIM(a.ciaName)) = N'' THEN N'NullИлиПусто'
            ELSE LTRIM(RTRIM(a.ciaName))
        END AS ciaNameNull
    FROM ags.cnInvAccnt AS a
    INNER JOIN ags.cnInvAccntSmpl AS s ON a.ciaCnInvAccntSmpl = s.ciasKey
    INNER JOIN ags.cnInv AS ci ON s.ciasCnInv = ci.ciKey
)
SELECT
    N'grain' AS section,
    COUNT(*) AS n_slots_base
FROM (
    SELECT iKey, ciaNameNull
    FROM raw
    GROUP BY iKey, ciaNameNull
) AS g;

SELECT
    N'manual-ikey' AS section,
    q.iKey,
    q.klass,
    CASE WHEN EXISTS (
        SELECT 1
        FROM ags.cnInv AS ci
        WHERE ci.ciInv = q.iKey
    ) THEN 1 ELSE 0 END AS inv_exists,
    (
        SELECT COUNT(*)
        FROM ags.cn_inv_dbt AS d
        INNER JOIN ags.cnInvAccnt AS a ON d.cidCnInvAccntCtpt = a.ciaKey
        INNER JOIN ags.cnInvAccntSmpl AS s ON a.ciaCnInvAccntSmpl = s.ciasKey
        INNER JOIN ags.cnInv AS ci ON s.ciasCnInv = ci.ciKey
        WHERE ci.ciInv = q.iKey
    ) AS fact_rows
FROM (
    SELECT 336 AS iKey, N'split' AS klass
    UNION ALL SELECT 4786, N'split'
    UNION ALL SELECT 6766, N'split'
    UNION ALL SELECT 6770, N'split'
    UNION ALL SELECT 6776, N'split'
    UNION ALL SELECT 6798, N'split'
    UNION ALL SELECT 6801, N'split'
    UNION ALL SELECT 6812, N'split'
    UNION ALL SELECT 6814, N'split'
    UNION ALL SELECT 4480, N'quarter'
) AS q
ORDER BY q.iKey;
