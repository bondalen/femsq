-- Access QueryDef: ДляДоговораОдинКонтрагентНаВыгрузку
-- Type: 0

SELECT x.ciCn, x.cn_inv_dbt_upl, y.cidCounterParty
FROM (SELECT z.ciCn, z.cn_inv_dbt_upl, Count(z.cidCounterParty) AS [Count-cidCounterParty] FROM (SELECT i.ciCn, d.cn_inv_dbt_upl, d.cidCounterParty FROM (ags_cnInv AS i INNER JOIN ags_cnInvAccnt AS a ON i.ciKey = a.ciaCnInv) INNER JOIN ags_cn_inv_dbt AS d ON a.ciaKey = d.cidCnInvAccnt GROUP BY i.ciCn, d.cn_inv_dbt_upl, d.cidCounterParty)  AS z GROUP BY z.ciCn, z.cn_inv_dbt_upl HAVING (((Count(z.cidCounterParty))=1)))  AS x INNER JOIN (SELECT i.ciCn, d.cn_inv_dbt_upl, d.cidCounterParty FROM (ags_cnInv AS i INNER JOIN ags_cnInvAccnt AS a ON i.ciKey = a.ciaCnInv) INNER JOIN ags_cn_inv_dbt AS d ON a.ciaKey = d.cidCnInvAccnt GROUP BY i.ciCn, d.cn_inv_dbt_upl, d.cidCounterParty)  AS y ON (x.ciCn = y.ciCn) AND (x.cn_inv_dbt_upl = y.cn_inv_dbt_upl);
