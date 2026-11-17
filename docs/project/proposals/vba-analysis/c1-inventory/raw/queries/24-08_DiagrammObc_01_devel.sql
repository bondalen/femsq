-- Access QueryDef: 24-08_DiagrammObc_01_devel
-- Type: 0

SELECT x.ogNm, x.branchName_Sort, x.cstAgPnCode_sort, x.branch, x.dateRslt, x.ogaKey, x.ogNm_hook, x.countBranch_, x.branchName, x.branchName_hook, x.cstAgPnCode_hook, 0 AS [АД, выполнен], 0 AS [АД, рассмотрение], 0 AS [АД, не выполнено], 0 AS [АД, перевыполнено], 0 AS [АД, лимит, рассмотрение], [24-08_DiagrammObc_01_lim].ag_lim AS [АД, лимит, остаток], 0 AS [АД, сверх лимита], 0 AS [АД, сверх лимита, рассмотрение], 0 AS [ИД, выполнено], 0 AS [ИД, рассмотрение], 0 AS [ИД, не выполнено], 0 AS [ИД, перевыполнено], 0 AS [ИД, лимит, рассмотрение], [24-08_DiagrammObc_01_lim].iv_lim AS [ИД, лимит, остаток], 0 AS [ИД, сверх лимита], 0 AS [ИД, сверх лимита, рассмотрение], 0 AS [? выполнено], 0 AS [? рассмотрение], 0 AS [? не выполнено], 0 AS [? перевыполнено], 0 AS [? лимит, рассмотрение], [24-08_DiagrammObc_01_lim].uk_lim AS [? лимит, остаток], 0 AS [? сверх лимита], 0 AS [? сверх лимита, рассмотрение], 0 AS [вне плана], 0 AS [вне плана, рассмотрение], [24-08_DiagrammObc_01_lim].ag_lim, [24-08_DiagrammObc_01_lim].iv_lim, [24-08_DiagrammObc_01_lim].uk_lim, 0 AS np_presentedAllModulAccum_dummy, 0 AS oh_presentedTtlAccum_dummy
FROM (SELECT 
			qq.ogNm, qq.branchName_Sort, qq.cstAgPnCode_sort, qq.branch, 
			dd.ddd AS dateRslt, qq.ogaKey, qq.ogNm_hook, qq.countBranch_, 
			qq.branchName, qq.branchName_hook, qq.cstAgPnCode_hook 
		FROM 
			(
				SELECT 
					q.ogNm, q.branchName_Sort, q.cstAgPnCode_sort, q.branch, q.ogaKey, 
					q.ogNm_hook, q.countBranch_, q.branchName, q.branchName_hook, 
					q.cstAgPnCode_hook 
				FROM [24-08_DiagrammObc] AS q 
				GROUP BY q.ogNm, q.branchName_Sort, q.cstAgPnCode_sort, q.branch, q.ogaKey, 
					q.ogNm_hook, q.countBranch_, q.branchName, q.branchName_hook, 
					q.cstAgPnCode_hook
			)  AS qq, [24-08_DiagrammObc_ddd] AS dd 
		GROUP BY qq.ogNm, qq.branchName_Sort, qq.cstAgPnCode_sort, qq.branch, dd.ddd, 
			qq.ogaKey, qq.ogNm_hook, qq.countBranch_, qq.branchName, qq.branchName_hook, 
			qq.cstAgPnCode_hook
	)  AS x LEFT JOIN [24-08_DiagrammObc_01_lim] ON (x.cstAgPnCode_sort = [24-08_DiagrammObc_01_lim].cstAgPnCode_sort) AND (x.branchName_Sort = [24-08_DiagrammObc_01_lim].branchName_Sort) AND (x.ogNm = [24-08_DiagrammObc_01_lim].ogNm);
