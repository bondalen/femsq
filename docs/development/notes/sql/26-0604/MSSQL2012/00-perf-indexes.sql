USE [FishEye];
GO

-- =============================================================================
-- Файл:    00-perf-indexes.sql
-- Пакет:   docs/development/notes/sql/26-0604/
-- Назначение: П4 — индексы производительности (нулевой риск, нет изменений кода).
--   IX_ipgStPn_St_Pn: для EXISTS в fnMasteringStIpgStCost_2606.
--   IX_cstAgPnBranch_Cst: для fnCstAgPnBranch + CTE-кэша (П3 в fn2_2606 MSTVF).
-- Источник:  07-performance-analysis.md §3 (УМ-5) и §4 (П4).
-- Применять: до Этапа 8 (fnMasteringFact*_2606).
-- Автор:   Александр
-- Дата:    2026-06-11
-- =============================================================================

PRINT '=== 00-perf-indexes.sql: создание индексов производительности ===';
GO

-- -----------------------------------------------------------------------------
-- П4.1 — Индекс для DAG-фильтрации в fnMasteringStIpgStCost_2606
-- WHERE ipgspSt = @ipgStKey AND ipgspPn = pn.iuplpKey
-- -----------------------------------------------------------------------------
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_ipgStPn_St_Pn'
      AND object_id = OBJECT_ID(N'ags.ipgStPn')
)
BEGIN
    CREATE INDEX IX_ipgStPn_St_Pn ON ags.ipgStPn (ipgspSt, ipgspPn);
    PRINT '  IX_ipgStPn_St_Pn создан';
END
ELSE
    PRINT '  IX_ipgStPn_St_Pn уже существует';
GO

-- -----------------------------------------------------------------------------
-- П4.2 — Индекс для fnCstAgPnBranch + будущего CTE-кэша (Этап 9, П3)
-- WHERE cstapbCstAgPn = @key AND (cstapbEnd IS NULL OR cstapbEnd >= ...) AND ...
-- -----------------------------------------------------------------------------
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_cstAgPnBranch_Cst'
      AND object_id = OBJECT_ID(N'ags.cstAgPnBranch')
)
BEGIN
    CREATE INDEX IX_cstAgPnBranch_Cst ON ags.cstAgPnBranch
        (cstapbCstAgPn) INCLUDE (cstapbBranch, cstapbStart, cstapbEnd);
    PRINT '  IX_cstAgPnBranch_Cst создан';
END
ELSE
    PRINT '  IX_cstAgPnBranch_Cst уже существует';
GO

PRINT '=== 00-perf-indexes.sql: завершено ===';
GO
