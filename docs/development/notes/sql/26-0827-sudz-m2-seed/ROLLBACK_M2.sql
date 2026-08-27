/*
 * M2 ROLLBACK — очистка seed + DROP D3′ cols / invDbtCia (опционально)
 * Предпочтительно: RESTORE из FishEye_*_pre-m2-seed.bak
 * lastUpdated: 2026-08-27
 */
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

BEGIN TRANSACTION;

DELETE FROM sudz.cnInvCmm;
DELETE FROM sudz.cnInvCmmAg;
DELETE FROM sudz.cnInvCmmCst;
DELETE FROM sudz.cnInvCmmDt;
DELETE FROM sudz.cnInvCmmFn;
DELETE FROM sudz.cnInvGr;
IF OBJECT_ID(N'sudz.DbtUplCstAg', N'U') IS NOT NULL
    DELETE FROM sudz.DbtUplCstAg;

DELETE FROM sudz.DbtValue;
DELETE FROM sudz.invDbtDbtVar;
DELETE FROM sudz.invDbtVar;
DELETE FROM sudz.invDbtDbt;
IF OBJECT_ID(N'sudz.invDbtCia', N'U') IS NOT NULL
    DELETE FROM sudz.invDbtCia;
DELETE FROM sudz.Dbt;
DELETE FROM sudz.invDbt;

/* D3′ columns */
IF COL_LENGTH(N'sudz.cnInvCmm', N'cnicDbt') IS NOT NULL
BEGIN
    ALTER TABLE sudz.cnInvCmm DROP CONSTRAINT FK_cnInvCmm_cnicDbt;
    ALTER TABLE sudz.cnInvCmm DROP COLUMN cnicDbt;
END
IF COL_LENGTH(N'sudz.cnInvCmmAg', N'cicaDbt') IS NOT NULL
BEGIN
    ALTER TABLE sudz.cnInvCmmAg DROP CONSTRAINT FK_cnInvCmmAg_cicaDbt;
    ALTER TABLE sudz.cnInvCmmAg DROP COLUMN cicaDbt;
END
IF COL_LENGTH(N'sudz.cnInvCmmCst', N'ciccDbt') IS NOT NULL
BEGIN
    ALTER TABLE sudz.cnInvCmmCst DROP CONSTRAINT FK_cnInvCmmCst_ciccDbt;
    ALTER TABLE sudz.cnInvCmmCst DROP COLUMN ciccDbt;
END
IF COL_LENGTH(N'sudz.cnInvCmmDt', N'cnicdDbt') IS NOT NULL
BEGIN
    ALTER TABLE sudz.cnInvCmmDt DROP CONSTRAINT FK_cnInvCmmDt_cnicdDbt;
    ALTER TABLE sudz.cnInvCmmDt DROP COLUMN cnicdDbt;
END
IF COL_LENGTH(N'sudz.cnInvCmmFn', N'cnicfDbt') IS NOT NULL
BEGIN
    ALTER TABLE sudz.cnInvCmmFn DROP CONSTRAINT FK_cnInvCmmFn_cnicfDbt;
    ALTER TABLE sudz.cnInvCmmFn DROP COLUMN cnicfDbt;
END
IF COL_LENGTH(N'sudz.cnInvGr', N'cnigDbt') IS NOT NULL
BEGIN
    ALTER TABLE sudz.cnInvGr DROP CONSTRAINT FK_cnInvGr_cnigDbt;
    ALTER TABLE sudz.cnInvGr DROP COLUMN cnigDbt;
END

IF OBJECT_ID(N'sudz.invDbtCia', N'U') IS NOT NULL
    DROP TABLE sudz.invDbtCia;

COMMIT TRANSACTION;
PRINT N'ROLLBACK_M2 logical clear done — prefer RESTORE bak for full revert of IDENTITY/demo';
GO
