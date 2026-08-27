/*
 * B1 DRAFT — VERIFY after M2 DDL (SELECT only)
 *
 * НЕ ПРИМЕНЯТЬ как DDL. Запускать после 01–04 при apply B1.
 * lastUpdated: 2026-08-26
 */

SET NOCOUNT ON;

PRINT N'=== columns (expect dvInvDbt, no dvDbt) ===';
SELECT SCHEMA_NAME(t.schema_id) AS sch,
       c.name AS column_name
FROM sys.tables t
JOIN sys.columns c ON c.object_id = t.object_id
WHERE t.name = N'DbtValue'
  AND SCHEMA_NAME(t.schema_id) IN (N'sudz', N'test_sudz')
  AND c.name IN (N'dvDbt', N'dvInvDbt', N'dvInvDbtVar', N'dvUpl')
ORDER BY sch, c.column_id;

PRINT N'=== UNIQUE UX_DbtValue_InvDbtUpl ===';
SELECT SCHEMA_NAME(t.schema_id) AS sch, i.name
FROM sys.indexes i
JOIN sys.tables t ON t.object_id = i.object_id
WHERE t.name = N'DbtValue'
  AND i.name = N'UX_DbtValue_InvDbtUpl';

PRINT N'=== triggers ===';
SELECT SCHEMA_NAME(o.schema_id) AS sch, tr.name
FROM sys.triggers tr
JOIN sys.objects o ON o.object_id = tr.parent_id
WHERE tr.name = N'trg_DbtValue_Consistency';

PRINT N'=== fact row counts ===';
SELECT N'sudz' AS sch, COUNT(*) AS fact_n FROM sudz.vw_Yr_DbtFact
UNION ALL
SELECT N'test_sudz', COUNT(*) FROM test_sudz.vw_Yr_DbtFact;

PRINT N'=== sample fact (sudz) ===';
SELECT TOP 5 yr_key, dbtKey, dvInvDbt, upl_key, dvTtl
FROM sudz.vw_Yr_DbtFact
ORDER BY yr_key, dbtKey, upl_key;
GO
