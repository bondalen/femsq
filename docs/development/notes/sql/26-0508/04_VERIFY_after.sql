USE [FishEye]
GO

-- =============================================================================
-- Файл:    04_VERIFY_after.sql
-- Пакет:   docs/development/notes/sql/26-0508/
-- Назначение: Проверочные запросы после применения всех объектов _2605.
--
-- Подтверждённые результаты (2026-05-16, ipgCh=15, MounthEndDate='2024-08-31'):
--   Объекты:       fnIpgChRsltCstUtl2_2605, fnIpgChRsltCstUtlPercentBrn_2605, spMstrg_2605 — созданы
--   Столбцы fn2:   cols_2408=90, cols_2605=90 — совпадают
--   Столбцы fnPBrn: cols_2408=398, cols_2605=398 — совпадают
--
--   spMstrg_2605(ipgSt=NULL, save=0):  7 рекордсетов (SELECT-режим), выполнено ~26 сек
--   spMstrg_2605(ipgSt=NULL, save=1):  RS1=12693 RS2=12693 RS3=12693 RS4=0 RS5=1 RS6=0 RS7=1
--   spMstrg_2605(ipgSt='12ОПР', save=1): RS1=604 RS2=604 RS3=604 RS4=0 RS5=1 RS6=0 RS7=1
--   spMstrg_2605(ipgSt='12ОПР', save=0): 7 рекордсетов (SELECT-режим с фильтром), выполнено ~6 сек
-- =============================================================================

-- =============================================================================
-- 1. Проверка существования объектов
-- =============================================================================
SELECT
    name,
    type_desc,
    CONVERT(varchar(10), create_date, 23) AS created,
    CONVERT(varchar(10), modify_date, 23) AS modified
FROM sys.objects
WHERE schema_id = SCHEMA_ID('ags')
  AND name IN (
    'fnIpgChRsltCstUtl2_2605',
    'fnIpgChRsltCstUtlPercentBrn_2605',
    'spMstrg_2605'
  )
ORDER BY name;
GO

-- =============================================================================
-- 2. Проверка функций (количество столбцов)
-- =============================================================================
-- 2a. fnIpgChRsltCstUtl2_2605 — совпадение числа столбцов с _2408
SELECT
    (SELECT COUNT(*) FROM sys.dm_exec_describe_first_result_set(
        N'SELECT * FROM ags.fnIpgChRsltCstUtl2_2408(15)', NULL, 0)) AS cols_2408,
    (SELECT COUNT(*) FROM sys.dm_exec_describe_first_result_set(
        N'SELECT * FROM ags.fnIpgChRsltCstUtl2_2605(15, NULL)', NULL, 0)) AS cols_2605;
GO

-- 2b. fnIpgChRsltCstUtlPercentBrn_2605 — совпадение числа столбцов с _2408
SELECT
    (SELECT COUNT(*) FROM sys.dm_exec_describe_first_result_set(
        N'SELECT * FROM ags.fnIpgChRsltCstUtlPercentBrn_2408(15)', NULL, 0)) AS cols_2408,
    (SELECT COUNT(*) FROM sys.dm_exec_describe_first_result_set(
        N'SELECT * FROM ags.fnIpgChRsltCstUtlPercentBrn_2605(15, NULL)', NULL, 0)) AS cols_2605;
GO

-- =============================================================================
-- 3. Тест spMstrg_2605: режим saveToTables=0 (Access), ipgSt=NULL
--    Ожидаемый результат: 7 рекордсетов (SELECT), ~26 сек, RS1 = 12693 строк (ipgCh=15)
-- =============================================================================
EXEC ags.spMstrg_2605
    @ipgCh        = 15,
    @MounthEndDate = '2024-08-31',
    @ipgSt         = NULL,
    @saveToTables  = 0;
GO

-- =============================================================================
-- 4. Тест spMstrg_2605: режим saveToTables=1 (FEMSQ), ipgSt=NULL
--    Ожидаемый результат: ResultSet-таблицы заполнены, ~17 сек
--    RS1=12693  RS2=12693  RS3=12693  RS4=0  RS5=1  RS6=0  RS7=1
-- =============================================================================
SET NOCOUNT ON;
EXEC ags.spMstrg_2605
    @ipgCh        = 15,
    @MounthEndDate = '2024-08-31',
    @ipgSt         = NULL,
    @saveToTables  = 1;

SELECT 'RS1' AS rs, COUNT(*) AS cnt FROM ags.spMstrg_2408_ResultSet1
UNION ALL SELECT 'RS2', COUNT(*) FROM ags.spMstrg_2408_ResultSet2
UNION ALL SELECT 'RS3', COUNT(*) FROM ags.spMstrg_2408_ResultSet3
UNION ALL SELECT 'RS4', COUNT(*) FROM ags.spMstrg_2408_ResultSet4
UNION ALL SELECT 'RS5', COUNT(*) FROM ags.spMstrg_2408_ResultSet5
UNION ALL SELECT 'RS6', COUNT(*) FROM ags.spMstrg_2408_ResultSet6
UNION ALL SELECT 'RS7', COUNT(*) FROM ags.spMstrg_2408_ResultSet7;
GO

-- =============================================================================
-- 5. Тест spMstrg_2605: режим saveToTables=1 (FEMSQ), ipgSt='12ОПР'
--    Ожидаемый результат: RS1=604  RS2=604  RS3=604  RS4=0  RS5=1  RS6=0  RS7=1
-- =============================================================================
SET NOCOUNT ON;
EXEC ags.spMstrg_2605
    @ipgCh        = 15,
    @MounthEndDate = '2024-08-31',
    @ipgSt         = N'12ОПР',
    @saveToTables  = 1;

SELECT 'RS1_12OPR' AS rs, COUNT(*) AS cnt FROM ags.spMstrg_2408_ResultSet1
UNION ALL SELECT 'RS2_12OPR', COUNT(*) FROM ags.spMstrg_2408_ResultSet2
UNION ALL SELECT 'RS3_12OPR', COUNT(*) FROM ags.spMstrg_2408_ResultSet3;
GO

-- =============================================================================
-- 6. Тест spMstrg_2605: режим saveToTables=0 (Access), ipgSt='12ОПР'
--    Ожидаемый результат: 7 рекордсетов (SELECT с фильтром), ~6 сек
-- =============================================================================
SET NOCOUNT OFF;
EXEC ags.spMstrg_2605
    @ipgCh        = 15,
    @MounthEndDate = '2024-08-31',
    @ipgSt         = N'12ОПР',
    @saveToTables  = 0;
GO
