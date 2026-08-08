-- =============================================================================
-- S44: итоговый документ D644 (~18 колонок) — паритет Access *RsltD644*
-- Источник логики: debit/23-0421_sql.docx («Стало» 25.05.2026 ← Rslt_26-0505)
--
-- Решения владельца (S44):
--   1) «счет-фактура» = invNumEnum базовой выгрузки года (на 31.12 предыд. года)
--   2) «Агент» = ags.cstAgPn.cstapOgName по JOIN к разрешённому «Код стройки»
--      (не period AgOrg; код — из комментариев года с fallback на CstAgPnCode срезов)
--   3) фильтр: Overd(base) > 0
--   4) шапка письма / длинные подписи «по состоянию на…» — слой отчёта, не SQL
--
-- Параметры: @yr; base = yr.cn_inv_dbt_upl; curr = MAX(upl_date) фактов года
--   (опционально @curr_upl — зафиксировать срез)
-- DEV only. sqlcmd -I
-- =============================================================================

SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE test_sudz.Yr_DbtChangesD644
    @yr       int,
    @curr_upl int = NULL  -- NULL → последний upl_date года в vw_Yr_DbtFact
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM test_sudz.yr WHERE yr_key = @yr)
    BEGIN
        RAISERROR(N'test_sudz.Yr_DbtChangesD644: yr_key=%d не найден', 16, 1, @yr);
        RETURN;
    END;

    DECLARE @base_upl int;
    DECLARE @base_date date;
    DECLARE @curr_date date;
    DECLARE @cmm_gr int;

    SELECT
        @base_upl  = y.cn_inv_dbt_upl,
        @base_date = u.upl_date,
        @cmm_gr    = y.yr_CmmGr
    FROM test_sudz.yr y
    JOIN test_sudz.cn_inv_dbt_upl u ON u.upl_key = y.cn_inv_dbt_upl
    WHERE y.yr_key = @yr;

    IF @curr_upl IS NOT NULL
    BEGIN
        SELECT @curr_date = upl_date
        FROM test_sudz.cn_inv_dbt_upl
        WHERE upl_key = @curr_upl;

        IF @curr_date IS NULL
        BEGIN
            RAISERROR(N'test_sudz.Yr_DbtChangesD644: curr_upl=%d не найден', 16, 1, @curr_upl);
            RETURN;
        END;
    END
    ELSE
    BEGIN
        SELECT @curr_date = MAX(f.upl_date)
        FROM test_sudz.vw_Yr_DbtFact f
        WHERE f.yr_key = @yr;

        SELECT TOP (1) @curr_upl = f.upl_key
        FROM test_sudz.vw_Yr_DbtFact f
        WHERE f.yr_key = @yr AND f.upl_date = @curr_date
        ORDER BY f.upl_key;
    END;

    IF @curr_date IS NULL OR @base_date IS NULL
    BEGIN
        RAISERROR(N'test_sudz.Yr_DbtChangesD644: нет base/curr дат для yr_key=%d', 16, 1, @yr);
        RETURN;
    END;

    ;WITH base AS (
        SELECT
            f.dbtKey,
            f.account_num,
            f.org_id_value_l,
            f.ITN,
            f.CtptOrg,
            f.cnNumEnum,
            f.csoCnDate,
            f.invNumEnum,
            f.dvDateStart,
            f.dvDateMaturity,
            f.dvTtl,
            f.dvOverd,
            f.CstAgPnCode,
            f.CstAgPnName
        FROM test_sudz.vw_Yr_DbtFact f
        WHERE f.yr_key = @yr
          AND f.upl_date = @base_date
          AND f.dvOverd > 0
    ),
    curr AS (
        SELECT
            f.dbtKey,
            f.dvDateMaturity,
            f.dvOverd,
            f.CstAgPnCode,
            f.CstAgPnName
        FROM test_sudz.vw_Yr_DbtFact f
        WHERE f.yr_key = @yr
          AND f.upl_date = @curr_date
    ),
    cmm AS (
        SELECT
            cm.cnicInvAccnt AS dbtKey,
            MAX(CASE WHEN cm.cnicType = 1 THEN cm.cnicText END) AS mery
        FROM test_sudz.cnInvCmm cm
        WHERE cm.cnicGroup = @cmm_gr
        GROUP BY cm.cnicInvAccnt
    ),
    cst_yr AS (
        SELECT
            cs.ciccInvAccnt AS dbtKey,
            MAX(pn.cstapIpgPnN) AS cst_code,
            MAX(c.cstName) AS cst_name
        FROM test_sudz.cnInvCmmCst cs
        JOIN ags.cstAgPn pn ON pn.cstapKey = cs.ciccCstAgPn
        JOIN ags.cstAg ca ON ca.cstaKey = pn.cstapCsta
        JOIN ags.cst c ON c.cstKey = ca.cstaCst
        WHERE cs.ciccCmmGr = @cmm_gr
          AND cs.ciccType = 2
        GROUP BY cs.ciccInvAccnt
    ),
    resolved AS (
        SELECT
            b.dbtKey,
            b.account_num,
            b.org_id_value_l,
            b.ITN,
            b.CtptOrg,
            b.cnNumEnum,
            b.csoCnDate,
            b.invNumEnum,          -- база года (решение владельца)
            b.dvDateStart,
            b.dvDateMaturity AS base_Maturity,
            b.dvTtl AS base_Ttl,
            b.dvOverd AS base_Overd,
            c.dvDateMaturity AS curr_Maturity,
            c.dvOverd AS curr_Overd,
            NULLIF(CONVERT(money, b.dvOverd - c.dvOverd), 0) AS pogasheno,
            /* Access Rslt: IIf(IsNull(коммент), IIf(IsNull(curr), base, curr), коммент) */
            COALESCE(cy.cst_code, c.CstAgPnCode, b.CstAgPnCode) AS cst_code,
            COALESCE(cy.cst_name, c.CstAgPnName, b.CstAgPnName) AS cst_name,
            cm.mery
        FROM base b
        LEFT JOIN curr c ON c.dbtKey = b.dbtKey
        LEFT JOIN cmm cm ON cm.dbtKey = b.dbtKey
        LEFT JOIN cst_yr cy ON cy.dbtKey = b.dbtKey
    )
    SELECT
        r.dbtKey,
        r.account_num AS [Счёт Главной книги],
        ag.cstapOgName AS [Агент],
        r.org_id_value_l AS [№ контрагента],
        r.ITN AS [ИНН контрагента],
        r.CtptOrg AS [Контрагент],
        r.cnNumEnum AS [Договор],
        r.csoCnDate AS [Дата договора],
        r.invNumEnum AS [счет-фактура],
        r.dvDateStart AS [Дата образования],
        r.base_Maturity AS [Срок погашения base],
        r.base_Ttl AS [Всего сумма задолженности base],
        r.base_Overd AS [Просроченная задолженность base],
        r.curr_Maturity AS [Срок погашения curr],
        r.curr_Overd AS [Просроченная задолженность curr],
        r.pogasheno AS [Погашено проср задолженности с начала года],
        r.cst_code AS [Код стройки],
        r.cst_name AS [Наименование стройки],
        r.mery AS [Комментарий Филиала 644],
        /* служебные — для отладки / smoke; отчётный слой может отбросить */
        @base_date AS [_base_upl_date],
        @curr_date AS [_curr_upl_date],
        @base_upl  AS [_base_upl],
        @curr_upl  AS [_curr_upl]
    FROM resolved r
    LEFT JOIN ags.cstAgPn ag ON ag.cstapIpgPnN = r.cst_code
    ORDER BY
        r.account_num,
        ag.cstapOgName,
        r.CtptOrg,
        r.cnNumEnum,
        r.invNumEnum;
END
GO

/* Smoke: эталон D644_26-05, долги 82/85 (doc 7947 / А19) */
EXEC test_sudz.Yr_DbtChangesD644 @yr = 901, @curr_upl = 902;
GO
