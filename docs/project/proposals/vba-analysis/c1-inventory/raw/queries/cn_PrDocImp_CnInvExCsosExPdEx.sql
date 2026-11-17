-- Access QueryDef: cn_PrDocImp_CnInvExCsosExPdEx
-- Type: 0

SELECT z.cn_key, z.CnNum, z.CnInvNum, z.CnInvDate, z.ciKey, z.inKeyCount, z.csosKey, z.AccountMain, z.ciasKey, z.cnpdTpOrd, z.cnpdTpOrdKey, z.cnpdNumNull, z.cnpdDateNull, ags_cn_PrDoc.cnpdKey
FROM (SELECT e.cn_key, e.CnNum, e.CnInvNum, e.CnInvDate, e.ciKey, e.inKeyCount, e.csosKey, e.AccountMain, e.ciasKey, i.cnpdTpOrd, i.cnpdTpOrdKey, i.cnpdNumNull, i.cnpdDateNull FROM cn_PrDocImp_CnInvExCsosEx AS e LEFT JOIN cn_PrDocImp AS i ON (e.AccountMain = i.AccountMain) AND (e.CnInvDate = i.cnpdCnInvDateNull) AND (e.CnInvNum = i.cnpdCnInvNumNull) AND (e.CnNum = i.cnpdCnNumNull))  AS z LEFT JOIN ags_cn_PrDoc ON (z.cnpdTpOrdKey = ags_cn_PrDoc.cnpdTpOrd) AND (z.cnpdDateNull = ags_cn_PrDoc.cnpdDateNull) AND (z.cnpdNumNull = ags_cn_PrDoc.cnpdNumNull) AND (z.ciasKey = ags_cn_PrDoc.cnpdCnInvAccntSmpl)
GROUP BY z.cn_key, z.CnNum, z.CnInvNum, z.CnInvDate, z.ciKey, z.inKeyCount, z.csosKey, z.AccountMain, z.ciasKey, z.cnpdTpOrd, z.cnpdTpOrdKey, z.cnpdNumNull, z.cnpdDateNull, ags_cn_PrDoc.cnpdKey
HAVING (((ags_cn_PrDoc.cnpdKey) Is Not Null));
