/*
 * Узел 4.3. Ворота перед миграцией Acc → *Dv.
 * Платформа: SQL Server 2012 SP4 (11.0.7507.2) и новее.
 * Схему не меняет. На ags без cnicDv — ошибка, это ожидаемо.
 * lastUpdated: 2026-10-16
 */
SET NOCOUNT ON;

DECLARE @major int = CONVERT(int, SERVERPROPERTY('ProductMajorVersion'));

IF @major IS NULL OR @major < 11
BEGIN
    RAISERROR(N'package_compat = FAIL: нужен SQL Server 2012 или новее', 16, 1);
    RETURN;
END;

SELECT
    N'OK for MSSQL2012 package' AS package_compat,
    @major AS major_version,
    CONVERT(nvarchar(128), SERVERPROPERTY('ProductVersion')) AS product_version;

IF COL_LENGTH(N'sudz.cnInvCmm', N'cnicDv') IS NULL
    OR COL_LENGTH(N'sudz.cnInvCmmCst', N'ciccDv') IS NULL
    OR OBJECT_ID(N'sudz.DbtValue', N'U') IS NULL
    OR OBJECT_ID(N'sudz.invDbtDbt', N'U') IS NULL
    OR OBJECT_ID(N'sudz.yr', N'U') IS NULL
    OR OBJECT_ID(N'sudz.yr_upl_p', N'U') IS NULL
BEGIN
    RAISERROR(N'gate FAIL: на sudz нет *Dv / DbtValue / yr. Пакет колонки не добавляет.', 16, 1);
    RETURN;
END;

SELECT
    N'gate OK' AS gate,
    CASE WHEN EXISTS (
        SELECT 1 FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'sudz.cnInvCmm') AND name = N'UX_cnInvCmm_GrTypeDv'
    ) THEN N'yes' ELSE N'no' END AS ux_cmm,
    CASE WHEN EXISTS (
        SELECT 1 FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'sudz.cnInvCmmCst') AND name = N'UX_cnInvCmmCst_GrTypeDv'
    ) THEN N'yes' ELSE N'no' END AS ux_cst;
