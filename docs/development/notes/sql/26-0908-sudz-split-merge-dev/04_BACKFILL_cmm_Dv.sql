/*
 * S77 I4 — backfill *Dv на DEV sudz.
 *
 * Посадка существующих cmm на единственную DbtValue среза группы
 * (yr → upl с датой группы). nval<>1 не трогаем.
 * Дополнительно копируем *InvAccnt → *Dbt, если *Dbt ещё NULL.
 *
 * Не MSSQL2012/, не продуктив, не ags, не test_sudz.
 * lastUpdated: 2026-09-09
 */
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

BEGIN TRANSACTION;

;WITH grp_year AS (
    SELECT y.yr_key, y.yr_CmmGr AS cmmg
    FROM sudz.yr AS y
    WHERE y.yr_CmmGr IS NOT NULL
    UNION ALL
    SELECT y.yr_key, y.yr_CmmGr_New
    FROM sudz.yr AS y
    WHERE y.yr_CmmGr_New IS NOT NULL
),
grp_upl AS (
    SELECT gy.cmmg, u.upl_key
    FROM grp_year AS gy
    INNER JOIN sudz.cnInvCmmGr AS g ON g.cnicgKey = gy.cmmg
    INNER JOIN sudz.yr_upl_p AS yp ON yp.yr_upl_p_yr = gy.yr_key
    INNER JOIN sudz.cn_inv_dbt_upl AS u ON u.upl_key = yp.cn_inv_dbt_upl
        AND CAST(u.uplStatusOnDate AS date) = CAST(g.cnicgDate AS date)
),
pick AS (
    SELECT cm.cnicKey, MIN(dv.dvKey) AS dvKey
    FROM sudz.cnInvCmm AS cm
    INNER JOIN grp_upl AS gu ON gu.cmmg = cm.cnicGroup
    INNER JOIN sudz.invDbtDbt AS idd
        ON idd.iddDbt = COALESCE(cm.cnicDbt, cm.cnicInvAccnt)
    INNER JOIN sudz.DbtValue AS dv
        ON dv.dvInvDbt = idd.iddInvDbt AND dv.dvUpl = gu.upl_key
    WHERE cm.cnicDv IS NULL
    GROUP BY cm.cnicKey
    HAVING COUNT(DISTINCT dv.dvKey) = 1
)
UPDATE cm
    SET cm.cnicDv = p.dvKey,
        cm.cnicDbt = COALESCE(cm.cnicDbt, cm.cnicInvAccnt)
FROM sudz.cnInvCmm AS cm
INNER JOIN pick AS p ON p.cnicKey = cm.cnicKey;

;WITH grp_year AS (
    SELECT y.yr_key, y.yr_CmmGr AS cmmg
    FROM sudz.yr AS y
    WHERE y.yr_CmmGr IS NOT NULL
    UNION ALL
    SELECT y.yr_key, y.yr_CmmGr_New
    FROM sudz.yr AS y
    WHERE y.yr_CmmGr_New IS NOT NULL
),
grp_upl AS (
    SELECT gy.cmmg, u.upl_key
    FROM grp_year AS gy
    INNER JOIN sudz.cnInvCmmGr AS g ON g.cnicgKey = gy.cmmg
    INNER JOIN sudz.yr_upl_p AS yp ON yp.yr_upl_p_yr = gy.yr_key
    INNER JOIN sudz.cn_inv_dbt_upl AS u ON u.upl_key = yp.cn_inv_dbt_upl
        AND CAST(u.uplStatusOnDate AS date) = CAST(g.cnicgDate AS date)
),
pick AS (
    SELECT ag.cicaKey AS rowKey, MIN(dv.dvKey) AS dvKey
    FROM sudz.cnInvCmmAg AS ag
    INNER JOIN grp_upl AS gu ON gu.cmmg = ag.cicaCmmGr
    INNER JOIN sudz.invDbtDbt AS idd
        ON idd.iddDbt = COALESCE(ag.cicaDbt, ag.cicaInvAccnt)
    INNER JOIN sudz.DbtValue AS dv
        ON dv.dvInvDbt = idd.iddInvDbt AND dv.dvUpl = gu.upl_key
    WHERE ag.cicaDv IS NULL
    GROUP BY ag.cicaKey
    HAVING COUNT(DISTINCT dv.dvKey) = 1
)
UPDATE ag
    SET ag.cicaDv = p.dvKey,
        ag.cicaDbt = COALESCE(ag.cicaDbt, ag.cicaInvAccnt)
FROM sudz.cnInvCmmAg AS ag
INNER JOIN pick AS p ON p.rowKey = ag.cicaKey;

;WITH grp_year AS (
    SELECT y.yr_key, y.yr_CmmGr AS cmmg
    FROM sudz.yr AS y
    WHERE y.yr_CmmGr IS NOT NULL
    UNION ALL
    SELECT y.yr_key, y.yr_CmmGr_New
    FROM sudz.yr AS y
    WHERE y.yr_CmmGr_New IS NOT NULL
),
grp_upl AS (
    SELECT gy.cmmg, u.upl_key
    FROM grp_year AS gy
    INNER JOIN sudz.cnInvCmmGr AS g ON g.cnicgKey = gy.cmmg
    INNER JOIN sudz.yr_upl_p AS yp ON yp.yr_upl_p_yr = gy.yr_key
    INNER JOIN sudz.cn_inv_dbt_upl AS u ON u.upl_key = yp.cn_inv_dbt_upl
        AND CAST(u.uplStatusOnDate AS date) = CAST(g.cnicgDate AS date)
),
pick AS (
    SELECT cs.ciccKey AS rowKey, MIN(dv.dvKey) AS dvKey
    FROM sudz.cnInvCmmCst AS cs
    INNER JOIN grp_upl AS gu ON gu.cmmg = cs.ciccCmmGr
    INNER JOIN sudz.invDbtDbt AS idd
        ON idd.iddDbt = COALESCE(cs.ciccDbt, cs.ciccInvAccnt)
    INNER JOIN sudz.DbtValue AS dv
        ON dv.dvInvDbt = idd.iddInvDbt AND dv.dvUpl = gu.upl_key
    WHERE cs.ciccDv IS NULL
    GROUP BY cs.ciccKey
    HAVING COUNT(DISTINCT dv.dvKey) = 1
)
UPDATE cs
    SET cs.ciccDv = p.dvKey,
        cs.ciccDbt = COALESCE(cs.ciccDbt, cs.ciccInvAccnt)
FROM sudz.cnInvCmmCst AS cs
INNER JOIN pick AS p ON p.rowKey = cs.ciccKey;

;WITH grp_year AS (
    SELECT y.yr_key, y.yr_CmmGr AS cmmg
    FROM sudz.yr AS y
    WHERE y.yr_CmmGr IS NOT NULL
    UNION ALL
    SELECT y.yr_key, y.yr_CmmGr_New
    FROM sudz.yr AS y
    WHERE y.yr_CmmGr_New IS NOT NULL
),
grp_upl AS (
    SELECT gy.cmmg, u.upl_key
    FROM grp_year AS gy
    INNER JOIN sudz.cnInvCmmGr AS g ON g.cnicgKey = gy.cmmg
    INNER JOIN sudz.yr_upl_p AS yp ON yp.yr_upl_p_yr = gy.yr_key
    INNER JOIN sudz.cn_inv_dbt_upl AS u ON u.upl_key = yp.cn_inv_dbt_upl
        AND CAST(u.uplStatusOnDate AS date) = CAST(g.cnicgDate AS date)
),
pick AS (
    SELECT dt.cnicdKey AS rowKey, MIN(dv.dvKey) AS dvKey
    FROM sudz.cnInvCmmDt AS dt
    INNER JOIN grp_upl AS gu ON gu.cmmg = dt.cnicdCmmGr
    INNER JOIN sudz.invDbtDbt AS idd
        ON idd.iddDbt = COALESCE(dt.cnicdDbt, dt.cnicdInvAccnt)
    INNER JOIN sudz.DbtValue AS dv
        ON dv.dvInvDbt = idd.iddInvDbt AND dv.dvUpl = gu.upl_key
    WHERE dt.cnicdDv IS NULL
    GROUP BY dt.cnicdKey
    HAVING COUNT(DISTINCT dv.dvKey) = 1
)
UPDATE dt
    SET dt.cnicdDv = p.dvKey,
        dt.cnicdDbt = COALESCE(dt.cnicdDbt, dt.cnicdInvAccnt)
FROM sudz.cnInvCmmDt AS dt
INNER JOIN pick AS p ON p.rowKey = dt.cnicdKey;

;WITH grp_year AS (
    SELECT y.yr_key, y.yr_CmmGr AS cmmg
    FROM sudz.yr AS y
    WHERE y.yr_CmmGr IS NOT NULL
    UNION ALL
    SELECT y.yr_key, y.yr_CmmGr_New
    FROM sudz.yr AS y
    WHERE y.yr_CmmGr_New IS NOT NULL
),
grp_upl AS (
    SELECT gy.cmmg, u.upl_key
    FROM grp_year AS gy
    INNER JOIN sudz.cnInvCmmGr AS g ON g.cnicgKey = gy.cmmg
    INNER JOIN sudz.yr_upl_p AS yp ON yp.yr_upl_p_yr = gy.yr_key
    INNER JOIN sudz.cn_inv_dbt_upl AS u ON u.upl_key = yp.cn_inv_dbt_upl
        AND CAST(u.uplStatusOnDate AS date) = CAST(g.cnicgDate AS date)
),
pick AS (
    SELECT fn.cnicfKey AS rowKey, MIN(dv.dvKey) AS dvKey
    FROM sudz.cnInvCmmFn AS fn
    INNER JOIN grp_upl AS gu ON gu.cmmg = fn.cnicfCmmGr
    INNER JOIN sudz.invDbtDbt AS idd
        ON idd.iddDbt = COALESCE(fn.cnicfDbt, fn.cnicfInvAccnt)
    INNER JOIN sudz.DbtValue AS dv
        ON dv.dvInvDbt = idd.iddInvDbt AND dv.dvUpl = gu.upl_key
    WHERE fn.cnicfDv IS NULL
    GROUP BY fn.cnicfKey
    HAVING COUNT(DISTINCT dv.dvKey) = 1
)
UPDATE fn
    SET fn.cnicfDv = p.dvKey,
        fn.cnicfDbt = COALESCE(fn.cnicfDbt, fn.cnicfInvAccnt)
FROM sudz.cnInvCmmFn AS fn
INNER JOIN pick AS p ON p.rowKey = fn.cnicfKey;

;WITH grp_year AS (
    SELECT y.yr_key, y.yr_CmmGr AS cmmg
    FROM sudz.yr AS y
    WHERE y.yr_CmmGr IS NOT NULL
    UNION ALL
    SELECT y.yr_key, y.yr_CmmGr_New
    FROM sudz.yr AS y
    WHERE y.yr_CmmGr_New IS NOT NULL
),
grp_upl AS (
    SELECT gy.cmmg, u.upl_key
    FROM grp_year AS gy
    INNER JOIN sudz.cnInvCmmGr AS g ON g.cnicgKey = gy.cmmg
    INNER JOIN sudz.yr_upl_p AS yp ON yp.yr_upl_p_yr = gy.yr_key
    INNER JOIN sudz.cn_inv_dbt_upl AS u ON u.upl_key = yp.cn_inv_dbt_upl
        AND CAST(u.uplStatusOnDate AS date) = CAST(g.cnicgDate AS date)
),
pick AS (
    SELECT gr.cnigKey AS rowKey, MIN(dv.dvKey) AS dvKey
    FROM sudz.cnInvGr AS gr
    INNER JOIN grp_upl AS gu ON gu.cmmg = gr.cnigCmmGr
    INNER JOIN sudz.invDbtDbt AS idd
        ON idd.iddDbt = COALESCE(gr.cnigDbt, gr.cnigInvAccnt)
    INNER JOIN sudz.DbtValue AS dv
        ON dv.dvInvDbt = idd.iddInvDbt AND dv.dvUpl = gu.upl_key
    WHERE gr.cnigDv IS NULL
    GROUP BY gr.cnigKey
    HAVING COUNT(DISTINCT dv.dvKey) = 1
)
UPDATE gr
    SET gr.cnigDv = p.dvKey,
        gr.cnigDbt = COALESCE(gr.cnigDbt, gr.cnigInvAccnt)
FROM sudz.cnInvGr AS gr
INNER JOIN pick AS p ON p.rowKey = gr.cnigKey;

COMMIT TRANSACTION;

SELECT N'cnInvCmm' AS tbl, COUNT(*) AS n, SUM(CASE WHEN cnicDv IS NULL THEN 1 ELSE 0 END) AS null_dv
FROM sudz.cnInvCmm
UNION ALL SELECT N'Ag', COUNT(*), SUM(CASE WHEN cicaDv IS NULL THEN 1 ELSE 0 END) FROM sudz.cnInvCmmAg
UNION ALL SELECT N'Cst', COUNT(*), SUM(CASE WHEN ciccDv IS NULL THEN 1 ELSE 0 END) FROM sudz.cnInvCmmCst
UNION ALL SELECT N'Dt', COUNT(*), SUM(CASE WHEN cnicdDv IS NULL THEN 1 ELSE 0 END) FROM sudz.cnInvCmmDt
UNION ALL SELECT N'Fn', COUNT(*), SUM(CASE WHEN cnicfDv IS NULL THEN 1 ELSE 0 END) FROM sudz.cnInvCmmFn
UNION ALL SELECT N'Gr', COUNT(*), SUM(CASE WHEN cnigDv IS NULL THEN 1 ELSE 0 END) FROM sudz.cnInvGr;
GO
