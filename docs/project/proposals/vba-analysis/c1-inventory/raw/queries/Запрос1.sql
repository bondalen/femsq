-- Access QueryDef: Запрос1
-- Type: 0

SELECT z.cst, z.[2022-02-10_ciaKey], z.gr, z.type, ags_cstAgPn.cstapKey
FROM (SELECT IIf(IsNull([22qIII_cst]),[Код стройки],[22qIII_cst]) AS cst, y.[2022-02-10_ciaKey], 13 AS gr, 2 AS type FROM [ags_Yr_DbtChangesRslt_22-1114_PIR_2] AS y WHERE (((y.[22qIII_mery]) Is Not Null)))  AS z INNER JOIN ags_cstAgPn ON z.cst = ags_cstAgPn.cstapIpgPnN;
