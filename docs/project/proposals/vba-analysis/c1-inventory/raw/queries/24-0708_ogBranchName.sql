-- Access QueryDef: 24-0708_ogBranchName
-- Type: 0

SELECT ags_cstAgPnBranch.cstapbCstAgPn, ags_cstAgPnBranch.cstapbBranch, ags_og.ogNm
FROM ags_cstAgPnBranch LEFT JOIN ags_og ON ags_cstAgPnBranch.cstapbBranch = ags_og.ogKey
WHERE (((ags_cstAgPnBranch.cstapbEnd) Is Null))
ORDER BY ags_cstAgPnBranch.cstapbBranch DESC;
