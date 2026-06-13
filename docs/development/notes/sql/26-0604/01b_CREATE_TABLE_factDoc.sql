USE [FishEye];
GO

-- =============================================================================
-- Файл:    01b_CREATE_TABLE_factDoc.sql
-- Пакет:   docs/development/notes/sql/26-0604/
-- Назначение: Суперкласс документов факта (Решение 9, шаг 1).
--   ags.factDoc      — идентификатор + тип подкласса + ключ строки подкласса
--   ags.factDocCost  — разбивка сумм по stCost (fdcoFd, fdcoStCost, fdcoSumm)
--   Колонки *_fdKey в шести таблицах-подклассах (NULL до бэкфилла / триггеров)
-- Автор:   Александр
-- Дата:    2026-06-05
-- =============================================================================

PRINT '=== 01b: CREATE TABLE ags.factDoc + ags.factDocCost + *_fdKey ===';

-- -----------------------------------------------------------------------------
-- Перепрогон: снять FK подклассов → factDoc, затем дочерние таблицы
-- -----------------------------------------------------------------------------
IF OBJECT_ID(N'ags.FK_ra_summ_factDoc', N'F') IS NOT NULL
    ALTER TABLE ags.ra_summ DROP CONSTRAINT FK_ra_summ_factDoc;
GO
IF OBJECT_ID(N'ags.FK_ra_change_summ_factDoc', N'F') IS NOT NULL
    ALTER TABLE ags.ra_change_summ DROP CONSTRAINT FK_ra_change_summ_factDoc;
GO
IF OBJECT_ID(N'ags.FK_ogAgFeeP_factDoc', N'F') IS NOT NULL
    ALTER TABLE ags.ogAgFeeP DROP CONSTRAINT FK_ogAgFeeP_factDoc;
GO
IF OBJECT_ID(N'ags.FK_ralpRaAu_factDoc', N'F') IS NOT NULL
    ALTER TABLE ags.ralpRaAu DROP CONSTRAINT FK_ralpRaAu_factDoc;
GO
IF OBJECT_ID(N'ags.FK_cn_PrDocP_factDoc', N'F') IS NOT NULL
    ALTER TABLE ags.cn_PrDocP DROP CONSTRAINT FK_cn_PrDocP_factDoc;
GO
IF OBJECT_ID(N'ags.FK_cstAgPnMnrl_factDoc', N'F') IS NOT NULL
    ALTER TABLE ags.cstAgPnMnrl DROP CONSTRAINT FK_cstAgPnMnrl_factDoc;
GO

IF OBJECT_ID(N'ags.factDocCost', N'U') IS NOT NULL
BEGIN
    PRINT 'DROP ags.factDocCost...';
    DROP TABLE ags.factDocCost;
END;
GO

IF OBJECT_ID(N'ags.factDoc', N'U') IS NOT NULL
BEGIN
    PRINT 'DROP ags.factDoc...';
    DROP TABLE ags.factDoc;
END;
GO

-- -----------------------------------------------------------------------------
-- Шаг 1: ags.factDoc
-- -----------------------------------------------------------------------------
CREATE TABLE ags.factDoc
(
    fdKey      int           NOT NULL IDENTITY(1, 1),
    fdDocType  nvarchar(32)  NOT NULL,
    fdNKey     int           NOT NULL,
    CONSTRAINT PK_factDoc              PRIMARY KEY CLUSTERED (fdKey),
    CONSTRAINT UQ_factDoc_type_nkey    UNIQUE (fdDocType, fdNKey),
    CONSTRAINT CK_factDoc_type CHECK (fdDocType IN (
        N'RaSumm', N'RaChangeSumm', N'OgAgFeeP', N'RalpRaAu', N'PrDocP', N'CstAgPnMnrl'
    ))
);
GO

PRINT 'Таблица ags.factDoc создана.';
GO

-- -----------------------------------------------------------------------------
-- Шаг 2: ags.factDocCost
-- -----------------------------------------------------------------------------
CREATE TABLE ags.factDocCost
(
    fdcoKey     int    NOT NULL IDENTITY(1, 1),
    fdcoFd      int    NOT NULL,
    fdcoStCost  int    NOT NULL,
    fdcoSumm    money  NOT NULL,
    CONSTRAINT PK_factDocCost                 PRIMARY KEY CLUSTERED (fdcoKey),
    CONSTRAINT UQ_factDocCost_fd_stcost       UNIQUE (fdcoFd, fdcoStCost),
    CONSTRAINT FK_factDocCost_factDoc FOREIGN KEY (fdcoFd)
        REFERENCES ags.factDoc (fdKey) ON DELETE CASCADE,
    CONSTRAINT FK_factDocCost_stCost FOREIGN KEY (fdcoStCost)
        REFERENCES ags.stCost (stcKey)
);
GO

PRINT 'Таблица ags.factDocCost создана.';
GO

-- -----------------------------------------------------------------------------
-- Шаг 3: колонки *_fdKey в подклассах (идемпотентно)
-- -----------------------------------------------------------------------------
IF COL_LENGTH('ags.ra_summ', 'ras_fdKey') IS NULL
    ALTER TABLE ags.ra_summ ADD ras_fdKey int NULL;
GO

IF COL_LENGTH('ags.ra_change_summ', 'racs_fdKey') IS NULL
    ALTER TABLE ags.ra_change_summ ADD racs_fdKey int NULL;
GO

IF COL_LENGTH('ags.ogAgFeeP', 'oafp_fdKey') IS NULL
    ALTER TABLE ags.ogAgFeeP ADD oafp_fdKey int NULL;
GO

IF COL_LENGTH('ags.ralpRaAu', 'ralpra_fdKey') IS NULL
    ALTER TABLE ags.ralpRaAu ADD ralpra_fdKey int NULL;
GO

IF COL_LENGTH('ags.cn_PrDocP', 'pdp_fdKey') IS NULL
    ALTER TABLE ags.cn_PrDocP ADD pdp_fdKey int NULL;
GO

IF COL_LENGTH('ags.cstAgPnMnrl', 'am_fdKey') IS NULL
    ALTER TABLE ags.cstAgPnMnrl ADD am_fdKey int NULL;
GO

PRINT 'Колонки *_fdKey добавлены (или уже существовали).';
GO

-- -----------------------------------------------------------------------------
-- Шаг 4: FK подклассов → factDoc (без CASCADE — подкласс владеет связью)
-- -----------------------------------------------------------------------------
ALTER TABLE ags.ra_summ
    ADD CONSTRAINT FK_ra_summ_factDoc FOREIGN KEY (ras_fdKey)
        REFERENCES ags.factDoc (fdKey);
GO

ALTER TABLE ags.ra_change_summ
    ADD CONSTRAINT FK_ra_change_summ_factDoc FOREIGN KEY (racs_fdKey)
        REFERENCES ags.factDoc (fdKey);
GO

ALTER TABLE ags.ogAgFeeP
    ADD CONSTRAINT FK_ogAgFeeP_factDoc FOREIGN KEY (oafp_fdKey)
        REFERENCES ags.factDoc (fdKey);
GO

ALTER TABLE ags.ralpRaAu
    ADD CONSTRAINT FK_ralpRaAu_factDoc FOREIGN KEY (ralpra_fdKey)
        REFERENCES ags.factDoc (fdKey);
GO

ALTER TABLE ags.cn_PrDocP
    ADD CONSTRAINT FK_cn_PrDocP_factDoc FOREIGN KEY (pdp_fdKey)
        REFERENCES ags.factDoc (fdKey);
GO

ALTER TABLE ags.cstAgPnMnrl
    ADD CONSTRAINT FK_cstAgPnMnrl_factDoc FOREIGN KEY (am_fdKey)
        REFERENCES ags.factDoc (fdKey);
GO

PRINT 'FK подклассов → factDoc созданы.';
GO

-- -----------------------------------------------------------------------------
-- Шаг 5: краткие описания (MS_Description) — видны в SSMS / DBeaver
-- -----------------------------------------------------------------------------
EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Суперкласс документа факта (spMstrg_2606). Тип подкласса + ключ строки в таблице-источнике.',
    @level0type = N'SCHEMA', @level0name = N'ags',
    @level1type = N'TABLE',  @level1name = N'factDoc';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Суррогатный ключ документа факта',
    @level0type = N'SCHEMA', @level0name = N'ags', @level1type = N'TABLE', @level1name = N'factDoc',
    @level2type = N'COLUMN', @level2name = N'fdKey';
GO
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Тип подкласса: RaSumm, RaChangeSumm, OgAgFeeP, RalpRaAu, PrDocP, CstAgPnMnrl',
    @level0type = N'SCHEMA', @level0name = N'ags', @level1type = N'TABLE', @level1name = N'factDoc',
    @level2type = N'COLUMN', @level2name = N'fdDocType';
GO
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'PK строки в таблице-подклассе (ras_key, oafpKey, …)',
    @level0type = N'SCHEMA', @level0name = N'ags', @level1type = N'TABLE', @level1name = N'factDoc',
    @level2type = N'COLUMN', @level2name = N'fdNKey';
GO

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Разбивка сумм документа факта по пунктам структуры затрат (stCost). Источник для fnStCost*_2606.',
    @level0type = N'SCHEMA', @level0name = N'ags',
    @level1type = N'TABLE',  @level1name = N'factDocCost';
GO

EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'FK → factDoc.fdKey',
    @level0type = N'SCHEMA', @level0name = N'ags', @level1type = N'TABLE', @level1name = N'factDocCost',
    @level2type = N'COLUMN', @level2name = N'fdcoFd';
GO
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'FK → stCost.stcKey',
    @level0type = N'SCHEMA', @level0name = N'ags', @level1type = N'TABLE', @level1name = N'factDocCost',
    @level2type = N'COLUMN', @level2name = N'fdcoStCost';
GO
EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'Сумма по пункту структуры затрат',
    @level0type = N'SCHEMA', @level0name = N'ags', @level1type = N'TABLE', @level1name = N'factDocCost',
    @level2type = N'COLUMN', @level2name = N'fdcoSumm';
GO

-- Колонки *_fdKey в подклассах (идемпотентно: add или update)
IF NOT EXISTS (
    SELECT 1 FROM fn_listextendedproperty(N'MS_Description', N'schema', N'ags', N'table', N'ra_summ', N'column', N'ras_fdKey')
)
    EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'FK → factDoc (суммы ОА; синхронизация factDocCost через триггер)',
        @level0type = N'SCHEMA', @level0name = N'ags', @level1type = N'TABLE', @level1name = N'ra_summ',
        @level2type = N'COLUMN', @level2name = N'ras_fdKey';
ELSE
    EXEC sys.sp_updateextendedproperty @name = N'MS_Description', @value = N'FK → factDoc (суммы ОА; синхронизация factDocCost через триггер)',
        @level0type = N'SCHEMA', @level0name = N'ags', @level1type = N'TABLE', @level1name = N'ra_summ',
        @level2type = N'COLUMN', @level2name = N'ras_fdKey';
GO

IF NOT EXISTS (
    SELECT 1 FROM fn_listextendedproperty(N'MS_Description', N'schema', N'ags', N'table', N'ra_change_summ', N'column', N'racs_fdKey')
)
    EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'FK → factDoc (суммы изменения ОА)',
        @level0type = N'SCHEMA', @level0name = N'ags', @level1type = N'TABLE', @level1name = N'ra_change_summ',
        @level2type = N'COLUMN', @level2name = N'racs_fdKey';
ELSE
    EXEC sys.sp_updateextendedproperty @name = N'MS_Description', @value = N'FK → factDoc (суммы изменения ОА)',
        @level0type = N'SCHEMA', @level0name = N'ags', @level1type = N'TABLE', @level1name = N'ra_change_summ',
        @level2type = N'COLUMN', @level2name = N'racs_fdKey';
GO

IF NOT EXISTS (
    SELECT 1 FROM fn_listextendedproperty(N'MS_Description', N'schema', N'ags', N'table', N'ogAgFeeP', N'column', N'oafp_fdKey')
)
    EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'FK → factDoc (пункт акта агентского вознаграждения)',
        @level0type = N'SCHEMA', @level0name = N'ags', @level1type = N'TABLE', @level1name = N'ogAgFeeP',
        @level2type = N'COLUMN', @level2name = N'oafp_fdKey';
ELSE
    EXEC sys.sp_updateextendedproperty @name = N'MS_Description', @value = N'FK → factDoc (пункт акта агентского вознаграждения)',
        @level0type = N'SCHEMA', @level0name = N'ags', @level1type = N'TABLE', @level1name = N'ogAgFeeP',
        @level2type = N'COLUMN', @level2name = N'oafp_fdKey';
GO

IF NOT EXISTS (
    SELECT 1 FROM fn_listextendedproperty(N'MS_Description', N'schema', N'ags', N'table', N'ralpRaAu', N'column', N'ralpra_fdKey')
)
    EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'FK → factDoc (аренда земельных участков)',
        @level0type = N'SCHEMA', @level0name = N'ags', @level1type = N'TABLE', @level1name = N'ralpRaAu',
        @level2type = N'COLUMN', @level2name = N'ralpra_fdKey';
ELSE
    EXEC sys.sp_updateextendedproperty @name = N'MS_Description', @value = N'FK → factDoc (аренда земельных участков)',
        @level0type = N'SCHEMA', @level0name = N'ags', @level1type = N'TABLE', @level1name = N'ralpRaAu',
        @level2type = N'COLUMN', @level2name = N'ralpra_fdKey';
GO

IF NOT EXISTS (
    SELECT 1 FROM fn_listextendedproperty(N'MS_Description', N'schema', N'ags', N'table', N'cn_PrDocP', N'column', N'pdp_fdKey')
)
    EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'FK → factDoc (проводка первичного документа: хранение, ССК)',
        @level0type = N'SCHEMA', @level0name = N'ags', @level1type = N'TABLE', @level1name = N'cn_PrDocP',
        @level2type = N'COLUMN', @level2name = N'pdp_fdKey';
ELSE
    EXEC sys.sp_updateextendedproperty @name = N'MS_Description', @value = N'FK → factDoc (проводка первичного документа: хранение, ССК)',
        @level0type = N'SCHEMA', @level0name = N'ags', @level1type = N'TABLE', @level1name = N'cn_PrDocP',
        @level2type = N'COLUMN', @level2name = N'pdp_fdKey';
GO

IF NOT EXISTS (
    SELECT 1 FROM fn_listextendedproperty(N'MS_Description', N'schema', N'ags', N'table', N'cstAgPnMnrl', N'column', N'am_fdKey')
)
    EXEC sys.sp_addextendedproperty @name = N'MS_Description', @value = N'FK → factDoc (проводки ОПИ / материалы)',
        @level0type = N'SCHEMA', @level0name = N'ags', @level1type = N'TABLE', @level1name = N'cstAgPnMnrl',
        @level2type = N'COLUMN', @level2name = N'am_fdKey';
ELSE
    EXEC sys.sp_updateextendedproperty @name = N'MS_Description', @value = N'FK → factDoc (проводки ОПИ / материалы)',
        @level0type = N'SCHEMA', @level0name = N'ags', @level1type = N'TABLE', @level1name = N'cstAgPnMnrl',
        @level2type = N'COLUMN', @level2name = N'am_fdKey';
GO

PRINT 'Описания MS_Description добавлены.';
GO

-- -----------------------------------------------------------------------------
-- Проверка: структура factDoc / factDocCost
-- -----------------------------------------------------------------------------
PRINT '--- Структура ags.factDoc ---';
SELECT c.name, t.name AS type_name, c.is_nullable
FROM sys.columns c
JOIN sys.types t ON t.user_type_id = c.user_type_id
WHERE c.object_id = OBJECT_ID(N'ags.factDoc')
ORDER BY c.column_id;
GO

PRINT '--- Структура ags.factDocCost ---';
SELECT c.name, t.name AS type_name, c.is_nullable
FROM sys.columns c
JOIN sys.types t ON t.user_type_id = c.user_type_id
WHERE c.object_id = OBJECT_ID(N'ags.factDocCost')
ORDER BY c.column_id;
GO

PRINT '--- Колонки *_fdKey в подклассах ---';
SELECT
    OBJECT_NAME(c.object_id) AS table_name,
    c.name AS column_name
FROM sys.columns c
WHERE c.object_id IN (
    OBJECT_ID(N'ags.ra_summ'),
    OBJECT_ID(N'ags.ra_change_summ'),
    OBJECT_ID(N'ags.ogAgFeeP'),
    OBJECT_ID(N'ags.ralpRaAu'),
    OBJECT_ID(N'ags.cn_PrDocP'),
    OBJECT_ID(N'ags.cstAgPnMnrl')
)
AND c.name LIKE '%_fdKey'
ORDER BY table_name;
GO

PRINT '=== 01b: завершено ===';
GO
