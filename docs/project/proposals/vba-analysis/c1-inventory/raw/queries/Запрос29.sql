-- Access QueryDef: Запрос29
-- Type: 0

SELECT [24-0110_ipg24].Num, [24-0110_ipg24].struct, ags_ipgPn.ipgpIpg, ags_ipgPn.ipgpKey
FROM [24-0110_ipg24] INNER JOIN ags_ipgPn ON [24-0110_ipg24].Num = ags_ipgPn.ipgpNum
WHERE (((ags_ipgPn.ipgpIpg)=21));
