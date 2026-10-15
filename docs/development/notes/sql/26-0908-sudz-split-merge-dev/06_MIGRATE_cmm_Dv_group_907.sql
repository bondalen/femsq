/*
 * Узел 3.5 — миграция группы 907: Acc-only → *Dv на Value крайних upl.
 *
 * Канон (08 §7 / 3.3–3.4): зерно комментария = Value крайней выгрузки года,
 * который смотрит на группу. Дата группы не равна дате среза — поэтому не
 * backfill 04 (по cnicgDate), а крайняя upl каждого связанного года.
 *
 * nval=1: UPDATE существующей строки.
 * nval>1: UPDATE на первую Value; INSERT копий на остальные (один текст).
 * nval=0: не трогаем (остаётся fallback InvAccnt до прод-пакета).
 *
 * Только группа 907. Не 905/906. Не MSSQL2012/, не продуктив.
 * lastUpdated: 2026-10-14
 */
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @cmm_gr int = 907;

BEGIN TRANSACTION;

/* ---- cnInvCmm ---- */
IF OBJECT_ID(N'tempdb..#cmm_vals') IS NOT NULL DROP TABLE #cmm_vals;

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
)
SELECT
    cm.cnicKey,
    dv.dvKey,
    COALESCE(cm.cnicDbt, cm.cnicInvAccnt) AS dbtKey,
    ROW_NUMBER() OVER (
        PARTITION BY cm.cnicKey
        ORDER BY dv.dvUpl, s.idNum, s.idKey, dv.dvKey
    ) AS ord
INTO #cmm_vals
FROM sudz.cnInvCmm AS cm
INNER JOIN target_upl AS t ON 1 = 1
INNER JOIN sudz.invDbtDbt AS idd
    ON idd.iddDbt = COALESCE(cm.cnicDbt, cm.cnicInvAccnt)
INNER JOIN sudz.DbtValue AS dv
    ON dv.dvInvDbt = idd.iddInvDbt AND dv.dvUpl = t.upl_key
INNER JOIN sudz.invDbt AS s ON s.idKey = dv.dvInvDbt
WHERE cm.cnicGroup = @cmm_gr
  AND cm.cnicDv IS NULL;

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

/* ---- cnInvCmmCst (type=2) ---- */
IF OBJECT_ID(N'tempdb..#cst_vals') IS NOT NULL DROP TABLE #cst_vals;

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
)
SELECT
    cs.ciccKey,
    dv.dvKey,
    COALESCE(cs.ciccDbt, cs.ciccInvAccnt) AS dbtKey,
    ROW_NUMBER() OVER (
        PARTITION BY cs.ciccKey
        ORDER BY dv.dvUpl, s.idNum, s.idKey, dv.dvKey
    ) AS ord
INTO #cst_vals
FROM sudz.cnInvCmmCst AS cs
INNER JOIN target_upl AS t ON 1 = 1
INNER JOIN sudz.invDbtDbt AS idd
    ON idd.iddDbt = COALESCE(cs.ciccDbt, cs.ciccInvAccnt)
INNER JOIN sudz.DbtValue AS dv
    ON dv.dvInvDbt = idd.iddInvDbt AND dv.dvUpl = t.upl_key
INNER JOIN sudz.invDbt AS s ON s.idKey = dv.dvInvDbt
WHERE cs.ciccCmmGr = @cmm_gr
  AND cs.ciccType = 2
  AND cs.ciccDv IS NULL;

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
