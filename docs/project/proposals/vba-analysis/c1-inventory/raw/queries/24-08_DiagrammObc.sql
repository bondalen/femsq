-- Access QueryDef: 24-08_DiagrammObc
-- Type: 0

SELECT IIf(IsNull([z].[ogNm]),"а",[z].[ogNm]) AS ogNm, IIf(IsNull([z].[branchName_Sort]),"а",[z].[branchName_Sort]) AS branchName_Sort, z.cstAgPnCode_sort, z.branch, z.dateRslt, z.ogaKey, z.ogNm_hook, z.countBranch_, z.branchName, z.branchName_hook, z.cstAgPnCode_hook, z.ag_lim, z.iv_lim, z.uk_lim, z.np_presentedAllModulAccum, z.oh_presentedTtlAccum
FROM (SELECT b.ogNm, IIf(IIf(IsNull([countBranch]),0,[countBranch])>0 And ((IsNull([branchName]) And [branch]=0) Or [b].[ogNm]=[branchName]),"а_Центральный офис",[branchName]) AS branchName_Sort, IIf(IsNull([cstAgPnCode]),"а_всего","б_" & [cstAgPnCode]) AS cstAgPnCode_sort, IIf(isnull(b.branch),-1,b.branch) AS branch, b.dateRslt, b.ogaKey, IIf(IsNull([branchName]),IIf(IsNull([b].[ogNm]),"итого",[b].[ogNm]),"пусто") AS ogNm_hook, IIf(IsNull([countBranch]),0,[countBranch]) AS countBranch_, 
b.branchName, 
IIf(IIf(IsNull([countBranch]),0,[countBranch])>0 And ((IsNull([branchName]) And [branch]=0) Or [b].[ogNm]=[branchName]),"Центральный офис", iif(isnull([branchName]), "пусто", [branchName])) AS branchName_hook, 
IIf(IsNull([cstAgPnCode]),"всего",[cstAgPnCode]) AS cstAgPnCode_hook, a.ag_lim, a.iv_lim, b.uk_lim, b.np_presentedAllModulAccum, b.oh_presentedTtlAccum FROM (ags_fnIpgChRsltCstUtlPercentBrn_2408_tbl_part_2 AS b LEFT JOIN [24-08_DiagrammObc_Br] AS br ON b.ogNm = br.ogNm) INNER JOIN ags_fnIpgChRsltCstUtlPercentBrn_2408_tbl_part_1 AS a ON b.rowNum = a.rowNum
)  AS z
WHERE ((((([z].[branch])=0) And (([z].[countBranch_])=0) And (([z].[cstAgPnCode_hook])="всего"))=False))
ORDER BY IIf(IsNull([z].[ogNm]),"а",[z].[ogNm]), IIf(IsNull([z].[branchName_Sort]),"а",[z].[branchName_Sort]), z.cstAgPnCode_sort, z.dateRslt;
