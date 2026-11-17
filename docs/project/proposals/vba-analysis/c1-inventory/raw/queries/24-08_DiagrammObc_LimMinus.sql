-- Access QueryDef: 24-08_DiagrammObc_LimMinus
-- Type: 0

SELECT [24-08_DiagrammObc_Z].ogNm, [24-08_DiagrammObc_Z].branchName_Sort, [24-08_DiagrammObc_Z].cstAgPnCode_sort, [24-08_DiagrammObc_Z].dateRslt, [24-08_DiagrammObc_Z].[ИД, выполнено], [24-08_DiagrammObc_Z].[ИД, рассмотрение], [24-08_DiagrammObc_Z].[ИД, не выполнено], [24-08_DiagrammObc_Z].[ИД, перевыполнено], [24-08_DiagrammObc_Z].[ИД, лимит, рассмотрение], [24-08_DiagrammObc_Z].[ИД, лимит, остаток], [24-08_DiagrammObc_Z].[ИД, сверх лимита], [24-08_DiagrammObc_Z].[ИД, сверх лимита, рассмотрение], [24-08_DiagrammObc_Z].iv_lim
FROM [24-08_DiagrammObc_Z]
WHERE ((([24-08_DiagrammObc_Z].[ИД, лимит, остаток])<0));
