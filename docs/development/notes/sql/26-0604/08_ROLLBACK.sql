USE [FishEye];
GO

-- =============================================================================
-- Файл:    08_ROLLBACK.sql
-- Пакет:   docs/development/notes/sql/26-0604/
-- Назначение: Откат объектов _2606. Не затрагивает _2605 / _2408 / ResultSet_2408.
-- PercentBrn: DROP покрывает и базовый 05, и патч 05a (календарь fnIpgChDats_2606).
-- Выполнять: в обратном порядке создания (сначала процедуры/функции — по мере появления).
-- =============================================================================

PRINT '=== 08_ROLLBACK: spMstrg_2606 ===';

-- Процедура и функции (добавлять DROP по мере создания объектов в пакете)
IF OBJECT_ID(N'ags.spMstrg_2606', N'P') IS NOT NULL
    DROP PROCEDURE ags.spMstrg_2606;
GO

IF OBJECT_ID(N'ags.spIpgChRsltCstUtlPercentBrn_2606', N'P') IS NOT NULL
    DROP PROCEDURE ags.spIpgChRsltCstUtlPercentBrn_2606;
GO

IF OBJECT_ID(N'ags.fnIpgChRsltCstUtlPercentBrn_2606', N'IF') IS NOT NULL
    DROP FUNCTION ags.fnIpgChRsltCstUtlPercentBrn_2606;
GO

IF OBJECT_ID(N'ags.spIpgChRsltCstUtl2_2606', N'P') IS NOT NULL
    DROP PROCEDURE ags.spIpgChRsltCstUtl2_2606;
GO

IF OBJECT_ID(N'ags.fnIpgChRsltCstUtl2_2606', N'TF') IS NOT NULL
    DROP FUNCTION ags.fnIpgChRsltCstUtl2_2606;
GO

-- Этап 19 (Решение 16): stIpgOutLimPn_2606, TVF универсума
IF OBJECT_ID(N'ags.fnIpgChContractsForStIpg_2606', N'IF') IS NOT NULL
    DROP FUNCTION ags.fnIpgChContractsForStIpg_2606;
GO

IF OBJECT_ID(N'ags.fnCstAgPnTypeChar', N'FN') IS NOT NULL
    DROP FUNCTION ags.fnCstAgPnTypeChar;
GO

IF OBJECT_ID(N'ags.stIpgOutLimPn_2606', N'U') IS NOT NULL
    DROP TABLE ags.stIpgOutLimPn_2606;
GO

IF OBJECT_ID(N'ags.fnMasteringStIpgStCost_2606', N'IF') IS NOT NULL
    DROP FUNCTION ags.fnMasteringStIpgStCost_2606;
GO

IF OBJECT_ID(N'ags.fnMasteringCstAgPnSh_2606', N'TF') IS NOT NULL
    DROP FUNCTION ags.fnMasteringCstAgPnSh_2606;
GO

IF OBJECT_ID(N'ags.fnMasteringCstAgPn_2606', N'TF') IS NOT NULL
    DROP FUNCTION ags.fnMasteringCstAgPn_2606;
GO

-- fnStCost*_2606 (03b0)
IF OBJECT_ID(N'ags.fnStCostMnrl_2606', N'FN') IS NOT NULL
    DROP FUNCTION ags.fnStCostMnrl_2606;
GO
IF OBJECT_ID(N'ags.fnStCostPrDoc_2606', N'FN') IS NOT NULL
    DROP FUNCTION ags.fnStCostPrDoc_2606;
GO
IF OBJECT_ID(N'ags.fnStCostRalp_2606', N'FN') IS NOT NULL
    DROP FUNCTION ags.fnStCostRalp_2606;
GO
IF OBJECT_ID(N'ags.fnStCostAgFee_2606', N'FN') IS NOT NULL
    DROP FUNCTION ags.fnStCostAgFee_2606;
GO
IF OBJECT_ID(N'ags.fnStCostRaCh_2606', N'FN') IS NOT NULL
    DROP FUNCTION ags.fnStCostRaCh_2606;
GO
IF OBJECT_ID(N'ags.fnStCostRa_2606', N'FN') IS NOT NULL
    DROP FUNCTION ags.fnStCostRa_2606;
GO

IF OBJECT_ID(N'ags.fnStCostRsCstAgPn_2606', N'TF') IS NOT NULL
    DROP FUNCTION ags.fnStCostRsCstAgPn_2606;
GO

IF OBJECT_ID(N'ags.fnStCostRsIpgPn_2606', N'TF') IS NOT NULL
    DROP FUNCTION ags.fnStCostRsIpgPn_2606;
GO

IF OBJECT_ID(N'ags.fnStCostIpgPn_2606', N'FN') IS NOT NULL
    DROP FUNCTION ags.fnStCostIpgPn_2606;
GO

IF OBJECT_ID(N'ags.fnIpgChDats_2606', N'IF') IS NOT NULL
    DROP FUNCTION ags.fnIpgChDats_2606;
GO

-- factDoc / factDocCost (01b–01c)
IF OBJECT_ID(N'ags.trgRaSumm_syncFactDoc', N'TR') IS NOT NULL DROP TRIGGER ags.trgRaSumm_syncFactDoc;
GO
IF OBJECT_ID(N'ags.trgRaChangeSumm_syncFactDoc', N'TR') IS NOT NULL DROP TRIGGER ags.trgRaChangeSumm_syncFactDoc;
GO
IF OBJECT_ID(N'ags.trgOgAgFeeP_syncFactDoc', N'TR') IS NOT NULL DROP TRIGGER ags.trgOgAgFeeP_syncFactDoc;
GO
IF OBJECT_ID(N'ags.trgRalpRaAu_syncFactDoc', N'TR') IS NOT NULL DROP TRIGGER ags.trgRalpRaAu_syncFactDoc;
GO
IF OBJECT_ID(N'ags.trgCn_PrDocP_syncFactDoc', N'TR') IS NOT NULL DROP TRIGGER ags.trgCn_PrDocP_syncFactDoc;
GO
IF OBJECT_ID(N'ags.trgCstAgPnMnrl_syncFactDoc', N'TR') IS NOT NULL DROP TRIGGER ags.trgCstAgPnMnrl_syncFactDoc;
GO
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

-- Таблицы ResultSet _2606 (после появления 05b)
IF OBJECT_ID(N'ags.spMstrg_2606_ResultSet7', N'U') IS NOT NULL DROP TABLE ags.spMstrg_2606_ResultSet7;
IF OBJECT_ID(N'ags.spMstrg_2606_ResultSet6', N'U') IS NOT NULL DROP TABLE ags.spMstrg_2606_ResultSet6;
IF OBJECT_ID(N'ags.spMstrg_2606_ResultSet5', N'U') IS NOT NULL DROP TABLE ags.spMstrg_2606_ResultSet5;
IF OBJECT_ID(N'ags.spMstrg_2606_ResultSet4', N'U') IS NOT NULL DROP TABLE ags.spMstrg_2606_ResultSet4;
IF OBJECT_ID(N'ags.spMstrg_2606_ResultSet3', N'U') IS NOT NULL DROP TABLE ags.spMstrg_2606_ResultSet3;
IF OBJECT_ID(N'ags.spMstrg_2606_ResultSet2', N'U') IS NOT NULL DROP TABLE ags.spMstrg_2606_ResultSet2;
IF OBJECT_ID(N'ags.spMstrg_2606_ResultSet1', N'U') IS NOT NULL DROP TABLE ags.spMstrg_2606_ResultSet1;
GO

-- Вычисляемый столбец ссылается на функцию — сначала таблица, потом функция
IF OBJECT_ID(N'ags.ipgChRl_2606', N'U') IS NOT NULL
BEGIN
    PRINT 'DROP TABLE ags.ipgChRl_2606';
    DROP TABLE ags.ipgChRl_2606;
END;
GO

IF OBJECT_ID(N'ags.fnIpgChRlEnd_2606', N'FN') IS NOT NULL
    DROP FUNCTION ags.fnIpgChRlEnd_2606;
GO

-- Удаляем устаревшее представление, если осталось от предыдущей версии скрипта
IF OBJECT_ID(N'ags.vIpgChRl_2606', N'V') IS NOT NULL
    DROP VIEW ags.vIpgChRl_2606;
GO

PRINT '=== 08_ROLLBACK: завершено (объекты _2606 удалены, _2605/_2408 не затронуты) ===';
GO
