/*
 * C2 / O1 — выгрузка недостающих cstAgPn (+ родители) с прода для B–D.
 * SSMS → Query → SQLCMD Mode → F5. Только чтение. SQL Server 2012.
 * Сессия: 26-1125_11-32 · задача 0081
 * lastUpdated: 2026-11-25
 */
:setvar OUTDIR "C:\Temp\femsq_cstagpn_missing_bcd_20261125"

SET NOCOUNT ON;
GO

PRINT N'=== EXPORT missing cstAgPn BCD → $(OUTDIR) ===';
PRINT N'Server=' + CAST(@@SERVERNAME AS nvarchar(128)) + N' DB=' + CAST(DB_NAME() AS nvarchar(128));
GO

IF OBJECT_ID(N'tempdb..#need') IS NOT NULL DROP TABLE #need;
CREATE TABLE #need (code nvarchar(255) COLLATE DATABASE_DEFAULT NOT NULL PRIMARY KEY);
INSERT INTO #need (code) VALUES
    (N'014-2006402'),
    (N'014-2007247'),
    (N'014-2007248'),
    (N'014-2007249'),
    (N'014-2007250'),
    (N'014-2007541'),
    (N'015-3000707'),
    (N'019-3000738'),
    (N'019-3004870'),
    (N'019-3004875'),
    (N'022-3004874'),
    (N'036-3001026'),
    (N'039-3001233'),
    (N'039-3001236'),
    (N'040-2004798'),
    (N'040-2007403'),
    (N'040-2007412'),
    (N'040-2007434'),
    (N'040-2007480'),
    (N'040-2007498'),
    (N'040-2007509'),
    (N'040-2007530'),
    (N'051-2000866'),
    (N'051-2000883'),
    (N'051-2000986'),
    (N'051-2001355'),
    (N'051-2001510'),
    (N'051-2002402'),
    (N'051-2003216'),
    (N'051-2004003'),
    (N'051-2005761'),
    (N'051-2005977'),
    (N'051-2006008'),
    (N'051-2006039'),
    (N'051-2006042'),
    (N'051-2006155'),
    (N'051-2006439'),
    (N'051-2006521'),
    (N'051-2007251'),
    (N'051-2007329'),
    (N'051-2007330'),
    (N'051-2007375'),
    (N'051-2007377'),
    (N'051-2007378'),
    (N'051-2007379'),
    (N'051-2007380'),
    (N'051-2007381'),
    (N'051-2007382'),
    (N'051-2007387'),
    (N'051-2007392'),
    (N'051-2007535'),
    (N'057-3001505'),
    (N'801-2003500'),
    (N'801-2003501'),
    (N'801-2003544'),
    (N'801-2005028'),
    (N'801-2005037'),
    (N'801-2005248'),
    (N'801-2005287'),
    (N'801-2005742'),
    (N'801-2005769'),
    (N'801-2006016'),
    (N'801-2006286'),
    (N'801-2007507'),
    (N'901-2006420'),
    (N'901-2006425'),
    (N'901-2006744'),
    (N'901-2007411'),
    (N'901-2007459'),
    (N'901-2007505'),
    (N'901-2007506'),
    (N'905-2005258'),
    (N'СИНЕРГИЯ-2005291');
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
