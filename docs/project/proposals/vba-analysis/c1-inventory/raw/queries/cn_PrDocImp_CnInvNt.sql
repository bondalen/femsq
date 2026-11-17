-- Access QueryDef: cn_PrDocImp_CnInvNt
-- Type: 0

SELECT x.cn_key, x.CnNum, x.CnInvNum, x.CnInvDate, x.ciKey, Count(ags_invNum.inKey) AS inKeyCount
FROM (SELECT z.cn_key, z.CnNum, z.CnInvNum, z.CnInvDate, y.ciKey FROM (SELECT i.cn_key, i.cnpdCnNumNull AS CnNum, i.cnpdCnInvNumNull AS CnInvNum, i.cnpdCnInvDateNull AS CnInvDate FROM cn_PrDocImp AS i WHERE (((i.cn_key) Is Not Null)) GROUP BY i.cn_key, i.cnpdCnNumNull, i.cnpdCnInvNumNull, i.cnpdCnInvDateNull)  AS z LEFT JOIN (SELECT ci.ciKey, ci.ciCn, i.iDateNull, n.inNumNull FROM (ags_cnInv AS ci INNER JOIN ags_inv AS i ON ci.ciInv = i.iKey) INNER JOIN ags_invNum AS n ON i.iKey = n.inInv)  AS y ON (z.CnInvDate = y.iDateNull) AND (z.CnInvNum = y.inNumNull) AND (z.cn_key = y.ciCn) GROUP BY z.cn_key, z.CnNum, z.CnInvNum, z.CnInvDate, y.ciKey)  AS x LEFT JOIN ags_invNum ON x.CnInvNum = ags_invNum.inNum
GROUP BY x.cn_key, x.CnNum, x.CnInvNum, x.CnInvDate, x.ciKey
HAVING (((x.ciKey) Is Null));
