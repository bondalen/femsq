-- Access QueryDef: Запрос11
-- Type: 0

SELECT ags_ipgPn.ipgpKey, ags_ipgPn.ipgpCstAgPn, ags_ipgPn.ipgpSmTtl, Запрос8.limN, [ipgpSmTtl]-[limN] AS limD, ags_ipgPn.ipgpSmOth, Запрос8.limOthersN, [ipgpSmOth]-[limOthersN] AS limOthD, ags_ipgPn.ipgpSmAgFee, Запрос8.limAgFeeN, [ipgpSmAgFee]-[limAgFeeN] AS limAgFeeD, ags_ipgPn.ipgpSmReserv, Запрос8.limResN, [ipgpSmReserv]-[limResN] AS limResD
FROM ags_ipgPn INNER JOIN Запрос8 ON (ags_ipgPn.ipgpSh = Запрос8.sh) AND (ags_ipgPn.ipgpCstAgPn = Запрос8.cstapKey) AND (ags_ipgPn.ipgpIpg = Запрос8.ipg)
WHERE ((([ipgpSmTtl]-[limN])<>0)) OR ((([ipgpSmOth]-[limOthersN])<>0)) OR ((([ipgpSmAgFee]-[limAgFeeN])<>0)) OR ((([ipgpSmReserv]-[limResN])<>0))
ORDER BY [ipgpSmTtl]-[limN];
