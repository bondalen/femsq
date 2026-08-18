-- Access: RecordSource формы CnInvPmtUpl>Sum_t
-- Снято 2026-08-17 (конструктор → построитель запросов).
-- Источник — связанный объект ags_q_cn_inv_pm_upl_sum (= VIEW ags.q_cn_inv_pm_upl_sum).

SELECT
    ags_q_cn_inv_pm_upl_sum.cn_inv_pm_upl,
    ags_q_cn_inv_pm_upl_sum.account_num,
    ags_q_cn_inv_pm_upl_sum.dbt_blns,
    ags_q_cn_inv_pm_upl_sum.dbt_blns_overd,
    ags_q_cn_inv_pm_upl_sum.dbt_blns_not_overd,
    ags_q_cn_inv_pm_upl_sum.cdt_blns,
    ags_q_cn_inv_pm_upl_sum.cdt_blns_overd,
    ags_q_cn_inv_pm_upl_sum.cdt_blns_not_overd,
    ags_q_cn_inv_pm_upl_sum.blns
FROM ags_q_cn_inv_pm_upl_sum;
