-- Access QueryDef: cipuCtpt_All
-- Type: SELECT (0)
-- dumped: 2026-08-17 23:44

SELECT CntrPrtNum, CntrPrtName
FROM (SELECT ciputCntrPrtNum AS CntrPrtNum, ciputCntrPrtName AS CntrPrtName FROM (SELECT ciputCntrPrtNum, ciputCntrPrtName FROM CnInvPmtUplTbl GROUP BY ciputCntrPrtNum, ciputCntrPrtName union SELECT ciputAgentNum, ciputAgentName FROM CnInvPmtUplTbl GROUP BY ciputAgentNum, ciputAgentName )  AS a)  AS b
WHERE CntrPrtNum is not null and CntrPrtName is not null;
