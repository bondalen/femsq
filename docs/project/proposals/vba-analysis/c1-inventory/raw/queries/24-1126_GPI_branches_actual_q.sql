-- Access QueryDef: 24-1126_GPI_branches_actual_q
-- Type: 0

SELECT z.[Count-Код1], z.код, [24-1126_GPI_branches_actual].филиал
FROM (SELECT [24-1126_GPI_branches_actual].код, Count([24-1126_GPI_branches_actual].Код1) AS [Count-Код1]
FROM [24-1126_GPI_branches_actual]
GROUP BY [24-1126_GPI_branches_actual].код
HAVING (((Count([24-1126_GPI_branches_actual].Код1))>1))
ORDER BY Count([24-1126_GPI_branches_actual].Код1) DESC
)  AS z INNER JOIN [24-1126_GPI_branches_actual] ON z.код = [24-1126_GPI_branches_actual].код
ORDER BY z.код, [24-1126_GPI_branches_actual].филиал;
