-- =============================================================================
-- Песочница: заголовки выгрузок IV.2025–II.2026 (не трогаем ags.cn_inv_dbt_upl)
-- + перенос FK DbtValue.dvUpl на sudz.cn_inv_dbt_upl
-- =============================================================================

IF OBJECT_ID(N'sudz.cn_inv_dbt_upl', N'U') IS NULL
BEGIN
    CREATE TABLE sudz.cn_inv_dbt_upl
    (
        upl_key           int            NOT NULL,
        upl_date          datetime       NULL,
        uplStatusOnDate   date           NOT NULL,
        upl_name          nvarchar(255)  NOT NULL,
        CONSTRAINT PK_cn_inv_dbt_upl PRIMARY KEY CLUSTERED (upl_key)
    );
END
GO

-- Перецепить DbtValue.dvUpl с ags на sudz (если ещё на ags)
IF EXISTS (
    SELECT 1 FROM sys.foreign_keys
    WHERE name = N'FK_DbtValue_upl'
      AND parent_object_id = OBJECT_ID(N'sudz.DbtValue')
)
BEGIN
    ALTER TABLE sudz.DbtValue DROP CONSTRAINT FK_DbtValue_upl;
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.foreign_keys
    WHERE name = N'FK_DbtValue_upl_test'
      AND parent_object_id = OBJECT_ID(N'sudz.DbtValue')
)
BEGIN
    ALTER TABLE sudz.DbtValue
        ADD CONSTRAINT FK_DbtValue_upl_test FOREIGN KEY (dvUpl)
            REFERENCES sudz.cn_inv_dbt_upl (upl_key);
END
GO

-- Идентификаторы выгрузок: 901–903 (вне диапазона ags upl_key)
MERGE sudz.cn_inv_dbt_upl AS t
USING (VALUES
    (901, CAST('2026-01-15' AS datetime), CAST('2025-12-31' AS date), N'[sudz] Дт Задолженность на 31.12.2025 (Общий свод) — seed 82/85'),
    (902, CAST('2026-04-15' AS datetime), CAST('2026-03-31' AS date), N'[sudz] Дт Задолженность на 31.03.2026 (Общий свод) — seed 82/85'),
    (903, CAST('2026-07-15' AS datetime), CAST('2026-06-30' AS date), N'[sudz] Дт Задолженность на 30.06.2026 (Общий свод) — seed 82/85')
) AS s (upl_key, upl_date, uplStatusOnDate, upl_name)
ON t.upl_key = s.upl_key
WHEN NOT MATCHED THEN
    INSERT (upl_key, upl_date, uplStatusOnDate, upl_name)
    VALUES (s.upl_key, s.upl_date, s.uplStatusOnDate, s.upl_name);
GO

SELECT * FROM sudz.cn_inv_dbt_upl ORDER BY upl_key;
GO
