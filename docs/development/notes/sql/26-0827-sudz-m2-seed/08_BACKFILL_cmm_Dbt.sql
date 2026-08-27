/*
 * M2 — backfill *Dbt на cmm (sandbox: после CLEAR cmm пуст → no-op)
 * Если появятся строки с *InvAccnt=dbtKey — копируем в *Dbt.
 * lastUpdated: 2026-08-27
 */
SET NOCOUNT ON;
GO

UPDATE sudz.cnInvCmm SET cnicDbt = cnicInvAccnt WHERE cnicDbt IS NULL AND cnicInvAccnt IS NOT NULL;
UPDATE sudz.cnInvCmmAg SET cicaDbt = cicaInvAccnt WHERE cicaDbt IS NULL AND cicaInvAccnt IS NOT NULL;
UPDATE sudz.cnInvCmmCst SET ciccDbt = ciccInvAccnt WHERE ciccDbt IS NULL AND ciccInvAccnt IS NOT NULL;
UPDATE sudz.cnInvCmmDt SET cnicdDbt = cnicdInvAccnt WHERE cnicdDbt IS NULL AND cnicdInvAccnt IS NOT NULL;
UPDATE sudz.cnInvCmmFn SET cnicfDbt = cnicfInvAccnt WHERE cnicfDbt IS NULL AND cnicfInvAccnt IS NOT NULL;
UPDATE sudz.cnInvGr SET cnigDbt = cnigInvAccnt WHERE cnigDbt IS NULL AND cnigInvAccnt IS NOT NULL;

PRINT N'cmm *Dbt backfill done (possibly no-op)';
GO
