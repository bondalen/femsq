-- Access QueryDef: ags_Yr_DbtTbl_RsltCst
-- Type: 0

SELECT ags_Yr_DbtTbl_Rslt.*, ags_cstAgPn.cstapKey, ags_cst.cstName, ags_og.ogNm
FROM ((((ags_Yr_DbtTbl_Rslt LEFT JOIN ags_cstAgPn ON ags_Yr_DbtTbl_Rslt.стройка_код = ags_cstAgPn.cstapIpgPnN) LEFT JOIN ags_cstAg ON ags_cstAgPn.cstapCsta = ags_cstAg.cstaKey) LEFT JOIN ags_cst ON ags_cstAg.cstaCst = ags_cst.cstKey) LEFT JOIN ags_ogAg ON ags_cstAg.cstaAg = ags_ogAg.ogaKey) LEFT JOIN ags_og ON ags_ogAg.ogaOg = ags_og.ogKey;
