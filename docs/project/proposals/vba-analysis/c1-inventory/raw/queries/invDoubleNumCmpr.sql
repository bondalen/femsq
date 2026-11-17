-- Access QueryDef: invDoubleNumCmpr
-- Type: 0

SELECT ags_cnInv.ciInv, ags_cnInvAccnt.ciaName, ags_accnt.account_num, ags_cn_inv_dbt_upl.uplStatusOnDate, ags_cn_inv_dbt.dbt_ttl, ags_cn_inv_dbt.dbt_overd, ags_cn.cnName
FROM (((((ags_cn_inv_dbt INNER JOIN ags_cnInvAccnt ON ags_cn_inv_dbt.cidCnInvAccntCtpt = ags_cnInvAccnt.ciaKey) INNER JOIN ags_cnInvAccntSmpl ON ags_cnInvAccnt.ciaCnInvAccntSmpl = ags_cnInvAccntSmpl.ciasKey) INNER JOIN ags_cnInv ON ags_cnInvAccntSmpl.ciasCnInv = ags_cnInv.ciKey) INNER JOIN ags_cn_inv_dbt_upl ON ags_cn_inv_dbt.cn_inv_dbt_upl = ags_cn_inv_dbt_upl.upl_key) INNER JOIN ags_accnt ON ags_cnInvAccntSmpl.ciasAccnt = ags_accnt.account_key) INNER JOIN ags_cn ON ags_cnInv.ciCn = ags_cn.cn_key;
