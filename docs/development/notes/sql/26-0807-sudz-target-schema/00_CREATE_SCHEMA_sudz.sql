-- =============================================================================
-- СУДЗ: целевая схема MVP (DEV)
-- Схема sudz — DEV-контур MVP; лаборатория остаётся test_sudz. (Docker femsq-mssql). На прод НЕ переносить.
-- Контекст: docs/development/notes/domain/sudz/08-target-schema.md
-- =============================================================================

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'sudz')
BEGIN
    EXEC(N'CREATE SCHEMA sudz AUTHORIZATION dbo');
END
GO

SELECT
    name AS schema_name,
    schema_id,
    USER_NAME(principal_id) AS owner_name
FROM sys.schemas
WHERE name = N'sudz';
GO
