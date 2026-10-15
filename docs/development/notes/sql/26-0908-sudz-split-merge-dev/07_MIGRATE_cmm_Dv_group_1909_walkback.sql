/*
 * Walk-back Acc→*Dv для группы 1909 (re-import QII / узел 4.2).
 *
 * Отличие от 06 (группа 907): целевая upl — не только крайняя, а первая
 * с Value при обходе upl года от крайней к базе (тот же walk-back, что DAO).
 *
 * nval=1: UPDATE; nval>1: UPDATE + INSERT копий; nval=0: Acc остаётся.
 * Только группа 1909. Не 905/906. Не MSSQL2012/, не продуктив.
 * lastUpdated: 2026-10-15
 */
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @cmm_gr int = 1909;

BEGIN TRANSACTION;

IF OBJECT_ID(N'tempdb..#cmm_vals') IS NOT NULL DROP TABLE #cmm_vals;

;WITH yrs AS (
    SELECT DISTINCT y.yr_key
    FROM sudz.yr AS y
    WHERE y.yr_CmmGr = @cmm_gr OR y.yr_CmmGr_New = @cmm_gr
),
ranked AS (
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
/* На каждый Acc cmm — первая upl (по rn) с Value этого долга. */
picked AS (
    SELECT
        cm.cnicKey,
        r.upl_key,
        COALESCE(cm.cnicDbt, cm.cnicInvAccnt) AS dbtKey,
        ROW_NUMBER() OVER (
            PARTITION BY cm.cnicKey
            ORDER BY r.rn
        ) AS pick_ord
    FROM sudz.cnInvCmm AS cm
    INNER JOIN ranked AS r ON 1 = 1
    INNER JOIN sudz.invDbtDbt AS idd
        ON idd.iddDbt = COALESCE(cm.cnicDbt, cm.cnicInvAccnt)
    INNER JOIN sudz.DbtValue AS dv
        ON dv.dvInvDbt = idd.iddInvDbt AND dv.dvUpl = r.upl_key
    WHERE cm.cnicGroup = @cmm_gr
      AND cm.cnicDv IS NULL
)
SELECT
    p.cnicKey,
    dv.dvKey,
    p.dbtKey,
    ROW_NUMBER() OVER (
        PARTITION BY p.cnicKey
        ORDER BY s.idNum, s.idKey, dv.dvKey
    ) AS ord
INTO #cmm_vals
FROM picked AS p
INNER JOIN sudz.invDbtDbt AS idd ON idd.iddDbt = p.dbtKey
INNER JOIN sudz.DbtValue AS dv
    ON dv.dvInvDbt = idd.iddInvDbt AND dv.dvUpl = p.upl_key
INNER JOIN sudz.invDbt AS s ON s.idKey = dv.dvInvDbt
WHERE p.pick_ord = 1;

UPDATE cm
SET cm.cnicDv = v.dvKey,
    cm.cnicDbt = v.dbtKey,
    cm.cnicInvAccnt = v.dbtKey
FROM sudz.cnInvCmm AS cm
INNER JOIN #cmm_vals AS v ON v.cnicKey = cm.cnicKey AND v.ord = 1
WHERE cm.cnicDv IS NULL;

INSERT INTO sudz.cnInvCmm (
    cnicType, cnicGroup, cnicInv, cnicText, cnicInvAccnt, cnicDbt, cnicDv
)
SELECT
    cm.cnicType,
    cm.cnicGroup,
    cm.cnicInv,
    cm.cnicText,
    v.dbtKey,
    v.dbtKey,
    v.dvKey
FROM #cmm_vals AS v
INNER JOIN sudz.cnInvCmm AS cm ON cm.cnicKey = v.cnicKey
WHERE v.ord > 1
  AND NOT EXISTS (
      SELECT 1
      FROM sudz.cnInvCmm AS x
      WHERE x.cnicGroup = cm.cnicGroup
        AND x.cnicType = cm.cnicType
        AND x.cnicDv = v.dvKey
  );

IF OBJECT_ID(N'tempdb..#cst_vals') IS NOT NULL DROP TABLE #cst_vals;

;WITH yrs AS (
    SELECT DISTINCT y.yr_key
    FROM sudz.yr AS y
    WHERE y.yr_CmmGr = @cmm_gr OR y.yr_CmmGr_New = @cmm_gr
),
ranked AS (
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
picked AS (
    SELECT
        cs.ciccKey,
        r.upl_key,
        COALESCE(cs.ciccDbt, cs.ciccInvAccnt) AS dbtKey,
        ROW_NUMBER() OVER (
            PARTITION BY cs.ciccKey
            ORDER BY r.rn
        ) AS pick_ord
    FROM sudz.cnInvCmmCst AS cs
    INNER JOIN ranked AS r ON 1 = 1
    INNER JOIN sudz.invDbtDbt AS idd
        ON idd.iddDbt = COALESCE(cs.ciccDbt, cs.ciccInvAccnt)
    INNER JOIN sudz.DbtValue AS dv
        ON dv.dvInvDbt = idd.iddInvDbt AND dv.dvUpl = r.upl_key
    WHERE cs.ciccCmmGr = @cmm_gr
      AND cs.ciccType = 2
      AND cs.ciccDv IS NULL
)
SELECT
    p.ciccKey,
    dv.dvKey,
    p.dbtKey,
    ROW_NUMBER() OVER (
        PARTITION BY p.ciccKey
        ORDER BY s.idNum, s.idKey, dv.dvKey
    ) AS ord
INTO #cst_vals
FROM picked AS p
INNER JOIN sudz.invDbtDbt AS idd ON idd.iddDbt = p.dbtKey
INNER JOIN sudz.DbtValue AS dv
    ON dv.dvInvDbt = idd.iddInvDbt AND dv.dvUpl = p.upl_key
INNER JOIN sudz.invDbt AS s ON s.idKey = dv.dvInvDbt
WHERE p.pick_ord = 1;

UPDATE cs
SET cs.ciccDv = v.dvKey,
    cs.ciccDbt = v.dbtKey,
    cs.ciccInvAccnt = v.dbtKey
FROM sudz.cnInvCmmCst AS cs
INNER JOIN #cst_vals AS v ON v.ciccKey = cs.ciccKey AND v.ord = 1
WHERE cs.ciccDv IS NULL;

INSERT INTO sudz.cnInvCmmCst (
    ciccCmmGr, ciccType, ciccCstAgPn, ciccInvAccnt, ciccDbt, ciccDv
)
SELECT
    cs.ciccCmmGr,
    cs.ciccType,
    cs.ciccCstAgPn,
    v.dbtKey,
    v.dbtKey,
    v.dvKey
FROM #cst_vals AS v
INNER JOIN sudz.cnInvCmmCst AS cs ON cs.ciccKey = v.ciccKey
WHERE v.ord > 1
  AND NOT EXISTS (
      SELECT 1
      FROM sudz.cnInvCmmCst AS x
      WHERE x.ciccCmmGr = cs.ciccCmmGr
        AND x.ciccType = cs.ciccType
        AND x.ciccDv = v.dvKey
  );

COMMIT TRANSACTION;

SELECT N'cnInvCmm' AS tbl,
       COUNT(*) AS n,
       SUM(CASE WHEN cnicDv IS NULL THEN 1 ELSE 0 END) AS null_dv,
       SUM(CASE WHEN cnicDv IS NOT NULL THEN 1 ELSE 0 END) AS with_dv
FROM sudz.cnInvCmm
WHERE cnicGroup = @cmm_gr
UNION ALL
SELECT N'cnInvCmmCst',
       COUNT(*),
       SUM(CASE WHEN ciccDv IS NULL THEN 1 ELSE 0 END),
       SUM(CASE WHEN ciccDv IS NOT NULL THEN 1 ELSE 0 END)
FROM sudz.cnInvCmmCst
WHERE ciccCmmGr = @cmm_gr AND ciccType = 2;
