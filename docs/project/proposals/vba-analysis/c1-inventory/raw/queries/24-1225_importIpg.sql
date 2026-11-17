-- Access QueryDef: 24-1225_importIpg
-- Type: 64

INSERT INTO ags_ipgStPn ( ipgspSt, ipgspPn )
SELECT [24-1128_ipg25].StIPgPn, ags_ipgPn.ipgpKey
FROM [24-1128_ipg25] LEFT JOIN ags_ipgPn ON [24-1128_ipg25].Код = ags_ipgPn.ipgpNum
WHERE (((ags_ipgPn.ipgpIpg)=25))
ORDER BY [24-1128_ipg25].Код;
