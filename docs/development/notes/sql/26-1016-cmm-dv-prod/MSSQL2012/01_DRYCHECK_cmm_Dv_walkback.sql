/*
 * Узел 4.3. Сухой подсчёт walk-back. Данные не меняет.
 * would_bind — строки Acc, у которых нашлась Value на upl связанного года.
 * stay_no_value — год есть, Value в его upl нет.
 * stay_no_year — на группу не смотрит ни yr_CmmGr, ни yr_CmmGr_New.
 * lastUpdated: 2026-10-16
 */
SET NOCOUNT ON;

IF OBJECT_ID(N'tempdb..#linked') IS NOT NULL DROP TABLE #linked;
IF OBJECT_ID(N'tempdb..#picked_cmm') IS NOT NULL DROP TABLE #picked_cmm;

SELECT DISTINCT y.yr_key, y.yr_CmmGr AS cmm_gr
INTO #linked
FROM sudz.yr AS y
WHERE y.yr_CmmGr IS NOT NULL
UNION
SELECT DISTINCT y.yr_key, y.yr_CmmGr_New
FROM sudz.yr AS y
WHERE y.yr_CmmGr_New IS NOT NULL;

;WITH ranked AS (
    SELECT
        L.cmm_gr,
        L.yr_key,
        u.upl_key,
        ROW_NUMBER() OVER (
            PARTITION BY L.cmm_gr, L.yr_key
            ORDER BY COALESCE(u.uplStatusOnDate, u.upl_date) DESC, u.upl_key DESC
        ) AS rn
    FROM #linked AS L
    INNER JOIN sudz.yr_upl_p AS yp ON yp.yr_upl_p_yr = L.yr_key
    INNER JOIN sudz.cn_inv_dbt_upl AS u ON u.upl_key = yp.cn_inv_dbt_upl
),
hit AS (
    SELECT
        cm.cnicKey,
        ROW_NUMBER() OVER (PARTITION BY cm.cnicKey ORDER BY r.rn, r.yr_key) AS pick_ord
    FROM sudz.cnInvCmm AS cm
    INNER JOIN #linked AS L ON L.cmm_gr = cm.cnicGroup
    INNER JOIN ranked AS r ON r.cmm_gr = L.cmm_gr AND r.yr_key = L.yr_key
    INNER JOIN sudz.invDbtDbt AS idd
        ON idd.iddDbt = COALESCE(cm.cnicDbt, cm.cnicInvAccnt)
    INNER JOIN sudz.DbtValue AS dv
        ON dv.dvInvDbt = idd.iddInvDbt AND dv.dvUpl = r.upl_key
    WHERE cm.cnicDv IS NULL
)
SELECT cnicKey
INTO #picked_cmm
FROM hit
WHERE pick_ord = 1;

SELECT
    cm.cnicGroup AS cmm_gr,
    COUNT(*) AS null_dv,
    SUM(CASE WHEN p.cnicKey IS NOT NULL THEN 1 ELSE 0 END) AS would_bind,
    SUM(CASE WHEN p.cnicKey IS NULL AND L.cmm_gr IS NOT NULL THEN 1 ELSE 0 END) AS stay_no_value,
    SUM(CASE WHEN L.cmm_gr IS NULL THEN 1 ELSE 0 END) AS stay_no_year
FROM sudz.cnInvCmm AS cm
LEFT JOIN #picked_cmm AS p ON p.cnicKey = cm.cnicKey
LEFT JOIN (SELECT DISTINCT cmm_gr FROM #linked) AS L ON L.cmm_gr = cm.cnicGroup
WHERE cm.cnicDv IS NULL
GROUP BY cm.cnicGroup
ORDER BY cm.cnicGroup;

DROP TABLE #picked_cmm;
DROP TABLE #linked;
