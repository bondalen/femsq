/*
 * C2 / D1.1 — список колонок таблиц эталона (только чтение).
 * Нужен, чтобы на DEV однозначно разобрать .tsv без заголовков BCP -c.
 * Прод: SSMS, FishEye, Windows auth. SQL Server 2012.
 * lastUpdated: 2026-11-20
 */
SET NOCOUNT ON;

SELECT
    N'columns' AS section,
    s.name AS schema_name,
    t.name AS table_name,
    c.column_id,
    c.name AS column_name,
    ty.name AS type_name,
    c.max_length,
    c.precision,
    c.scale,
    c.is_nullable
FROM sys.tables AS t
INNER JOIN sys.schemas AS s ON s.schema_id = t.schema_id
INNER JOIN sys.columns AS c ON c.object_id = t.object_id
INNER JOIN sys.types AS ty ON ty.user_type_id = c.user_type_id
WHERE s.name = N'ags'
  AND t.name IN (
        N'stType', N'st', N'stIpg', N'stIpgNm',
        N'stCost', N'stCostNm', N'stRel', N'stNet', N'stNetPn',
        N'ipg', N'ipgCh', N'ipgPn', N'ipgStPn', N'ipgSh',
        N'stIpgOutLimPn_2606', N'stIpgOutLimPn'
  )
ORDER BY t.name, c.column_id;
