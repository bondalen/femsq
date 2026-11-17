-- Access QueryDef: ags_cn_PrDocP_q
-- Type: 0

SELECT Year([cnpdDate]) AS yyyy, *
FROM ags_cn_PrDocP AS p INNER JOIN ags_cn_PrDoc AS d ON p.pdpPrDoc = d.cnpdKey
WHERE (((d.cnpdTpOrd)=1 Or (d.cnpdTpOrd)=2 Or (d.cnpdTpOrd)=4));
