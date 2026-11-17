-- Access QueryDef: Запрос32
-- Type: 0

SELECT Запрос31.*, ags_cst.cstKey
FROM Запрос31 LEFT JOIN ags_cst ON Запрос31.CstName=left(ags_cst.cstName,255);
