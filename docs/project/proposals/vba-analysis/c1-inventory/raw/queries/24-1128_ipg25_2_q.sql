-- Access QueryDef: 24-1128_ipg25_2_q
-- Type: 0

SELECT [24-1128_ipg25_2].num, [24-1128_ipg25_2].cstAgPn, [24-1128_ipg25_2].ipgSh, ags_cstAgPn.cstapKey
FROM [24-1128_ipg25_2] LEFT JOIN ags_cstAgPn ON [24-1128_ipg25_2].cstAgPn = ags_cstAgPn.cstapIpgPnN;
