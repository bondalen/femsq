-- Access QueryDef: ipgCs
-- Type: 0

SELECT ags_ipg.ipgKey, [ags_og]![ogNm] & ". " & CStr([ags_yyyy]![yyyy]) & " г. № " & CStr([ags_ipg]![ipgNum]) & ". " & [ags_ipg]![ipgNm] AS nnn
FROM (ags_ipg INNER JOIN ags_yyyy ON ags_ipg.ipgYy = ags_yyyy.yKey) INNER JOIN ags_og ON ags_ipg.ipgOg = ags_og.ogKey
ORDER BY [ags_og]![ogNm] & ". " & CStr([ags_yyyy]![yyyy]) & " г. № " & CStr([ags_ipg]![ipgNum]) & ". " & [ags_ipg]![ipgNm];
