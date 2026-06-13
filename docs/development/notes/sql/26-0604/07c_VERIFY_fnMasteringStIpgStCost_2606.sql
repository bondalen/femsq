USE [FishEye];
GO

-- =============================================================================
-- Файл:    07c_VERIFY_fnMasteringStIpgStCost_2606.sql
-- Пакет:   docs/development/notes/sql/26-0604/
-- Назначение: Приёмка этапа 3e — fnMasteringStIpgStCost_2606 на цепи 5 (быстрые тесты).
--   @ipgStKey=21: COUNT legacy=_2606, 17 дат, суммы agSmmTtl по датам.
--   Полный NULL-тест (680 строек) — см. 07c_FULL_VERIFY_fnMasteringStIpgStCost_2606.sql
-- Предусловия: 03d.
-- Автор:   Александр
-- Дата:    2026-06-09
-- =============================================================================

SET NOCOUNT ON;
GO

PRINT '=== 07c: VERIFY fnMasteringStIpgStCost_2606 (цепь 5, ipgStKey=21) ===';

DECLARE @fail int = 0;

DECLARE @cntL21 int = (SELECT COUNT(*) FROM ags.fnMasteringStIpgStCost(21, 5, 212, 2));
DECLARE @cntN21 int = (SELECT COUNT(*) FROM ags.fnMasteringStIpgStCost_2606(21, 5, 212, 2));

PRINT N'Test 1 COUNT: legacy=' + CAST(@cntL21 AS nvarchar(10))
    + N' _2606=' + CAST(@cntN21 AS nvarchar(10));

IF @cntL21 <> @cntN21
BEGIN
    SET @fail = @fail + 1;
    PRINT N'  FAIL';
END
ELSE
    PRINT N'  OK';

DECLARE @dates21 int = (
    SELECT COUNT(DISTINCT dAll) FROM ags.fnMasteringStIpgStCost_2606(21, 5, 212, 2)
);

PRINT N'Test 2 distinct dAll: ' + CAST(@dates21 AS nvarchar(10)) + N' (expected 17)';

IF @dates21 <> 17
BEGIN
    SET @fail = @fail + 1;
    PRINT N'  FAIL';
END
ELSE
    PRINT N'  OK';

DECLARE @sumDiff21 money = (
    SELECT SUM(ABS(ISNULL(l.s, 0) - ISNULL(n.s, 0)))
    FROM (
        SELECT dAll, SUM(agSmmTtl) AS s
        FROM ags.fnMasteringStIpgStCost(21, 5, 212, 2)
        GROUP BY dAll
    ) l
    FULL OUTER JOIN (
        SELECT dAll, SUM(agSmmTtl) AS s
        FROM ags.fnMasteringStIpgStCost_2606(21, 5, 212, 2)
        GROUP BY dAll
    ) n ON l.dAll = n.dAll
);

PRINT N'Test 3 sum |agSmmTtl| diff by date: ' + CAST(@sumDiff21 AS nvarchar(30));

IF ISNULL(@sumDiff21, 0) <> 0
BEGIN
    SET @fail = @fail + 1;
    PRINT N'  FAIL';
END
ELSE
    PRINT N'  OK';

IF @fail = 0
    PRINT N'=== 07c: PASS ===';
ELSE
    PRINT N'=== 07c: FAIL (' + CAST(@fail AS nvarchar(10)) + N' test(s)) ===';
GO
