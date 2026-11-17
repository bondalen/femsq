-- Access QueryDef: ciduCnCtptExistInvNot
-- Type: 0

SELECT w.cidutCntrPrtNum, w.cidutCntrPrtName, w.cidutCnName, w.cidutCnNameNull, w.cidutCnDate, w.cidutCnDateNull, w.cidutCnInv, w.cidutCnInvNull, w.cn_key, w.cn_s_org_key, w.iKey, w.ciKey, q.inNumCount
FROM ciduCnCtptExistInvAll AS w LEFT JOIN agsInvNumCount AS q ON w.cidutCnInvNull = q.inNumNull
GROUP BY w.cidutCntrPrtNum, w.cidutCntrPrtName, w.cidutCnName, w.cidutCnNameNull, w.cidutCnDate, w.cidutCnDateNull, w.cidutCnInv, w.cidutCnInvNull, w.cn_key, w.cn_s_org_key, w.iKey, w.ciKey, q.inNumCount;
