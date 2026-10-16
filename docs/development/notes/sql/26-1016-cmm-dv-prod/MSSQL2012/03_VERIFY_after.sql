/*
 * Узел 4.3. Остаток Acc после 02. Данные не меняет.
 * stay_no_year должен совпасть с сухим подсчётом 01 для групп без указателя.
 * lastUpdated: 2026-10-16
 */
SET NOCOUNT ON;

SELECT
    cm.cnicGroup AS cmm_gr,
    COUNT(*) AS rows_n,
    SUM(CASE WHEN cm.cnicDv IS NULL THEN 1 ELSE 0 END) AS null_dv,
    SUM(CASE WHEN cm.cnicDv IS NOT NULL THEN 1 ELSE 0 END) AS with_dv,
    CASE WHEN EXISTS (
        SELECT 1 FROM sudz.yr AS y
        WHERE y.yr_CmmGr = cm.cnicGroup OR y.yr_CmmGr_New = cm.cnicGroup
    ) THEN N'linked' ELSE N'no year pointer' END AS link
FROM sudz.cnInvCmm AS cm
GROUP BY cm.cnicGroup
ORDER BY cm.cnicGroup;

SELECT
    cs.ciccCmmGr AS cmm_gr,
    COUNT(*) AS rows_n,
    SUM(CASE WHEN cs.ciccDv IS NULL THEN 1 ELSE 0 END) AS null_dv
FROM sudz.cnInvCmmCst AS cs
WHERE cs.ciccType = 2
GROUP BY cs.ciccCmmGr
ORDER BY cs.ciccCmmGr;
