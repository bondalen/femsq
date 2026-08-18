-- Access QueryDef: cipuCn_Ctpt
-- Type: SELECT (0)
-- dumped: 2026-08-17 23:44

SELECT a.ciputCntrPrtNum AS CntrPrtNum, a.ciputCntrPrtName AS CntrPrtName, IIf(IsNull([a].[ciputCnName]),"NullИлиПусто",IIf([a].[ciputCnName]="","NullИлиПусто",[a].[ciputCnName])) AS CnName, agsOrgIdBUiRG.org_id_key
FROM (CnInvPmtUplTbl AS a LEFT JOIN cipuCtpt_All_OIdNot AS b ON a.ciputCntrPrtNum = b.CntrPrtNum) LEFT JOIN agsOrgIdBUiRG ON a.ciputCntrPrtNum = agsOrgIdBUiRG.org_id_value_l
WHERE (((b.CntrPrtNum) Is Null))
GROUP BY a.ciputCntrPrtNum, a.ciputCntrPrtName, agsOrgIdBUiRG.org_id_key, a.ciputCnName;
