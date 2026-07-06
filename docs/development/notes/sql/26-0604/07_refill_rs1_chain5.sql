USE [FishEye];
GO

-- =============================================================================
-- Файл:    07_refill_rs1_chain5.sql
-- Пакет:   docs/development/notes/sql/26-0604/
-- Назначение: Перезаполнение ResultSet1 цепи 5 @ 2022-12-31 (этап 21.4.3+).
-- Автор:   Александр | Дата: 2026-07-06
-- =============================================================================

SET NOCOUNT ON;
GO

RAISERROR(N'=== 07_refill_rs1: chain 5 @ 2022-12-31 ===', 0, 1) WITH NOWAIT;

DECLARE @ipgCh int = 5;
DECLARE @dt    date = '2022-12-31';
DECLARE @t0    datetime2 = SYSDATETIME();
DECLARE @ms    int;
DECLARE @msg nvarchar(200);

RAISERROR(N'--- spMstrg_2605 full chain ---', 0, 1) WITH NOWAIT;
EXEC ags.spMstrg_2605
    @ipgCh         = @ipgCh,
    @MounthEndDate = @dt,
    @ipgSt         = NULL,
    @saveToTables  = 1;
SET @ms = DATEDIFF(ms, @t0, SYSDATETIME());
SET @msg = N'  spMstrg_2605 ms=' + CAST(@ms AS nvarchar(20));
RAISERROR(@msg, 0, 1) WITH NOWAIT;

SET @t0 = SYSDATETIME();
RAISERROR(N'--- spMstrg_2606 @ipgStKey=42 ---', 0, 1) WITH NOWAIT;
EXEC ags.spMstrg_2606
    @ipgCh         = @ipgCh,
    @MounthEndDate = @dt,
    @ipgStKey      = 42,
    @stCostKey     = NULL,
    @saveToTables  = 1;
SET @ms = DATEDIFF(ms, @t0, SYSDATETIME());
SET @msg = N'  spMstrg_2606 ms=' + CAST(@ms AS nvarchar(20));
RAISERROR(@msg, 0, 1) WITH NOWAIT;

SELECT 'RS1_2606' AS rs, COUNT(*) AS cnt FROM ags.spMstrg_2606_ResultSet1;

RAISERROR(N'=== 07_refill_rs1: DONE ===', 0, 1) WITH NOWAIT;
GO
