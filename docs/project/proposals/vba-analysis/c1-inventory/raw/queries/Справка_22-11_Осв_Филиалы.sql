-- Access QueryDef: Справка_22-11_Осв_Филиалы
-- Type: 0

PARAMETERS ДатаОкончанияМесяца DateTime;
SELECT z.ogNm, z.branchName, z.cstAgPnCode, z.cstapCstName, z.lim, z.ag_lim, z.ag_Ful_OverFul, z.ag_LimPc, z.ag_PlOverLimit_, z.iv_lim, z.uk_lim, z.ag_PlAccum, z.ag_PlFulfillment, z.ag_PlPz, z.ag_PlOverFulfillment, z.ag_PlPercent, iif(isnull(z.ag_PlFulfillment), 0, z.ag_PlFulfillment) + iif(isnull(z.ag_PlOverFulfillment), 0, z.ag_PlOverFulfillment) AS ag_PlFulfillmentAll, z.ag_Pl_M, z.ag_acceptedTtl_M, z.ag_acceptedNot, z.ag_PlPz_M, z.mn, y.ag_PlAccum AS PrM_ag_PlAccum, y.ag_PlFulfillment AS PrM_ag_PlFulfillment, y.ag_PlPz AS PrM_ag_PlPz, y.ag_PlOverFulfillment AS PrM_ag_PlOverFulfillment, y.ag_PlPercent AS PrM_ag_PlPercent, iif(isnull(y.ag_PlFulfillment), 0, y.ag_PlFulfillment) + iif(isnull(y.ag_PlOverFulfillment), 0, y.ag_PlOverFulfillment) AS PrM_ag_PlFulfillmentAll, y.ag_Pl_M AS PrM_ag_Pl_M, y.ag_acceptedTtl_M AS PrM_ag_acceptedTtl_M, y.ag_PlPz_M AS PrM_ag_PlPz_M, y.mnPrevious AS PrM_mnPrevious, x.ag_PlAccum AS PrM_ag_PlAccum2, x.ag_PlFulfillment AS PrM_ag_PlFulfillment2, x.ag_PlPz AS PrM_ag_PlPz2, x.ag_PlOverFulfillment AS PrM_ag_PlOverFulfillment2, x.ag_PlPercent AS PrM_ag_PlPercent2, iif(isnull(x.ag_PlFulfillment), 0, x.ag_PlFulfillment) + iif(isnull(x.ag_PlOverFulfillment), 0, x.ag_PlOverFulfillment) AS PrM_ag_PlFulfillment2All, x.ag_Pl_M AS PrM_ag_Pl_M2, x.ag_acceptedTtl_M AS PrM_ag_acceptedTtl_M2, x.ag_PlPz_M AS PrM_ag_PlPz_M2, x.mnPrevious AS PrM_mnPrevious2, IIf([ag_lim]>0,"агентская",IIf([iv_lim]>0,"инвест.","прочая")) AS ipgSh, z.np_acceptedTtlAccum
FROM ((SELECT 
				za.ogNm, 
				iif(isnull(za.branch),-1, za.branch) as branch, 
				za.branchName, za.cstAgPnCode, za.cstapCstName, za.lim, za.ag_lim, za.ag_Ful_OverFul, 
				za.ag_LimPc, za.ag_PlOverLimit_, za.iv_lim, 
				za.uk_lim, 
				za.ag_PlAccum, za.ag_PlFulfillment, za.ag_PlPz, za.ag_PlOverFulfillment, za.ag_PlPercent, 
				za.ag_Pl_M, za.ag_acceptedTtl_M, za.ag_acceptedNot,
				za.ag_PlPz_M, za.mn, za.ogNmSort, za.cstAgPnCodeSort, 
				IIf([za].[cstAgPnCode]="всего" And [za].[branch]=0,1,0) AS wr,
    za.np_acceptedTtlAccum
			FROM 
				(
					SELECT 
						IIf(IsNull(p![ogNm]),"итого",p![ogNm]) AS ogNm, p.branch, p.branchName, 
						IIf(IsNull(p![cstAgPnCode]),"всего",p![cstAgPnCode]) AS cstAgPnCode, c.cstapCstName, 
						IIf(IsNull(p![ag_lim]),0,p![ag_lim])+IIf(IsNull(p![iv_lim]),0,p![iv_lim])+IIf(IsNull(p![uk_lim]),0,p![uk_lim]) AS lim, 
						p.ag_lim, 
						IIf(p![ag_PlFulfillment]+p![ag_PlOverFulfillment]=0,Null,p![ag_PlFulfillment]+p![ag_PlOverFulfillment]) AS ag_Ful_OverFul, 
						(p![ag_PlFulfillment]+p![ag_PlOverFulfillment])/p![ag_lim] AS ag_LimPc, 
						IIf([ag_PlOverLimit]=0,Null,[ag_PlOverLimit]) AS ag_PlOverLimit_, p.iv_lim, p.uk_lim, 
						IIf(p![ag_PlAccum]=0,Null,p![ag_PlAccum]) AS ag_PlAccum, 
						IIf(p![ag_PlFulfillment]=0,Null,p![ag_PlFulfillment]) AS ag_PlFulfillment, 
						IIf(IsNull(p![ag_PlAccum]) Or p![ag_PlAccum]=0,Null,p![ag_PlFulfillment]/p![ag_PlAccum]) AS ag_PlPz, 
						IIf(p![ag_PlOverFulfillment]=0,Null,p![ag_PlOverFulfillment]) AS ag_PlOverFulfillment, p.ag_PlPercent, 
						p.ag_Pl AS ag_Pl_M, p.ag_acceptedTtl AS ag_acceptedTtl_M, 
						(IIf(IsNull([p]![ag_presentedAccum]), 0, [p]![ag_presentedAccum]) + IIf(IsNull([p]![ag_presentedRalpAccum]), 0, [p]![ag_presentedRalpAccum])) - (IIf(IsNull([p]![ag_acceptedAccum]), 0, [p]![ag_acceptedAccum]) + IIf(IsNull([p]![ag_acceptedRalpAccum]), 0, [p]![ag_acceptedRalpAccum])) as ag_acceptedNot,
						IIf(IsNull([ag_Pl_M]) Or [ag_Pl_M]=0,Null,[ag_acceptedTtl_M]/[ag_Pl_M]) AS ag_PlPz_M, 
						MonthName(Month([dateRslt])) AS mn, p.ogNm AS ogNmSort, p.cstAgPnCode AS cstAgPnCodeSort, p.np_acceptedTtlAccum
					FROM ipgChRsltPlCstPercent AS p 
						LEFT JOIN ags_cstAgPn AS c ON p.cstAgPnCode = c.cstapIpgPnN
					WHERE 
						(((p.dateRslt)=[ДатаОкончанияМесяца]) AND 
						((IIf(IsNull([p]![ag_lim]),0,[p]![ag_lim])+IIf(IsNull([p]![iv_lim]),0,[p]![iv_lim])+IIf(IsNull([p]![uk_lim]),0,[p]![uk_lim]))>0))
				)  AS za
			WHERE (((IIf([za].[cstAgPnCode]="всего" And [za].[branch]=0,1,0))=0))
			ORDER BY za.ogNm, za.branchName, za.cstAgPnCode
		)  AS z LEFT JOIN (Select 
						zb.ogNm, 
						iif(isnull(zb.branch),-1, zb.branch) as branch, zb.branchName, 
						zb.cstAgPnCode, zb.ag_PlAccum, zb.ag_PlFulfillment, zb.ag_PlPz, 
						zb.ag_PlOverFulfillment, zb.ag_PlPercent, 
						zb.ag_Pl_M, zb.ag_acceptedTtl_M, zb.ag_PlPz_M, zb.mnPrevious
					From
						(
							SELECT 
								IIf(IsNull(p.[ogNm]),"итого",p.[ogNm]) AS ogNm, 
								p.branch, p.branchName, 
								IIf(IsNull(p.[cstAgPnCode]),"всего",p.[cstAgPnCode]) AS cstAgPnCode, 
								IIf(p.[ag_PlAccum]=0,Null,p.[ag_PlAccum]) AS ag_PlAccum, 
								IIf(p.[ag_PlFulfillment]=0,Null,p.[ag_PlFulfillment]) AS ag_PlFulfillment, 
								IIf(IsNull(p.[ag_PlAccum]) Or p.[ag_PlAccum]=0,Null,p.[ag_PlFulfillment]/p.[ag_PlAccum]) AS ag_PlPz, 
								IIf(p.[ag_PlOverFulfillment]=0,Null,p.[ag_PlOverFulfillment]) AS ag_PlOverFulfillment, p.ag_PlPercent, 
								p.ag_Pl AS ag_Pl_M, p.ag_acceptedTtl AS ag_acceptedTtl_M, 
								IIf(IsNull([ag_Pl_M]) Or [ag_Pl_M]=0,Null,[ag_acceptedTtl_M]/[ag_Pl_M]) AS ag_PlPz_M, 
								IIf(IsNull([dateRslt]),Null,MonthName(Month([dateRslt]))) AS mnPrevious 
							FROM ipgChRsltPlCstPercent AS p 
								LEFT JOIN ags_cstAgPn AS c ON p.cstAgPnCode = c.cstapIpgPnN 
							WHERE
								(
									(
										(
											p.dateRslt
										)
										=IIf
											(
												Month([ДатаОкончанияМесяца])=1, 
												0, 
												ddLastDayInMonth
													(
														DateSerial
															(
																Year([ДатаОкончанияМесяца]), 
																Month([ДатаОкончанияМесяца])-1, 
																1
															)
													)
											)
									) 
									And 
									((IIf(IsNull(p.ag_lim),0,p.ag_lim)+IIf(IsNull(p.iv_lim),0,p.iv_lim)+IIf(IsNull(p.uk_lim),0,p.uk_lim))>0)
									)
						) as zb
					WHERE (((IIf([zb].[cstAgPnCode]="всего" And [zb].[branch]=0,1,0))=0))
					ORDER BY zb.ogNm, zb.branchName, zb.cstAgPnCode
				)  AS y ON (z.branch = y.branch) AND (z.ogNm = y.ogNm) AND (z.cstAgPnCode = y.cstAgPnCode)) LEFT JOIN (SELECT 
	zc.ogNm, 
	iif(isnull(zc.branch),-1, zc.branch) as branch, zc.branchName,  
	zc.cstAgPnCode, zc.ag_PlAccum, zc.ag_PlFulfillment, zc.ag_PlPz, zc.ag_PlOverFulfillment, zc.ag_PlPercent, zc.ag_Pl_M, 
	zc.ag_acceptedTtl_M, zc.ag_PlPz_M, zc.mnPrevious 
FROM 
	(
		SELECT 
			IIf(IsNull(p![ogNm]),"итого",p![ogNm]) AS ogNm, 
			p.branch, p.branchName, IIf(IsNull(p![cstAgPnCode]),"всего",p![cstAgPnCode]) AS cstAgPnCode, 
			IIf(p![ag_PlAccum]=0,Null,p![ag_PlAccum]) AS ag_PlAccum, 
			IIf(p![ag_PlFulfillment]=0,Null,p![ag_PlFulfillment]) AS ag_PlFulfillment, 
			IIf(IsNull(p![ag_PlAccum]) Or p![ag_PlAccum]=0,Null,p![ag_PlFulfillment]/p![ag_PlAccum]) AS ag_PlPz, 
			IIf(p![ag_PlOverFulfillment]=0,Null,p![ag_PlOverFulfillment]) AS ag_PlOverFulfillment, 
			p.ag_PlPercent, p.ag_Pl AS ag_Pl_M, p.ag_acceptedTtl AS ag_acceptedTtl_M, 
			IIf(IsNull([ag_Pl_M]) Or [ag_Pl_M]=0,Null,[ag_acceptedTtl_M]/[ag_Pl_M]) AS ag_PlPz_M, 
			IIf(IsNull([dateRslt]),Null,MonthName(Month([dateRslt]))) AS mnPrevious 
		FROM 
			ipgChRsltPlCstPercent AS p LEFT JOIN ags_cstAgPn AS c ON p.cstAgPnCode = c.cstapIpgPnN 
		WHERE 
			(((p.dateRslt)=IIf(Month([ДатаОкончанияМесяца])<3, 0, ddLastDayInMonth(DateSerial(Year([ДатаОкончанияМесяца]), 
			Month([ДатаОкончанияМесяца])-2, 1)))) 
			And ((IIf(IsNull(p!ag_lim), 0, p!ag_lim)+IIf(IsNull(p!iv_lim), 0, p!iv_lim)+IIf(IsNull(p!uk_lim), 0, p!uk_lim))>0))
	)  AS zc
WHERE (((IIf([zc].[cstAgPnCode]="всего" And [zc].[branch]=0,1,0))=0))
		)  AS x ON (z.branch = x.branch) AND (z.ogNm = x.ogNm) AND (z.cstAgPnCode = x.cstAgPnCode)
ORDER BY z.ogNmSort, z.branchName, z.cstAgPnCodeSort;
