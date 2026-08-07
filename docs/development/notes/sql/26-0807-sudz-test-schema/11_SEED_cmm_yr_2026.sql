-- =============================================================================
-- Seed: yr 2026 + группы комментариев IV.2025 / I.2026 / II.2026
-- + тестовые комментарии и cnInvGr для Dbt 82/85
-- Требует: 08…upl, 09…seed 82/85, 10…cnInvCmm_mirrors
-- DEV only. ags.* не меняем (только read FK на справочники / yyyy).
-- =============================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRAN;

-- Идемпотентность: факты комментариев / группы долгов / год / группы периода
DELETE FROM test_sudz.cnInvGr;
DELETE FROM test_sudz.cnInvCmmFn;
DELETE FROM test_sudz.cnInvCmmDt;
DELETE FROM test_sudz.cnInvCmmCst;
DELETE FROM test_sudz.cnInvCmmAg;
DELETE FROM test_sudz.cnInvCmm;
DELETE FROM test_sudz.yr_upl_p;
-- yr_CmmGr → NULL перед удалением групп
UPDATE test_sudz.yr SET yr_CmmGr = NULL;
DELETE FROM test_sudz.yr;
DELETE FROM test_sudz.cnInvCmmGr;
DELETE FROM test_sudz.cnInvGrNm;

---------------------------------------------------------------------
-- Имена произвольных групп долгов (sandbox)
---------------------------------------------------------------------
SET IDENTITY_INSERT test_sudz.cnInvGrNm ON;
INSERT INTO test_sudz.cnInvGrNm (cnignKey, cnignName) VALUES
 (1, N'Расторжение договора'),
 (2, N'Передача объекта в ООО "Газпром инвест"'),
 (3, N'Некорректные данные в БУиРГ'),
 (901, N'Рассмотреть углубленно в сентябре');
SET IDENTITY_INSERT test_sudz.cnInvGrNm OFF;

---------------------------------------------------------------------
-- Группы комментариев «общие» за три квартала (условные ключи 901–903)
---------------------------------------------------------------------
SET IDENTITY_INSERT test_sudz.cnInvCmmGr ON;
INSERT INTO test_sudz.cnInvCmmGr (cnicgKey, cnicgNmCs, cnicgDate, cnicgName) VALUES
 (901, NULL, '2025-12-31', N'[test_sudz] Отчёт за IV-й квартал 2025 года, общий'),
 (902, NULL, '2026-03-31', N'[test_sudz] Отчёт за I-й квартал 2026 года, общий'),
 (903, NULL, '2026-06-30', N'[test_sudz] Отчёт за II-й квартал 2026 года, общий');
SET IDENTITY_INSERT test_sudz.cnInvCmmGr OFF;

---------------------------------------------------------------------
-- yr 2026: база = дек’25 (901); актуальная группа = II.2026 (903)
-- yyyy = ags.yyyy.yKey 28 (календарный 2026)
---------------------------------------------------------------------
SET IDENTITY_INSERT test_sudz.yr ON;
INSERT INTO test_sudz.yr (yr_key, yr_variant, cn_inv_dbt_upl, yyyy, yr_CmmGr, yr_Progress)
VALUES (
    901,
    N'[test_sudz] Основной вариант 2026-го года',
    901,
    28,
    903,
    N'<p>seed S40: yr_CmmGr → II.2026 общий; upl 901/902/903</p>'
);
SET IDENTITY_INSERT test_sudz.yr OFF;

INSERT INTO test_sudz.yr_upl_p (yr_upl_p_yr, cn_inv_dbt_upl) VALUES
 (901, 901),
 (901, 902),
 (901, 903);

---------------------------------------------------------------------
-- cnInvCmm: мероприятия (cnictKey=1) + куратор (8) по группам / долгам
---------------------------------------------------------------------
INSERT INTO test_sudz.cnInvCmm (cnicType, cnicGroup, cnicInv, cnicText, cnicInvAccnt) VALUES
 -- IV.2025
 (1, 901, NULL, N'[seed] 82: претензионная работа; график погашения согласован с контрагентом.', 82),
 (8, 901, NULL, N'[seed] 82: куратор УПВР — тест.', 82),
 (1, 901, NULL, N'[seed] 85: ожидание исполнения судебного акта А19-16343/2021.', 85),
 -- I.2026
 (1, 902, NULL, N'[seed] 82: срок погашения перенесён на 31.10.2027; просрочка обнулена в своде.', 82),
 (1, 902, NULL, N'[seed] 85: в своде отражена исходная СФ 90 (смена контекста СФ).', 85),
 -- II.2026
 (1, 903, NULL, N'[seed] 82: мониторинг исполнения графика; изменений суммы нет.', 82),
 (1, 903, NULL, N'[seed] 85: без погашения; контроль по договору 32-425/05-18.', 85),
 (5, 903, NULL, N'[seed] 85: примечание — кандидат в углублённый разбор сентябрь.', 85);

---------------------------------------------------------------------
-- cnInvCmmDt / cnInvCmmFn — по одному типу на долг в актуальной группе
---------------------------------------------------------------------
INSERT INTO test_sudz.cnInvCmmDt (cnicdName, cnicdCmmGr, cnicdInv, cnicdDate, cnicdInvAccnt) VALUES
 (1, 903, NULL, '2027-10-31', 82),
 (1, 903, NULL, '2026-09-30', 85);

INSERT INTO test_sudz.cnInvCmmFn (cnicfName, cnicfCmmGr, cnicfInv, cnicfValue, cnicfInvAccnt) VALUES
 (1, 903, NULL, 0,        82),
 (1, 903, NULL, 9527.42,  85);

---------------------------------------------------------------------
-- cnInvGr: произвольная группа «рассмотреть углубленно…» в II.2026
---------------------------------------------------------------------
INSERT INTO test_sudz.cnInvGr (cnigInv, cnigCmmGr, cnigGrName, cnigInvAccnt) VALUES
 (NULL, 903, 901, 85);

COMMIT TRAN;

---------------------------------------------------------------------
-- Проверки
---------------------------------------------------------------------
SELECT 'cnInvCmmGr' AS obj, cnicgKey AS k, CONVERT(varchar(10), cnicgDate, 23) AS d, cnicgName AS n
FROM test_sudz.cnInvCmmGr
ORDER BY cnicgKey;

SELECT y.yr_key, y.yr_variant, y.cn_inv_dbt_upl AS base_upl, y.yyyy, y.yr_CmmGr,
       u.cn_inv_dbt_upl AS linked_upl, upl.uplStatusOnDate
FROM test_sudz.yr y
JOIN test_sudz.yr_upl_p u ON u.yr_upl_p_yr = y.yr_key
JOIN test_sudz.cn_inv_dbt_upl upl ON upl.upl_key = u.cn_inv_dbt_upl
ORDER BY upl.uplStatusOnDate;

SELECT c.cnicKey, c.cnicInvAccnt AS dbt, g.cnicgName AS gr, t.cnictName AS tp, LEFT(c.cnicText, 80) AS txt
FROM test_sudz.cnInvCmm c
JOIN test_sudz.cnInvCmmGr g ON g.cnicgKey = c.cnicGroup
JOIN ags.cnInvCmmTp t ON t.cnictKey = c.cnicType
ORDER BY c.cnicInvAccnt, c.cnicGroup, c.cnicKey;

SELECT gr.cnigKey, gr.cnigInvAccnt AS dbt, n.cnignName, g.cnicgName
FROM test_sudz.cnInvGr gr
JOIN test_sudz.cnInvGrNm n ON n.cnignKey = gr.cnigGrName
JOIN test_sudz.cnInvCmmGr g ON g.cnicgKey = gr.cnigCmmGr;
GO
