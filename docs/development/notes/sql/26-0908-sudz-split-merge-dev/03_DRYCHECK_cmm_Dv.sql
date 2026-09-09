/*
 * S77 I4 — dry-check backfill *Dv (SELECT only).
 *
 * Зерно: cmm группы → DbtValue среза этой группы, не крайней upl канона.
 * Срез = upl года, который указывает на группу (yr_CmmGr / yr_CmmGr_New),
 * с uplStatusOnDate = cnInvCmmGr.cnicgDate.
 *
 * Не MSSQL2012/, не продуктив, не ags, не test_sudz.
 * lastUpdated: 2026-09-09
 */
SET NOCOUNT ON;
GO

;WITH grp_year AS (
    SELECT y.yr_key, y.yr_CmmGr AS cmmg, N'official' AS gk
    FROM sudz.yr AS y
    WHERE y.yr_CmmGr IS NOT NULL
    UNION ALL
    SELECT y.yr_key, y.yr_CmmGr_New, N'new'
    FROM sudz.yr AS y
    WHERE y.yr_CmmGr_New IS NOT NULL
),
grp_upl AS (
    SELECT gy.cmmg, gy.yr_key, gy.gk, u.upl_key
    FROM grp_year AS gy
    INNER JOIN sudz.cnInvCmmGr AS g ON g.cnicgKey = gy.cmmg
    INNER JOIN sudz.yr_upl_p AS yp ON yp.yr_upl_p_yr = gy.yr_key
    INNER JOIN sudz.cn_inv_dbt_upl AS u ON u.upl_key = yp.cn_inv_dbt_upl
        AND CAST(u.uplStatusOnDate AS date) = CAST(g.cnicgDate AS date)
)
SELECT N'cnInvCmm' AS tbl, cm.cnicKey AS rowKey, cm.cnicGroup AS cmmGr,
       COALESCE(cm.cnicDbt, cm.cnicInvAccnt) AS dbtKey,
       gu.upl_key AS uplKey, COUNT(DISTINCT dv.dvKey) AS nval,
       MIN(dv.dvKey) AS pickDv
FROM sudz.cnInvCmm AS cm
LEFT JOIN grp_upl AS gu ON gu.cmmg = cm.cnicGroup
LEFT JOIN sudz.invDbtDbt AS idd
    ON idd.iddDbt = COALESCE(cm.cnicDbt, cm.cnicInvAccnt)
LEFT JOIN sudz.DbtValue AS dv
    ON dv.dvInvDbt = idd.iddInvDbt AND dv.dvUpl = gu.upl_key
GROUP BY cm.cnicKey, cm.cnicGroup, COALESCE(cm.cnicDbt, cm.cnicInvAccnt), gu.upl_key
ORDER BY cm.cnicKey;
GO
