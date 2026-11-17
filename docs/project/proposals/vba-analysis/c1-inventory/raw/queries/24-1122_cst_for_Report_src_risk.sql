-- Access QueryDef: 24-1122_cst_for_Report_src_risk
-- Type: 0

SELECT *
FROM (SELECT z.*, b.PrM_ag_acceptedTtl_M, b.PrM_ag_acceptedTtl_M2, b.PrM_ag_Pl_M, b.PrM_ag_Pl_M2, b.PrM_ag_PlAccum, b.PrM_ag_PlAccum2, b.PrM_ag_PlFulfillment, b.PrM_ag_PlFulfillment2, b.PrM_ag_PlFulfillment2All, b.PrM_ag_PlFulfillmentAll, b.PrM_ag_PlFulfillmentAll, b.PrM_ag_PlOverFulfillment, b.PrM_ag_PlOverFulfillment2, b.PrM_ag_PlPercent, b.PrM_ag_PlPercent2, b.PrM_ag_PlPz, b.PrM_ag_PlPz_M, b.PrM_ag_PlPz_M2, b.PrM_ag_PlPz2, b.PrM_mnPrevious, b.PrM_mnPrevious2 FROM (SELECT IIf(IsNull([branchName]),IIf(IsNull([ogNm]),"пусто",[ogNm]),"пусто") AS ogNm_hook, IIf(IsNull([branchName]),"пусто",IIf([branchName]=[ogNm],"Центральный офис",[branchName])) AS branchName_hook, a.* FROM ags_fnIpgChRsltCstUtlPercentBrnRepSrc01_2408 AS a WHERE (((a.cstAgPnCode)<>"всего")) ORDER BY a.cstAgPnCode)  AS z LEFT JOIN ags_fnIpgChRsltCstUtlPercentBrnRep01_2408_tbl AS b ON z.cstAgPnCode = b.cstAgPnCode)  AS y INNER JOIN [24-1122_risk] ON y.cstAgPnCode = [24-1122_risk].cstAgPn
ORDER BY y.cstAgPnCode;
