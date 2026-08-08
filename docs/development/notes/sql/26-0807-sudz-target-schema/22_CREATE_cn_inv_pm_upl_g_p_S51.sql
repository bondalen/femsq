-- =============================================================================
-- S51: зеркала cn_inv_pm_upl + cn_inv_dbt_upl_g_p в схеме sudz (для экрана yr)
-- DEV only. На prod объекты уже в ags — этот скрипт не нужен.
-- sqlcmd -I
-- =============================================================================

SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

IF OBJECT_ID(N'sudz.cn_inv_pm_upl', N'U') IS NULL
BEGIN
    CREATE TABLE sudz.cn_inv_pm_upl
    (
        cn_inv_pm_key  int            NOT NULL IDENTITY(1, 1),
        cn_inv_pm_date date           NOT NULL,
        cn_inv_pm_name nvarchar(255)  NULL,
        CONSTRAINT PK_cn_inv_pm_upl PRIMARY KEY CLUSTERED (cn_inv_pm_key)
    );
END
GO

IF OBJECT_ID(N'sudz.cn_inv_dbt_upl_g_p', N'U') IS NULL
BEGIN
    CREATE TABLE sudz.cn_inv_dbt_upl_g_p
    (
        [key]          int NOT NULL IDENTITY(1, 1),
        cn_inv_pm_upl  int NOT NULL,
        cn_inv_dbt_upl int NOT NULL,
        CONSTRAINT PK_cn_inv_dbt_upl_g_p PRIMARY KEY CLUSTERED ([key]),
        CONSTRAINT UX_cn_inv_dbt_upl_g_p UNIQUE (cn_inv_dbt_upl, cn_inv_pm_upl),
        CONSTRAINT FK_g_p_pm FOREIGN KEY (cn_inv_pm_upl)
            REFERENCES sudz.cn_inv_pm_upl (cn_inv_pm_key),
        CONSTRAINT FK_g_p_dbt_upl FOREIGN KEY (cn_inv_dbt_upl)
            REFERENCES sudz.cn_inv_dbt_upl (upl_key)
    );
END
GO

SELECT s.name AS schema_name, t.name AS table_name
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
WHERE s.name = N'sudz'
  AND t.name IN (N'cn_inv_pm_upl', N'cn_inv_dbt_upl_g_p')
ORDER BY t.name;
GO
