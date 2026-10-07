-- =============================================================================
-- 26-0928 ALTER sudz.yr_upl_p: yr_upl_p_q + UNIQUE (yr, q)
-- lastUpdated: 2026-09-28
-- Совместимо с SQL Server 2012 SP4 (MSSQL2012) и DEV 2022.
-- =============================================================================

SET NOCOUNT ON;
GO

IF COL_LENGTH(N'sudz.yr_upl_p', N'yr_upl_p_q') IS NULL
BEGIN
    ALTER TABLE sudz.yr_upl_p
        ADD yr_upl_p_q tinyint NULL;
END
GO

UPDATE yp
SET yr_upl_p_q = CASE
    WHEN CONVERT(date, u.uplStatusOnDate) = DATEFROMPARTS(YEAR(bu.uplStatusOnDate), 12, 31)
        THEN 0
    WHEN CONVERT(date, u.uplStatusOnDate) = DATEFROMPARTS(YEAR(bu.uplStatusOnDate) + 1, 3, 31)
        THEN 1
    WHEN CONVERT(date, u.uplStatusOnDate) = DATEFROMPARTS(YEAR(bu.uplStatusOnDate) + 1, 6, 30)
        THEN 2
    WHEN CONVERT(date, u.uplStatusOnDate) = DATEFROMPARTS(YEAR(bu.uplStatusOnDate) + 1, 9, 30)
        THEN 3
    WHEN CONVERT(date, u.uplStatusOnDate) = DATEFROMPARTS(YEAR(bu.uplStatusOnDate) + 1, 12, 31)
        THEN 4
    ELSE NULL
END
FROM sudz.yr_upl_p AS yp
INNER JOIN sudz.yr AS y ON y.yr_key = yp.yr_upl_p_yr
INNER JOIN sudz.cn_inv_dbt_upl AS bu ON bu.upl_key = y.cn_inv_dbt_upl
INNER JOIN sudz.cn_inv_dbt_upl AS u ON u.upl_key = yp.cn_inv_dbt_upl
WHERE yp.yr_upl_p_q IS NULL;
GO

IF EXISTS (SELECT 1 FROM sudz.yr_upl_p WHERE yr_upl_p_q IS NULL)
BEGIN
    RAISERROR(N'26-0928: есть строки yr_upl_p без yr_upl_p_q (дата среза не конец квартала портфеля)', 16, 1);
    RETURN;
END
GO

IF EXISTS (
    SELECT 1
    FROM sudz.yr_upl_p
    GROUP BY yr_upl_p_yr, yr_upl_p_q
    HAVING COUNT(*) > 1
)
BEGIN
    RAISERROR(N'26-0928: дубли (yr, q) — устраните до UNIQUE', 16, 1);
    RETURN;
END
GO

IF EXISTS (
    SELECT 1
    FROM sys.columns
    WHERE object_id = OBJECT_ID(N'sudz.yr_upl_p')
      AND name = N'yr_upl_p_q'
      AND is_nullable = 1
)
BEGIN
    ALTER TABLE sudz.yr_upl_p
        ALTER COLUMN yr_upl_p_q tinyint NOT NULL;
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.check_constraints
    WHERE parent_object_id = OBJECT_ID(N'sudz.yr_upl_p')
      AND name = N'CK_yr_upl_p_q'
)
BEGIN
    ALTER TABLE sudz.yr_upl_p
        ADD CONSTRAINT CK_yr_upl_p_q CHECK (yr_upl_p_q BETWEEN 0 AND 4);
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'sudz.yr_upl_p')
      AND name = N'UX_yr_upl_p_YrQ'
)
BEGIN
    ALTER TABLE sudz.yr_upl_p
        ADD CONSTRAINT UX_yr_upl_p_YrQ UNIQUE (yr_upl_p_yr, yr_upl_p_q);
END
GO
