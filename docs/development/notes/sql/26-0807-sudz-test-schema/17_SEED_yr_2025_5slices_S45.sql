-- =============================================================================
-- S45: seed года 2025 (5 срезов как в ags_Yr_DbtChangesRslt_26-0212)
-- upl_date = Excel: 2025-01-24, 2025-04-21, 2025-07-18, 2025-10-21, 2026-01-30
-- yr_key=900, yyyy=27 (2025). Долги 82/85: факты по стр. Excel 129/134.
-- 85: invNum А19 → 90 → 90 → 90 → А19 (Q4 снова А19).
-- DEV only.
-- =============================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

BEGIN TRAN;

---------------------------------------------------------------------
-- Выгрузки 801–805
---------------------------------------------------------------------
MERGE test_sudz.cn_inv_dbt_upl AS t
USING (VALUES
    (801, CAST('2025-01-24' AS datetime), CAST('2024-12-31' AS date), N'[test_sudz] YE2024 / Rslt_26-0212 base'),
    (802, CAST('2025-04-21' AS datetime), CAST('2025-03-31' AS date), N'[test_sudz] Q1 2025 / Rslt_26-0212'),
    (803, CAST('2025-07-18' AS datetime), CAST('2025-06-30' AS date), N'[test_sudz] Q2 2025 / Rslt_26-0212'),
    (804, CAST('2025-10-21' AS datetime), CAST('2025-09-30' AS date), N'[test_sudz] Q3 2025 / Rslt_26-0212'),
    (805, CAST('2026-01-30' AS datetime), CAST('2025-12-31' AS date), N'[test_sudz] Q4 2025 / Rslt_26-0212')
) AS s (upl_key, upl_date, uplStatusOnDate, upl_name)
ON t.upl_key = s.upl_key
WHEN MATCHED THEN UPDATE SET
    upl_date = s.upl_date, uplStatusOnDate = s.uplStatusOnDate, upl_name = s.upl_name
WHEN NOT MATCHED THEN
    INSERT (upl_key, upl_date, uplStatusOnDate, upl_name)
    VALUES (s.upl_key, s.upl_date, s.uplStatusOnDate, s.upl_name);

---------------------------------------------------------------------
-- Группа комментариев IV.2025 (итог года 2025 в Rslt_26-0212)
---------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM test_sudz.cnInvCmmGr WHERE cnicgKey = 805)
BEGIN
    SET IDENTITY_INSERT test_sudz.cnInvCmmGr ON;
    INSERT INTO test_sudz.cnInvCmmGr (cnicgKey, cnicgNmCs, cnicgDate, cnicgName)
    VALUES (805, NULL, '2025-12-31', N'[test_sudz] Отчёт за IV-й квартал 2025 (Rslt_26-0212), общий');
    SET IDENTITY_INSERT test_sudz.cnInvCmmGr OFF;
END

---------------------------------------------------------------------
-- yr 900 = 2025
---------------------------------------------------------------------
DELETE FROM test_sudz.yr_upl_p WHERE yr_upl_p_yr = 900;
IF EXISTS (SELECT 1 FROM test_sudz.yr WHERE yr_key = 900)
    UPDATE test_sudz.yr SET yr_CmmGr = NULL WHERE yr_key = 900;
DELETE FROM test_sudz.yr WHERE yr_key = 900;

SET IDENTITY_INSERT test_sudz.yr ON;
INSERT INTO test_sudz.yr (yr_key, yr_variant, cn_inv_dbt_upl, yyyy, yr_CmmGr, yr_Progress)
VALUES (
    900,
    N'[test_sudz] Основной вариант 2025-го года (S45 / Rslt_26-0212)',
    801,
    27,
    805,
    N'<p>S45: 5 upl 801–805; база 801; yr_CmmGr=805</p>'
);
SET IDENTITY_INSERT test_sudz.yr OFF;

INSERT INTO test_sudz.yr_upl_p (yr_upl_p_yr, cn_inv_dbt_upl) VALUES
 (900, 801), (900, 802), (900, 803), (900, 804), (900, 805);

---------------------------------------------------------------------
-- DbtValue 82/85 на 801–805 (не трогаем 901–903)
---------------------------------------------------------------------
DELETE FROM test_sudz.DbtValue WHERE dvUpl BETWEEN 801 AND 805;

-- 82: стабилен все 5 срезов (var 8201)
INSERT INTO test_sudz.DbtValue
 (dvDbt, dvInvDbtVar, dvUpl, dvTtl, dvOverd, dvDateStart, dvDateMaturity, dvDocBase)
VALUES
 (82, 8201, 801, 70525000.01, 70525000.01, '2022-01-21', '2024-10-30', N'7947'),
 (82, 8201, 802, 70525000.01, 70525000.01, '2022-01-21', '2024-10-30', N'7947'),
 (82, 8201, 803, 70525000.01, 70525000.01, '2022-01-21', '2024-10-30', N'7947'),
 (82, 8201, 804, 70525000.01, 70525000.01, '2022-01-21', '2024-10-30', N'7947'),
 (82, 8201, 805, 70525000.01, 70525000.01, '2022-01-21', '2024-10-30', N'7947');

-- 85: А19 / 90 / 90 / 90 / А19
INSERT INTO test_sudz.DbtValue
 (dvDbt, dvInvDbtVar, dvUpl, dvTtl, dvOverd, dvDateStart, dvDateMaturity, dvDocBase)
VALUES
 (85, 8501, 801, 9527.42, 9527.42, '2021-10-13', '2022-08-15', N'А19-16343/2021'),
 (85, 8502, 802, 9527.42, 9527.42, '2021-10-13', '2022-08-15', N'90'),
 (85, 8502, 803, 9527.42, 9527.42, '2021-10-13', '2022-08-15', N'90'),
 (85, 8502, 804, 9527.42, 9527.42, '2021-10-13', '2022-08-15', N'90'),
 (85, 8501, 805, 9527.42, 9527.42, '2021-10-13', '2022-08-15', N'А19-16343/2021');

---------------------------------------------------------------------
-- Cst/Ag периода: 82 — все срезы (как Excel); 85 — без периода (в Excel пусто)
---------------------------------------------------------------------
DELETE FROM test_sudz.DbtUplCstAg WHERE ducaUpl BETWEEN 801 AND 805;

INSERT INTO test_sudz.DbtUplCstAg (ducaDbt, ducaUpl, ducaCstAgPn) VALUES
 (82, 801, 1835), (82, 802, 1835), (82, 803, 1835), (82, 804, 1835), (82, 805, 1835);

---------------------------------------------------------------------
-- Комментарии группы 805 (куратор + стройка года)
---------------------------------------------------------------------
DELETE FROM test_sudz.cnInvCmm    WHERE cnicGroup = 805;
DELETE FROM test_sudz.cnInvCmmCst WHERE ciccCmmGr = 805;
DELETE FROM test_sudz.cnInvCmmAg  WHERE cicaCmmGr = 805;

INSERT INTO test_sudz.cnInvCmm (cnicType, cnicGroup, cnicText, cnicInvAccnt) VALUES
 (8, 805, N'Сербул А.С.', 82),
 (1, 805, N'[seed S45] 82: см. Excel 26-0212 стр.129 — полный текст мероприятий отложен.', 82),
 (8, 805, N'Дедова И.В', 85),
 (1, 805, N'[seed S45] 85: см. Excel 26-0212 стр.134 — полный текст мероприятий отложен.', 85);

INSERT INTO test_sudz.cnInvCmmCst (ciccCmmGr, ciccType, ciccCstAgPn, ciccInvAccnt) VALUES
 (805, 2, 1835, 82),
 (805, 2, 2016, 85);

INSERT INTO test_sudz.cnInvCmmAg (cicaCmmGr, cicaType, cicaOgAg, cicaInvAccnt) VALUES
 (805, 2, 1, 82),
 (805, 2, 1, 85);

COMMIT TRAN;
GO

SELECT 'upl' AS kind, upl_key, CONVERT(varchar(10), upl_date, 23) AS upl_date, CONVERT(varchar(10), uplStatusOnDate, 23) AS as_of
FROM test_sudz.cn_inv_dbt_upl WHERE upl_key BETWEEN 801 AND 805
UNION ALL
SELECT 'yr', yr_key, CAST(cn_inv_dbt_upl AS varchar(10)), CAST(yr_CmmGr AS varchar(10))
FROM test_sudz.yr WHERE yr_key = 900;
SELECT dvDbt, dvUpl, LEFT(dvDocBase, 20) AS doc, dvTtl, dvOverd
FROM test_sudz.DbtValue WHERE dvUpl BETWEEN 801 AND 805 ORDER BY dvDbt, dvUpl;
GO
