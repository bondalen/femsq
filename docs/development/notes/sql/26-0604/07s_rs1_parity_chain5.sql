USE [FishEye];
GO

-- =============================================================================
-- Файл:    07s_rs1_parity_chain5.sql
-- Пакет:   docs/development/notes/sql/26-0604/
-- Назначение: Gate **parity** (Решение 17, этап 20.1) — полное сравнение RS1
--   по golden-стройке cstAgPn=2102: spMstrg_2606 (@ipgStKey=42) ↔ _2605 (полная
--   цепь, срез cstapKey=2102). Все столбцы ResultSet1, кроме rowNum (порядковый
--   номер зависит от объёма прогона). Агрегаты GROUPING SETS (_2606, 48 строк)
--   сверяются с деталью 2102 на той же dateRslt.
-- Предусловия: 05–06, 10a–10d, патч 04.
-- Эталон: 16 dateRslt (legacy), 16 detail + 48 aggregate = 64 строки _2606.
-- Автор:   Александр
-- Дата:    2026-06-29
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

RAISERROR(N'=== 07s: RS1 parity gate chain 5 (cst 2102, этап 20.1) ===', 0, 1) WITH NOWAIT;

DECLARE @ipgCh       int  = 5;
DECLARE @stIpg       int  = 42;
DECLARE @cstAgPn     int  = 2102;
DECLARE @dt          date = '2022-12-31';
DECLARE @refresh     bit  = 0;   -- 1: перезаполнить ResultSet-таблицы (spMstrg ~25 с + ~0,3 с)
DECLARE @fail        int  = 0;
DECLARE @warn        int  = 0;
DECLARE @msg         nvarchar(500);
DECLARE @t0          datetime2;
DECLARE @ms          int;

DECLARE @cnt05d int, @cnt06d int, @cnt06a int, @cnt06t int;
DECLARE @dt05 int, @dt06 int;
DECLARE @except06to05 int, @except05to06 int;
DECLARE @aggDiff int;
DECLARE @calMissing int;

DECLARE @colList nvarchar(max);
DECLARE @sql     nvarchar(max);
DECLARE @valueColList nvarchar(max);
DECLARE @pbDiff int;
DECLARE @setPrefix nvarchar(200) = N'SET ANSI_NULLS ON; SET QUOTED_IDENTIFIER ON; ';

-- ---------------------------------------------------------------------------
-- 1. Материализация ResultSet (при @refresh=1)
-- ---------------------------------------------------------------------------
IF @refresh = 1
BEGIN
    RAISERROR(N'--- 1. EXEC spMstrg_2605 (full chain) ---', 0, 1) WITH NOWAIT;
    SET @t0 = SYSDATETIME();
    EXEC ags.spMstrg_2605
        @ipgCh         = @ipgCh,
        @MounthEndDate = @dt,
        @ipgSt         = NULL,
        @saveToTables  = 1;
    SET @ms = DATEDIFF(ms, @t0, SYSDATETIME());
    SET @msg = N'  spMstrg_2605 ms=' + CAST(@ms AS nvarchar(20));
    RAISERROR(@msg, 0, 1) WITH NOWAIT;

    RAISERROR(N'--- 1b. EXEC spMstrg_2606 @ipgStKey=42 ---', 0, 1) WITH NOWAIT;
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
-- 0. Calendar WARN (Решение 17 — ожидаемо до fix PercentBrn)
-- ---------------------------------------------------------------------------
RAISERROR(N'--- 0. Calendar WARN (fnIpgChDats_2606 vs RS1 dateRslt) ---', 0, 1) WITH NOWAIT;

SELECT @calMissing = COUNT(*)
FROM ags.fnIpgChDats_2606(@ipgCh) d
WHERE NOT EXISTS (
    SELECT 1
    FROM ags.spMstrg_2606_ResultSet1 r
    WHERE r.cstapKey = @cstAgPn AND r.dateRslt = d.dAll
);

IF @calMissing > 0
BEGIN
    SET @warn = @warn + 1;
    SET @msg = N'  WARN calendar: fnIpgChDats_2606 dates missing in RS1(2102) = '
        + CAST(@calMissing AS nvarchar(10)) + N' (ожидаемо до этапа 20.2)';
    RAISERROR(@msg, 0, 1) WITH NOWAIT;
END
ELSE
    RAISERROR(N'  calendar: all fnIpgChDats_2606 dates present in RS1(2102)', 0, 1) WITH NOWAIT;

-- ---------------------------------------------------------------------------
-- 2. Счётчики universe
-- ---------------------------------------------------------------------------
RAISERROR(N'--- 2. Row counts ---', 0, 1) WITH NOWAIT;

SELECT @cnt05d = COUNT(*) FROM ags.spMstrg_2408_ResultSet1 WHERE cstapKey = @cstAgPn;
SELECT @cnt06d = COUNT(*) FROM ags.spMstrg_2606_ResultSet1 WHERE cstapKey = @cstAgPn;
SELECT @cnt06a = COUNT(*) FROM ags.spMstrg_2606_ResultSet1 WHERE cstapKey IS NULL;
SELECT @cnt06t = COUNT(*) FROM ags.spMstrg_2606_ResultSet1;
SELECT @dt05 = COUNT(DISTINCT dateRslt) FROM ags.spMstrg_2408_ResultSet1 WHERE cstapKey = @cstAgPn;
SELECT @dt06 = COUNT(DISTINCT dateRslt) FROM ags.spMstrg_2606_ResultSet1 WHERE cstapKey = @cstAgPn;

SET @msg = N'  _2605 detail(2102)=' + CAST(@cnt05d AS nvarchar(10))
    + N' _2606 detail=' + CAST(@cnt06d AS nvarchar(10))
    + N' aggregate=' + CAST(@cnt06a AS nvarchar(10))
    + N' total _2606=' + CAST(@cnt06t AS nvarchar(10))
    + N' dateRslt=' + CAST(@dt06 AS nvarchar(10)) + N' (expect 16, total 64)';
RAISERROR(@msg, 0, 1) WITH NOWAIT;

IF @cnt05d <> 16 OR @cnt06d <> 16 OR @cnt06a <> 48 OR @cnt06t <> 64 OR @dt05 <> 16 OR @dt06 <> 16
BEGIN
    SET @fail = @fail + 1;
    RAISERROR(N'  FAIL: row count / dateRslt', 0, 1) WITH NOWAIT;
END

-- ---------------------------------------------------------------------------
-- 3. Деталь 2102: полный EXCEPT всех столбцов кроме rowNum
-- ---------------------------------------------------------------------------
RAISERROR(N'--- 3. Detail EXCEPT (all columns except rowNum) ---', 0, 1) WITH NOWAIT;

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
    WHERE cstapKey = @cst
    EXCEPT
    SELECT ' + @colList + N'
    FROM ags.spMstrg_2408_ResultSet1
    WHERE cstapKey = @cst
) x;';
EXEC sp_executesql @sql, N'@cst int, @o int OUTPUT', @cst = @cstAgPn, @o = @except06to05 OUTPUT;

SET @sql = @setPrefix + N'
SELECT @o = COUNT(*) FROM (
    SELECT ' + @colList + N'
    FROM ags.spMstrg_2408_ResultSet1
    WHERE cstapKey = @cst
    EXCEPT
    SELECT ' + @colList + N'
    FROM ags.spMstrg_2606_ResultSet1
    WHERE cstapKey = @cst
) x;';
EXEC sp_executesql @sql, N'@cst int, @o int OUTPUT', @cst = @cstAgPn, @o = @except05to06 OUTPUT;

SET @msg = N'  EXCEPT 2606→2605=' + CAST(@except06to05 AS nvarchar(10))
    + N' 2605→2606=' + CAST(@except05to06 AS nvarchar(10)) + N' (expect 0,0)';
RAISERROR(@msg, 0, 1) WITH NOWAIT;

IF @except06to05 <> 0 OR @except05to06 <> 0
BEGIN
    SET @fail = @fail + 1;
    RAISERROR(N'  FAIL: detail full EXCEPT', 0, 1) WITH NOWAIT;

    RAISERROR(N'  --- sample: first mismatch keys (business key) ---', 0, 1) WITH NOWAIT;
    SELECT TOP 5
        COALESCE(a.dateRslt, b.dateRslt) AS dateRslt,
        COALESCE(a.ipgKey, b.ipgKey) AS ipgKey,
        CASE WHEN a.dateRslt IS NULL THEN N'missing_2606' WHEN b.dateRslt IS NULL THEN N'missing_2605' ELSE N'value_diff' END AS side
    FROM ags.spMstrg_2606_ResultSet1 a
    FULL OUTER JOIN ags.spMstrg_2408_ResultSet1 b
        ON a.cstapKey = b.cstapKey
       AND a.cstapKey = @cstAgPn
       AND a.dateRslt = b.dateRslt
       AND ISNULL(a.ipgKey, -1) = ISNULL(b.ipgKey, -1)
       AND ISNULL(a.ogNm, N'') = ISNULL(b.ogNm, N'')
       AND ISNULL(a.branch, -1) = ISNULL(b.branch, -1)
       AND ISNULL(a.cstAgPnCode, N'') = ISNULL(b.cstAgPnCode, N'')
    WHERE a.cstapKey = @cstAgPn OR b.cstapKey = @cstAgPn;
END

-- ---------------------------------------------------------------------------
-- 4. Агрегаты GROUPING SETS (_2606): метрики roll-up = деталь 2102 на dateRslt
--     (календарные поля mNum/yKey… на агрегатах = NULL по семантике GROUPING SETS;
--      parity с _2605 — только деталь, см. §3; _2605 не даёт срез 48 aggregate при stIpg=42)
-- ---------------------------------------------------------------------------
RAISERROR(N'--- 4. Aggregate metric consistency (_2606 roll-up vs detail 2102) ---', 0, 1) WITH NOWAIT;

SELECT @valueColList = STUFF((
    SELECT N', ' + QUOTENAME(c.COLUMN_NAME)
    FROM INFORMATION_SCHEMA.COLUMNS c
    WHERE c.TABLE_SCHEMA = N'ags'
      AND c.TABLE_NAME = N'spMstrg_2606_ResultSet1'
      AND c.COLUMN_NAME NOT IN (
          N'rowNum', N'ogNm', N'branch', N'branchName', N'cstAgPnCode', N'cstapKey',
          N'ipgKey', N'ipgChKey', N'ipgCount',
          N'ag_ipgpKey', N'ag_iShKey', N'iv_ipgpKey', N'iv_iShKey', N'ia_iShKey',
          N'uk_ipgpKey', N'uk_iShKey', N'np_iShKey',
          N'mNum', N'mKey', N'yKey', N'yyyy', N'mCs', N'mNm', N'mQ', N'mHy',
          N'cstaInvestor', N'ogaKey'
      )
    ORDER BY c.ORDINAL_POSITION
    FOR XML PATH(N''), TYPE
).value(N'.', N'nvarchar(max)'), 1, 2, N'');

SET @sql = @setPrefix + N'
SELECT @o = COUNT(*)
FROM ags.spMstrg_2606_ResultSet1 g
INNER JOIN ags.spMstrg_2606_ResultSet1 d
    ON d.cstapKey = @cst AND g.dateRslt = d.dateRslt
WHERE g.cstapKey IS NULL
  AND EXISTS (
    SELECT 1 FROM (
        SELECT ' + @valueColList + N'
        FROM ags.spMstrg_2606_ResultSet1 g2
        WHERE g2.dateRslt = g.dateRslt
          AND ISNULL(g2.ogNm, N'''') = ISNULL(g.ogNm, N'''')
          AND ISNULL(g2.branch, -1) = ISNULL(g.branch, -1)
          AND g2.cstapKey IS NULL
        EXCEPT
        SELECT ' + @valueColList + N'
        FROM ags.spMstrg_2606_ResultSet1 d2
        WHERE d2.cstapKey = @cst AND d2.dateRslt = g.dateRslt
    ) z
);';
EXEC sp_executesql @sql, N'@cst int, @o int OUTPUT', @cst = @cstAgPn, @o = @aggDiff OUTPUT;

SET @msg = N'  aggregate rows with metric diff vs _2606 detail=' + CAST(@aggDiff AS nvarchar(10))
    + N' (expect 0)';
RAISERROR(@msg, 0, 1) WITH NOWAIT;

IF @aggDiff <> 0
BEGIN
    SET @fail = @fail + 1;
    RAISERROR(N'  FAIL: aggregate roll-up metrics', 0, 1) WITH NOWAIT;
END

-- ---------------------------------------------------------------------------
-- 5. RS1 ↔ PercentBrn (_2606) на всём наборе 64 строк
-- ---------------------------------------------------------------------------
RAISERROR(N'--- 5. RS1 ↔ PercentBrn_2606 (64 rows) ---', 0, 1) WITH NOWAIT;

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
-- Итог
-- ---------------------------------------------------------------------------
IF @fail = 0 AND @warn = 0
    RAISERROR(N'=== 07s: PASS (parity) ===', 0, 1) WITH NOWAIT;
ELSE IF @fail = 0
BEGIN
    SET @msg = N'=== 07s: PASS (parity); WARN calendar=' + CAST(@warn AS nvarchar(10)) + N' ===';
    RAISERROR(@msg, 0, 1) WITH NOWAIT;
END
ELSE
BEGIN
    SET @msg = N'=== 07s: FAIL (parity); fail=' + CAST(@fail AS nvarchar(10))
        + N' warn=' + CAST(@warn AS nvarchar(10)) + N' ===';
    RAISERROR(@msg, 0, 1) WITH NOWAIT;
END
GO
