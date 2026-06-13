USE [FishEye];
GO

-- =============================================================================
-- Файл:    07e2_COMPARE_fn2_single_cstAgPn.sql
-- Пакет:   docs/development/notes/sql/26-0604/
-- Назначение: Точечное сравнение fn2_2606 ↔ fn2_2605 по одной стройке (cstAgPnKey).
--   Сужает диагностику: помесячно, по ipgKey, отдельно presented / accepted / lim.
-- Использование: задать @cstAgPnKey (и при необходимости @ipgCh, @months) перед запуском.
-- Автор:   Александр
-- Дата:    2026-06-09
-- =============================================================================

SET NOCOUNT ON;
GO

-- >>> Параметры точечной проверки <<<
DECLARE @ipgCh int = 5;
DECLARE @cstAgPnKey int = 849;          -- пример: 051-2000973
DECLARE @iShKey int = 2;                -- агентская схема
DECLARE @typeGr nvarchar(255) = N'1. ОА и Изм.';
-- NULL = все месяцы; иначе список: '3,9' или '9'
DECLARE @months nvarchar(50) = NULL;

DECLARE @code nvarchar(20) = (
    SELECT cstapIpgPnN FROM ags.cstAgPn WHERE cstapKey = @cstAgPnKey
);

PRINT N'=== 07e2: fn2 compare single cstAgPn ===';
PRINT N'  chain=' + CAST(@ipgCh AS nvarchar(10))
    + N' cstAgPnKey=' + CAST(@cstAgPnKey AS nvarchar(10))
    + N' code=' + ISNULL(@code, N'?');
PRINT N'';

IF OBJECT_ID('tempdb..#months') IS NOT NULL DROP TABLE #months;
CREATE TABLE #months (mNum int NOT NULL PRIMARY KEY);

IF @months IS NULL
    INSERT INTO #months (mNum) SELECT mNum FROM ags.mmmm;
ELSE
BEGIN
    DECLARE @xml xml = N'<r><m>' + REPLACE(@months, ',', '</m><m>') + N'</m></r>';
    INSERT INTO #months (mNum)
    SELECT DISTINCT x.n.value('.', 'int')
    FROM @xml.nodes('/r/m') x(n)
    WHERE x.n.value('.', 'int') BETWEEN 1 AND 12;
END

-- Сводка по месяцам (MAX presented — месячный факт без ipgKey)
PRINT N'--- Monthly summary (MAX presented / accepted / lim) ---';

SELECT
    m.mNum,
    r.pres05,
    n.pres06,
    ABS(ISNULL(r.pres05, 0) - ISNULL(n.pres06, 0)) AS d_pres,
    r.acc05,
    n.acc06,
    ABS(ISNULL(r.acc05, 0) - ISNULL(n.acc06, 0)) AS d_acc,
    r.lim05,
    n.lim06,
    ABS(ISNULL(r.lim05, 0) - ISNULL(n.lim06, 0)) AS d_lim
FROM #months m
OUTER APPLY (
    SELECT MAX(presented) AS pres05, MAX(accepted) AS acc05, MAX(lim) AS lim05
    FROM ags.fnIpgChRsltCstUtl2_2605(@ipgCh, NULL)
    WHERE cstAgPnKey = @cstAgPnKey AND mNum = m.mNum AND iShKey = @iShKey
      AND typeGr = @typeGr AND ipgKey IS NOT NULL
) r
OUTER APPLY (
    SELECT MAX(presented) AS pres06, MAX(accepted) AS acc06, MAX(lim) AS lim06
    FROM ags.fnIpgChRsltCstUtl2_2606(@ipgCh, NULL, NULL)
    WHERE cstAgPnKey = @cstAgPnKey AND mNum = m.mNum AND iShKey = @iShKey
      AND typeGr = @typeGr AND ipgKey IS NOT NULL
) n
ORDER BY m.mNum;

-- Детализация per ipgKey (лимиты, переходы ИПГ)
PRINT N'';
PRINT N'--- Detail per ipgKey (months with any diff > 0.01) ---';

SELECT
    x.mNum,
    x.ipgKey,
    x.pres05,
    x.pres06,
    x.acc05,
    x.acc06,
    x.lim05,
    x.lim06
FROM (
    SELECT
        COALESCE(a.mNum, b.mNum) AS mNum,
        COALESCE(a.ipgKey, b.ipgKey) AS ipgKey,
        a.presented AS pres05,
        b.presented AS pres06,
        a.accepted AS acc05,
        b.accepted AS acc06,
        a.lim AS lim05,
        b.lim AS lim06
    FROM (
        SELECT mNum, ipgKey, presented, accepted, lim
        FROM ags.fnIpgChRsltCstUtl2_2605(@ipgCh, NULL)
        WHERE cstAgPnKey = @cstAgPnKey AND iShKey = @iShKey AND typeGr = @typeGr AND ipgKey IS NOT NULL
    ) a
    FULL OUTER JOIN (
        SELECT mNum, ipgKey, presented, accepted, lim
        FROM ags.fnIpgChRsltCstUtl2_2606(@ipgCh, NULL, NULL)
        WHERE cstAgPnKey = @cstAgPnKey AND iShKey = @iShKey AND typeGr = @typeGr AND ipgKey IS NOT NULL
    ) b ON a.mNum = b.mNum AND a.ipgKey = b.ipgKey
    INNER JOIN #months fm ON fm.mNum = COALESCE(a.mNum, b.mNum)
) x
WHERE ABS(ISNULL(x.pres05, 0) - ISNULL(x.pres06, 0)) > 0.01
   OR ABS(ISNULL(x.acc05, 0) - ISNULL(x.acc06, 0)) > 0.01
   OR ABS(ISNULL(x.lim05, 0) - ISNULL(x.lim06, 0)) > 0.01
ORDER BY x.mNum, x.ipgKey;

DECLARE @presDiff int = (
    SELECT COUNT(*)
    FROM #months m
    WHERE ABS(
        ISNULL((
            SELECT MAX(presented) FROM ags.fnIpgChRsltCstUtl2_2605(@ipgCh, NULL)
            WHERE cstAgPnKey = @cstAgPnKey AND mNum = m.mNum AND iShKey = @iShKey
              AND typeGr = @typeGr AND ipgKey IS NOT NULL
        ), 0)
        - ISNULL((
            SELECT MAX(presented) FROM ags.fnIpgChRsltCstUtl2_2606(@ipgCh, NULL, NULL)
            WHERE cstAgPnKey = @cstAgPnKey AND mNum = m.mNum AND iShKey = @iShKey
              AND typeGr = @typeGr AND ipgKey IS NOT NULL
        ), 0)
    ) > 0.01
);

PRINT N'';
PRINT N'Months with presented diff > 0.01: ' + CAST(@presDiff AS nvarchar(10));
IF @presDiff = 0
    PRINT N'=== 07e2: PASS (presented) ===';
ELSE
    PRINT N'=== 07e2: FAIL (presented) — см. таблицы выше ===';
GO
