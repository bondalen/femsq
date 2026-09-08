-- Сводка лаборатории
SELECT labMode, labNote FROM test_sudz_sm.lab_state WHERE labKey = 1;

SELECT evKey, evScript, evOk, evMsg
FROM test_sudz_sm.lab_event
ORDER BY evKey;

SELECT N'Dbt×upl Value count' AS metric, COUNT(*) AS n
FROM test_sudz_sm.DbtValue;

SELECT idd.iddDbt, COUNT(*) AS slots, COUNT(DISTINCT idd.iddInv) AS invs
FROM test_sudz_sm.invDbtDbt AS idd
GROUP BY idd.iddDbt
ORDER BY idd.iddDbt;

SELECT dv.dvUpl, idd.iddDbt, COUNT(*) AS valuesN, SUM(dv.dvTtl) AS sumTtl
FROM test_sudz_sm.DbtValue AS dv
INNER JOIN test_sudz_sm.invDbtDbt AS idd ON idd.iddInvDbt = dv.dvInvDbt
WHERE idd.iddDbt IN (111, 112, 113, 116)
GROUP BY dv.dvUpl, idd.iddDbt
ORDER BY idd.iddDbt, dv.dvUpl;
GO
