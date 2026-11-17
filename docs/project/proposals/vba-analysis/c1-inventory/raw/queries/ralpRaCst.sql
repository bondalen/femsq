-- Access QueryDef: ralpRaCst
-- Type: 0

SELECT ags_cst.cstKey, ags_ogAgCs.ogaNm, ags_cstAgPn.cstapIpgPnN, ags_ralpRa.ralprKey, ags_ralpRa.ralprNum, ags_ralpRa.ralprDate, ags_ralpRa.ralprCstAgPn, ags_ralpRa.ralprOgSender, ags_og.ogNm
FROM ags_og INNER JOIN (ags_ogAgCs INNER JOIN (ags_cst INNER JOIN (ags_cstAg INNER JOIN (ags_cstAgPn INNER JOIN ags_ralpRa ON ags_cstAgPn.cstapKey = ags_ralpRa.ralprCstAgPn) ON ags_cstAg.cstaKey = ags_cstAgPn.cstapCsta) ON ags_cst.cstKey = ags_cstAg.cstaCst) ON ags_ogAgCs.ogaKey = ags_cstAg.cstaAg) ON ags_og.ogKey = ags_ralpRa.ralprOgSender;
