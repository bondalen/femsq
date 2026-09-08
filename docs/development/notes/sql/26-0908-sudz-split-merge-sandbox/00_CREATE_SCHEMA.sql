-- =============================================================================
-- test_sudz_sm — песочница «разделение и слияние долгов»
-- DEV / FishEye only. Не копировать в MSSQL2012/prod. Не трогает sudz.* и test_sudz 82/85.
-- =============================================================================

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'test_sudz_sm')
BEGIN
    EXEC(N'CREATE SCHEMA test_sudz_sm AUTHORIZATION dbo');
END
GO

SELECT name AS schema_name FROM sys.schemas WHERE name = N'test_sudz_sm';
GO
