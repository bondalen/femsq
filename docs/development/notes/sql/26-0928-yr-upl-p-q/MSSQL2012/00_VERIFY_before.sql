-- =============================================================================
-- 26-0928 VERIFY before: yr_upl_p_q
-- lastUpdated: 2026-09-28
-- =============================================================================

SET NOCOUNT ON;

SELECT
    CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(128)) AS product_version,
    CAST(SERVERPROPERTY('ProductLevel') AS nvarchar(128)) AS product_level;

SELECT
    CASE WHEN COL_LENGTH(N'sudz.yr_upl_p', N'yr_upl_p_q') IS NULL
         THEN N'missing (ожидается до ALTER)'
         ELSE N'already present'
    END AS yr_upl_p_q_status;

-- Дубли yr + дата среза (блокируют UNIQUE по слоту)
SELECT yp.yr_upl_p_yr, CONVERT(date, u.uplStatusOnDate) AS asOf, COUNT(*) AS cnt
FROM sudz.yr_upl_p AS yp
INNER JOIN sudz.cn_inv_dbt_upl AS u ON u.upl_key = yp.cn_inv_dbt_upl
GROUP BY yp.yr_upl_p_yr, CONVERT(date, u.uplStatusOnDate)
HAVING COUNT(*) > 1;

-- Даты вне канонических слотов портфеля
SELECT yp.yr_upl_p_key, yp.yr_upl_p_yr, yp.cn_inv_dbt_upl,
       CONVERT(varchar(10), u.uplStatusOnDate, 23) AS asOf
FROM sudz.yr_upl_p AS yp
INNER JOIN sudz.yr AS y ON y.yr_key = yp.yr_upl_p_yr
INNER JOIN sudz.cn_inv_dbt_upl AS bu ON bu.upl_key = y.cn_inv_dbt_upl
INNER JOIN sudz.cn_inv_dbt_upl AS u ON u.upl_key = yp.cn_inv_dbt_upl
WHERE u.uplStatusOnDate IS NULL
   OR CONVERT(date, u.uplStatusOnDate) NOT IN (
        DATEFROMPARTS(YEAR(bu.uplStatusOnDate), 12, 31),
        DATEFROMPARTS(YEAR(bu.uplStatusOnDate) + 1, 3, 31),
        DATEFROMPARTS(YEAR(bu.uplStatusOnDate) + 1, 6, 30),
        DATEFROMPARTS(YEAR(bu.uplStatusOnDate) + 1, 9, 30),
        DATEFROMPARTS(YEAR(bu.uplStatusOnDate) + 1, 12, 31)
   );
GO
