/*
=============================================================================
MSSQL2012/06_CREATE_PROCEDURE_spMstrg_2606.sql
Зеркало ../06_CREATE_PROCEDURE_spMstrg_2606.sql
SQL Server 2012 SP4 — без CREATE OR ALTER.
=============================================================================*/
USE [FishEye];
GO
SET NOCOUNT ON;
PRINT N'=== 06 MSSQL2012: Создание ags.spMstrg_2606 ===';

IF OBJECT_ID(N'ags.spMstrg_2606', N'P') IS NOT NULL
    DROP PROCEDURE ags.spMstrg_2606;
GO

DECLARE @sql  nvarchar(max);
DECLARE @chk  int;

SET @sql = OBJECT_DEFINITION(OBJECT_ID(N'ags.spMstrg_2605'));
IF @sql IS NULL
BEGIN
    RAISERROR(N'OBJECT_DEFINITION вернул NULL для ags.spMstrg_2605', 16, 1);
    RETURN;
END

SET @sql = REPLACE(@sql, N'CREATE   PROCEDURE ags.spMstrg_2605', N'CREATE PROCEDURE ags.spMstrg_2606');
SET @sql = REPLACE(@sql, N'CREATE PROCEDURE ags.spMstrg_2605', N'CREATE PROCEDURE ags.spMstrg_2606');

SET @sql = REPLACE(@sql,
    N'@ipgSt         nvarchar(255) = NULL',
    N'@ipgStKey      int           = NULL,' + CHAR(10)
    + N'    @stCostKey     int           = NULL');

SET @sql = REPLACE(@sql,
    N'ags.fnIpgChRsltCstUtlPercentBrn_2605(@ipgCh, @ipgSt)',
    N'ags.fnIpgChRsltCstUtlPercentBrn_2606(@ipgCh, @ipgStKey, @stCostKey)');

SET @sql = REPLACE(@sql, N'spMstrg_2408_ResultSet', N'spMstrg_2606_ResultSet');
SET @sql = REPLACE(@sql,
    N'@TableFnIpgChRsltCstUtlPercentBrn_2408',
    N'@TableFnIpgChRsltCstUtlPercentBrn_2606');

IF @sql NOT LIKE N'%spMstrg_2606%' OR @sql NOT LIKE N'%@ipgStKey%'
   OR @sql LIKE N'%spMstrg_2408_ResultSet%'
BEGIN
    RAISERROR(N'Замены в spMstrg_2606 не применились', 16, 1);
    RETURN;
END

EXEC sp_executesql @sql;
PRINT N'ags.spMstrg_2606 (MSSQL2012) создана успешно!';
GO
