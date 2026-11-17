-- Access QueryDef: ipgLdM_rslt
-- Type: 0

SELECT ipgLdM_f.ldmfLdM, ipgLdM_f.ldmfKey, ags_ipgUtPl.iuplKey, ags_ipgUtPl.iuplNm, ags_ipgUtPl.iuplDate, z.ipgpKey, z.ipgpIpg, z.ipgpCstAgPn, z.ogaNm, z.ipgpSmTtl, z.cstaAg, z.ipgpNum, z.cstapIpgPnN, z.ipgpSh, z.ipgsNm, ags_ipgUtPlP.iuplpKey, ags_ipgUtPlP.iuplpLim, IIf(IsNull([ipgpSmTtl]),0,[ipgpSmTtl])-IIf(IsNull([iuplpLim]),0,[iuplpLim]) AS diff, ipgLdM_f.ldmfUtPlKey
FROM ipgLdM_f INNER JOIN ((ags_ipgUtPl INNER JOIN (SELECT ip.ipgpKey, ip.ipgpIpg, ip.ipgpCstAgPn, ip.ipgpSmTtl, ca.cstaAg, ip.ipgpNum, cap.cstapIpgPnN, ip.ipgpSh, ags_ipgSh.ipgsNm, ags_ogAgCs.ogaNm FROM (((ags_ipgPn AS ip INNER JOIN ags_cstAgPn AS cap ON ip.ipgpCstAgPn = cap.cstapKey) INNER JOIN ags_cstAg AS ca ON cap.cstapCsta = ca.cstaKey) INNER JOIN ags_ipgSh ON ip.ipgpSh = ags_ipgSh.ipgsKey) INNER JOIN ags_ogAgCs ON ca.cstaAg = ags_ogAgCs.ogaKey)  AS z ON (ags_ipgUtPl.iuplIpg = z.ipgpIpg) AND (ags_ipgUtPl.iuplAg = z.cstaAg)) LEFT JOIN ags_ipgUtPlP ON z.ipgpKey = ags_ipgUtPlP.iuplpIpgPn) ON ipgLdM_f.ldmfUtPlKey = ags_ipgUtPl.iuplKey
ORDER BY z.ipgpNum;
