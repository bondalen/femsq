-- Access QueryDef: ciduCnCtptInvAccSmplExtAccExt
-- Type: SELECT (0)
-- dumped: 2026-08-24 15:25

SELECT a.cidutCntrPrtNum, a.cidutCntrPrtName, a.cidutCnName, a.cidutCnNameNull, a.cidutCnDate, a.cidutCnDateNull, a.cidutCnInv, a.cidutCnInvNull, a.cidutCnInvNameNull, a.cn_key, a.cn_s_org_key, a.iKey, a.ciKey, a.account_num, a.account_key, a.ciasKey, a.ciasCn_s_org_smpl, a.ciaKey
FROM ciduCnCtptInvAccSmplExtAccAll AS a
WHERE (((a.ciaKey) Is Not Null));
