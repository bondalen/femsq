-- Access QueryDef: ciduCnCtptInvAccSmplExtAccExtDbt
-- Type: SELECT (0)
-- dumped: 2026-08-24 15:25

SELECT z.cidutCntrPrtNum, z.cidutCntrPrtName, z.cidutCnName, z.cidutCnNameNull, z.cidutCnDate, z.cidutCnDateNull, z.cidutCnInv, z.cidutCnInvNull, z.cn_key, z.cn_s_org_key, z.iKey, z.ciKey, z.account_num, z.account_key, z.ciasKey, z.ciasCn_s_org_smpl, z.ciaKey, z.cidutCnInvNameNull, z.cidutUnloadKey, d.cn_inv_dbt_key
FROM (SELECT t.cidutCntrPrtNum, t.cidutCntrPrtName, t.cidutCnName, t.cidutCnNameNull, t.cidutCnDate, t.cidutCnDateNull, t.cidutCnInv, t.cidutCnInvNull, t.cn_key, t.cn_s_org_key, t.iKey, t.ciKey, t.account_num, t.account_key, t.ciasKey, t.ciasCn_s_org_smpl, t.ciaKey, t.cidutCnInvNameNull, a.cidutUnloadKey1 AS cidutUnloadKey FROM ciduCnCtptInvAccSmplExtAccExt AS t, (SELECT First (cidutUnloadKey) AS cidutUnloadKey1 FROM CnInvDbtUplTbl)  AS a)  AS z LEFT JOIN ags_cn_inv_dbt AS d ON (z.ciaKey = d.cidCnInvAccntCtpt) AND (z.cidutUnloadKey = d.cn_inv_dbt_upl);
