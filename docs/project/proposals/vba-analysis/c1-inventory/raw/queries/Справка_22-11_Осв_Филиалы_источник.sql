-- Access QueryDef: Справка_22-11_Осв_Филиалы_источник
-- Type: 0

PARAMETERS ДатаОкончанияМесяца DateTime;
SELECT z.ogNm, z.branchName, z.cstAgPnCode, z.cstapCstName, z.lim, z.ag_lim, z.ag_Ful_OverFul, z.ag_LimPc, z.ag_PlOverLimit_, z.iv_lim, z.uk_lim, z.ag_PlAccum, z.ag_PlFulfillment, z.ag_PlPz, z.ag_PlOverFulfillment, z.ag_PlPercent, iif(isnull(z.ag_PlFulfillment), 0, z.ag_PlFulfillment) + iif(isnull(z.ag_PlOverFulfillment), 0, z.ag_PlOverFulfillment) AS ag_PlFulfillmentAll, z.ag_Pl_M, z.ag_acceptedTtl_M, z.ag_acceptedNot, z.ag_PlPz_M, z.mn, IIf([ag_lim]>0,"агентская",IIf([iv_lim]>0,"инвест.","прочая")) AS ipgSh, z.ag_accepted, z.ag_acceptedAccum, z.ag_agFeeAccepted, z.ag_agFeeAcceptedAccum, z.ag_acceptedRalp, z.ag_acceptedRalpAccum, z.ag_storageSum, z.ag_storageSumAccum, z.ag_cctSum, z.ag_cctSumAccum, z.ag_MnrlSum, z.ag_MnrlSumAccum, z.np_lim, z.np_iShKey, z.np_accepted, z.np_acceptedAccum, z.np_agFeeAccepted, z.np_agFeeAcceptedAccum, z.np_acceptedRalp, z.np_acceptedRalpAccum, z.np_storageSum, z.np_storageSumAccum, z.np_cctSum, z.np_cctSumAccum, z.np_MnrlSum, z.np_MnrlSumAccum, z.np_acceptedTtl, z.np_acceptedTtlAccum
FROM (SELECT 
			za.ogNm, iif(isnull(za.branch),-1, za.branch) as branch, 
			za.branchName, za.cstAgPnCode, za.cstapCstName, za.lim, za.ag_lim, za.ag_Ful_OverFul, 
			za.ag_LimPc, za.ag_PlOverLimit_, za.iv_lim, 
			za.uk_lim, 
			za.ag_PlAccum, za.ag_PlFulfillment, za.ag_PlPz, za.ag_PlOverFulfillment, za.ag_PlPercent, 
			za.ag_Pl_M, za.ag_acceptedTtl_M, za.ag_acceptedNot,
			za.ag_PlPz_M, za.mn, za.ogNmSort, za.cstAgPnCodeSort, 
			IIf([za].[cstAgPnCode]="всего" And [za].[branch]=0,1,0) AS wr,
			za.ag_accepted, za.ag_acceptedAccum, za.ag_agFeeAccepted, za.ag_agFeeAcceptedAccum, 
			za.ag_acceptedRalp, za.ag_acceptedRalpAccum, 
			za.ag_storageSum, za.ag_storageSumAccum, za.ag_cctSum, za.ag_cctSumAccum, za.ag_MnrlSum, za.ag_MnrlSumAccum, 
			za.np_lim, za.np_iShKey, za.np_accepted, za.np_acceptedAccum, za.np_agFeeAccepted, 
			za.np_agFeeAcceptedAccum, za.np_acceptedRalp, za.np_acceptedRalpAccum, 
			za.np_storageSum, za.np_storageSumAccum, za.np_cctSum, za.np_cctSumAccum, za.np_MnrlSum, 
			za.np_MnrlSumAccum, za.np_acceptedTtl, za.np_acceptedTtlAccum
		FROM 
			(
				SELECT 
					IIf(IsNull(p![ogNm]),"итого",p![ogNm]) AS ogNm, p.branch, p.branchName, 
					IIf(IsNull(p![cstAgPnCode]),"всего",p![cstAgPnCode]) AS cstAgPnCode, c.cstapCstName, 
					IIf(IsNull(p![ag_lim]),0,p![ag_lim])+IIf(IsNull(p![iv_lim]),0,p![iv_lim])+IIf(IsNull(p![uk_lim]),0,p![uk_lim]) AS lim, p.ag_lim, 
					IIf(p![ag_PlFulfillment]+p![ag_PlOverFulfillment]=0,Null,p![ag_PlFulfillment]+p![ag_PlOverFulfillment]) AS ag_Ful_OverFul, 
					(p![ag_PlFulfillment]+p![ag_PlOverFulfillment])/p![ag_lim] AS ag_LimPc, IIf([ag_PlOverLimit]=0,Null,[ag_PlOverLimit]) AS ag_PlOverLimit_, 
					p.iv_lim, p.uk_lim, IIf(p![ag_PlAccum]=0,Null,p![ag_PlAccum]) AS ag_PlAccum, 
					IIf(p![ag_PlFulfillment]=0,Null,p![ag_PlFulfillment]) AS ag_PlFulfillment, 
					IIf(IsNull(p![ag_PlAccum]) Or p![ag_PlAccum]=0,Null,p![ag_PlFulfillment]/p![ag_PlAccum]) AS ag_PlPz, 
					IIf(p![ag_PlOverFulfillment]=0,Null,p![ag_PlOverFulfillment]) AS ag_PlOverFulfillment, 
					p.ag_PlPercent, p.ag_Pl AS ag_Pl_M, p.ag_acceptedTtl AS ag_acceptedTtl_M, 
					(IIf(IsNull([p]![ag_presentedAccum]),0,[p]![ag_presentedAccum])+IIf(IsNull([p]![ag_presentedRalpAccum]),0,[p]![ag_presentedRalpAccum]))-(IIf(IsNull([p]![ag_acceptedAccum]),0,[p]![ag_acceptedAccum])+IIf(IsNull([p]![ag_acceptedRalpAccum]),0,[p]![ag_acceptedRalpAccum])) AS ag_acceptedNot, 
					IIf(IsNull([ag_Pl_M]) Or [ag_Pl_M]=0,Null,[ag_acceptedTtl_M]/[ag_Pl_M]) AS ag_PlPz_M, MonthName(Month([dateRslt])) AS mn, 
					p.ogNm AS ogNmSort, p.cstAgPnCode AS cstAgPnCodeSort, 
					p.ag_accepted, p.ag_acceptedAccum, p.ag_agFeeAccepted, p.ag_agFeeAcceptedAccum, p.ag_acceptedRalp, p.ag_acceptedRalpAccum, 
					p.ag_storageSum, p.ag_storageSumAccum, p.ag_cctSum, p.ag_cctSumAccum, p.ag_MnrlSum, p.ag_MnrlSumAccum, 
					p.np_lim, p.np_iShKey, p.np_accepted, p.np_acceptedAccum, p.np_agFeeAccepted, p.np_agFeeAcceptedAccum, p.np_acceptedRalp, p.np_acceptedRalpAccum, 
					p.np_storageSum, p.np_storageSumAccum, p.np_cctSum, p.np_cctSumAccum, p.np_MnrlSum, p.np_MnrlSumAccum, p.np_acceptedTtl, p.np_acceptedTtlAccum
				FROM ipgChRsltPlCstPercent AS p 
					LEFT JOIN ags_cstAgPn AS c ON p.cstAgPnCode = c.cstapIpgPnN
				WHERE 
					(((p.dateRslt)=[ДатаОкончанияМесяца]) AND 
					((IIf(IsNull([p]![ag_lim]), 0,[p]![ag_lim])+IIf(IsNull([p]![iv_lim]), 0,[p]![iv_lim])+IIf(IsNull([p]![uk_lim]), 0,[p]![uk_lim])+IIf(IsNull([p]![np_acceptedTtlAccum]), 0, [p]![np_acceptedTtlAccum]))>0))
			)  AS za
		WHERE (((IIf([za].[cstAgPnCode]="всего" And [za].[branch]=0,1,0))=0))
		ORDER BY za.ogNm, za.branchName, za.cstAgPnCode
	)  AS z
ORDER BY z.ogNmSort, z.branchName, z.cstAgPnCodeSort;
