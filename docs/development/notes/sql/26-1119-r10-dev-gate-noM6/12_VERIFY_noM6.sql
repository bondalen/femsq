/*
 * DEV: проверка FishEye_prod_noM6 после strip. lastUpdated: 2026-11-19
 */
SET NOCOUNT ON;

SELECT
    N'db' AS section,
    DB_NAME() AS db_name,
    CASE WHEN DB_NAME() = N'FishEye_prod_noM6' THEN N'OK' ELSE N'WRONG_DB' END AS db_check;

SELECT
    N'sudz-schema' AS section,
    CASE WHEN EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'sudz')
         THEN N'FAIL_STILL_EXISTS' ELSE N'PASS_ABSENT' END AS sudz_schema;

SELECT
    N'm6-absent' AS section,
    CASE WHEN OBJECT_ID(N'sudz.Dbt', N'U') IS NULL
              AND OBJECT_ID(N'ags.Dbt', N'U') IS NULL
         THEN N'PASS' ELSE N'FAIL' END AS Dbt_absent,
    CASE WHEN OBJECT_ID(N'sudz.DbtValue', N'U') IS NULL
              AND OBJECT_ID(N'ags.DbtValue', N'U') IS NULL
         THEN N'PASS' ELSE N'FAIL' END AS DbtValue_absent,
    CASE WHEN OBJECT_ID(N'sudz.invDbtDbt', N'U') IS NULL
              AND OBJECT_ID(N'ags.invDbtDbt', N'U') IS NULL
         THEN N'PASS' ELSE N'FAIL' END AS invDbtDbt_absent,
    CASE WHEN COL_LENGTH(N'ags.cnInvCmm', N'cnicDbt') IS NULL
         THEN N'PASS' ELSE N'FAIL' END AS ags_cnicDbt_absent,
    CASE WHEN COL_LENGTH(N'ags.cnInvCmm', N'cnicDv') IS NULL
         THEN N'PASS' ELSE N'FAIL' END AS ags_cnicDv_absent,
    CASE WHEN OBJECT_ID(N'ags.invDbt', N'U') IS NOT NULL
         THEN N'PASS' ELSE N'FAIL' END AS ags_invDbt_present,
    CASE WHEN OBJECT_ID(N'ags.invDbtTmpCiaRel', N'U') IS NOT NULL
         THEN N'PASS' ELSE N'FAIL' END AS ags_invDbtTmpCiaRel_present;

SELECT
    N'revisions' AS section,
    CASE WHEN OBJECT_ID(N'ags.ralpRa', N'U') IS NOT NULL THEN N'OK' ELSE N'MISSING' END AS ralpRa,
    CASE WHEN OBJECT_ID(N'ags.ralpRaAu', N'U') IS NOT NULL THEN N'OK' ELSE N'MISSING' END AS ralpRaAu,
    CASE WHEN OBJECT_ID(N'ags.ogAgFee', N'U') IS NOT NULL THEN N'OK' ELSE N'MISSING' END AS ogAgFee,
    CASE WHEN OBJECT_ID(N'ags.ogAgFeeP', N'U') IS NOT NULL THEN N'OK' ELSE N'MISSING' END AS ogAgFeeP,
    CASE WHEN OBJECT_ID(N'ags.ra_a', N'U') IS NOT NULL THEN N'OK' ELSE N'MISSING' END AS ra_a;
