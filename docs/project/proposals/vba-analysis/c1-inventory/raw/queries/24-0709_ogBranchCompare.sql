-- Access QueryDef: 24-0709_ogBranchCompare
-- Type: 0

SELECT [24-0709_ГИ_филиалы].код, [24-0709_ГИ_филиалы].филиал, ags_cstAgPn.cstapKey, [24-0708_ogBranchName].ogNm, IIf([филиал]=[ogNm],"соответствует","не соответствует") AS rslt
FROM ([24-0709_ГИ_филиалы] LEFT JOIN ags_cstAgPn ON [24-0709_ГИ_филиалы].код = ags_cstAgPn.cstapIpgPnN) LEFT JOIN [24-0708_ogBranchName] ON ags_cstAgPn.cstapKey = [24-0708_ogBranchName].cstapbCstAgPn;
