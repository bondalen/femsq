-- Access QueryDef: cipuCn_CtptNot
-- Type: SELECT (0)
-- dumped: 2026-08-17 23:44

SELECT a.ciputCntrPrtNum AS CntrPrtNum, a.ciputCntrPrtName AS CntrPrtName, a.ciputCnName AS CnName
FROM CnInvPmtUplTbl AS a LEFT JOIN cipuCtpt_All_OIdNot AS b ON a.ciputCntrPrtNum = b.CntrPrtNum
WHERE (((b.CntrPrtNum) Is Not Null))
GROUP BY a.ciputCntrPrtNum, a.ciputCntrPrtName, a.ciputCnName;
