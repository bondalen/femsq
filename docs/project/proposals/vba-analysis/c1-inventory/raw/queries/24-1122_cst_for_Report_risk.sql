-- Access QueryDef: 24-1122_cst_for_Report_risk
-- Type: 0

SELECT IIf(IsNull([branchName]),IIf(IsNull([ogNm]),"пусто",[ogNm]),"пусто") AS ogNm_hook, IIf(IsNull([branchName]),"пусто",IIf([branchName]=[ogNm],"Центральный офис",[branchName])) AS branchName_hook, a.*, a.cstAgPnCode
FROM ags_fnIpgChRsltCstUtlPercentBrnRep01_2408_tbl AS a INNER JOIN [24-1122_risk] ON a.cstAgPnCode = [24-1122_risk].cstAgPn
WHERE (((a.cstAgPnCode)<>"всего"))
ORDER BY a.cstAgPnCode;
