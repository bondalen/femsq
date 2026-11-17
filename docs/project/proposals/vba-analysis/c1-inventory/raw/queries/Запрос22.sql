-- Access QueryDef: Запрос22
-- Type: 0

SELECT ags_ipgPn.ipgpIpg, ags_ipgPn.ipgpNum, ags_ipgPn.ipgpKey, [22-1227_ipg23].struk
FROM ags_ipgPn LEFT JOIN [22-1227_ipg23] ON ags_ipgPn.ipgpNum = [22-1227_ipg23].num
WHERE (((ags_ipgPn.ipgpIpg)=12))
ORDER BY ags_ipgPn.ipgpNum;
