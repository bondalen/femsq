USE [FishEye];
GO

-- =============================================================================
-- Файл:    07f4_baseline_count_chain5.sql
-- Пакет:   docs/development/notes/sql/26-0604/
-- Назначение: Этап 20.4 — фиксация dev-эталона COUNT после календарного fix
--   (17 dateRslt, PercentBrn/RS1 _2606). Быстрый прогон без полного 07f.
-- Предусловия: 05a (PercentBrn @dt ← fnIpgChDats_2606).
-- Автор:   Александр
-- Дата:    2026-06-30
-- =============================================================================

SET NOCOUNT ON;
GO

RAISERROR(N'=== 07f4: baseline COUNT chain 5 (post calendar fix) ===', 0, 1) WITH NOWAIT;

DECLARE @ipgCh int = 5;
DECLARE @fail int = 0;
DECLARE @msg nvarchar(400);
DECLARE @t0 datetime2;

-- Dev-эталон (цепь 5, 2022, после этапа 20.2–20.3)
DECLARE @expectPb06   int = 15262;
DECLARE @expectDt06   int = 17;
DECLARE @expectPb05   int = 14447;
DECLARE @expectDt05   int = 16;

DECLARE @cnt06 int, @dts06 int, @cnt05 int, @dts05 int;
DECLARE @rs1 int, @rs4 int, @rs1dts int;

-- PercentBrn_2606
SET @t0 = SYSDATETIME();
SELECT @cnt06 = COUNT(*), @dts06 = COUNT(DISTINCT dateRslt)
FROM ags.fnIpgChRsltCstUtlPercentBrn_2606(@ipgCh, NULL, NULL);
SET @msg = N'  PercentBrn_2606 rows=' + CAST(@cnt06 AS nvarchar(10))
    + N' dateRslt=' + CAST(@dts06 AS nvarchar(10))
    + N' ms=' + CAST(DATEDIFF(ms, @t0, SYSDATETIME()) AS nvarchar(10))
    + N' (expect ' + CAST(@expectPb06 AS nvarchar(10)) + N', ' + CAST(@expectDt06 AS nvarchar(10)) + N')';
RAISERROR(@msg, 0, 1) WITH NOWAIT;

IF @cnt06 <> @expectPb06 OR @dts06 <> @expectDt06
BEGIN
    SET @fail = @fail + 1;
    RAISERROR(N'  FAIL: PercentBrn_2606 baseline', 0, 1) WITH NOWAIT;
END

-- PercentBrn_2605 (legacy, неизменный prod-эталон)
SET @t0 = SYSDATETIME();
SELECT @cnt05 = COUNT(*), @dts05 = COUNT(DISTINCT dateRslt)
FROM ags.fnIpgChRsltCstUtlPercentBrn_2605(@ipgCh, NULL);
SET @msg = N'  PercentBrn_2605 rows=' + CAST(@cnt05 AS nvarchar(10))
    + N' dateRslt=' + CAST(@dts05 AS nvarchar(10))
    + N' ms=' + CAST(DATEDIFF(ms, @t0, SYSDATETIME()) AS nvarchar(10))
    + N' (expect ' + CAST(@expectPb05 AS nvarchar(10)) + N', ' + CAST(@expectDt05 AS nvarchar(10)) + N')';
RAISERROR(@msg, 0, 1) WITH NOWAIT;

IF @cnt05 <> @expectPb05 OR @dts05 <> @expectDt05
    RAISERROR(N'  WARN: PercentBrn_2605 drift from legacy baseline', 0, 1) WITH NOWAIT;

SET @msg = N'  delta _2606-_2605 rows=' + CAST(@cnt06 - @cnt05 AS nvarchar(10))
    + N' (+01.01 × GROUPING SETS)';
RAISERROR(@msg, 0, 1) WITH NOWAIT;

-- RS1 (если уже заполнен spMstrg_2606)
IF OBJECT_ID(N'ags.spMstrg_2606_ResultSet1', N'U') IS NOT NULL
BEGIN
    SELECT @rs1 = COUNT(*), @rs1dts = COUNT(DISTINCT dateRslt) FROM ags.spMstrg_2606_ResultSet1;
    SELECT @rs4 = COUNT(*) FROM ags.spMstrg_2606_ResultSet4;
    SET @msg = N'  RS1=' + CAST(@rs1 AS nvarchar(10)) + N' dateRslt=' + CAST(@rs1dts AS nvarchar(10))
        + N' RS4=' + CAST(@rs4 AS nvarchar(10));
    RAISERROR(@msg, 0, 1) WITH NOWAIT;
    IF @rs1 <> @cnt06
    BEGIN
        SET @fail = @fail + 1;
        RAISERROR(N'  FAIL: RS1 <> PercentBrn_2606', 0, 1) WITH NOWAIT;
    END
END
ELSE
    RAISERROR(N'  RS1: table empty or missing (run spMstrg_2606 @saveToTables=1)', 0, 1) WITH NOWAIT;

IF @fail = 0
    RAISERROR(N'=== 07f4: PASS ===', 0, 1) WITH NOWAIT;
ELSE
    RAISERROR(N'=== 07f4: FAIL ===', 0, 1) WITH NOWAIT;
GO
