/*
 * R1.0 DEV-гейт: полный инвентарь схемы sudz (если есть). Только чтение.
 * Прод SSMS / FishEye. lastUpdated: 2026-11-19
 */
SET NOCOUNT ON;

SELECT
    N'schema' AS section,
    CASE WHEN EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'sudz')
         THEN N'EXISTS' ELSE N'ABSENT' END AS sudz_schema;

SELECT
    N'sudz-object' AS section,
    o.type_desc,
    o.name AS object_name
FROM sys.objects AS o
INNER JOIN sys.schemas AS s ON s.schema_id = o.schema_id
WHERE s.name = N'sudz'
  AND o.is_ms_shipped = 0
ORDER BY o.type_desc, o.name;

SELECT
    N'sudz-counts-by-type' AS section,
    o.type_desc,
    COUNT(*) AS cnt
FROM sys.objects AS o
INNER JOIN sys.schemas AS s ON s.schema_id = o.schema_id
WHERE s.name = N'sudz'
  AND o.is_ms_shipped = 0
GROUP BY o.type_desc
ORDER BY o.type_desc;
