-- Access QueryDef: ciduCnCtptExistNot
-- Type: SELECT (0)
-- dumped: 2026-08-24 15:25

SELECT k.cidutCntrPrtNum, k.cidutCntrPrtName, k.cidutCntrPrtITN, k.cidutCnName, k.cidutCnDate, k.cidutCnDateNull, k.cidutCnNameNull
FROM ciduTblCtptExist AS k LEFT JOIN ciduCnCtptList AS l ON (k.cidutCnNameNull = l.cn_number) AND (k.cidutCntrPrtNum = l.org_id_value_l) AND (k.cidutCnDateNull = l.csoCnDateNull)
GROUP BY k.cidutCntrPrtNum, k.cidutCntrPrtName, k.cidutCntrPrtITN, k.cidutCnName, k.cidutCnDate, k.cidutCnDateNull, k.cidutCnNameNull, l.cn_key
HAVING (((l.cn_key) Is Null));
