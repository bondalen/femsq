-- Access QueryDef: ciduCnInvCnCtptExist
-- Type: SELECT (0)
-- dumped: 2026-08-24 15:25

SELECT h.cidutCntrPrtNum, h.cidutCntrPrtName, h.cidutCnName, h.cidutCnDate, h.cn_key, IIf(IsNull(h.cidutCnInv),"NullИлиПусто",IIf(h.cidutCnInv="","NullИлиПусто",Trim(h.cidutCnInv))) AS cidutCnInv
FROM (SELECT u.cidutCntrPrtNum, u.cidutCntrPrtName, u.cidutCntrPrtITN, u.cidutCnName, u.cidutCnDate, u.cn_key, t.cidutCnInv, t.cidutAccount FROM ciduCnCtptExistList AS u LEFT JOIN CnInvDbtUplTbl AS t ON (u.cidutCnDate = t.cidutCnDate or (isnull(u.cidutCnDate) and isnull(t.cidutCnDate))) AND (u.cidutCnName = t.cidutCnName) AND (u.cidutCntrPrtNum = t.cidutCntrPrtNum))  AS h
GROUP BY h.cidutCntrPrtNum, h.cidutCntrPrtName, h.cidutCnName, h.cidutCnDate, h.cn_key, h.cidutCnInv;
