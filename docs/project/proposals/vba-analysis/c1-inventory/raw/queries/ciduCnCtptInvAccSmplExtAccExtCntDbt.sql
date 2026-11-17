-- Access QueryDef: ciduCnCtptInvAccSmplExtAccExtCntDbt
-- Type: 0

SELECT *
FROM ciduCnCtptInvAccSmplExtAccExtCnt LEFT JOIN ags_cn_inv_dbt ON (ciduCnCtptInvAccSmplExtAccExtCnt.ciaKey = ags_cn_inv_dbt.cidCnInvAccnt) AND (ciduCnCtptInvAccSmplExtAccExtCnt.cidutUnloadKey = ags_cn_inv_dbt.cn_inv_dbt_upl);
