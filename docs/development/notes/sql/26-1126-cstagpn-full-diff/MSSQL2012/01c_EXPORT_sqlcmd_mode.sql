/*
 * C2 §3.5.1 — полный EXPORT cstAgPn + родители с прода.
 * SSMS → Query → SQLCMD Mode → F5. Только чтение. SQL Server 2012.
 * Сессия: 26-1126_09-31 · задача 0081
 * lastUpdated: 2026-11-26
 */
:setvar OUTDIR "C:\Temp\femsq_cstagpn_full_diff_20261126"

SET NOCOUNT ON;
GO

PRINT N'=== EXPORT FULL cstAgPn (+parents) → $(OUTDIR) ===';
PRINT N'Server=' + CAST(@@SERVERNAME AS nvarchar(128)) + N' DB=' + CAST(DB_NAME() AS nvarchar(128));
GO

:OUT $(OUTDIR)\00_counts.tsv
SELECT
    (SELECT COUNT(*) FROM ags.cstAgPn) AS cstAgPn_cnt,
    (SELECT COUNT(*) FROM ags.cstAg) AS cstAg_cnt,
    (SELECT COUNT(*) FROM ags.cst) AS cst_cnt,
    (SELECT COUNT(*) FROM ags.ogAg) AS ogAg_cnt;
GO

:OUT $(OUTDIR)\cstAgPn.tsv
SELECT cstapKey, cstapCsta, cstapIpgPnN, cstapOidOld, cstapCstName, cstapCstName255, cstapOgName
FROM ags.cstAgPn
ORDER BY cstapKey;
GO

:OUT $(OUTDIR)\cstAg.tsv
SELECT cstaKey, cstaAg, cstaCst, cstaOidOld, cstaInvestor
FROM ags.cstAg
ORDER BY cstaKey;
GO

:OUT $(OUTDIR)\cst.tsv
SELECT cstKey, cstName, cstBusSgm, cstOidOld, cstMark
FROM ags.cst
ORDER BY cstKey;
GO

:OUT $(OUTDIR)\ogAg.tsv
SELECT ogaKey, ogaCode, ogaOg, ogaOidOld
FROM ags.ogAg
ORDER BY ogaKey;
GO

:OUT stdout
PRINT N'=== DONE ===';
PRINT N'Файлы: 00_counts.tsv, cstAgPn.tsv, cstAg.tsv, cst.tsv, ogAg.tsv';
GO
