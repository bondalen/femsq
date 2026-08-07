-- =============================================================================
-- СУДЗ: песочница проектирования целевой модели
-- Схема test_sudz — только на DEV (Docker femsq-mssql). На прод НЕ переносить.
-- Контекст: docs/development/notes/domain/sudz/08-target-schema.md
-- =============================================================================

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'test_sudz')
BEGIN
    EXEC(N'CREATE SCHEMA test_sudz AUTHORIZATION dbo');
END
GO

SELECT
    name AS schema_name,
    schema_id,
    USER_NAME(principal_id) AS owner_name
FROM sys.schemas
WHERE name = N'test_sudz';
GO
