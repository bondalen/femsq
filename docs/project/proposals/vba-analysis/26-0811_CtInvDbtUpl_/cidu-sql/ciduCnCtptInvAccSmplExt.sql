-- Access QueryDef: ciduCnCtptInvAccSmplExt
-- Type: SELECT (0)
-- dumped: 2026-08-24 15:25

SELECT ciduCnCtptInvAccSmplAll.cidutCntrPrtNum, ciduCnCtptInvAccSmplAll.cidutCntrPrtName, ciduCnCtptInvAccSmplAll.cidutCnName, ciduCnCtptInvAccSmplAll.cidutCnNameNull, ciduCnCtptInvAccSmplAll.cidutCnDate, ciduCnCtptInvAccSmplAll.cidutCnDateNull, ciduCnCtptInvAccSmplAll.cidutCnInv, ciduCnCtptInvAccSmplAll.cidutCnInvNull, ciduCnCtptInvAccSmplAll.cn_key, ciduCnCtptInvAccSmplAll.cn_s_org_key, ciduCnCtptInvAccSmplAll.iKey, ciduCnCtptInvAccSmplAll.ciKey, ciduCnCtptInvAccSmplAll.account_num, ciduCnCtptInvAccSmplAll.account_key, ciduCnCtptInvAccSmplAll.ciasKey, ciduCnCtptInvAccSmplAll.ciasCn_s_org_smpl
FROM ciduCnCtptInvAccSmplAll
WHERE (((ciduCnCtptInvAccSmplAll.ciasKey) Is Not Null));
