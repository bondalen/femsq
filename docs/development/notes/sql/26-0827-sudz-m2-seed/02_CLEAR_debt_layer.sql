/*
 * M2 — очистка экспериментального слоя долга в sudz (+ demo cmm на Dbt)
 * ags не трогаем. Funnel/upl staging оставляем.
 * lastUpdated: 2026-08-27
 */
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

BEGIN TRANSACTION;

/* cmm / gr — FK → Dbt */
DELETE FROM sudz.cnInvCmm;
DELETE FROM sudz.cnInvCmmAg;
DELETE FROM sudz.cnInvCmmCst;
DELETE FROM sudz.cnInvCmmDt;
DELETE FROM sudz.cnInvCmmFn;
DELETE FROM sudz.cnInvGr;

/* DbtUplCstAg */
IF OBJECT_ID(N'sudz.DbtUplCstAg', N'U') IS NOT NULL
    DELETE FROM sudz.DbtUplCstAg;

/* Value / vars / bridges / slots / Dbt */
DELETE FROM sudz.DbtValue;
DELETE FROM sudz.invDbtDbtVar;
DELETE FROM sudz.invDbtVar;
DELETE FROM sudz.invDbtDbt;
IF OBJECT_ID(N'sudz.invDbtCia', N'U') IS NOT NULL
    DELETE FROM sudz.invDbtCia;
DELETE FROM sudz.Dbt;
DELETE FROM sudz.invDbt;

COMMIT TRANSACTION;
GO

DBCC CHECKIDENT (N'sudz.DbtValue', RESEED, 0);
DBCC CHECKIDENT (N'sudz.invDbtDbtVar', RESEED, 0);
DBCC CHECKIDENT (N'sudz.invDbtVar', RESEED, 0);
DBCC CHECKIDENT (N'sudz.invDbtDbt', RESEED, 0);
DBCC CHECKIDENT (N'sudz.Dbt', RESEED, 0);
DBCC CHECKIDENT (N'sudz.invDbt', RESEED, 0);
IF OBJECT_ID(N'sudz.invDbtCia', N'U') IS NOT NULL
    DBCC CHECKIDENT (N'sudz.invDbtCia', RESEED, 0);
GO

SELECT N'invDbt' AS t, COUNT(*) AS n FROM sudz.invDbt
UNION ALL SELECT N'Dbt', COUNT(*) FROM sudz.Dbt
UNION ALL SELECT N'DbtValue', COUNT(*) FROM sudz.DbtValue;
GO
