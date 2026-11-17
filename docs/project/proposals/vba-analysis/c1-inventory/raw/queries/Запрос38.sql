-- Access QueryDef: Запрос38
-- Type: 0

SELECT e.CnInvDate, i.cnpdDateNull, e.cn_key, e.CnNum, e.CnInvNum, e.ciKey, e.inKeyCount, e.csosKey, e.AccountMain, e.ciasKey, i.cnpdTpOrdKey, i.cnpdNumNull, i.cnpdTpOrd
FROM cn_PrDocImp_CnInvExCsosEx AS e LEFT JOIN cn_PrDocImp AS i ON (e.AccountMain = i.AccountMain) AND (e.CnInvDate = i.cnpdCnInvDateNull) AND (e.CnInvNum = i.cnpdCnInvNumNull) AND (e.CnNum = i.cnpdCnNumNull);
