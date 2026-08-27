/*
 * M2 — D3′: ADD nullable *Dbt → sudz.Dbt (не трогаем *InvAccnt)
 * На sudz sandbox *InvAccnt уже FK→Dbt; колонки *Dbt — репетиция prod-паттерна.
 * lastUpdated: 2026-08-27
 */
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

/* cnInvCmm */
IF COL_LENGTH(N'sudz.cnInvCmm', N'cnicDbt') IS NULL
BEGIN
    ALTER TABLE sudz.cnInvCmm ADD cnicDbt int NULL;
    ALTER TABLE sudz.cnInvCmm
        ADD CONSTRAINT FK_cnInvCmm_cnicDbt FOREIGN KEY (cnicDbt)
            REFERENCES sudz.Dbt (dbtKey);
    PRINT N'ADD sudz.cnInvCmm.cnicDbt';
END
GO

IF COL_LENGTH(N'sudz.cnInvCmmAg', N'cicaDbt') IS NULL
BEGIN
    ALTER TABLE sudz.cnInvCmmAg ADD cicaDbt int NULL;
    ALTER TABLE sudz.cnInvCmmAg
        ADD CONSTRAINT FK_cnInvCmmAg_cicaDbt FOREIGN KEY (cicaDbt)
            REFERENCES sudz.Dbt (dbtKey);
    PRINT N'ADD sudz.cnInvCmmAg.cicaDbt';
END
GO

IF COL_LENGTH(N'sudz.cnInvCmmCst', N'ciccDbt') IS NULL
BEGIN
    ALTER TABLE sudz.cnInvCmmCst ADD ciccDbt int NULL;
    ALTER TABLE sudz.cnInvCmmCst
        ADD CONSTRAINT FK_cnInvCmmCst_ciccDbt FOREIGN KEY (ciccDbt)
            REFERENCES sudz.Dbt (dbtKey);
    PRINT N'ADD sudz.cnInvCmmCst.ciccDbt';
END
GO

IF COL_LENGTH(N'sudz.cnInvCmmDt', N'cnicdDbt') IS NULL
BEGIN
    ALTER TABLE sudz.cnInvCmmDt ADD cnicdDbt int NULL;
    ALTER TABLE sudz.cnInvCmmDt
        ADD CONSTRAINT FK_cnInvCmmDt_cnicdDbt FOREIGN KEY (cnicdDbt)
            REFERENCES sudz.Dbt (dbtKey);
    PRINT N'ADD sudz.cnInvCmmDt.cnicdDbt';
END
GO

IF COL_LENGTH(N'sudz.cnInvCmmFn', N'cnicfDbt') IS NULL
BEGIN
    ALTER TABLE sudz.cnInvCmmFn ADD cnicfDbt int NULL;
    ALTER TABLE sudz.cnInvCmmFn
        ADD CONSTRAINT FK_cnInvCmmFn_cnicfDbt FOREIGN KEY (cnicfDbt)
            REFERENCES sudz.Dbt (dbtKey);
    PRINT N'ADD sudz.cnInvCmmFn.cnicfDbt';
END
GO

IF COL_LENGTH(N'sudz.cnInvGr', N'cnigDbt') IS NULL
BEGIN
    ALTER TABLE sudz.cnInvGr ADD cnigDbt int NULL;
    ALTER TABLE sudz.cnInvGr
        ADD CONSTRAINT FK_cnInvGr_cnigDbt FOREIGN KEY (cnigDbt)
            REFERENCES sudz.Dbt (dbtKey);
    PRINT N'ADD sudz.cnInvGr.cnigDbt';
END
GO

PRINT N'D3′ DDL done';
GO
