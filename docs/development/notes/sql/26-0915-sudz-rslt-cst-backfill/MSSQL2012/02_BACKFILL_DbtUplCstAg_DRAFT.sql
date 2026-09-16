/*
 * 02 — DRAFT backfill: INSERT в sudz.DbtUplCstAg из однозначных кандидатов (см. 01).
 * lastUpdated: 2026-09-15
 *
 * ПО УМОЛЧАНИЮ: BEGIN TRAN … ROLLBACK.
 * После ревью 00+01 на проде: заменить ROLLBACK на COMMIT (и снять RAISERROR-стоп при желании).
 *
 * Не пишет multi / conflict / empty. Не трогает cnInvCmmCst (годовые «Код стройки» — отдельно).
 */
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

DECLARE @UplQiv int = 901;
DECLARE @UplQi  int = 902;
DECLARE @DoCommit bit = 0;  /* 0 = ROLLBACK, 1 = COMMIT */

IF OBJECT_ID(N'sudz.DbtUplCstAg') IS NULL
BEGIN
    RAISERROR(N'sudz.DbtUplCstAg нет — сначала DDL cutover / seed таблицы.', 16, 1);
    RETURN;
END;

IF OBJECT_ID(N'tempdb..#uplMap') IS NOT NULL DROP TABLE #uplMap;
IF OBJECT_ID(N'tempdb..#ins') IS NOT NULL DROP TABLE #ins;

SELECT
    f.upl_key AS femsqUpl,
    f.uplStatusOnDate AS statusOn,
    a.upl_key AS agsUpl
INTO #uplMap
FROM sudz.cn_inv_dbt_upl f
JOIN ags.cn_inv_dbt_upl a ON a.uplStatusOnDate = f.uplStatusOnDate
WHERE f.upl_key IN (@UplQiv, @UplQi);

IF NOT EXISTS (SELECT 1 FROM #uplMap)
BEGIN
    RAISERROR(N'Нет map femsq→ags upl по statusOn — INSERT отменён.', 16, 1);
    RETURN;
END;

;WITH raw AS (
    SELECT
        idd.iddDbt AS dbtKey,
        dv.dvUpl AS femsqUpl,
        f.cnipCstAgPn AS cstapKey,
        f.countCstAgPn AS cntCst
    FROM sudz.DbtValue dv
    JOIN sudz.invDbtDbt idd ON idd.iddInvDbt = dv.dvInvDbt
    JOIN sudz.invDbtCia c ON c.idcInvDbt = dv.dvInvDbt
    JOIN #uplMap m ON m.femsqUpl = dv.dvUpl
    OUTER APPLY ags.fnCiasDbtUplCst(c.idcCia, m.agsUpl) f
    WHERE dv.dvUpl IN (@UplQiv, @UplQi)
      AND idd.iddDbt IS NOT NULL
      AND f.cnipCstAgPn IS NOT NULL
      AND f.countCstAgPn = 1
),
uniq AS (
    SELECT DISTINCT dbtKey, femsqUpl, cstapKey FROM raw
),
ok AS (
    SELECT dbtKey, femsqUpl, MIN(cstapKey) AS cstapKey
    FROM uniq
    GROUP BY dbtKey, femsqUpl
    HAVING COUNT(DISTINCT cstapKey) = 1
)
SELECT o.dbtKey, o.femsqUpl, o.cstapKey
INTO #ins
FROM ok o
WHERE NOT EXISTS (
    SELECT 1 FROM sudz.DbtUplCstAg d
    WHERE d.ducaDbt = o.dbtKey AND d.ducaUpl = o.femsqUpl
);

PRINT N'=== to insert ===';
SELECT femsqUpl, COUNT(*) AS n FROM #ins GROUP BY femsqUpl ORDER BY femsqUpl;
SELECT TOP 40 * FROM #ins ORDER BY femsqUpl, dbtKey;

BEGIN TRAN;

INSERT INTO sudz.DbtUplCstAg (ducaDbt, ducaUpl, ducaCstAgPn)
SELECT dbtKey, femsqUpl, cstapKey
FROM #ins;

PRINT N'inserted rows = ' + CONVERT(varchar(20), @@ROWCOUNT);

IF @DoCommit = 1
BEGIN
    COMMIT TRAN;
    PRINT N'COMMITTED';
END
ELSE
BEGIN
    ROLLBACK TRAN;
    PRINT N'ROLLED BACK (set @DoCommit=1 after review to apply)';
END
GO
