-- Access QueryDef: ciduCnCtptInvAccSmplExtAccExtCntDbt
-- Type: SELECT (0)
-- dumped: 2026-08-24 15:25

SELECT *
FROM ciduCnCtptInvAccSmplExtAccExtCnt LEFT JOIN ags_cn_inv_dbt ON (ciduCnCtptInvAccSmplExtAccExtCnt.ciaKey = ags_cn_inv_dbt.cidCnInvAccnt) AND (ciduCnCtptInvAccSmplExtAccExtCnt.cidutUnloadKey = ags_cn_inv_dbt.cn_inv_dbt_upl);
