-- Access QueryDef: ags_Yr_DbtCstT
-- Type: 0

SELECT ags_Yr_DbtCst.ciccInvAccnt, ags_cstAgPnCs.cstAgPnNm AS [Код стройки], ags_cstAgPnCs_1.cstAgPnNm AS [Код стройки новый]
FROM (((ags_Yr_DbtCst LEFT JOIN ags_cnInvCmmCst ON ags_Yr_DbtCst.[Код стройки] = ags_cnInvCmmCst.ciccKey) LEFT JOIN ags_cstAgPnCs ON ags_cnInvCmmCst.ciccCstAgPn = ags_cstAgPnCs.cstapKey) LEFT JOIN ags_cnInvCmmCst AS ags_cnInvCmmCst_1 ON ags_Yr_DbtCst.[Код стройки новый] = ags_cnInvCmmCst_1.ciccKey) LEFT JOIN ags_cstAgPnCs AS ags_cstAgPnCs_1 ON ags_cnInvCmmCst_1.ciccCstAgPn = ags_cstAgPnCs_1.cstapKey;
