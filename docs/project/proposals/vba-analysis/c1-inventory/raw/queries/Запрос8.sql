-- Access QueryDef: Запрос8
-- Type: 0

SELECT 12 AS ipg, IIf([lim]=615.65,2,3) AS sh, i.num, ags_cstAgPn.cstapKey, IIf([lim]=0,Null,[lim]) AS limN, IIf([limWork]=0,Null,[limWork]) AS limWorkN, IIf([limEquip]=0,Null,[limEquip]) AS limEquipN, IIf([limOthers]=0,Null,[limOthers]) AS limOthersN, IIf([limAgFee]=0,Null,[limAgFee]) AS limAgFeeN, IIf([limRes]=0,Null,[limRes]) AS limResN, IIf([comisTask]="0",Null,[comisTask]) AS comisTaskN
FROM [22-1227_ipg23] AS i LEFT JOIN ags_cstAgPn ON i.cst = ags_cstAgPn.cstapIpgPnN;
