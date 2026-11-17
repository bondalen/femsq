-- Access QueryDef: Запрос33
-- Type: 0

SELECT Запрос32.*, ags_ogAg.ogaKey
FROM Запрос32 LEFT JOIN ags_ogAg ON Запрос32.cstAg = ags_ogAg.ogaCode;
