-- Access QueryDef: 25-1029_polikarpov_2_q
-- Type: 0

SELECT p.Код, p.cstAgPn, p.cstName, p.lkv_25_hy1, p.pl_01_10
FROM [25-1029_polikarpov_2] AS p LEFT JOIN ags_cstAgPn AS c ON p.cstAgPn = c.cstapIpgPnN
WHERE (((p.cstName)<>"Подрядные работы" And (p.cstName)<>"Оборудование" And (p.cstName)<>"Прочие, всего") AND ((p.lkv_25_hy1)>0) AND ((c.cstapKey) Is Not Null));
