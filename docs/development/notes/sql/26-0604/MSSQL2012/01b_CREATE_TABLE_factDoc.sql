USE [FishEye];
GO

-- =============================================================================
-- Файл:    MSSQL2012/01b_CREATE_TABLE_factDoc.sql
-- Пакет:   docs/development/notes/sql/26-0604/
-- Назначение: ags.factDoc + ags.factDocCost + колонки *_fdKey (Решение 9).
--   Совместимость: SQL Server 2012 SP4 (11.0.7507.2). Без DROP IF EXISTS.
-- Автор:   Александр
-- Дата:    2026-06-05
-- =============================================================================

PRINT '=== 01b MSSQL2012: factDoc + factDocCost ===';

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
    DROP TABLE ags.factDocCost;
GO

IF OBJECT_ID(N'ags.factDoc', N'U') IS NOT NULL
    DROP TABLE ags.factDoc;
GO

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

-- Описания MS_Description (SSMS / DBeaver)
EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Суперкласс документа факта (spMstrg_2606). Тип подкласса + ключ строки в таблице-источнике.',
    @level0type = N'SCHEMA', @level0name = N'ags',
    @level1type = N'TABLE',  @level1name = N'factDoc';
GO
EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Разбивка сумм документа факта по пунктам структуры затрат (stCost). Источник для fnStCost*_2606.',
    @level0type = N'SCHEMA', @level0name = N'ags',
    @level1type = N'TABLE',  @level1name = N'factDocCost';
GO

PRINT '=== 01b MSSQL2012: завершено ===';
GO
