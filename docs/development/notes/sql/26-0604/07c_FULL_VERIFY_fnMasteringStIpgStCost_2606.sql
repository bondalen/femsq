USE [FishEye];
GO

-- =============================================================================
-- Файл:    07c_FULL_VERIFY_fnMasteringStIpgStCost_2606.sql
-- Пакет:   docs/development/notes/sql/26-0604/
-- Назначение: Полная приёмка fnMasteringStIpgStCost_2606(NULL,5,NULL,NULL) — ~680 строек, долгий прогон.
-- Автор:   Александр
-- Дата:    2026-06-09
-- =============================================================================

SET NOCOUNT ON;
GO

PRINT '=== 07c_FULL: VERIFY fnMasteringStIpgStCost_2606 (NULL,5,NULL,NULL) ===';
PRINT N'Ожидаемое время: 15–30 мин';

DECLARE @fail int = 0;

DECLARE @cntL int = (SELECT COUNT(*) FROM ags.fnMasteringStIpgStCost(1, 5, 212, 2));
DECLARE @cntN int = (SELECT COUNT(*) FROM ags.fnMasteringStIpgStCost_2606(NULL, 5, NULL, NULL));

PRINT N'Test 1 COUNT all: legacy=' + CAST(@cntL AS nvarchar(10))
    + N' _2606=' + CAST(@cntN AS nvarchar(10));

IF @cntL <> @cntN
BEGIN
    SET @fail = @fail + 1;
    PRINT N'  FAIL';
END
ELSE
    PRINT N'  OK';

DECLARE @datesN int = (
    SELECT COUNT(DISTINCT dAll)
    FROM ags.fnMasteringStIpgStCost_2606(NULL, 5, NULL, NULL)
);

PRINT N'Test 2 distinct dAll: ' + CAST(@datesN AS nvarchar(10)) + N' (expected 17)';

IF @datesN <> 17
    SET @fail = @fail + 1;

IF @fail = 0
    PRINT N'=== 07c_FULL: PASS ===';
ELSE
    PRINT N'=== 07c_FULL: FAIL ===';
GO
