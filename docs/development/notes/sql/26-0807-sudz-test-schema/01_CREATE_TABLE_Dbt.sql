-- =============================================================================
-- test_sudz.Dbt — канон задолженности (песочница СУДЗ)
-- DEV only. Спецификация: 08-target-schema.md §2.1
-- =============================================================================

IF OBJECT_ID(N'test_sudz.Dbt', N'U') IS NULL
BEGIN
    CREATE TABLE test_sudz.Dbt
    (
        dbtKey          int            NOT NULL IDENTITY(1, 1),
        dbtNote         nvarchar(255)  NULL,
        dbtTimeOfEntry  datetime       NOT NULL
            CONSTRAINT DF_Dbt_dbtTimeOfEntry DEFAULT (getdate()),
        CONSTRAINT PK_Dbt PRIMARY KEY CLUSTERED (dbtKey)
    );
END
GO

-- MS_Description (как в ags-контуре)
IF NOT EXISTS (
    SELECT 1
    FROM sys.extended_properties ep
    WHERE ep.major_id = OBJECT_ID(N'test_sudz.Dbt')
      AND ep.minor_id = 0
      AND ep.name = N'MS_Description'
)
BEGIN
    EXEC sys.sp_addextendedproperty
        @name = N'MS_Description',
        @value = N'СУДЗ: каноническая задолженность (песочница test_sudz). Без FK на сторону/документ/счёт.',
        @level0type = N'SCHEMA', @level0name = N'test_sudz',
        @level1type = N'TABLE',  @level1name = N'Dbt';
END
GO

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS type_name,
    c.max_length,
    c.is_nullable,
    c.is_identity
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.columns c ON c.object_id = t.object_id
JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE s.name = N'test_sudz' AND t.name = N'Dbt'
ORDER BY c.column_id;
GO
