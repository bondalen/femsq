-- Access QueryDef: Справка_22-11_Осв_Филиалы_R_источник
-- Type: 128

SELECT  
	iif(o.ogNm = "итого", "а", o.ipgSh) as ipgSh, lmm.lim as limSort, 
	iif(isnull(o.branchName), o.ogNm, null) as ogNm,
	iif(o.branchName=o.ogNm, "Центральный офис",o.branchName ) as branchName,  o.lim, o.ag_lim, 
	o.ag_Ful_OverFul, o.ag_LimPc, o.ag_PlOverLimit_, o.iv_lim, o.uk_lim,  
	o.ag_PlAccum, o.ag_PlFulfillment, o.ag_PlPz, o.ag_PlOverFulfillment, o.ag_PlPercent, 
	iif(o.ag_PlFulfillmentAll=0, null, o.ag_PlFulfillmentAll) as ag_PlFulfillmentAll,
	o.ag_Pl_M, o.ag_acceptedTtl_M, 
	iif(o.ag_acceptedNot=0, null, o.ag_acceptedNot) as ag_acceptedNot, 
	o.ag_PlPz_M, o.mn,  
	o.cstAgPnCode,
	o.ag_accepted, o.ag_acceptedAccum, o.ag_agFeeAccepted, o.ag_agFeeAcceptedAccum, 
	o.ag_acceptedRalp, o.ag_acceptedRalpAccum, 
	o.ag_storageSum, o.ag_storageSumAccum, o.ag_cctSum, o.ag_cctSumAccum, o.ag_MnrlSum, o.ag_MnrlSumAccum, 
	o.np_lim, o.np_iShKey, o.np_accepted, o.np_acceptedAccum, o.np_agFeeAccepted, 
	o.np_agFeeAcceptedAccum, o.np_acceptedRalp, o.np_acceptedRalpAccum, 
	o.np_storageSum, o.np_storageSumAccum, o.np_cctSum, o.np_cctSumAccum, o.np_MnrlSum, 
	o.np_MnrlSumAccum, o.np_acceptedTtl, o.np_acceptedTtlAccum
FROM  
	[Справка_22-11_Осв_Филиалы_источник] AS o  
		left join 
			( 
				SELECT 
					ob.ogNm, ob.lim, ob.branchName 
				FROM 
					[Справка_22-11_Осв_Филиалы_источник] AS ob 
				WHERE 
					(((ob.cstAgPnCode)="всего") AND ((ob.branchName) Is Null)) 
			) as lmm 
				on o.ogNm = lmm.ogNm 
WHERE (((o.cstAgPnCode)="всего"))
UNION select  
	"агентская_", 0, "Заказчики", null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 
	null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null    
from (select top 1 ipgKey from ags_ipg)
ORDER BY ipgSh, limSort DESC , lim DESC;
