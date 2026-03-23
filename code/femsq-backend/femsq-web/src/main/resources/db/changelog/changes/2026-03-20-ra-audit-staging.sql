--liquibase formatted sql

--changeset femsq:2026-03-20-ra-execution runOnChange:false
IF OBJECT_ID(N'ags.ra_execution', N'U') IS NULL
BEGIN
    CREATE TABLE ags.ra_execution (
        exec_key INT IDENTITY(1,1) NOT NULL,
        exec_adt_key INT NOT NULL,
        exec_status NVARCHAR(20) NOT NULL,
        exec_add_ra BIT NOT NULL,
        exec_started DATETIME2 NULL,
        exec_finished DATETIME2 NULL,
        exec_error NVARCHAR(MAX) NULL,
        CONSTRAINT PK_ra_execution PRIMARY KEY (exec_key)
    );
END;

--changeset femsq:2026-03-20-ra-staging-tables runOnChange:false
IF OBJECT_ID(N'ags.ra_stg_ra', N'U') IS NULL
BEGIN
    CREATE TABLE ags.ra_stg_ra (
        rain_key INT IDENTITY(1,1) NOT NULL,
        rain_exec_key INT NULL,
        rainRow INT NULL,
        rainRaNum NVARCHAR(100) NOT NULL,
        rainRaDate DATE NULL,
        rainSign NVARCHAR(50) NULL,
        rainCstAgPnStr NVARCHAR(100) NULL,
        rainCstName NVARCHAR(255) NULL,
        rainSender NVARCHAR(255) NULL,
        rainTtl MONEY NULL,
        rainWork MONEY NULL,
        rainEquip MONEY NULL,
        rainOthers MONEY NULL,
        rainArrivedNum NVARCHAR(255) NULL,
        rainArrivedDate DATE NULL,
        rainArrivedDateFact DATE NULL,
        rainReturnedNum NVARCHAR(255) NULL,
        rainReturnedDate DATE NULL,
        rainReturnedReason NVARCHAR(500) NULL,
        rainSendNum NVARCHAR(255) NULL,
        rainSendDate DATE NULL,
        rainUnit NVARCHAR(255) NULL,
        rainRaSheetsNumber INT NULL,
        rainTitleDocSheetsNumber INT NULL,
        rainPlanNumber INT NULL,
        rainPlanDate DATE NULL,
        rainRaSignOfTest NVARCHAR(50) NULL,
        rainRaSendedSum MONEY NULL,
        rainRaReturnedSum MONEY NULL,
        CONSTRAINT PK_ra_stg_ra PRIMARY KEY (rain_key)
    );
END;

IF OBJECT_ID(N'ags.ra_stg_cn_prdoc', N'U') IS NULL
BEGIN
    CREATE TABLE ags.ra_stg_cn_prdoc (
        cnpd_key INT IDENTITY(1,1) NOT NULL,
        cnpd_exec_key INT NULL,
        cnpdNumSequential INT NULL,
        cnpdNum NVARCHAR(100) NOT NULL,
        cnpdDate DATE NULL,
        cnpdTpOrd NVARCHAR(50) NULL,
        cnpdCnInvNum NVARCHAR(50) NULL,
        cnpdCnInvDate DATE NULL,
        cnpdCnNum NVARCHAR(100) NULL,
        StatusOfDICtext NVARCHAR(100) NULL,
        satstusOfOUKVtext NVARCHAR(100) NULL,
        summ MONEY NULL,
        cost MONEY NULL,
        SumTax MONEY NULL,
        costVAT MONEY NULL,
        SPPelement NVARCHAR(50) NULL,
        docOfAccountNum NVARCHAR(50) NULL,
        AccountDate DATE NULL,
        positingDate DATE NULL,
        accountingDoc NVARCHAR(50) NULL,
        accountingDocName NVARCHAR(255) NULL,
        agent INT NULL,
        TextOfAgent NVARCHAR(255) NULL,
        textOfCreditor NVARCHAR(255) NULL,
        supplierTIN NVARCHAR(20) NULL,
        supplierKPP NVARCHAR(10) NULL,
        purchasingGroup NVARCHAR(50) NULL,
        purchasingGroupName NVARCHAR(255) NULL,
        pdpCstAgPnStr NVARCHAR(50) NULL,
        prjctDefinition NVARCHAR(100) NULL,
        prjctDefinitionSort NVARCHAR(255) NULL,
        prjctHierarchyLevel NVARCHAR(10) NULL,
        ParentSppElementNum NVARCHAR(50) NULL,
        Object NVARCHAR(255) NULL,
        cstDSW NVARCHAR(10) NULL,
        raNum NVARCHAR(100) NULL,
        raDate DATE NULL,
        CorrectionNum NVARCHAR(20) NULL,
        CorrectionDate DATE NULL,
        AccountMain NVARCHAR(50) NULL,
        cnpdTpOrdKey INT NULL,
        pdpCstAgPnKey INT NULL,
        CONSTRAINT PK_ra_stg_cn_prdoc PRIMARY KEY (cnpd_key)
    );
END;

IF OBJECT_ID(N'ags.ra_stg_ralp', N'U') IS NULL
BEGIN
    CREATE TABLE ags.ra_stg_ralp (
        ralprt_key INT IDENTITY(1,1) NOT NULL,
        ralprt_exec_key INT NULL,
        ralprtNum NVARCHAR(100) NOT NULL,
        ralprtDate DATE NULL,
        ralprtCstCodeStr NVARCHAR(50) NULL,
        ralprtOgSenderStr NVARCHAR(255) NULL,
        ralprtOgBranchStr NVARCHAR(255) NULL,
        ralprtCostAndVat MONEY NULL,
        ralprtPresented TINYINT NULL,
        ralprtSentToBook TINYINT NULL,
        ralprtReturnedFlg TINYINT NULL,
        ralprtTestStartDate DATE NULL,
        ralprtNote NVARCHAR(MAX) NULL,
        ralprtArrived NVARCHAR(255) NULL,
        ralprtSent NVARCHAR(255) NULL,
        ralprtReturned NVARCHAR(255) NULL,
        ralprtCstAgPn INT NULL,
        ralprtOgSender INT NULL,
        ralprtStatus TINYINT NULL,
        ralprtRaKey INT NULL,
        ralprtRaAuKey INT NULL,
        CONSTRAINT PK_ra_stg_ralp PRIMARY KEY (ralprt_key)
    );
END;

IF OBJECT_ID(N'ags.ra_stg_ralp_sm', N'U') IS NULL
BEGIN
    CREATE TABLE ags.ra_stg_ralp_sm (
        ralprs_key INT IDENTITY(1,1) NOT NULL,
        ralprs_exec_key INT NULL,
        ralprsNum INT NULL,
        ralprsSenderStr NVARCHAR(255) NOT NULL,
        ralprsArrived INT NULL,
        ralprsInProcess INT NULL,
        ralprsSended INT NULL,
        ralprsReturned INT NULL,
        ralprsAccepted MONEY NULL,
        ralprsSender INT NULL,
        ralprsY INT NULL,
        ralprsAdtKey INT NULL,
        CONSTRAINT PK_ra_stg_ralp_sm PRIMARY KEY (ralprs_key)
    );
END;

IF OBJECT_ID(N'ags.ra_stg_agfee', N'U') IS NULL
BEGIN
    CREATE TABLE ags.ra_stg_agfee (
        oafpt_key INT IDENTITY(1,1) NOT NULL,
        oafpt_exec_key INT NULL,
        oafptOafName NVARCHAR(100) NOT NULL,
        oafptOafDate DATE NULL,
        oafptPnCstAgPn NVARCHAR(50) NULL,
        oafptTtl MONEY NULL,
        oafptArrivedNum NVARCHAR(255) NULL,
        oafptArrivedDate DATE NULL,
        oafptSendedNum NVARCHAR(255) NULL,
        oafptSendedDate DATE NULL,
        oafptReturnedNum NVARCHAR(255) NULL,
        oafptReturnedDate DATE NULL,
        oafptReturnedReason NVARCHAR(500) NULL,
        oafptUnit NVARCHAR(255) NULL,
        oafptPagesCount INT NULL,
        oafptActCount INT NULL,
        oafptOafSender NVARCHAR(255) NULL,
        oafptCapex NVARCHAR(10) NULL,
        oafptReturnedSum MONEY NULL,
        oafptOgKey INT NULL,
        CONSTRAINT PK_ra_stg_agfee PRIMARY KEY (oafpt_key)
    );
END;

--changeset femsq:2026-03-20-ra-mapping-tables runOnChange:false
IF OBJECT_ID(N'ags.ra_sheet_conf', N'U') IS NULL
BEGIN
    CREATE TABLE ags.ra_sheet_conf (
        rsc_key INT IDENTITY(1,1) NOT NULL,
        rsc_ft_key INT NOT NULL,
        rsc_sheet NVARCHAR(100) NULL,
        rsc_stg_tbl NVARCHAR(100) NOT NULL,
        rsc_anchor NVARCHAR(200) NOT NULL,
        rsc_anchor_match CHAR(1) NOT NULL,
        rsc_row_pattern NVARCHAR(200) NULL,
        CONSTRAINT PK_ra_sheet_conf PRIMARY KEY (rsc_key),
        CONSTRAINT FK_rsc_ft FOREIGN KEY (rsc_ft_key) REFERENCES ags.ra_ft(ft_key)
    );
END;

IF OBJECT_ID(N'ags.ra_col_map', N'U') IS NULL
BEGIN
    CREATE TABLE ags.ra_col_map (
        rcm_key INT IDENTITY(1,1) NOT NULL,
        rcm_rsc_key INT NOT NULL,
        rcm_tbl_col NVARCHAR(100) NOT NULL,
        rcm_tbl_col_ord SMALLINT NOT NULL,
        rcm_xl_hdr NVARCHAR(200) NOT NULL,
        rcm_xl_hdr_pri TINYINT NOT NULL,
        rcm_xl_match CHAR(1) NOT NULL,
        rcm_required BIT NOT NULL,
        CONSTRAINT PK_ra_col_map PRIMARY KEY (rcm_key),
        CONSTRAINT FK_rcm_rsc FOREIGN KEY (rcm_rsc_key) REFERENCES ags.ra_sheet_conf(rsc_key)
    );
END;

--changeset femsq:2026-03-20-ra-sheet-conf-seed runOnChange:false
SET IDENTITY_INSERT ags.ra_sheet_conf ON;

MERGE ags.ra_sheet_conf AS target
USING (VALUES
(1, 5, N'Отчеты', N'ags.ra_stg_ra', N'№ ОА', 'W', N'%_______-%'),
(2, 6, NULL, N'ags.ra_stg_agfee', N'№ Акта', 'W', NULL),
(3, 2, N'ХрСтрКнтрл', N'ags.ra_stg_cn_prdoc', N'Номер первичного документа', 'P', NULL),
(4, 3, N'Аренда_Земли', N'ags.ra_stg_ralp', N'№ отчета', 'P', NULL),
(5, 3, N'учет_аренды', N'ags.ra_stg_ralp_sm', N'Наименование Агента', 'W', NULL)
) AS src (rsc_key, rsc_ft_key, rsc_sheet, rsc_stg_tbl, rsc_anchor, rsc_anchor_match, rsc_row_pattern)
ON target.rsc_key = src.rsc_key
WHEN MATCHED THEN
    UPDATE SET
        rsc_ft_key = src.rsc_ft_key,
        rsc_sheet = src.rsc_sheet,
        rsc_stg_tbl = src.rsc_stg_tbl,
        rsc_anchor = src.rsc_anchor,
        rsc_anchor_match = src.rsc_anchor_match,
        rsc_row_pattern = src.rsc_row_pattern
WHEN NOT MATCHED THEN
    INSERT (rsc_key, rsc_ft_key, rsc_sheet, rsc_stg_tbl, rsc_anchor, rsc_anchor_match, rsc_row_pattern)
    VALUES (src.rsc_key, src.rsc_ft_key, src.rsc_sheet, src.rsc_stg_tbl, src.rsc_anchor, src.rsc_anchor_match, src.rsc_row_pattern);

SET IDENTITY_INSERT ags.ra_sheet_conf OFF;

--changeset femsq:2026-03-20-ra-col-map-seed runOnChange:false
SET IDENTITY_INSERT ags.ra_col_map ON;

MERGE ags.ra_col_map AS target
USING (VALUES
(1, 1, N'rainRaNum', 1, N'№ ОА', 1, 'W', 1),
(2, 1, N'rainRaDate', 2, N'Дата ОА', 1, 'W', 0),
(3, 1, N'rainSign', 3, N'Признак', 1, 'W', 0),
(4, 1, N'rainCstAgPnStr', 4, N'Код стройки', 1, 'W', 0),
(5, 1, N'rainCstName', 5, N'Наименование стройки', 1, 'W', 0),
(6, 1, N'rainSender', 6, N'Агент', 1, 'W', 0),
(7, 1, N'rainTtl', 7, N'Всего с НДС', 1, 'W', 0),
(8, 1, N'rainWork', 8, N'СМР', 1, 'W', 0),
(9, 1, N'rainEquip', 9, N'Оборудование', 1, 'W', 0),
(10, 1, N'rainOthers', 10, N'Прочие', 1, 'W', 0),
(11, 1, N'rainArrivedNum', 11, N'Поступило \n(№ письма)', 1, 'W', 0),
(12, 1, N'rainArrivedNum', 11, N'Поступило (№ письма)', 2, 'P', 0),
(13, 1, N'rainArrivedDate', 12, N'Поступило (Дата письма)', 1, 'W', 0),
(14, 1, N'rainArrivedDateFact', 13, N'Поступило (Фактическая дата)', 1, 'W', 0),
(15, 1, N'rainReturnedNum', 14, N'Возвращен на доработку (№ письма) ', 1, 'W', 0),
(16, 1, N'rainReturnedDate', 15, N'Возвращен на доработку (дата письма)', 1, 'W', 0),
(17, 1, N'rainReturnedReason', 16, N'Причина возврата', 1, 'W', 0),
(18, 1, N'rainSendNum', 17, N'Направлен в Бухгалтерию (№ СЗ)', 1, 'W', 0),
(19, 1, N'rainSendDate', 18, N'Направлен в Бухгалтерию (дата СЗ)', 1, 'W', 0),
(20, 1, N'rainUnit', 19, N'Отдел Управления', 1, 'W', 0),
(21, 1, N'rainRaSheetsNumber', 20, N'Кол-во листов ОА', 1, 'W', 0),
(22, 1, N'rainTitleDocSheetsNumber', 21, N'Кол-во листов ПУД', 1, 'W', 0),
(23, 1, N'rainPlanNumber', 22, N'План кол-во', 1, 'W', 0),
(24, 1, N'rainPlanDate', 23, N'План дата', 1, 'W', 0),
(25, 1, N'rainRaSignOfTest', 24, N'Признак проверки ОА', 1, 'W', 0),
(26, 1, N'rainRaSendedSum', 25, N'Сумма переданных ОА', 1, 'W', 0),
(27, 1, N'rainRaReturnedSum', 26, N'Сумма возвращенных ОА', 1, 'W', 0),
(29, 2, N'oafptOafName', 1, N'№ Акта', 1, 'W', 1),
(30, 2, N'oafptOafDate', 2, N'Дата Акта', 1, 'W', 0),
(31, 2, N'oafptPnCstAgPn', 3, N'Код стройки', 1, 'W', 0),
(32, 2, N'oafptTtl', 4, N'Сумма', 1, 'W', 0),
(33, 2, N'oafptTtl', 4, N'Итого', 2, 'W', 0),
(34, 2, N'oafptArrivedNum', 5, N'Поступило \n(№ письма)', 1, 'W', 0),
(35, 2, N'oafptArrivedNum', 5, N'Поступило (№ письма)', 2, 'P', 0),
(36, 2, N'oafptArrivedDate', 6, N'Поступило (Дата письма)', 1, 'W', 0),
(37, 2, N'oafptSendedNum', 7, N'Направлен в Бухгалтерию (№ СЗ)', 1, 'W', 0),
(38, 2, N'oafptSendedDate', 8, N'Направлен в Бухгалтерию (дата СЗ)', 1, 'W', 0),
(39, 2, N'oafptReturnedNum', 9, N'Возвращен на доработку (№ письма) ', 1, 'W', 0),
(40, 2, N'oafptReturnedDate', 10, N'Возвращен на доработку (дата письма)', 1, 'W', 0),
(41, 2, N'oafptReturnedReason', 11, N'Причина возврата', 1, 'W', 0),
(42, 2, N'oafptUnit', 12, N'Отдел Управления', 1, 'W', 0),
(43, 2, N'oafptPagesCount', 13, N'Кол-во листов Акта и С/Ф', 1, 'W', 0),
(44, 2, N'oafptActCount', 14, N'Кол-во Актов', 1, 'W', 0),
(45, 2, N'oafptOafSender', 15, N'Агент', 1, 'W', 0),
(46, 2, N'oafptCapex', 16, N'CAPEX', 1, 'W', 0),
(47, 2, N'oafptReturnedSum', 17, N'Сумма возвращенных АВ', 1, 'W', 0),
(49, 3, N'cnpdNum', 1, N'Номер первичного документа', 1, 'P', 1),
(50, 3, N'cnpdDate', 2, N'Дата первичного документа', 1, 'W', 0),
(51, 3, N'cnpdTpOrd', 3, N'ВидЗаказаНаПоставку', 1, 'W', 0),
(52, 3, N'cnpdCnInvNum', 4, N'Номер вх. Счета-фактуры', 1, 'W', 0),
(53, 3, N'cnpdCnInvDate', 5, N'Дата вх. Счета-фактуры', 1, 'W', 0),
(54, 3, N'cnpdCnNum', 6, N'Договор', 1, 'W', 0),
(55, 3, N'StatusOfDICtext', 7, N'Статус ДИС  (текст)', 1, 'W', 0),
(56, 3, N'satstusOfOUKVtext', 8, N'Статус ОУКВ  (текст)', 1, 'W', 0),
(57, 3, N'summ', 9, N'Сумма', 1, 'W', 0),
(58, 3, N'cost', 10, N'Стоимость', 1, 'W', 0),
(59, 3, N'SumTax', 11, N'Сумма налога', 1, 'W', 0),
(60, 3, N'costVAT', 12, N'Стоимость с НДС', 1, 'W', 0),
(61, 3, N'SPPelement', 13, N'СПП-элемент', 1, 'W', 0),
(62, 3, N'docOfAccountNum', 14, N'№ документа счета', 1, 'W', 0),
(63, 3, N'AccountDate', 15, N'Дата счета', 1, 'W', 0),
(64, 3, N'positingDate', 16, N'Дата проводки', 1, 'W', 0),
(65, 3, N'accountingDoc', 17, N'Бухг. документ', 1, 'W', 0),
(66, 3, N'accountingDocName', 18, N'Название бух док-та', 1, 'W', 0),
(67, 3, N'agent', 19, N'Агент', 1, 'W', 0),
(68, 3, N'TextOfAgent', 20, N'Текст агента', 1, 'W', 0),
(69, 3, N'textOfCreditor', 21, N'Текст кредитора', 1, 'W', 0),
(70, 3, N'supplierTIN', 22, N'ИНН поставщика', 1, 'W', 0),
(71, 3, N'supplierKPP', 23, N'КПП поставщика', 1, 'W', 0),
(72, 3, N'purchasingGroup', 24, N'Группа закупок', 1, 'W', 0),
(73, 3, N'purchasingGroupName', 25, N'Название ГрЗакупок', 1, 'W', 0),
(74, 3, N'pdpCstAgPnStr', 26, N'Определение проекта', 1, 'W', 0),
(75, 3, N'prjctDefinition', 26, N'Определение проекта', 1, 'W', 0),
(76, 3, N'prjctDefinitionSort', 27, N'Краткое описание проекта', 1, 'W', 0),
(77, 3, N'prjctHierarchyLevel', 28, N'Уровень в иерархии проекта', 1, 'W', 0),
(78, 3, N'ParentSppElementNum', 29, N'Номер вышестоящего СПП-Элемента', 1, 'W', 0),
(79, 3, N'Object', 30, N'Объект', 1, 'W', 0),
(80, 3, N'cstDSW', 31, N'Стройка/ПИР', 1, 'W', 0),
(81, 3, N'raNum', 32, N'Номер отчета Агента', 1, 'W', 0),
(82, 3, N'raDate', 33, N'Дата отчета Агента', 1, 'W', 0),
(83, 3, N'CorrectionNum', 34, N'Номер  исправления', 1, 'W', 0),
(84, 3, N'CorrectionDate', 35, N'Дата  исправления', 1, 'W', 0),
(85, 3, N'AccountMain', 36, N'Основной счет', 1, 'W', 0),
(87, 5, N'ralprsSenderStr', 1, N'Наименование Агента', 1, 'W', 1),
(101, 5, N'ralprsArrived', 2, N'поступило на проверку ', 1, 'P', 0),
(102, 5, N'ralprsInProcess', 3, N'на проверке', 1, 'W', 0),
(103, 5, N'ralprsSended', 4, N'передано в СБУ ', 1, 'P', 0),
(104, 5, N'ralprsReturned', 5, N'Возврат на доработку', 1, 'W', 0),
(105, 5, N'ralprsAccepted', 6, N'принято затрат,руб.', 1, 'W', 0),
(119, 4, N'ralprtNum', 1, N'№ отчета', 1, 'W', 1),
(120, 4, N'ralprtDate', 2, N'Дата ', 1, 'W', 0),
(121, 4, N'ralprtCstCodeStr', 3, N'Код проекта', 1, 'W', 0),
(122, 4, N'ralprtOgSenderStr', 4, N'Наименование\nдочернего общества', 1, 'W', 0),
(123, 4, N'ralprtOgBranchStr', 5, N'Филиал ООО "Газпром инвест"', 1, 'P', 0),
(124, 4, N'ralprtCostAndVat', 6, N'Принято затрат, руб.', 1, 'W', 0),
(125, 4, N'ralprtPresented', 7, N'Поступило в Ф644', 1, 'W', 0),
(126, 4, N'ralprtSentToBook', 8, N'Направ-лено в СБУ', 1, 'P', 0),
(127, 4, N'ralprtReturnedFlg', 9, N'Возврат на доработку', 1, 'W', 0),
(128, 4, N'ralprtTestStartDate', 10, N'начало проверки отчета', 1, 'P', 0),
(129, 4, N'ralprtNote', 11, N'КОММЕНТАРИЙ\n(предварительно)', 1, 'P', 0),
(130, 4, N'ralprtArrived', 12, N'Письмо Агента о направлении отчетов', 1, 'P', 0),
(131, 4, N'ralprtSent', 13, N'СЗ о направлении отчета в Службу бухгалтерского учета Филиала 644', 1, 'W', 0),
(132, 4, N'ralprtReturned', 14, N'Письмо Ф644 о замечаниях', 1, 'P', 0)
) AS src (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
ON target.rcm_key = src.rcm_key
WHEN MATCHED THEN
    UPDATE SET
        rcm_rsc_key = src.rcm_rsc_key,
        rcm_tbl_col = src.rcm_tbl_col,
        rcm_tbl_col_ord = src.rcm_tbl_col_ord,
        rcm_xl_hdr = src.rcm_xl_hdr,
        rcm_xl_hdr_pri = src.rcm_xl_hdr_pri,
        rcm_xl_match = src.rcm_xl_match,
        rcm_required = src.rcm_required
WHEN NOT MATCHED THEN
    INSERT (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
    VALUES (src.rcm_key, src.rcm_rsc_key, src.rcm_tbl_col, src.rcm_tbl_col_ord, src.rcm_xl_hdr, src.rcm_xl_hdr_pri, src.rcm_xl_match, src.rcm_required);

SET IDENTITY_INSERT ags.ra_col_map OFF;
