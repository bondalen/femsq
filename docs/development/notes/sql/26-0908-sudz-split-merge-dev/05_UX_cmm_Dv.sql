/*
 * Узел 3.2 — UNIQUE на якоре *Dv (группа + тип + Value).
 *
 * Filtered unique: строки с NULL *Dv (ещё на InvAccnt) не конфликтуют.
 * Только DEV схема sudz. Не MSSQL2012/, не продуктив, не ags.
 *
 * lastUpdated: 2026-10-14
 */
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'sudz.cnInvCmm') AND name = N'UX_cnInvCmm_GrTypeDv'
)
BEGIN
    CREATE UNIQUE INDEX UX_cnInvCmm_GrTypeDv
        ON sudz.cnInvCmm (cnicGroup, cnicType, cnicDv)
        WHERE cnicDv IS NOT NULL;
    PRINT N'ADD UX_cnInvCmm_GrTypeDv';
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'sudz.cnInvCmmCst') AND name = N'UX_cnInvCmmCst_GrTypeDv'
)
BEGIN
    CREATE UNIQUE INDEX UX_cnInvCmmCst_GrTypeDv
        ON sudz.cnInvCmmCst (ciccCmmGr, ciccType, ciccDv)
        WHERE ciccDv IS NOT NULL;
    PRINT N'ADD UX_cnInvCmmCst_GrTypeDv';
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'sudz.cnInvCmmAg') AND name = N'UX_cnInvCmmAg_GrTypeDv'
)
BEGIN
    CREATE UNIQUE INDEX UX_cnInvCmmAg_GrTypeDv
        ON sudz.cnInvCmmAg (cicaCmmGr, cicaType, cicaDv)
        WHERE cicaDv IS NOT NULL;
    PRINT N'ADD UX_cnInvCmmAg_GrTypeDv';
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'sudz.cnInvCmmDt') AND name = N'UX_cnInvCmmDt_GrNameDv'
)
BEGIN
    CREATE UNIQUE INDEX UX_cnInvCmmDt_GrNameDv
        ON sudz.cnInvCmmDt (cnicdCmmGr, cnicdName, cnicdDv)
        WHERE cnicdDv IS NOT NULL;
    PRINT N'ADD UX_cnInvCmmDt_GrNameDv';
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'sudz.cnInvCmmFn') AND name = N'UX_cnInvCmmFn_GrNameDv'
)
BEGIN
    CREATE UNIQUE INDEX UX_cnInvCmmFn_GrNameDv
        ON sudz.cnInvCmmFn (cnicfCmmGr, cnicfName, cnicfDv)
        WHERE cnicfDv IS NOT NULL;
    PRINT N'ADD UX_cnInvCmmFn_GrNameDv';
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE object_id = OBJECT_ID(N'sudz.cnInvGr') AND name = N'UX_cnInvGr_GrNameDv'
)
BEGIN
    CREATE UNIQUE INDEX UX_cnInvGr_GrNameDv
        ON sudz.cnInvGr (cnigCmmGr, cnigGrName, cnigDv)
        WHERE cnigDv IS NOT NULL;
    PRINT N'ADD UX_cnInvGr_GrNameDv';
END
GO

PRINT N'3.2 UX *Dv: filtered UNIQUE on sudz cmm tables.';
GO
