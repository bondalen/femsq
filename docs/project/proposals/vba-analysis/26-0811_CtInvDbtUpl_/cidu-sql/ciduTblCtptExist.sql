-- Access QueryDef: ciduTblCtptExist
-- Type: SELECT (0)
-- dumped: 2026-08-24 15:25

SELECT a.cidutAccount, a.cidutCntrPrtNum, ags_og.ogNm AS cidutCntrPrtName, a.cidutCntrPrtITN, a.cidutCnDate, IIf(IsNull(a.cidutCnName),"NullИлиПусто",IIf(a.cidutCnName="","NullИлиПусто",Trim(a.cidutCnName))) AS cidutCnName, a.cidutCnInv, a.cidutCnInvName, a.cidutFormtnDate, a.cidutMatrtyDate, a.cidutDebt, a.cidutDebtOverdue, a.cidutDoc, a.cidutLink, a.cidutSheet, a.cidutSheetNum, a.cidutUnloadKey, a.cidutCnDateNull, a.cidutCnNameNull, a.cidutCnInvNull, a.cidutCnInvNameNull
FROM ((CnInvDbtUplTbl AS a LEFT JOIN ciduCtptNot AS b ON a.cidutCntrPrtNum = b.cidutCntrPrtNum) LEFT JOIN ags_org_id ON a.cidutCntrPrtNum = ags_org_id.org_id_value_l) LEFT JOIN ags_og ON ags_org_id.org = ags_og.ogKey
WHERE (((b.cidutCntrPrtName) Is Null) AND ((ags_org_id.org_id_type)=1));
