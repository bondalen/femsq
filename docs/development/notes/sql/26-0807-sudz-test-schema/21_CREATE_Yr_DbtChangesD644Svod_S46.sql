-- =============================================================================
-- S46b: годовой свод «СВОД по субсчетам Д644»
-- Эталон: excel/2025-12/debit/Приложение 1. Информация о состоянии…xlsx
-- Лист: «СВОД по субсчетам Д644»
--
-- Access SQL в 23-0421_sql.docx НЕТ — логика снята с Excel:
--   гр.3 = SUM(Overd base) по долгам портфеля (Overd base > 0)
--   гр.4 = SUM(NULLIF(Overd base − Overd curr, 0))  — погашено с начала года
--   гр.5 = SUM(Overd curr) по тем же долгам         — остаток просрочки портфеля
--   гр.6 = гр.4 / гр.3 * 100                        — % погашения
-- Имена счетов — ags.accnt.
--
-- Параметры как у D644: @yr, @curr_upl (NULL → MAX upl_date года).
-- Песочница сейчас содержит только долги 82/85 → итоги ≠ Excel-миллиардов
-- (полный портфель не засеян). Формулы и форма строк — проверяемые.
-- DEV only. sqlcmd -I
-- =============================================================================

SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE test_sudz.Yr_DbtChangesD644Svod
    @yr       int,
    @curr_upl int = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM test_sudz.yr WHERE yr_key = @yr)
    BEGIN
        RAISERROR(N'test_sudz.Yr_DbtChangesD644Svod: yr_key=%d не найден', 16, 1, @yr);
        RETURN;
    END;

    DECLARE @base_upl int, @base_date date, @curr_date date;

    SELECT
        @base_upl  = y.cn_inv_dbt_upl,
        @base_date = u.upl_date
    FROM test_sudz.yr y
    JOIN test_sudz.cn_inv_dbt_upl u ON u.upl_key = y.cn_inv_dbt_upl
    WHERE y.yr_key = @yr;

    IF @curr_upl IS NOT NULL
        SELECT @curr_date = upl_date FROM test_sudz.cn_inv_dbt_upl WHERE upl_key = @curr_upl;
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

    IF @base_date IS NULL OR @curr_date IS NULL
    BEGIN
        RAISERROR(N'test_sudz.Yr_DbtChangesD644Svod: нет base/curr дат для yr=%d', 16, 1, @yr);
        RETURN;
    END;

    /* Эталонный перечень счетов из листа «СВОД…» (порядок как в Excel) */
    ;WITH acc_list AS (
        SELECT * FROM (VALUES
            (601300), (601750), (601760),
            (606012), (606022),
            (682102), (761010), (762210),
            (767401), (767403), (767501), (767502)
        ) v(account_num)
    ),
    base AS (
        SELECT f.dbtKey, f.account_num, f.dvOverd
        FROM test_sudz.vw_Yr_DbtFact f
        WHERE f.yr_key = @yr
          AND f.upl_date = @base_date
          AND f.dvOverd > 0
    ),
    curr AS (
        SELECT f.dbtKey, f.dvOverd
        FROM test_sudz.vw_Yr_DbtFact f
        WHERE f.yr_key = @yr
          AND f.upl_date = @curr_date
    ),
    by_dbt AS (
        SELECT
            b.account_num,
            b.dvOverd AS overd_base,
            ISNULL(c.dvOverd, 0) AS overd_curr,
            NULLIF(CONVERT(money, b.dvOverd - ISNULL(c.dvOverd, 0)), 0) AS pogasheno
        FROM base b
        LEFT JOIN curr c ON c.dbtKey = b.dbtKey
    ),
    agg AS (
        SELECT
            account_num,
            SUM(overd_base) AS overd_base_sum,
            SUM(ISNULL(pogasheno, 0)) AS pogasheno_sum,
            SUM(overd_curr) AS overd_curr_sum
        FROM by_dbt
        GROUP BY account_num
    )
    SELECT
        a.account_num AS [№ счётов бухгалтерского учета],
        ac.account_name AS [Наименование счёта],
        CONVERT(money, ISNULL(g.overd_base_sum, 0)) AS [Сумма просроченной ДЗ на начало года],
        CONVERT(money, ISNULL(g.pogasheno_sum, 0)) AS [Погашено просроченной ДЗ с начала года],
        CONVERT(money, ISNULL(g.overd_curr_sum, 0)) AS [Остаток просроченной ДЗ портфеля],
        CASE
            WHEN ISNULL(g.overd_base_sum, 0) = 0 THEN CONVERT(float, 0)
            ELSE CONVERT(float, g.pogasheno_sum) / CONVERT(float, g.overd_base_sum) * 100.0
        END AS [Погашено в %],
        @base_date AS [_base_upl_date],
        @curr_date AS [_curr_upl_date],
        @yr AS [_yr],
        @curr_upl AS [_curr_upl]
    FROM acc_list a
    LEFT JOIN agg g ON g.account_num = a.account_num
    LEFT JOIN ags.accnt ac ON ac.account_num = a.account_num
    ORDER BY a.account_num;

    /* Итоговая строка ВСЕГО — отдельным result set для удобства отчёта */
    ;WITH base AS (
        SELECT f.dbtKey, f.dvOverd
        FROM test_sudz.vw_Yr_DbtFact f
        WHERE f.yr_key = @yr AND f.upl_date = @base_date AND f.dvOverd > 0
    ),
    curr AS (
        SELECT f.dbtKey, f.dvOverd
        FROM test_sudz.vw_Yr_DbtFact f
        WHERE f.yr_key = @yr AND f.upl_date = @curr_date
    ),
    by_dbt AS (
        SELECT
            b.dvOverd AS overd_base,
            ISNULL(c.dvOverd, 0) AS overd_curr,
            ISNULL(NULLIF(CONVERT(money, b.dvOverd - ISNULL(c.dvOverd, 0)), 0), 0) AS pogasheno
        FROM base b
        LEFT JOIN curr c ON c.dbtKey = b.dbtKey
    )
    SELECT
        N'ВСЕГО' AS [Наименование],
        CONVERT(money, SUM(overd_base)) AS [Сумма просроченной ДЗ на начало года],
        CONVERT(money, SUM(pogasheno)) AS [Погашено просроченной ДЗ с начала года],
        CONVERT(money, SUM(overd_curr)) AS [Остаток просроченной ДЗ портфеля],
        CASE
            WHEN SUM(overd_base) = 0 THEN CONVERT(float, 0)
            ELSE CONVERT(float, SUM(pogasheno)) / CONVERT(float, SUM(overd_base)) * 100.0
        END AS [Погашено в %]
    FROM by_dbt;
END
GO
