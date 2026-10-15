/*
 * Узел 3.5 — dry-check миграции группы 907 на *Dv (SELECT only).
 *
 * Цель Value: крайняя upl каждого года, у которого yr_CmmGr / yr_CmmGr_New = 907
 * (дата группы 2026-10-12 не совпадает с uplStatusOnDate срезов — старый
 * backfill 04 по дате для 907 не сработал).
 *
 * Не MSSQL2012/, не продуктив.
 * lastUpdated: 2026-10-14
 */
SET NOCOUNT ON;
GO

DECLARE @cmm_gr int = 907;

;WITH yrs AS (
    SELECT DISTINCT y.yr_key
    FROM sudz.yr AS y
    WHERE y.yr_CmmGr = @cmm_gr OR y.yr_CmmGr_New = @cmm_gr
),
extreme AS (
    SELECT
        y.yr_key,
        u.upl_key,
        ROW_NUMBER() OVER (
            PARTITION BY y.yr_key
            ORDER BY COALESCE(u.uplStatusOnDate, u.upl_date) DESC, u.upl_key DESC
        ) AS rn
    FROM yrs AS y
    INNER JOIN sudz.yr_upl_p AS yp ON yp.yr_upl_p_yr = y.yr_key
    INNER JOIN sudz.cn_inv_dbt_upl AS u ON u.upl_key = yp.cn_inv_dbt_upl
),
target_upl AS (
    SELECT yr_key, upl_key FROM extreme WHERE rn = 1
)
SELECT N'target_upl' AS kind, t.yr_key, t.upl_key,
       CONVERT(varchar(10), u.upl_date, 23) AS upl_date
FROM target_upl AS t
JOIN sudz.cn_inv_dbt_upl AS u ON u.upl_key = t.upl_key
ORDER BY t.yr_key;
GO

DECLARE @cmm_gr int = 907;

;WITH yrs AS (
    SELECT DISTINCT y.yr_key
    FROM sudz.yr AS y
    WHERE y.yr_CmmGr = @cmm_gr OR y.yr_CmmGr_New = @cmm_gr
),
extreme AS (
    SELECT
        y.yr_key,
        u.upl_key,
        ROW_NUMBER() OVER (
            PARTITION BY y.yr_key
            ORDER BY COALESCE(u.uplStatusOnDate, u.upl_date) DESC, u.upl_key DESC
        ) AS rn
    FROM yrs AS y
    INNER JOIN sudz.yr_upl_p AS yp ON yp.yr_upl_p_yr = y.yr_key
    INNER JOIN sudz.cn_inv_dbt_upl AS u ON u.upl_key = yp.cn_inv_dbt_upl
),
target_upl AS (
    SELECT upl_key FROM extreme WHERE rn = 1
),
pick AS (
    SELECT
        cm.cnicKey,
        cm.cnicType,
        COALESCE(cm.cnicDbt, cm.cnicInvAccnt) AS dbtKey,
        COUNT(DISTINCT dv.dvKey) AS nval
    FROM sudz.cnInvCmm AS cm
    CROSS JOIN target_upl AS t
    LEFT JOIN sudz.invDbtDbt AS idd
        ON idd.iddDbt = COALESCE(cm.cnicDbt, cm.cnicInvAccnt)
    LEFT JOIN sudz.DbtValue AS dv
        ON dv.dvInvDbt = idd.iddInvDbt AND dv.dvUpl = t.upl_key
    WHERE cm.cnicGroup = @cmm_gr
      AND cm.cnicDv IS NULL
    GROUP BY cm.cnicKey, cm.cnicType, COALESCE(cm.cnicDbt, cm.cnicInvAccnt)
)
SELECT N'cnInvCmm' AS tbl, nval, COUNT(*) AS rows_cnt
FROM pick
GROUP BY nval
ORDER BY nval;

;WITH yrs AS (
    SELECT DISTINCT y.yr_key
    FROM sudz.yr AS y
    WHERE y.yr_CmmGr = @cmm_gr OR y.yr_CmmGr_New = @cmm_gr
),
extreme AS (
    SELECT
        y.yr_key,
        u.upl_key,
        ROW_NUMBER() OVER (
            PARTITION BY y.yr_key
            ORDER BY COALESCE(u.uplStatusOnDate, u.upl_date) DESC, u.upl_key DESC
        ) AS rn
    FROM yrs AS y
    INNER JOIN sudz.yr_upl_p AS yp ON yp.yr_upl_p_yr = y.yr_key
    INNER JOIN sudz.cn_inv_dbt_upl AS u ON u.upl_key = yp.cn_inv_dbt_upl
),
target_upl AS (
    SELECT upl_key FROM extreme WHERE rn = 1
),
pick AS (
    SELECT
        cs.ciccKey,
        COUNT(DISTINCT dv.dvKey) AS nval
    FROM sudz.cnInvCmmCst AS cs
    CROSS JOIN target_upl AS t
    LEFT JOIN sudz.invDbtDbt AS idd
        ON idd.iddDbt = COALESCE(cs.ciccDbt, cs.ciccInvAccnt)
    LEFT JOIN sudz.DbtValue AS dv
        ON dv.dvInvDbt = idd.iddInvDbt AND dv.dvUpl = t.upl_key
    WHERE cs.ciccCmmGr = @cmm_gr
      AND cs.ciccType = 2
      AND cs.ciccDv IS NULL
    GROUP BY cs.ciccKey
)
SELECT N'cnInvCmmCst' AS tbl, nval, COUNT(*) AS rows_cnt
FROM pick
GROUP BY nval
ORDER BY nval;
GO
