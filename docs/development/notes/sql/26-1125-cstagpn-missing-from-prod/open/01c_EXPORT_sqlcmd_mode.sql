/*
 * C2 / O1 — выгрузка недостающих cstAgPn (+ родители) с прода.
 * SSMS → Query → SQLCMD Mode → F5. Только чтение. SQL Server 2012.
 * Сессия: 26-1125_09-50 · задача 0081
 * lastUpdated: 2026-11-25
 *
 * ПЕРЕД ЗАПУСКОМ:
 *   1) Каталог OUTDIR без кириллицы (по умолчанию ниже).
 *   2) Query → SQLCMD Mode.
 *   3) F5. В OUTDIR появятся *.tsv
 */
:setvar OUTDIR "C:\Temp\femsq_cstagpn_missing_20261125"

SET NOCOUNT ON;
GO

PRINT N'=== EXPORT missing cstAgPn → $(OUTDIR) ===';
PRINT N'Server=' + CAST(@@SERVERNAME AS nvarchar(128)) + N' DB=' + CAST(DB_NAME() AS nvarchar(128));
GO

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
GO

:OUT $(OUTDIR)\00_match_summary.tsv
SELECT
    (SELECT COUNT(*) FROM #need) AS need_cnt,
    (SELECT COUNT(*) FROM #need n INNER JOIN ags.cstAgPn p ON p.cstapIpgPnN = n.code COLLATE DATABASE_DEFAULT) AS found_cnt,
    (SELECT COUNT(*) FROM #need n WHERE NOT EXISTS (SELECT 1 FROM ags.cstAgPn p WHERE p.cstapIpgPnN = n.code COLLATE DATABASE_DEFAULT)) AS missing_on_prod_cnt;
GO

:OUT $(OUTDIR)\cstAgPn.tsv
SELECT p.*
FROM ags.cstAgPn p
INNER JOIN #need n ON n.code COLLATE DATABASE_DEFAULT = p.cstapIpgPnN
ORDER BY p.cstapKey;
GO

:OUT $(OUTDIR)\cstAg.tsv
SELECT DISTINCT a.*
FROM ags.cstAg a
INNER JOIN ags.cstAgPn p ON p.cstapCsta = a.cstaKey
INNER JOIN #need n ON n.code COLLATE DATABASE_DEFAULT = p.cstapIpgPnN
ORDER BY a.cstaKey;
GO

:OUT $(OUTDIR)\cst.tsv
SELECT DISTINCT c.*
FROM ags.cst c
INNER JOIN ags.cstAg a ON a.cstaCst = c.cstKey
INNER JOIN ags.cstAgPn p ON p.cstapCsta = a.cstaKey
INNER JOIN #need n ON n.code COLLATE DATABASE_DEFAULT = p.cstapIpgPnN
ORDER BY c.cstKey;
GO

:OUT $(OUTDIR)\ogAg.tsv
SELECT DISTINCT g.*
FROM ags.ogAg g
INNER JOIN ags.cstAg a ON a.cstaAg = g.ogaKey
INNER JOIN ags.cstAgPn p ON p.cstapCsta = a.cstaKey
INNER JOIN #need n ON n.code COLLATE DATABASE_DEFAULT = p.cstapIpgPnN
ORDER BY g.ogaKey;
GO

:OUT $(OUTDIR)\codes_not_on_prod.tsv
SELECT n.code
FROM #need n
WHERE NOT EXISTS (SELECT 1 FROM ags.cstAgPn p WHERE p.cstapIpgPnN = n.code COLLATE DATABASE_DEFAULT)
ORDER BY n.code;
GO

:OUT stdout
PRINT N'=== DONE ===';
PRINT N'Ожидаемые файлы: 00_match_summary.tsv, cstAgPn.tsv, cstAg.tsv, cst.tsv, ogAg.tsv, codes_not_on_prod.tsv';
GO
