/*
 * C2 / D1.1 — выгрузка эталона структуры ИПГ с прода (только чтение).
 * Способ: SSMS → Query → SQLCMD Mode → F5 (без bcp.exe).
 * Прод: SPB-05-NV-SQL1 / FishEye, Windows auth. SQL Server 2012.
 * lastUpdated: 2026-11-20
 * Задача 0081 / план chat-plan-26-1120-c2-d11-ipg-plans.md §2.0d
 *
 * ПЕРЕД ЗАПУСКОМ:
 *   1) Создайте каталог OUTDIR (путь БЕЗ кириллицы), по умолчанию ниже.
 *   2) SSMS: Query → SQLCMD Mode (галочка).
 *   3) При необходимости поправьте :setvar OUTDIR.
 *   4) Выполните весь скрипт (F5). Сообщения — в Messages; данные — в .tsv.
 *   5) В конце снова :OUT stdout — сетка Messages покажет DONE.
 *
 * Файлы пишутся на машину, где открыт SSMS (клиент), не на SQL Server.
 */
:setvar OUTDIR "C:\Temp\femsq_ipg_st_etalon_20261120"

SET NOCOUNT ON;
GO

PRINT N'=== EXPORT etalon → $(OUTDIR) ===';
PRINT N'Server=' + CAST(@@SERVERNAME AS nvarchar(128)) + N' DB=' + CAST(DB_NAME() AS nvarchar(128));
GO

:OUT $(OUTDIR)\stType.tsv
SELECT * FROM ags.stType ORDER BY 1;
GO

:OUT $(OUTDIR)\st.tsv
SELECT * FROM ags.st ORDER BY 1;
GO

:OUT $(OUTDIR)\stIpg.tsv
SELECT * FROM ags.stIpg ORDER BY 1;
GO

:OUT $(OUTDIR)\stIpgNm.tsv
SELECT * FROM ags.stIpgNm ORDER BY 1;
GO

:OUT $(OUTDIR)\stCost.tsv
SELECT * FROM ags.stCost ORDER BY 1;
GO

:OUT $(OUTDIR)\stCostNm.tsv
SELECT * FROM ags.stCostNm ORDER BY 1;
GO

:OUT $(OUTDIR)\stRel.tsv
SELECT * FROM ags.stRel ORDER BY 1;
GO

:OUT $(OUTDIR)\stNet.tsv
SELECT * FROM ags.stNet ORDER BY 1;
GO

:OUT $(OUTDIR)\stNetPn.tsv
SELECT * FROM ags.stNetPn ORDER BY 1;
GO

:OUT $(OUTDIR)\ipg.tsv
SELECT * FROM ags.ipg ORDER BY 1;
GO

:OUT $(OUTDIR)\ipgCh.tsv
SELECT * FROM ags.ipgCh ORDER BY 1;
GO

:OUT $(OUTDIR)\ipgPn.tsv
SELECT * FROM ags.ipgPn ORDER BY 1;
GO

:OUT $(OUTDIR)\ipgStPn.tsv
SELECT * FROM ags.ipgStPn ORDER BY 1;
GO

:OUT $(OUTDIR)\ipgSh.tsv
SELECT * FROM ags.ipgSh ORDER BY 1;
GO

/* Опционально: после трека A. Если ошибка — :ON ERROR ignore, файл может быть пустым/частичным. */
:ON ERROR ignore
:OUT $(OUTDIR)\stIpgOutLimPn_2606.tsv
SELECT * FROM ags.stIpgOutLimPn_2606 ORDER BY 1;
GO
:ON ERROR exit

:OUT stdout
PRINT N'=== DONE ===';
PRINT N'Проверьте каталог $(OUTDIR): ожидаются 14 .tsv (+ stIpgOutLimPn_2606.tsv при успехе).';
PRINT N'Упакуйте *.tsv в AES-zip → отПрод сессии 26-1120_14-45.';
GO
