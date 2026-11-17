-- Access QueryDef: 24-08_DiagrammObc_01_lim
-- Type: 0

SELECT q.ogNm, q.branchName_Sort, q.cstAgPnCode_sort, q.branch, q.ogaKey, q.ogNm_hook, q.countBranch_, q.branchName, q.branchName_hook, q.cstAgPnCode_hook, Month([dateRslt]) AS mm, Day([dateRslt]) AS dd, q.ag_lim, q.iv_lim, q.uk_lim
FROM [24-08_DiagrammObc] AS q
WHERE (((Month([dateRslt]))=1) AND ((Day([dateRslt]))=31));
