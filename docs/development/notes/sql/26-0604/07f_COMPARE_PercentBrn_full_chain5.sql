USE [FishEye];
GO

-- =============================================================================
-- Файл:    07f_COMPARE_PercentBrn_full_chain5.sql
-- Пакет:   docs/development/notes/sql/26-0604/
-- Назначение: Полное сравнение PercentBrn_2606 ↔ _2605 (будущий RS1, цепь 5).
--   Материализация ~14 447 строк; ключевые поля ag_* на всех dateRslt 2022.
--   Опционально: @cstAgPnKey — сузить к одной стройке (быстрая отладка).
-- Предусловия: 05 (PercentBrn_2606), fnIpgChRsltCstUtlPercentBrn_2605.
-- Ожидаемое время: 30–60 мин (полный набор); ~2–5 мин при @cstAgPnKey.
-- Автор:   Александр
-- Дата:    2026-06-09 | Обновлено: 2026-06-11 (F.3: дедуп ключей GROUPING SETS)
-- =============================================================================

SET NOCOUNT ON;
GO

DECLARE @ipgCh int = 5;
DECLARE @cstAgPnKey int = NULL;  -- напр. 849 для точечной проверки
DECLARE @fail int = 0;

PRINT N'=== 07f: FULL PercentBrn compare chain 5 ===';
IF @cstAgPnKey IS NOT NULL
    PRINT N'  filter cstAgPnKey=' + CAST(@cstAgPnKey AS nvarchar(10));
PRINT N'  (materialization may take 30–60 min for full set)';
PRINT N'';

IF OBJECT_ID('tempdb..#pb05') IS NOT NULL DROP TABLE #pb05;
IF OBJECT_ID('tempdb..#pb06') IS NOT NULL DROP TABLE #pb06;

DECLARE @t0 datetime2 = SYSDATETIME();
RAISERROR(N'--- materialize PercentBrn_2605 ---', 0, 1) WITH NOWAIT;
SELECT
    dateRslt,
    ipgKey,
    cstapKey,
    cstAgPnCode,
    ag_lim,
    ag_Pl,
    ag_presented,
    ag_accepted,
    ag_percentDev,
    ag_LimPercent
INTO #pb05
FROM ags.fnIpgChRsltCstUtlPercentBrn_2605(@ipgCh, NULL)
WHERE @cstAgPnKey IS NULL OR cstapKey = @cstAgPnKey;

DECLARE @cnt05 int = (SELECT COUNT(*) FROM #pb05);
DECLARE @msg nvarchar(200) = N'  #pb05 rows: ' + CAST(@cnt05 AS nvarchar(10)) + N'  elapsed: ' + CAST(DATEDIFF(ms, @t0, SYSDATETIME()) AS nvarchar(10)) + N' ms';
RAISERROR(@msg, 0, 1) WITH NOWAIT;

SET @t0 = SYSDATETIME();
RAISERROR(N'--- materialize PercentBrn_2606 ---', 0, 1) WITH NOWAIT;
SELECT
    dateRslt,
    ipgKey,
    cstapKey,
    cstAgPnCode,
    ag_lim,
    ag_Pl,
    ag_presented,
    ag_accepted,
    ag_percentDev,
    ag_LimPercent
INTO #pb06
FROM ags.fnIpgChRsltCstUtlPercentBrn_2606(@ipgCh, NULL, NULL)
WHERE @cstAgPnKey IS NULL OR cstapKey = @cstAgPnKey;

DECLARE @cnt06 int = (SELECT COUNT(*) FROM #pb06);
SET @msg = N'  #pb06 rows: ' + CAST(@cnt06 AS nvarchar(10)) + N'  elapsed: ' + CAST(DATEDIFF(ms, @t0, SYSDATETIME()) AS nvarchar(10)) + N' ms';
RAISERROR(@msg, 0, 1) WITH NOWAIT;

-- F.1 COUNT
PRINT N'';
PRINT N'F.1 row counts: _2605=' + CAST(@cnt05 AS nvarchar(10)) + N' _2606=' + CAST(@cnt06 AS nvarchar(10));
IF @cnt05 <> @cnt06
BEGIN
    SET @fail = @fail + 1;
    PRINT N'  FAIL (COUNT mismatch)';
END
ELSE
    PRINT N'  OK';

-- F.2 dateRslt
DECLARE @dt05 int = (SELECT COUNT(DISTINCT dateRslt) FROM #pb05);
DECLARE @dt06 int = (SELECT COUNT(DISTINCT dateRslt) FROM #pb06);
PRINT N'F.2 distinct dateRslt: _2605=' + CAST(@dt05 AS nvarchar(10)) + N' _2606=' + CAST(@dt06 AS nvarchar(10));
IF @dt05 <> @dt06 OR @dt05 = 0
BEGIN
    SET @fail = @fail + 1;
    PRINT N'  FAIL';
END
ELSE
    PRINT N'  OK (expected 16 on full chain 5)';

-- F.3 key field mismatches — по дедуплицированным ключам (GROUPING SETS даёт дубли на агрегатах).
IF OBJECT_ID('tempdb..#da05') IS NOT NULL DROP TABLE #da05;
IF OBJECT_ID('tempdb..#da06') IS NOT NULL DROP TABLE #da06;
SELECT dateRslt, ipgKey, cstapKey,
       MAX(cstAgPnCode) AS cstAgPnCode,
       MAX(ag_lim) AS ag_lim, MAX(ag_Pl) AS ag_Pl,
       MAX(ag_presented) AS ag_presented, MAX(ag_percentDev) AS ag_percentDev
INTO #da05 FROM #pb05 GROUP BY dateRslt, ipgKey, cstapKey;
SELECT dateRslt, ipgKey, cstapKey,
       MAX(cstAgPnCode) AS cstAgPnCode,
       MAX(ag_lim) AS ag_lim, MAX(ag_Pl) AS ag_Pl,
       MAX(ag_presented) AS ag_presented, MAX(ag_percentDev) AS ag_percentDev
INTO #da06 FROM #pb06 GROUP BY dateRslt, ipgKey, cstapKey;

DECLARE @keyDiff int = (
    SELECT COUNT(*)
    FROM #da05 a
    FULL OUTER JOIN #da06 b
        ON a.dateRslt = b.dateRslt
       AND ISNULL(a.ipgKey, -1)    = ISNULL(b.ipgKey, -1)
       AND ISNULL(a.cstapKey, -1)  = ISNULL(b.cstapKey, -1)
    WHERE a.dateRslt IS NULL OR b.dateRslt IS NULL
       OR ABS(ISNULL(a.ag_presented, 0) - ISNULL(b.ag_presented, 0)) > 0.01
       OR ABS(ISNULL(a.ag_lim, 0) - ISNULL(b.ag_lim, 0)) > 0.01
       OR ABS(ISNULL(a.ag_Pl, 0) - ISNULL(b.ag_Pl, 0)) > 0.01
       OR ABS(ISNULL(a.ag_percentDev, 0) - ISNULL(b.ag_percentDev, 0)) > 0.0001
);

PRINT N'F.3 distinct keys with field diff (pres/lim/pl/percentDev): ' + CAST(@keyDiff AS nvarchar(10));
IF @keyDiff > 0
BEGIN
    SET @fail = @fail + 1;
    PRINT N'  TOP 10 diffs:';
    SELECT TOP 10
        COALESCE(a.dateRslt, b.dateRslt) AS dateRslt,
        COALESCE(a.cstAgPnCode, b.cstAgPnCode) AS code,
        COALESCE(a.ipgKey, b.ipgKey) AS ipgKey,
        a.ag_presented AS pres05, b.ag_presented AS pres06,
        a.ag_lim AS lim05, b.ag_lim AS lim06,
        a.ag_percentDev AS pct05, b.ag_percentDev AS pct06
    FROM #da05 a
    FULL OUTER JOIN #da06 b
        ON a.dateRslt = b.dateRslt
       AND ISNULL(a.ipgKey, -1)    = ISNULL(b.ipgKey, -1)
       AND ISNULL(a.cstapKey, -1)  = ISNULL(b.cstapKey, -1)
    WHERE a.dateRslt IS NULL OR b.dateRslt IS NULL
       OR ABS(ISNULL(a.ag_presented, 0) - ISNULL(b.ag_presented, 0)) > 0.01
       OR ABS(ISNULL(a.ag_lim, 0) - ISNULL(b.ag_lim, 0)) > 0.01
       OR ABS(ISNULL(a.ag_Pl, 0) - ISNULL(b.ag_Pl, 0)) > 0.01
       OR ABS(ISNULL(a.ag_percentDev, 0) - ISNULL(b.ag_percentDev, 0)) > 0.0001
    ORDER BY ABS(ISNULL(a.ag_presented, 0) - ISNULL(b.ag_presented, 0)) DESC;
END
ELSE
    PRINT N'  OK';

-- F.4 transition model Sept (ipg 8@21.09 / 11@22.09)
DECLARE @pairCnt int = (
    SELECT COUNT(*)
    FROM #pb05 a
    INNER JOIN #pb05 b
        ON a.cstapKey = b.cstapKey
       AND a.dateRslt = '2022-09-21' AND a.ipgKey = 8
       AND b.dateRslt = '2022-09-22' AND b.ipgKey = 11
    WHERE a.ag_presented IS NOT NULL
);
DECLARE @samePres int = (
    SELECT COUNT(*)
    FROM #pb05 a
    INNER JOIN #pb05 b
        ON a.cstapKey = b.cstapKey
       AND a.dateRslt = '2022-09-21' AND a.ipgKey = 8
       AND b.dateRslt = '2022-09-22' AND b.ipgKey = 11
    INNER JOIN #pb06 c ON c.cstapKey = a.cstapKey AND c.dateRslt = a.dateRslt AND c.ipgKey = a.ipgKey
    INNER JOIN #pb06 d ON d.cstapKey = b.cstapKey AND d.dateRslt = b.dateRslt AND d.ipgKey = b.ipgKey
    WHERE ISNULL(a.ag_presented, 0) = ISNULL(b.ag_presented, 0)
      AND ISNULL(c.ag_presented, 0) = ISNULL(a.ag_presented, 0)
      AND ISNULL(d.ag_presented, 0) = ISNULL(b.ag_presented, 0)
      AND ISNULL(c.ag_lim, -1) = ISNULL(a.ag_lim, -1)
      AND ISNULL(d.ag_lim, -1) = ISNULL(b.ag_lim, -1)
);
PRINT N'F.4 transition pairs 21/22.09 with equal pres (05+06): '
    + CAST(@samePres AS nvarchar(10)) + N' / ' + CAST(@pairCnt AS nvarchar(10));

-- F.5 spot cstAgPnKey=849 @ 2022-09-30 if in scope
IF @cstAgPnKey IS NULL OR @cstAgPnKey = 849
BEGIN
    PRINT N'F.5 spot cstAgPnKey=849 @2022-09-30:';
    SELECT a.dateRslt, a.ipgKey, a.ag_presented AS pres05, b.ag_presented AS pres06,
        a.ag_lim AS lim05, b.ag_lim AS lim06, a.ag_percentDev AS pct05, b.ag_percentDev AS pct06
    FROM #pb05 a
    LEFT JOIN #pb06 b
        ON a.dateRslt = b.dateRslt AND a.ipgKey = b.ipgKey AND a.cstapKey = b.cstapKey
    WHERE a.cstapKey = 849 AND a.dateRslt = '2022-09-30'
    ORDER BY a.ipgKey;
END

PRINT N'';
IF @fail = 0
    PRINT N'=== 07f: PASS ===';
ELSE
    PRINT N'=== 07f: FAIL (' + CAST(@fail AS nvarchar(10)) + N' check(s)) ===';
GO
