/*
 * S77 D3″ DRAFT — nullable *Dv → sudz.DbtValue рядом с D3′ *Dbt.
 *
 * НЕ ВЫПОЛНЯТЬ вместе с 01, пока не согласован якорь cmm (S77 I4).
 * *InvAccnt и *Dbt не трогаем. Access-мост цел.
 *
 * Чтобы применить: удалите единственный THROW ниже (и только его).
 * Имена зеркалят D3′: cnicDv / cicaDv / ciccDv / cnicdDv / cnicfDv / cnigDv.
 *
 * lastUpdated: 2026-09-08
 */
SET NOCOUNT ON;
SET XACT_ABORT ON;

THROW 50077, N'S77 D3″ DRAFT: не выполнять до согласия I4. Удалите этот THROW.', 1;

IF COL_LENGTH(N'sudz.cnInvCmm', N'cnicDv') IS NULL
BEGIN
    ALTER TABLE sudz.cnInvCmm ADD cnicDv int NULL;
    ALTER TABLE sudz.cnInvCmm
        ADD CONSTRAINT FK_cnInvCmm_cnicDv FOREIGN KEY (cnicDv)
            REFERENCES sudz.DbtValue (dvKey);
    PRINT N'ADD sudz.cnInvCmm.cnicDv';
END

IF COL_LENGTH(N'sudz.cnInvCmmAg', N'cicaDv') IS NULL
BEGIN
    ALTER TABLE sudz.cnInvCmmAg ADD cicaDv int NULL;
    ALTER TABLE sudz.cnInvCmmAg
        ADD CONSTRAINT FK_cnInvCmmAg_cicaDv FOREIGN KEY (cicaDv)
            REFERENCES sudz.DbtValue (dvKey);
    PRINT N'ADD sudz.cnInvCmmAg.cicaDv';
END

IF COL_LENGTH(N'sudz.cnInvCmmCst', N'ciccDv') IS NULL
BEGIN
    ALTER TABLE sudz.cnInvCmmCst ADD ciccDv int NULL;
    ALTER TABLE sudz.cnInvCmmCst
        ADD CONSTRAINT FK_cnInvCmmCst_ciccDv FOREIGN KEY (ciccDv)
            REFERENCES sudz.DbtValue (dvKey);
    PRINT N'ADD sudz.cnInvCmmCst.ciccDv';
END

IF COL_LENGTH(N'sudz.cnInvCmmDt', N'cnicdDv') IS NULL
BEGIN
    ALTER TABLE sudz.cnInvCmmDt ADD cnicdDv int NULL;
    ALTER TABLE sudz.cnInvCmmDt
        ADD CONSTRAINT FK_cnInvCmmDt_cnicdDv FOREIGN KEY (cnicdDv)
            REFERENCES sudz.DbtValue (dvKey);
    PRINT N'ADD sudz.cnInvCmmDt.cnicdDv';
END

IF COL_LENGTH(N'sudz.cnInvCmmFn', N'cnicfDv') IS NULL
BEGIN
    ALTER TABLE sudz.cnInvCmmFn ADD cnicfDv int NULL;
    ALTER TABLE sudz.cnInvCmmFn
        ADD CONSTRAINT FK_cnInvCmmFn_cnicfDv FOREIGN KEY (cnicfDv)
            REFERENCES sudz.DbtValue (dvKey);
    PRINT N'ADD sudz.cnInvCmmFn.cnicfDv';
END

IF COL_LENGTH(N'sudz.cnInvGr', N'cnigDv') IS NULL
BEGIN
    ALTER TABLE sudz.cnInvGr ADD cnigDv int NULL;
    ALTER TABLE sudz.cnInvGr
        ADD CONSTRAINT FK_cnInvGr_cnigDv FOREIGN KEY (cnigDv)
            REFERENCES sudz.DbtValue (dvKey);
    PRINT N'ADD sudz.cnInvGr.cnigDv';
END

PRINT N'S77 D3″ DRAFT: *Dv added, *Dbt/*InvAccnt unchanged.';
