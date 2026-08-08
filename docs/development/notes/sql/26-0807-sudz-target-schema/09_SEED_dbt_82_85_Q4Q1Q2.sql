-- =============================================================================
-- Seed: долги Rslt «82» и «85» за IV.2025 / I.2026 / II.2026
-- Только INSERT в sudz.*; ссылки на уже существующие ключи ags.*
-- Источник фактов: docs/development/notes/domain/sudz/04-2_example-rslt-82-85.md
-- Требует: 08_CREATE_TABLE_cn_inv_dbt_upl_sandbox.sql
-- =============================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRAN;

-- Очистка предыдущего seed (если перезапуск)
DELETE FROM sudz.DbtValue;
DELETE FROM sudz.invDbtDbtVar;
DELETE FROM sudz.invDbtDbt;
DELETE FROM sudz.invDbtVar;
DELETE FROM sudz.invDbt;
DELETE FROM sudz.Dbt;

---------------------------------------------------------------------
-- Dbt: две канонические задолженности
---------------------------------------------------------------------
SET IDENTITY_INSERT sudz.Dbt ON;
INSERT INTO sudz.Dbt (dbtKey, dbtNote) VALUES
 (82, N'Rslt стр.82 / ciaKey=11002 / СФ 7947 / 1-306-12 / 70525000.01'),
 (85, N'Rslt стр.85 / P1: А19-16343/2021 ↔ 90 / 32-425/05-18 / 9527.42');
SET IDENTITY_INSERT sudz.Dbt OFF;

---------------------------------------------------------------------
-- invDbt: слоты у СФ (суррогат idKey)
-- 82 → inv 11885; 85 → inv 12032 (А19) и inv 20505 (90)
---------------------------------------------------------------------
SET IDENTITY_INSERT sudz.invDbt ON;
INSERT INTO sudz.invDbt (idKey, idInv, idNum, idNote) VALUES
 (8201, 11885, 1, N'слот долга 82 на СФ 7947'),
 (8501, 12032, 1, N'слот долга 85 на А19-16343/2021'),
 (8502, 20505, 1, N'слот долга 85 на исходной СФ 90');
SET IDENTITY_INSERT sudz.invDbt OFF;

---------------------------------------------------------------------
-- invDbtDbt: красный путь идентичности
---------------------------------------------------------------------
INSERT INTO sudz.invDbtDbt (iddInv, iddDbt, iddInvDbt)
VALUES
 (11885, 82, 8201),
 (12032, 85, 8501),
 (20505, 85, 8502);

---------------------------------------------------------------------
-- invDbtVar: контексты (без ciaName)
-- ags keys: cnNum 423/1434, invNum 11888/12035/20511, accnt 19/24, cn_s_org 785/2370
---------------------------------------------------------------------
SET IDENTITY_INSERT sudz.invDbtVar ON;
INSERT INTO sudz.invDbtVar (idvvKey, idvvCnNum, idvvInvNum, idvvAccnt, idvvCn_s_org) VALUES
 (8201, 423,  11888, 19, 785),   -- 82: 1-306-12 / 7947 / 606012
 (8501, 1434, 12035, 24, 2370),  -- 85: 32-425/05-18 / А19 / 762210
 (8502, 1434, 20511, 24, 2370);  -- 85: 32-425/05-18 / 90 / 762210
SET IDENTITY_INSERT sudz.invDbtVar OFF;

---------------------------------------------------------------------
-- invDbtDbtVar: фиолетовый мост слот↔контекст
---------------------------------------------------------------------
INSERT INTO sudz.invDbtDbtVar (iddvInvDbt, iddvInvDbtVar) VALUES
 (8201, 8201),
 (8501, 8501),
 (8502, 8502);

---------------------------------------------------------------------
-- DbtValue: снимки по трём выгрузкам (upl 901/902/903)
---------------------------------------------------------------------
-- Долг 82
INSERT INTO sudz.DbtValue
 (dvDbt, dvInvDbtVar, dvUpl, dvTtl, dvOverd, dvDateStart, dvDateMaturity, dvDocBase)
VALUES
 (82, 8201, 901, 70525000.01, 70525000.01, '2022-01-21', '2024-10-30', N'7947'),  -- IV.2025
 (82, 8201, 902, 70525000.01, 0,           '2022-01-21', '2027-10-31', N'7947'),  -- I.2026 (срок сдвинут)
 (82, 8201, 903, 70525000.01, 0,           '2022-01-21', '2027-10-31', N'7947');  -- II.2026

-- Долг 85: IV.2025 под А19; I–II.2026 под СФ 90
INSERT INTO sudz.DbtValue
 (dvDbt, dvInvDbtVar, dvUpl, dvTtl, dvOverd, dvDateStart, dvDateMaturity, dvDocBase)
VALUES
 (85, 8501, 901, 9527.42, 9527.42, '2022-08-15', '2022-08-15', N'А19-16343/2021'), -- IV.2025
 (85, 8502, 902, 9527.42, 9527.42, '2022-08-15', '2022-08-15', N'90'),            -- I.2026
 (85, 8502, 903, 9527.42, 9527.42, '2022-08-15', '2022-08-15', N'90');            -- II.2026

COMMIT TRAN;

-- Проверка: история долга 85 по выгрузкам (смена контекста СФ)
SELECT
    dv.dvDbt AS dbt,
    u.uplStatusOnDate AS as_of,
    n.inNum AS sf,
    c.cnnNum AS cn_num,
    a.account_num AS accnt,
    dv.dvTtl,
    dv.dvOverd,
    dv.dvDateMaturity,
    dv.dvDocBase
FROM sudz.DbtValue dv
JOIN sudz.cn_inv_dbt_upl u ON u.upl_key = dv.dvUpl
JOIN sudz.invDbtVar v ON v.idvvKey = dv.dvInvDbtVar
JOIN ags.invNum n ON n.inKey = v.idvvInvNum
JOIN ags.cnNum c ON c.cnnKey = v.idvvCnNum
JOIN ags.accnt a ON a.account_key = v.idvvAccnt
ORDER BY dv.dvDbt, u.uplStatusOnDate;
GO
