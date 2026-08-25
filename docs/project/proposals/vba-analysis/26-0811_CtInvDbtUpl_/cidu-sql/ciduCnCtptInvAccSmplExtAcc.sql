-- Access QueryDef: ciduCnCtptInvAccSmplExtAcc
-- Type: SELECT (0)
-- dumped: 2026-08-24 15:25

SELECT c.cidutCntrPrtNum, c.cidutCntrPrtName, c.cidutCnName, c.cidutCnNameNull, c.cidutCnDate, c.cidutCnDateNull, c.cidutCnInv, c.cidutCnInvNull, c.cn_key, c.cn_s_org_key, c.iKey, c.ciKey, c.account_num, c.account_key, c.ciasKey, c.ciasCn_s_org_smpl, t.cidutCnInvNameNull, t.DbtCount
FROM ciduCnCtptInvAccSmplExt AS c LEFT JOIN ciduTblCnCtptInvAccNameCount AS t ON (c.cidutCntrPrtNum = t.cidutCntrPrtNum) AND (c.cidutCnNameNull = t.cidutCnNameNull) AND (c.cidutCnDateNull = t.cidutCnDateNull) AND (c.cidutCnInvNull = t.cidutCnInvNull) AND (c.account_key = t.cidutAccount)
GROUP BY c.cidutCntrPrtNum, c.cidutCntrPrtName, c.cidutCnName, c.cidutCnNameNull, c.cidutCnDate, c.cidutCnDateNull, c.cidutCnInv, c.cidutCnInvNull, c.cn_key, c.cn_s_org_key, c.iKey, c.ciKey, c.account_num, c.account_key, c.ciasKey, c.ciasCn_s_org_smpl, t.cidutCnInvNameNull, t.DbtCount;
