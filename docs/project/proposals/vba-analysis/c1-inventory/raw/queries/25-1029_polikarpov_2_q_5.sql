-- Access QueryDef: 25-1029_polikarpov_2_q_5
-- Type: 0

SELECT ags_ipgUtPlGr.iuplgKey, ags_ipgUtPlP.iuplpIpgPn, ags_ipgPn.ipgpNum, ags_ipgPn.ipgpCstAgPn, ags_cstAgPn.cstapIpgPnN, ags_ipgPn.ipgpSmTtl, CDbl(Replace(CStr([iuplpM10Accum]),".",",")) AS iuplpM10AccumD, CDbl(Replace(CStr([iuplpM11Accum]),".",",")) AS iuplpM11AccumD, CDbl(Replace(CStr([iuplpM12Accum]),".",",")) AS iuplpM12AccumD
FROM (((ags_ipgUtPlGr INNER JOIN ags_ipgUtPlGrP ON ags_ipgUtPlGr.iuplgKey = ags_ipgUtPlGrP.iuplgpGr) INNER JOIN ags_ipgUtPlP ON ags_ipgUtPlGrP.iuplgpPl = ags_ipgUtPlP.iuplpPl) INNER JOIN ags_ipgPn ON ags_ipgUtPlP.iuplpIpgPn = ags_ipgPn.ipgpKey) INNER JOIN ags_cstAgPn ON ags_ipgPn.ipgpCstAgPn = ags_cstAgPn.cstapKey
WHERE (((ags_ipgUtPlGr.iuplgKey)=19));
