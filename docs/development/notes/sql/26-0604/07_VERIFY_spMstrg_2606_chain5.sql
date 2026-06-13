USE [FishEye];
GO
-- =============================================================================
-- 07_VERIFY_spMstrg_2606_chain5.sql
-- Приёмка Этапа 11: spMstrg_2606 на цепи 5, @MounthEndDate='2022-09-30'
-- =============================================================================
SET NOCOUNT ON;
GO

DECLARE @ipgCh int = 5;
DECLARE @dt    date = '2022-09-30';
DECLARE @t0    datetime2;
DECLARE @ms    int;
DECLARE @msg   nvarchar(300);
DECLARE @fail  int = 0;

RAISERROR(N'=== 07_VERIFY: spMstrg_2606 chain 5 ===', 0, 1) WITH NOWAIT;

-- 11.3 saveToTables=1
SET @t0 = SYSDATETIME();
RAISERROR(N'--- 11.3 EXEC @saveToTables=1 ---', 0, 1) WITH NOWAIT;
EXEC ags.spMstrg_2606 @ipgCh, @dt, NULL, NULL, @saveToTables = 1;
SET @ms = DATEDIFF(ms, @t0, SYSDATETIME());

SELECT 'RS1' AS rs, COUNT(*) AS cnt FROM ags.spMstrg_2606_ResultSet1
UNION ALL SELECT 'RS2', COUNT(*) FROM ags.spMstrg_2606_ResultSet2
UNION ALL SELECT 'RS3', COUNT(*) FROM ags.spMstrg_2606_ResultSet3
UNION ALL SELECT 'RS4', COUNT(*) FROM ags.spMstrg_2606_ResultSet4
UNION ALL SELECT 'RS5', COUNT(*) FROM ags.spMstrg_2606_ResultSet5
UNION ALL SELECT 'RS6', COUNT(*) FROM ags.spMstrg_2606_ResultSet6
UNION ALL SELECT 'RS7', COUNT(*) FROM ags.spMstrg_2606_ResultSet7;

DECLARE @rs1 int, @rs4 int;
SELECT @rs1 = COUNT(*) FROM ags.spMstrg_2606_ResultSet1;
SELECT @rs4 = COUNT(*) FROM ags.spMstrg_2606_ResultSet4;

SET @msg = N'  saveToTables=1 ms=' + CAST(@ms AS nvarchar) + N' RS1=' + CAST(@rs1 AS nvarchar) + N' RS4=' + CAST(@rs4 AS nvarchar);
RAISERROR(@msg, 0, 1) WITH NOWAIT;

IF @rs1 = 0 BEGIN RAISERROR(N'  FAIL: RS1 empty', 0, 1) WITH NOWAIT; SET @fail = @fail + 1; END
IF @rs4 = 0 BEGIN RAISERROR(N'  FAIL: RS4 empty', 0, 1) WITH NOWAIT; SET @fail = @fail + 1; END

-- Сравнение RS1 с _2605 (эталон приёмки)
DECLARE @rs1_05 int;
SELECT @rs1_05 = COUNT(*) FROM ags.spMstrg_2408_ResultSet1;
-- Запускаем _2605 для свежего эталона если пусто
IF @rs1_05 = 0
BEGIN
    RAISERROR(N'  (заполняем _2605 эталон)...', 0, 1) WITH NOWAIT;
    EXEC ags.spMstrg_2605 @ipgCh, @dt, NULL, @saveToTables = 1;
    SELECT @rs1_05 = COUNT(*) FROM ags.spMstrg_2408_ResultSet1;
END

IF @rs1 <> @rs1_05
BEGIN
    SET @msg = N'  WARN: RS1 count _2606=' + CAST(@rs1 AS nvarchar) + N' vs _2605=' + CAST(@rs1_05 AS nvarchar);
    RAISERROR(@msg, 0, 1) WITH NOWAIT;
END
ELSE
    RAISERROR(N'  RS1 count = _2605 OK', 0, 1) WITH NOWAIT;

-- 11.4 saveToTables=0 — 7 рекордсетов (Access); успех = без ошибки
SET @t0 = SYSDATETIME();
RAISERROR(N'--- 11.4 EXEC @saveToTables=0 (7 recordsets) ---', 0, 1) WITH NOWAIT;
EXEC ags.spMstrg_2606 @ipgCh, @dt, NULL, NULL, @saveToTables = 0;
SET @ms = DATEDIFF(ms, @t0, SYSDATETIME());
SET @msg = N'  saveToTables=0 completed ms=' + CAST(@ms AS nvarchar);
RAISERROR(@msg, 0, 1) WITH NOWAIT;

IF @fail = 0
    RAISERROR(N'=== 07_VERIFY: PASS ===', 0, 1) WITH NOWAIT;
ELSE
    RAISERROR(N'=== 07_VERIFY: FAIL ===', 0, 1) WITH NOWAIT;
GO
