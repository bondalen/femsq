-- Access QueryDef: Запрос42
-- Type: 0

SELECT cn_PrDocImp_26.cnpdTpOrd, cn_PrDocImp_26.StatusOfDICtext, cn_PrDocImp_26.satstusOfOUKVtext, cn_PrDocImp_26.AccountMain, Sum(cn_PrDocImp_26.summ) AS [Sum-summ], Sum(cn_PrDocImp_26.cost) AS [Sum-cost], Sum(cn_PrDocImp_26.SumTax) AS [Sum-SumTax], Sum(cn_PrDocImp_26.costVAT) AS [Sum-costVAT]
FROM cn_PrDocImp_26
GROUP BY cn_PrDocImp_26.cnpdTpOrd, cn_PrDocImp_26.StatusOfDICtext, cn_PrDocImp_26.satstusOfOUKVtext, cn_PrDocImp_26.AccountMain
ORDER BY cn_PrDocImp_26.cnpdTpOrd, cn_PrDocImp_26.StatusOfDICtext, cn_PrDocImp_26.satstusOfOUKVtext, cn_PrDocImp_26.AccountMain;
