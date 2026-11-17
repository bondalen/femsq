-- Access QueryDef: Запрос17
-- Type: 128

SELECT  
	iif(o.ogNm = "итого", "а", o.ipgSh) as ipgSh, lmm.lim as limSort, 
iif(o.cstAgPnCode="всего", o.ogNm, o.cstAgPnCode) as ogNm,
	iif(o.branchName=o.ogNm, "Центральный офис",o.branchName ) as branchName,  
	o.lim, o.ag_lim, o.ag_Ful_OverFul, o.ag_LimPc, o.ag_PlOverLimit_, o.iv_lim, o.uk_lim,  o.ag_PlAccum, 
	o.ag_PlFulfillment, o.ag_PlPz, o.ag_PlOverFulfillment, o.ag_PlPercent, o.ag_Pl_M, o.ag_acceptedTtl_M, 
	o.ag_PlPz_M, o.mn,  o.PrM_ag_PlAccum, o.PrM_ag_PlFulfillment, o.PrM_ag_PlPz, o.PrM_ag_PlOverFulfillment, 
	o.PrM_ag_PlPercent, o.PrM_ag_Pl_M, o.PrM_ag_acceptedTtl_M, o.PrM_ag_PlPz_M, o.PrM_mnPrevious,  
	o.PrM_ag_PlAccum2, o.PrM_ag_PlFulfillment2, o.PrM_ag_PlPz2, o.PrM_ag_PlOverFulfillment2, o.PrM_ag_PlPercent2, 
	o.PrM_ag_Pl_M2, o.PrM_ag_acceptedTtl_M2, o.PrM_ag_PlPz_M2, o.PrM_mnPrevious2, o.cstAgPnCode   
FROM  
	[Справка_22-11_Осв_Филиалы] AS o  
		left join 
			( 
				SELECT ob.ogNm, ob.lim, ob.branchName 
				FROM [Справка_22-11_Осв_Филиалы] AS ob 
				WHERE (((ob.cstAgPnCode)="всего") AND ((ob.branchName) Is Null)) 
			) as lmm on o.ogNm = lmm.ogNm 
UNION select  
	"агентская_", 0, "Заказчики", null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 
	null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null  
from (select top 1 ipgKey from ags_ipg)
ORDER BY ipgSh, limSort DESC , lim DESC;
