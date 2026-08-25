-- Access QueryDef: ciduCnCtptExistList
-- Type: SELECT (0)
-- dumped: 2026-08-24 15:25

SELECT k.cidutCntrPrtNum, k.cidutCntrPrtName, k.cidutCntrPrtITN, k.cidutCnName, k.cidutCnNameNull, k.cidutCnDate, k.cidutCnDateNull, l.cn_key, l.cn_s_org_key
FROM ciduTblCtptExist AS k LEFT JOIN ciduCnCtptList AS l ON (k.cidutCnNameNull = l.cn_number) AND (k.cidutCnDateNull = l.csoCnDateNull) AND (k.cidutCntrPrtNum = l.org_id_value_l)
GROUP BY k.cidutCntrPrtNum, k.cidutCntrPrtName, k.cidutCntrPrtITN, k.cidutCnName, k.cidutCnNameNull, k.cidutCnDate, k.cidutCnDateNull, l.cn_key, l.cn_s_org_key
HAVING (((l.cn_key) Is Not Null));
