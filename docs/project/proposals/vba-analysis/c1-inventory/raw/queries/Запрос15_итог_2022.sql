-- Access QueryDef: Запрос15_итог_2022
-- Type: 0

SELECT z.account_num, z.overdSum, z.overdSumMatured, overdSum-overdSumMatured AS overdSumRest, overdSumMatured/overdSum AS overdSumMaturedPrct
FROM (SELECT i.account_num, sum(i.[2022-02-10_Overd]) as overdSum, sum(i.[2023-02-02_погашено]) as overdSumMatured
FROM [ags_Yr_DbtChangesRslt_23-0210] AS i
WHERE (((i.[2022-02-10_org_id_value_l])<>55) AND ((i.[2022-02-10_Overd])>0))
group by i.account_num
)  AS z;
