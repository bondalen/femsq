-- =============================================================================
-- 26-0928 VERIFY after: yr_upl_p_q
-- lastUpdated: 2026-09-28
-- =============================================================================

SET NOCOUNT ON;

SELECT c.name AS column_name, ty.name AS type_name, c.is_nullable
FROM sys.columns c
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE c.object_id = OBJECT_ID(N'sudz.yr_upl_p')
  AND c.name = N'yr_upl_p_q';

SELECT name AS constraint_name
FROM sys.check_constraints
WHERE parent_object_id = OBJECT_ID(N'sudz.yr_upl_p')
  AND name = N'CK_yr_upl_p_q';

SELECT i.name AS index_name, i.is_unique
FROM sys.indexes i
WHERE i.object_id = OBJECT_ID(N'sudz.yr_upl_p')
  AND i.name = N'UX_yr_upl_p_YrQ';

SELECT yp.yr_upl_p_yr, yp.yr_upl_p_q, COUNT(*) AS cnt
FROM sudz.yr_upl_p AS yp
GROUP BY yp.yr_upl_p_yr, yp.yr_upl_p_q
HAVING COUNT(*) > 1;

SELECT TOP 20
    yp.yr_upl_p_yr,
    yp.yr_upl_p_q,
    yp.cn_inv_dbt_upl,
    CONVERT(varchar(10), u.uplStatusOnDate, 23) AS asOf
FROM sudz.yr_upl_p AS yp
INNER JOIN sudz.cn_inv_dbt_upl AS u ON u.upl_key = yp.cn_inv_dbt_upl
WHERE yp.yr_upl_p_yr IN (900, 901)
ORDER BY yp.yr_upl_p_yr, yp.yr_upl_p_q;
GO
