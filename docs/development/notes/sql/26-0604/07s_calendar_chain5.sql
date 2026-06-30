USE [FishEye];
GO

-- =============================================================================
-- Файл:    07s_calendar_chain5.sql
-- Пакет:   docs/development/notes/sql/26-0604/
-- Назначение: Gate **calendar** (Решение 17, этап 20.3) — RS1 / PercentBrn
--   соответствуют контракту графика Java: 17 дат fnIpgChDats_2606, начальная точка
--   01.01 (plan=0), spot golden cstAgPn=2102 / stIpg=42: 68 строк (=17×4).
-- Предусловия: 02 (fnIpgChDats_2606), 05a (PercentBrn @dt), 06, 10a–10d.
-- Автор:   Александр
-- Дата:    2026-06-30
-- =============================================================================

SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
GO

RAISERROR(N'=== 07s: RS1 calendar gate chain 5 (cst 2102, этап 20.3) ===', 0, 1) WITH NOWAIT;

DECLARE @ipgCh       int  = 5;
DECLARE @stIpg       int  = 42;
DECLARE @cstAgPn     int  = 2102;
DECLARE @dt          date = '2022-12-31';
DECLARE @jan1        date = '2022-01-01';
DECLARE @refresh     bit  = 1;   -- 1: EXEC spMstrg_2606 → ResultSet1 (~25 с)
DECLARE @fail        int  = 0;
DECLARE @warn        int  = 0;
DECLARE @msg         nvarchar(500);
DECLARE @t0          datetime2;
DECLARE @ms          int;

DECLARE @datsV       int;
DECLARE @calMissRs1  int;
DECLARE @calExtraRs1 int;
DECLARE @calMiss2102 int;
DECLARE @cntPb       int;
DECLARE @cntRs1      int;
DECLARE @cntDetail   int;
DECLARE @cntAgg      int;
DECLARE @dtPb        int;
DECLARE @dtRs1       int;
DECLARE @dtDetail    int;
DECLARE @pbDiff      int;
DECLARE @jan1Rows    int;
DECLARE @jan1PlanOk  int;
DECLARE @jan1RestOk  int;
DECLARE @jan1LimNull int;

DECLARE @colList nvarchar(max);
DECLARE @sql     nvarchar(max);
DECLARE @setPrefix nvarchar(200) = N'SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; ';

-- ---------------------------------------------------------------------------
-- 1. Материализация ResultSet
-- ---------------------------------------------------------------------------
IF @refresh = 1
BEGIN
    RAISERROR(N'--- 1. EXEC spMstrg_2606 @ipgStKey=42 ---', 0, 1) WITH NOWAIT;
    SET @t0 = SYSDATETIME();
    EXEC ags.spMstrg_2606
        @ipgCh         = @ipgCh,
        @MounthEndDate = @dt,
        @ipgStKey      = @stIpg,
        @stCostKey     = NULL,
        @saveToTables  = 1;
    SET @ms = DATEDIFF(ms, @t0, SYSDATETIME());
    SET @msg = N'  spMstrg_2606 ms=' + CAST(@ms AS nvarchar(20));
    RAISERROR(@msg, 0, 1) WITH NOWAIT;
END
ELSE
    RAISERROR(N'--- 1. SKIP refresh (@refresh=0) ---', 0, 1) WITH NOWAIT;

-- ---------------------------------------------------------------------------
-- 2. fnIpgChDats_2606 — эталон 17 дат
-- ---------------------------------------------------------------------------
RAISERROR(N'--- 2. fnIpgChDats_2606 baseline ---', 0, 1) WITH NOWAIT;

SELECT @datsV = COUNT(*) FROM ags.fnIpgChDats_2606(@ipgCh);

SET @msg = N'  fnIpgChDats_2606 count=' + CAST(@datsV AS nvarchar(10)) + N' (expect 17)';
RAISERROR(@msg, 0, 1) WITH NOWAIT;

IF @datsV <> 17
BEGIN
    SET @fail = @fail + 1;
    RAISERROR(N'  FAIL: fnIpgChDats_2606 count', 0, 1) WITH NOWAIT;
END

IF NOT EXISTS (SELECT 1 FROM ags.fnIpgChDats_2606(@ipgCh) WHERE dAll = @jan1)
BEGIN
    SET @fail = @fail + 1;
    RAISERROR(N'  FAIL: fnIpgChDats_2606 missing 2022-01-01', 0, 1) WITH NOWAIT;
END

-- ---------------------------------------------------------------------------
-- 3. EXCEPT календаря: fnIpgChDats_2606 ↔ RS1 / PercentBrn
-- ---------------------------------------------------------------------------
RAISERROR(N'--- 3. Calendar EXCEPT (fnIpgChDats_2606 ↔ RS1) ---', 0, 1) WITH NOWAIT;

SELECT @calMissRs1 = COUNT(*)
FROM ags.fnIpgChDats_2606(@ipgCh) d
WHERE NOT EXISTS (
    SELECT 1 FROM ags.spMstrg_2606_ResultSet1 r WHERE r.dateRslt = d.dAll
);

SELECT @calExtraRs1 = COUNT(*)
FROM (SELECT DISTINCT dateRslt FROM ags.spMstrg_2606_ResultSet1) r
WHERE NOT EXISTS (
    SELECT 1 FROM ags.fnIpgChDats_2606(@ipgCh) d WHERE d.dAll = r.dateRslt
);

SELECT @calMiss2102 = COUNT(*)
FROM ags.fnIpgChDats_2606(@ipgCh) d
WHERE NOT EXISTS (
    SELECT 1
    FROM ags.spMstrg_2606_ResultSet1 r
    WHERE r.cstapKey = @cstAgPn AND r.dateRslt = d.dAll
);

SET @msg = N'  RS1 missing datsV=' + CAST(@calMissRs1 AS nvarchar(10))
    + N' RS1 extra=' + CAST(@calExtraRs1 AS nvarchar(10))
    + N' detail2102 missing=' + CAST(@calMiss2102 AS nvarchar(10)) + N' (expect 0,0,0)';
RAISERROR(@msg, 0, 1) WITH NOWAIT;

IF @calMissRs1 <> 0 OR @calExtraRs1 <> 0 OR @calMiss2102 <> 0
BEGIN
    SET @fail = @fail + 1;
    RAISERROR(N'  FAIL: calendar EXCEPT RS1', 0, 1) WITH NOWAIT;
END

RAISERROR(N'--- 3b. Calendar EXCEPT (fnIpgChDats_2606 ↔ PercentBrn) ---', 0, 1) WITH NOWAIT;

DECLARE @calMissPb int, @calExtraPb int;

SELECT @calMissPb = COUNT(*)
FROM ags.fnIpgChDats_2606(@ipgCh) d
WHERE NOT EXISTS (
    SELECT 1
    FROM ags.fnIpgChRsltCstUtlPercentBrn_2606(@ipgCh, @stIpg, NULL) p
    WHERE p.dateRslt = d.dAll
);

SELECT @calExtraPb = COUNT(*)
FROM (
    SELECT DISTINCT dateRslt
    FROM ags.fnIpgChRsltCstUtlPercentBrn_2606(@ipgCh, @stIpg, NULL)
) p
WHERE NOT EXISTS (
    SELECT 1 FROM ags.fnIpgChDats_2606(@ipgCh) d WHERE d.dAll = p.dateRslt
);

SET @msg = N'  PercentBrn missing datsV=' + CAST(@calMissPb AS nvarchar(10))
    + N' PercentBrn extra=' + CAST(@calExtraPb AS nvarchar(10)) + N' (expect 0,0)';
RAISERROR(@msg, 0, 1) WITH NOWAIT;

IF @calMissPb <> 0 OR @calExtraPb <> 0
BEGIN
    SET @fail = @fail + 1;
    RAISERROR(N'  FAIL: calendar EXCEPT PercentBrn', 0, 1) WITH NOWAIT;
END

-- ---------------------------------------------------------------------------
-- 4. Счётчики spot 2102 / stIpg=42
-- ---------------------------------------------------------------------------
RAISERROR(N'--- 4. Row counts (expect 68 total, 17 detail, 17 dateRslt) ---', 0, 1) WITH NOWAIT;

SELECT @cntPb = COUNT(*)
FROM ags.fnIpgChRsltCstUtlPercentBrn_2606(@ipgCh, @stIpg, NULL);

SELECT @cntRs1 = COUNT(*) FROM ags.spMstrg_2606_ResultSet1;
SELECT @cntDetail = COUNT(*) FROM ags.spMstrg_2606_ResultSet1 WHERE cstapKey = @cstAgPn;
SELECT @cntAgg = COUNT(*) FROM ags.spMstrg_2606_ResultSet1 WHERE cstapKey IS NULL;
SELECT @dtPb = COUNT(DISTINCT dateRslt)
FROM ags.fnIpgChRsltCstUtlPercentBrn_2606(@ipgCh, @stIpg, NULL);
SELECT @dtRs1 = COUNT(DISTINCT dateRslt) FROM ags.spMstrg_2606_ResultSet1;
SELECT @dtDetail = COUNT(DISTINCT dateRslt)
FROM ags.spMstrg_2606_ResultSet1 WHERE cstapKey = @cstAgPn;

SET @msg = N'  PercentBrn=' + CAST(@cntPb AS nvarchar(10))
    + N' RS1=' + CAST(@cntRs1 AS nvarchar(10))
    + N' detail2102=' + CAST(@cntDetail AS nvarchar(10))
    + N' aggregate=' + CAST(@cntAgg AS nvarchar(10))
    + N' distinct dateRslt=' + CAST(@dtRs1 AS nvarchar(10));
RAISERROR(@msg, 0, 1) WITH NOWAIT;

IF @cntPb <> 68 OR @cntRs1 <> 68 OR @cntDetail <> 17 OR @cntAgg <> 51
    OR @dtPb <> 17 OR @dtRs1 <> 17 OR @dtDetail <> 17
BEGIN
    SET @fail = @fail + 1;
    RAISERROR(N'  FAIL: row count / dateRslt', 0, 1) WITH NOWAIT;
END

-- ---------------------------------------------------------------------------
-- 5. RS1 ↔ PercentBrn (полный набор 68 строк)
-- ---------------------------------------------------------------------------
RAISERROR(N'--- 5. RS1 ↔ PercentBrn_2606 (68 rows) ---', 0, 1) WITH NOWAIT;

SELECT @colList = STUFF((
    SELECT N', ' + QUOTENAME(c.COLUMN_NAME)
    FROM INFORMATION_SCHEMA.COLUMNS c
    WHERE c.TABLE_SCHEMA = N'ags'
      AND c.TABLE_NAME = N'spMstrg_2606_ResultSet1'
      AND c.COLUMN_NAME <> N'rowNum'
    ORDER BY c.ORDINAL_POSITION
    FOR XML PATH(N''), TYPE
).value(N'.', N'nvarchar(max)'), 1, 2, N'');

SET @sql = @setPrefix + N'
SELECT @o = COUNT(*) FROM (
    SELECT ' + @colList + N'
    FROM ags.spMstrg_2606_ResultSet1
    EXCEPT
    SELECT ' + @colList + N'
    FROM ags.fnIpgChRsltCstUtlPercentBrn_2606(@ipgCh, @stIpg, NULL)
) x;';
EXEC sp_executesql @sql,
    N'@ipgCh int, @stIpg int, @o int OUTPUT',
    @ipgCh = @ipgCh, @stIpg = @stIpg, @o = @pbDiff OUTPUT;

SET @msg = N'  RS1 EXCEPT PercentBrn=' + CAST(@pbDiff AS nvarchar(10)) + N' (expect 0)';
RAISERROR(@msg, 0, 1) WITH NOWAIT;

IF @pbDiff <> 0
BEGIN
    SET @fail = @fail + 1;
    RAISERROR(N'  FAIL: RS1 vs PercentBrn', 0, 1) WITH NOWAIT;
END

-- ---------------------------------------------------------------------------
-- 6. Spot 01.01 — начальная точка графика (деталь 2102)
-- ---------------------------------------------------------------------------
RAISERROR(N'--- 6. Spot 2022-01-01 detail 2102 (plan=0, rest≈lim) ---', 0, 1) WITH NOWAIT;

SELECT @jan1Rows = COUNT(*)
FROM ags.fnIpgChRsltCstUtlPercentBrn_2606(@ipgCh, @stIpg, NULL)
WHERE cstapKey = @cstAgPn AND dateRslt = @jan1;

IF @jan1Rows < 1
BEGIN
    SET @fail = @fail + 1;
    RAISERROR(N'  FAIL: no detail row on 2022-01-01', 0, 1) WITH NOWAIT;
END
ELSE
BEGIN
    SELECT
        @jan1PlanOk = SUM(CASE
            WHEN ISNULL(ag_Pl, 0) = 0 AND ISNULL(ag_PlAccum, 0) = 0 THEN 1 ELSE 0 END),
        @jan1RestOk = SUM(CASE
            WHEN ag_lim IS NOT NULL
             AND ag_restOfLimit IS NOT NULL
             AND ABS(ag_restOfLimit - ag_lim) <= 0.01 THEN 1
            WHEN ag_lim IS NOT NULL
             AND ag_restOfLimit IS NOT NULL
             AND ag_lim <> 0
             AND ABS(ag_restOfLimit - ag_lim) / ABS(ag_lim) <= 0.0001 THEN 1
            ELSE 0 END),
        @jan1LimNull = SUM(CASE WHEN ag_lim IS NULL THEN 1 ELSE 0 END)
    FROM ags.fnIpgChRsltCstUtlPercentBrn_2606(@ipgCh, @stIpg, NULL)
    WHERE cstapKey = @cstAgPn AND dateRslt = @jan1;

    SET @msg = N'  Jan1 rows=' + CAST(@jan1Rows AS nvarchar(10))
        + N' planOk=' + CAST(ISNULL(@jan1PlanOk, 0) AS nvarchar(10))
        + N' rest≈lim=' + CAST(ISNULL(@jan1RestOk, 0) AS nvarchar(10))
        + N' limNull=' + CAST(ISNULL(@jan1LimNull, 0) AS nvarchar(10));
    RAISERROR(@msg, 0, 1) WITH NOWAIT;

    IF ISNULL(@jan1PlanOk, 0) < @jan1Rows
    BEGIN
        SET @fail = @fail + 1;
        RAISERROR(N'  FAIL: Jan1 ag_Pl/ag_PlAccum != 0', 0, 1) WITH NOWAIT;
    END

    IF ISNULL(@jan1LimNull, 0) = @jan1Rows
    BEGIN
        SET @warn = @warn + 1;
        RAISERROR(N'  WARN: Jan1 ag_lim NULL on golden fixture — rest≈lim skipped', 0, 1) WITH NOWAIT;
    END
    ELSE IF ISNULL(@jan1RestOk, 0) < (@jan1Rows - ISNULL(@jan1LimNull, 0))
    BEGIN
        SET @fail = @fail + 1;
        RAISERROR(N'  FAIL: Jan1 ag_restOfLimit not ≈ ag_lim', 0, 1) WITH NOWAIT;
    END
END

-- ---------------------------------------------------------------------------
-- Итог
-- ---------------------------------------------------------------------------
IF @fail = 0 AND @warn = 0
    RAISERROR(N'=== 07s: PASS (calendar) ===', 0, 1) WITH NOWAIT;
ELSE IF @fail = 0
BEGIN
    SET @msg = N'=== 07s: PASS (calendar); WARN=' + CAST(@warn AS nvarchar(10)) + N' ===';
    RAISERROR(@msg, 0, 1) WITH NOWAIT;
END
ELSE
BEGIN
    SET @msg = N'=== 07s: FAIL (calendar); fail=' + CAST(@fail AS nvarchar(10))
        + N' warn=' + CAST(@warn AS nvarchar(10)) + N' ===';
    RAISERROR(@msg, 0, 1) WITH NOWAIT;
END
GO
