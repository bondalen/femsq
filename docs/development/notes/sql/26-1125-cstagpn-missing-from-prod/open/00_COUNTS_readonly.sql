/*
 * C2 / O1 — сверка 92 кодов САК (дыры load8/sql_0 на noM6) на ПРОДЕ.
 * Только чтение. SQL Server 2012 SP4 / FishEye / Windows auth.
 * Сессия продОбмен: 26-1125_09-50
 * Задача 0081 · план §3.2.4 prep (G5)
 * lastUpdated: 2026-11-25
 */
SET NOCOUNT ON;

PRINT N'=== 00 identity ===';
SELECT
    CAST(@@SERVERNAME AS nvarchar(128)) AS server_name,
    CAST(DB_NAME() AS nvarchar(128)) AS db_name,
    CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(128)) AS product_version,
    CAST(SERVERPROPERTY('ProductLevel') AS nvarchar(128)) AS product_level;

PRINT N'=== 00 objects ===';
SELECT o.name, o.type_desc
FROM sys.objects o
JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE s.name = N'ags'
  AND o.name IN (N'cstAgPn', N'cstAg', N'cst', N'ogAg')
ORDER BY o.name;

IF OBJECT_ID(N'tempdb..#need') IS NOT NULL DROP TABLE #need;
CREATE TABLE #need (code nvarchar(255) COLLATE DATABASE_DEFAULT NOT NULL PRIMARY KEY);
INSERT INTO #need (code) VALUES
    (N'001-3000010'),
    (N'019-3000737'),
    (N'019-3004873'),
    (N'022-3000796'),
    (N'022-3006560'),
    (N'023-3000860'),
    (N'023-3006280'),
    (N'026-3005711'),
    (N'026-3005712'),
    (N'026-3007242'),
    (N'039-3001202'),
    (N'039-3001209'),
    (N'039-3004010'),
    (N'039-3005366'),
    (N'040-2005400'),
    (N'051-2001690'),
    (N'051-2003126'),
    (N'051-2005160'),
    (N'051-2005274'),
    (N'051-2005996'),
    (N'051-2006006'),
    (N'051-2006007'),
    (N'051-2006032'),
    (N'051-2006045'),
    (N'051-2006055'),
    (N'051-2006065'),
    (N'051-2006079'),
    (N'051-2006091'),
    (N'051-2006107'),
    (N'051-2006108'),
    (N'051-2006110'),
    (N'051-2006111'),
    (N'051-2006114'),
    (N'051-2006115'),
    (N'051-2006116'),
    (N'051-2006117'),
    (N'051-2006118'),
    (N'051-2006119'),
    (N'051-2006121'),
    (N'051-2006126'),
    (N'051-2006127'),
    (N'051-2006130'),
    (N'051-2006144'),
    (N'051-2006145'),
    (N'051-2006150'),
    (N'051-2006154'),
    (N'051-2006296'),
    (N'051-2006297'),
    (N'051-2006298'),
    (N'051-2006453'),
    (N'051-2006660'),
    (N'051-2006661'),
    (N'051-2006662'),
    (N'051-2006664'),
    (N'051-2006665'),
    (N'051-2006669'),
    (N'051-2006670'),
    (N'051-2006672'),
    (N'051-2006673'),
    (N'051-2006675'),
    (N'051-2006676'),
    (N'051-2006677'),
    (N'051-2006678'),
    (N'051-2006680'),
    (N'051-2006681'),
    (N'051-2006682'),
    (N'051-2006687'),
    (N'051-2006688'),
    (N'051-2006689'),
    (N'051-2006690'),
    (N'051-2006691'),
    (N'051-2006696'),
    (N'051-2006698'),
    (N'051-2006699'),
    (N'051-2006702'),
    (N'051-2006704'),
    (N'051-2006705'),
    (N'051-2006706'),
    (N'051-2006708'),
    (N'051-2006709'),
    (N'051-2006723'),
    (N'051-2006724'),
    (N'051-2006729'),
    (N'051-2006732'),
    (N'051-2007114'),
    (N'051-2007373'),
    (N'057-3000721'),
    (N'057-3001311'),
    (N'057-3002160'),
    (N'057-3002172'),
    (N'057-3002542'),
    (N'057-3002855');

PRINT N'=== 00 need vs prod cstAgPn ===';
SELECT
    (SELECT COUNT(*) FROM #need) AS need_cnt,
    (SELECT COUNT(*) FROM #need n
      INNER JOIN ags.cstAgPn p ON p.cstapIpgPnN = n.code COLLATE DATABASE_DEFAULT) AS found_cnt,
    (SELECT COUNT(*) FROM #need n
      WHERE NOT EXISTS (
        SELECT 1 FROM ags.cstAgPn p WHERE p.cstapIpgPnN = n.code COLLATE DATABASE_DEFAULT)) AS missing_on_prod_cnt;

PRINT N'=== 00 codes missing on prod (ожидаем 0) ===';
SELECT n.code
FROM #need n
WHERE NOT EXISTS (SELECT 1 FROM ags.cstAgPn p WHERE p.cstapIpgPnN = n.code COLLATE DATABASE_DEFAULT)
ORDER BY n.code;

PRINT N'=== 00 parent coverage (cstAg / cst / ogAg) ===';
SELECT
    COUNT(DISTINCT p.cstapKey) AS pn_rows,
    COUNT(DISTINCT a.cstaKey) AS cstAg_rows,
    COUNT(DISTINCT c.cstKey) AS cst_rows,
    COUNT(DISTINCT g.ogaKey) AS ogAg_rows
FROM #need n
INNER JOIN ags.cstAgPn p ON p.cstapIpgPnN = n.code COLLATE DATABASE_DEFAULT
LEFT JOIN ags.cstAg a ON a.cstaKey = p.cstapCsta
LEFT JOIN ags.cst c ON c.cstKey = a.cstaCst
LEFT JOIN ags.ogAg g ON g.ogaKey = a.cstaAg;

PRINT N'=== 00 DONE ===';
