-- Access QueryDef: ags_cn_PrDocP_q_CCt
-- Type: 0

SELECT Year([cnpdDate]) AS yyyy, *
FROM (ags_cn_PrDocP AS p INNER JOIN ags_cn_PrDoc AS d ON p.pdpPrDoc = d.cnpdKey) INNER JOIN ags_cnInvAccntSmpl AS i ON d.cnpdCnInvAccntSmpl = i.ciasKey
WHERE d.cnpdTpOrd = 3 and i.ciasAccnt = 30;
