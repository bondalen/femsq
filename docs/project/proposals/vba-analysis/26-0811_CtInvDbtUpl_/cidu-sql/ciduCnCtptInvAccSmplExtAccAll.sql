-- Access QueryDef: ciduCnCtptInvAccSmplExtAccAll
-- Type: SELECT (0)
-- dumped: 2026-08-24 15:25

SELECT c.cidutCntrPrtNum, c.cidutCntrPrtName, c.cidutCnName, c.cidutCnNameNull, c.cidutCnDate, c.cidutCnDateNull, c.cidutCnInv, c.cidutCnInvNull, c.cn_key, c.cn_s_org_key, c.iKey, c.ciKey, c.account_num, c.account_key, c.ciasKey, c.ciasCn_s_org_smpl, c.cidutCnInvNameNull, c.DbtCount, a.ciaKey
FROM (SELECT q.cidutCntrPrtNum, q.cidutCntrPrtName, q.cidutCnName, q.cidutCnNameNull, q.cidutCnDate, q.cidutCnDateNull, q.cidutCnInv, q.cidutCnInvNull, q.cn_key, q.cn_s_org_key, q.iKey, q.ciKey, q.account_num, q.account_key, q.ciasKey, q.ciasCn_s_org_smpl, q.cidutCnInvNameNull, q.DbtCount FROM ciduCnCtptInvAccSmplExtAcc AS q WHERE (((q.DbtCount)=1)))  AS c LEFT JOIN (SELECT a.ciaKey, a.ciaCnInvAccntSmpl, o.csoCnDate, o.csoCnDateNull, a.ciaName, a.ciaNameNull FROM ags_cn_s_org AS o INNER JOIN ags_cnInvAccnt AS a ON o.cn_s_org_key = a.ciaCn_s_org)  AS a ON (c.ciasKey = a.ciaCnInvAccntSmpl) AND (c.cidutCnInvNameNull = a.ciaNameNull) AND (c.cidutCnDateNull = a.csoCnDateNull);
