-- Access QueryDef: ciduCnNumNotLoad
-- Type: SELECT (0)
-- dumped: 2026-08-24 15:25

SELECT z.cidutCntrPrtNum, z.cidutCntrPrtName, z.cidutCntrPrtITN, z.cidutCnNameNull AS cidutCnName, z.cidutCnDateNull AS cidutCnDate, Count(y.cn_key) AS cnCount
FROM ciduCnCtptExistNot AS z LEFT JOIN (SELECT n.cnnNumNull AS cn_number, o.cn_key FROM ags_cn AS o INNER JOIN ags_cnNum AS n ON o.cn_key = n.cnnCn)  AS y ON z.cidutCnNameNull = y.cn_number
GROUP BY z.cidutCntrPrtNum, z.cidutCntrPrtName, z.cidutCntrPrtITN, z.cidutCnNameNull, z.cidutCnDateNull
HAVING (((Count(y.cn_key))=0));
