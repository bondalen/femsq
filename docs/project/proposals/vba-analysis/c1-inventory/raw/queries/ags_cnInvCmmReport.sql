-- Access QueryDef: ags_cnInvCmmReport
-- Type: 0

SELECT ags_cn_inv_dbt.cn_inv_dbt_upl, ags_cn_inv_dbt.number, ags_cn_inv_dbt.dbt_ttl, ags_cn_inv_dbt.dbt_overd
FROM ags_cn_inv_dbt
WHERE (((ags_cn_inv_dbt.cn_inv_dbt_upl)=10) AND ((ags_cn_inv_dbt.dbt_overd)>0))
ORDER BY ags_cn_inv_dbt.number;
