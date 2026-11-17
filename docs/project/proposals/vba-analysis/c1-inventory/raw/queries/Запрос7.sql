-- Access QueryDef: Запрос7
-- Type: 0

SELECT x.rootNew, x.ccc, i.cst, i.cstName
FROM (SELECT y.rootNew, count(p.cstapKey) AS ccc 
FROM 
(
SELECT rootNew FROM (SELECT ags_cstAgPn.cstapKey, i.cst, IIf(Mid$([cst],5,1)="3",Null,Right$([cst],4)) AS rootNew FROM [22-1227_ipg23] AS i LEFT JOIN ags_cstAgPn ON i.cst = ags_cstAgPn.cstapIpgPnN WHERE (((ags_cstAgPn.cstapKey) Is Null)) ORDER BY i.cst)  AS z WHERE not rootNew is null
)  AS y LEFT JOIN ags_cstAgPn AS p ON y.rootNew=right(p.cstapIpgPnN,4) 
GROUP BY y.rootNew
)  AS x LEFT JOIN [22-1227_ipg23] AS i ON x.rootNew = right(i.cst, 4);
