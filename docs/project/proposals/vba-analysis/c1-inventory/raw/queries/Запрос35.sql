-- Access QueryDef: Запрос35
-- Type: 0

SELECT [24-0813_mnrl_imp].amPositing, Left([amCst],11) AS cst, Sum([24-0813_mnrl_imp].amSum) AS [Sum-amSum], [24-0813_mnrl_imp].amBranch, [24-0813_mnrl_imp].amType
FROM [24-0813_mnrl_imp]
GROUP BY [24-0813_mnrl_imp].amPositing, Left([amCst],11), [24-0813_mnrl_imp].amBranch, [24-0813_mnrl_imp].amType;
