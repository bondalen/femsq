-- =============================================
-- Создание таблицы ags.spMstrg_2408_ResultSet7
-- Структура идентична spMstrg_2408_ResultSet6 (51 столбец)
-- Создано: 2025-12-05
-- =============================================

USE FishEye;
GO

-- Удаляем таблицу если существует
IF OBJECT_ID('ags.spMstrg_2408_ResultSet7', 'U') IS NOT NULL
    DROP TABLE ags.spMstrg_2408_ResultSet7;
GO

-- Создаём таблицу ResultSet7
CREATE TABLE ags.spMstrg_2408_ResultSet7
(
    ipgSh nvarchar(50) NULL,
    limSort money NULL,
    ogNm nvarchar(255) NULL,
    branchName nvarchar(255) NULL,
    lim money NULL,
    ag_lim money NULL,
    ag_Ful_OverFul money NULL,
    ag_LimPc money NULL,
    ag_PlOverLimit_ money NULL,
    iv_lim money NULL,
    uk_lim money NULL,
    ag_PlAccum money NULL,
    ag_PlFulfillment money NULL,
    ag_PlPz float NULL,
    ag_PlOverFulfillment money NULL,
    ag_PlPercent float NULL,
    ag_PlFulfillmentAll money NULL,
    ag_Pl_M money NULL,
    ag_acceptedTtl_M money NULL,
    ag_acceptedNot money NULL,
    ag_PlPz_M float NULL,
    mn nvarchar(50) NULL,
    cstAgPnCode nvarchar(255) NULL,
    ag_accepted money NULL,
    ag_acceptedAccum money NULL,
    ag_agFeeAccepted money NULL,
    ag_agFeeAcceptedAccum money NULL,
    ag_acceptedRalp money NULL,
    ag_acceptedRalpAccum money NULL,
    ag_storageSum money NULL,
    ag_storageSumAccum money NULL,
    ag_cctSum money NULL,
    ag_cctSumAccum money NULL,
    ag_MnrlSum money NULL,
    ag_MnrlSumAccum money NULL,
    np_lim money NULL,
    np_iShKey int NULL,
    np_accepted money NULL,
    np_acceptedAccum money NULL,
    np_agFeeAccepted money NULL,
    np_agFeeAcceptedAccum money NULL,
    np_acceptedRalp money NULL,
    np_acceptedRalpAccum money NULL,
    np_storageSum money NULL,
    np_storageSumAccum money NULL,
    np_cctSum money NULL,
    np_cctSumAccum money NULL,
    np_MnrlSum money NULL,
    np_MnrlSumAccum money NULL,
    np_acceptedTtl money NULL,
    np_acceptedTtlAccum money NULL
);
GO

PRINT 'Таблица ags.spMstrg_2408_ResultSet7 успешно создана';
GO

