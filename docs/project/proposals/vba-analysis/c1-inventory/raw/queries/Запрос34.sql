-- Access QueryDef: Запрос34
-- Type: 0

SELECT Запрос33.CstAgPnStr, ags_cstAg.cstaKey
FROM Запрос33 LEFT JOIN ags_cstAg ON (Запрос33.ogaKey = ags_cstAg.cstaAg) AND (Запрос33.cstKey = ags_cstAg.cstaCst);
