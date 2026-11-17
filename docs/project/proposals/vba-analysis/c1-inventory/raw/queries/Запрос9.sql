-- Access QueryDef: Запрос9
-- Type: 0

SELECT [22-1227_ipg23].cst, Count([22-1227_ipg23].cst) AS [Count-cst]
FROM [22-1227_ipg23]
GROUP BY [22-1227_ipg23].cst
ORDER BY Count([22-1227_ipg23].cst) DESC;
