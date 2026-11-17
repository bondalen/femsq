-- Access QueryDef: 24-1225_compare
-- Type: 0

SELECT [24-1225_importIpg].cstapKey, [24-1225_importIpg].cstAgPn, [24-1225_importIpg].cstName, Len([24-1225_importIpg].[cstName]) AS lnCstName, [24-1225_importIpg].r7, [24-1225_importIpg].r4, [24-1225_importIpg].m5, ags_ogAg.ogaKey, [24-1225_importIpg].Код, ags_cst.cstKey, ags_cst.cstName, ags_cstAg.cstaKey
FROM (([24-1225_importIpg] LEFT JOIN ags_ogAg ON [24-1225_importIpg].l3 = ags_ogAg.ogaCode) LEFT JOIN ags_cst ON [24-1225_importIpg].Код = ags_cst.cstMark) LEFT JOIN ags_cstAg ON ags_cst.cstKey = ags_cstAg.cstaCst
ORDER BY [24-1225_importIpg].Код;
