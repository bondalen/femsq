-- Access QueryDef: cipuCn_Agnt
-- Type: SELECT (0)
-- dumped: 2026-08-17 23:44

SELECT a.ciputAgentNum AS AgNum, a.ciputAgentName AS AgName, a.ciputCnName AS CnName, agsOrgIdBUiRG.org_id_key
FROM (CnInvPmtUplTblNull AS a LEFT JOIN agsOrgIdBUiRG ON a.ciputAgentNum = agsOrgIdBUiRG.org_id_value_l) LEFT JOIN cipuCtpt_All_OIdNot AS b ON a.ciputAgentNum = b.CntrPrtNum
WHERE (((b.CntrPrtNum) Is Null) AND ((a.ciputAgentNum) Is Not Null))
GROUP BY a.ciputAgentNum, a.ciputAgentName, a.ciputCnName, agsOrgIdBUiRG.org_id_key;
