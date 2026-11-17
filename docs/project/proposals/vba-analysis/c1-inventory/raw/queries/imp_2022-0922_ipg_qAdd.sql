-- Access QueryDef: imp_2022-0922_ipg_qAdd
-- Type: 0

SELECT [imp_2022-0922_ipg].num, [imp_2022-0922_ipg].ttl, [imp_2022-0922_ipg].work, [imp_2022-0922_ipg].equip, [imp_2022-0922_ipg].others, [imp_2022-0922_ipg].mastering, ags_cstAgPn.cstapKey, 9 AS opg, 3 AS sh
FROM [imp_2022-0922_ipg] LEFT JOIN ags_cstAgPn ON [imp_2022-0922_ipg].code = ags_cstAgPn.cstapIpgPnN;
