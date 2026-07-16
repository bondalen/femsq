-- =============================================================================
-- Файл:    05_ROLLBACK.sql
-- Пакет:   docs/development/notes/sql/26-0714/
-- Назначение: Откат колонок ralprtRow / ralprsRow (если Stage 1 ещё не пишет в них).
-- Внимание: на prod выполнять только при согласованном откате задачи 0051.
-- =============================================================================

PRINT '=== 05_ROLLBACK: drop ralprtRow / ralprsRow ===';

IF COL_LENGTH(N'ags.ra_stg_ralp', N'ralprtRow') IS NOT NULL
BEGIN
    ALTER TABLE ags.ra_stg_ralp DROP COLUMN ralprtRow;
    PRINT 'Dropped ags.ra_stg_ralp.ralprtRow';
END
ELSE
    PRINT 'Skip: ags.ra_stg_ralp.ralprtRow absent';

IF COL_LENGTH(N'ags.ra_stg_ralp_sm', N'ralprsRow') IS NOT NULL
BEGIN
    ALTER TABLE ags.ra_stg_ralp_sm DROP COLUMN ralprsRow;
    PRINT 'Dropped ags.ra_stg_ralp_sm.ralprsRow';
END
ELSE
    PRINT 'Skip: ags.ra_stg_ralp_sm.ralprsRow absent';

PRINT '=== 05_ROLLBACK: готово ===';
