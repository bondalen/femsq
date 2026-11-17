-- Access QueryDef: Запрос15
-- Type: 0

PARAMETERS ДатаОкончанияМесяца DateTime;
SELECT z.ogNm, z.branchName, z.cstAgPnCode, z.cstapCstName, z.lim, z.ag_lim, z.ag_Ful_OverFul, z.ag_LimPc, z.ag_PlOverLimit_, z.iv_lim, z.uk_lim, z.ag_PlAccum, z.ag_PlFulfillment, z.ag_PlPz, z.ag_PlOverFulfillment, z.ag_PlPercent, z.ag_Pl_M, z.ag_acceptedTtl_M, z.ag_PlPz_M, z.mn, y.ag_PlAccum AS PrM_ag_PlAccum, y.ag_PlFulfillment AS PrM_ag_PlFulfillment, y.ag_PlPz AS PrM_ag_PlPz, y.ag_PlOverFulfillment AS PrM_ag_PlOverFulfillment, y.ag_PlPercent AS PrM_ag_PlPercent, y.ag_Pl_M AS PrM_ag_Pl_M, y.ag_acceptedTtl_M AS PrM_ag_acceptedTtl_M, y.ag_PlPz_M AS PrM_ag_PlPz_M, y.mnPrevious AS PrM_mnPrevious, x.ag_PlAccum AS PrM_ag_PlAccum2, x.ag_PlFulfillment AS PrM_ag_PlFulfillment2, x.ag_PlPz AS PrM_ag_PlPz2, x.ag_PlOverFulfillment AS PrM_ag_PlOverFulfillment2, x.ag_PlPercent AS PrM_ag_PlPercent2, x.ag_Pl_M AS PrM_ag_Pl_M2, x.ag_acceptedTtl_M AS PrM_ag_acceptedTtl_M2, x.ag_PlPz_M AS PrM_ag_PlPz_M2, x.mnPrevious AS PrM_mnPrevious2, IIf([ag_lim]>0,"агентская",IIf([iv_lim]>0,"инвест.","прочая")) AS ipgSh
FROM ((SELECT 
				z.ogNm, z.branchName, z.cstAgPnCode, z.cstapCstName, z.lim, z.ag_lim, z.ag_Ful_OverFul, z.ag_LimPc, z.ag_PlOverLimit_, z.iv_lim, 
				z.uk_lim, z.ag_PlAccum, z.ag_PlFulfillment, z.ag_PlPz, z.ag_PlOverFulfillment, z.ag_PlPercent, z.ag_Pl_M, z.ag_acceptedTtl_M, 
				z.ag_PlPz_M, z.mn, z.ogNmSort, z.cstAgPnCodeSort, IIf([z].[cstAgPnCode]="всего" And [z].[branch]=0,1,0) AS wr
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
						IIf(p![ag_PlAccum]=0,Null,p![ag_PlAccum]) AS ag_PlAccum, IIf(p![ag_PlFulfillment]=0,Null,p![ag_PlFulfillment]) AS ag_PlFulfillment, 
						IIf(IsNull(p![ag_PlAccum]) Or p![ag_PlAccum]=0,Null,p![ag_PlFulfillment]/p![ag_PlAccum]) AS ag_PlPz, 
						IIf(p![ag_PlOverFulfillment]=0,Null,p![ag_PlOverFulfillment]) AS ag_PlOverFulfillment, p.ag_PlPercent, 
						p.ag_Pl AS ag_Pl_M, p.ag_acceptedTtl AS ag_acceptedTtl_M, 
						IIf(IsNull([ag_Pl_M]) Or [ag_Pl_M]=0,Null,[ag_acceptedTtl_M]/[ag_Pl_M]) AS ag_PlPz_M, 
						MonthName(Month([dateRslt])) AS mn, p.ogNm AS ogNmSort, p.cstAgPnCode AS cstAgPnCodeSort
					FROM ipgChRsltPlCstPercent AS p 
						LEFT JOIN ags_cstAgPn AS c ON p.cstAgPnCode = c.cstapIpgPnN
					WHERE 
						(((p.dateRslt)=[ДатаОкончанияМесяца]) AND 
						((IIf(IsNull([p]![ag_lim]),0,[p]![ag_lim])+IIf(IsNull([p]![iv_lim]),0,[p]![iv_lim])+IIf(IsNull([p]![uk_lim]),0,[p]![uk_lim]))>0))
				)  AS z
			WHERE (((IIf([z].[cstAgPnCode]="всего" And [z].[branch]=0,1,0))=0))
			ORDER BY z.ogNm, z.branchName, z.cstAgPnCode
	)  AS z LEFT JOIN (SELECT 
					IIf(IsNull(p![ogNm]),"итого",p![ogNm]) AS ogNm, IIf(IsNull(p![cstAgPnCode]),"всего",p![cstAgPnCode]) AS cstAgPnCode, 
					IIf(p![ag_PlAccum]=0,Null,p![ag_PlAccum]) AS ag_PlAccum, IIf(p![ag_PlFulfillment]=0,Null,p![ag_PlFulfillment]) AS ag_PlFulfillment, 
					IIf(IsNull(p![ag_PlAccum]) Or p![ag_PlAccum]=0,Null,p![ag_PlFulfillment]/p![ag_PlAccum]) AS ag_PlPz, 
					IIf(p![ag_PlOverFulfillment]=0,Null,p![ag_PlOverFulfillment]) AS ag_PlOverFulfillment, p.ag_PlPercent, 
p.ag_Pl AS ag_Pl_M, p.ag_acceptedTtl AS ag_acceptedTtl_M, IIf(IsNull([ag_Pl_M]) Or [ag_Pl_M]=0,Null,[ag_acceptedTtl_M]/[ag_Pl_M]) AS ag_PlPz_M, IIf(IsNull([dateRslt]),Null,MonthName(Month([dateRslt]))) AS mnPrevious 
				FROM ipgChRsltPlCstPercent AS p 
					LEFT JOIN ags_cstAgPn AS c ON p.cstAgPnCode = c.cstapIpgPnN 
				WHERE
					(((p.dateRslt)=IIf(Month([ДатаОкончанияМесяца])=1, 0, ddLastDayInMonth(DateSerial(Year([ДатаОкончанияМесяца]), 
					Month([ДатаОкончанияМесяца])-1, 1)))) 
					And ((IIf(IsNull(p!ag_lim),0,p!ag_lim)+IIf(IsNull(p!iv_lim),0,p!iv_lim)+IIf(IsNull(p!uk_lim),0,p!uk_lim))>0))
			)  AS y ON (z.ogNm = y.ogNm) AND (z.cstAgPnCode = y.cstAgPnCode)) LEFT JOIN (SELECT IIf(IsNull(p![ogNm]),"итого",p![ogNm]) AS ogNm, IIf(IsNull(p![cstAgPnCode]),"всего",p![cstAgPnCode]) AS cstAgPnCode, IIf(p![ag_PlAccum]=0,Null,p![ag_PlAccum]) AS ag_PlAccum, IIf(p![ag_PlFulfillment]=0,Null,p![ag_PlFulfillment]) AS ag_PlFulfillment, IIf(IsNull(p![ag_PlAccum]) Or p![ag_PlAccum]=0,Null,p![ag_PlFulfillment]/p![ag_PlAccum]) AS ag_PlPz, IIf(p![ag_PlOverFulfillment]=0,Null,p![ag_PlOverFulfillment]) AS ag_PlOverFulfillment, p.ag_PlPercent, p.ag_Pl AS ag_Pl_M, p.ag_acceptedTtl AS ag_acceptedTtl_M, IIf(IsNull([ag_Pl_M]) Or [ag_Pl_M]=0,Null,[ag_acceptedTtl_M]/[ag_Pl_M]) AS ag_PlPz_M, IIf(IsNull([dateRslt]),Null,MonthName(Month([dateRslt]))) AS mnPrevious FROM ipgChRsltPlCstPercent AS p LEFT JOIN ags_cstAgPn AS c ON p.cstAgPnCode = c.cstapIpgPnN 
WHERE (((p.dateRslt)=IIf(Month([ДатаОкончанияМесяца])<3,0,ddLastDayInMonth(DateSerial(Year([ДатаОкончанияМесяца]),Month([ДатаОкончанияМесяца])-2,1)))) And ((IIf(IsNull(p!ag_lim),0,p!ag_lim)+IIf(IsNull(p!iv_lim),0,p!iv_lim)+IIf(IsNull(p!uk_lim),0,p!uk_lim))>0))
	)  AS x ON (z.ogNm = x.ogNm) AND (z.cstAgPnCode = x.cstAgPnCode)
ORDER BY z.ogNmSort, z.branchName, z.cstAgPnCodeSort;
