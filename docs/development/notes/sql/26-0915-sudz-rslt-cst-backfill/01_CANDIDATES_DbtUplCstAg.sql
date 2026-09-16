/*
 * 01 — READ ONLY: кандидаты бэкфилла sudz.DbtUplCstAg для QIV/QI.
 * lastUpdated: 2026-09-15
 *
 * Строит (dbtKey, femsqUpl, agsUpl, cstapKey) через:
 *   DbtValue@upl → slot → invDbtDbt → dbtKey
 *               → invDbtCia → cias
 *               → ags.fnCiasDbtUplCst(cias, agsUpl)
 * где agsUpl сопоставлен с femsqUpl по uplStatusOnDate.
 *
 * В INSERT идут только строки с однозначным cnipCstAgPn (countCstAgPn=1).
 * Multi / empty / conflict → отдельные SELECT для разбора.
 *
 * Требует: схему FEMSQ (DbtValue, invDbtCia, invDbtDbt, cn_inv_dbt_upl),
 *          ags.fnCiasDbtUplCst, ags.cn_inv_dbt_upl (+ g_p на проде для fn).
 */
SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

DECLARE @UplQiv int = 901;
DECLARE @UplQi  int = 902;

IF OBJECT_ID(N'sudz.DbtValue') IS NULL
   OR OBJECT_ID(N'sudz.invDbtCia') IS NULL
   OR OBJECT_ID(N'sudz.invDbtDbt') IS NULL
   OR OBJECT_ID(N'ags.fnCiasDbtUplCst') IS NULL
BEGIN
    RAISERROR(N'Нет нужных объектов (sudz.* / ags.fnCiasDbtUplCst). Сверьте схему cutover.', 16, 1);
    RETURN;
END;

IF OBJECT_ID(N'tempdb..#uplMap') IS NOT NULL DROP TABLE #uplMap;
IF OBJECT_ID(N'tempdb..#raw') IS NOT NULL DROP TABLE #raw;
IF OBJECT_ID(N'tempdb..#cand') IS NOT NULL DROP TABLE #cand;

/* FEMSQ upl → ags upl (один statusOn может дать несколько ags upl — берём все, потом выберем) */
SELECT
    f.upl_key AS femsqUpl,
    f.uplStatusOnDate AS statusOn,
    a.upl_key AS agsUpl
INTO #uplMap
FROM sudz.cn_inv_dbt_upl f
JOIN ags.cn_inv_dbt_upl a ON a.uplStatusOnDate = f.uplStatusOnDate
WHERE f.upl_key IN (@UplQiv, @UplQi);

PRINT N'=== map femsq→ags ===';
SELECT * FROM #uplMap ORDER BY femsqUpl, agsUpl;

IF NOT EXISTS (SELECT 1 FROM #uplMap)
BEGIN
    RAISERROR(N'Нет ags.cn_inv_dbt_upl с тем же uplStatusOnDate, что у QIV/QI. На DEV так и есть; на проде — проверить каталог upl/g_p.', 16, 1);
    RETURN;
END;

/* Сырьё: каждая (dbt, femsqUpl, cias, agsUpl) + результат fn */
SELECT
    idd.iddDbt AS dbtKey,
    dv.dvUpl AS femsqUpl,
    m.agsUpl,
    c.idcCia AS ciasKey,
    f.countCstAgPn AS cntCst,
    f.cnipCstAgPn AS cstapKey,
    CONVERT(nvarchar(200), f.cstAgPn) AS cstCodeOrStub,
    CONVERT(nvarchar(400), f.cstName) AS cstName,
    CONVERT(nvarchar(400), f.ogNm) AS agOrg
INTO #raw
FROM sudz.DbtValue dv
JOIN sudz.invDbtDbt idd ON idd.iddInvDbt = dv.dvInvDbt
JOIN sudz.invDbtCia c ON c.idcInvDbt = dv.dvInvDbt
JOIN #uplMap m ON m.femsqUpl = dv.dvUpl
OUTER APPLY ags.fnCiasDbtUplCst(c.idcCia, m.agsUpl) f
WHERE dv.dvUpl IN (@UplQiv, @UplQi)
  AND idd.iddDbt IS NOT NULL;

PRINT N'=== raw counts ===';
SELECT
    femsqUpl,
    COUNT(*) AS rawRows,
    COUNT(DISTINCT dbtKey) AS distinctDbt,
    SUM(CASE WHEN cstapKey IS NOT NULL AND cntCst = 1 THEN 1 ELSE 0 END) AS uniqHits,
    SUM(CASE WHEN cntCst > 1 THEN 1 ELSE 0 END) AS multiHits,
    SUM(CASE WHEN cstapKey IS NULL THEN 1 ELSE 0 END) AS emptyHits
FROM #raw
GROUP BY femsqUpl
ORDER BY femsqUpl;

/*
 * Кандидат на (dbtKey, femsqUpl): если среди uniqHits ровно один distinct cstapKey — берём его.
 * Иначе conflict / empty.
 */
;WITH uniq AS (
    SELECT DISTINCT dbtKey, femsqUpl, agsUpl, cstapKey, cstCodeOrStub, cstName, agOrg
    FROM #raw
    WHERE cstapKey IS NOT NULL AND cntCst = 1
),
agg AS (
    SELECT
        dbtKey,
        femsqUpl,
        COUNT(DISTINCT cstapKey) AS nCst,
        MIN(cstapKey) AS cstapKey,
        MIN(agsUpl) AS agsUplSample,
        MIN(cstCodeOrStub) AS cstCode,
        MIN(cstName) AS cstName
    FROM uniq
    GROUP BY dbtKey, femsqUpl
)
SELECT
    a.dbtKey,
    a.femsqUpl,
    a.agsUplSample AS agsUpl,
    a.cstapKey,
    a.cstCode,
    a.cstName,
    CASE
        WHEN a.nCst = 1 THEN N'OK'
        WHEN a.nCst > 1 THEN N'CONFLICT_MULTI_CST'
        ELSE N'EMPTY'
    END AS verdict
INTO #cand
FROM agg a;

/* Долги с Value@upl, но без OK-кандидата */
INSERT INTO #cand (dbtKey, femsqUpl, agsUpl, cstapKey, cstCode, cstName, verdict)
SELECT DISTINCT
    idd.iddDbt,
    dv.dvUpl,
    NULL, NULL, NULL, NULL,
    N'MISSING'
FROM sudz.DbtValue dv
JOIN sudz.invDbtDbt idd ON idd.iddInvDbt = dv.dvInvDbt
WHERE dv.dvUpl IN (@UplQiv, @UplQi)
  AND idd.iddDbt IS NOT NULL
  AND NOT EXISTS (
        SELECT 1 FROM #cand c
        WHERE c.dbtKey = idd.iddDbt AND c.femsqUpl = dv.dvUpl AND c.verdict = N'OK'
  )
  AND NOT EXISTS (
        SELECT 1 FROM #cand c
        WHERE c.dbtKey = idd.iddDbt AND c.femsqUpl = dv.dvUpl
  );

PRINT N'=== candidates summary ===';
SELECT femsqUpl, verdict, COUNT(*) AS n
FROM #cand
GROUP BY femsqUpl, verdict
ORDER BY femsqUpl, verdict;

PRINT N'=== OK sample (TOP 30) ===';
SELECT TOP 30 *
FROM #cand
WHERE verdict = N'OK'
ORDER BY femsqUpl, dbtKey;

PRINT N'=== CONFLICT sample ===';
SELECT TOP 30 *
FROM #cand
WHERE verdict = N'CONFLICT_MULTI_CST'
ORDER BY femsqUpl, dbtKey;

PRINT N'=== already in DbtUplCstAg (overlap) ===';
IF OBJECT_ID(N'sudz.DbtUplCstAg') IS NOT NULL
BEGIN
    SELECT c.femsqUpl, COUNT(*) AS okN,
           SUM(CASE WHEN d.ducaKey IS NOT NULL THEN 1 ELSE 0 END) AS alreadyPresent
    FROM #cand c
    LEFT JOIN sudz.DbtUplCstAg d
      ON d.ducaDbt = c.dbtKey AND d.ducaUpl = c.femsqUpl
    WHERE c.verdict = N'OK'
    GROUP BY c.femsqUpl;
END;

/*
 * Полный список OK для выгрузки в Excel / ревью перед 02:
 * SELECT * FROM #cand WHERE verdict = N'OK' ORDER BY femsqUpl, dbtKey;
 */
GO
