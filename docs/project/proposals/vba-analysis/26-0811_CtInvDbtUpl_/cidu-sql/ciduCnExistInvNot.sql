-- Access QueryDef: ciduCnExistInvNot
-- Type: SELECT (0)
-- dumped: 2026-08-24 15:25

SELECT w.cn_key, w.cidutCnNameNull, w.cidutCnInvNull, w.ciKey, agsInvNumCount.inNumCount
FROM (SELECT f.cn_key, f.cidutCnNameNull, f.cidutCnInvNull, g.ciKey FROM (SELECT u.cn_key, u.cidutCnNameNull, t.cidutCnInvNull FROM ciduCnCtptExistList AS u LEFT JOIN CnInvDbtUplTbl AS t ON (u.cidutCnDateNull = t.cidutCnDateNull) AND (u.cidutCnNameNull = t.cidutCnNameNull) AND (u.cidutCntrPrtNum = t.cidutCntrPrtNum) GROUP BY u.cn_key, u.cidutCnNameNull, t.cidutCnInvNull)  AS f LEFT JOIN agsCnInvNumsVariants AS g ON (f.cn_key = g.cn_key) AND (f.cidutCnInvNull = g.inNumNull) GROUP BY f.cn_key, f.cidutCnNameNull, f.cidutCnInvNull, g.ciKey)  AS w LEFT JOIN agsInvNumCount ON w.cidutCnInvNull = agsInvNumCount.inNumNull
GROUP BY w.cn_key, w.cidutCnNameNull, w.cidutCnInvNull, w.ciKey, agsInvNumCount.inNumCount;
