/*
 * M2/M3 — DbtValue.dvUpl → sudz.cn_inv_dbt_upl (воронка FEMSQ + E1)
 *
 * E1 читает ags.cn_inv_dbt (upl 2..28); воронка пишет unloadKey (напр. 910) в sudz.cn_inv_dbt_upl.
 * FK на ags ломает INSERT Value из invDbtLoad. Канон DEV: зеркало upl в sudz + FK на sudz.
 *
 * Шаги: sync недостающих ключей из ags → DROP FK_…_upl(ags) → FK → sudz.cn_inv_dbt_upl
 * lastUpdated: 2026-08-27
 */
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/* 1) досинхрон ags → sudz (только отсутствующие ключи) */
INSERT INTO sudz.cn_inv_dbt_upl (upl_key, upl_date, uplStatusOnDate, upl_name)
SELECT a.upl_key,
       CAST(a.upl_date AS datetime),
       a.uplStatusOnDate,
       a.upl_name
FROM ags.cn_inv_dbt_upl AS a
WHERE NOT EXISTS (
    SELECT 1 FROM sudz.cn_inv_dbt_upl AS s WHERE s.upl_key = a.upl_key
);

DECLARE @n int = (SELECT COUNT(*) FROM sudz.cn_inv_dbt_upl);
PRINT CONCAT(N'sudz.cn_inv_dbt_upl rows: ', @n);
GO

/* 2) FK → sudz */
IF EXISTS (
    SELECT 1 FROM sys.foreign_keys
    WHERE name = N'FK_DbtValue_upl'
      AND parent_object_id = OBJECT_ID(N'sudz.DbtValue')
)
    ALTER TABLE sudz.DbtValue DROP CONSTRAINT FK_DbtValue_upl;
GO

IF EXISTS (
    SELECT 1 FROM sys.foreign_keys
    WHERE name = N'FK_DbtValue_upl_test'
      AND parent_object_id = OBJECT_ID(N'sudz.DbtValue')
)
    ALTER TABLE sudz.DbtValue DROP CONSTRAINT FK_DbtValue_upl_test;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys
    WHERE name = N'FK_DbtValue_upl'
      AND parent_object_id = OBJECT_ID(N'sudz.DbtValue')
)
BEGIN
    ALTER TABLE sudz.DbtValue
        ADD CONSTRAINT FK_DbtValue_upl FOREIGN KEY (dvUpl)
            REFERENCES sudz.cn_inv_dbt_upl (upl_key);
    PRINT N'FK_DbtValue_upl → sudz.cn_inv_dbt_upl';
END
ELSE
    PRINT N'FK_DbtValue_upl already present';
GO

/* 3) все текущие dvUpl должны резолвиться */
IF EXISTS (
    SELECT 1
    FROM sudz.DbtValue AS dv
    WHERE NOT EXISTS (
        SELECT 1 FROM sudz.cn_inv_dbt_upl AS u WHERE u.upl_key = dv.dvUpl
    )
)
    RAISERROR(N'DbtValue has dvUpl missing from sudz.cn_inv_dbt_upl', 16, 1);
GO
