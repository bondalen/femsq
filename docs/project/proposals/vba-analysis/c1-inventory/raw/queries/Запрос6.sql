-- Access QueryDef: Запрос6
-- Type: 0

SELECT y.rootNew, y.cst, y.cstapIpgPnN, ags_cstAgPn.cstapCsta
FROM (SELECT z.rootNew, z.cst, p.cstapIpgPnN FROM (SELECT z.rootNew, i.cst FROM Запрос4 AS z INNER JOIN [22-1227_ipg23] AS i ON z.rootNew=right(i.cst,4))  AS z LEFT JOIN ags_cstAgPn AS p ON z.rootNew=right(p.cstapIpgPnN,4))  AS y INNER JOIN ags_cstAgPn ON y.cstapIpgPnN = ags_cstAgPn.cstapIpgPnN;
