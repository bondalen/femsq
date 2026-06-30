USE [FishEye];
GO

-- =============================================================================
-- Файл:    01b_MIGRATE_naming_21_1.sql
-- Пакет:   docs/development/notes/sql/26-0604/
-- Назначение: Переименование объектов этапа 21.1 на существующей dev-БД
--   (данные ipgChRl_2606 / stIpgOutLimPn_2606 сохраняются).
--   После скрипта — переприменить 02, 03a–03d, 04, 05, 05a, 10d (CREATE OR ALTER).
-- Идемпотентность: пропуск, если новые имена уже есть.
-- Автор:   Александр
-- Дата:    2026-06-30
-- =============================================================================

PRINT N'=== 01b: MIGRATE naming 21.1 ===';
GO

-- -----------------------------------------------------------------------------
-- 1. ipgChRlV → ipgChRl_2606 + fnIpgChRlVEnd → fnIpgChRlEnd_2606
-- -----------------------------------------------------------------------------
IF OBJECT_ID(N'ags.ipgChRl_2606', N'U') IS NOT NULL
    PRINT N'ags.ipgChRl_2606 уже существует — шаг 1 пропущен.';
ELSE IF OBJECT_ID(N'ags.ipgChRlV', N'U') IS NOT NULL
BEGIN
    PRINT N'Переименование ipgChRlV → ipgChRl_2606...';

    IF COL_LENGTH(N'ags.ipgChRlV', N'ipgcrvEnd') IS NOT NULL
    BEGIN
        PRINT N'  DROP computed ipgcrvEnd';
        ALTER TABLE ags.ipgChRlV DROP COLUMN ipgcrvEnd;
    END;

    IF OBJECT_ID(N'ags.fnIpgChRlVEnd', N'FN') IS NOT NULL
    BEGIN
        PRINT N'  sp_rename fnIpgChRlVEnd → fnIpgChRlEnd_2606';
        EXEC sp_rename N'ags.fnIpgChRlVEnd', N'fnIpgChRlEnd_2606', N'OBJECT';
    END;

    PRINT N'  sp_rename ipgChRlV → ipgChRl_2606';
    EXEC sp_rename N'ags.ipgChRlV', N'ipgChRl_2606', N'OBJECT';

    PRINT N'  ADD computed ipgcrvEnd';
    ALTER TABLE ags.ipgChRl_2606
        ADD ipgcrvEnd AS (ags.fnIpgChRlEnd_2606(ipgcrvChain, ipgcrvStr));
END
ELSE
    PRINT N'ags.ipgChRlV не найдена — шаг 1 пропущен (примените 01).';
GO

-- -----------------------------------------------------------------------------
-- 2. fnIpgChDatsV → fnIpgChDats_2606
-- -----------------------------------------------------------------------------
IF OBJECT_ID(N'ags.fnIpgChDats_2606', N'IF') IS NOT NULL
    PRINT N'ags.fnIpgChDats_2606 уже существует — шаг 2 пропущен.';
ELSE IF OBJECT_ID(N'ags.fnIpgChDatsV', N'IF') IS NOT NULL
BEGIN
    PRINT N'sp_rename fnIpgChDatsV → fnIpgChDats_2606';
    EXEC sp_rename N'ags.fnIpgChDatsV', N'fnIpgChDats_2606', N'OBJECT';
END
ELSE
    PRINT N'fnIpgChDatsV не найдена — шаг 2 пропущен (примените 02).';
GO

-- -----------------------------------------------------------------------------
-- 3. stIpgOutLimPn → stIpgOutLimPn_2606
-- -----------------------------------------------------------------------------
IF OBJECT_ID(N'ags.stIpgOutLimPn_2606', N'U') IS NOT NULL
    PRINT N'ags.stIpgOutLimPn_2606 уже существует — шаг 3 пропущен.';
ELSE IF OBJECT_ID(N'ags.stIpgOutLimPn', N'U') IS NOT NULL
BEGIN
    PRINT N'sp_rename stIpgOutLimPn → stIpgOutLimPn_2606';
    EXEC sp_rename N'ags.stIpgOutLimPn', N'stIpgOutLimPn_2606', N'OBJECT';
END
ELSE
    PRINT N'stIpgOutLimPn не найдена — шаг 3 пропущен (примените 10a).';
GO

-- -----------------------------------------------------------------------------
-- Проверка
-- -----------------------------------------------------------------------------
PRINT N'--- Объекты после 01b ---';
SELECT name, type_desc
FROM sys.objects
WHERE schema_id = SCHEMA_ID(N'ags')
  AND name IN (
      N'ipgChRl_2606', N'fnIpgChRlEnd_2606', N'fnIpgChDats_2606', N'stIpgOutLimPn_2606',
      N'ipgChRlV', N'fnIpgChRlVEnd', N'fnIpgChDatsV', N'stIpgOutLimPn'
  )
ORDER BY name;
GO

PRINT N'=== 01b: завершено. Перепримените 02, 03a–03d, 04, 05, 05a, 10d. ===';
GO
