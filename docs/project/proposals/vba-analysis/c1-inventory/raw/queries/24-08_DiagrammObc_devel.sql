-- Access QueryDef: 24-08_DiagrammObc_devel
-- Type: 0

SELECT IIf(IsNull([z].[ogNm]),"а",[z].[ogNm]) AS ogNm, IIf(IsNull([z].[branchName_Sort]),"а",[z].[branchName_Sort]) AS branchName_Sort, z.cstAgPnCode_sort, z.branch, z.dateRslt, z.ogaKey, z.ogNm_hook, z.countBranch_, z.branchName, z.branchName_hook, z.cstAgPnCode_hook, z.[АД, выполнен], z.[АД, рассмотрение], z.[АД, не выполнено], z.[АД, перевыполнено], z.[АД, лимит, рассмотрение], z.[АД, лимит, остаток], z.[АД, сверх лимита], z.[АД, сверх лимита, рассмотрение], z.[ИД, выполнено], z.[ИД, рассмотрение], z.[ИД, не выполнено], z.[ИД, перевыполнено], z.[ИД, лимит, рассмотрение], z.[ИД, лимит, остаток], z.[ИД, сверх лимита], z.[ИД, сверх лимита, рассмотрение], z.[? выполнено], z.[? рассмотрение], z.[? не выполнено], z.[? перевыполнено], z.[? лимит, рассмотрение], z.[? лимит, остаток], z.[? сверх лимита], z.[? сверх лимита, рассмотрение], z.[вне плана], z.[вне плана, рассмотрение], z.ag_lim, z.iv_lim, z.uk_lim, z.np_presentedAllModulAccum, z.oh_presentedTtlAccum
FROM (SELECT 
			b.ogNm, 
			IIf(IIf(IsNull([countBranch]),0,[countBranch])>0 And ((IsNull([branchName]) And [branch]=0) Or [b].[ogNm]=[branchName]),"а_Центральный офис",[branchName]) AS branchName_Sort, 
			IIf(IsNull ([cstAgPnCode]),"а_всего","б_" & [cstAgPnCode]) AS cstAgPnCode_sort, 
			IIf(isnull(b.branch),-1,b.branch) AS branch, b.dateRslt, b.ogaKey, 
			IIf(IsNull([branchName]),IIf(IsNull([b].[ogNm]),"итого",[b].[ogNm]),"пусто") AS ogNm_hook, 
			IIf(IsNull([countBranch]),0,[countBranch]) AS countBranch_, b.branchName, 
			IIf(IIf(IsNull([countBranch]),0,[countBranch])>0 And ((IsNull([branchName]) And [branch]=0) Or [b].[ogNm]=[branchName]),"Центральный офис",iif(isnull([branchName]), "пусто", [branchName])) AS branchName_hook, 
			IIf(IsNull([cstAgPnCode]),"всего",[cstAgPnCode]) AS cstAgPnCode_hook, 
			ag_PlFulfillment AS [АД, выполнен],
			ag_PlNonFulfillment_review as [АД, рассмотрение],
			ag_PlNonFulfillment AS [АД, не выполнено],
			ag_PlOverFulfillment AS [АД, перевыполнено],
			ag_PlRestLimit_review AS [АД, лимит, рассмотрение],
			ag_PlRestLimit AS [АД, лимит, остаток],
			ag_PlOverLimit AS [АД, сверх лимита],
			ag_PlOverLimit_review AS [АД, сверх лимита, рассмотрение],
			iv_PlFulfillment AS [ИД, выполнено], 
			iv_PlNonFulfillment_review as [ИД, рассмотрение],
			iv_PlNonFulfillment AS [ИД, не выполнено], 
			iv_PlOverFulfillment AS [ИД, перевыполнено], 
			iv_PlRestLimit_review AS [ИД, лимит, рассмотрение],
			iv_PlRestLimit AS [ИД, лимит, остаток],
			iv_PlOverLimit AS [ИД, сверх лимита],
			iv_PlOverLimit_review AS [ИД, сверх лимита, рассмотрение],
			uk_PlFulfillment AS [? выполнено],
			uk_PlNonFulfillment_review as [? рассмотрение],
			uk_PlNonFulfillment AS [? не выполнено], 
			uk_PlOverFulfillment AS [? перевыполнено], 
			uk_PlRestLimit_review AS [? лимит, рассмотрение],
			uk_PlRestLimit AS [? лимит, остаток],
			uk_PlOverLimit AS [? сверх лимита],
			uk_PlOverLimit_review AS [? сверх лимита, рассмотрение],
			np_acceptedTtlAccum AS [вне плана],
			np_inProcessTtlAccum AS [вне плана, рассмотрение],
			a.ag_lim, a.iv_lim, b.uk_lim, b.np_presentedAllModulAccum, b.oh_presentedTtlAccum 
		FROM 
			(
				ags_fnIpgChRsltCstUtlPercentBrn_2408_tbl_part_2 AS b 
					LEFT JOIN [24-08_DiagrammObc_Br] AS br ON b.ogNm = br.ogNm
			) INNER JOIN ags_fnIpgChRsltCstUtlPercentBrn_2408_tbl_part_1 AS a ON b.rowNum = a.rowNum
	)  AS z
WHERE ((((([z].[branch])=0) And (([z].[countBranch_])=0) And (([z].[cstAgPnCode_hook])="всего"))=False))
ORDER BY IIf(IsNull([z].[ogNm]),"а",[z].[ogNm]), IIf(IsNull([z].[branchName_Sort]),"а",[z].[branchName_Sort]), z.cstAgPnCode_sort, z.dateRslt;
