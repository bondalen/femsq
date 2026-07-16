-- =============================================================================
-- Файл:    01_ALTER_ra_stg_excel_row.sql
-- Пакет:   docs/development/notes/sql/26-0714/
-- Назначение: Добавить номер строки Excel (1-based) в staging type=3.
-- Совместимость: SQL Server 2012 SP4+
-- =============================================================================

PRINT '=== 01_ALTER: ralprtRow / ralprsRow ===';

IF COL_LENGTH(N'ags.ra_stg_ralp', N'ralprtRow') IS NULL
BEGIN
    ALTER TABLE ags.ra_stg_ralp
        ADD ralprtRow INT NULL;
    PRINT 'Added ags.ra_stg_ralp.ralprtRow';
END
ELSE
    PRINT 'Skip: ags.ra_stg_ralp.ralprtRow already exists';

IF COL_LENGTH(N'ags.ra_stg_ralp_sm', N'ralprsRow') IS NULL
BEGIN
    ALTER TABLE ags.ra_stg_ralp_sm
        ADD ralprsRow INT NULL;
    PRINT 'Added ags.ra_stg_ralp_sm.ralprsRow';
END
ELSE
    PRINT 'Skip: ags.ra_stg_ralp_sm.ralprsRow already exists';

PRINT '=== 01_ALTER: готово ===';
