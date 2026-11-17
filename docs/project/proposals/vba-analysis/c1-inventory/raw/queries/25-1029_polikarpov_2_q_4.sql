-- Access QueryDef: 25-1029_polikarpov_2_q_4
-- Type: 0

SELECT ags_ipgPn.ipgpIpg, ags_ipgPn.ipgpNum, ags_ipgPn.ipgpCstAgPn, ags_ipgPn.ipgpSmTtl, ags_ipgPn.ipgpSh, ags_cstAgPn.cstapIpgPnN, ags_cstAgPn.cstapCstName, [25-1029_polikarpov_2_q].Код, [25-1029_polikarpov_2_q].lkv_25_hy1
FROM (ags_ipgPn INNER JOIN ags_cstAgPn ON ags_ipgPn.ipgpCstAgPn = ags_cstAgPn.cstapKey) LEFT JOIN [25-1029_polikarpov_2_q] ON ags_cstAgPn.cstapIpgPnN = [25-1029_polikarpov_2_q].cstAgPn
GROUP BY ags_ipgPn.ipgpIpg, ags_ipgPn.ipgpNum, ags_ipgPn.ipgpCstAgPn, ags_ipgPn.ipgpSmTtl, ags_ipgPn.ipgpSh, ags_cstAgPn.cstapIpgPnN, ags_cstAgPn.cstapCstName, [25-1029_polikarpov_2_q].Код, [25-1029_polikarpov_2_q].lkv_25_hy1
HAVING (((ags_ipgPn.ipgpIpg)=27));
