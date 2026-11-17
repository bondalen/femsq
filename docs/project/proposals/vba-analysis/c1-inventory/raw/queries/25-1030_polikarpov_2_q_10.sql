-- Access QueryDef: 25-1030_polikarpov_2_q_10
-- Type: 0

SELECT [25-1030_polikarpov_2_q_9].iii, Sum([25-1030_polikarpov_2_q_9].lim) AS [Sum-lim], Count([25-1030_polikarpov_2_q_9].lim) AS [Count-lim]
FROM [25-1030_polikarpov_2_q_9]
WHERE ((([25-1030_polikarpov_2_q_9].iii) Is Not Null))
GROUP BY [25-1030_polikarpov_2_q_9].iii;
