USE [FishEye];
GO

-- =============================================================================
-- Файл:    MSSQL2012/00-perf-indexes-k7.sql
-- Пакет:   docs/development/notes/sql/26-0604/
-- Назначение: зеркало 00-perf-indexes-k7.sql для SQL Server 2012 SP4 (продуктив).
-- Автор:   Александр | Дата: 2026-06-15
-- =============================================================================

PRINT '=== 00-perf-indexes-k7.sql: индексы К-7 (этап 14.1) ===';
GO

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
