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
-- Полоса (2026-10-13): ось — доли базового свода. Высота = max(доли базы, доли среза).
-- Стыковка: общий слот dvInvDbt, затем оставшиеся доли по порядку idNum.
-- Одна доля базы и одна доля среза — одна строка, даже если ключ invDbt между
-- выгрузками сменился. Декартова произведения по dbtKey нет.
-- Зерно 1 сливается (_*_span > 1, значение в верхней строке).
-- Комментарий / код / агент (2026-10-15, walk-back): *Dv среза, иначе *Dv базы,
-- иначе Acc; _cmm_span = зерно фактического якоря (curr_span или base_span).
-- «Погашено» — канон долга: NULLIF(∑Overd базы − ∑Overd среза, 0).
--
-- Параметры: @yr; base = yr.cn_inv_dbt_upl; curr = MAX(upl_date) фактов года
--   (опционально @curr_upl — зафиксировать срез)
-- DEV only. sqlcmd -I
-- =============================================================================

SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE sudz.Yr_DbtChangesD644
    @yr       int,
    @curr_upl int = NULL  -- NULL → последний upl_date года в vw_Yr_DbtFact
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM sudz.yr WHERE yr_key = @yr)
    BEGIN
        RAISERROR(N'sudz.Yr_DbtChangesD644: yr_key=%d не найден', 16, 1, @yr);
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
    FROM sudz.yr y
    JOIN sudz.cn_inv_dbt_upl u ON u.upl_key = y.cn_inv_dbt_upl
    WHERE y.yr_key = @yr;

    IF @curr_upl IS NOT NULL
    BEGIN
        SELECT @curr_date = upl_date
        FROM sudz.cn_inv_dbt_upl
        WHERE upl_key = @curr_upl;

        IF @curr_date IS NULL
        BEGIN
            RAISERROR(N'sudz.Yr_DbtChangesD644: curr_upl=%d не найден', 16, 1, @curr_upl);
            RETURN;
        END;
    END
    ELSE
    BEGIN
        SELECT @curr_date = MAX(f.upl_date)
        FROM sudz.vw_Yr_DbtFact f
        WHERE f.yr_key = @yr;

        SELECT TOP (1) @curr_upl = f.upl_key
        FROM sudz.vw_Yr_DbtFact f
        WHERE f.yr_key = @yr AND f.upl_date = @curr_date
        ORDER BY f.upl_key;
    END;

    IF @curr_date IS NULL OR @base_date IS NULL
    BEGIN
        RAISERROR(N'sudz.Yr_DbtChangesD644: нет base/curr дат для yr_key=%d', 16, 1, @yr);
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
            f.CstAgPnName,
            f.idNum,
            sk.slotKey,
            sk.dvKey
        FROM sudz.vw_Yr_DbtFact f
        CROSS APPLY (
            SELECT TOP (1) dv.dvInvDbt AS slotKey, dv.dvKey AS dvKey
            FROM sudz.DbtValue dv
            INNER JOIN sudz.invDbt slot ON slot.idKey = dv.dvInvDbt
            INNER JOIN sudz.invDbtDbt idd
                ON idd.iddInvDbt = dv.dvInvDbt AND idd.iddDbt = f.dbtKey
            WHERE dv.dvUpl = f.upl_key AND slot.idNum = f.idNum
            ORDER BY dv.dvKey
        ) sk
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
            f.CstAgPnName,
            f.idNum,
            sk.slotKey,
            sk.dvKey
        FROM sudz.vw_Yr_DbtFact f
        CROSS APPLY (
            SELECT TOP (1) dv.dvInvDbt AS slotKey, dv.dvKey AS dvKey
            FROM sudz.DbtValue dv
            INNER JOIN sudz.invDbt slot ON slot.idKey = dv.dvInvDbt
            INNER JOIN sudz.invDbtDbt idd
                ON idd.iddInvDbt = dv.dvInvDbt AND idd.iddDbt = f.dbtKey
            WHERE dv.dvUpl = f.upl_key AND slot.idNum = f.idNum
            ORDER BY dv.dvKey
        ) sk
        WHERE f.yr_key = @yr
          AND f.upl_date = @curr_date
          AND EXISTS (
              SELECT 1 FROM base b WHERE b.dbtKey = f.dbtKey
          )
    ),
    -- Комментарий по *Dv (срез или база / walk-back); legacy InvAccnt — запасной путь.
    cmm_dv AS (
        SELECT
            cm.cnicDv AS dvKey,
            MAX(CASE WHEN cm.cnicType = 1 THEN cm.cnicText END) AS mery
        FROM sudz.cnInvCmm cm
        WHERE cm.cnicGroup = @cmm_gr
          AND cm.cnicDv IS NOT NULL
          AND cm.cnicType = 1
        GROUP BY cm.cnicDv
    ),
    cmm_acc AS (
        SELECT
            cm.cnicInvAccnt AS dbtKey,
            MAX(CASE WHEN cm.cnicType = 1 THEN cm.cnicText END) AS mery
        FROM sudz.cnInvCmm cm
        WHERE cm.cnicGroup = @cmm_gr
          AND cm.cnicType = 1
        GROUP BY cm.cnicInvAccnt
    ),
    cst_dv AS (
        SELECT
            cs.ciccDv AS dvKey,
            MAX(pn.cstapIpgPnN) AS cst_code,
            MAX(c.cstName) AS cst_name
        FROM sudz.cnInvCmmCst cs
        JOIN ags.cstAgPn pn ON pn.cstapKey = cs.ciccCstAgPn
        JOIN ags.cstAg ca ON ca.cstaKey = pn.cstapCsta
        JOIN ags.cst c ON c.cstKey = ca.cstaCst
        WHERE cs.ciccCmmGr = @cmm_gr
          AND cs.ciccType = 2
          AND cs.ciccDv IS NOT NULL
        GROUP BY cs.ciccDv
    ),
    cst_acc AS (
        SELECT
            cs.ciccInvAccnt AS dbtKey,
            MAX(pn.cstapIpgPnN) AS cst_code,
            MAX(c.cstName) AS cst_name
        FROM sudz.cnInvCmmCst cs
        JOIN ags.cstAgPn pn ON pn.cstapKey = cs.ciccCstAgPn
        JOIN ags.cstAg ca ON ca.cstaKey = pn.cstapCsta
        JOIN ags.cst c ON c.cstKey = ca.cstaCst
        WHERE cs.ciccCmmGr = @cmm_gr
          AND cs.ciccType = 2
        GROUP BY cs.ciccInvAccnt
    ),
    base_n AS (
        SELECT
            b.*,
            ROW_NUMBER() OVER (PARTITION BY b.dbtKey ORDER BY b.idNum, b.slotKey) AS rb,
            COUNT(*) OVER (PARTITION BY b.dbtKey) AS n_base
        FROM base b
    ),
    curr_n AS (
        SELECT
            c.*,
            ROW_NUMBER() OVER (PARTITION BY c.dbtKey ORDER BY c.idNum, c.slotKey) AS rc,
            COUNT(*) OVER (PARTITION BY c.dbtKey) AS n_curr
        FROM curr c
    ),
    paired AS (
        SELECT b.dbtKey, b.rb, c.rc
        FROM base_n b
        INNER JOIN curr_n c ON c.dbtKey = b.dbtKey AND c.slotKey = b.slotKey
    ),
    base_free AS (
        SELECT
            b.dbtKey,
            b.rb,
            ROW_NUMBER() OVER (PARTITION BY b.dbtKey ORDER BY b.rb) AS free_ord
        FROM base_n b
        WHERE NOT EXISTS (
            SELECT 1 FROM paired p WHERE p.dbtKey = b.dbtKey AND p.rb = b.rb
        )
    ),
    curr_free AS (
        SELECT
            c.dbtKey,
            c.rc,
            ROW_NUMBER() OVER (PARTITION BY c.dbtKey ORDER BY c.rc) AS free_ord
        FROM curr_n c
        WHERE NOT EXISTS (
            SELECT 1 FROM paired p WHERE p.dbtKey = c.dbtKey AND p.rc = c.rc
        )
    ),
    zipped AS (
        SELECT
            COALESCE(b.dbtKey, c.dbtKey) AS dbtKey,
            b.rb,
            c.rc
        FROM base_free b
        FULL OUTER JOIN curr_free c
            ON c.dbtKey = b.dbtKey AND c.free_ord = b.free_ord
    ),
    links AS (
        SELECT dbtKey, rb, rc FROM paired
        UNION ALL
        SELECT dbtKey, rb, rc FROM zipped
    ),
    numbered AS (
        SELECT
            l.dbtKey,
            l.rb,
            l.rc,
            CASE WHEN l.rb IS NOT NULL THEN 1 ELSE 0 END AS has_base,
            CASE WHEN l.rc IS NOT NULL THEN 1 ELSE 0 END AS has_curr,
            ROW_NUMBER() OVER (
                PARTITION BY l.dbtKey
                ORDER BY CASE WHEN l.rb IS NULL THEN 1 ELSE 0 END, l.rb, l.rc
            ) AS rn,
            COUNT(*) OVER (PARTITION BY l.dbtKey) AS band_n,
            bn.n_base,
            cn.n_curr
        FROM links l
        LEFT JOIN (
            SELECT dbtKey, MAX(n_base) AS n_base FROM base_n GROUP BY dbtKey
        ) bn ON bn.dbtKey = l.dbtKey
        LEFT JOIN (
            SELECT dbtKey, MAX(n_curr) AS n_curr FROM curr_n GROUP BY dbtKey
        ) cn ON cn.dbtKey = l.dbtKey
    ),
    sums AS (
        SELECT
            b.dbtKey,
            SUM(b.dvOverd) AS overd_base,
            (
                SELECT SUM(c.dvOverd) FROM curr c WHERE c.dbtKey = b.dbtKey
            ) AS overd_curr
        FROM base b
        GROUP BY b.dbtKey
    ),
    resolved AS (
        SELECT
            n.dbtKey,
            n.rn,
            n.band_n,
            COALESCE(b.account_num, hb.account_num) AS account_num,
            b.org_id_value_l,
            b.ITN,
            b.CtptOrg,
            b.cnNumEnum,
            b.csoCnDate,
            b.invNumEnum,
            b.dvDateStart,
            b.dvDateMaturity AS base_Maturity,
            b.dvTtl AS base_Ttl,
            b.dvOverd AS base_Overd,
            CASE
                WHEN n.n_curr = 1 AND n.rn = 1 THEN cone.dvDateMaturity
                WHEN n.n_curr > 1 AND n.has_curr = 1 THEN c.dvDateMaturity
            END AS curr_Maturity,
            CASE
                WHEN n.n_curr = 1 AND n.rn = 1 THEN cone.dvOverd
                WHEN n.n_curr > 1 AND n.has_curr = 1 THEN c.dvOverd
            END AS curr_Overd,
            CASE
                WHEN n.rn = 1 THEN NULLIF(CONVERT(money, sm.overd_base - ISNULL(sm.overd_curr, 0)), 0)
            END AS pogasheno,
            COALESCE(
                cyd_curr.cst_code, cyd_base.cst_code, cya.cst_code,
                ISNULL(c.CstAgPnCode, cone.CstAgPnCode), b.CstAgPnCode
            ) AS cst_code,
            COALESCE(
                cyd_curr.cst_name, cyd_base.cst_name, cya.cst_name,
                ISNULL(c.CstAgPnName, cone.CstAgPnName), b.CstAgPnName
            ) AS cst_name,
            COALESCE(cmd_curr.mery, cmd_base.mery, cma.mery) AS mery,
            CASE
                WHEN n.n_base = 1 AND n.has_base = 1 THEN n.band_n
                WHEN n.n_base > 1 AND n.has_base = 1 THEN 1
                ELSE 0
            END AS base_span,
            CASE
                WHEN n.n_curr = 1 AND n.rn = 1 THEN n.band_n
                WHEN n.n_curr > 1 AND n.has_curr = 1 THEN 1
                ELSE 0
            END AS curr_span,
            -- cmm_span = зерно фактического якоря комментария (срез → база → Acc).
            CASE
                WHEN cmd_curr.mery IS NOT NULL THEN
                    CASE
                        WHEN n.n_curr = 1 AND n.rn = 1 THEN n.band_n
                        WHEN n.n_curr > 1 AND n.has_curr = 1 THEN 1
                        ELSE 0
                    END
                WHEN cmd_base.mery IS NOT NULL THEN
                    CASE
                        WHEN n.n_base = 1 AND n.has_base = 1 THEN n.band_n
                        WHEN n.n_base > 1 AND n.has_base = 1 THEN 1
                        ELSE 0
                    END
                WHEN cma.mery IS NOT NULL AND n.has_curr = 1 THEN
                    CASE
                        WHEN n.n_curr = 1 AND n.rn = 1 THEN n.band_n
                        WHEN n.n_curr > 1 THEN 1
                        ELSE 0
                    END
                WHEN cma.mery IS NOT NULL THEN
                    CASE
                        WHEN n.n_base = 1 AND n.has_base = 1 THEN n.band_n
                        WHEN n.n_base > 1 AND n.has_base = 1 THEN 1
                        ELSE 0
                    END
                ELSE 0
            END AS cmm_span,
            CASE WHEN n.rn = 1 THEN n.band_n ELSE 0 END AS repaid_span
        FROM numbered n
        OUTER APPLY (
            SELECT TOP (1) bx.account_num
            FROM base bx
            WHERE bx.dbtKey = n.dbtKey
        ) hb
        LEFT JOIN base_n b ON b.dbtKey = n.dbtKey AND b.rb = n.rb
        LEFT JOIN curr_n c ON c.dbtKey = n.dbtKey AND c.rc = n.rc
        LEFT JOIN curr cone ON cone.dbtKey = n.dbtKey AND n.n_curr = 1
        LEFT JOIN base bone ON bone.dbtKey = n.dbtKey AND n.n_base = 1
        LEFT JOIN sums sm ON sm.dbtKey = n.dbtKey
        LEFT JOIN cmm_dv cmd_curr ON cmd_curr.dvKey = COALESCE(c.dvKey, cone.dvKey)
        LEFT JOIN cmm_dv cmd_base ON cmd_base.dvKey = COALESCE(b.dvKey, bone.dvKey)
        LEFT JOIN cmm_acc cma ON cma.dbtKey = n.dbtKey
        LEFT JOIN cst_dv cyd_curr ON cyd_curr.dvKey = COALESCE(c.dvKey, cone.dvKey)
        LEFT JOIN cst_dv cyd_base ON cyd_base.dvKey = COALESCE(b.dvKey, bone.dvKey)
        LEFT JOIN cst_acc cya ON cya.dbtKey = n.dbtKey
    )
    SELECT
        r.dbtKey,
        r.account_num AS [Счёт Главной книги],
        CASE WHEN r.cmm_span > 0 THEN ag.cstapOgName END AS [Агент],
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
        CASE WHEN r.cmm_span > 0 THEN r.cst_code END AS [Код стройки],
        CASE WHEN r.cmm_span > 0 THEN r.cst_name END AS [Наименование стройки],
        CASE WHEN r.cmm_span > 0 THEN r.mery END AS [Комментарий Филиала 644],
        @base_date AS [_base_upl_date],
        @curr_date AS [_curr_upl_date],
        @base_upl  AS [_base_upl],
        @curr_upl  AS [_curr_upl],
        r.rn AS [_band_rn],
        r.base_span AS [_base_span],
        r.curr_span AS [_curr_span],
        r.cmm_span AS [_cmm_span],
        r.repaid_span AS [_repaid_span]
    FROM resolved r
    LEFT JOIN ags.cstAgPn ag ON ag.cstapIpgPnN = r.cst_code
    ORDER BY
        r.account_num,
        r.CtptOrg,
        r.dbtKey,
        r.rn;
END
GO

/* Smoke: эталон D644_26-05, долги 82/85 (doc 7947 / А19) */
EXEC sudz.Yr_DbtChangesD644 @yr = 901, @curr_upl = 902;
GO
