-- Access QueryDef: ipgLdMnRsltGr
-- Type: 0

SELECT z.ldmKey, z.ldmName, Sum(z.ipgpSmTtl) AS ipgLim, Sum(y.iuplpLim) AS uplLim, Sum(IIf(IsNull([ipgpSmTtl]),0,[ipgpSmTtl])-IIf(IsNull([iuplpLim]),0,[iuplpLim])) AS diff
FROM (SELECT ip.ipgpIpg, ip.ipgpKey, ip.ipgpNum, ac.ogaKey, ac.ogaNm, ap.cstapIpgPnN, ip.ipgpSmTtl, ip.ipgpSh, [is].ipgsNm, il.ldmKey, il.ldmName FROM ((((ags_ipgPn AS ip INNER JOIN ags_cstAgPn AS ap ON ip.ipgpCstAgPn = ap.cstapKey) INNER JOIN ags_ipgSh AS [is] ON ip.ipgpSh = [is].ipgsKey) INNER JOIN ipgLdM AS il ON ip.ipgpIpg = il.ldmIpg) INNER JOIN ags_cstAg AS ca ON ap.cstapCsta = ca.cstaKey) INNER JOIN ags_ogAgCs AS ac ON ca.cstaAg = ac.ogaKey)  AS z LEFT JOIN (SELECT lf.ldmfLdM, lf.ldmfNum, lf.ldmfKey, up.iuplNm, up.iuplDate, pp.iuplpKey, pp.iuplpSubAg, pp.iuplpIpgPn, pp.iuplpLim FROM ((ipgLdM_f AS lf INNER JOIN ags_ipgUtPl AS up ON lf.ldmfUtPlKey = up.iuplKey) LEFT JOIN ags_ipgUtPlP AS pp ON up.iuplKey = pp.iuplpPl) INNER JOIN ags_ogAgCs AS ag ON up.iuplAg = ag.ogaKey)  AS y ON (z.ipgpKey = y.iuplpIpgPn) AND (z.ldmKey = y.ldmfLdM)
GROUP BY z.ldmKey, z.ldmName
ORDER BY z.ldmKey;
