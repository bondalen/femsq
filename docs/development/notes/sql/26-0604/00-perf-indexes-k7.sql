USE [FishEye];
GO

-- =============================================================================
-- Файл:    00-perf-indexes-k7.sql
-- Пакет:   docs/development/notes/sql/26-0604/
-- Назначение: П4b / Этап 14.1 — индексы FK для закрытия К-7 строгой.
--   Устраняют повторные table scan в fnMasteringRaCostBase_2606,
--   fnMasteringRalpBundle_2606, fnMasteringPrDocMnrlBundle_2606 (680× на цепи 5).
-- Источник:  07-performance-analysis.md §9 (УМ-7), §10 (Ступень 1).
-- Предусловия: 00-perf-indexes.sql (П4) применён.
-- Применять: до Ступени 2 (CostBase Ralp/PrDoc).
-- Автор:   Александр
-- Дата:    2026-06-15
-- =============================================================================

PRINT '=== 00-perf-indexes-k7.sql: индексы К-7 (этап 14.1) ===';
GO

-- -----------------------------------------------------------------------------
-- K7.1 — ags.ra по контракту (fnMasteringRaCostBase_2606: WHERE ra_cac = @cstAgPn)
-- Без индекса: ~49K scan × 680 вызовов на полной цепи.
-- -----------------------------------------------------------------------------
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_ra_cac'
      AND object_id = OBJECT_ID(N'ags.ra')
)
BEGIN
    CREATE INDEX IX_ra_cac ON ags.ra (ra_cac);
    PRINT '  IX_ra_cac создан';
END
ELSE
    PRINT '  IX_ra_cac уже существует';
GO

-- -----------------------------------------------------------------------------
-- K7.2 — ags.ra_change → ags.ra (JOIN по raс_ra)
-- -----------------------------------------------------------------------------
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_ra_change_rac_ra'
      AND object_id = OBJECT_ID(N'ags.ra_change')
)
BEGIN
    CREATE INDEX IX_ra_change_rac_ra ON ags.ra_change (raс_ra);
    PRINT '  IX_ra_change_rac_ra создан';
END
ELSE
    PRINT '  IX_ra_change_rac_ra уже существует';
GO

-- -----------------------------------------------------------------------------
-- K7.3 — batch lookup ras_fdKey (fnMasteringRaCostBase_2606, ROW_NUMBER по ras_ra)
-- -----------------------------------------------------------------------------
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_ra_summ_ras_ra'
      AND object_id = OBJECT_ID(N'ags.ra_summ')
)
BEGIN
    CREATE INDEX IX_ra_summ_ras_ra ON ags.ra_summ (ras_ra)
        INCLUDE (ras_fdKey, ras_date, ras_key);
    PRINT '  IX_ra_summ_ras_ra создан';
END
ELSE
    PRINT '  IX_ra_summ_ras_ra уже существует';
GO

-- -----------------------------------------------------------------------------
-- K7.4 — fnMasteringRalpBundle_2606 (WHERE ralpCstAgPn = @cstAgPn), 17× на контракт
-- ags.ralp — VIEW (ralpRa ⨝ ralpRaAu); индекс на базовой таблице ralpRa.
-- -----------------------------------------------------------------------------
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_ralpRa_cac'
      AND object_id = OBJECT_ID(N'ags.ralpRa')
)
BEGIN
    CREATE INDEX IX_ralpRa_cac ON ags.ralpRa (ralprCstAgPn);
    PRINT '  IX_ralpRa_cac создан';
END
ELSE
    PRINT '  IX_ralpRa_cac уже существует';
GO

-- -----------------------------------------------------------------------------
-- K7.5 — fnMasteringPrDocMnrlBundle_2606 / @raFactPrDoc (pdpCstAgPn)
-- -----------------------------------------------------------------------------
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_cn_PrDocP_cac'
      AND object_id = OBJECT_ID(N'ags.cn_PrDocP')
)
BEGIN
    CREATE INDEX IX_cn_PrDocP_cac ON ags.cn_PrDocP (pdpCstAgPn);
    PRINT '  IX_cn_PrDocP_cac создан';
END
ELSE
    PRINT '  IX_cn_PrDocP_cac уже существует';
GO

-- -----------------------------------------------------------------------------
-- K7.6 — fnMasteringPrDocMnrlBundle_2606 (amCstAgPn)
-- -----------------------------------------------------------------------------
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_cstAgPnMnrl_cac'
      AND object_id = OBJECT_ID(N'ags.cstAgPnMnrl')
)
BEGIN
    CREATE INDEX IX_cstAgPnMnrl_cac ON ags.cstAgPnMnrl (amCstAgPn);
    PRINT '  IX_cstAgPnMnrl_cac создан';
END
ELSE
    PRINT '  IX_cstAgPnMnrl_cac уже существует';
GO

PRINT '=== 00-perf-indexes-k7.sql: завершено ===';
GO
