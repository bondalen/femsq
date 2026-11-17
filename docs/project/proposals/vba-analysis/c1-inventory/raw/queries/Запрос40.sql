-- Access QueryDef: Запрос40
-- Type: 64

INSERT INTO ags_cnInv ( ciCn, ciInv, ciTimeOfEntry, ciNote )
SELECT z.cn_key, y.iKey, y.iTimeOfEntry, "Для первичных документов вручную" AS Выражение2
FROM (SELECT cn_PrDocImp_CnInvNt.inKeyCount, cn_PrDocImp_CnInvNt.CnNum, cn_PrDocImp_CnInvNt.cn_key, cn_PrDocImp_CnInvNt.CnInvNum, cn_PrDocImp_CnInvNt.CnInvDate, cn_PrDocImp_CnInvNt.ciKey, [CnInvNum] & "*" & [CnInvDate] & "*26-1112" AS insert_key, Now() AS Выражение1 FROM cn_PrDocImp_CnInvNt WHERE (((cn_PrDocImp_CnInvNt.inKeyCount)>0)))  AS z INNER JOIN (SELECT CStr(Left(iNote,100)) AS iNote100, ags_inv.iKey, * FROM ags_inv WHERE (((ags_inv.iKey)>107820)))  AS y ON z.insert_key = y.iNote100;
