-- =============================================================================
-- 06_SEED_mapping.sql — seed ra_sheet_conf + ra_col_map (FEMSQ Stage 1)
-- Источник: liquibase 2026-03-20 + whitelist 2026-04-02
-- Идемпотентно по PK; требует ra_ft keys 2,3,5,6 (скрипт 05)
-- =============================================================================

PRINT '=== 06_SEED_mapping ===';

IF OBJECT_ID(N'ags.ra_sheet_conf', N'U') IS NULL
BEGIN
    PRINT 'ERROR: ags.ra_sheet_conf missing — run 04 first';
END
ELSE
BEGIN
    SET IDENTITY_INSERT ags.ra_sheet_conf ON;

    IF NOT EXISTS (SELECT 1 FROM ags.ra_sheet_conf WHERE rsc_key = 1)
        INSERT INTO ags.ra_sheet_conf (rsc_key, rsc_ft_key, rsc_sheet, rsc_stg_tbl, rsc_anchor, rsc_anchor_match, rsc_row_pattern, rsc_sign_whitelist)
        VALUES (1, 5, N'Отчеты', N'ags.ra_stg_ra', N'№ ОА', 'W', N'%_______-%', N'ОА;ОА изм;ОА прочие');
    IF NOT EXISTS (SELECT 1 FROM ags.ra_sheet_conf WHERE rsc_key = 2)
        INSERT INTO ags.ra_sheet_conf (rsc_key, rsc_ft_key, rsc_sheet, rsc_stg_tbl, rsc_anchor, rsc_anchor_match, rsc_row_pattern, rsc_sign_whitelist)
        VALUES (2, 6, NULL, N'ags.ra_stg_agfee', N'№ Акта', 'W', NULL, NULL);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_sheet_conf WHERE rsc_key = 3)
        INSERT INTO ags.ra_sheet_conf (rsc_key, rsc_ft_key, rsc_sheet, rsc_stg_tbl, rsc_anchor, rsc_anchor_match, rsc_row_pattern, rsc_sign_whitelist)
        VALUES (3, 2, N'ХрСтрКнтрл', N'ags.ra_stg_cn_prdoc', N'Номер первичного документа', 'P', NULL, NULL);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_sheet_conf WHERE rsc_key = 4)
        INSERT INTO ags.ra_sheet_conf (rsc_key, rsc_ft_key, rsc_sheet, rsc_stg_tbl, rsc_anchor, rsc_anchor_match, rsc_row_pattern, rsc_sign_whitelist)
        VALUES (4, 3, N'Аренда_Земли', N'ags.ra_stg_ralp', N'№ отчета', 'P', NULL, NULL);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_sheet_conf WHERE rsc_key = 5)
        INSERT INTO ags.ra_sheet_conf (rsc_key, rsc_ft_key, rsc_sheet, rsc_stg_tbl, rsc_anchor, rsc_anchor_match, rsc_row_pattern, rsc_sign_whitelist)
        VALUES (5, 3, N'учет_аренды', N'ags.ra_stg_ralp_sm', N'Наименование Агента', 'W', NULL, NULL);

    SET IDENTITY_INSERT ags.ra_sheet_conf OFF;

    UPDATE ags.ra_sheet_conf
    SET rsc_sign_whitelist = N'ОА;ОА изм;ОА прочие'
    WHERE rsc_key = 1
      AND (rsc_sign_whitelist IS NULL OR LTRIM(RTRIM(rsc_sign_whitelist)) = N'');

    PRINT 'ra_sheet_conf seed checked';
END
GO

IF OBJECT_ID(N'ags.ra_col_map', N'U') IS NULL
BEGIN
    PRINT 'ERROR: ags.ra_col_map missing — run 04 first';
END
ELSE
BEGIN
    SET IDENTITY_INSERT ags.ra_col_map ON;

    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 1)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (1, 1, N'rainRaNum', 1, N'№ ОА', 1, 'W', 1);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 2)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (2, 1, N'rainRaDate', 2, N'Дата ОА', 1, 'W', 0);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 3)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (3, 1, N'rainSign', 3, N'Признак', 1, 'W', 0);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 4)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (4, 1, N'rainCstAgPnStr', 4, N'Код стройки', 1, 'W', 0);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 5)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (5, 1, N'rainCstName', 5, N'Наименование стройки', 1, 'W', 0);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 6)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (6, 1, N'rainSender', 6, N'Агент', 1, 'W', 0);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 7)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (7, 1, N'rainTtl', 7, N'Всего с НДС', 1, 'W', 0);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 8)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (8, 1, N'rainWork', 8, N'СМР', 1, 'W', 0);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 9)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (9, 1, N'rainEquip', 9, N'Оборудование', 1, 'W', 0);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 10)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (10, 1, N'rainOthers', 10, N'Прочие', 1, 'W', 0);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 11)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (11, 1, N'rainArrivedNum', 11, N'Поступило ' + CHAR(10) + N'(№ письма)', 1, 'W', 0);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 12)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (12, 1, N'rainArrivedNum', 11, N'Поступило (№ письма)', 2, 'P', 0);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 13)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (13, 1, N'rainArrivedDate', 12, N'Поступило (Дата письма)', 1, 'W', 0);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 14)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (14, 1, N'rainArrivedDateFact', 13, N'Поступило (Фактическая дата)', 1, 'W', 0);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 15)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (15, 1, N'rainReturnedNum', 14, N'Возвращен на доработку (№ письма) ', 1, 'W', 0);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 16)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (16, 1, N'rainReturnedDate', 15, N'Возвращен на доработку (дата письма)', 1, 'W', 0);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 17)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (17, 1, N'rainReturnedReason', 16, N'Причина возврата', 1, 'W', 0);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 18)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (18, 1, N'rainSendNum', 17, N'Направлен в Бухгалтерию (№ СЗ)', 1, 'W', 0);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 19)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (19, 1, N'rainSendDate', 18, N'Направлен в Бухгалтерию (дата СЗ)', 1, 'W', 0);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 20)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (20, 1, N'rainUnit', 19, N'Отдел Управления', 1, 'W', 0);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 21)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (21, 1, N'rainRaSheetsNumber', 20, N'Кол-во листов ОА', 1, 'W', 0);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 22)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (22, 1, N'rainTitleDocSheetsNumber', 21, N'Кол-во листов ПУД', 1, 'W', 0);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 23)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (23, 1, N'rainPlanNumber', 22, N'План кол-во', 1, 'W', 0);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 24)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (24, 1, N'rainPlanDate', 23, N'План дата', 1, 'W', 0);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 25)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (25, 1, N'rainRaSignOfTest', 24, N'Признак проверки ОА', 1, 'W', 0);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 26)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (26, 1, N'rainRaSendedSum', 25, N'Сумма переданных ОА', 1, 'W', 0);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 27)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (27, 1, N'rainRaReturnedSum', 26, N'Сумма возвращенных ОА', 1, 'W', 0);

    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 29)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (29, 2, N'oafptOafName', 1, N'№ Акта', 1, 'W', 1);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 30)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (30, 2, N'oafptOafDate', 2, N'Дата Акта', 1, 'W', 0);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 31)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (31, 2, N'oafptPnCstAgPn', 3, N'Код стройки', 1, 'W', 0);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 32)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (32, 2, N'oafptTtl', 4, N'Сумма', 1, 'W', 0);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 33)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (33, 2, N'oafptTtl', 4, N'Итого', 2, 'W', 0);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 34)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (34, 2, N'oafptArrivedNum', 5, N'Поступило ' + CHAR(10) + N'(№ письма)', 1, 'W', 0);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 35)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (35, 2, N'oafptArrivedNum', 5, N'Поступило (№ письма)', 2, 'P', 0);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 36)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (36, 2, N'oafptArrivedDate', 6, N'Поступило (Дата письма)', 1, 'W', 0);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 37)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (37, 2, N'oafptSendedNum', 7, N'Направлен в Бухгалтерию (№ СЗ)', 1, 'W', 0);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 38)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (38, 2, N'oafptSendedDate', 8, N'Направлен в Бухгалтерию (дата СЗ)', 1, 'W', 0);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 39)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (39, 2, N'oafptReturnedNum', 9, N'Возвращен на доработку (№ письма) ', 1, 'W', 0);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 40)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (40, 2, N'oafptReturnedDate', 10, N'Возвращен на доработку (дата письма)', 1, 'W', 0);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 41)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (41, 2, N'oafptReturnedReason', 11, N'Причина возврата', 1, 'W', 0);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 42)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (42, 2, N'oafptUnit', 12, N'Отдел Управления', 1, 'W', 0);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 43)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (43, 2, N'oafptPagesCount', 13, N'Кол-во листов Акта и С/Ф', 1, 'W', 0);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 44)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (44, 2, N'oafptActCount', 14, N'Кол-во Актов', 1, 'W', 0);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 45)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (45, 2, N'oafptOafSender', 15, N'Агент', 1, 'W', 0);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 46)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (46, 2, N'oafptCapex', 16, N'CAPEX', 1, 'W', 0);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 47)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (47, 2, N'oafptReturnedSum', 17, N'Сумма возвращенных АВ', 1, 'W', 0);

    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 87)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (87, 5, N'ralprsSenderStr', 1, N'Наименование Агента', 1, 'W', 1);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 101)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (101, 5, N'ralprsArrived', 2, N'поступило на проверку ', 1, 'P', 0);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 102)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (102, 5, N'ralprsInProcess', 3, N'на проверке', 1, 'W', 0);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 103)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (103, 5, N'ralprsSended', 4, N'передано в СБУ ', 1, 'P', 0);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 104)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (104, 5, N'ralprsReturned', 5, N'Возврат на доработку', 1, 'W', 0);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 105)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (105, 5, N'ralprsAccepted', 6, N'принято затрат,руб.', 1, 'W', 0);

    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 119)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (119, 4, N'ralprtNum', 1, N'№ отчета', 1, 'W', 1);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 120)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (120, 4, N'ralprtDate', 2, N'Дата ', 1, 'W', 0);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 121)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (121, 4, N'ralprtCstCodeStr', 3, N'Код проекта', 1, 'W', 0);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 122)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (122, 4, N'ralprtOgSenderStr', 4, N'Наименование' + CHAR(10) + N'дочернего общества', 1, 'W', 0);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 123)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (123, 4, N'ralprtOgBranchStr', 5, N'Филиал ООО "Газпром инвест"', 1, 'P', 0);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 124)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (124, 4, N'ralprtCostAndVat', 6, N'Принято затрат, руб.', 1, 'W', 0);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 125)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (125, 4, N'ralprtPresented', 7, N'Поступило в Ф644', 1, 'W', 0);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 126)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (126, 4, N'ralprtSentToBook', 8, N'Направ-лено в СБУ', 1, 'P', 0);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 127)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (127, 4, N'ralprtReturnedFlg', 9, N'Возврат на доработку', 1, 'W', 0);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 128)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (128, 4, N'ralprtTestStartDate', 10, N'начало проверки отчета', 1, 'P', 0);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 129)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (129, 4, N'ralprtNote', 11, N'КОММЕНТАРИЙ' + CHAR(10) + N'(предварительно)', 1, 'P', 0);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 130)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (130, 4, N'ralprtArrived', 12, N'Письмо Агента о направлении отчетов', 1, 'P', 0);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 131)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (131, 4, N'ralprtSent', 13, N'СЗ о направлении отчета в Службу бухгалтерского учета Филиала 644', 1, 'W', 0);
    IF NOT EXISTS (SELECT 1 FROM ags.ra_col_map WHERE rcm_key = 132)
        INSERT INTO ags.ra_col_map (rcm_key, rcm_rsc_key, rcm_tbl_col, rcm_tbl_col_ord, rcm_xl_hdr, rcm_xl_hdr_pri, rcm_xl_match, rcm_required)
        VALUES (132, 4, N'ralprtReturned', 14, N'Письмо Ф644 о замечаниях', 1, 'P', 0);

    SET IDENTITY_INSERT ags.ra_col_map OFF;
    PRINT 'ra_col_map seed checked (core Stage1 maps; cn_prdoc map rows omitted — table optional)';
END
GO

PRINT '=== 06_SEED_mapping: готово ===';
GO
