-- Access QueryDef: 24-08_DiagrammObc_NoBranch
-- Type: 0

SELECT [24-08_DiagrammObc].ogNm, [24-08_DiagrammObc].branch, [24-08_DiagrammObc].branchName, [24-08_DiagrammObc].cstAgPnCode_hook
FROM [24-08_DiagrammObc]
WHERE ((([24-08_DiagrammObc].branch)=0)) and (((Left([cstAgPnCode_hook],3))="051"))
GROUP BY [24-08_DiagrammObc].ogNm, [24-08_DiagrammObc].branch, [24-08_DiagrammObc].branchName, [24-08_DiagrammObc].cstAgPnCode_hook
ORDER BY [24-08_DiagrammObc].cstAgPnCode_hook;
