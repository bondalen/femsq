USE [FishEye];
GO

-- =============================================================================
-- Файл:    07s_rs1_parity_chain5.sql
-- Пакет:   docs/development/notes/sql/26-0604/
-- Назначение: Gate **parity** (Решение 17/21/22, этапы 20.1 / 21.4.6).
--   RS1 _2606 ↔ _2605 (2408_ResultSet1) по cst 2102: non-plan поля на общих dateRslt;
--   plan-колонки (ag_Pl/iv_Pl/…) — **ожидаемый WARN** после plan-align (Решение 22).
--   _2606: 17 dateRslt, 68 строк; legacy _2605: 16 dateRslt.
-- Дата:    2026-07-06 (обновление 21.4.6)
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
DECLARE @refresh     bit  = 1;   -- 1: перезаполнить ResultSet (gate 21.4.6)
DECLARE @fail        int  = 0;
DECLARE @warn        int  = 0;
DECLARE @msg         nvarchar(500);
DECLARE @t0          datetime2;
DECLARE @ms          int;

DECLARE @cnt05d int, @cnt06d int, @cnt06a int, @cnt06t int;
DECLARE @dt05 int, @dt06 int;
DECLARE @exceptNp06 int, @exceptNp05 int;
DECLARE @planDiffRows int;
DECLARE @aggDiff int;
DECLARE @calMissing int;

DECLARE @colList nvarchar(max);
DECLARE @colListNonPlan nvarchar(max);
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
-- 0. Calendar (17 дат в RS1 detail 2102)
-- ---------------------------------------------------------------------------
RAISERROR(N'--- 0. Calendar (fnIpgChDats_2606 vs RS1 detail 2102) ---', 0, 1) WITH NOWAIT;

SELECT @calMissing = COUNT(*)
FROM ags.fnIpgChDats_2606(@ipgCh) d
WHERE NOT EXISTS (
    SELECT 1
    FROM ags.spMstrg_2606_ResultSet1 r
    WHERE r.cstapKey = @cstAgPn AND r.dateRslt = d.dAll
);

IF @calMissing > 0
BEGIN
    SET @fail = @fail + 1;
    SET @msg = N'  FAIL calendar: dates missing in RS1(2102) = ' + CAST(@calMissing AS nvarchar(10));
    RAISERROR(@msg, 0, 1) WITH NOWAIT;
END
ELSE
    RAISERROR(N'  calendar: all 17 fnIpgChDats_2606 dates in RS1(2102)', 0, 1) WITH NOWAIT;

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
    + N' dateRslt _2606=' + CAST(@dt06 AS nvarchar(10))
    + N' (expect legacy 16/16; _2606 17/51/68/17)';
RAISERROR(@msg, 0, 1) WITH NOWAIT;

IF @cnt05d <> 16 OR @dt05 <> 16
BEGIN
    SET @fail = @fail + 1;
    RAISERROR(N'  FAIL: legacy _2605 row count / dateRslt', 0, 1) WITH NOWAIT;
END

IF @cnt06d <> 17 OR @cnt06a <> 51 OR @cnt06t <> 68 OR @dt06 <> 17
BEGIN
    SET @fail = @fail + 1;
    RAISERROR(N'  FAIL: _2606 row count / dateRslt (calendar)', 0, 1) WITH NOWAIT;
END

-- ---------------------------------------------------------------------------
-- 3. Деталь 2102: EXCEPT на пересечении dateRslt (16 legacy + 01.01 только _2606)
-- ---------------------------------------------------------------------------
RAISERROR(N'--- 3a. Detail EXCEPT non-plan (common dateRslt) ---', 0, 1) WITH NOWAIT;

SELECT @colList = STUFF((
    SELECT N', ' + QUOTENAME(c.COLUMN_NAME)
    FROM INFORMATION_SCHEMA.COLUMNS c
    WHERE c.TABLE_SCHEMA = N'ags'
      AND c.TABLE_NAME = N'spMstrg_2606_ResultSet1'
      AND c.COLUMN_NAME <> N'rowNum'
    ORDER BY c.ORDINAL_POSITION
    FOR XML PATH(N''), TYPE
).value(N'.', N'nvarchar(max)'), 1, 2, N'');

-- Non-plan = факт + ключи + календарь; исключаем план и все plan-derived
-- (fulfillment/percent/restOfLimit — следствие Решения 22, см. §3b).
SELECT @colListNonPlan = STUFF((
    SELECT N', ' + QUOTENAME(c.COLUMN_NAME)
    FROM INFORMATION_SCHEMA.COLUMNS c
    WHERE c.TABLE_SCHEMA = N'ags'
      AND c.TABLE_NAME = N'spMstrg_2606_ResultSet1'
      AND c.COLUMN_NAME <> N'rowNum'
      AND c.COLUMN_NAME NOT IN (
          N'ag_Pl', N'ag_PlAccum', N'iv_Pl', N'iv_PlAccum', N'uk_Pl', N'uk_PlAccum'
      )
      AND c.COLUMN_NAME NOT LIKE N'%PlFulfillment%'
      AND c.COLUMN_NAME NOT LIKE N'%PlNonFulfillment%'
      AND c.COLUMN_NAME NOT LIKE N'%PlOverFulfillment%'
      AND c.COLUMN_NAME NOT LIKE N'%PlRestLimit%'
      AND c.COLUMN_NAME NOT LIKE N'%PlOverLimit%'
      AND c.COLUMN_NAME NOT LIKE N'%Percent%'
      AND c.COLUMN_NAME NOT LIKE N'%percent%'
      AND c.COLUMN_NAME NOT LIKE N'%restOfLimit%'
    ORDER BY c.ORDINAL_POSITION
    FOR XML PATH(N''), TYPE
).value(N'.', N'nvarchar(max)'), 1, 2, N'');

SET @sql = @setPrefix + N'
SELECT @o = COUNT(*) FROM (
    SELECT ' + @colListNonPlan + N'
    FROM ags.spMstrg_2606_ResultSet1
    WHERE cstapKey = @cst
      AND dateRslt IN (SELECT dateRslt FROM ags.spMstrg_2408_ResultSet1 WHERE cstapKey = @cst)
    EXCEPT
    SELECT ' + @colListNonPlan + N'
    FROM ags.spMstrg_2408_ResultSet1
    WHERE cstapKey = @cst
) x;';
EXEC sp_executesql @sql, N'@cst int, @o int OUTPUT', @cst = @cstAgPn, @o = @exceptNp06 OUTPUT;

SET @sql = @setPrefix + N'
SELECT @o = COUNT(*) FROM (
    SELECT ' + @colListNonPlan + N'
    FROM ags.spMstrg_2408_ResultSet1
    WHERE cstapKey = @cst
    EXCEPT
    SELECT ' + @colListNonPlan + N'
    FROM ags.spMstrg_2606_ResultSet1
    WHERE cstapKey = @cst
      AND dateRslt IN (SELECT dateRslt FROM ags.spMstrg_2408_ResultSet1 WHERE cstapKey = @cst)
) x;';
EXEC sp_executesql @sql, N'@cst int, @o int OUTPUT', @cst = @cstAgPn, @o = @exceptNp05 OUTPUT;

SET @msg = N'  non-plan EXCEPT 2606→2605=' + CAST(@exceptNp06 AS nvarchar(10))
    + N' 2605→2606=' + CAST(@exceptNp05 AS nvarchar(10)) + N' (expect 0,0)';
RAISERROR(@msg, 0, 1) WITH NOWAIT;

IF @exceptNp06 <> 0 OR @exceptNp05 <> 0
BEGIN
    SET @fail = @fail + 1;
    RAISERROR(N'  FAIL: detail non-plan EXCEPT', 0, 1) WITH NOWAIT;
END

RAISERROR(N'--- 3b. Plan columns diff (expected WARN post plan-align) ---', 0, 1) WITH NOWAIT;

SELECT @planDiffRows = COUNT(*)
FROM ags.spMstrg_2606_ResultSet1 a
INNER JOIN ags.spMstrg_2408_ResultSet1 b
    ON a.cstapKey = b.cstapKey
   AND a.cstapKey = @cstAgPn
   AND a.dateRslt = b.dateRslt
   AND ISNULL(a.ipgKey, -1) = ISNULL(b.ipgKey, -1)
   AND ISNULL(a.ogNm, N'') = ISNULL(b.ogNm, N'')
   AND ISNULL(a.branch, -1) = ISNULL(b.branch, -1)
   AND ISNULL(a.cstAgPnCode, N'') = ISNULL(b.cstAgPnCode, N'')
WHERE ISNULL(a.ag_Pl, 0) <> ISNULL(b.ag_Pl, 0)
   OR ISNULL(a.ag_PlAccum, 0) <> ISNULL(b.ag_PlAccum, 0)
   OR ISNULL(a.iv_Pl, 0) <> ISNULL(b.iv_Pl, 0)
   OR ISNULL(a.iv_PlAccum, 0) <> ISNULL(b.iv_PlAccum, 0)
   OR ISNULL(a.uk_Pl, 0) <> ISNULL(b.uk_Pl, 0)
   OR ISNULL(a.uk_PlAccum, 0) <> ISNULL(b.uk_PlAccum, 0);

SET @msg = N'  plan column diff rows (common dates)=' + CAST(@planDiffRows AS nvarchar(10))
    + N' (WARN>0 expected after Решение 22)';
RAISERROR(@msg, 0, 1) WITH NOWAIT;

IF @planDiffRows > 0
    SET @warn = @warn + 1;

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
          N'cstaInvestor', N'ogaKey',
          N'ag_Pl', N'ag_PlAccum', N'iv_Pl', N'iv_PlAccum', N'uk_Pl', N'uk_PlAccum'
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
-- 5. RS1 ↔ PercentBrn (_2606) на всём наборе 68 строк
-- ---------------------------------------------------------------------------
RAISERROR(N'--- 5. RS1 ↔ PercentBrn_2606 (68 rows) ---', 0, 1) WITH NOWAIT;

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
    SET @msg = N'=== 07s: PASS (parity); WARN=' + CAST(@warn AS nvarchar(10))
        + N' (plan diff expected) ===';
    RAISERROR(@msg, 0, 1) WITH NOWAIT;
END
ELSE
BEGIN
    SET @msg = N'=== 07s: FAIL (parity); fail=' + CAST(@fail AS nvarchar(10))
        + N' warn=' + CAST(@warn AS nvarchar(10)) + N' ===';
    RAISERROR(@msg, 0, 1) WITH NOWAIT;
END
GO
